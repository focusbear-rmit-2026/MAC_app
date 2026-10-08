import SwiftUI
import WebKit
import PusherSwift

enum ProjectNoteRequestAction {
    case load, save, authorize
    var method: String { self == .load ? "GET" : self == .save ? "PUT" : "POST" }
    static func path(identity: ProjectNoteIdentity, action: Self) -> String? {
        let safe = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard !identity.accountID.isEmpty,
              [identity.projectID, identity.noteID].allSatisfy({ !$0.isEmpty && $0.unicodeScalars.allSatisfy(safe.contains) }) else { return nil }
        return "\(ToDoEndpoint.projectNote(id: identity.projectID, noteId: identity.noteID))/\(action == .authorize ? "realtime-auth" : "doc")"
    }
}

/// Labels are bundled in English and Spanish, then overridden by the downloaded configuration.
struct ProjectNoteEditorStrings {
    static let defaults = [
        "loading": "Loading note…", "saved": "Saved", "saving": "Saving…",
        "offline": "Live connection interrupted. Edits are saved locally while reconnecting.",
        "saveFailed": "Could not save to the server. Your edits are saved on this Mac.",
        "localSaveFailed": "Could not save your edits locally. Keep this note open and retry.",
        "loadFailed": "Could not load this note. Retry to enable editing.",
        "unavailable": "You no longer have access to this note. Unsaved edits remain on this Mac.",
        "error": "This note contains content this editor cannot safely edit. Open it on the web.",
        "retry": "Retry", "readOnly": "Read only", "bold": "Bold", "italic": "Italic",
        "bulletList": "Bulleted list", "orderedList": "Numbered list", "heading": "Heading",
        "undo": "Undo", "redo": "Redo", "taskEmbed": "Linked task", "taskListEmbed": "Task list"
    ]
    let values: [String: String]
    init() {
        var values = Self.defaults
        let resource = BundledConfigLanguage.current()
        if let url = Bundle.main.url(forResource: resource, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let bundled = config["projectNoteEditor"] as? [String: String] { values.merge(bundled) { _, new in new } }
        if let remote = configjson["projectNoteEditor"] as? [String: String] { values.merge(remote) { _, new in new } }
        self.values = values
    }
    subscript(_ key: String) -> String { values[key] ?? Self.defaults[key] ?? "" }
}

struct ProjectNoteEditor: View {
    @StateObject private var session: ProjectNoteEditorSession
    init(identity: ProjectNoteIdentity) {
        _session = StateObject(wrappedValue: ProjectNoteEditorSession(identity: identity))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProjectNoteWebView(session: session)
                .frame(minHeight: 180, maxHeight: .infinity)
            HStack(spacing: 8) {
                Text(session.strings[session.status]).font(.system(size: 11))
                    .foregroundColor(session.hasError ? .red : .secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if session.hasError {
                    SwiftUI.Button(session.strings["retry"]) { session.retry() }
                        .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                }
            }
        }
    }
}

private struct ProjectNoteWebView: NSViewRepresentable {
    let session: ProjectNoteEditorSession
    func makeNSView(context: Context) -> WKWebView { session.makeWebView() }
    func updateNSView(_ view: WKWebView, context: Context) {}
    func makeCoordinator() -> ProjectNoteEditorSession { session }
    static func dismantleNSView(_ view: WKWebView, coordinator: ProjectNoteEditorSession) {
        coordinator.close()
    }
}

/// Each instance owns one immutable account/project/note identity. No credentials or HTTP requests
/// reach JavaScript. The bundled editor exchanges only Yjs updates, document snapshots and labels.
final class ProjectNoteEditorSession: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler, PusherDelegate, Authorizer {
    private final class WeakSession {
        weak var value: ProjectNoteEditorSession?
        init(_ value: ProjectNoteEditorSession) { self.value = value }
    }
    private static var activeEditors: [ProjectNoteIdentity: WeakSession] = [:]
    typealias Request = (ProjectNoteIdentity, ProjectNoteRequestAction, Data?, @escaping (Data?, Int) -> Void) -> Void
    let identity: ProjectNoteIdentity
    let strings = ProjectNoteEditorStrings()
    @Published private(set) var status = "loading"
    var hasError: Bool { ["loadFailed", "saveFailed", "localSaveFailed", "unavailable", "error"].contains(status) }
    private var nonce = UUID().uuidString
    private let drafts: ProjectNoteDraftStore
    private let request: Request
    private let accountID: () -> String
    private let useRealtime: Bool
    private var webView: WKWebView?
    private var editorURL: URL?
    private var predecessor: ProjectNoteEditorSession?
    private var pageLoaded = false
    private var pusher: Pusher?
    private var channel: PusherChannel?
    private var loaded = false
    private var ready = false
    private var closed = false
    private var closing = false
    private var closingSaveAttempts = 0
    private var subscribed = false
    private var accessRevoked = false
    private var editorFailed = false
    private var generation = 0
    private var snapshotWork: DispatchWorkItem?
    private var saveWork: DispatchWorkItem?
    private var pollTimer: Timer?
    private var outbound: ProjectNoteOutboundQueue
    private var pending: [String: Any]?
    private var pendingData: Data?
    private var ownedDraft: Data?
    private var recoveryState: String?
    private var savingRevision: Int?
    private var savedRevision = 0
    private var localSaveFailed = false
    private static let events = Set(["client-yjs-update", "client-yjs-awareness", "client-yjs-sync-request", "client-yjs-sync-reply"])
    private var currentAccount: Bool { !identity.accountID.isEmpty && accountID() == identity.accountID }

