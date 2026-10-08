import test from 'node:test';
import assert from 'node:assert/strict';
import * as Y from 'yjs';
import { prosemirrorJSONToYDoc } from 'y-prosemirror';
import { NoteProtocol, ChunkReceiver, EVENTS, CHUNK_SIZE, MAX_STATE_BYTES, MAX_STATE_CHARS, encode64, decode64 } from '../src/protocol.js';
import { makeSchema, validateContent, contentFromDoc } from '../src/schema.js';

const schema = makeSchema();
const content = { type: 'doc', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'hello' }] }] };
function document() { return prosemirrorJSONToYDoc(schema, content, 'default'); }
function copy(doc) { const result = new Y.Doc(); Y.applyUpdate(result, Y.encodeStateAsUpdate(doc)); return result; }
function client(doc) {
  const events = [], revisions = [], errors = [];
  const provider = new NoteProtocol({ doc, emit: value => events.push(value),
    validate: candidate => contentFromDoc(candidate, schema), onChange: value => revisions.push(value),
    onError: value => errors.push(value), user: { name: 'Test', color: '#123456' } });
  provider.activate(); return { provider, events, revisions, errors };
}
function relay(events, receiver) { for (const event of events.splice(0)) receiver.receive(event.event, event.data); }

test('concurrent web-compatible Yjs edits converge without echo and both revisions become dirty', () => {
  const a = client(document()), b = client(copy(a.provider.doc));
  try {
    a.provider.doc.getXmlFragment('default').get(0).get(0).insert(0, 'A');
    b.provider.doc.getXmlFragment('default').get(0).get(0).insert(5, 'B');
    a.provider.flush(); b.provider.flush();
    assert.equal(a.events[0].event, EVENTS.update);
    relay(a.events, b.provider); relay(b.events, a.provider);
    a.provider.flush(); b.provider.flush();
    assert.deepEqual(a.events, []); assert.deepEqual(b.events, []);
    assert.deepEqual(contentFromDoc(a.provider.doc, schema), contentFromDoc(b.provider.doc, schema));
    assert.equal(a.provider.doc.getXmlFragment('default').get(0).get(0).toString(), 'AhelloB');
    assert.deepEqual(a.revisions, [1, 2]); assert.deepEqual(b.revisions, [1, 2]);
  } finally { a.provider.destroy(); b.provider.destroy(); }
});

test('reconnect state-vector exchange and current-state advertisement recover offline draft changes', () => {
  const a = client(document()), b = client(copy(a.provider.doc));
  const offline = copy(a.provider.doc);
  try {
    offline.getXmlFragment('default').get(0).get(0).insert(0, 'draft ');
    a.provider.mergeSnapshot(encode64(Y.encodeStateAsUpdate(offline)));
    assert.deepEqual(a.revisions, [1]); assert.deepEqual(a.events, []);
    a.provider.subscribed();
    assert.equal(a.events[0].event, EVENTS.request);
    assert.deepEqual(Object.keys(a.events[0].data), ['sv']);
    relay(a.events, b.provider); relay(b.events, a.provider);
    assert.deepEqual(contentFromDoc(a.provider.doc, schema), contentFromDoc(b.provider.doc, schema));
    const revision = a.provider.revision;
    a.provider.mergeSnapshot(encode64(Y.encodeStateAsUpdate(offline)));
    assert.equal(a.provider.revision, revision, 'Identical save response is not another dirty edit');
  } finally { offline.destroy(); a.provider.destroy(); b.provider.destroy(); }
});

test('awareness uses frontend {u} payload and remote awareness is not echoed', () => {
  const a = client(document()), b = client(copy(a.provider.doc));
  try {
    a.provider.setUser({ name: 'Another author', color: '#abcdef' });
    assert.equal(a.events[0].event, EVENTS.awareness);
    assert.deepEqual(Object.keys(a.events[0].data), ['u']);
    relay(a.events, b.provider);
    assert.equal(b.provider.awareness.getStates().get(a.provider.doc.clientID).user.name, 'Another author');
    assert.deepEqual(b.events, []); assert.deepEqual(b.revisions, []);
  } finally { a.provider.destroy(); b.provider.destroy(); }
});

test('chunks support out-of-order delivery, duplicates and completed-message deduplication', () => {
  const receiver = new ChunkReceiver();
  const bytes = new Uint8Array(11000).fill(172), encoded = encode64(bytes), n = Math.ceil(encoded.length / CHUNK_SIZE);
  const parts = Array.from({ length: n }, (_, i) => ({ id: 'web-1', i, n, d: encoded.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE) }));
  assert.equal(receiver.accept(EVENTS.update, parts[2]), null);
  assert.equal(receiver.accept(EVENTS.update, parts[2]), null);
  assert.equal(receiver.accept(EVENTS.update, parts[0]), null);
  assert.deepEqual(receiver.accept(EVENTS.update, parts[1]), bytes);
  assert.equal(receiver.accept(EVENTS.update, parts[1]), null);
  assert.equal(receiver.pending.size, 0);
});

