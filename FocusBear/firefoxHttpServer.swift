//
//  webSocketServer.swift
//  FocusBear
//
//  Created by Manish Jain on 25/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


// Swifter package added for this

import Cocoa
import Swifter

class firefoxHttpServer {

    private let server = HttpServer()
    private let stateLock = NSLock()
    private var storedTabURL: String?
    private var storedTabTitle = ""
    private var storedPendingMessage: [String: Any]?
    private var pendingAuthorization: (() -> Bool)?
    private var managedTarget: ManagedBrowserObservation?
    private var pendingManagedId: String?
    private var pendingManagedCompletion: ((Bool) -> Void)?
    private var navigationProtocolVersion = 0
    private var lastCapabilityUptime: TimeInterval = -.infinity
    var supportsManagedNavigation: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return navigationProtocolVersion == 2 && ProcessInfo.processInfo.systemUptime - lastCapabilityUptime < 5
    }

    var managedObservation: ManagedBrowserObservation? {
        stateLock.lock(); defer { stateLock.unlock() }
        guard navigationProtocolVersion == 2, ProcessInfo.processInfo.systemUptime - lastCapabilityUptime < 5 else { return nil }
        return managedTarget
    }

    private func receiveCapabilities(_ version: Int, observation: [String: Any]?) {
        stateLock.lock(); defer { stateLock.unlock() }
        navigationProtocolVersion = version; lastCapabilityUptime = ProcessInfo.processInfo.systemUptime
        if let value = observation, let url = value["url"] as? String, url.count <= 16384,
           let window = value["window_id"] as? Int, let tab = value["tab_id"] as? Int {
            managedTarget = ManagedBrowserObservation(url: url, title: value["title"] as? String, windowId: window, tabId: tab)
            storedTabURL = url; storedTabTitle = value["title"] as? String ?? ""
        } else { managedTarget = nil }
    }
    var currentTabUrl: String? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedTabURL }
        set { stateLock.lock(); defer { stateLock.unlock() }; storedTabURL = newValue }
    }
    var currentTabTitle: String {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedTabTitle }
        set { stateLock.lock(); defer { stateLock.unlock() }; storedTabTitle = newValue }
    }
    var pendingMessage: [String: Any]? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return storedPendingMessage }
        set { stateLock.lock(); defer { stateLock.unlock() }; if pendingManagedId == nil { storedPendingMessage = newValue; pendingAuthorization = nil } }
    }

    private func takePendingMessage() -> [String: Any]? {
        stateLock.lock()
        let message = storedPendingMessage; storedPendingMessage = nil
        let authorization = pendingAuthorization; pendingAuthorization = nil
        stateLock.unlock()
        if authorization?() == false { return nil }
        if message?["action"] as? String == "unblock_now", let url = message?["url"] as? String,
           ManagedBlockingRuntime.shared.shouldDeferLegacyURL(url) { return nil }
        return message
    }

    func sendManagedNavigation(url: String, expectedURL: String, target: ManagedBrowserObservation?, authorization: @escaping () -> Bool) -> Bool {
        guard !Thread.isMainThread, let target = target, authorization() else { return false }
        let completed = DispatchSemaphore(value: 0)
        let resultLock = NSLock()
        var applied = false
        let requestId = UUID().uuidString
        stateLock.lock()
        guard navigationProtocolVersion == 2, ProcessInfo.processInfo.systemUptime - lastCapabilityUptime < 5,
              storedTabURL == expectedURL, managedTarget?.windowId == target.windowId,
              managedTarget?.tabId == target.tabId, pendingManagedId == nil else { stateLock.unlock(); return false }
        storedPendingMessage = ["action": "managed_navigate", "url": url, "expected_url": expectedURL,
            "window_id": target.windowId, "tab_id": target.tabId, "request_id": requestId]
        pendingAuthorization = authorization
        pendingManagedId = requestId
        pendingManagedCompletion = { value in
            resultLock.lock(); applied = value; resultLock.unlock(); completed.signal()
        }
        stateLock.unlock()
        let status = completed.wait(timeout: .now() + 3)
        stateLock.lock()
        if pendingManagedId == requestId {
            pendingManagedId = nil; pendingManagedCompletion = nil
            storedPendingMessage = nil; pendingAuthorization = nil
        }
        stateLock.unlock()
        resultLock.lock(); defer { resultLock.unlock() }
        return status == .success && applied
    }

    private func finishManagedNavigation(_ json: [String: Any]) {
        stateLock.lock()
        guard let id = json["request_id"] as? String, id == pendingManagedId else { stateLock.unlock(); return }
        let completion = pendingManagedCompletion
        pendingManagedCompletion = nil; pendingManagedId = nil
        stateLock.unlock()
        completion?(json["applied"] as? Bool == true)
    }
    func start() {
        // A fixed port the installed app is already listening on; a UI-test build must not compete.
        if UITestHost.suppressesEnforcement { return }
        print("Starting FocusBear Local HTTP Server on 50502")

        // POST /check_url  << this acts like "handle WebSocket message"
        server["/check_url"] = { request in
            guard self.isLocalExtensionRequest(request) else { return HttpResponse.badRequest(nil) }
            let body = request.body
//            guard let body = request.body else {
//                return HttpResponse.badRequest(nil)
//            }

            let bodyString = String(decoding: body, as: UTF8.self)
            // Page data is evaluated in memory; never add it to diagnostic logs.

            guard
                let jsonData = bodyString.data(using: .utf8),
                let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
            else {
                return HttpResponse.badRequest(nil)
            }

            // 🔥 Call central handler (WebSocket-style)
            let responseDict = self.handleWebSocketMessage(dict)

            // Encode and return
            let data = try! JSONSerialization.data(withJSONObject: responseDict)

            return HttpResponse.raw(
                200,
                "OK",
                ["Content-Type": "application/json"]
            ) { writer in
                try? writer.write(data)
            }
        }

   // ------------------------------------------------------
        // NEW ENDPOINT (Swift → Extension)
        // Extension will call this every 300ms or 500ms.
        // ------------------------------------------------------
        server["/push"] = { request in
            guard self.isLocalExtensionRequest(request) else { return HttpResponse.badRequest(nil) }
            let capabilities = (try? JSONSerialization.jsonObject(with: Data(request.body))) as? [String: Any]
            self.receiveCapabilities(capabilities?["managed_navigation_version"] as? Int ?? 0, observation: capabilities?["observation"] as? [String: Any])
            if let msg = self.takePendingMessage() {
                let data = try! JSONSerialization.data(withJSONObject: msg)

                // Managed messages may contain exact URLs; keep them out of logs.

                return HttpResponse.raw(
                    200, "OK", ["Content-Type": "application/json"]
                ) { writer in
                    try writer.write(data)
                }
            } else {
                // No message — tell extension "nothing"
                return HttpResponse.raw(
                    204, "No Content", [:]
                ) { _ in }
            }
        }
        
        do {
            server.listenAddressIPv4 = "127.0.0.1"
            try server.start(50502, forceIPv4: true)
            print("Local server ready")
        } catch {
            print("Error starting local server:", error)
        }
    }

    private func isLocalExtensionRequest(_ request: HttpRequest) -> Bool {
        guard request.body.count <= 32768,
              ["127.0.0.1:50502", "localhost:50502"].contains(request.headers["host"] ?? "") else { return false }
        // Firefox extension origins are opaque install IDs. Ordinary website origins cannot read or inject observations.
        if let origin = request.headers["origin"] { return origin.hasPrefix("moz-extension://") }
        return true
    }

    func stop() {
        server.stop()
        print("HTTP server stopped")
    }

    // ----------------------------------------------------------
    // MARK: - WEBSOCKET-LIKE MESSAGE HANDLER
    // ----------------------------------------------------------

    /// This processes messages just like your NWWebSocket server did.
    func handleWebSocketMessage(_ json: [String: Any]) -> [String: Any] {

        guard let action = json["action"] as? String else {
            return ["error": "missing action"]
        }

        switch action {

        case "check_url":
            guard let url = json["url"] as? String else {
                return ["error": "missing url"]
            }
            let title = json["title"] as? String ?? ""
            
            currentTabUrl = url
            currentTabTitle = title
            
            ManagedBlockingRuntime.shared.checkCurrentBrowserNow()
            // Observation acknowledgement only. Managed navigation is conditional and delivered by /push.
            return ["action": ManagedBlockingRuntime.shared.hasManagedIdentity ? "managed_pending" : "allow"]

        case "managed_navigation_result":
            finishManagedNavigation(json)
            return ["action": "ack"]

        case "ping":
            return ["action": "pong"]

        default:
            return ["error": "unknown action: \(action)"]
        }
    }
    
    // -------------------------------------------------------------------
   // MARK: - NEW: Swift → Extension Messaging
   // -------------------------------------------------------------------

   /// Swift calls this to send a message to extension
   func sendToExtension(_ json: [String: Any]) {
       // Messages can contain full website URLs; never log them.
       pendingMessage = json
   }

   /// Special helper to block a URL
    func sendBlockNow(url: String, params: String? = nil) {
       var msg: [String: Any] = [
           "action": "block_now",
           "url": url
       ]
        if let p = params { msg["params"] = p.removingPercentEncoding ?? p }
      // msg["params"] = """
        //                    "old_url=focus_mode" & "&version=\(appVersion)"
          //                  """
      //  msg["params"] = params

       sendToExtension(msg)
   }

    func sendUnBlockNow(url: String, params: String? = nil) {
       guard !ManagedBlockingRuntime.shared.shouldDeferLegacyURL(url) else { return }
       var msg: [String: Any] = [
           "action": "unblock_now",
           "url": url
       ]
        if let p = params { msg["params"] = p.removingPercentEncoding ?? p }
      // msg["params"] = """
        //                    "old_url=focus_mode" & "&version=\(appVersion)"
          //                  """
      //  msg["params"] = params

       sendToExtension(msg)
   }
}

// checkkrna h ki focusmode , blocking schedule ya habit chal rahi ho
//about:debugging#/runtime/this-firefox
//about:newtab  //  allow them
// app change hone per agar browser firefox h to url again and again check ni krn ahai
