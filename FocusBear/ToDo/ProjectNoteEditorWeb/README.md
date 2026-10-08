# Native project-note editor

The checked-in bundle implements the same `default` Yjs fragment and Pusher client-event wire format as web dashboard `origin/feat/project-notes-realtime-3062` (`src/services/project-note-realtime.ts`, `useRealtimeNoteEditor.ts`, and `embeds/noteEmbedExtensions.ts`). Native code owns authentication, account/note lifetime, Pusher subscription and rate limiting, durable drafts, save debounce/retry, and final-close reconciliation. This JavaScript never opens a network connection.

Only `Resources/ProjectNoteEditorWeb` belongs in the app's Copy Bundle Resources phase. Load `ProjectNoteEditorWeb/index.html` from the app resource URL. Do not copy this package root, source, tests or `node_modules` into the app.

## Native bridge

Messages use `window.webkit.messageHandlers.projectNote.postMessage`. Every message includes the initialization nonce; native must reject stale nonces. JavaScript must be invoked with safely serialized JSON, never interpolated note text.

- `initialize({nonce, labels, user:{name,color}, snapshot:{yjs_state,content}})`: initialize once per web-view lifetime from a successful scoped GET. Both snapshot keys are required; explicit null state permits validated JSON seeding, while missing/corrupt state fails closed. Yjs state is authoritative over companion JSON. Emits `ready` after successful read-only load; revision starts at zero and initialization does not emit dirty.
- `setEditable(bool)`: native enables after `ready` and successful draft merge. A failed document cannot be re-enabled. Offline editing is permitted after a valid initial load; native reports connection/save status honestly.
- `mergeSnapshot(yjs_state)`: apply a validated durable draft or server-merged save response. Returns true for success/noop, false on failure. A changed document emits dirty; remote origin prevents echo.
- `receive(event,payload)`: receive one native Pusher client event. `subscribed()` sends a state-vector request, current-document advertisement (including restored offline edits) and awareness.
- `snapshot()`: returns and emits the same `{nonce,type:'snapshot',revision,yjs_state,content}` object; returns null on failure. Native can use the evaluation callback for final-close flush. Native must merge any server response containing additional CRDT edits and reconcile its rendered content projection before discarding an editor with unresolved saves.
- `configure({labels,user,status})`: update supplied localized strings, cursor identity or visible status. `destroy()` tears down editor/document/awareness timers. Use a new web view for a new account or note.

Outgoing types: `ready`; `dirty` with monotonic `revision` (local or remote changes); `snapshot`; `event` with `event`/`data`; and `error` with stable `code`. Errors contain no note content, credentials or server response text. Native must inspect merge results rather than overwrite a failed state with a connected/editable status.

Before reporting a protocol error, an initialized editor emits its last validated live snapshot, preserving edits still waiting for native's 300 ms draft debounce. This precedes the error message so native can save that recovery copy before disabling snapshot acceptance. Failed initialization or an invalid live document never emits a fabricated snapshot.

Labels supplied by native: `bold`, `italic`, `bulletList`, `orderedList`, `heading`, `undo`, `redo`, `taskEmbed`, `taskListEmbed`, `loading`, `readOnly`, `error`. Toolbar buttons use local SVG formatting icons; their tooltips and accessible names use these translated labels. Icons are hidden from assistive technology, and existing pressed, disabled and keyboard-focus states remain on the buttons. All visible status/embed copy comes from these strings or document content. Task embeds are preserved reference blocks; task fetching and editing remains in native project UI.

## Protocol and preservation

- `client-yjs-update` and `client-yjs-sync-reply`: `{id,i,n,d}` with at most 7000 base64 characters per chunk. Local updates merge over 150 ms; native rate-limits outgoing events.
- `client-yjs-sync-request`: `{sv}`; `client-yjs-awareness`: `{u}`. Both use standard Yjs/y-protocols binary encodings in base64. Remote updates/awareness never echo.
- Assemblies are bounded to 32 simultaneous messages and 8 MiB buffered characters, deduplicated, and expire after 5 minutes. This allows a maximal 999-chunk state at native six events per second. State limits match backend 5 MiB decoded / 6,990,508 base64 characters.
- StarterKit (history disabled for collaborative undo), image, table/cell/header/row, taskEmbed.taskId and taskListEmbed.status/label match the frontend schema. Unknown nodes, marks, attributes and root fragments fail before the live editor can normalize them away. An incoming update is validated on a disposable document replica before applying it to the live document.
- CSP permits only local scripts/styles and HTTPS/data images. No external script, fetch, websocket, token or inline executable JavaScript is present.

## Reproducible build and tests

Dependencies are exact versions, with transitive Tiptap versions pinned to the source web lockfile. `package-lock.json` pins the full install. Node 22 was used for validation.

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm run build
npm test
npm run check-bundle
```

The build emits the minified Safari 14-compatible bundle and third-party notices into the runtime resource folder. `check-bundle` rebuilds in memory and requires byte-for-byte agreement. Node/jsdom tests exercise concurrent document convergence, reconnect/draft recovery, awareness/no echo, chunk validation/dedup/expiry/limits, full schema preservation, initialization/edit gating, snapshot return values and invalid-state failures. They make no API calls and do not launch the Mac app.

The Tiptap notice in `licenses/tiptap.txt` comes from its npm 2.27.2 gitHead `4b8d4e9434cdaf624d1c982f3b99f95d1359b4e1` (`ueberdosis/tiptap/LICENSE.md`); npm omits that file from individual extension packages. Other runtime notices are collected from the exact installed packages used by esbuild.
