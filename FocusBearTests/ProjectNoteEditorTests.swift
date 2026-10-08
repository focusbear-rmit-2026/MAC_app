import XCTest
import WebKit
@testable import Focus_Bear

final class ProjectNoteEditorTests: XCTestCase {
    private let identity = ProjectNoteIdentity(accountID: "account-a", projectID: "project-a", noteID: "note-a")

    func testDocumentEndpointsRejectPathInjectionAndKeepDocumentAndAuthorizationSeparate() {
        XCTAssertEqual(ProjectNoteRequestAction.path(identity: identity, action: .load), "/projects/project-a/notes/note-a/doc")
        XCTAssertEqual(ProjectNoteRequestAction.path(identity: identity, action: .save), "/projects/project-a/notes/note-a/doc")
        XCTAssertEqual(ProjectNoteRequestAction.path(identity: identity, action: .authorize), "/projects/project-a/notes/note-a/realtime-auth")
        for id in ["../other", "note?admin=true", "note#fragment", "note%2Fother", ""] {
            XCTAssertNil(ProjectNoteRequestAction.path(identity: .init(accountID: "a", projectID: "p", noteID: id), action: .save))
        }
        XCTAssertEqual(ProjectNoteRequestAction.save.method, "PUT")
        XCTAssertEqual(ProjectNoteRequestAction.authorize.method, "POST")
    }

