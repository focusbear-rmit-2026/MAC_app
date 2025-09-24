//
//  Log.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


class Log: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        
        if let log = DebugLogsURL{//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
}

class Log_Graphs: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        
        if let log = DebugGraphLogsURL{//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
    static var log_Graphs: Log_Graphs = Log_Graphs()
    private init() {} // we are sure, nobody else could create it
}

func addGraphsLog(text:String){
    // if isDebugModeEnabled{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    
    print(now , " - ", text, to: &Log_Graphs.log_Graphs)
    //}
}

func addLog(text:String){
    // if isDebugModeEnabled{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    
    print(now , " - ", text, to: &Log.log)
}
