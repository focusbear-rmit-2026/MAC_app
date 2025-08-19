//
//  flaskServer.swift
//  FocusBear
//
//  Created by Manish Jain on 03/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var flaskServerObject = flaskServer()
class flaskServer:NSObject {
    var flaskProcess: Process?
    
    func startFlaskServer()->Bool {
        addLog(text: "func startFlaskServer")
#if arch(arm64)
        let serverPath = Bundle.main.path(forResource: "server", ofType: nil)
#else
        let serverPath = Bundle.main.path(forResource: "serverIntel", ofType: nil)
#endif
        addLog(text: "serverPath:- \(serverPath)")
        if let path = serverPath{//Bundle.main.path(forResource: "server", ofType: "") {
            let serverURL = URL(fileURLWithPath: path)
            flaskProcess = Process()
            flaskProcess?.executableURL = serverURL
            flaskProcess?.environment = ["STATIC_FOLDER_PATH": localFlaskServerFolderURL!.path]
            do {
                try flaskProcess?.run()
                print("Flask server started")
                addLog(text: "Flask server started")
                return true
            } catch {
                print("Failed to start Flask server: \(error)")
                addLog(text: "Failed to start Flask server: \(error.localizedDescription)")
                return false
            }
        }
        return false 
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
   "/Users/manish/Documents/Apps/Focus Bear/src/trunk/FocusBear/server"
 
 */