    init(identity: ProjectNoteIdentity, drafts: ProjectNoteDraftStore = ProjectNoteDraftStore(),
         accountID: @escaping () -> String = { appdelegate?.user?.userId ?? "" }, useRealtime: Bool = true,
         request: @escaping Request = { identity, action, body, completion in
             allApiObject.projectNoteDocumentRequest(identity: identity, action: action, body: body, completion: completion)
         }) {
        self.identity = identity; self.drafts = drafts; self.accountID = accountID
        self.useRealtime = useRealtime; self.request = request
        self.outbound = ProjectNoteOutboundQueue(identity: identity)
        super.init()
    }

    func makeWebView() -> WKWebView {
        // Two successive views for one note must not race final snapshots into the same recovery
        // file. The new view waits asynchronously for the previous editor's bounded final save.
        if let previous = Self.activeEditors[identity]?.value, previous !== self {
            predecessor = previous
            previous.close()
        }
        Self.activeEditors[identity] = WeakSession(self)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.add(self, name: "projectNote")
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        self.webView = view
        if let directory = Bundle.main.resourceURL?.appendingPathComponent("ProjectNoteEditorWeb", isDirectory: true).standardizedFileURL,
           FileManager.default.fileExists(atPath: directory.appendingPathComponent("index.html").path) {
            let url = directory.appendingPathComponent("index.html").standardizedFileURL
            editorURL = url
            view.loadFileURL(url, allowingReadAccessTo: directory)
        } else { status = "loadFailed" }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in self?.tick() }
        return view
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Note content cannot navigate the authenticated editor or load executable remote pages.
        decisionHandler(action.targetFrame?.isMainFrame == true && action.request.url?.standardizedFileURL == editorURL ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { pageLoaded = true; load() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { status = "loadFailed" }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        ready = false; loaded = false; pageLoaded = false; status = "loadFailed"
    }

    private func call(_ method: String, _ arguments: [Any] = [], completion: ((Any?, Error?) -> Void)? = nil) {
        guard let view = webView, let data = try? JSONSerialization.data(withJSONObject: arguments),
              let json = String(data: data, encoding: .utf8) else { return }
        view.evaluateJavaScript("window.projectNote.\(method)(...\(json))", completionHandler: completion)
    }

    private func load() {
        guard currentAccount, !closed, !closing, !loaded, pageLoaded else { return }
        if predecessor != nil {
            var previous = predecessor
            var inherited = recoveryState
            while let editor = previous {
                guard editor.closed else { return }
                inherited = inherited ?? editor.pending?["yjs_state"] as? String ?? editor.recoveryState
                previous = editor.predecessor
            }
            // A failed disk/server save can leave a fresher snapshot in memory. Carry it forward
            // instead of requiring the user to recover an older on-disk copy.
            recoveryState = inherited
            predecessor = nil
        }
        loaded = true // Also prevents a second GET while the first is in flight.
        generation += 1
        nonce = UUID().uuidString
        let requestGeneration = generation
        savedRevision = 0
        recoveryState = pending?["yjs_state"] as? String ?? recoveryState
        snapshotWork?.cancel(); saveWork?.cancel()
        pending = nil; pendingData = nil
        editorFailed = false
        status = "loading"
        request(identity, .load, nil) { [weak self] data, code in
            DispatchQueue.main.async {
                guard let self = self, self.currentAccount, !self.closed, self.generation == requestGeneration else { return }
                guard (200..<300).contains(code), let data = data, data.count <= ProjectNoteDraftStore.maxSnapshotBytes,
                      let snapshot = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      snapshot.keys.contains("yjs_state"), snapshot.keys.contains("content") else {
                    self.status = [401, 403, 404].contains(code) ? "unavailable" : "loadFailed"
                    return
                }
                self.call("initialize", [["nonce": self.nonce, "labels": self.strings.values,
                                           "user": ["name": appdelegate?.user?.name ?? "", "color": "#D56B19"],
                                           "snapshot": snapshot]]) { [weak self] _, error in
                    if error != nil { self?.status = "error" }
                }
            }
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, message.frameInfo.request.url?.standardizedFileURL == editorURL,
              currentAccount, !closed, let body = message.body as? [String: Any],
              body["nonce"] as? String == nonce, let type = body["type"] as? String else { return }
        switch type {
        case "ready":
            guard loaded, !ready else { return }
            ready = true
            let draft = drafts.load(identity: identity)
            ownedDraft = draft
            let snapshot = draft.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            if let state = recoveryState ?? snapshot?["yjs_state"] as? String {
                let editorGeneration = generation
                call("mergeSnapshot", [state]) { [weak self] result, error in
                    guard let self = self, self.currentAccount, !self.closed, self.generation == editorGeneration else { return }
                    guard error == nil, result as? Bool == true, !self.editorFailed else {
                        self.editorFailed = true; self.status = "error"; return
                    }
                    self.recoveryState = nil
                    self.enableEditor()
                }
            } else { enableEditor() }
        case "dirty":
            guard ready, !editorFailed else { return }
            if !accessRevoked { status = localSaveFailed ? "localSaveFailed" : "saving" }
            snapshotWork?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.call("snapshot") }
            snapshotWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        case "snapshot": acceptSnapshot(body)
        case "event":
            guard !closing, !accessRevoked, !editorFailed, let event = body["event"] as? String, Self.events.contains(event),
                  let data = body["data"] as? [String: Any],
                  let encoded = try? JSONSerialization.data(withJSONObject: data), encoded.count <= 10_000 else { return }
            // Offline updates live in the Y.Doc/draft. subscribed() advertises the full merged state.
            guard subscribed else { return }
            guard outbound.enqueue(event: event, payload: encoded, identity: identity) == .accepted else {
                call("snapshot"); subscribed = false; status = "offline"
                pusher?.disconnect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self = self, self.currentAccount, !self.closed else { return }
                    self.pusher?.connect()
                }
                return
            }
        case "error":
            editorFailed = true
            status = "error"
            call("setEditable", [false])
        default: break
        }
    }