    func testBundledEditorLoadsSnapshotWithoutSavingAnUntouchedNote() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var writes = 0
        let session = ProjectNoteEditorSession(identity: identity, drafts: ProjectNoteDraftStore(directory: directory),
                                              accountID: { "account-a" }, useRealtime: false) { _, action, _, completion in
            if action == .load { completion(self.serverSnapshot(), 200) }
            else { writes += 1; completion(nil, 500) }
        }
        let view = makeTestWebView(session)
        waitUntil { session.status == "offline" || session.hasError }
        XCTAssertEqual(session.status, "offline")
        XCTAssertTrue((evaluate("document.body.innerText", in: view) as? String)?.contains("Existing note") == true)
        let snapshot = evaluate("window.projectNote.snapshot()", in: view) as? [String: Any]
        XCTAssertNotNil(snapshot?["yjs_state"] as? String)
        XCTAssertEqual(snapshot?["revision"] as? Int, 0)
        session.close()
        waitUntil { view.navigationDelegate == nil }
        XCTAssertEqual(writes, 0, "Opening and closing a note must not mutate its body")
    }

    func testFailedInitialLoadNeverEnablesEditingOrSendsASnapshot() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var writes = 0
        let session = ProjectNoteEditorSession(identity: identity, drafts: ProjectNoteDraftStore(directory: directory),
                                              accountID: { "account-a" }, useRealtime: false) { _, action, _, completion in
            if action != .load { writes += 1 }
            completion(nil, 503)
        }
        let view = makeTestWebView(session)
        waitUntil { session.status == "loadFailed" }
        XCTAssertEqual(evaluate("!!document.querySelector('[contenteditable=\"true\"]')", in: view) as? Bool, false)
        session.close()
        XCTAssertEqual(writes, 0)
    }

    func testAccountSwitchDiscardsAnInFlightDocumentResponse() {
        var account = "account-a"
        var respond: ((Data?, Int) -> Void)?
        let session = ProjectNoteEditorSession(identity: identity, accountID: { account }, useRealtime: false) { _, _, _, completion in
            respond = completion
        }
        let view = makeTestWebView(session)
        waitUntil { respond != nil }
        account = "account-b"
        respond?(serverSnapshot(), 200)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertNotEqual(session.status, "offline")
        XCTAssertFalse((evaluate("document.body.innerText", in: view) as? String)?.contains("Existing note") == true)
        session.close()
    }

    func testForeignChannelAuthorizationNeverReachesTheAPI() {
        var calls = 0
        let session = ProjectNoteEditorSession(identity: identity, accountID: { "account-a" }, useRealtime: false) { _, _, _, _ in calls += 1 }
        let result = expectation(description: "Authorization rejected")
        session.fetchAuthValue(socketID: "12.34", channelName: "presence-project-note-other") { value in
            XCTAssertNil(value); result.fulfill()
        }
        wait(for: [result], timeout: 1)
        XCTAssertEqual(calls, 0)
        session.close()
    }

    func testAllEditorLabelsHaveBundledEnglishAndSpanishTranslations() throws {
        for name in ["config", "config-es"] {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "json"))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            let labels = try XCTUnwrap(json["projectNoteEditor"] as? [String: String])
            XCTAssertEqual(Set(labels.keys), Set(ProjectNoteEditorStrings.defaults.keys))
            XCTAssertTrue(labels.values.allSatisfy { !$0.isEmpty })
        }
    }

    func testInvalidDurableYjsMergeRemainsReadOnlyAndPreservesRecoveryCopy() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory)
        // Canonical base64 and valid transport shape, but an incomplete Yjs varint. The native
        // draft validator cannot detect this semantic corruption; the real editor must reject it.
        let invalidDraft = try JSONSerialization.data(withJSONObject: [
            "revision": 4, "yjs_state": Data([0xff, 0xff, 0xff]).base64EncodedString(),
            "content": ["type": "doc", "content": []]
        ], options: [.sortedKeys])
        try drafts.save(invalidDraft, identity: identity)
        var writes = 0
        let session = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                              accountID: { "account-a" }, useRealtime: false) { _, action, _, completion in
            if action == .load { completion(self.serverSnapshot(), 200) }
            else { writes += 1; completion(nil, 500) }
        }
        let view = makeTestWebView(session)
        defer { session.close() }
        waitUntil { session.status == "error" }
        XCTAssertEqual(evaluate("!!document.querySelector('[contenteditable=\"true\"]')", in: view) as? Bool, false)
        XCTAssertEqual(evaluate("Array.from(document.querySelectorAll('#toolbar button')).every(button => button.disabled)", in: view) as? Bool, true)
        XCTAssertTrue(evaluate("window.projectNote.snapshot() === null", in: view) as? Bool == true)
        XCTAssertEqual(drafts.load(identity: identity), invalidDraft)
        XCTAssertEqual(writes, 0, "A failed recovery merge must never save the server-only document over the draft")
    }

    func testRealTextEditSavesCRDTAndContentThenClearsOnlyTheAcknowledgedDraft() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory)
        var bodies: [Data] = []
        let session = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                              accountID: { "account-a" }, useRealtime: false) { requestedIdentity, action, body, completion in
            XCTAssertEqual(requestedIdentity, self.identity)
            if action == .load { completion(self.serverSnapshot(), 200) }
            else if action == .save, let body = body { bodies.append(body); completion(body, 200) }
            else { XCTFail("Unexpected realtime authorization in an isolated editor"); completion(nil, 500) }
        }
        let view = makeTestWebView(session)
        defer { session.close() }
        waitUntil { session.status == "offline" || session.hasError }
        XCTAssertFalse(session.hasError)
        let original = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: view) as? [String: Any])
        appendText(" — locally edited", in: view)
        let edited = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: view) as? [String: Any])
        XCTAssertGreaterThan(edited["revision"] as? Int ?? 0, 0)
        waitUntil { drafts.load(identity: self.identity) != nil || session.hasError }
        XCTAssertFalse(session.hasError)
        waitUntil { bodies.count == 1 && drafts.load(identity: self.identity) == nil }
        let request = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(bodies.first)) as? [String: Any])
        XCTAssertEqual(Set(request.keys), ["yjs_state", "content"], "Editor-local revision/identity metadata must not leak into the document PUT")
        let state = try XCTUnwrap(request["yjs_state"] as? String)
        XCTAssertFalse(try XCTUnwrap(Data(base64Encoded: state)).isEmpty)
        XCTAssertNotEqual(state, original["yjs_state"] as? String)
        XCTAssertEqual(state, edited["yjs_state"] as? String)
        XCTAssertEqual(documentText(request["content"]), "Existing note — locally edited")
        session.close()
        waitUntil { view.navigationDelegate == nil }
        XCTAssertEqual(bodies.count, 1, "Closing an already acknowledged note must not repeat its PUT")
    }

    func testAccountChangeWithPendingEditsStopsSavesAndKeepsOriginalAccountsDraft() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory)
        var account = "account-a"
        var writes = 0
        let session = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                              accountID: { account }, useRealtime: false) { _, action, _, completion in
            if action == .load { completion(self.serverSnapshot(), 200) }
            else { writes += 1; completion(nil, 500) }
        }
        let view = makeTestWebView(session)
        defer { session.close() }
        waitUntil { session.status == "offline" || session.hasError }
        XCTAssertFalse(session.hasError)
        appendText(" private account-a edit", in: view)
        _ = evaluate("window.projectNote.snapshot()", in: view)
        waitUntil { drafts.load(identity: self.identity) != nil }
        let savedDraft = try XCTUnwrap(drafts.load(identity: identity))
        account = "account-b"
        session.retry()
        let authRejected = expectation(description: "Changed account cannot authorize the old note")
        session.fetchAuthValue(socketID: "12.34", channelName: "presence-project-note-note-a") { auth in
            XCTAssertNil(auth); authRejected.fulfill()
        }
        wait(for: [authRejected], timeout: 1)
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        XCTAssertEqual(evaluate("!!document.querySelector('[contenteditable=\"true\"]')", in: view) as? Bool, false)
        XCTAssertFalse((evaluate("document.body.innerText", in: view) as? String)?.contains("private account-a edit") == true)
        session.close()
        waitUntil { view.navigationDelegate == nil }
        XCTAssertEqual(writes, 0, "The pending debounce, retry, authorization and closing flush must all respect the original account")
        XCTAssertEqual(drafts.load(identity: identity), savedDraft)
        XCTAssertNil(drafts.load(identity: .init(accountID: "account-b", projectID: identity.projectID, noteID: identity.noteID)))
    }

    func testFirstEditAfterReloadIsSavedEvenWhenPreviousDocumentHadHigherRevisions() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory)
        var server = serverSnapshot()
        var loads = 0
        var bodies: [Data] = []
        let session = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                              accountID: { "account-a" }, useRealtime: false) { _, action, body, completion in
            if action == .load { loads += 1; completion(server, 200) }
            else if action == .save, let body = body { bodies.append(body); server = body; completion(body, 200) }
            else { XCTFail("Unexpected authorization"); completion(nil, 500) }
        }
        let view = makeTestWebView(session)
        defer { session.close() }
        waitUntil { session.status == "offline" || session.hasError }
        XCTAssertFalse(session.hasError)
        appendText(" first", in: view)
        appendText(" second", in: view)
        appendText(" third", in: view)
        let before = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: view) as? [String: Any])
        XCTAssertGreaterThan(before["revision"] as? Int ?? 0, 1)
        waitUntil { bodies.count == 1 && drafts.load(identity: self.identity) == nil }

        // Invoke the same public delegate path WebKit uses after process termination, then let
        // Retry perform an actual bundled-document reload with a fresh JS revision counter.
        session.webViewWebContentProcessDidTerminate(view)
        session.retry()
        waitUntil { loads == 2 && session.status == "offline" }
        appendText(" after reload", in: view)
        let after = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: view) as? [String: Any])
        XCTAssertGreaterThan(after["revision"] as? Int ?? 0, 0)
        XCTAssertLessThanOrEqual(after["revision"] as? Int ?? 0, before["revision"] as? Int ?? 0)
        waitUntil { bodies.count == 2 && drafts.load(identity: self.identity) == nil }
        let request = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(bodies.last)) as? [String: Any])
        XCTAssertEqual(documentText(request["content"]), "Existing note first second third after reload")
    }

    func testFinalCloseRegeneratesContentFromServerMergedYjsBeforeReleasingEditor() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory.appendingPathComponent("local"))
        var bodies: [Data] = []
        var respondToFirstSave: ((Data?, Int) -> Void)?
        let local = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                            accountID: { "account-a" }, useRealtime: false) { _, action, body, completion in
            if action == .load { completion(self.serverSnapshot(), 200) }
            else if action == .save, let body = body {
                bodies.append(body)
                if bodies.count == 1 { respondToFirstSave = completion }
                else { completion(body, 200) }
            } else { XCTFail("Unexpected authorization"); completion(nil, 500) }
        }
        let localView = makeTestWebView(local)
        defer {
            respondToFirstSave?(nil, 503)
            respondToFirstSave = nil
            local.close()
            waitUntil { localView.navigationDelegate == nil }
        }
        waitUntil { local.status == "offline" || local.hasError }
        XCTAssertFalse(local.hasError)
        let base = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: localView) as? [String: Any])
        let sharedBase = try JSONSerialization.data(withJSONObject: ["yjs_state": XCTUnwrap(base["yjs_state"]),
                                                                   "content": XCTUnwrap(base["content"])])

        // A second actual Yjs editor starts from the same document lineage. Its separate note ID
        // avoids native view-replacement behavior while it models the backend's concurrent merge.
        let peerIdentity = ProjectNoteIdentity(accountID: identity.accountID, projectID: identity.projectID, noteID: "peer-fixture")
        let peer = ProjectNoteEditorSession(identity: peerIdentity,
                                           drafts: ProjectNoteDraftStore(directory: directory.appendingPathComponent("peer")),
                                           accountID: { "account-a" }, useRealtime: false) { _, action, body, completion in
            if action == .load { completion(sharedBase, 200) }
            else if action == .save { completion(body, 200) }
            else { XCTFail("Unexpected authorization"); completion(nil, 500) }
        }
        let peerView = makeTestWebView(peer)
        defer { peer.close(); waitUntil { peerView.navigationDelegate == nil } }
        waitUntil { peer.status == "offline" || peer.hasError }
        XCTAssertFalse(peer.hasError)
        appendText(" LOCAL", in: localView)
        appendText(" REMOTE", in: peerView)
        let localSnapshot = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: localView) as? [String: Any])
        let encodedArguments = try JSONSerialization.data(withJSONObject: [XCTUnwrap(localSnapshot["yjs_state"])])
        let arguments = try XCTUnwrap(String(data: encodedArguments, encoding: .utf8))
        XCTAssertEqual(evaluate("window.projectNote.mergeSnapshot(...\(arguments))", in: peerView) as? Bool, true)
        let merged = try XCTUnwrap(evaluate("window.projectNote.snapshot()", in: peerView) as? [String: Any])
        let mergedText = documentText(merged["content"])
        XCTAssertTrue(mergedText.contains("LOCAL"))
        XCTAssertTrue(mergedText.contains("REMOTE"))
        local.close()
        waitUntil { respondToFirstSave != nil }
        XCTAssertNotNil(localView.navigationDelegate, "The closing editor must stay alive while its save is unresolved")
        let first = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(bodies.first)) as? [String: Any])
        XCTAssertTrue(documentText(first["content"]).contains("LOCAL"))
        XCTAssertFalse(documentText(first["content"]).contains("REMOTE"))
        // This matches the backend: it merges Yjs state but initially stores the submitted,
        // potentially stale, content projection. The closing editor must correct that projection.
        let response = try JSONSerialization.data(withJSONObject: ["yjs_state": XCTUnwrap(merged["yjs_state"]),
                                                                 "content": XCTUnwrap(first["content"])])
        let respond = try XCTUnwrap(respondToFirstSave)
        respondToFirstSave = nil
        respond(response, 200)
        waitUntil { localView.navigationDelegate == nil }
        XCTAssertEqual(bodies.count, 2, "A final server merge needs exactly one stable projection follow-up")
        let final = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(bodies.last)) as? [String: Any])
        XCTAssertEqual(documentText(final["content"]), mergedText)
        XCTAssertNil(drafts.load(identity: identity), "Release the recovery copy only after the merged content is acknowledged")
    }

    func testRapidReopeningWaitsThroughAClosedIntermediateEditorUntilOriginalSaveFinishes() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let drafts = ProjectNoteDraftStore(directory: directory)
        var server = serverSnapshot()
        var heldBody: Data?
        var respondToFirstSave: ((Data?, Int) -> Void)?
        var firstSaves = 0
        let first = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                            accountID: { "account-a" }, useRealtime: false) { _, action, body, completion in
            if action == .load { completion(server, 200) }
            else if action == .save {
                firstSaves += 1
                heldBody = body
                respondToFirstSave = completion
            } else { XCTFail("Unexpected authorization"); completion(nil, 500) }
        }
        let firstView = makeTestWebView(first)
        defer {
            respondToFirstSave?(nil, 503)
            respondToFirstSave = nil
            first.close()
            waitUntil { firstView.navigationDelegate == nil }
        }
        waitUntil { first.status == "offline" || first.hasError }
        XCTAssertFalse(first.hasError)
        appendText(" first editor's final edit", in: firstView)
        _ = evaluate("window.projectNote.snapshot()", in: firstView)
        first.close()
        waitUntil { respondToFirstSave != nil }
        var middleLoads = 0
        let middle = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                             accountID: { "account-a" }, useRealtime: false) { _, action, _, completion in
            if action == .load { middleLoads += 1; completion(server, 200) }
            else { XCTFail("The superseded waiting editor must never write"); completion(nil, 500) }
        }
        let middleView = makeTestWebView(middle)
        defer { middle.close(); waitUntil { middleView.navigationDelegate == nil } }
        var finalLoads = 0
        let final = ProjectNoteEditorSession(identity: identity, drafts: drafts,
                                            accountID: { "account-a" }, useRealtime: false) { _, action, _, completion in
            if action == .load {
                finalLoads += 1
                XCTAssertNil(firstView.navigationDelegate, "The replacement's GET must wait for the original closing save, through the intermediate predecessor")
                completion(server, 200)
            } else { XCTFail("The untouched replacement must never write"); completion(nil, 500) }
        }
        let finalView = makeTestWebView(final)
        defer { final.close(); waitUntil { finalView.navigationDelegate == nil } }
        waitUntil { middleView.navigationDelegate == nil && finalView.url != nil && !finalView.isLoading }
        XCTAssertEqual(evaluate("typeof window.projectNote?.initialize === 'function'", in: finalView) as? Bool, true,
                       "The bundled replacement page must actually be ready for the load-barrier assertion")
        // Let the 150ms native load-poll run more than once while the original PUT is held.
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        XCTAssertEqual(middleLoads, 0)
        XCTAssertEqual(finalLoads, 0)
        XCTAssertNotNil(firstView.navigationDelegate)
        XCTAssertEqual(evaluate("!!document.querySelector('[contenteditable=\"true\"]')", in: finalView) as? Bool, false)
        server = try XCTUnwrap(heldBody)
        let respond = try XCTUnwrap(respondToFirstSave)
        respondToFirstSave = nil
        respond(server, 200)
        waitUntil { finalLoads == 1 && final.status == "offline" }
        XCTAssertEqual(middleLoads, 0)
        XCTAssertEqual(firstSaves, 1)
        XCTAssertTrue((evaluate("document.querySelector('.tiptap')?.textContent", in: finalView) as? String)?.contains("first editor's final edit") == true)
        XCTAssertNil(drafts.load(identity: identity))
    }

    /// SwiftUI supplies a viewport in production. A zero-sized standalone WKWebView can suspend
    /// page/bootstrap work, so every native fixture gets a real layout without showing a window.
    private func makeTestWebView(_ session: ProjectNoteEditorSession) -> WKWebView {
        let view = session.makeWebView()
        view.frame = NSRect(x: 0, y: 0, width: 600, height: 400)
        view.layoutSubtreeIfNeeded()
        return view
    }

    /// Browser editing APIs drive the real ProseMirror input/DOM observer path. No production
    /// bridge mutator, OS event, app window activation, or live API is needed.
    private func appendText(_ text: String, in view: WKWebView, file: StaticString = #filePath, line: UInt = #line) {
        let encoded = try! JSONSerialization.data(withJSONObject: [text])
        let arguments = String(data: encoded, encoding: .utf8)!
        let inserted = evaluate("""
            (() => {
                const editor = document.querySelector('.tiptap[contenteditable="true"]');
                if (!editor) return false;
                editor.focus();
                const range = document.createRange(); range.selectNodeContents(editor); range.collapse(false);
                const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
                return document.execCommand('insertText', false, \(arguments)[0]);
            })()
            """, in: view, file: file, line: line)
        XCTAssertEqual(inserted as? Bool, true, "Synthetic text insertion must reach the real editable document", file: file, line: line)
        // ProseMirror observes the edit at the next microtask before another JS evaluation.
        XCTAssertTrue((evaluate("document.querySelector('.tiptap')?.textContent", in: view, file: file, line: line) as? String)?.contains(text) == true,
                      file: file, line: line)
    }

    private func documentText(_ value: Any?) -> String {
        guard let node = value as? [String: Any] else { return "" }
        if let text = node["text"] as? String { return text }
        return (node["content"] as? [[String: Any]] ?? []).map { documentText($0) }.joined()
    }

    private func serverSnapshot() -> Data {
        try! JSONSerialization.data(withJSONObject: ["yjs_state": NSNull(), "content": ["type": "doc", "content": [["type": "paragraph", "content": [["type": "text", "text": "Existing note"]]]]]])
    }
    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ProjectNoteEditorTests-" + UUID().uuidString)
    }
    private func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool, file: StaticString = #filePath, line: UInt = #line) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.02)) }
        XCTAssertTrue(condition(), "Timed out waiting for the local editor", file: file, line: line)
    }
    private func evaluate(_ script: String, in view: WKWebView, file: StaticString = #filePath, line: UInt = #line) -> Any? {
        var finished = false
        var value: Any?
        view.evaluateJavaScript(script) { result, error in
            XCTAssertNil(error, file: file, line: line); value = result; finished = true
        }
        waitUntil { finished }
        return value
    }
}
