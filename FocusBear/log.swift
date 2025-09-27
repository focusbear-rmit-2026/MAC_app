//
//  Log.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


class Log: TextOutputStream {
    private static let queue = DispatchQueue(label: "logQueue")// queue added in version 2.27.419 to handle mixud up logs(two threads writing at the same time)
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
    
    func write(_ string: String) {
        guard let log = DebugLogsURL else { return }
        Self.queue.async { // ensures only one write at a time
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                if let data = string.data(using: .utf8) {
                    handle.write(data)
                }
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
}

func addLog(text:String){
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    print(now , " - ", text, to: &Log.log)
}


//class Log_Graphs: TextOutputStream { // removed in version 2.27.419
//
//    func write(_ string: String) {
//        if let log = DebugGraphLogsURL{
//            if let handle = try? FileHandle(forWritingTo: log) {
//                handle.seekToEndOfFile()
//                if let data = string.data(using: .utf8) {
//                    handle.write(data)
//                }
//                handle.closeFile()
//            } else {
//                try? string.data(using: .utf8)?.write(to: log)
//            }
//        }
//    }
//    static var log_Graphs: Log_Graphs = Log_Graphs()
//    private init() {} // we are sure, nobody else could create it
//}

//func addGraphsLog(text:String){
//    let df = DateFormatter()
//    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
//    let now = df.string(from: Date())
//    print(now , " - ", text, to: &Log_Graphs.log_Graphs)
//}
//

