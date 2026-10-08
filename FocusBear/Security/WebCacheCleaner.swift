//
//  WebCacheCleaner.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation
import WebKit

/// Clears WebKit's HTTP caches for Focus Bear's own sites.
///
/// The dashboard web view caches API responses and pages (to-dos, habits, roles) on disk, where any
/// process running as the user can read them. The dashboard re-downloads its bundle once per launch
/// anyway, so clearing at launch and quit costs nothing a user would notice. Local storage and
/// cookies are left alone: the web app keeps its state there.
enum WebCacheCleaner {
    static let focusBearDomain = "focusbear.io"
    static let cacheTypes: Set<String> = [
        WKWebsiteDataTypeDiskCache,
        WKWebsiteDataTypeMemoryCache,
        WKWebsiteDataTypeFetchCache,
        WKWebsiteDataTypeOfflineWebApplicationCache,
    ]
    /// Quit can't wait long; the launch-time clear catches whatever this misses.
    static let quitWaitSeconds: TimeInterval = 0.5

    static func isFocusBearRecord(displayName: String) -> Bool {
        let name = displayName.lowercased()
        return name == focusBearDomain || name.hasSuffix("." + focusBearDomain)
    }

    /// Must be called on the main thread (WebKit's data store is main-thread only).
    static func clearFocusBearCaches(in store: WKWebsiteDataStore = .default(),
                                     completion: @escaping () -> Void = {}) {
        store.fetchDataRecords(ofTypes: cacheTypes) { records in
            let ours = records.filter { isFocusBearRecord(displayName: $0.displayName) }
            guard !ours.isEmpty else {
                completion()
                return
            }
            store.removeData(ofTypes: cacheTypes, for: ours) {
                addLog(text: "[at-rest] cleared web caches for \(ours.count) Focus Bear site(s)")
                completion()
            }
        }
    }

    /// Best effort at quit: runs the main run loop briefly so the removal can finish.
    static func clearFocusBearCachesBeforeQuit() {
        var finished = false
        clearFocusBearCaches { finished = true }
        let deadline = Date().addingTimeInterval(quitWaitSeconds)
        while !finished && Date() < deadline {
            RunLoop.current.run(mode: .default, before: deadline)
        }
    }
}
