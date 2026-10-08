import * as Y from 'yjs';
import { Awareness, applyAwarenessUpdate, encodeAwarenessUpdate } from 'y-protocols/awareness';

export const EVENTS = Object.freeze({ update: 'client-yjs-update', awareness: 'client-yjs-awareness',
  request: 'client-yjs-sync-request', reply: 'client-yjs-sync-reply' });
export const CHUNK_SIZE = 7000;
export const MAX_STATE_BYTES = 5 * 1024 * 1024;
export const MAX_STATE_CHARS = Math.ceil(MAX_STATE_BYTES / 3) * 4;
const MAX_CHUNKS = Math.ceil(MAX_STATE_CHARS / CHUNK_SIZE);
const MAX_ASSEMBLIES = 32;
const MAX_BUFFERED_CHARS = 8 * 1024 * 1024;
// A maximal document takes almost three minutes at the native six-events/second budget.
const TTL = 5 * 60_000;

export function encode64(bytes) {
  let binary = '';
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}

export function decode64(value) {
  if (typeof value !== 'string' || !value.length || value.length > MAX_STATE_CHARS ||
      value.length % 4 !== 0 || !/^[A-Za-z0-9+/]*={0,2}$/.test(value)) throw new Error('invalid_base64');
  const binary = atob(value);
  if (binary.length > MAX_STATE_BYTES || btoa(binary) !== value) throw new Error('invalid_base64');
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}

/** Bounded, duplicate-safe assemblies. Event namespaces cannot complete one another's chunks. */
export class ChunkReceiver {
  constructor(now = () => Date.now()) { this.now = now; this.pending = new Map(); this.completed = new Map(); }
  prune() {
    const cutoff = this.now() - TTL;
    for (const [key, entry] of this.pending) if (entry.created <= cutoff) this.pending.delete(key);
    for (const [key, created] of this.completed) if (created <= cutoff) this.completed.delete(key);
  }
  accept(event, message) {
    this.prune();
    if (!message || typeof message.id !== 'string' || !message.id.length || message.id.length > 128 ||
        !Number.isInteger(message.n) || message.n < 1 || message.n > MAX_CHUNKS ||
        !Number.isInteger(message.i) || message.i < 0 || message.i >= message.n ||
        typeof message.d !== 'string' || !message.d.length || message.d.length > CHUNK_SIZE ||
        !/^[A-Za-z0-9+/]*={0,2}$/.test(message.d)) throw new Error('invalid_chunk');
    const key = `${event}:${message.id}`;
    if (this.completed.has(key)) return null;
    let entry = this.pending.get(key);
    if (entry && (entry.count !== message.n || (entry.parts.has(message.i) && entry.parts.get(message.i) !== message.d))) {
      this.pending.delete(key); throw new Error('conflicting_chunk');
    }
    if (!entry) {
      if (this.pending.size >= MAX_ASSEMBLIES) throw new Error('chunk_limit');
      entry = { created: this.now(), count: message.n, parts: new Map() };
      this.pending.set(key, entry);
    }
    entry.parts.set(message.i, message.d);
    let buffered = 0;
    for (const assembly of this.pending.values()) for (const part of assembly.parts.values()) buffered += part.length;
    if (buffered > MAX_BUFFERED_CHARS) { this.pending.delete(key); throw new Error('chunk_limit'); }
    if (entry.parts.size !== entry.count) return null;
    this.pending.delete(key);
    const bytes = decode64(Array.from({ length: entry.count }, (_, i) => entry.parts.get(i)).join(''));
    if (this.completed.size >= 256) this.completed.delete(this.completed.keys().next().value);
    this.completed.set(key, this.now());
    return bytes;
  }
  clear() { this.pending.clear(); this.completed.clear(); }
}

