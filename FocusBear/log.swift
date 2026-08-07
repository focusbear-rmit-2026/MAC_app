//
//  Log.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


//class Log: TextOutputStream {
//    private static let queue = DispatchQueue(label: "logQueue")// queue added in version 2.27.419 to handle mixud up logs(two threads writing at the same time)
//    static var log: Log = Log()
//    private init() {} // we are sure, nobody else could create it
//    
//    func write(_ string: String) {
//        guard let log = DebugLogsURL else { return }
//        Self.queue.async { // ensures only one write at a time
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
//}
//
//func addLog(text:String){
//    let df = DateFormatter()
//    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
//    let now = df.string(from: Date())
//    print(now , " - ", text, to: &Log.log)
//}


class Log: TextOutputStream {
    static let queue = DispatchQueue(label: "logQueue")

    static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    static var log = Log()
    private init() {}

    func write(_ string: String) {
        guard let log = DebugLogsURL, let data = string.data(using: .utf8) else { return }

        Self.queue.async {
            // The deprecated non-throwing FileHandle seek/write raise an Objective-C
            // NSException on failure (e.g. NSFileHandleOperationException when the volume
            // is full) that Swift cannot catch — it hits the terminate handler and aborts
            // the whole app. Use the throwing API and swallow errors so logging can never
            // crash the process. (Root cause of the SIGABRT-on-full-disk crashes.)
            guard let handle = try? FileHandle(forWritingTo: log) else {
                try? data.write(to: log) // file doesn't exist yet — create it
                return
            }
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } catch {
                // out of space / write error — drop this line rather than abort
            }
        }
    }
}

func addLog(text: String) {
    Log.queue.async {
        let now = Log.formatter.string(from: Date())
        print("\(now) - \(text)", to: &Log.log)
    }
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

