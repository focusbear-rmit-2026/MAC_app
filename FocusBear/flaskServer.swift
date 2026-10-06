//
//  flaskServer.swift
//  FocusBear
//
//  Created by Manish Jain on 03/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

var flaskServerObject = flaskServer()

// ⚠️  IMPORTANT — Flask server binaries (server / serverIntel)
//
//  The pre-built binaries committed to the repo (FocusBear/server for Apple Silicon
//  and FocusBear/serverIntel for Intel Macs) must ONLY be rebuilt and re-signed by
//  the lead developer (Manish Jain).
//
//  Reasons:
//  • The two binaries require separate build environments: Apple Silicon (arm64) must
//    be built on an M-Series Mac; Intel (x86_64) must be built on an Intel Mac.
//    Universal Python on M-Series does not produce a working Intel binary.
//  • The binaries must be codesigned with the Focus Bear Developer-ID certificate
//    before being committed.  An unsigned or incorrectly signed binary will be
//    blocked by macOS Gatekeeper at runtime.
//
//  If you need a new server build, contact the lead developer rather than
//  attempting to rebuild yourself — an incorrect binary will silently fail.

/// Port the embedded Flask server is actually running on. Defaults to 50501 but is
/// updated by `startFlaskServer()` to a free port when 50501 is already in use.
var flaskServerPort = 50501

class flaskServer:NSObject {
    var flaskProcess: Process?

    func startFlaskServer()->Bool {
        addLog(text: "func startFlaskServer")
        // It serves the block page, so a UI-test build that blocks nothing has no use for it — and
        // XCTest's hard kill of the app between tests left two server processes behind per launch.
        if UITestHost.suppressesEnforcement { return false }
#if arch(arm64)
        let serverPath = Bundle.main.path(forResource: "server", ofType: nil)
#else
        let serverPath = Bundle.main.path(forResource: "serverIntel", ofType: nil)
#endif
        addLog(text: "serverPath:- \(serverPath)")
        if let path = serverPath{//Bundle.main.path(forResource: "server", ofType: "") {
            let serverURL = URL(fileURLWithPath: path)
            // Pick a free port (starting at 50501) so we don't hang when 50501 is taken,
            // then hand it to the server via the PORT env var and keep the app's URLs in sync.
            let port = flaskServer.firstAvailablePort(from: 50501)
            flaskServerPort = port
            if let idx = defaultAllowedUrl.firstIndex(where: { $0.hasPrefix("localhost:") }) {
                defaultAllowedUrl[idx] = "localhost:\(port)"
            }
            flaskProcess = Process()
            flaskProcess?.executableURL = serverURL
            flaskProcess?.environment = [
                "STATIC_FOLDER_PATH": localFlaskServerFolderURL!.path,
                "PORT": "\(port)"
            ]
            do {
                try flaskProcess?.run()
                print("Flask server started on port \(port)")
                addLog(text: "Flask server started on port \(port)")
                return true
            } catch {
                print("Failed to start Flask server: \(error)")
                addLog(text: "Failed to start Flask server: \(error.localizedDescription)")
                return false
            }
        }
        return false
    }

    /// First free TCP port at/after `start` on 127.0.0.1, so the server can fall back
    /// when its preferred port is occupied. Returns `start` if none is found in range.
    static func firstAvailablePort(from start: UInt16, attempts: Int = 50) -> Int {
        var port = start
        for _ in 0..<attempts {
            if isPortAvailable(port) { return Int(port) }
            if port == UInt16.max { break }
            port += 1
        }
        return Int(start)
    }

    /// Whether a TCP listener can bind 127.0.0.1:`port` right now (i.e. it's free).
    static func isPortAvailable(_ port: UInt16) -> Bool {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        if fd < 0 { return false }
        defer { close(fd) }
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                // Darwin.bind to avoid NSObject's KVO bind(_:to:withKeyPath:options:)
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return bound == 0
    }
    
    func stopFlaskServer() {
        addLog(text: "stopFlaskServer")
        flaskProcess?.terminate()
        flaskProcess = nil
    }
}
/*
  write steps here
 make  a folder  FlaskAppBuild(name could be anything)
        |_server.py
        |_static(folder)
            |_focus-block.html
 
 
 Create a virtual environment (if you haven’t already):
    python3 -m venv myenv
 
 
 Activate the virtual environment:
    source myenv/bin/activate
 
 Install Flask inside the virtual environment:
    pip install flask
 
 Run your Flask app again:
    python server.py
 
 */

/* terminal command
 codesign --force --options runtime \
   --entitlements /Users/manish/Desktop/serverIntel.entitlements \
   --sign "Developer ID Application: Focus Bear Pty Ltd (TCUD568B3U)" \
   "/Users/manish/Documents/Apps/Focus Bear/SRC-NEW/FocusBear/serverIntel"
 
 */


