//
//  RelevanceShadowLogger.swift
//  FocusBear
//
//  Shadow-mode integration for the website-relevance model
//  (Focus-Bear-research/FocusBear-Distraction-Detection-Model#18): runs the model
//  alongside the existing AI URL check, purely for observation — it never affects
//  the real block/allow decision. Every check is logged to relevance-shadow.jsonl;
//  entries where the model's tier disagrees with the existing dProbability-derived
//  decision are what a future disagreement-rate analysis would read.
//
//  DEV-ONLY FOR NOW: the model's Python process (torch + sentence-transformers +
//  xgboost + sklearn) isn't bundled with the app yet — packaging it the way
//  FocusBear/server is (a signed, committed PyInstaller binary) is a separate,
//  sizeable follow-up given how much heavier this dependency set is. Point
//  FB_RELEVANCE_MODEL_PYTHON and FB_RELEVANCE_MODEL_SCRIPT at a local checkout's
//  venv + deployment/predict_server.py to exercise this; with either unset the
//  feature no-ops (logs once, does nothing further) rather than failing loudly for
//  everyone who doesn't have the model checked out.
//

import Foundation

/// One JSON request/response per line over stdin/stdout — see predict_server.py in
/// Focus-Bear-research/FocusBear-Distraction-Detection-Model (deployment/).
private struct RelevanceShadowRequest: Encodable {
    let focus_intention: String
    let tab_title: String
    let current_task: String
    let url: String
}

private struct RelevanceShadowResult: Decodable {
    let tier: Int?
    let label: String?
    let action: String?
    let confidence: Double?
    let cosine_similarity: Double?
    let confidence_gate_passed: Bool?
    let llm_fallback_required: Bool?
    let error: String?
}

/// Launches and owns the long-lived `predict_server.py` subprocess, and serializes
/// requests to it one at a time — the stdin/stdout protocol is strictly one response
/// per line, in request order, so a second request must never be written before the
/// first request's response has been read back.
final class RelevanceShadowService {
    static let shared = RelevanceShadowService()

    private let queue = DispatchQueue(label: "relevance.shadow.service")
    private var process: Process?
    private var stdinHandle: FileHandle?
    private var stdoutHandle: FileHandle?
    private var stdoutBuffer = Data()
    private var isUnavailable = false   // sticky once true: missing env vars, or the process died

    private init() {}

    /// Predicts the relevance tier for `tabTitle`/`url` against `focusIntention`/`currentTask`.
    /// Fire-and-forget from the caller's side: `completion` always runs on this service's
    /// background queue (never the caller's thread) and never throws — a missing/broken
    /// subprocess just completes with `nil`, so callers never need error-handling here.
    /// `fileprivate`, not `internal`: its signature carries `RelevanceShadowResult`, which is
    /// private to this file — call it only via `logRelevanceShadowCheck` below (same file).
    fileprivate func predict(focusIntention: String, tabTitle: String, currentTask: String, url: String,
                             completion: @escaping (RelevanceShadowResult?) -> Void) {
        queue.async { [weak self] in
            guard let self = self, self.ensureRunning(),
                  let stdinHandle = self.stdinHandle, let stdoutHandle = self.stdoutHandle else {
                completion(nil)
                return
            }
            let request = RelevanceShadowRequest(focus_intention: focusIntention, tab_title: tabTitle,
                                                 current_task: currentTask, url: url)
            guard let requestLine = self.encodeLine(request) else {
                completion(nil)
                return
            }
            do {
                try stdinHandle.write(contentsOf: requestLine)
            } catch {
                addLog(text: "RelevanceShadowService: stdin write failed, tearing down: \(error.localizedDescription)")
                self.tearDown()
                completion(nil)
                return
            }
            guard let responseLine = self.readLine(from: stdoutHandle),
                  let result = try? JSONDecoder().decode(RelevanceShadowResult.self, from: responseLine) else {
                completion(nil)
                return
            }
            completion(result)
        }
    }

    // MARK: - Process lifecycle (call only on `queue`)

