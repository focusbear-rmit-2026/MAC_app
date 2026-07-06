//
//  FocusButtonCommandChannel.swift
//  Focus Bear
//
//  A tiny local command channel so ANOTHER process (e.g. a firmware flashing tool / agent) can ask the
//  Mac app to release or re-grab the Focus Button serial port without touching the launch agent or the
//  user's blocking session. Poll-based on a file, so it's trivially triggerable from a shell.
//
//  Protocol — files under ~/.focusbear/ :
//    • Write one word into `focus-button-command`:
//        disconnect  → app closes the serial port and STAYS disconnected (frees /dev/cu.usbmodem*)
//        reconnect   → app reconnects and resumes normal auto-reconnect
//        status      → no-op; just refreshes focus-button-status
//    • The app consumes (deletes) the command file and writes `focus-button-status`:
//        line 1: disconnected | connected | connecting
//        line 2: the connected port path (empty when disconnected)
//        line 3: unix epoch seconds of the update
//
//  Reflash recipe for an external tool:
//    printf disconnect > ~/.focusbear/focus-button-command
//    # poll ~/.focusbear/focus-button-status until line 1 == "disconnected" (allow ~1s for the port to free)
//    esptool ... upload ...
//    printf reconnect  > ~/.focusbear/focus-button-command
//

import Foundation

final class FocusButtonCommandChannel {
    static let shared = FocusButtonCommandChannel()
    private init() {}

    private let dir = (NSHomeDirectory() as NSString).appendingPathComponent(".focusbear")
    private var commandPath: String { (dir as NSString).appendingPathComponent("focus-button-command") }
    private var statusPath: String { (dir as NSString).appendingPathComponent("focus-button-status") }

    private var timer: Timer?
    private let pollInterval: TimeInterval = 1.0

    /// Begin watching for commands. Idempotent; call once at app launch (main thread).
    func start() {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        // Don't act on a command left over from before launch — clear it, then publish current status.
        try? FileManager.default.removeItem(atPath: commandPath)
        writeStatus()
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        t.tolerance = pollInterval / 2
        timer = t
        addLog(text: "FocusButtonCommandChannel: watching \(commandPath)")
    }

    private func poll() {
        guard let raw = try? String(contentsOfFile: commandPath, encoding: .utf8) else { return }
        let cmd = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Consume the command up front so a slow action can't cause it to run twice.
        try? FileManager.default.removeItem(atPath: commandPath)

        switch cmd {
        case "disconnect":
            addLog(text: "FocusButtonCommandChannel: external disconnect request")
            focusButtonServiceObject.manualDisconnect()
        case "reconnect", "connect":
            addLog(text: "FocusButtonCommandChannel: external reconnect request")
            focusButtonServiceObject.manualReconnect()
        case "", "status":
            break
        default:
            addLog(text: "FocusButtonCommandChannel: ignoring unknown command '\(cmd)'")
        }
        // Give a disconnect a beat to actually release the port before we report status.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.writeStatus() }
    }

    private func writeStatus() {
        let state: String
        if focusButtonServiceObject.isManuallyDisconnected {
            state = "disconnected"
        } else if focusButtonServiceObject.isRunning {
            state = "connected"
        } else {
            state = "connecting"
        }
        let port = focusButtonServiceObject.connectedPortPath ?? ""
        let epoch = Int(Date().timeIntervalSince1970)
        let body = "\(state)\n\(port)\n\(epoch)\n"
        try? body.write(toFile: statusPath, atomically: true, encoding: .utf8)
    }
}
