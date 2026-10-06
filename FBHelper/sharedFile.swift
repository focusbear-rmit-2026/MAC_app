//
//  sharedFile.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 12/07/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation


let kUserdefaultsSharedUserId = "kUserdefaultsSharedUserId"
let kUserdefaultsSharedCurrentDeviceId = "kUserdefaultsSharedCurrentDeviceId"
let kUserdefaultsSharedAppVersion = "kUserdefaultsSharedAppVersion"
let kUserdefaultsSharedIsPurchased = "kUserdefaultsSharedIsPurchased"
let kUserdefaultsSharedSelectedLanguage = "kUserdefaultsSharedSelectedLanguage"
/// FBHelper's analytics events, queued for the signed-in main app to send (see HelperEventQueue).
let kUserdefaultsSharedPendingHelperEvents = "kUserdefaultsSharedPendingHelperEvents"
/// Whether the signed-in account is an internal test account, so FBHelper can skip analytics
/// without the account's email being copied into the shared suite.
let kUserdefaultsSharedIsInternalTestUser = "kUserdefaultsSharedIsInternalTestUser"
