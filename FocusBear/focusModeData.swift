//
//  focusModeData.swift
//  FocusBear
//
//  Created by Manish Jain on 23/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


var focusModeTaskString = ""
var arrFocusType = [[String:Any]]()
var nextFocusSessionIntention = ""
var arrAllFocusModeTags = [[String:String]]()


var arrBlockedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()
var arrAllowedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()

var arrBlockedUrlsInCuddlyModeCurrentFocus = [String]()
var arrAllowedUrlsInCuddlyModeCurrentFocus = [String]()
var arrAllowedDomianInCuddlyModeCurrentFocus = [String]()
var arrAllowedTabTitlesInCuddlyModeCurrentFocus = [String]()

var dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus = [String:[String:Any]]()
var arrConvinceAiUrlsInCurrentFocus = [[String:String]]()



var arrKeywordsToAllowInFocus = [String]()
var currentRunningFocusType = [String:Any]()

var dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus = [String:[String:Any]]()
var lastFocusModeTempInfo:lastFocusTempInfo?
struct lastFocusTempInfo {
    var id:String!
    var arrAllowedAppsInCuddlyModeCurrentFocus = [NSRunningApplication]()
    var arrAllowedUrlsInCuddlyModeCurrentFocus = [String]()
    
    init(id:String, arrAllowedAppsInCuddlyModeCurrentFocus:[NSRunningApplication], arrAllowedUrlsInCuddlyModeCurrentFocus:[String]) {
        self.id = id
        self.arrAllowedAppsInCuddlyModeCurrentFocus = arrAllowedAppsInCuddlyModeCurrentFocus
        self.arrAllowedUrlsInCuddlyModeCurrentFocus = arrAllowedUrlsInCuddlyModeCurrentFocus
    }
}

var arrFocusTypeForPomodoro = [[String:Any]]()

var focusModeStartWindowLodded = false
var isFocusModeStartedAutomatically = false
var isMeetingsFocusStartedAutomatically = false

var isFocusModeStartedFromPomodoroMode = false
var isSkipBreakActivityDuringPomodoro = false

var isSkipBreakActivityDuringFocus = false

var isShowTimerInFocusEnabled = false
var customUrlHandleLastDurationForRelaxFocusMode = 0