test('chunk validation bounds buffers, rejects conflicting metadata and expires incomplete data', () => {
  let now = 0; const receiver = new ChunkReceiver(() => now);
  const part = { id: 'one', i: 0, n: 2, d: 'AAAA' };
  for (const invalid of [{ ...part, n: 10000000 }, { ...part, i: -1 }, { ...part, i: 2 },
    { ...part, d: 'A'.repeat(CHUNK_SIZE + 1) }, { ...part, d: '<script>' }]) {
    assert.throws(() => receiver.accept(EVENTS.update, invalid), /invalid_chunk/);
  }
  receiver.accept(EVENTS.update, part);
  assert.throws(() => receiver.accept(EVENTS.update, { ...part, d: 'BBBB' }), /conflicting_chunk/);
  for (let i = 0; i < 32; i++) receiver.accept(EVENTS.update, { ...part, id: String(i) });
  assert.throws(() => receiver.accept(EVENTS.update, { ...part, id: 'overflow' }), /chunk_limit/);
  now = 300_001;
  assert.equal(receiver.accept(EVENTS.update, { ...part, id: 'after-expiry' }), null);
  assert.equal(receiver.pending.size, 1);
});

test('unknown remote nodes are rejected before altering the live document', () => {
  const a = client(document()), future = copy(a.provider.doc);
  try {
    const before = encode64(Y.encodeStateAsUpdate(a.provider.doc));
    future.getXmlFragment('default').push([new Y.XmlElement('futureEmbed')]);
    const data = encode64(Y.encodeStateAsUpdate(future));
    a.provider.receive(EVENTS.update, { id: 'future', i: 0, n: 1, d: data });
    assert.deepEqual(a.errors, ['unsupported_content']);
    assert.equal(encode64(Y.encodeStateAsUpdate(a.provider.doc)), before);
    assert.deepEqual(a.revisions, []);
  } finally { future.destroy(); a.provider.destroy(); }
});

test('task references, images and table attributes survive Yjs round trips', () => {
  const docContent = { type: 'doc', content: [
    { type: 'taskEmbed', attrs: { taskId: 'task-123' } },
    { type: 'taskListEmbed', attrs: { status: 'IN_PROGRESS', label: 'Equipo' } },
    { type: 'image', attrs: { src: 'https://example.com/image.png', alt: 'Reference', title: 'Draft' } },
    { type: 'table', content: [{ type: 'tableRow', content: [
      { type: 'tableHeader', attrs: { colspan: 1, rowspan: 1, colwidth: [180] }, content: [{ type: 'paragraph' }] },
      { type: 'tableCell', attrs: { colspan: 2, rowspan: 1, colwidth: [120, 160] }, content: [content.content[0]] }
    ] }] }
  ] };
  validateContent(docContent, schema);
  const doc = prosemirrorJSONToYDoc(schema, docContent, 'default');
  try { assert.deepEqual(schema.nodeFromJSON(contentFromDoc(doc, schema)).toJSON(), schema.nodeFromJSON(docContent).toJSON()); }
  finally { doc.destroy(); }
});

test('unknown node, mark or attribute cannot silently normalize into a supported document', () => {
  for (const child of [{ type: 'futureWidget' }, { type: 'paragraph', attrs: { futureAlignment: 'center' } },
    { type: 'paragraph', content: [{ type: 'text', text: 'x', marks: [{ type: 'futureMark' }] }] }]) {
    assert.throws(() => validateContent({ type: 'doc', content: [child] }, schema), /unsupported_content/);
  }
  assert.throws(() => decode64('not base64!'), /invalid_base64/);
});

test('snapshot limits match backend decoded5MiB and permit its base64 expansion', () => {
  const encoded = encode64(new Uint8Array(MAX_STATE_BYTES));
  assert.equal(encoded.length, MAX_STATE_CHARS);
  assert.equal(decode64(encoded).length, MAX_STATE_BYTES);
  assert.throws(() => decode64(encode64(new Uint8Array(MAX_STATE_BYTES + 1))), /invalid_base64/);
});

test('unknown Yjs root fragments are not silently presented as an empty note', () => {
  const doc = new Y.Doc();
  try {
    doc.getText('future-root').insert(0, 'Unrecognized content');
    assert.throws(() => contentFromDoc(doc, schema), /unsupported_content/);
  } finally { doc.destroy(); }
});