export class NoteProtocol {
  constructor({ doc, emit, validate, onChange, onError, user }) {
    this.doc = doc; this.emit = emit; this.validate = validate; this.onChange = onChange; this.onError = onError;
    this.awareness = new Awareness(doc); this.chunks = new ChunkReceiver(); this.revision = 0;
    this.counter = 0; this.pending = []; this.timer = null; this.active = false; this.destroyed = false;
    this.awareness.setLocalStateField('user', user);
    this.updated = (update, origin) => {
      if (!this.active || this.destroyed) return;
      this.revision += 1; this.onChange(this.revision);
      if (origin === this) return;
      this.pending.push(update);
      if (!this.timer) this.timer = setTimeout(() => { this.timer = null; this.flush(); }, 150);
    };
    this.awarenessUpdated = (changes, origin) => {
      if (!this.active || this.destroyed || origin === this) return;
      this.send(EVENTS.awareness, { u: encode64(encodeAwarenessUpdate(this.awareness,
        [...changes.added, ...changes.updated, ...changes.removed])) });
    };
    doc.on('update', this.updated); this.awareness.on('update', this.awarenessUpdated);
  }
  activate() { this.active = true; }
  send(event, data) { if (this.active && !this.destroyed) this.emit({ type: 'event', event, data }); }
  broadcast(event, bytes) {
    const base64 = encode64(bytes), n = Math.ceil(base64.length / CHUNK_SIZE);
    if (base64.length > MAX_STATE_CHARS) throw new Error('document_too_large');
    const id = `${this.doc.clientID}-${++this.counter}`;
    for (let i = 0; i < n; i++) this.send(event, { id, i, n, d: base64.slice(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE) });
  }
  flush() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
    if (!this.pending.length) return;
    const updates = this.pending; this.pending = [];
    try { this.broadcast(EVENTS.update, Y.mergeUpdates(updates)); } catch (error) { this.onError(error.message); }
  }
  subscribed() {
    if (!this.active || this.destroyed) return;
    try {
      this.send(EVENTS.request, { sv: encode64(Y.encodeStateVector(this.doc)) });
      // Also advertise restored/offline content: existing peers need not reconnect to request it.
      this.broadcast(EVENTS.update, Y.encodeStateAsUpdate(this.doc));
      this.send(EVENTS.awareness, { u: encode64(encodeAwarenessUpdate(this.awareness, [this.doc.clientID])) });
    } catch (error) { this.onError(error.message); }
  }
  apply(bytes) {
    // Validate on a disposable replica before the editor's Yjs plugin can normalize unknown nodes.
    const candidate = new Y.Doc();
    try {
      Y.applyUpdate(candidate, Y.encodeStateAsUpdate(this.doc));
      Y.applyUpdate(candidate, bytes);
      this.validate(candidate);
      Y.applyUpdate(this.doc, bytes, this);
    } finally { candidate.destroy(); }
  }
  mergeSnapshot(state) {
    if (!this.active || this.destroyed) return false;
    try { this.apply(decode64(state)); return true; }
    catch (error) { this.onError(error.message); return false; }
  }
  receive(event, payload) {
    if (!this.active || this.destroyed) return;
    try {
      if (event === EVENTS.update || event === EVENTS.reply) {
        const bytes = this.chunks.accept(event, payload);
        if (bytes) this.apply(bytes);
      } else if (event === EVENTS.request) {
        this.broadcast(EVENTS.reply, Y.encodeStateAsUpdate(this.doc, decode64(payload?.sv)));
      } else if (event === EVENTS.awareness) {
        applyAwarenessUpdate(this.awareness, decode64(payload?.u), this);
      }
    } catch (error) { this.onError(error.message); }
  }
  setUser(user) { this.awareness.setLocalStateField('user', user); }
  destroy() {
    this.destroyed = true; this.active = false;
    if (this.timer) clearTimeout(this.timer);
    this.pending = []; this.chunks.clear();
    this.doc.off('update', this.updated); this.awareness.off('update', this.awarenessUpdated);
    this.awareness.destroy(); this.doc.destroy();
  }
}