    private func enableEditor() {
        guard currentAccount, !closed, !closing, !editorFailed, !accessRevoked else { return }
        call("setEditable", [true])
        status = pending == nil ? "offline" : "saving"
        connect()
    }

    private func acceptSnapshot(_ body: [String: Any]) {
        guard currentAccount, ready, !editorFailed, let revision = body["revision"] as? Int,
              revision > savedRevision, let state = body["yjs_state"] as? String,
              let content = body["content"] as? [String: Any] else { return }
        let snapshot: [String: Any] = ["revision": revision, "yjs_state": state, "content": content]
        guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]),
              (try? ProjectNoteDraftStore.revision(in: data)) != nil else {
            status = "localSaveFailed"; return
        }
        pending = snapshot
        pendingData = data
        do {
            if closing {
                guard try drafts.save(data, identity: identity, replacing: ownedDraft) else {
                    localSaveFailed = true; status = "localSaveFailed"
                    scheduleSave(after: 0)
                    return
                }
            } else { try drafts.save(data, identity: identity) }
            ownedDraft = data
            localSaveFailed = false
        }
        catch { localSaveFailed = true; status = "localSaveFailed" }
        scheduleSave(after: 2.5)
    }

    private func scheduleSave(after delay: TimeInterval) {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.save() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func save() {
        if closing && closingSaveAttempts >= 3 {
            // A continuously edited shared note must not keep the next view waiting forever.
            // The latest merged snapshot remains recoverable and the next editor reloads/merges it.
            finishClose()
            return
        }
        guard currentAccount, !closed, ready, !accessRevoked, !editorFailed, savingRevision == nil,
              let snapshot = pending, let revision = snapshot["revision"] as? Int,
              let draftData = pendingData,
              let body = try? JSONSerialization.data(withJSONObject: ["yjs_state": snapshot["yjs_state"]!, "content": snapshot["content"]!]) else { return }
        savingRevision = revision
        if closing { closingSaveAttempts += 1 }
        let requestGeneration = generation
        if !localSaveFailed { status = "saving" }
        // Retain a closing editor through its final save; any failure leaves the durable draft.
        request(identity, .save, body) { [self] data, code in
            DispatchQueue.main.async {
                guard self.currentAccount else { self.savingRevision = nil; self.disconnect(); if self.closing { self.finishClose() }; return }
                guard self.generation == requestGeneration else {
                    self.savingRevision = nil
                    if self.pending != nil { self.scheduleSave(after: 0) }
                    return
                }
                guard (200..<300).contains(code), let data = data, data.count <= ProjectNoteDraftStore.maxSnapshotBytes,
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let merged = response["yjs_state"] as? String, !merged.isEmpty,
                      merged.utf8.count <= ProjectNoteDraftStore.maxYjsStateBase64Length,
                      Data(base64Encoded: merged) != nil else {
                    self.savingRevision = nil
                    self.accessRevoked = [401, 403, 404].contains(code)
                    self.status = self.accessRevoked ? "unavailable" : self.localSaveFailed ? "localSaveFailed" : "saveFailed"
                    if self.accessRevoked { self.call("setEditable", [false]); self.disconnect() }
                    else if !self.closing { self.scheduleSave(after: 10) }
                    if self.closing { self.finishClose() }
                    return
                }
                // Accept the merged Yjs state before acknowledging the recovery copy. Keep the
                // detached editor alive during close: the backend stores our content projection,
                // so a merge with another client's edits needs one more coherent snapshot save.
                self.call("mergeSnapshot", [merged]) { [self] result, error in
                    guard self.currentAccount, self.generation == requestGeneration else {
                        self.savingRevision = nil
                        if self.closing { self.finishClose() }
                        return
                    }
                    guard error == nil, result as? Bool == true, !self.editorFailed else {
                        self.savingRevision = nil; self.editorFailed = true; self.status = "error"
                        if self.closing { self.finishClose() }
                        return
                    }
                    self.savedRevision = revision
                    self.call("snapshot") { [self] value, error in
                        self.savingRevision = nil
                        guard self.currentAccount, self.generation == requestGeneration,
                              error == nil, let value = value as? [String: Any] else {
                            if self.closing { self.finishClose() }
                            return
                        }
                        self.acceptSnapshot(value)
                        if self.pending?["revision"] as? Int == revision {
                            self.pending = nil; self.pendingData = nil
                            try? self.drafts.remove(identity: self.identity, matching: draftData)
                            self.ownedDraft = nil
                            self.localSaveFailed = false
                            self.status = self.subscribed ? "saved" : "offline"
                        }
                        if self.pending != nil { self.scheduleSave(after: self.closing ? 0 : 2.5) }
                        else if self.closing { self.finishClose() }
                    }
                }
            }
        }
    }

    func retry() {
        guard currentAccount, !closed, !closing else { return }
        if !ready || editorFailed || accessRevoked {
            generation += 1
            nonce = UUID().uuidString
            snapshotWork?.cancel(); saveWork?.cancel()
            disconnect()
            accessRevoked = false; loaded = false; ready = false; pageLoaded = false
            webView?.reload()
        } else {
            call("snapshot"); save()
            if pusher == nil { connect() } else { pusher?.connect() }
        }
    }

    private func connect() {
        guard currentAccount, !closed, !closing, pusher == nil, useRealtime else { return }
        let client = Pusher(key: "e6efc69cb17b6816c56c",
                            options: PusherClientOptions(authMethod: .authorizer(authorizer: self), host: .cluster("mt1")))
        pusher = client
        client.delegate = self
        let channel = client.subscribe("presence-project-note-\(identity.noteID)")
        self.channel = channel
        for name in Self.events {
            channel.bind(eventName: name) { [weak self] event in
                DispatchQueue.main.async {
                    guard let self = self, self.currentAccount, !self.closed, self.ready, !self.accessRevoked, !self.editorFailed,
                          let raw = event.data, let data = raw.data(using: .utf8), data.count <= 10_000,
                          let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                    self.call("receive", [name, payload])
                }
            }
        }
        client.connect()
    }

    func fetchAuthValue(socketID: String, channelName: String, completionHandler: @escaping (PusherAuth?) -> Void) {
        guard currentAccount, !closed, channelName == "presence-project-note-\(identity.noteID)",
              let body = try? JSONSerialization.data(withJSONObject: ["socket_id": socketID]) else { completionHandler(nil); return }
        let requestGeneration = generation
        request(identity, .authorize, body) { [weak self] data, code in
            DispatchQueue.main.async {
                guard let self = self, self.currentAccount, !self.closed, self.generation == requestGeneration else { completionHandler(nil); return }
                guard (200..<300).contains(code), let data = data,
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let auth = response["auth"] as? String else {
                    if [401, 403, 404].contains(code) {
                        self.call("snapshot")
                        self.accessRevoked = true; self.status = "unavailable"; self.call("setEditable", [false]); self.disconnect()
                    } else { self.status = "offline" }
                    completionHandler(nil); return
                }
                completionHandler(PusherAuth(auth: auth, channelData: response["channel_data"] as? String))
            }
        }
    }

    func subscribedToChannel(name: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.currentAccount, !self.closed, !self.accessRevoked, !self.editorFailed,
                  name == "presence-project-note-\(self.identity.noteID)" else { return }
            self.subscribed = true
            self.outbound.resumeAfterResync()
            if !self.hasError { self.status = self.pending == nil ? "saved" : "saving" }
            self.call("subscribed")
        }
    }
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.closed else { return }
            if new != .connected {
                self.subscribed = false; self.outbound.markRequiresResync()
                if self.ready && !self.hasError { self.status = "offline" }
            }
        }
    }
    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.hasError else { return }
            self.status = "offline"
        }
    }

    private func tick() {
        guard currentAccount, !closed else {
            call("setEditable", [false])
            // Remove the previous account's content immediately; its disk recovery remains scoped.
            webView?.evaluateJavaScript("document.body.replaceChildren()", completionHandler: nil)
            status = "unavailable"; disconnect(); pollTimer?.invalidate(); return
        }
        if pageLoaded, !loaded, !closing { load() }
        if subscribed, !accessRevoked, !editorFailed,
           let next = outbound.next(at: ProcessInfo.processInfo.systemUptime, identity: identity),
           let payload = try? JSONSerialization.jsonObject(with: next.payload) {
            channel?.trigger(eventName: next.event, data: payload)
        }
    }
    private func disconnect() {
        subscribed = false; outbound.markRequiresResync()
        pusher?.unbindAll(); pusher?.unsubscribeAll(); pusher?.disconnect(); pusher?.delegate = nil
        channel = nil; pusher = nil
    }

    func close() {
        guard !closed, !closing else { return }
        closing = true
        snapshotWork?.cancel(); saveWork?.cancel(); pollTimer?.invalidate()
        disconnect()
        call("setEditable", [false])
        // Keep the web view and session alive until the last keystroke has been snapshotted.
        let finish: (Any?, Error?) -> Void = { [self] value, _ in
            if let snapshot = value as? [String: Any], self.currentAccount { self.acceptSnapshot(snapshot) }
            self.saveWork?.cancel()
            self.save()
            if self.savingRevision == nil { self.finishClose() }
        }
        if ready && currentAccount { call("snapshot", completion: finish) } else { finish(nil, nil) }
    }

    private func finishClose() {
        closed = true
        if Self.activeEditors[identity]?.value === self { Self.activeEditors.removeValue(forKey: identity) }
        snapshotWork?.cancel(); saveWork?.cancel()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "projectNote")
        webView?.navigationDelegate = nil
        webView = nil
    }
}
