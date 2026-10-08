import { Editor } from '@tiptap/core';
import Collaboration from '@tiptap/extension-collaboration';
import CollaborationCursor from '@tiptap/extension-collaboration-cursor';
import * as Y from 'yjs';
import { prosemirrorJSONToYDoc } from 'y-prosemirror';
import { NoteProtocol, decode64, encode64, MAX_STATE_BYTES } from './protocol.js';
import { baseExtensions, makeSchema, validateContent, contentFromDoc } from './schema.js';
import { createToolbarIcon } from './toolbar-icons.js';

const schema = makeSchema();
let nonce = null, editor = null, provider = null, labels = {}, failed = false, requestedEditable = false;
const toolbar = document.getElementById('toolbar'), status = document.getElementById('status');
const knownErrors = new Set(['invalid_base64', 'invalid_chunk', 'conflicting_chunk', 'chunk_limit',
  'document_too_large', 'invalid_content', 'unsupported_content', 'invalid_snapshot', 'already_initialized']);

function emit(message) {
  if (nonce) window.webkit?.messageHandlers?.projectNote?.postMessage({ nonce, ...message });
}
function fail(code) {
  // A rejected peer update never touched the live document. Preserve any recent local keystrokes
  // before native handles the error and disables snapshot acceptance. Failed initialization and
  // an invalid/oversized live document must never manufacture a recovery snapshot.
  let recovery = null;
  if (!failed && editor && provider?.active) {
    try { recovery = currentSnapshot(); } catch {}
  }
  failed = true; requestedEditable = false; editor?.setEditable(false);
  status.textContent = labels.error || ''; refreshToolbar();
  if (recovery) emit(recovery);
  emit({ type: 'error', code: knownErrors.has(code) ? code : 'invalid_snapshot' });
}
function userValue(user) {
  return { name: typeof user?.name === 'string' ? user.name : '',
    color: typeof user?.color === 'string' && /^#[0-9a-f]{6}$/i.test(user.color) ? user.color : '#686de0' };
}

const actions = [
  ['bold', 'bold', chain => chain.toggleBold()], ['italic', 'italic', chain => chain.toggleItalic()],
  ['bulletList', 'bulletList', chain => chain.toggleBulletList()],
  ['orderedList', 'orderedList', chain => chain.toggleOrderedList()],
  ['heading', 'heading', chain => chain.toggleHeading({ level: 2 })],
  ['undo', null, chain => chain.undo()], ['redo', null, chain => chain.redo()]
];
function refreshToolbar() {
  for (const [key, node] of actions) {
    const button = document.getElementById(`action-${key}`);
    if (!button) continue;
    button.title = labels[key] || '';
    button.setAttribute('aria-label', labels[key] || '');
    button.disabled = !editor || !requestedEditable || failed;
    if (node) button.setAttribute('aria-pressed', String(Boolean(editor?.isActive(node))));
  }
}
function configure(options = {}) {
  if (options.labels && typeof options.labels === 'object') labels = { ...labels, ...options.labels };
  if (options.user) provider?.setUser(userValue(options.user));
  if (options.status !== undefined) status.textContent = String(options.status);
  else status.textContent = failed ? labels.error || '' : editor ? requestedEditable ? '' : labels.readOnly || '' : labels.loading || '';
  refreshToolbar();
}

function initialize(options) {
  if (nonce) { emit({ type: 'error', code: 'already_initialized' }); return; }
  if (!options || typeof options.nonce !== 'string' || !options.nonce.length) return;
  nonce = options.nonce; configure(options);
  const snapshot = options.snapshot;
  let doc = new Y.Doc();
  try {
    // Missing/failed GET is distinct from an explicitly null, successfully loaded empty note.
    if (!snapshot || !Object.prototype.hasOwnProperty.call(snapshot, 'yjs_state') ||
        !Object.prototype.hasOwnProperty.call(snapshot, 'content')) throw new Error('invalid_snapshot');
    if (snapshot.yjs_state !== null) {
      Y.applyUpdate(doc, decode64(snapshot.yjs_state));
      contentFromDoc(doc, schema);
    } else {
      const content = validateContent(snapshot.content === null ? { type: 'doc', content: [] } : snapshot.content, schema);
      const seeded = prosemirrorJSONToYDoc(schema, content, 'default');
      Y.applyUpdate(doc, Y.encodeStateAsUpdate(seeded)); seeded.destroy();
    }
    provider = new NoteProtocol({ doc, user: userValue(options.user), emit,
      validate: candidate => contentFromDoc(candidate, schema),
      onChange: revision => emit({ type: 'dirty', revision }), onError: fail });
    editor = new Editor({ element: document.getElementById('editor'), editable: false,
      extensions: [...baseExtensions(() => labels), Collaboration.configure({ document: doc }),
        CollaborationCursor.configure({ provider, user: userValue(options.user) })],
      editorProps: { attributes: { spellcheck: 'true' } },
      onSelectionUpdate: refreshToolbar, onTransaction: refreshToolbar });
    provider.activate();
    status.textContent = labels.readOnly || ''; refreshToolbar();
    emit({ type: 'ready' });
  } catch (error) { provider?.destroy(); if (!provider) doc.destroy(); fail(error.message); }
}

function setEditable(value) {
  requestedEditable = Boolean(value) && Boolean(editor) && !failed;
  editor?.setEditable(requestedEditable);
  status.textContent = failed ? labels.error || '' : requestedEditable ? '' : labels.readOnly || '';
  refreshToolbar();
}

function currentSnapshot() {
  contentFromDoc(provider.doc, schema);
  const content = editor.getJSON(); validateContent(content, schema);
  const bytes = Y.encodeStateAsUpdate(provider.doc);
  if (bytes.length > MAX_STATE_BYTES) throw new Error('document_too_large');
  return { nonce, type: 'snapshot', revision: provider.revision,
    yjs_state: encode64(bytes), content };
}

function snapshot() {
  if (!editor || !provider || failed) return null;
  try { const message = currentSnapshot(); emit(message); return message; }
  catch (error) { fail(error.message); return null; }
}

for (const [key, , action] of actions) {
  const button = document.createElement('button'); button.id = `action-${key}`; button.type = 'button';
  button.className = 'toolbar-button';
  button.appendChild(createToolbarIcon(key, document));
  button.disabled = true;
  button.addEventListener('click', () => {
    if (editor && requestedEditable && !failed) { action(editor.chain().focus()).run(); refreshToolbar(); }
  });
  toolbar.appendChild(button);
}

window.projectNote = Object.freeze({ initialize, configure, setEditable, snapshot,
  receive: (event, payload) => { if (!failed) provider?.receive(event, payload); },
  subscribed: () => { if (!failed) provider?.subscribed(); },
  mergeSnapshot: state => !failed && Boolean(provider?.mergeSnapshot(state)),
  destroy: () => { editor?.destroy(); provider?.destroy(); editor = null; provider = null; } });
