import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { JSDOM } from 'jsdom';
import * as Y from 'yjs';
import { prosemirrorJSONToYDoc } from 'y-prosemirror';
import { makeSchema } from '../src/schema.js';
import { encode64 } from '../src/protocol.js';

const bundle = await readFile(new URL('../Resources/ProjectNoteEditorWeb/editor.bundle.js', import.meta.url), 'utf8');
function environment() {
  const dom = new JSDOM('<div id="toolbar"></div><div id="status"></div><main id="editor"></main>',
    { runScripts: 'outside-only', pretendToBeVisual: true });
  const messages = [];
  dom.window.webkit = { messageHandlers: { projectNote: { postMessage: value => messages.push(JSON.parse(JSON.stringify(value))) } } };
  dom.window.eval(bundle);
  return { dom, messages, api: dom.window.projectNote,
    close() { dom.window.projectNote.destroy(); dom.window.close(); } };
}
const content = { type: 'doc', content: [{ type: 'taskEmbed', attrs: { taskId: 'unchanged-id' } },
  { type: 'paragraph', content: [{ type: 'text', text: 'Document' }] }] };
const options = { nonce: 'native-session', labels: { bold: 'Negrita', readOnly: 'Solo lectura', taskEmbed: 'Tarea', error: 'Error' },
  user: { name: 'Editor', color: '#123456' }, snapshot: { yjs_state: null, content } };

test('valid load remains read-only until enabled, uses native labels and returns the emitted snapshot', () => {
  const env = environment();
  try {
    env.api.initialize(options);
    assert.deepEqual(env.messages.map(m => m.type), ['ready']);
    assert.equal(env.dom.window.document.querySelector('.tiptap').getAttribute('contenteditable'), 'false');
    const bold = env.dom.window.document.querySelector('#action-bold');
    const icon = bold.querySelector('svg');
    assert.equal(bold.textContent, '');
    assert.equal(bold.getAttribute('aria-label'), 'Negrita');
    assert.equal(bold.title, 'Negrita');
    assert.equal(icon.getAttribute('aria-hidden'), 'true');
    assert.equal(icon.getAttribute('focusable'), 'false');
    for (const key of ['bold', 'italic', 'bulletList', 'orderedList', 'heading', 'undo', 'redo']) {
      assert.ok(env.dom.window.document.querySelector(`#action-${key} svg path`));
    }
    env.api.setEditable(true);
    assert.equal(env.dom.window.document.querySelector('.tiptap').getAttribute('contenteditable'), 'true');
    const returned = JSON.parse(JSON.stringify(env.api.snapshot()));
    assert.deepEqual(returned, env.messages.at(-1));
    assert.equal(returned.revision, 0);
    assert.equal(returned.content.content[0].attrs.taskId, 'unchanged-id');
    assert.equal(returned.nonce, 'native-session');
    env.api.configure({ labels: { bold: 'Bold' } });
    assert.equal(bold.title, 'Bold');
    assert.equal(bold.getAttribute('aria-label'), 'Bold');
    assert.equal(bold.querySelector('svg'), icon, 'State/locale refresh must preserve the icon');
    assert.equal(bold.disabled, false);
  } finally { env.close(); }
});

test('failed or missing snapshots never fall back to JSON seeding or allow edits', () => {
  for (const snapshot of [{ yjs_state: 'corrupt', content }, { content }, { yjs_state: null },
    { yjs_state: null, content: { type: 'doc', content: [{ type: 'futureWidget' }] } }]) {
    const env = environment();
    try {
      env.api.initialize({ ...options, snapshot }); env.api.setEditable(true);
      assert.equal(env.messages.some(m => m.type === 'ready'), false);
      assert.equal(env.messages.some(m => m.type === 'snapshot'), false);
      assert.equal(env.messages.at(-1).type, 'error');
      assert.equal(env.api.snapshot(), null);
      assert.equal(env.dom.window.document.querySelector('.tiptap'), null);
    } finally { env.close(); }
  }
});

test('merging an offline snapshot preserves IDs, becomes dirty and survives snapshot reload', () => {
  const env = environment(), next = environment();
  try {
    env.api.initialize(options);
    const before = env.api.snapshot();
    const offline = new Y.Doc();
    Y.applyUpdate(offline, Uint8Array.from(Buffer.from(before.yjs_state, 'base64')));
    offline.getXmlFragment('default').get(1).get(0).insert(0, 'Offline ');
    assert.equal(env.api.mergeSnapshot(encode64(Y.encodeStateAsUpdate(offline))), true); offline.destroy();
    assert.equal(env.messages.at(-1).type, 'dirty');
    const saved = env.api.snapshot();
    assert.equal(saved.revision, 1);
    assert.equal(saved.content.content[1].content[0].text, 'Offline Document');
    next.api.initialize({ ...options, nonce: 'next', snapshot: saved });
    assert.deepEqual(JSON.parse(JSON.stringify(next.api.snapshot().content)), JSON.parse(JSON.stringify(saved.content)));
  } finally { env.close(); next.close(); }
});

test('authoritative Yjs content overrides stale companion JSON and preserves unknown-content failures', () => {
  const source = prosemirrorJSONToYDoc(makeSchema(), content, 'default');
  const env = environment();
  try {
    env.api.initialize({ ...options, snapshot: { yjs_state: encode64(Y.encodeStateAsUpdate(source)), content: null } });
    assert.equal(env.api.snapshot().content.content[0].attrs.taskId, 'unchanged-id');
    source.getXmlFragment('default').push([new Y.XmlElement('futureWidget')]);
    assert.equal(env.api.mergeSnapshot(encode64(Y.encodeStateAsUpdate(source))), false);
    assert.equal(env.messages.at(-1).code, 'unsupported_content');
    assert.equal(env.api.snapshot(), null);
    assert.equal(env.dom.window.document.querySelector('.tiptap').getAttribute('contenteditable'), 'false');
  } finally { source.destroy(); env.close(); }
});

test('rejecting a remote update snapshots the last local keystroke before reporting the error', async () => {
  const env = environment(), remote = new Y.Doc();
  try {
    env.api.initialize(options); env.api.setEditable(true);
    const baseline = env.api.snapshot();
    Y.applyUpdate(remote, Uint8Array.from(Buffer.from(baseline.yjs_state, 'base64')));
    remote.getXmlFragment('default').push([new Y.XmlElement('futureWidget')]);
    env.messages.length = 0;
    // Exercise the real editor's DOM observer without waiting for native's 300 ms draft debounce.
    env.dom.window.document.querySelector('.tiptap p').firstChild.textContent = 'Document with a recent edit';
    await new Promise(resolve => setTimeout(resolve, 0));
    assert.equal(env.messages.at(-1).type, 'dirty');
    assert.equal(env.messages.some(message => message.type === 'snapshot'), false);
    assert.equal(env.api.mergeSnapshot(encode64(Y.encodeStateAsUpdate(remote))), false);
    assert.deepEqual(env.messages.slice(-2).map(message => message.type), ['snapshot', 'error']);
    const recovery = env.messages.at(-2);
    assert.equal(recovery.revision, 1);
    assert.equal(recovery.content.content[1].content[0].text, 'Document with a recent edit');
    assert.equal(recovery.content.content.some(node => node.type === 'futureWidget'), false);
    assert.equal(env.messages.at(-1).code, 'unsupported_content');
    assert.equal(env.api.snapshot(), null, 'The failed editor still rejects ordinary snapshot requests');
  } finally { remote.destroy(); env.close(); }
});
