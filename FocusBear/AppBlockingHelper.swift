//
//  AppBlockingHelper.swift
//  Focus Bear
//
//  Created by Devin AI on 17/01/26.
//

import Foundation

class AppBlockingHelper { 
    
    static func isAppInAlwaysAllowedList(appName: String, alwaysAllowedApps: [String]) -> Bool {
        let normalizedAppName = appName.lowercased()
        for path in alwaysAllowedApps {
            let url = URL(fileURLWithPath: path)
            let allowedAppName = url.deletingPathExtension().lastPathComponent.lowercased()
            if allowedAppName == normalizedAppName {
                return true
            }
        }
        return false
    }
    
    static func isAppInBlockedList(appName: String, blockedApps: [String]) -> Bool {
        let normalizedAppName = appName.lowercased()
        for path in blockedApps {
            let url = URL(fileURLWithPath: path)
            let blockedAppName = url.deletingPathExtension().lastPathComponent.lowercased()
            if blockedAppName == normalizedAppName {
                return true
            }
        }
        return false
    }
    
    static func isAppInAllowedList(appName: String, allowedApps: [String]) -> Bool {
        let normalizedAppName = appName.lowercased()
        for path in allowedApps {
            let url = URL(fileURLWithPath: path)
            let allowedAppName = url.deletingPathExtension().lastPathComponent.lowercased()
            if allowedAppName == normalizedAppName {
                return true
            }
        }
        return false
    }
    
    static func shouldBlockApp(
        appName: String,
        alwaysAllowedApps: [String],
        blockedApps: [String],
        allowedApps: [String],
        isAllowedAllAppsInFocus: Bool,
        defaultAllowedApps: [String]
    ) -> Bool {
        let normalizedAppName = appName.lowercased()
        
        if isAppInAlwaysAllowedList(appName: normalizedAppName, alwaysAllowedApps: alwaysAllowedApps) {
            return false
        }
        
        if isAppInBlockedList(appName: normalizedAppName, blockedApps: blockedApps) {
            return true
        }
        
        if isAllowedAllAppsInFocus {
            return false
        }
        
        if defaultAllowedApps.contains(normalizedAppName) {
            return false
        }
        
        if isAppInAllowedList(appName: normalizedAppName, allowedApps: allowedApps) {
            return false
        }
        
        return true
    }
}

class URLBlockingHelper {
    
    static func isURLInAlwaysBlockedList(url: String, alwaysBlockedURLs: [String]) -> Bool {
        let urlValidation = urlValidation()
        for blockedURL in alwaysBlockedURLs {
            if urlValidation.isUrlValid(urlToCheck: url, allowUrl: blockedURL) {
                return true
            }
        }
        return false
    }
    
    static func isURLInAllowedList(url: String, allowedURLs: [String]) -> Bool {
        let urlValidation = urlValidation()
        for allowedURL in allowedURLs {
            if urlValidation.isUrlValid(urlToCheck: url, allowUrl: allowedURL) {
                return true
            }
        }
        return false
    }
    
    static func shouldBlockURL(
        url: String,
        alwaysBlockedURLs: [String],
        allowedURLs: [String],
        isAllowedListApproach: Bool
    ) -> Bool {
        if isURLInAlwaysBlockedList(url: url, alwaysBlockedURLs: alwaysBlockedURLs) {
            return true
        }
        
        if isAllowedListApproach {
            return !isURLInAllowedList(url: url, allowedURLs: allowedURLs)
        }
        
        return false
    }
}
