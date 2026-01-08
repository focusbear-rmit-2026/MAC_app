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
    var currentTabUrl:String?
    var currentTabTitle = ""
    var pendingMessage: [String: Any]?
    func start() {
        
        print("Starting FocusBear Local HTTP Server on 50502")

        // POST /check_url  << this acts like "handle WebSocket message"
        server["/check_url"] = { request in
            let body = request.body
//            guard let body = request.body else {
//                return HttpResponse.badRequest(nil)
//            }

            let bodyString = String(decoding: body, as: UTF8.self)
            print("Received from Firefox:", bodyString)

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

            if let msg = self.pendingMessage {
                self.pendingMessage = nil   // deliver once
                let data = try! JSONSerialization.data(withJSONObject: msg)

                print("⬅️ Delivering pending msg to extension:", msg)

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
            try server.start(50502, forceIPv4: true)
            print("Local server ready")
        } catch {
            print("Error starting local server:", error)
        }
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
            
            let blocked = false //UrlChecker.shared.shouldBlock(url)

            if blocked {
                return [
                    "action": "block",
                    "params": ["reason": "focus_mode", "reason21": "focus_mode2"]
                ]
            } else {
                return ["action": "allow"]
            }

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
       print("🟦 Queued message for browser extension:", json)
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
