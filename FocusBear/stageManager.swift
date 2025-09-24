//
//  StageManager.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


class StageManager:NSObject {
    
    var isStageManagerEnabled = false
    
    func checkIsStageManagerEnabled() -> Bool {
        guard #available(macOS 13.0, *) else {
            return false // Only available on macOS Ventura+
        }
        
        let windowInfos = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
        let appWindows = windowInfos?.filter { window in
            if let ownerName = window[kCGWindowOwnerName as String] as? String {
                return ownerName == "WindowManager"
            }
            return false
        }
        return (appWindows?.count ?? 0) >= 1
    }
}