    private func ensureRunning() -> Bool {
        if let process = process, process.isRunning { return true }
        if isUnavailable { return false }

        let env = ProcessInfo.processInfo.environment
        guard let pythonPath = env["FB_RELEVANCE_MODEL_PYTHON"], !pythonPath.isEmpty,
              let scriptPath = env["FB_RELEVANCE_MODEL_SCRIPT"], !scriptPath.isEmpty,
              FileManager.default.isExecutableFile(atPath: pythonPath),
              FileManager.default.fileExists(atPath: scriptPath) else {
            isUnavailable = true
            addLog(text: "RelevanceShadowService: FB_RELEVANCE_MODEL_PYTHON/FB_RELEVANCE_MODEL_SCRIPT not set (or invalid) — shadow logging disabled for this run.")
            return false
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = [scriptPath]
        proc.currentDirectoryURL = URL(fileURLWithPath: scriptPath).deletingLastPathComponent()

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardInput = stdin
        proc.standardOutput = stdout
        proc.standardError = stderr

        proc.terminationHandler = { [weak self] terminated in
            self?.queue.async {
                addLog(text: "RelevanceShadowService: subprocess exited (code \(terminated.terminationStatus))")
                self?.process = nil
                self?.stdinHandle = nil
                self?.stdoutHandle = nil
            }
        }

        do {
            try proc.run()
        } catch {
            isUnavailable = true
            addLog(text: "RelevanceShadowService: failed to launch: \(error.localizedDescription)")
            return false
        }

        // Block this background queue until the model finishes loading (~8-9s) so the
        // first real predict() doesn't race a subprocess that isn't reading stdin yet.
        // Uses its own local buffer — must fully finish (and stop reading stderr) before
        // the continuous drain below starts, or the two would race for the same bytes.
        var stderrStartupBuffer = Data()
        let readyLine = readLine(from: stderr.fileHandleForReading, buffer: &stderrStartupBuffer)
        guard let readyLine = readyLine, String(data: readyLine, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) == "ready" else {
            addLog(text: "RelevanceShadowService: subprocess didn't signal ready — tearing down.")
            proc.terminate()
            isUnavailable = true
            return false
        }

        // Now drain stderr continuously on its own thread so the child never blocks on a
        // full pipe for any later error output — logs are diagnostic only from here on.
        DispatchQueue.global(qos: .utility).async {
            let handle = stderr.fileHandleForReading
            while true {
                let data = handle.availableData
                if data.isEmpty { break }   // EOF: process exited
                if let text = String(data: data, encoding: .utf8) {
                    addLog(text: "RelevanceShadowService (stderr): \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
                }
            }
        }

        process = proc
        stdinHandle = stdin.fileHandleForWriting
        stdoutHandle = stdout.fileHandleForReading
        addLog(text: "RelevanceShadowService: subprocess ready")
        return true
    }

    private func tearDown() {
        process?.terminate()
        process = nil
        stdinHandle = nil
        stdoutHandle = nil
        stdoutBuffer.removeAll()
    }

    // MARK: - Line framing helpers

    private func encodeLine<T: Encodable>(_ value: T) -> Data? {
        guard var data = try? JSONEncoder().encode(value) else { return nil }
        data.append(0x0A)   // '\n'
        return data
    }

    /// Blocks (on `queue`) until a full newline-terminated line is available, buffering
    /// any extra bytes read past the newline for the next call. Returns nil on EOF.
    private func readLine(from handle: FileHandle) -> Data? {
        readLine(from: handle, buffer: &stdoutBuffer)
    }

    private func readLine(from handle: FileHandle, buffer: inout Data) -> Data? {
        while true {
            if let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let line = buffer[..<newlineIndex]
                buffer.removeSubrange(...newlineIndex)
                return Data(line)
            }
            let chunk = handle.availableData
            if chunk.isEmpty { return nil }   // EOF
            buffer.append(chunk)
        }
    }
}

// MARK: - Comparison + JSONL logging

private let relevanceShadowJsonlURL: URL? = applicationSupportURL?.appendingPathComponent("relevance-shadow.jsonl")
private var relevanceShadowLogger: CSVLogger?

/// Runs the shadow model against the same signal the existing AI URL check just used,
/// and appends one JSONL entry recording whether they agree. Purely observational —
/// this never influences `existingProbability` or any blocking decision. Safe to call
/// on the main thread: the actual model call and file write both happen off it.
func logRelevanceShadowCheck(focusIntention: String, tabTitle: String, currentTask: String,
                              url: String, existingProbability: Double) {
    let existingDecision = existingProbability >= 0.70 ? "allow" : "block"
    // Native ONNX model (RelevanceShadowNativeModel) — produces a real prediction for every check,
    // unlike the dev-only Python predict_server path it replaces. Runs off the main thread. The
    // TextCNN+cosine model is binary (relevant / not), so it maps straight onto the existing
    // allow/block decision — no tier/caution/low-confidence buckets. `current_task` is still logged
    // for offline re-scoring, but (matching how the model was trained) only `focus_intention` +
    // `tab_title` feed the model.
    RelevanceShadowNativeModel.shared.predict(focusIntention: focusIntention, tabTitle: tabTitle) { prediction in
        var entry: [String: Any] = [
            "timestamp": getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss"),
            "focus_intention": focusIntention,
            "current_task": currentTask,
            "tab_title": tabTitle,
            "url": url,
            "existing_probability": existingProbability,
            "existing_decision": existingDecision,
        ]

        guard let prediction = prediction else {
            entry["agreement"] = "unavailable"   // model still downloading / loading this session
            appendRelevanceShadowEntry(entry)
            return
        }
        let modelDecision = prediction.isRelevant ? "allow" : "block"
        entry["model_label"] = prediction.isRelevant ? "Relevant" : "Not Relevant"
        entry["model_action"] = modelDecision
        entry["model_confidence"] = Double(prediction.confidence)
        entry["model_cosine"] = Double(prediction.cosine)
        entry["model_source"] = "onnx-textcnn-cosine"
        entry["agreement"] = modelDecision == existingDecision ? "agree" : "disagree"
        appendRelevanceShadowEntry(entry)
    }
}

private func appendRelevanceShadowEntry(_ entry: [String: Any]) {
    guard let url = relevanceShadowJsonlURL,
          let data = try? JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys]),
          let line = String(data: data, encoding: .utf8) else { return }
    if relevanceShadowLogger == nil {
        relevanceShadowLogger = CSVLogger(fileURL: url)
    }
    relevanceShadowLogger?.append(line: line + "\n")
}
