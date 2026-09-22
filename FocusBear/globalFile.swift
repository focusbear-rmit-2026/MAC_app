//
//  globalFile.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
//import IOKit
import IOKit.pwr_mgt
//import SystemConfiguration// for check internet availibility code
//import WebKit

// Initialize the service
let focusButtonServiceObject = focusButtonService()
let recorder = audioRecorder()

let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

// Suite name shared with FBHelper — must derive identically in both targets.
// The team prefix comes from the build's DEVELOPMENT_TEAM (via FBTeamIdentifierPrefix in
// Info.plist) so a contributor building under their own team still gets a matching suite.
let fbSharedDefaultsSuiteName: String = {
    if let team = Bundle.main.object(forInfoDictionaryKey: "FBTeamIdentifierPrefix") as? String, !team.isEmpty {
        return "\(team).group.com.focusbear.fbmac"
    }
    return "TCUD568B3U.group.com.focusbear.fbmac"
}()

/// Recursively strip anything that is not a property-list type so a value is always safe to hand
/// to `UserDefaults.set`. The focus-mode JSON from the API can carry `null`s (bridged to `NSNull`)
/// and other non-plist values; inserting one throws `NSInvalidArgumentException` and crashed app
/// startup (Sentry FOCUS-BEAR-MACOS-15N). Null-valued keys/elements are DROPPED rather than
/// replaced with a placeholder — they were absent-equivalent anyway, and read sites already treat
/// missing keys as optional.
func plistSanitized(_ value: Any) -> Any? {
    switch value {
    case is NSNull:
        return nil
    case let dictionary as [String: Any]:
        var clean = [String: Any]()
        for (key, child) in dictionary {
            if let sanitizedChild = plistSanitized(child) {
                clean[key] = sanitizedChild
            }
        }
        return clean
    case let array as [Any]:
        return array.compactMap { plistSanitized($0) }
    case is String, is NSNumber, is Date, is Data:
        return value
    default:
        return nil
    }
}

/// Property-list-safe view of the focus-mode array, safe to persist under
/// `kUserdefaultsArrFocusTypes` without risking an `NSInvalidArgumentException` crash.
func plistSafeFocusModes(_ modes: [[String: Any]]) -> [[String: Any]] {
    modes.compactMap { plistSanitized($0) as? [String: Any] }
}


func getBlockedUrlsToBlock()->[String]{
    if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
        if isFocusBreakOn{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                if state{
                    return [];
                }
            }
        }
        if currentState == ._MICRO_BREAK_{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                if state{
                    return [];
                }
            }
        }
        
        if appdelegate?.isUserOnMeeting == true && !SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled{
            return [];
        }

    }
    var arrBlockedUrls = [String]()
    var blockedUrlsCount = SettingsManagerObject.arrBlockedUrls.count
    if isExpired{
        if blockedUrlsCount > alwaysBlockedUrlsCountInExpireApp{
            blockedUrlsCount = alwaysBlockedUrlsCountInExpireApp
        }
    }
    for i in 0..<blockedUrlsCount{
        let url = SettingsManagerObject.arrBlockedUrls[i]
        arrBlockedUrls.append(url)
    }
     return arrBlockedUrls
}

func getBlockedAppsToBlock()->[String]{
    if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
        if isFocusBreakOn{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                if state{
                    return [];
                }
            }
        }
        if currentState == ._MICRO_BREAK_{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                if state{
                    return [];
                }
            }
        }
        
        if appdelegate?.isUserOnMeeting == true && !SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled{
            return [];
        }

    }

    var arrBlockedApps = [String]()
    var blockedAppsCount = SettingsManagerObject.arrBlockedApps.count
    if isExpired{
        if blockedAppsCount > alwaysBlockedUrlsCountInExpireApp{
            blockedAppsCount = alwaysBlockedUrlsCountInExpireApp
        }
    }
    for i in 0..<blockedAppsCount{
        let app = SettingsManagerObject.arrBlockedApps[i]
        arrBlockedApps.append(app)
    }
     return arrBlockedApps
}


let appdelegate = NSApplication.shared.delegate as? AppDelegate
var SettingsManagerObject = SettingsManager()
var isTestUser = false

var tryBlockingVcShownInOnboarding = false

var isExpired:Bool = false
let alwaysBlockedUrlsCountInExpireApp = 3
let activitiesCountInExpireApp = 3
var isActivitiesReducedInExpiredApp = false

var isHardCorePomodoroModeOn = false
var hardcodePmodoroFocusModeName:String = ""
/// True for the LIFE of a focus session that was started from the "postpone routine → set intention →
/// start focus" flow (captured at session start from pomodoroVc.isIntentionFromMorningPostpone, which is
/// itself cleared in the pomodoro's viewWillDisappear and so can't be read later). Used by the Stop
/// handler to skip the password gate and hand the user back to the routine they postponed. Reset at every
/// focus-session start (focusModeStartted) and when the session is stopped/resumed.
var isFocusSessionStartedFromPostponeIntention = false
var totalMinutesRemainingForHardcodePomodoro = 0
var currentPomodoroWorkDuration = 25
var currentPomodoroBreakDuration = 5
var totalPomodoroCountInHardCorePomodoro = 0
var completedPomodoroCountInHardcorePomodoro = 0
var isFocusBreakOn = false

var isEmailVerified = false



var configjson = NSDictionary()


var currentDeviceId = ""
var currentUserName = ""
var currentUserEmail = ""
var currentLeaderboardUsername = ""


//var shouldShowOnboardingBlockedUrlsView = true
var isAppInitialLodded = false// activation kha se show hua h menu se ya startup per iske liye iska use krenge


var areSettingsEdited = false
var isAppEnable = true// should be true here dont change
var startTimeString = ""
var shutOffTimeString = ""
var cutOffTimeString = ""

var startTime:Time?
var shutOffTime:Time?
var cutOffTime:Time?
var has_edited_settings = false

let kDayPlanCompletedHabitIds = "kDayPlanCompletedHabitIds"
let kDayPlanCompletedHabitIdsDate = "kDayPlanCompletedHabitIdsDate"
let kDayPlanCompletedHabitIdsByDay = "kDayPlanCompletedHabitIdsByDay"

/// #2012: per-day completed habit ids, keyed by yyyy-MM-dd. `dayPlanCompletedHabitIds` above only tracks
/// TODAY; this lets a PAST-day habit strike through immediately after a backdated completion (which we
/// sync to the backend via /completed-activity with the real past timestamp — the same path the offline
/// activity-sync uses). Persisted so the strike-through survives a relaunch until the backend day-view
/// becomes the source of truth. Change → requestDayPlanRefresh() re-renders the Day Plan.
var dayPlanCompletedHabitIdsByDay: [String: Set<String>] = {
    guard let raw = UserDefaults.standard.dictionary(forKey: kDayPlanCompletedHabitIdsByDay) as? [String: [String]] else { return [:] }
    return raw.mapValues { Set($0) }
}() {
    didSet {
        UserDefaults.standard.set(dayPlanCompletedHabitIdsByDay.mapValues { Array($0) }, forKey: kDayPlanCompletedHabitIdsByDay)
        requestDayPlanRefresh()
    }
}

/// Whether `habitId` is done for `dayKey` (yyyy-MM-dd): checks the per-day cache, plus the today-only
/// `dayPlanCompletedHabitIds` set when dayKey is today (so the live day and past days share one check).
func isHabitDoneForDay(_ habitId: String, dayKey: String) -> Bool {
    if dayPlanCompletedHabitIdsByDay[dayKey]?.contains(habitId) == true { return true }
    if dayKey == getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd") { return dayPlanCompletedHabitIds.contains(habitId) }
    return false
}

/// Today's server-confirmed completed habit ids (both routines). The Day Plan filters these out so
/// it never shows a habit the backend says is done — a safety net over the arrFiltered* arrays,
/// which aren't always re-filtered on the remote-completion path. Reassigned on each routine refetch,
/// persisted (with today's date) so the next launch can filter on the FIRST Day Plan render — before
/// current-activity-props returns — and re-filters the visible Day Plan whenever it changes.
var dayPlanCompletedHabitIds = Set<String>() {
    didSet {
        let today = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
        UserDefaults.standard.set(Array(dayPlanCompletedHabitIds), forKey: kDayPlanCompletedHabitIds)
        UserDefaults.standard.set(today, forKey: kDayPlanCompletedHabitIdsDate)
        requestDayPlanRefresh()
    }
}

/// #2012: mark a past morning habit done in the Day Plan after a by-id completion (direct API, or via
/// the log-quantity / take-notes popups). Inserting into dayPlanCompletedHabitIds persists it and, via
/// the didSet above, requests a schedule refresh — so the "earlier today" accordion strikes it through.
/// #2012: record a PAST habit completion through the offline activity-sync pipeline — write it to the
/// offline activities CSV with the BACKDATED start/finish, then flush via `processOfflineData()` →
/// `POST /completed-activity/sync`. The backend confirmed /sync is the correct path for backdated data:
/// it attaches the completion to the per-DATE activity-sequence log (derived from start_time), updates
/// that day's stats, has no 30-day clamp, and does NOT disturb today's current-activity pointer for a
/// past-dated record — unlike the single /completed-activity endpoint, which skips stats + sequence-log
/// attachment when should_not_update_current_activity is set. Also marks the Day Plan done locally so the
/// row strikes through immediately.
func recordPastHabitCompletionViaOfflineSync(activity_id: String, activity_sequence_id: String,
                                             performedAt: Date, duration: Int, quantity: Double?,
                                             notes: String, dayKey: String) {
    let fmt = offlineActivityTimestampFormat
    let startStr = getStringFromDateInUtc(date: performedAt, dateFormat: fmt)
    let finish = Calendar.current.date(byAdding: .second, value: max(duration, 1), to: performedAt) ?? performedAt
    let finishStr = getStringFromDateInUtc(date: finish, dateFormat: fmt)
    let qtyStr = quantity.map { "\($0)" } ?? ""
    // skipped_did_complete = "true": "I already did this" semantics, matching the live already-done action.
    addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "\(duration)",
                                   device_id: currentDeviceId, activity_sequence_id: activity_sequence_id,
                                   start_time: startStr, finish_time: finishStr,
                                   skipped_did_complete: "true", choice_id: "", quantity_logged: qtyStr,
                                   skipped_did_not_complete: "", note_logged: notes)
    appdelegate?.processOfflineData()   // flush now via /completed-activity/sync
    markPastHabitDoneInDayPlan(id: activity_id, dayKey: dayKey)
}

/// Per-user key: the current user's id is appended in SettingsManager.resetAllKeys() (the app-wide
/// convention for per-user UserDefaults keys), so a shutdown prompt one account triggers can't leak to
/// a different account that signs in on the same device — UserDefaults.standard is shared across
/// Focus Bear accounts. `var` (not `let`) so resetAllKeys() can append the id.
var kEveningShutdownPromptDate = "kEveningShutdownPromptDate"

/// The evening routine finished today → the Day Plan shows the shutdown prompt at its bottom (#2005
/// part 4). Not a standalone window — only inside the Day Plan, only for the rest of today.
func markEveningRoutineDoneForShutdownPrompt() {
    UserDefaults.standard.set(getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd"), forKey: kEveningShutdownPromptDate)
    requestDayPlanRefresh()
}
func shouldShowEveningShutdownPrompt() -> Bool {
    UserDefaults.standard.string(forKey: kEveningShutdownPromptDate) == getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
}
func dismissEveningShutdownPrompt() {
    UserDefaults.standard.removeObject(forKey: kEveningShutdownPromptDate)
    requestDayPlanRefresh()
}

func markPastHabitDoneInDayPlan(id: String?, dayKey: String? = nil) {
    guard let id = id, !id.isEmpty else { return }
    let todayKey = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
    let key = dayKey ?? todayKey
    dayPlanCompletedHabitIdsByDay[key, default: []].insert(id)
    // Today also feeds the today-only set the live day relies on everywhere else.
    if key == todayKey { dayPlanCompletedHabitIds.insert(id) }
}

/// Seed dayPlanCompletedHabitIds from the persisted cache (today only) so the first Day Plan render
/// reflects already-completed habits before the current-activity-props refetch lands. No-op once the
/// server data is present (so it never overrides fresher state).
func loadPersistedDayPlanCompletedIds() {
    guard dayPlanCompletedHabitIds.isEmpty else { return }
    var ids = offlineCompletedHabitIds()   // unsynced offline completions (today)
    // Plus the last server-confirmed set (the current-activity-props response isn't itself cached).
    let today = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
    if UserDefaults.standard.string(forKey: kDayPlanCompletedHabitIdsDate) == today,
       let saved = UserDefaults.standard.array(forKey: kDayPlanCompletedHabitIds) as? [String] {
        ids.formUnion(saved)
    }
    if !ids.isEmpty { dayPlanCompletedHabitIds = ids }
}

/// The format the offline activities CSV writes its start/finish timestamps in (UTC).
let offlineActivityTimestampFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

/// The LOCAL day (`yyyy-MM-dd`) an offline activity row belongs to. Habit completion is tracked per
/// local day everywhere else, while the CSV stores UTC — so the two only agree once the timestamp is
/// converted. Matching the raw UTC text instead dropped every completion whose local morning falls on
/// the previous UTC day (UTC+10: 8:49am Thursday is 22:49 Wednesday UTC), i.e. most of a Melbourne
/// morning routine.
func offlineActivityLocalDayKey(_ timestampUtc: String) -> String? {
    guard let date = getDateFromStringInUtc(date: timestampUtc, dateFormat: offlineActivityTimestampFormat) else { return nil }
    return getStringFromDate(date: date, dateFormat: "yyyy-MM-dd")
}

/// Today's completed/skipped habit ids from the offline activities CSV — the local cache of activity
/// completions made while offline that the backend (and current-activity-props) doesn't know about
/// yet. Folding these in keeps the Day Plan correct for offline completions until they sync.
func offlineCompletedHabitIds() -> Set<String> {
    guard let url = offlineActivitiesCsvURL,
          let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    // CSV: activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,…
    let today = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
    var ids = Set<String>()
    for (i, row) in content.components(separatedBy: "\n").enumerated() where i > 0 && !row.isEmpty {
        let cols = row.components(separatedBy: ",")
        guard cols.count > 5, !cols[0].isEmpty, offlineActivityLocalDayKey(cols[5]) == today else { continue }
        ids.insert(cols[0])
    }
    return ids
}

/// Capture today's completed habit ids from a `today_routine_progress` payload (both routines), unioned
/// with the offline cache so unsynced completions stay filtered even after the server response lands.
func captureDayPlanCompletedIds(_ progress: NSDictionary) {
    var ids = Set<String>()
    if let m = progress.value(forKey: "morning_routine") as? NSDictionary,
       let arr = m.value(forKey: "completed_habit_ids") as? [String] { ids.formUnion(arr) }
    if let e = progress.value(forKey: "evening_routine") as? NSDictionary,
       let arr = e.value(forKey: "completed_habit_ids") as? [String] { ids.formUnion(arr) }
    ids.formUnion(offlineCompletedHabitIds())
    dayPlanCompletedHabitIds = ids
}

var isMainWindowLoaded = false


var isFirstRun = false


struct Time{
    var hour = 0
    var minute = 0
    var second = 0
}

/// Whether the routine has already been shown for the current routine-day.
///
/// A routine-day does not start at midnight: before the routine's start time the user is still in
/// *yesterday's* day, so "now" rolls back a day before the two dates are compared. With no start
/// time known — settings not loaded yet, or a profile whose startup time is missing or unparseable
/// — there is nothing to roll back to, so the plain calendar day is used.
///
/// Pulled out of `AppDelegate.checkLastHabitShowDate` because that force-unwrapped `startTime` and
/// crashed the app on launch whenever it was nil (EXC_BREAKPOINT in `readSettingsAndLoadApp`).
func isHabitAlreadyShown(lastShown: Date, now: Date, routineStart: Time?, calendar: Calendar = .current) -> Bool {
    var today = now
    if let routineStart,
       let startOfRoutineDay = calendar.date(bySettingHour: routineStart.hour,
                                             minute: routineStart.minute,
                                             second: routineStart.second,
                                             of: now),
       now < startOfRoutineDay {
        today = calendar.date(byAdding: .day, value: -1, to: now) ?? now
    }
    // Shown already unless the routine-day has moved past the day it was last shown on.
    return calendar.compare(today, to: lastShown, toGranularity: .day) != .orderedDescending
}


var occupationStudentIndex = 0
var occupationBusinessOwnerIndex = 1
var occupationEmployeeIndex = 2
var occupationFreelancerIndex = 3
var occupationOtherIndex = 4
var occupationProgrammerIndex = 5
var occupationGraphicDesignerIndex = 6
var occupationOtherOfficeWorkIndex  = 7
var occupationFieldWorkIndex = 8



var preferencesEditHabitsIndex = 3
let preferencesFocusModesIndex = 1
var preferencesSettingsIndex = 2
var preferencesBlocksIndex = 1

var arrFocusAlignmentScore = ["30", "40", "50", "60", "70", "80", "90", "95", "99"]




func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

// Seconds since the last user HID input (mouse/keyboard) system-wide.
func secondsSinceLastUserInput() -> TimeInterval {
    return CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
}

// Body for POST /class-session/:id/heartbeat. `in_focus`/`device_id` stay as-is;
// `idle_seconds` (engagement) is always sent so the backend can score per student.
// `alignment_score` (site-relevance) is sent only when AI relevance-checking is actually
// active — gated on isAIBlockingEnabled() rather than the student's raw isAiCheckUrlEnabled,
// so during a class it follows the TEACHER's allow-list AI setting (which takes precedence).
// That keeps the score present exactly when it's being computed: no omitted score when the
// teacher enabled AI but the student's own toggle is off, and no stale score in the reverse case.
func classSessionHeartbeatBody(inFocus: Bool) -> [String: Any] {
    var body: [String: Any] = [
        "in_focus": inFocus,
        "device_id": currentDeviceId,
        "idle_seconds": Int(secondsSinceLastUserInput())
    ]
    if SettingsManagerObject.isAIBlockingEnabled() {
        body["alignment_score"] = currentFocusAlignmentScore
    }
    return body
}
func getStringTimeFromSeconds(seconds : Int)->String{
    let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)" + hoursHText
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)" + minutesMText
        }else{
            stringTime += " \(m)" + minutesMText
        }
    }
    if s != 0{
        if stringTime.isEmpty{
            stringTime = "\(s)" + secondsSText
        }else{
            stringTime += " \(s)" + secondsSText
        }
    }
    return stringTime
}
func getStringTimeFromSecondsWithoutSeconds(seconds : Int)->String{// olny h and m
    let (h,m,_) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)" + hoursHText
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)" + minutesMText
        }else{
            stringTime += " \(m)" + minutesMText
        }
    }
    if stringTime.isEmpty{
        stringTime += "\(m)" + minutesMText
    }
    return stringTime
}



let avmonitor = AVMonitor()

func getTimeFromString(val:String)->Time{
    let timearr = val.components(separatedBy: ":")
    var hour = 0
    var minute = 0
    var second = 0
    if timearr.count == 3{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
        second = Int(timearr[2]) ?? 0
    }else if timearr.count == 2{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
    }else if timearr.count == 1{
        hour = Int(timearr[0]) ?? 0
    }
    return Time(hour: hour, minute: minute, second: second)
}




func attechIconWithString(text:String)->NSMutableAttributedString{
    if text.localizedCaseInsensitiveContains("<icon>"){
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let arr = text.components(separatedBy: "<icon>")
        let mainstr =  NSMutableAttributedString()
        for i in 0..<arr.count{
            let string = arr[i]
            if !string.isEmpty{
                let str = NSMutableAttributedString(string: string, attributes: attrs)
                if i != arr.count - 1{
                    let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("Bear-Small")))
                    let attachment: NSTextAttachment = NSTextAttachment()
                    attachment.attachmentCell = attachmentCell
                    let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
                    str.append(attrString)
                }
                mainstr.append(str)
            }
        }
        return mainstr
    }else{
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let str = NSMutableAttributedString(string: text, attributes: attrs)
        return str
    }
    
}


enum ACTION:Int{
    case _START_ = 11, _INPROGRESS_, _END_, _VISUALIZE_, _BRAIN_DUMP_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}

var applastSettingsGetTime:Date?





enum CURRENTSTATE:Int, CustomStringConvertible {
    case _NOTHING_ = 111, _MORNING_HABIT_, _EVENING_HABIT_, _MICRO_BREAK_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FOCUS_SUMMARY_, _POSTPONE_MORNING_HABIT_, _POSTPONE_EVENING_HABIT_, _POSTPONE_FOCUS_SUMMARY_, _ONBOARDING_, _SPECIAL_ACTIVITY_, _CUSTOM_ROUTINE_, _LOGIN_
    
    var description: String {
        switch self {
        case ._NOTHING_: return "_NOTHING_"
        case ._MORNING_HABIT_: return "_MORNING_HABIT_"
        case ._EVENING_HABIT_: return "_EVENING_HABIT_"
        case ._MICRO_BREAK_: return "_MICRO_BREAK_"
        case ._SHUTOFFMAC_: return "_SHUTOFFMAC_"
        case ._BREATHING_: return "_BREATHING_"
        case ._ABORT_: return "_ABORT_"
        case ._FOCUS_SUMMARY_: return "_FOCUS_SUMMARY_"
        case ._POSTPONE_MORNING_HABIT_: return "_POSTPONE_MORNING_HABIT_"
        case ._POSTPONE_EVENING_HABIT_: return "_POSTPONE_EVENING_HABIT_"
        case ._POSTPONE_FOCUS_SUMMARY_: return "_POSTPONE_FOCUS_SUMMARY_"
        case ._ONBOARDING_: return "_ONBOARDING_"
        case ._SPECIAL_ACTIVITY_: return "_SPECIAL_ACTIVITY_"
        case ._CUSTOM_ROUTINE_: return "_CUSTOM_ROUTINE_"
        case ._LOGIN_: return "_LOGIN_"
        }
    }

    /// The user has explicitly stepped away from a routine for a while. Postponed is NOT active — the
    /// routine owns neither the window nor the left menu in these states.
    var isRoutinePostponed: Bool {
        switch self {
        case ._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_: return true
        default: return false
        }
    }
}//_POSTPONE_BREAK_ACTIVITY_ is not required because we always reset break activity timer when user clicks on postpone

var lastCurrentStateSaved:CURRENTSTATE = ._NOTHING_



var currentState:CURRENTSTATE = ._NOTHING_{
    didSet{
        if currentState == ._NOTHING_ && lastCurrentStateSaved == ._CUSTOM_ROUTINE_{// if currest state was custom routine and custom routine was started during postpone morning/evening routine state then after complete or abort custom routine set postpone state again
            if isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit{
                currentState = ._POSTPONE_EVENING_HABIT_
            }
            
            if isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit{
                currentState = ._POSTPONE_MORNING_HABIT_
            }
        }
        if currentState != ._CUSTOM_ROUTINE_{
            isCustomRoutineWasRunningInPostponeMorningHabit = false
            isCustomRoutineWasRunningInPostponeEveningHabit = false
        }
        lastCurrentStateSaved = currentState
        
        if currentState == ._MORNING_HABIT_{
            if oldValue != currentState{
                // New routine session → reset the #2091 grace so the away-timer re-centres once before
                // a drag triggers the postpone prompt.
                mainWindowControllerObj?.hasRecenteredRoutineWindowThisSession = false
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._EVENING_HABIT_{
            if oldValue != currentState{
                mainWindowControllerObj?.hasRecenteredRoutineWindowThisSession = false
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._SHUTOFFMAC_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }
        // Postponed is NOT active: stepping away from a routine has to give the whole left menu back.
        // The postpone paths already do this via habitOver(), but a postpone reached any other way
        // (e.g. the custom-routine rollback above) would otherwise strand the menu in the restricted
        // state a running routine left behind.
        if oldValue != currentState, currentState.isRoutinePostponed {
            leftMenuVcObj?.applyRoutineMenuAvailability()
        }
        if oldValue != currentState {
            // Defer to the next runloop. Mutating the Schedule view's hierarchy synchronously here
            // collides with the window style-mask change that follows in the same call stack during
            // the break transition (activityOver → showBreaksView → showSmallSizeWindow), which
            // crashes AppKit's AutoLayout engine. Deferring also lets the routine arrays settle so
            // the schedule re-reads the *same* (completed-filtered) data the habit list shows —
            // e.g. after a remote completion rebuilds the routine and flips the state back.
            DispatchQueue.main.async {
                firstViewControllerObj?.updateScheduleTabForState()
                routinePostponedInfoVcObj?.updateScheduleTabForState()
                firstViewControllerObj?.refreshScheduleIfVisible()
                routinePostponedInfoVcObj?.refreshScheduleIfVisible()
            }
        }
    }
}


/// Set when a remote (other-device) habit completion arrives while the user is viewing the
/// Schedule tab, so that after the routine re-syncs we return them to the schedule instead of
/// navigating into the next habit.
var pendingReturnToSchedule = false

var currentAction:ACTION = ACTION._START_

var lastCurrentState:CURRENTSTATE = ._NOTHING_//abort  cancel ho to to pta krne k liye 
var lastCurrentAction:ACTION = ACTION._START_



// NSSound.play() blocks its calling thread while CoreAudio wakes/primes the output device
// (StartIO_Sync / AudioQueue prime) — routinely >2s when the device is idle or a Bluetooth output has
// to reconnect. All the play*Sound helpers below called it on the main thread, which froze the UI
// (Sentry AppHang, culprits playEveryActivitySound / playStartMorningEveningRoutineSound /
// playFocusPomodorBreakEndsSound). Play on a background queue instead, and keep the NSSound retained
// until playback should be finished so async playback isn't cut off when the caller returns.
private final class BackgroundSoundPlayer {
    static let shared = BackgroundSoundPlayer()
    private let lock = NSLock()
    private var playing: [NSSound] = []

    func play(_ name: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let sound = NSSound(named: name) else { return }
            self.lock.lock(); self.playing.append(sound); self.lock.unlock()
            sound.play()   // blocks THIS background thread on CoreAudio startup, not the main thread
            // NSSound plays asynchronously; its delegate isn't reliably delivered without a run loop on
            // this queue, so just drop the strong reference after the clip's own duration (+ margin).
            let ttl = sound.duration > 0 ? sound.duration + 1 : 8
            DispatchQueue.global().asyncAfter(deadline: .now() + ttl) {
                self.lock.lock(); self.playing.removeAll { $0 === sound }; self.lock.unlock()
            }
        }
    }
}

/// Play a bundled named sound effect off the main thread (see BackgroundSoundPlayer).
func playNamedSound(_ name: String) { BackgroundSoundPlayer.shared.play(name) }

func playEveryActivitySound(){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            playNamedSound(sound)
        }
        addLog(text: "Play Every Activity Sound")
        focusButtonServiceObject.beep()
    }

}

func playAfterMorningEveningRoutineSound(isMorning:Bool){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if isMorning{
            if let sound = arrCompletingWholeMorningRoutineSound.randomElement(){
                addLog(text: "Sound name: \(sound)")
                playNamedSound(sound)
            }
            addLog(text: "Play Morning Routine End Sound")
        }else{
            if let sound = arrCompletingWholeEveningRoutineSound.randomElement(){
                addLog(text: "Sound name: \(sound)")
                playNamedSound(sound)
            }
            addLog(text: "Play Evening Routine End Sound")
        }
        focusButtonServiceObject.beep()
    }
}

func playFocusModeStartedSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartFocusSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            playNamedSound(sound)
        }
        addLog(text: "Play Focus Mode Started Sound")
        focusButtonServiceObject.beep()
    }
}
func playStartMorningEveningRoutineSound(){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartingMorningEveningRoutineSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            playNamedSound(sound)
        }
        addLog(text: "Play Start Morning Evening Routine Sound")
        focusButtonServiceObject.beep()
    }
}
func playFocusPomodorBreakEndsSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            playNamedSound(sound)
        }
        addLog(text: "Play Focus Pomodor Break Ends Sound")
        focusButtonServiceObject.beep()
    }
}


var arrStartingMorningEveningRoutineSound = ["Starting the MorningEvening Routine_2",
                                             "Starting the MorningEvening Routine_4",
                                             "Starting the MorningEvening Routine_5"]

var arrStartFocusSound = ["Start Focus Button_1",
                          "Start Focus Button_2"]


var arrCompletingWholeMorningRoutineSound = ["Completing the Whole Morning Routine_2.2",
                                             "Completing the Whole Morning Routine_3.1"]

var arrCompletingWholeEveningRoutineSound = ["Completing the Whole Evening Routine_4",
                                             "Completing the Whole Evening Routine_5",
                                             "Completing the Whole Evening Routine_7"]

var arrCompletingHabitSound = ["Completing a Habit_4", "grunz__success-low"]


var activitySkippedWhatNextSoundText = "<ACTIVITY> skipped. Guess Whats next?"
var activityFinishedWhatNextSoundText = "<ACTIVITY> finished. Guess Whats next?"
var activitySkippedNextActivitySoundText = "<ACTIVITY> skipped. Next up is <NEXTACTIVITY>."
var activityFinishedNextActivitySoundText = "<ACTIVITY> finished. Next up is <NEXTACTIVITY>."
var activitySkippedUnlockNowSoundText = "<ACTIVITY> skipped. You’ve earned your screen time."
var activityFinishedUnlockNowSoundText = "<ACTIVITY> finished. You’ve earned your screen time."


var startNonTimerActivityButtonText = "Start <NAME>"

var startActivityButtonText = "Start <TIME> <NAME>"
var unlockMachineButtonText = "Let's start work"
var activityFinishedText = "<ACTIVITY> finished!✅"
var lastActivityFinishedText = "<ACTIVITY> finished!✅"
var activitySkippedText = "<ACTIVITY> skipped!"
var lastActivitySkippedText = "<ACTIVITY> skipped! Nice break - Let's get back into it 💪"
var startBreakActivityTitleText = "It’s time for a break. Do <TIME> of <ACTIVITY> to earn more screentime."
var startNonTimerBreakActivityTitleText = "It’s time for a micro break. Let’s do <ACTIVITY> to keep your mind and body sharp."
var doSomeActivityText = "Do some <ACTIVITY>."
var startMorningHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."
var startEveningHabitTitleText = "Good Evening! It’s time to Focus Bear. Here are the habits you need to accomplish before you can leave for the day."
var startCustomRoutineHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."

var emailID = "support@focusbear.io"
var appName = "Focus Bear"
var buttonCancelText = "Cancel"
var buttonOkText = "OK"
var buttonStatusStateFocusText = "FOCUS"
var buttonStatusStateOffText = "OFF"
var buttonStatusStateCallText = "MEETING"
var buttonYesText = "Yes"
var buttonNoText = "No"
var buttonContinueText = "Continue"

var secondsText = "seconds"
var minuteText = "minute"
var minutesText = "minutes"
var hourText = "hour"
var hoursText = "hours"

var graphQuantityText = "Quantity"
var graphMinutesText = "Minutes"
var graphDateText = "Date"
var graphTimeText = "Time"

var hoursHText = "h"
var minutesMText = "m"
var secondsSText = "s"

var windDownText = "Time to wind down"

var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"

//var upgradeNowUrl = "https://dashboard.focusbear.io/manage-subscription"//https://dashboard.focusbear.io/profile"
var buttonMoreActionsText = "More Actions"
var appAllowedInFocusModeText = "\"<APP>\" is allowed in \"<FOCUSMODE>\" focus mode."
var appNotAllowedInFocusModeText = "\"<APP>\" is not allowed in \"<FOCUSMODE>\" focus mode."

var strictnessNormalText = "Normal"
var strictnessStrictText = "Strict"
var strictnessSuperStrictText = "Super strict"

func readConfigFile(){
    addLog(text: "read Config File")
    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
        startActivityButtonText = activityInfo.value(forKey: "startActivityButtonText") as? String ?? startActivityButtonText
        startNonTimerActivityButtonText = activityInfo.value(forKey: "startNonTimerActivityButtonText") as? String ?? startNonTimerActivityButtonText
        activityFinishedText = activityInfo.value(forKey: "activityFinishedText") as? String ?? activityFinishedText
        lastActivityFinishedText = activityInfo.value(forKey: "lastActivityFinishedText") as? String ?? lastActivityFinishedText
        startBreakActivityTitleText = activityInfo.value(forKey: "startBreakActivityTitleText") as? String ?? startBreakActivityTitleText
        startNonTimerBreakActivityTitleText = activityInfo.value(forKey: "startNonTimerBreakActivityTitleText") as? String ?? startNonTimerBreakActivityTitleText
        doSomeActivityText = activityInfo.value(forKey: "doSomeActivityText") as? String ?? doSomeActivityText
        startMorningHabitTitleText = activityInfo.value(forKey: "startMorningHabitTitleText") as? String ?? startMorningHabitTitleText
        startEveningHabitTitleText = activityInfo.value(forKey: "startEveningHabitTitleText") as? String ?? startEveningHabitTitleText
        activitySkippedText = activityInfo.value(forKey: "activitySkippedText") as? String ?? activitySkippedText
        lastActivitySkippedText = activityInfo.value(forKey: "lastActivitySkippedText") as? String ?? lastActivitySkippedText
        
        activitySkippedWhatNextSoundText = activityInfo.value(forKey: "activitySkippedWhatNextSoundText") as? String ?? activitySkippedWhatNextSoundText
        activityFinishedWhatNextSoundText = activityInfo.value(forKey: "activityFinishedWhatNextSoundText") as? String ?? activityFinishedWhatNextSoundText
        activitySkippedNextActivitySoundText = activityInfo.value(forKey: "activitySkippedNextActivitySoundText") as? String ?? activitySkippedNextActivitySoundText
        activityFinishedNextActivitySoundText = activityInfo.value(forKey: "activityFinishedNextActivitySoundText") as? String ?? activityFinishedNextActivitySoundText
        activitySkippedUnlockNowSoundText = activityInfo.value(forKey: "activitySkippedUnlockNowSoundText") as? String ?? activitySkippedUnlockNowSoundText
        activityFinishedUnlockNowSoundText = activityInfo.value(forKey: "activityFinishedUnlockNowSoundText") as? String ?? activityFinishedUnlockNowSoundText
        buttonMoreActionsText = activityInfo.value(forKey: "buttonMoreActionsText") as? String ?? buttonMoreActionsText
    }
    
    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
            strictnessNormalText = startingFocusModeInfo.value(forKey: "strictnessNormalText") as? String ?? strictnessNormalText
            strictnessStrictText = startingFocusModeInfo.value(forKey: "strictnessStrictText") as? String ?? strictnessStrictText
            strictnessSuperStrictText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictText") as? String ?? strictnessSuperStrictText
        }
    }
    
    
    if let languageInfo = configjson.value(forKey: "languageInfo") as? NSDictionary{
        arrLanguageDic[0]["name"] = languageInfo.value(forKey: "languageEnglish") as? String ?? arrLanguageDic[0]["name"]
        arrLanguageDic[1]["name"] = languageInfo.value(forKey: "languageSpanish") as? String ?? arrLanguageDic[1]["name"]
    }
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        emailID = common.value(forKey: "emailId") as? String ?? emailID
        appName = common.value(forKey: "appName") as? String ?? appName
        buttonCancelText = common.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        buttonOkText = common.value(forKey: "buttonOkText") as? String ?? buttonOkText
        buttonYesText = common.value(forKey: "yesText") as? String ?? buttonYesText
        buttonContinueText = common.value(forKey: "buttonContinueText") as? String ?? buttonContinueText
        buttonNoText = common.value(forKey: "noText") as? String ?? buttonNoText
        unlockMachineButtonText = common.value(forKey: "unlockMachineButtonText") as? String ?? unlockMachineButtonText
        webhookUrl = common.value(forKey: "webhookUrl") as? String ?? webhookUrl
        buttonStatusStateFocusText = common.value(forKey: "buttonStatusStateFocusText") as? String ?? buttonStatusStateFocusText
        buttonStatusStateOffText = common.value(forKey: "buttonStatusStateOffText") as? String ?? buttonStatusStateOffText
        buttonStatusStateCallText = common.value(forKey: "buttonStatusStateCallText") as? String ?? buttonStatusStateCallText
        
        secondsText = common.value(forKey: "secondsText") as? String ?? secondsText
        minuteText = common.value(forKey: "minuteText") as? String ?? minuteText
        minutesText = common.value(forKey: "minutesText") as? String ?? minutesText
        hourText = common.value(forKey: "hourText") as? String ?? hourText
        hoursText = common.value(forKey: "hoursText") as? String ?? hoursText
        
        graphQuantityText = common.value(forKey: "graphQuantityText") as? String ?? graphQuantityText
        graphMinutesText = common.value(forKey: "graphMinutesText") as? String ?? graphMinutesText
        graphDateText = common.value(forKey: "graphDateText") as? String ?? graphDateText
        graphTimeText = common.value(forKey: "graphTimeText") as? String ?? graphTimeText
        
        hoursHText = common.value(forKey: "hoursHText") as? String ?? hoursHText
        minutesMText = common.value(forKey: "minutesMText") as? String ?? minutesMText
        secondsSText = common.value(forKey: "secondsSText") as? String ?? secondsSText
       
        appAllowedInFocusModeText = common.value(forKey: "appAllowedInFocusModeText") as? String ?? appAllowedInFocusModeText
        appNotAllowedInFocusModeText = common.value(forKey: "appNotAllowedInFocusModeText") as? String ?? appNotAllowedInFocusModeText
    }
    
    if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
        if let title = shutOffTimeInfo.value(forKey: "title") as? String{
            windDownText = title
        }
    }
    
//    upgradeNowUrl = configjson.value(forKey: "upgradeNowUrl") as? String ?? upgradeNowUrl
    
}
func getDoSomeActivityText(activityName:String)->String{
    return doSomeActivityText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
}

func getStartBreakActivityTitleText(seconds:Int, activityName:String)->String{
    var title = ""
    if seconds == 86400{
        title = startNonTimerBreakActivityTitleText
        title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }else{
        let stringTime = getStringTime(seconds: seconds)
        title = startBreakActivityTitleText.replacingOccurrences(of: "<TIME>", with: stringTime)
        title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }
    return title
    
}
func getActivityFinishedText(isLast:Bool, activityName:String)->String{
    if currentState == ._EVENING_HABIT_ && isLast{
        return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName) + " " + windDownText
    }else{
        if isLast{
            return lastActivityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }else{
            return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }
    }
}
func getActivitySkippedText(isLast:Bool, activityName:String)->String{
    if currentState == ._EVENING_HABIT_ && isLast{
        return activitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName) + " " + windDownText
    }else{
        if isLast{
            return lastActivitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }else{
            return activitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }
    }
}

func playActivityFinishedSound(lastActivity:String, nextActivity:String, isSkipped:Bool, isAskNext:Bool){
    if !SettingsManagerObject.isAnnouncementEnabled{
        return;
    }
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    var text = ""
    if isAskNext{
        if isSkipped{
            text = activitySkippedWhatNextSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
        }else{
            text = activityFinishedWhatNextSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
        }
    }else{
        if isSkipped{
            if !nextActivity.isEmpty{
                text = activitySkippedNextActivitySoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
                text = text.replacingOccurrences(of: "<NEXTACTIVITY>", with: nextActivity)
            }else{
                text = activitySkippedUnlockNowSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
            }
        }else{
            if !nextActivity.isEmpty{
                text = activityFinishedNextActivitySoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
                text = text.replacingOccurrences(of: "<NEXTACTIVITY>", with: nextActivity)
            }else{
                text = activityFinishedUnlockNowSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
            }
        }
    }
    
    
    let task = Process()
    task.arguments = ["-c", "say \"\(text)\""]//-v \"\(popUpBtn.titleOfSelectedItem ?? "")\""]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
}

func getStringTime(seconds:Int)->String{
    var stringTime = ""
    
    let hours = seconds / 3600
    let mins = (seconds % 3600) / 60;
    let secs = seconds % 60
    if (hours > 0 && mins > 0 && secs > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(mins)" + " " + (mins > 1 ? minutesText : minuteText) + " " + "\(secs)" + " " + secondsText
    }else if (hours > 0 && mins > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(mins)" + " " + (mins > 1 ? minutesText : minuteText)
    }else if (hours > 0 && secs > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(secs)" + " " + secondsText
    }else if (mins > 0 && secs > 0){
        stringTime = "\(mins)" + " " + (mins > 1 ? minutesText : minuteText) + " " + "\(secs)" + " " + secondsText
    }else if (hours > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText)
    }else if (mins > 0){
        stringTime = "\(mins)" + " " + (mins > 1 ? minutesText : minuteText)
    }else if (secs > 0){
        stringTime = "\(secs)" + " " + secondsText
    }
    if stringTime.isEmpty{
        stringTime = "\(secs)" + " " + secondsText
    }
    return stringTime
}




func getstartActivityButtonText(seconds:Int, name:String)->String{
    var title = startActivityButtonText
    if seconds == 86400{
        title = startNonTimerActivityButtonText
        if title.localizedCaseInsensitiveContains("<NAME>"){
            title = title.replacingOccurrences(of: "<NAME>", with: name)
        }
    }else{
        let stringTime = getStringTime(seconds: seconds)
        
        if title.localizedCaseInsensitiveContains("<TIME>"){
            title = title.replacingOccurrences(of: "<TIME>", with: stringTime)
        }
        if title.localizedCaseInsensitiveContains("<NAME>"){
            title = title.replacingOccurrences(of: "<NAME>", with: name)
        }
    }
    
    return title
}



var isGettingSchema = false



let allApiObject = AllApi()
let pusherEventsObject = pusherEvents()

var applicationSupportURL: URL?
var localFlaskServerFolderURL:URL!
var trackFilesFolderURL:URL!
var DebugLogsFolderURL:URL!
var DebugLogsURL:URL!
//var DebugGraphLogsURL:URL!

//var habitInfoFileURL:URL!
var settingForScreeenTimeFileURL:URL!
var newLocalSettingsFileURL:URL!
var arrNonTimerBasedHabitsDurationsPlistFileUrl:URL!


//var blockURL:URL!
var blockWebUrlString = ""

func getSystemTimeFormat()->String{
    var timeFormat = "h:mm a"
    if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
        if let isShow24Hour = dict["Show24Hour"] as? Bool {
            if isShow24Hour{
                timeFormat = "H:mm"
            }
        }
    }
    return timeFormat
}

func getStringFromDate(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    let now = df.string(from: date)
    return now
}

func getStringFromDateInUtc(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    df.timeZone = TimeZone(abbreviation: "UTC")
    let now = df.string(from: date)
    return now
}
func getDateFromString(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter.date(from: string)
}

func getDateFromStringInUtc(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    // Set Date Format
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = dateFormat
    // Convert String to Date
    return dateFormatter.date(from: string)
}

func getFirstRunDateString()->String{
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let myDateString = formatter.string(from: firstRunDate)
    return myDateString
}
func getDaysSinceAppInstalled()->Int{
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
    return diffDays
}

/// True when the app is running inside CI / an automated test harness. Used to suppress ALL analytics
/// sends so CI-launched builds never pollute the PostHog onboarding funnel with fake "users": a CI
/// build boots to the welcome screen and would otherwise fire welcome-screen-shown etc. from cloud
/// runners (Focus-Bear/analytics#33). Detected via the standard CI env vars, the XCTest harness, or an
/// explicit FOCUSBEAR_DISABLE_TELEMETRY opt-out CI can set when those env vars don't propagate to the
/// launched app. Computed each call (cheap) so it reflects the actual process environment.
let isRunningInCIOrAutomatedTest: Bool = {
    let env = ProcessInfo.processInfo.environment
    for key in ["CI", "GITHUB_ACTIONS", "FOCUSBEAR_DISABLE_TELEMETRY",
                "XCTestConfigurationFilePath", "XCTestSessionIdentifier"] {
        if let value = env[key], !value.isEmpty { return true }
    }
    // A unit/UI-test bundle injects XCTest into the running process.
    return NSClassFromString("XCTestCase") != nil
}()

func isAppInstalledWithinLast3Days() -> Bool {
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    return firstRunDate >= threeDaysAgo
}

//******************************************CreateDirectoryIfNotExist*******************************************************//
func CreateDirectoryIfNotExist(path:String){
    if !FileManager.default.fileExists(atPath: path){
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch{
            
        }
    }
}





//



var isPurchased = false
var daysLeft = 0
let daysFreeTrial  = 31



var focusDefaultAllowApps = ["finder", "universalaccessauthwarn", "system preferences", "loginwindow", "screensaverengine", "osascript", "late no more", "focus bear time tracker"]
var arrExcludeAppsInBreaksBrainDumpLastActivateApp = ["finder", "universalaccessauthwarn", "system preferences", "loginwindow", "screensaverengine", "osascript", "late no more", "focus bear time tracker"]

let focusBearTimeTrackerAppName = "focus bear time tracker"


var selfAppName = Bundle.main.infoDictionary!["CFBundleName"] as! String




var lastFrontMostApplication:NSRunningApplication?

/// The app the user is actually looking at right now, ignoring Focus Bear's own windows: presenting a
/// block prompt makes Focus Bear frontmost, so `frontmostApplication` can't be trusted on its own. Falls
/// back to the last non-Focus-Bear app that was frontmost.
func currentUserFacingApp() -> NSRunningApplication? {
    if let front = NSWorkspace.shared.frontmostApplication, front.bundleIdentifier != mainAppBundelId {
        return front
    }
    return lastFrontMostApplication
}


func getColorString(color:NSColor)->String{
    let ciColor:CIColor = CIColor(color: color)!
    let hexString = String(format: "%02X%02X%02X", Int(ciColor.red * 0xff), Int(ciColor.green * 0xff), Int(ciColor.blue * 0xff))
    return hexString
}
func HexToColor(hexString: String, alpha:CGFloat? = 1.0) -> NSColor {
    // Convert hex string to an integer
    let hexint = Int(intFromHexString(hexStr: hexString))
    let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
    let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
    let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
    let alpha = alpha!
    // Create color object, specifying alpha as well
    let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
    return color
}
func intFromHexString(hexStr: String) -> UInt32 {
    var hexInt: UInt32 = 0
    // Create scanner
    let scanner: Scanner = Scanner(string: hexStr)
    // Tell scanner to skip the # character
    scanner.charactersToBeSkipped = NSCharacterSet(charactersIn: "#") as CharacterSet
    // Scan hex value
    scanner.scanHexInt32(&hexInt)
    return hexInt
}



func isBlockSuperDistractingFocusModeOn()->Bool{
    // An accountability-buddy session judges apps/sites with the AI against the user's goal, NOT the
    // curated "super distracting" blocklist — so it must not count as the super-distracting mode even
    // though it piggybacks on the default focus mode. Otherwise the AI URL/app check is skipped.
    if currentAccountabilityBuddySession != nil { return false }
    if currentRunningFocusType["isDefault"] as? Bool == true {
        return true
    }
    return false
}

//pomodoro
func resetPomodoroVcFocusListIfNeeded(){
    if pomodoroVcObj?.isViewVisible ?? false{
        pomodoroVcObj?.reFillFocusTypeList()
    }
}


var assertionIDDisableSleep: IOPMAssertionID = 0
func disableSystemSleep(){
    addLog(text:"disableSystemSleep")
    let reasonForActivity = "Reason for activity" as CFString
    //    var assertionID: IOPMAssertionID = 0
    var success = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                               IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                               reasonForActivity,
                                               &assertionIDDisableSleep )
    //    if success == kIOReturnSuccess {
    //        // Add the work you need to do without the system sleeping here.
    //
    //        success = IOPMAssertionRelease(assertionIDDisableSleep);
    //        // The system will be able to sleep again.
    //    }
}
func enableSystemSleep(){
    IOPMAssertionRelease(assertionIDDisableSleep);
}

/// True when the window's first responder is a text field or text view the user is typing into.
/// The app's Return-key monitor fires before the responder chain sees the event, so any shortcut it
/// runs has to check this or it steals Return from every multi-line field on screen.
func isTextInputFocused(in window: NSWindow?) -> Bool {
    guard let responder = window?.firstResponder else { return false }
    if responder is NSTextView { return true }
    // A focused NSTextField is represented by its field editor, whose delegate is the field.
    if let fieldEditor = responder as? NSText, fieldEditor.delegate is NSTextField { return true }
    return responder is NSTextField
}


var isFocusMusicPausedAutomatically = false
func pauseAutomaticallyIfAnyFocusMusicPlaying(){
    if allTracksVcObj != nil{
        for i in 0..<arrAllTracks.count{
            if arrAllTracks[i]["isPlaying"] as? Bool == true{
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = true
                if allTracksVcObj?.currentSound?.isPlaying ?? false{
                    allTracksVcObj?.currentSound?.pause()
                    isFocusMusicPausedAutomatically = true
                }
                reloadFocusMusicListIfVisible()
                break;
            }
        }
    }
}
func resumeIfAnyFocusMusicStoppedAutomatically(){
    if isFocusMusicPausedAutomatically{
        isFocusMusicPausedAutomatically = false
        if allTracksVcObj != nil{
            for i in 0..<arrAllTracks.count{
                if arrAllTracks[i]["isPaused"] as? Bool == true{
                    arrAllTracks[i]["isPlaying"] = true
                    arrAllTracks[i]["isPaused"] = false
                    allTracksVcObj?.currentSound?.resume()
                    reloadFocusMusicListIfVisible()
                    break;
                }
            }
        }
    }
}

func reloadFocusMusicListIfVisible(){
    if allTracksVcObj != nil && mainWindowControllerObj != nil{
        if mainWindowControllerObj?.window?.isVisible ?? false{
            if leftMenuVcObj?.boxFocusMusic.isSelected ?? false{
                allTracksVcObj?.model.refresh()
            }
        }
    }
}

/// Whether the app should be in its borderless full-screen window RIGHT NOW.
///
/// The user's setting says they want full-screen mode; `FullScreenStates` says which states it
/// covers. Full screen is for holding the user inside a running routine, so a postponed routine and
/// a micro break are not covered — both used to take the whole display with no traffic lights
/// (report 2026-09-14_16-31-53). The old mid-meeting break exception is subsumed: no micro break is
/// covered now, in a meeting or not.
func checkIsFullScreenEnabled()-> Bool{
    FullScreenStates.shouldUseFullScreen(setting: SettingsManagerObject.isFullScreenEnabled,
                                         state: currentState)
}



var newGifsNamesArray = ["Glasses-Bear-250-px_V3", "cheer_250px_trans_centered", "Finger-and-Sign-Bear-250px", "Weight-bear-250-px_V2", "Whistle-bear-250-px"]




//

func wildcard(_ string: String, pattern: String) -> Bool {
    let pred = NSPredicate(format: "self LIKE %@", escapedForLike(pattern))
    return !NSArray(object: string).filtered(using: pred).isEmpty
}

/// Makes a `LIKE` pattern safe to hand to `NSPredicate`.
///
/// A trailing unescaped backslash makes `NSPredicate` raise `NSInvalidArgumentException`, which is
/// an Objective-C exception and so cannot be caught from Swift — it terminates the app. Verified
/// directly: the process dies with "terminating due to uncaught exception of type NSException".
///
/// Most callers wrap the user's entry as `*entry*`, so the backslash is never last and the hazard
/// never shows. `isUrlValid`'s `file://` branch does not wrap (urlValidation.swift), so an
/// allow-list entry like `file:///Users/me/folder\` reaches here unwrapped and crashes Focus Bear.
///
/// Doubling an odd run of trailing backslashes escapes the last one, which is what the user meant
/// by typing it: a literal backslash. `*` and `?` elsewhere in the pattern keep their wildcard
/// meaning, so no caller's behaviour changes.
func escapedForLike(_ pattern: String) -> String {
    var trailing = 0
    for character in pattern.reversed() {
        guard character == "\\" else { break }
        trailing += 1
    }
    return trailing % 2 == 0 ? pattern : pattern + "\\"
}

func getDomainFromUrl(url:String) -> String{
    let mainurl = NSURL(string: url)
    var domain = mainurl?.host ?? ""
    
    if domain.contains("www."){
        domain = domain.replacingOccurrences(of: "www.", with: "")
    }
    return domain
}

func getPathFromUrl(url:String) -> String{
    let domain = getDomainFromUrl(url: url)
    
    var path = url.replacingOccurrences(of: "http://", with: "")
    path = path.replacingOccurrences(of: "https://", with: "")
    if path.contains("www."){
        path = path.replacingOccurrences(of: "www.", with: "")
    }

    if domain == "youtube.com"{
        return path
    }else{
        if path.contains("?"){
            path = path.components(separatedBy: "?")[0]
        }
    }
    return path
}

func getPathFromUrl(url:String, domain:String) -> String{
    var path = url.replacingOccurrences(of: "http://", with: "")
    path = path.replacingOccurrences(of: "https://", with: "")
    if path.contains("www."){
        path = path.replacingOccurrences(of: "www.", with: "")
    }

    if domain == "youtube.com"{
        return path
    }else{
        if path.contains("?"){
            path = path.components(separatedBy: "?")[0]
        }
    }
    return path
}


func isPreventUserIdleDisplaySleepOn()-> Bool{
    var assertions: Unmanaged<CFDictionary>?
    if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
        fatalError("Error with assertions")
    }
    var dic = [AnyHashable : Any]()

    if assertions != nil{
        
        let val = assertions!.takeRetainedValue()

        if let dictionary = val as? [AnyHashable : Any]{
            dic = dictionary
        }else{
            addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
            return false
        }
    }else{
        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
        return false
    }

    let processArray = ["zoom.us", "teams"]// lowercased names aynge sirf

    let keys  = dic.keys
    for key in keys{
        if let arr = dic[key] as? NSArray{
            var isArrayContainAudioIn = false
            var isArrayContainAudioIOut = false
            var isArrayContainColonOutput = false
            var isArrayContainColonInput = false
            var isArrayContainAppleHDAEngineOutput = false
            
            for item in arr{
                if let itemDic = item as? NSDictionary{
                    if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                        if let name = itemDic.value(forKey: "Process Name") as?  String{
                            let processName = name.lowercased()
                            if processName != selfAppName.lowercased(){
                                if processArray.contains(processName){
                                    addLog(text: "is Prevent UserIdle Display SleepOn return true")
                                    return true
                                }
                            }
                            
                        }
                    }else if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleSystemSleep"{
                        if var resourcesUsedArr = itemDic.value(forKey: "ResourcesUsed") as?  [String]{
                            resourcesUsedArr = resourcesUsedArr.map {$0.lowercased()}
                            var isContainAudioIn = false
                            var isContainAudioIOut = false
                            if resourcesUsedArr.contains("audio-in"){
                                isContainAudioIn = true
                                isArrayContainAudioIn = true
                            }
                            if resourcesUsedArr.contains("audio-out"){
                                isContainAudioIOut = true
                                isArrayContainAudioIOut = true
                            }
                            
                            if isContainAudioIn && isContainAudioIOut{
                                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and audioOut found in resources")
                                return true
                            }else if isContainAudioIOut{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":input"){
                                        addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and colonOut found in resources")
                                        return true
                                    }
                                }
                            }
                            if !isContainAudioIOut{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":output"){
                                        isArrayContainColonOutput = true
                                    }else if resource.contains("applehdaengineoutput:"){
                                        isArrayContainAppleHDAEngineOutput = true
                                    }
                                }
                            }
                            if !isContainAudioIn{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":input"){
                                        isArrayContainColonInput = true
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            
            if isArrayContainAudioIn && isArrayContainAudioIOut{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and audioOut found in array")
                return true
            }else if isArrayContainAudioIn && isArrayContainColonOutput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and colonOut found in array")
                return true
            }else if isArrayContainAudioIOut && isArrayContainColonInput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioOut and colonIn found in array")
                return true
            }else if isArrayContainAudioIn && isArrayContainAppleHDAEngineOutput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and AppleHDAEngineOutput found in array")
                return true
            }
        }
    }
    
    //    addLog(text: "is Prevent UserIdle Display SleepOn return false")
    return false
}


func isAnyPresentationOrVideoShowing()-> Bool{
    var assertions: Unmanaged<CFDictionary>?
    if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
        fatalError("Error with assertions")
    }
    var dic = [AnyHashable : Any]()
    
    if assertions != nil{
        
        let val = assertions!.takeRetainedValue()
        
        if let dictionary = val as? [AnyHashable : Any]{
            dic = dictionary
        }else{
            addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
            return false
        }
    }else{
        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
        return false
    }
    
    let keys  = dic.keys
    for key in keys{
        if let arr = dic[key] as? NSArray{
            for item in arr{
                if let itemDic = item as? NSDictionary{
                    if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                        if let name = itemDic.value(forKey: "Process Name") as?  String{
                            let processName = name.lowercased()
                            if processName != selfAppName.lowercased(){
                                // Name the actual process (and its assertion reason, if it supplied one) so a
                                // suppressed natural break is diagnosable — e.g. whether it's a genuine video /
                                // presentation or a false positive like a call app or a media tab keeping the
                                // display awake. Details keys vary by macOS, so try the common ones.
                                let reason = (itemDic.value(forKey: "AssertionName") as? String)
                                    ?? (itemDic.value(forKey: "Name") as? String)
                                    ?? (itemDic.value(forKey: "Details") as? String) ?? ""
                                addLog(text: "isAnyPresentationOrVideoShowing: '\(name)' holds a PreventUserIdleDisplaySleep assertion\(reason.isEmpty ? "" : " — \"\(reason)\"").")
                                return true
                            }

                        }
                    }
                    
                }
            }
        }
    }
    return false
}



var lastShownRandomChoiceDic = [String:activityChoice]()



let mainAppBundelId = Bundle.main.bundleIdentifier ?? ""
//func createLaunchAgent(){//  comment this
//    addLog(text: "func:- createLaunchAgent")
//    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
//    let path = Bundle.main.bundlePath
//    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
//        for uLA in userLA {
//            if uLA.isCurrentlyLoaded{
//                if let arguments = uLA.programArguments as? [String]{
//                    if arguments.contains(where: {$0.caseInsensitiveCompare(path) == .orderedSame}) {
//                        addLog(text: "LaunchAgent already created return")
//                        return;
//                    }
//                }
//            }
//        }
//    }
//    //
//    
//    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
//    if !FileManager.default.fileExists(atPath: destination) {
//        do {
//            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
//        } catch {}
//        
//    }
//    
//    // saves the agent plist file
//    let userLaunchAgentsPath = "\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"
//    
//    let dicContent = ["Label": "\(mainAppBundelId).plist", "ProgramArguments":["/usr/bin/open","-F","-g",path,"--args"],"RunAtLoad":true,"KeepAlive":true] as [String : Any]
//    
//    let plistContent = NSDictionary(dictionary: dicContent)
//    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
//    if success {
//        print("file has been created!")
//    }else{
//        print("unable to create the file")
//    }
//    shell(launchPath: "/bin/launchctl", arguments: ["load","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
//    addLog(text: "createLaunchAgent done")
//}

var helperUrl: URL = {

    let helperURL = URL(fileURLWithPath: "Contents/Resources/FBHelper.app", relativeTo: Bundle.main.bundleURL)
    return helperURL
}()

/// The LaunchAgent that starts the nudge helper at login.
///
/// Split out from `createLaunchAgentForHelperApp()` so what gets written is assertable without
/// touching ~/Library/LaunchAgents or launchctl.
enum HelperLaunchAgent {
    static let label = "com.focusbear.focusbearhelper"

    /// The helper's own executable inside its bundle.
    static func executablePath(helperBundle: URL) -> String {
        helperBundle.appendingPathComponent("Contents/MacOS/FBHelper").path
    }

    /// What launchd should run.
    ///
    /// Deliberately NOT `/usr/bin/open`, which is what this used to be. Two things were wrong with
    /// that, and the one the user sees is the second:
    ///
    /// * `open` exits as soon as LaunchServices has been asked to start the helper, so `KeepAlive`
    ///   was supervising `open` rather than the helper — `launchctl list` shows the job with no PID
    ///   while the helper runs under a separate LaunchServices label. launchd relaunched `open` on a
    ///   loop and never watched the thing it was meant to keep alive.
    /// * macOS names a background item after the program it runs, so Login Items and the
    ///   "Background Items Added" notice both called this **"open"** — which reads like something
    ///   suspicious rather than like Focus Bear (report 2026-09-21_18-01-43, issue #409).
    ///
    /// Pointing at the executable INSIDE FBHelper.app also lets macOS attribute the item to that
    /// bundle, so it can show the bundle's display name instead of a bare executable name.
    static func programArguments(helperBundle: URL) -> [String] {
        [executablePath(helperBundle: helperBundle)]
    }

    static func plist(helperBundle: URL) -> [String: Any] {
        ["Label": label,
         "ProgramArguments": programArguments(helperBundle: helperBundle),
         "RunAtLoad": true,
         "KeepAlive": true]
    }

    /// Whether an already-loaded job matches what we would write now. Used to leave a correct agent
    /// alone — and, just as importantly, to REPLACE an old `/usr/bin/open` one instead of returning
    /// early because it merely mentions the helper somewhere in its arguments, which is what the
    /// previous check did.
    static func matchesCurrentDesign(existingArguments: [String]?, helperBundle: URL) -> Bool {
        existingArguments == programArguments(helperBundle: helperBundle)
    }
}

func createLaunchAgentForHelperApp(){
    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
    let helperBundleID = HelperLaunchAgent.label
    let userLaunchAgentsPath = "/Users/\(NSUserName())/Library/LaunchAgents/\(helperBundleID).plist"
    var needsUnloadFirst = false
    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
        for uLA in userLA where uLA.isCurrentlyLoaded {
            let arguments = uLA.programArguments as? [String]
            guard arguments?.contains(where: { $0.contains("FBHelper") }) == true else { continue }
            if HelperLaunchAgent.matchesCurrentDesign(existingArguments: arguments, helperBundle: helperUrl) {
               // return          // already what we would write
            }
            // An older agent for the same helper — the /usr/bin/open one. `launchctl load` is a
            // no-op while a label is loaded, so it has to go before the replacement can take.
            needsUnloadFirst = true
        }
    }
    if needsUnloadFirst {
        addLog(text: "replacing the legacy /usr/bin/open helper LaunchAgent")
        shell(launchPath: "/bin/launchctl", arguments: ["unload", "-w", userLaunchAgentsPath])
    }
    //
    
    
    
    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
    if !FileManager.default.fileExists(atPath: destination) {
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
    }
    
    // saves the agent plist file
    let plistContent = NSDictionary(dictionary: HelperLaunchAgent.plist(helperBundle: helperUrl))
    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
    if success {
        print("file has been created!")
    }else{
        print("unable to create the file")
    }
    shell(launchPath: "/bin/launchctl", arguments: ["load", "-w", userLaunchAgentsPath])
}

func deleteLaunchAgent(){
    addLog(text: "func:- deleteLaunchAgent")
    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
    let path = Bundle.main.bundlePath
    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
        for uLA in userLA {
            if uLA.isCurrentlyLoaded{
                if let arguments = uLA.programArguments as? [String]{
                    if arguments.contains(where: {$0.caseInsensitiveCompare(path) == .orderedSame}) {
                        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                        addLog(text: "deleteLaunchAgent done")
                        return;
                    }
                }
            }
            
            
        }
    }
    //
    
}



func shell(launchPath: String, arguments: [String] = [])  {
    addLog(text: "func shell")
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
}





func showNotificationWithMessage(msg:String){
    let notification = NSUserNotification()
    //notification.informativeText = ""
    notification.title = msg
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
}






//***********Popup Block Confirm Window***************//
func getBlurFrameForBrowser(x:Int, y:Int, width:Int, height:Int, browser:BROWSER)->NSRect{
    switch browser{
    case ._SAFARI_:
        return NSRect(x: x, y: y + 81, width: width, height: height - 81)
    case . _GOOGLE_CHROME_:
        return NSRect(x: x, y: y + 85, width: width, height: height - 85)
    case . _OPERA_:
        return NSRect(x: x, y: y + 82, width: width, height: height - 82)
    case . _OPERA_GX_:
        return NSRect(x: x, y: y + 76, width: width, height: height - 76)
    case . _VIVALDI_:
        return NSRect(x: x, y: y + 67, width: width, height: height - 67)
    case ._BRAVE_BROWSER_:
        return NSRect(x: x, y: y + 77, width: width, height: height - 77)
    case ._SIDEKICK_:
        return NSRect(x: x, y: y + 79, width: width, height: height - 79)
    case ._MICROSOFT_EDGE_:
        return NSRect(x: x, y: y + 79, width: width, height: height - 79)
    case ._ARC_:
        return NSRect(x: x + 213, y: y + 40, width: width - 213, height: height - 40)
    case ._FIREFOX_:
        return NSRect(x: x, y: y + 81, width: width, height: height - 81)
    case ._SIGMA_OS_:
        return NSRect(x: x + 288, y: y + 48, width: width - 288, height: height - 48)
    case ._COMET_:
        return NSRect(x: x, y: y + 85, width: width, height: height - 85)
    }
}



func runAppleScriptFile(path:String){
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = [path]
    
    task.launch()
}

func runShellCommand(command:String){
    let task = Process()
    var args: [AnyHashable] = []
    args.append("-c")
    args.append(command)
    task.launchPath = "/bin/sh"
    task.arguments = args as? [String]
    task.launch()
}

/// Auto Do-Not-Disturb when a focus mode starts.
///
/// This was written out five times, in focusModeData, addTaskVc, pomodoroVc and pusherEvents, and
/// the copies had drifted: most also switch DND on for a deep-work or default block list when the
/// mode's own flag is off, and one does not. `includingDeepWorkAndDefault` keeps that difference
/// explicit at the call site rather than hidden in a fifth copy.
func applyAutoDoNotDisturb(forFocusModeAt index: Int, includingDeepWorkAndDefault: Bool) {
    guard arrFocusType.indices.contains(index) else { return }
    if arrFocusType[index]["isAutoDoNotDisturbEnabled"] as? Bool == true, isAccessibilityEnabled(isPrompt: true) {
        DNDManager.shared.setDND(true)
    }
    guard includingDeepWorkAndDefault, !DNDManager.shared.isDndEnabled else { return }
    let wantsDND = (arrFocusType[index]["isDeepWorkFocus"] as? Bool)
        ?? (arrFocusType[index]["isDefault"] as? Bool) ?? false
    if wantsDND, isAccessibilityEnabled(isPrompt: true) { DNDManager.shared.setDND(true) }
}

func workBeforeFocusBegin(index:Int){
    var appleScriptPath:String?
    var shellCommand:String?
    
    if let isScriptBeforeFocusEnabled = arrFocusType[index]["isScriptBeforeFocusEnabled"] as? Bool{
        if isScriptBeforeFocusEnabled{
            if let path = arrFocusType[index]["scriptPathBeforeFocus"] as? String{
                appleScriptPath = path
            }
        }
    }
    
    if let isShellCommandBeforeFocusEnabled = arrFocusType[index]["isShellCommandBeforeFocusEnabled"] as? Bool{
        if isShellCommandBeforeFocusEnabled{
            if let text = arrFocusType[index]["shellCommandBeforeFocusText"] as? String{
                if !text.isEmpty{
                    shellCommand = text
                }
            }
        }
    }
    
    if appleScriptPath == nil && shellCommand == nil{
        return;
    }

    var shouldShowConfirmationForScript = true
    
    if let state = UserDefaults.standard.object(forKey: kUserdefaultsDontConfirmBeforeExecuteScript) as? Bool{
        shouldShowConfirmationForScript = !state
    }else{
        UserDefaults.standard.set(false, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
    }
    
    if shouldShowConfirmationForScript{
        let name = arrFocusType[index]["name"] as? String ?? ""
        showConfirmRunScriptWindow(focusMode: name, scriptPath: appleScriptPath, shellCommand: shellCommand)
    }else{
        if let appleScriptPath = appleScriptPath{
            runAppleScriptFile(path: appleScriptPath)
        }
        if let shellCommand = shellCommand{
            runShellCommand(command: shellCommand)
        }
    }
}

func workAfterFocusBegin(index:Int){
    var appleScriptPath:String?
    var shellCommand:String?
    
    if let isScriptAfterFocusEnabled = arrFocusType[index]["isScriptAfterFocusEnabled"] as? Bool{
        if isScriptAfterFocusEnabled{
            if let path = arrFocusType[index]["scriptPathAfterFocus"] as? String{
                appleScriptPath = path
            }
        }
    }
    
    
    if let isShellCommandAfterFocusEnabled = arrFocusType[index]["isShellCommandAfterFocusEnabled"] as? Bool{
        if isShellCommandAfterFocusEnabled{
            if let text = arrFocusType[index]["shellCommandAfterFocusText"] as? String{
                if !text.isEmpty{
                    shellCommand = text
                }
            }
        }
    }
    
    if appleScriptPath == nil && shellCommand == nil{
        return;
    }

    var shouldShowConfirmationForScript = true
    
    if let state = UserDefaults.standard.object(forKey: kUserdefaultsDontConfirmBeforeExecuteScript) as? Bool{
        shouldShowConfirmationForScript = !state
    }else{
        UserDefaults.standard.set(false, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
    }
    
    if shouldShowConfirmationForScript{
        let name = arrFocusType[index]["name"] as? String ?? ""
        showConfirmRunScriptWindow(focusMode: name, scriptPath: appleScriptPath, shellCommand: shellCommand)
    }else{
        if let appleScriptPath = appleScriptPath{
            runAppleScriptFile(path: appleScriptPath)
        }
        if let shellCommand = shellCommand{
            runShellCommand(command: shellCommand)
        }
    }
}

//*****************************Read data from csv******************************//
func readDataFromCSV(url:URL)-> [[String]]{
    var arrItems = [[String]]()
    if let string = try? String(contentsOf: url){
        let arrCsv = csv(data: string)
        for item in arrCsv{
            if let row = item.first{
                var arrHeaders = [String]()
                let arrString = getArrItem(data: row)
                for header in arrString{
                    if header != "\r"{
                        arrHeaders.append(header)
                    }
                }
                arrItems.append(arrHeaders)
            }
        }
    }
    return arrItems
}
func csv(data: String) -> [[String]] {
    var result: [[String]] = []
    let rows = data.components(separatedBy: "\n")
    for row in rows {
        let columns = row.components(separatedBy: ";")
        result.append(columns)
    }
    return result
}
func getArrItem(data: String) -> [String] {
    var result: [String] = []
    result = data.components(separatedBy: ",")
    return result
}


var arrLanguageDic = [["name":"English", "id":"en", "languageName":"English"], ["name":"Spanish", "id":"es", "languageName":"Spanish"]]
/// Every language the bundled configuration ships, and the resource each one lives in.
///
/// English is `config.json`; every other language is `config-<code>.json` — the same rule the runtime
/// loader in `AppDelegate` already uses. Screens that preload their strings used to hardcode the pair
/// `[("en", "config"), ("es", "config-es")]`, so a new language loaded at runtime but was invisible to
/// every one of those screens. Add a language here and they all pick it up.
enum BundledConfigLanguage {
    static let english = "en"
    static let supported = [english, "es", "de", "fr", "pl"]

    /// `config` for English, `config-<code>` otherwise. The file does not have to exist yet: a missing
    /// one simply leaves that language falling back to English, which is what an untranslated app does.
    static func resource(_ code: String) -> String {
        code == english ? "config" : "config-\(code)"
    }

    /// The supported language CODE for the language in use ("es-419" → "es"), else English. Screens
    /// that keep their strings keyed by code look themselves up with this.
    static func code(_ code: String = currentLanguageCode) -> String {
        let base = code.lowercased().split(separator: "-").first.map(String.init) ?? english
        return supported.contains(base) ? base : english
    }

    /// (code, resource) for every supported language, for screens that preload all of them.
    static var all: [(code: String, resource: String)] { supported.map { ($0, resource($0)) } }

    /// The language NAME the AI endpoints expect ("please answer in <language>"). Without an entry a
    /// user gets English answers however well the UI is translated, so this list has to grow with
    /// `supported`.
    private static let apiNames = [
        "en": "english", "es": "spanish", "de": "german", "fr": "french", "pl": "polish",
    ]

    static func apiName(_ code: String = currentLanguageCode) -> String {
        let base = code.lowercased().split(separator: "-").first.map(String.init) ?? english
        return apiNames[base] ?? "english"
    }

    /// The bundled resource for the language in use, normalised ("es-419" → "es") and defaulting to English.
    static func current(_ code: String = currentLanguageCode) -> String {
        let base = code.lowercased().split(separator: "-").first.map(String.init) ?? english
        return resource(supported.contains(base) ? base : english)
    }
}

var currentLanguageCode = ""




func roundToHundred(number : Int) -> Int {
    let rounded = Int(number + 50)/100 * 100
    print(rounded) // 1398000
    return rounded
}
func roundToTen(number : Int) -> Int {
    let rounded = (number + 5)/10 * 10
    print(rounded) // 1398000
    return rounded
}
func roundOffValue(number : Int) -> Int {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}

func roundToHundred(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/100 * 100)
    print(rounded) // 1398000
    return rounded
}

func roundToTen(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/10 * 10)
    print(rounded) // 1398000
    return rounded
}

func roundOffValue(number : Double) -> Double {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}

func roundDoubleValue(val:Double)->Double{
    return Double(round(10 * val) / 10)
}






func getUuid()->String{
    return UUID().uuidString.lowercased()
}


func showAlertNoInternet(window:NSWindow){
    var noInternetTitle = "No Internet Connection"
    var noInternetSubTitle = "Make sure your device is connected to the internet."
    addLog(text: "No Internet Connection")
    if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{//useful text
        if let text = activationNagInfo.value(forKey: "noInternetTitle") as? String{
            noInternetTitle = text
        }
        if let text = activationNagInfo.value(forKey: "noInternetSubTitle") as? String{
            noInternetSubTitle = text
        }
    }
    let alert = NSAlert()
    alert.setSharingType()
    alert.messageText = noInternetTitle
    alert.informativeText = noInternetSubTitle
    alert.alertStyle = .warning
    alert.addButton(withTitle:  buttonOkText)
    alert.beginSheetModal(for: window, completionHandler: {_ in
        //  window.close()
        // Since v3.32.487, users are allowed to continue using the app even when internet connectivity is unavailable.
        // We no longer close the window when the internet is disconnected.
    })
}

/// Ask for the after-cutoff postpone password, running `onAuthorized` only if it is correct.
///
/// A fresh controller each time, matching `popupAppointmentTimeVc`: the shared preferences instance
/// carries its own presentation state and reusing it here showed the wrong view.
func askPostponePasswordAfterCutoff(presenter: NSViewController, onAuthorized: @escaping () -> Void) {
    guard let passwordVc = mainStoryboard.instantiateController(
        withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc else {
        // Without the sheet there is no way to ask, and silently postponing would be the hole the
        // password exists to close. Refusing is the safe direction.
        addLog(text: "askPostponePasswordAfterCutoff:- could not load enterPasswordVc, refusing")
        showCutoffPostponeRefusedAlert()
        return
    }
    passwordVc.requestAuthorization(action: onAuthorized)
    presenter.presentAsSheet(passwordVc)
}

/// Tells the user their cutoff time has passed, so the evening routine can't be postponed any further.
///
/// Used for the focus-session extension case (`forExtension`), where the cutoff genuinely leaves no
/// room for another whole minute, and as the fallback when the password sheet cannot be loaded.
func showCutoffPostponeRefusedAlert(forExtension: Bool = false) {
    var title = "Your cutoff time has passed"
    var message = "It's past your cutoff time, so your evening routine can't be postponed any further."
    if let activityPostponeInfo = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary{
        title = activityPostponeInfo.value(forKey: "cutoffPostponeRefusedTitle") as? String ?? title
        message = activityPostponeInfo.value(forKey: "cutoffPostponeRefusedText") as? String ?? message
    }
    if forExtension {
        let info = configjson.value(forKey: "activityPostponeInfo") as? NSDictionary
        title = info?.value(forKey: "cutoffExtensionRefusedTitle") as? String ?? "Your cutoff limits this extension" // i18n-ignore: bundled config fallback
        message = info?.value(forKey: "cutoffExtensionRefusedText") as? String ?? "This focus session cannot be extended past <TIME>. There is no room for another full minute." // i18n-ignore: bundled config fallback
    }
    message = message.replacingOccurrences(of: "<TIME>", with: cutOffTimeString)
    let alert = NSAlert()
    alert.setSharingType()
    alert.alertStyle = .informational
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: buttonOkText)
    if let window = mainWindowControllerObj?.window, window.isVisible, !window.isMiniaturized{
        alert.beginSheetModal(for: window, completionHandler: { _ in })
    }else{
        alert.runModal()
    }
}



var allActivityTodaySummaryData:NSDictionary?
var graphOneMonthData:NSDictionary?
var graphOneDayData:[NSDictionary]?
var graphOneDayDataForQuantity:NSDictionary?

var focusModeTemplateData:[NSDictionary]?
var habitPacksData:[NSDictionary]?



func setDocBarTo(isHide:Bool){
    DispatchQueue.global().async {
        if !SettingsManagerObject.isHideDockInActivity{
            return
        }
        guard !shouldSkipSystemEventsAppleEvent() else { return }
        var script: String = ""
        var hideVal = "true"
        if isHide{
            addLog(text:"set Doc Bar To hide")
            hideVal = "true"
        }else{
            addLog(text:"set Doc Bar To unhide")
            hideVal = "false"
        }
        
        script =
        """
        tell application "System Events"
        set autohide of dock preferences to \(hideVal)
        end tell
        """
        
        executeScript(script: script)
    }
}

func checkDocBarState()->String?{
    guard !shouldSkipSystemEventsAppleEvent() else { return nil }
    var script: String = ""

    script =
    """
    tell application "System Events"
    set val to autohide of dock preferences
    end tell
    """
    
    var errors : NSDictionary? = nil
    let desc = runAppleScriptSafely(script, errors: &errors)
    if errors != nil {
        print(errors!)
    }
    return desc?.stringValue
}







var defaultBrowser: String? {
    NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http://")!)
        .flatMap(Bundle.init(url:))
        .flatMap {
            $0.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? $0.object(forInfoDictionaryKey: "CFBundleName")
        }.flatMap {
            $0 as? String
        }
}

var isBreakActivityShowingWhileMeeting = false

func getAppVersionInString()-> String{
    if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
        return version + "." + build
    }
    return ""
}


var appVersion = ""
var macOSVersion = ""


// **************************Font Work*******************************//
var systemFontIndex = 0
var intelOneMonoIndex = 7
var openDyslexicIndex = 8
var poppinsIndex = 9
let arrFont:[fontStyle] = [fontStyle(name: "System Font", regularFontName: "System Font", boldFontName: "System Font Bold", webFontName: "San Francisco"),
                           fontStyle(name: "Arial", regularFontName: "Arial", boldFontName: "Arial Bold", webFontName: "Arial"),
                           fontStyle(name: "Comic Sans MS", regularFontName: "Comic Sans MS", boldFontName: "Comic Sans MS Bold", webFontName: "Comic Sans MS"),
                           fontStyle(name: "Verdana", regularFontName: "Verdana", boldFontName: "Verdana Bold", webFontName: "Verdana"),
                           fontStyle(name: "Tahoma", regularFontName: "Tahoma", boldFontName: "Tahoma Bold", webFontName: "Tahoma"),
                           fontStyle(name: "Trebuchet MS", regularFontName: "Trebuchet MS", boldFontName: "Trebuchet MS Bold", webFontName: "Trebuchet MS"),
                           fontStyle(name: "Helvetica", regularFontName: "Helvetica", boldFontName: "Helvetica Bold", webFontName: "Helvetica"),
                           fontStyle(name: "IntelOneMono", regularFontName: "IntelOneMono-Regular", boldFontName: "IntelOneMono-Regular", webFontName: "Intel One Mono"),
                           fontStyle(name: "OpenDyslexic", regularFontName: "OpenDyslexicThree-Regular", boldFontName: "OpenDyslexicThree-Regular", webFontName: "Open Dyslexic"),
                           fontStyle(name: "Poppins", regularFontName: "Poppins-Regular", boldFontName: "Poppins-Regular", webFontName: "Poppins"),
                           fontStyle(name: "Lexend", regularFontName: "Lexend-Regular", boldFontName: "Lexend-Bold", webFontName: "Lexend")]

/// Index of Lexend in arrFont — the app's default font.
let lexendFontIndex = 10

struct fontStyle{
    var name = ""
    var regularFontName = ""
    var boldFontName = ""
    var webFontName = ""
    
    init(name:String, regularFontName:String, boldFontName:String, webFontName:String){
        self.name = name
        self.regularFontName = regularFontName
        self.boldFontName = boldFontName
        self.webFontName = webFontName
    }
}

let intelOneMonoFontIndex = 7
let openDyslexicFontIndex = 8
let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex]

/// A digits-only number formatter capped at three characters, used by the duration/ratio/tab-limit
/// text fields. It lived on the old pomodoro start screen; that screen is SwiftUI now, so it moved
/// here to the other shared helpers rather than being deleted with the scene.
class IntegerFormatter: NumberFormatter {
    let maxLength = 3

    let wrongCharacterSet = CharacterSet(charactersIn: "0123456789").inverted
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        self.maximumFractionDigits = 2
        self.minimumFractionDigits = 0

        if partialString.count > maxLength {
            return false
        }
        if partialString.rangeOfCharacter(from: wrongCharacterSet) != nil {
            return false
        }
        return true
    }
}

func getRegularFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.systemFont(ofSize: size)
    }
    return NSFont(name: selectedFont.regularFontName, size: size) ?? NSFont.systemFont(ofSize: size)
}
func getBoldFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.boldSystemFont(ofSize: size)
    }
    return NSFont(name: selectedFont.boldFontName, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}

func getMediumFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.systemFont(ofSize: size, weight: .medium)
    }
    return NSFont(name: selectedFont.regularFontName, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}

func getSemiBoldFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.systemFont(ofSize: size, weight: .semibold)
    }
    return NSFont(name: selectedFont.boldFontName, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}




func fileCreationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.creationDate] as? Date
    } catch {
        return nil
    }
}

func checkLogFileRotation(){
    addLog(text: "func:- checkLogFileRotation")
    if let date = fileCreationDate(url: DebugLogsURL){
        print(date)
        let diffInDays = Date().interval(ofComponent: .day, fromDate: date)
        print(diffInDays)
        
        if diffInDays > 3{
            let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
            let oldDebugLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Logs - \(timestamp).txt")
            addLog(text: "func:- checkLogFileRotation:- log file will move")
            do{
                try  FileManager.default.moveItem(at: DebugLogsURL, to: oldDebugLogsURL)
            }catch{
                print(error)
            }
        }
        
    }
    addLog(text: "func:- checkLogFileRotation:- checkCount")
    let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
    let array = try? FileManager.default.contentsOfDirectory(at: DebugLogsFolderURL!, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
    if array != nil{
        var arrayOfPath = [[String:Any]]()
        for url in array!{
            
            if url.pathExtension == "txt"{
                print(url)
                if let date = fileCreationDate(url: url){
                    arrayOfPath.append(["url":url, "date":date])
                }
            }
            
        }
        if arrayOfPath.count > 5{
            arrayOfPath = arrayOfPath.sorted(by: { ($0["date"] as! Date).compare($1["date"] as! Date) == .orderedDescending })
            
            while arrayOfPath.count > 5{
                do{
                    try FileManager.default.removeItem(at: arrayOfPath[5]["url"] as! URL)
                }catch{
                    print(error)
                }
                arrayOfPath.remove(at: 5)
            }
        }
    }
}


func isAccessibilityEnabled(isPrompt: Bool) -> Bool {// if  isPrompt is true it means setting prompt will be visible
    if #available(OSX 12.0, *) {
        if isPrompt{
            let checkOptionPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let opts = [checkOptionPromptKey: isPrompt] as CFDictionary
            return AXIsProcessTrustedWithOptions(opts)
        }else{
            return AXIsProcessTrusted()
        }
    }else{
        return true
    }
    
}
//*********************************************************//




func forceCompleteIfAnyHabitGoing(){
    
    addLog(text: "get Last Activity Info - forceCompleteIfAnyActivityGoing")
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    
    var sequenceId = ""
    if lastCurrentState == ._MORNING_HABIT_{// no need to force complete in morning routine
//        sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
//        UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
    }else if lastCurrentState == ._FOCUS_SUMMARY_ || lastCurrentState == ._EVENING_HABIT_{
        sequenceId = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }
    }else{
        addLog(text: "force Complete Current Sequence - no Sequence found to complete")
        return
    }
    
    if sequenceId.isEmpty{
        addLog(text: "force Complete Current Sequence - SequenceId is blank :- return")
        return
    }
    addLog(text: "force Complete Current Sequence - forceCompleteIfAnyActivityGoing")
    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
        
        // and strt break activity
        DispatchQueue.main.async {
            
        }
    })
    
    
}




func zipTextFile(inputFilePath: String, outputZipPath: String) throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: outputZipPath){
        do{
            try fm.removeItem(atPath: outputZipPath)
        }catch{
            print(error.localizedDescription)
        }
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    // Define arguments for the `zip` command
    let fileName = (inputFilePath as NSString).lastPathComponent
    process.arguments = ["-j", outputZipPath, inputFilePath]
    
    // Run the process
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("Zipped file created at \(outputZipPath)")
    } else {
        throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to zip file."])
    }
}


func zipItem(inputPath: String, outputZipPath: String) throws {
    let fm = FileManager.default
    
    // Remove old zip if it exists
    if fm.fileExists(atPath: outputZipPath) {
        try fm.removeItem(atPath: outputZipPath)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    var isDir: ObjCBool = false
    fm.fileExists(atPath: inputPath, isDirectory: &isDir)
    
    if isDir.boolValue {
        // For folder → use -r (recursive)
        let folderName = (inputPath as NSString).lastPathComponent
        let parentPath = (inputPath as NSString).deletingLastPathComponent
        
        process.currentDirectoryURL = URL(fileURLWithPath: parentPath)
        process.arguments = ["-r", outputZipPath, folderName]
    } else {
        // For file → keep -j (junk paths, no directory structure)
        process.arguments = ["-j", outputZipPath, inputPath]
    }
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Zipped at \(outputZipPath)")
    } else {
        throw NSError(
            domain: "ZipError",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Failed to zip item."]
        )
    }
}



func zipItems(inputPaths: [String], outputZipPath: String) throws {
    let fm = FileManager.default
    
    // Remove old zip if it exists
    if fm.fileExists(atPath: outputZipPath) {
        try fm.removeItem(atPath: outputZipPath)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    // Separate into parent dir + relative names (so zip doesn’t store absolute paths)
    var allArguments: [String] = ["-r", outputZipPath]
    
    var parentDir: String?
    for path in inputPaths {
        let parent = (path as NSString).deletingLastPathComponent
        if parentDir == nil { parentDir = parent }
        // Ensure all files are from same parent directory, otherwise paths get long
        allArguments.append((path as NSString).lastPathComponent)
    }
    
    if let parentDir = parentDir {
        process.currentDirectoryURL = URL(fileURLWithPath: parentDir)
    }
    
    process.arguments = allArguments
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Zipped at \(outputZipPath)")
    } else {
        throw NSError(
            domain: "ZipError",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Failed to zip items."]
        )
    }
}

func createZipArchive(zipPath: String, logFolder: String, screenshots: [URL]) throws {
    let fileManager = FileManager.default

    // Remove old zip if exists
    if fileManager.fileExists(atPath: zipPath) {
        try fileManager.removeItem(atPath: zipPath)
    }

    // Create temporary folder for Screenshots
    let logParent = URL(fileURLWithPath: logFolder).deletingLastPathComponent()
    let screenshotsFolder = logParent.appendingPathComponent("Screenshots", isDirectory: true)

    if fileManager.fileExists(atPath: screenshotsFolder.path) {
        try fileManager.removeItem(at: screenshotsFolder)
    }
    
    if screenshots.count != 0{
        try fileManager.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true)
    }

    // Copy screenshots into the temporary Screenshots folder
    for sourceURL in screenshots {
        let destURL = screenshotsFolder.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destURL)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    
    // Run /usr/bin/zip
    var arguments: [String] = ["-r", zipPath]
    var itemsToZip: [String] = []
    let logURL = URL(fileURLWithPath: logFolder)
    let parentDir = logURL.deletingLastPathComponent()
    process.currentDirectoryURL = parentDir
    itemsToZip.append(logURL.lastPathComponent)
    
    if screenshots.count != 0{
        itemsToZip.append(screenshotsFolder.lastPathComponent)
    }
    arguments.append(contentsOf: itemsToZip)
    process.arguments = arguments
    

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }

    if process.terminationStatus != 0 {
        throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: [
            NSLocalizedDescriptionKey: "Failed to create zip archive"
        ])
    }
    if fileManager.fileExists(atPath: screenshotsFolder.path) {
        try fileManager.removeItem(at: screenshotsFolder)
    }
}




var arrAllTracks = [[String:Any]]()
/// True while focus music is playing because the user accepted the post-session-start prompt — so
/// it can be stopped when that focus session ends (music the user started manually is left alone).
var isFocusMusicStartedFromPrompt = false

func checkAllTracksDownloadState(){
    for track in arrAllTracks{
        let thumbnailLocalUrlString = track["thumbnailLocalUrl"] as? String ?? ""
        let thumbnailLocalUrl = URL(fileURLWithPath: thumbnailLocalUrlString)
        let thumbnail_download_urlString = track["thumbnail_download_url"] as? String ?? ""
        let thumbnail_download_url = URL(string: thumbnail_download_urlString)//URL(fileURLWithPath: download_urlString)
        
        if !FileManager.default.fileExists(atPath: thumbnailLocalUrlString){
            allApiObject.downloadFileAsync(url: thumbnail_download_url, destinationUrl: thumbnailLocalUrl){ (success, error) in
                checkAllTracksDownloadState()
                DispatchQueue.main.async {
                    reloadFocusMusicListIfVisible()
                }
            }
            break;
        }
    }
}

func shouldDoHabits()->Bool{//after onboarding cards morning evening routine should not show till 2 hours
    if let date = UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) as? Date{
        let currentDate = Date()
        let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
        if diffHours > 1{//it means after onboarding cards morning evening routine will not show till 2 hours
            return true
        }else{
            return false
        }
    }
    return true
}



func getLastHabitDoneDuration(lastHabit:habit)->Int{
    var duration = 0
    if lastHabit.useTimer{
        duration = lastHabit.durationSeconds!
    }else{
        duration = Calendar.current.dateComponents([.second], from: lastActivityPerformedTime!, to: Date()).second ?? 0
    }
    return duration
}


func getLastActivityDoneDuration(lastActivity:breakActivity)->Int{
    var duration = 0
    if lastActivity.useTimer{
        duration = lastActivity.durationSeconds!
    }else{
        duration = Calendar.current.dateComponents([.second], from: lastActivityPerformedTime!, to: Date()).second ?? 0
    }
    return duration
}


var arrForSearchFromSettings = [[String:Any]]()
var arrForSearchFromSimpleModeSettings = [[String:Any]]()

var arrAlwaysBlockedSitesData = [[String:Any]]()
var arrAlwaysBlockedAppsData = [[String:Any]]()

var defaultBreakDurationValue = 20

var macGoesInSleepTime:Date?
var shouldShowPomodoroAfterBreak = false
var shouldEndPomodoroBreakAtTime:Date?


/// Dedicated serial queue that owns ALL AppleScript execution. NSAppleScript is NOT thread-safe —
/// compiling/running it from more than one thread at once corrupts the shared AppleScript component
/// (the EXC_BAD_ACCESS segfault inside Apple's AppleScript compiler). Funnelling every script through
/// one serial queue means two scripts never run concurrently, which removes the crash — without
/// pinning the work to the main thread (the frequent focus-timer / browser detection scripts run on
/// this background queue and never block the UI).
private let appleScriptSerialQueue = DispatchQueue(label: "com.focusbear.applescript")
// exitFullScreen runs its AppleScript here when called on the main thread, so the app-switch path
// never blocks the UI (see the App-Hang note on exitFullScreen). MUST be separate from
// appleScriptSerialQueue — runAppleScriptSafely dispatches onto that queue and waits, so running
// exitFullScreen there too would deadlock.
private let fullScreenExitQueue = DispatchQueue(label: "com.focusbear.fullscreenexit", qos: .userInitiated)

/// Cumulative main-thread AppleScript wait budget per runloop turn (#2315). runAppleScriptSafely caps
/// each INDIVIDUAL main-thread wait at 1.2s, but callers that chain 2–3 scripts back-to-back (e.g.
/// `exitFullScreen`'s warm-up + `isAppInFullScreen` + keystroke) stack those caps to ~3s and trip the 2s
/// App Hang threshold. This bounds the TOTAL main-thread AppleScript wait within a single runloop turn:
/// once ~1.5s has been spent this turn, further main-thread scripts are skipped (return nil) rather than
/// adding more wait — the callers already tolerate a dropped script (they poll). A CFRunLoopObserver
/// resets the counter each time the main runloop goes idle (`.beforeWaiting`), i.e. once per turn.
/// All access is main-thread-only (background callers never touch it), so no locking is needed.
private let mainThreadAppleScriptBudget: TimeInterval = 1.5
private var mainThreadAppleScriptSpentThisTurn: TimeInterval = 0
private var mainThreadAppleScriptBudgetObserverInstalled = false

private func installMainThreadAppleScriptBudgetResetIfNeeded() {
    guard Thread.isMainThread, !mainThreadAppleScriptBudgetObserverInstalled else { return }
    mainThreadAppleScriptBudgetObserverInstalled = true
    let observer = CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { _, _ in
        mainThreadAppleScriptSpentThisTurn = 0
    }
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
}

/// Single safe entry point for running AppleScript. Serialised on `appleScriptSerialQueue` (see above)
/// so it can't run concurrently from multiple threads. The source is wrapped in `with timeout of N
/// seconds`, and we additionally guard with a wall-clock timeout so an unresponsive target app can't
/// wedge the queue or block the caller indefinitely.
@discardableResult
func runAppleScriptSafely(_ source: String, timeoutSeconds: Int = 5, errors: inout NSDictionary?, authorization: @escaping () -> Bool = { true }) -> NSAppleEventDescriptor? {
    // The script runs on `appleScriptSerialQueue`, but the semaphore wait below blocks the *caller*.
    // On the MAIN thread that means a frozen UI, so cap the main-thread wait hard: browser/URL and
    // focus-timer scripts return in well under 100 ms normally, and only a hung target app would ever
    // approach the cap — in which case we'd far rather skip this detection cycle (the callers poll, e.g.
    // the 1 s URL-block timer) than lock the UI. The dropped script keeps running on the queue; we just
    // don't read its result. Background callers keep the full, generous timeout.
    let onMain = Thread.isMainThread
    // #2315: bound the cumulative main-thread AppleScript wait per runloop turn so chained callers can't
    // stack the per-call caps into a multi-second UI freeze. Once this turn's budget is spent, skip the
    // script entirely (the callers poll, so a dropped detection cycle is fine). Only ever touch the
    // budget counter on the main thread.
    var mainWaitSeconds = 1.2
    if onMain {
        installMainThreadAppleScriptBudgetResetIfNeeded()
        let remaining = mainThreadAppleScriptBudget - mainThreadAppleScriptSpentThisTurn
        if remaining <= 0 {
            addLog(text: "runAppleScriptSafely: main-thread AppleScript budget spent this runloop turn — skipping to protect the UI")
            errors = nil
            return nil
        }
        mainWaitSeconds = min(1.2, remaining)
    }
    let scriptTimeout = onMain ? min(timeoutSeconds, 1) : timeoutSeconds
    let waitCap: DispatchTimeInterval = onMain ? .milliseconds(Int(mainWaitSeconds * 1000)) : .seconds(timeoutSeconds + 2)
    let bounded = "with timeout of \(scriptTimeout) seconds\n" + source + "\nend timeout\n"
    var capturedErrors: NSDictionary?
    var result: NSAppleEventDescriptor?
    let done = DispatchSemaphore(value: 0)
    // The caller blocks on `done.wait` below. If the caller runs at a higher QoS than this queue's
    // default (e.g. the main thread at user-interactive), that's a priority inversion — a high-QoS
    // thread waiting on lower-QoS work — which Xcode's Thread Performance Checker flags (the purple
    // "priority inversion" runtime warning). Donate the caller's QoS to the dispatched block so the
    // AppleScript runs at (at least) the waiting thread's priority and the inversion goes away.
    let callerQoS = DispatchQoS(qosClass: DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .default,
                                relativePriority: 0)
    appleScriptSerialQueue.async(qos: callerQoS, flags: .enforceQoS) {
        guard authorization() else { done.signal(); return }
        if let appleScript = NSAppleScript(source: bounded) {
            result = appleScript.executeAndReturnError(&capturedErrors)
        }
        done.signal()
    }
    // Wall-clock guard a little longer than the AppleScript `with timeout`, so the script normally
    // finishes first. On timeout we return without reading the still-running block's outputs.
    let waitStart = Date()
    let timedOut = done.wait(timeout: .now() + waitCap) == .timedOut
    if onMain {
        // #2315: charge the actual time this call blocked the main thread against the runloop-turn budget
        // (fast successes cost ~nothing; a slow/hung call costs up to its cap), so a later chained call
        // sees the reduced remaining budget — or is skipped once the turn's budget is exhausted.
        mainThreadAppleScriptSpentThisTurn += Date().timeIntervalSince(waitStart)
    }
    if timedOut {
        errors = nil
        return nil
    }
    errors = capturedErrors
    return result
}

func executeScript(script:String){
    var errors : NSDictionary? = nil
    runAppleScriptSafely(script, errors: &errors)
    if errors != nil {
        print(errors!)
    }
}

func executeScriptAndReturnBool(script:String)->Bool{
    var errors : NSDictionary? = nil
    let desc = runAppleScriptSafely(script, errors: &errors)
    if errors != nil {
        print(errors!)
    }
    return desc?.booleanValue ?? false
}


/// Which RevenueCat entitlements mean the account is paid.
///
/// A user commonly holds several at once: a team admin's `activeEntitlements` comes back as
/// `[team_admin, team_member, team_owner]`. The old check read only `activeEntitlements.first`, so
/// `team_admin` sorting first marked a fully paid admin as unpaid — being an admin was itself enough
/// to be offered an upgrade (report 2026-09-14_19-47-35). Any qualifying entitlement now counts.
enum SubscriptionEntitlements {
    static let paid: Set<String> = ["personal", "team_admin", "team_member", "team_owner", "team_size_5"]

    /// The entitlement granting access, or nil when none of the active ones do. Returned rather than
    /// a Bool because the caller looks the expiry up by entitlement name.
    static func payingEntitlement(in active: [String]) -> String? {
        active.first(where: { paid.contains($0) })
    }
}

func executeScriptAndReturnString(script:String)->String?{
    var errors : NSDictionary? = nil
    let desc = runAppleScriptSafely(script, errors: &errors)
    switch BrowserScriptStringResult.interpret(value: desc?.stringValue, hasDescriptor: desc != nil, errors: errors) {
    case .value(let value):
        return value
    case .automationDenied(let application):
        if let browser = getCurrentBrowserFrom(browserName: application.lowercased()) {
            recordBrowserAutomationPermission(browser: browser, enabled: false)
        }
        return nil
    case .unavailable:
        return nil
    }
}

/// `isQuickLookPreview`: the block is a Quick Look preview and `appName` is the previewed file's name,
/// so the card says "Previewing <file> …" instead of treating the file as an app.
func showFocusAppBlockNotification(appName: String, runningApp: NSRunningApplication? = nil, isQuickLookPreview: Bool = false){
    addLog(text: "show Focus App Block Notification called")
    let arrAppsAvoidNotification = ["loginwindow", "screensaverengine"]//lowercased
    if arrAppsAvoidNotification.contains(appName.lowercased()){
        addLog(text: "func showFocusAppBlockNotification:- AppsAvoidNotification contain app:- return")
        return;
    }

    // Teacher-controlled class session: the student can't unblock apps themselves, so the card shows a
    // class-session message + a "Request unlock" button. A normal focus session keeps the old message
    // and has no button.
    let isTeacherSession = teacherSessionManagerObject.isTeacherSessionActive()
    var msg: String
    if isTeacherSession {
        if isQuickLookPreview {
            msg = "Previewing <FILE_NAME> is blocked during your class session. Ask your teacher to unlock it."
        } else {
            msg = "<APP_NAME> is blocked during your class session. Ask your teacher to unlock it."
        }
        if let teacherInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
            let key = isQuickLookPreview ? "quickLookBlockedRequestUnlockText" : "appBlockedRequestUnlockText"
            msg = teacherInfo.value(forKey: key) as? String ?? msg
        }
    } else {
        if isQuickLookPreview {
            msg = "Previewing <FILE_NAME> isn't allowed in the <FOCUS_NAME> focus mode."
        } else {
            msg = "<APP_NAME> isn't allowed in the <FOCUS_NAME> focus mode."
        }
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            let key = isQuickLookPreview ? "quickLookBlockNotificationTitle" : "appBlockNotificationTitle"
            msg = common.value(forKey: key) as? String ?? msg
        }
        var focusMode = ""
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                focusMode = dic["name"] as? String ?? ""
                break;
            }
        }
        msg = msg.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
    }
    msg = msg.replacingOccurrences(of: isQuickLookPreview ? "<FILE_NAME>" : "<APP_NAME>", with: appName)
    addLog(text: "func showFocusAppBlockNotification:- show notification for app:- \(appName)")
    // Show a custom top-right notification every time the app is blocked. Unlike the old
    // NSUserNotification path there is NO one-time-per-session limit; the manager only suppresses a
    // duplicate while this app's card is still on screen (see FocusBlockNotificationManager).
    FocusBlockNotificationManager.shared.show(appName: appName, message: msg, isTeacherSession: isTeacherSession, runningApp: runningApp)
}

/// Shows the custom "app blocked by Focus Mode" notification in the top-right corner of the main
/// screen. Replaces the deprecated `NSUserNotification` path, which stopped delivering reliably on
/// modern macOS. The notification is a borderless overlay card that fades in, counts down, then fades
/// out. Only ONE notification is ever visible: a block of a DIFFERENT app replaces the current one; a
/// block of the SAME app that's already showing is ignored (so its countdown isn't restarted). There
/// is deliberately no per-session restriction.
final class FocusBlockNotificationManager {
    static let shared = FocusBlockNotificationManager()
    private init() {}

    private let visibleDuration: TimeInterval = 5
    private let cardWidth: CGFloat = 340        // height is derived per-card from its content
    private let edgeMargin: CGFloat = 16

    // The single on-screen notification, if any.
    private var currentCard: FocusBlockNotificationCard?

    func show(appName: String, message: String, isTeacherSession: Bool, runningApp: NSRunningApplication? = nil) {
        // UI work — hop to the main thread (the app-blocking monitor runs off-main).
        if !Thread.isMainThread {
            DispatchQueue.main.async { self.show(appName: appName, message: message, isTeacherSession: isTeacherSession, runningApp: runningApp) }
            return
        }
        // Same app already showing → leave it be (don't restart its countdown).
        if currentCard?.appName == appName { return }
        guard let screen = NSScreen.main else { return }

        // Only one notification at a time — drop any existing (different-app) card immediately.
        removeCurrent()

        // Brand title shown at the top of the card (e.g. "Focus Bear").
        var brandTitle = "Focus Bear"
        if let common = configjson.value(forKey: "common") as? NSDictionary {
            brandTitle = common.value(forKey: "appName") as? String ?? brandTitle
        }
        // The card carries one optional action button:
        //   • Teacher session → "Request unlock" opens the unlock-request window pre-filled with this app.
        //   • Normal focus session → "Oops I actually need it" re-presents the app block-confirm popup (the
        //     same allow/set-intention flow the URL block page offers via its cuddly "unblock it" button),
        //     letting the user through the app.
        var actionTitle: String? = nil
        if isTeacherSession {
            var title = "Request unlock"
            if let teacherInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary {
                title = teacherInfo.value(forKey: "buttonRequestUnlock") as? String ?? title
            }
            actionTitle = title
        } else if runningApp != nil && SettingsManagerObject.isCuddlyModeEnabled {
            // "Oops I actually need it" re-presents the app block-confirm popup (allow / set intention).
            // That popup is only the block flow in cuddly mode — in strict (non-cuddly) mode an unwanted
            // app is hard-blocked with just this notification and NO confirm popup, so offering the button
            // there would hand the user an escape hatch strict mode deliberately withholds. Gate it on
            // cuddly mode: show the button only where the confirm popup is actually part of the flow.
            var title = "Oops I actually need it"
            if let common = configjson.value(forKey: "common") as? NSDictionary {
                title = common.value(forKey: "appBlockNotificationAllowButton") as? String ?? title
            }
            actionTitle = title
        }

        let card = FocusBlockNotificationCard(appName: appName, brandTitle: brandTitle, message: message,
                                              actionTitle: actionTitle,
                                              seconds: Int(visibleDuration), width: cardWidth)
        card.onAction = { [weak self, weak card] in
            if isTeacherSession {
                teacherSessionManagerObject.showTeacherUnlockRequestWindow(prefillAppOrUrl: appName)
            } else if let runningApp = runningApp {
                // "Oops I actually need it" — mirror the URL block's "unblock it for me" (checkUrlIsUnlock):
                // drop the app from the per-session blocked list so it's treated as fresh, then bring it
                // back to the front. When it becomes the running context again, the app-blocking monitor
                // re-runs focusTryToBlockUnwantedApp — which, no longer finding it in
                // arrBlockedAppsInCuddlyModeCurrentFocus, presents popUpBlockConfirmVc (allow / set
                // intention) through the normal flow. We don't force-show that popup ourselves here.
                if let idx = arrBlockedAppsInCuddlyModeCurrentFocus.firstIndex(of: runningApp) {
                    arrBlockedAppsInCuddlyModeCurrentFocus.remove(at: idx)
                }
                allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                runningApp.unhide()
                runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
            guard let self = self, let card = card else { return }
            self.dismiss(card)
        }
        card.onExpire = { [weak self, weak card] in
            guard let self = self, let card = card else { return }
            self.dismiss(card)
        }
        currentCard = card

        let area = screen.visibleFrame
        let frame = card.window.frame
        card.window.setFrameOrigin(NSPoint(x: area.maxX - frame.width - edgeMargin,
                                           y: area.maxY - edgeMargin - frame.height))
        card.window.alphaValue = 0
        card.window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            card.window.animator().alphaValue = 1
        }
        card.startCountdown()
    }

    /// Instantly tear down the current card (used when a new notification replaces it).
    private func removeCurrent() {
        guard let card = currentCard else { return }
        card.stopCountdown()
        card.window.orderOut(nil)
        currentCard = nil
    }

    /// Fade out and remove `card` when it expires or is dismissed via its button.
    private func dismiss(_ card: FocusBlockNotificationCard) {
        guard currentCard === card else { return }   // already replaced/removed
        card.stopCountdown()
        currentCard = nil
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            card.window.animator().alphaValue = 0
        }, completionHandler: {
            card.window.orderOut(nil)
        })
    }
}

/// One notification card + its overlay window. Built in AppKit (NSVisualEffectView) so it renders a
/// native blurred, rounded card and works on the app's macOS 11 deployment target. Layout: the Focus
/// Bear icon on the left, a bold brand title, the (multi-line) message, and a bottom row with a
/// live seconds countdown on the right — plus, in a teacher session, an orange "Request unlock" button.
private final class FocusBlockNotificationCard: NSObject {
    let appName: String
    let window: NSWindow
    private let actionButton: NSButton?
    private let secondsLabel: NSTextField
    private var secondsRemaining: Int
    private var countdownTimer: Timer?
    var onAction: (() -> Void)?
    var onExpire: (() -> Void)?

    init(appName: String, brandTitle: String, message: String, actionTitle: String?,
         seconds: Int, width: CGFloat) {
        self.appName = appName
        self.secondsRemaining = seconds

        let padding: CGFloat = 14
        let iconSize: CGFloat = 40
        let gap: CGFloat = 12
        let cornerRadius: CGFloat = 14
        let textX = padding + iconSize + gap
        let textRight = width - padding
        let textWidth = textRight - textX

        // Title ("Focus Bear").
        let titleFont = NSFont.systemFont(ofSize: 14, weight: .bold)
        let titleHeight = ceil((brandTitle as NSString).size(withAttributes: [.font: titleFont]).height)

        // Message — smaller than the title. Measure the WRAPPED height for the fixed text width so it
        // wraps instead of running off the right edge (sizeToFit would instead widen it to one line).
        let messageFont = NSFont.systemFont(ofSize: 12, weight: .regular)
        let messageHeight = ceil((message as NSString).boundingRect(
            with: NSSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: messageFont]).height)

        // Optional action button ("Request unlock" in a teacher session, "Oops I actually need it" in a
        // normal session). Reuses the app's `Button` for the brand-orange fill + pointing-hand cursor on
        // hover. Created in code, so its awakeFromNib visual setup (layer, tracking area for the cursor) is
        // replicated here.
        var button: FocusBlockUnlockButton? = nil
        var buttonSize = NSSize.zero
        if let unlockTitle = actionTitle {
            let buttonFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
            let b = FocusBlockUnlockButton(title: "", target: nil, action: nil)
            b.font = buttonFont
            b.horizontalPadding = 0
            b.verticalPadding = 0
            b.wantsLayer = true
            b.isBordered = false
            b.title = unlockTitle                      // Button.title didSet → centered white title
            b.layer?.cornerRadius = 6
            b.layer?.backgroundColor = b.buttonColor   // brand orange
            b.contentTintColor = b.titleColor
            b.addTrackingArea(NSTrackingArea(rect: .zero,
                                             options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
                                             owner: b, userInfo: nil))
            let titleWidth = (unlockTitle as NSString).size(withAttributes: [.font: buttonFont]).width
            buttonSize = NSSize(width: ceil(titleWidth) + 34, height: 28)
            button = b
        }
        self.actionButton = button

        // Countdown (hourglass + "Ns"), bottom-right.
        let countdownHeight: CGFloat = 18
        let hourglassSize = NSSize(width: 11, height: 16)
        let secondsFont = NSFont.systemFont(ofSize: 12, weight: .medium)
        let secondsWidth = ceil(("00s" as NSString).size(withAttributes: [.font: secondsFont]).width)
        let secLabel = NSTextField(labelWithString: "\(seconds)s")
        secLabel.font = secondsFont
        secLabel.textColor = .secondaryLabelColor
        self.secondsLabel = secLabel
        let countdownWidth = hourglassSize.width + 3 + secondsWidth

        let bottomRowHeight = max(buttonSize.height, countdownHeight)

        let titleToMsg: CGFloat = 6      // clear separation between title and the smaller subtitle
        let msgToBottom: CGFloat = 8
        let contentHeight = titleHeight + titleToMsg + messageHeight + msgToBottom + bottomRowHeight
        let cardHeight = max(iconSize, contentHeight) + padding * 2
        let size = NSSize(width: width, height: cardHeight)

        let container = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        container.material = .popover      // adapts to light/dark so .labelColor text stays legible
        container.blendingMode = .behindWindow
        container.state = .active
        container.maskImage = FocusBlockNotificationCard.roundedMaskImage(cornerRadius: cornerRadius)

        // Icon — the Focus Bear app icon (branded), not the blocked app's icon.
        let iconView = NSImageView(frame: NSRect(x: padding, y: cardHeight - padding - iconSize,
                                                 width: iconSize, height: iconSize))
        iconView.image = NSImage(named: NSImage.applicationIconName)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        container.addSubview(iconView)

        // Title.
        let titleY = cardHeight - padding - titleHeight
        let titleLabel = NSTextField(labelWithString: brandTitle)
        titleLabel.font = titleFont
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: textX, y: titleY, width: textWidth, height: titleHeight)
        container.addSubview(titleLabel)

        // Message (wraps within the fixed text width).
        let messageY = titleY - titleToMsg - messageHeight
        let messageLabel = NSTextField(wrappingLabelWithString: message)
        messageLabel.font = messageFont
        messageLabel.textColor = .labelColor
        messageLabel.isEditable = false
        messageLabel.isSelectable = false
        messageLabel.drawsBackground = false
        messageLabel.maximumNumberOfLines = 0
        messageLabel.frame = NSRect(x: textX, y: messageY, width: textWidth, height: messageHeight)
        container.addSubview(messageLabel)

        // Bottom row: button (left, teacher only) + countdown (right).
        let bottomRowY = messageY - msgToBottom - bottomRowHeight
        if let button = button {
            button.frame = NSRect(x: textX, y: bottomRowY + (bottomRowHeight - buttonSize.height) / 2,
                                  width: buttonSize.width, height: buttonSize.height)
            container.addSubview(button)
        }
        let cy = bottomRowY + (bottomRowHeight - countdownHeight) / 2
        let hourglass = NSImageView(frame: NSRect(x: textRight - countdownWidth,
                                                  y: cy + (countdownHeight - hourglassSize.height) / 2,
                                                  width: hourglassSize.width, height: hourglassSize.height))
        hourglass.image = NSImage(systemSymbolName: "hourglass", accessibilityDescription: nil)
        hourglass.contentTintColor = .secondaryLabelColor
        hourglass.imageScaling = .scaleProportionallyUpOrDown
        container.addSubview(hourglass)
        secLabel.frame = NSRect(x: textRight - secondsWidth, y: cy, width: secondsWidth, height: countdownHeight)
        container.addSubview(secLabel)

        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: .borderless,
                              backing: .buffered, defer: true)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        // Click-through unless there's a button — then the card must receive the click.
        window.ignoresMouseEvents = (button == nil)
        window.level = .statusBar                  // above other apps' normal windows
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isExcludedFromWindowsMenu = true
        window.hidesOnDeactivate = false
        window.isRestorable = false
        window.animationBehavior = .none
        window.contentView = container
        self.window = window

        super.init()
        button?.target = self
        button?.action = #selector(actionClicked)
    }

    @objc private func actionClicked() { onAction?() }

    /// Start the 1-second countdown that updates the "Ns" label and fires `onExpire` at zero.
    func startCountdown() {
        let t = Timer(timeInterval: 1, target: self, selector: #selector(countdownTick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        countdownTimer = t
    }

    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    @objc private func countdownTick() {
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            stopCountdown()
            onExpire?()
        } else {
            secondsLabel.stringValue = "\(secondsRemaining)s"
        }
    }

    /// A resizable rounded-rect mask — the reliable way to round an NSVisualEffectView's blur (a plain
    /// layer cornerRadius doesn't clip the vibrancy).
    private static func roundedMaskImage(cornerRadius r: CGFloat) -> NSImage {
        let d = r * 2 + 1
        let image = NSImage(size: NSSize(width: d, height: d), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: r, left: r, bottom: r, right: r)
        image.resizingMode = .stretch
        return image
    }
}

/// The app's `Button` (brand-orange fill, pointing-hand cursor on hover) that additionally fires on
/// the FIRST click even when its window isn't key — the notification window is shown non-activating
/// (orderFrontRegardless), so without this the first click would just be swallowed activating the window.
private final class FocusBlockUnlockButton: Button {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

//*******************GET APP APPEARANCE******************//

func getAppAppearance()->NSAppearance?{
    var appearance: NSAppearance?
    switch SettingsManagerObject.selectedAppAppearanceIndex {
    case 0:
        appearance = NSApp!.appearance
    case 1:
        appearance = NSAppearance(named: .darkAqua)
    case 2:
        appearance = NSAppearance(named: .aqua)
    default:
        break;
    }
    return appearance
}


//******GET OR CREATE FOCUS MODE TAG ID********//

func getIdForTag(tag:String)->String{
    for tagInfo in arrAllFocusModeTags{
        if let oldTag = tagInfo["text"]{
            if oldTag.lowercased() == tag.lowercased(){
                return tagInfo["id"] ?? getUuid()
            }
        }
    }
    let id = getUuid()
    arrAllFocusModeTags.append(["id": id, "text": tag])
    return id
}
//------------------------------------------------------------------------//


//*********************POMODORO SHORTCUT WORK***********************//
var char = ""
var flags = NSEvent.modifierFlags
enum shortcutFlags:Int{
    case _COMMAND_ = 11, _CONTROL_, _OPTION_, _SHIFT_
}


func updateFlags(sflags:[Int]){
    flags = NSEvent.modifierFlags
    for falg in sflags{
        if falg == shortcutFlags._CONTROL_.rawValue{
            flags.update(with: .control)
        }
        if falg == shortcutFlags._OPTION_.rawValue{
            flags.update(with: .option)
        }
        if falg == shortcutFlags._SHIFT_.rawValue{
            flags.update(with: .shift)
        }
        if falg == shortcutFlags._COMMAND_.rawValue{
            flags.insert(.command)
        }
    }
}
//------------------------------------------------------------------------//






func calculateBackoffWithJitter(baseDelayMs: Int, retry: Int) -> Int {
    addLog(text: "CalculateBackoffWithJitter()")
    let maxDelayMs = 120000 // Maximum delay in milliseconds
    let exponentialDelay = Int(pow(2.0, Double(retry)) * Double(baseDelayMs))
    let jitter = Int.random(in: 1...baseDelayMs/2)  // Adding jitter within half of the base delay
    let delayMs = min(exponentialDelay + jitter, maxDelayMs)
    return delayMs
}






func writeStringToHabitInfo(isFinishTime:Bool, activityName:String){
    var outString = ""
    if isFinishTime{
        outString = "finishTime:"
    }else{
        outString = "startTime:"
    }
    
    let time = getStringFromDate(date:Date(), dateFormat:"yyyy-MM-dd HH-mm-ss")
    outString =  outString + time
    
    outString = outString + ",name:" + activityName
    writeSettingForScreeenTime(habitInfo: outString)
}

func writeSettingForScreeenTime(habitInfo:String){
    var language = "es"
    language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String ?? language
    var isScreenTimeEnabled = false
    isScreenTimeEnabled = UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool ?? isScreenTimeEnabled
     
    var dicContent = ["language":language, "isScreenTimeEnabled":isScreenTimeEnabled, "habitInfo":habitInfo, "userID":appdelegate!.user?.userId ?? "", "isPurchased":isPurchased, "startup_time":startTimeString, "shutdown_time":shutOffTimeString, "cutoff_time":cutOffTimeString, "isUserOnMeeting":appdelegate!.isUserOnMeeting] as [String : Any]
    
    if appdelegate?.isUserOnMeeting ?? false{
        if let meetingStartTime = appdelegate?.meetingStartTime{
            let time = getStringFromDate(date: meetingStartTime, dateFormat:"yyyy-MM-dd HH-mm-ss")
            dicContent["meetingStartTime"] = time
        }
    }
    
    let plistContent = NSDictionary(dictionary: dicContent)
    let _ = plistContent.write(toFile: settingForScreeenTimeFileURL!.path, atomically: true)
}


func enableTimeTracker(){
    allApiObject.capturePosthog(event: "settings-changed-enable-time-tracker", metadata: [:])
    UserDefaults.standard.set(true, forKey: kUserdefaultsScreenTimeEnabled)
    UserDefaults.standard.set(true, forKey: kUserdefaultsScreenTimeEnabledOneTime)
    UserDefaults.standard.set(true, forKey: kUserdefaultsEnableScreenTimeShown)
    
    let appPath = "/Applications/Focus Bear Time Tracker.app"
    let configuration = NSWorkspace.OpenConfiguration()//.arguments = [appPath]
    if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app") {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: appPath), configuration: configuration)
    }
    writeSettingForScreeenTime(habitInfo: "")
    // Let any live FBTT "Today" view re-sync its toggle (e.g. enabled via the first-run window).
    NotificationCenter.default.post(name: .timeTrackerEnabledStateChanged, object: nil)
}

/// Central enable/disable flow for the Focus Bear Time Tracker. Extracted from the old
/// Advanced → Add-Ons toggle so the FBTT "Today" view can own the switch. `presentingWindow`
/// hosts the download alert (falls back to a modal if nil). `completion` reports the RESOLVED
/// enabled state — the switch must reflect reality, so it stays off until the tracker is
/// actually installed and enabled (first-run and not-installed both resolve to false).
func setTimeTrackerEnabled(_ enabled: Bool, presentingWindow: NSWindow?, completion: @escaping (Bool) -> Void) {
    guard enabled else {
        allApiObject.capturePosthog(event: "settings-changed-disable-time-tracker", metadata: [:])
        UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
        writeSettingForScreeenTime(habitInfo: "")
        NotificationCenter.default.post(name: .timeTrackerEnabledStateChanged, object: nil)
        completion(false)
        return
    }

    // Time Tracker is a Pro feature — if the trial/subscription has lapsed, don't enable it; prompt
    // to upgrade instead and leave the switch off.
    if !(isPurchased || daysLeft > 0) {
        showUpgradeNowWindow(reason: "time_tracker_expired")
        completion(false)
        return
    }

    // First time enabling → run the intro window flow; leave the switch off until it enables there.
    if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabledOneTime) == nil {
        showTimeTrackerWindow(showingAutomatically: false)
        completion(false)
        return
    }

    if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app") {
        enableTimeTracker()
        completion(true)
        return
    }
    
    enableTimeTracker()
    // Installed component missing → offer to download it; switch stays off.
    let alert = NSAlert()
    alert.setSharingType()
    alert.alertStyle = .informational
    var titleDownloadTimeTrackerText = "Focus Bear Time Tracker needs to be downloaded and installed as a separate component."
    var buttonDownloadTimeTrackerText = "Download Now"
    if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary {
        titleDownloadTimeTrackerText = settingsNew.value(forKey: "titleDownloadTimeTrackerText") as? String ?? titleDownloadTimeTrackerText
        buttonDownloadTimeTrackerText = settingsNew.value(forKey: "buttonDownloadTimeTrackerText") as? String ?? buttonDownloadTimeTrackerText
    }
    alert.messageText = titleDownloadTimeTrackerText
    alert.addButton(withTitle: buttonDownloadTimeTrackerText)
    alert.addButton(withTitle: buttonCancelText)
    let handleResponse: (NSApplication.ModalResponse) -> Void = { modalResponse in
        if modalResponse == .alertFirstButtonReturn,
           let url = URL(string: "https://downloads.focusbear.io/fbtt/FocusBearTimeTracker.dmg") {
            NSWorkspace.shared.open(url)
        }
    }
    if let window = presentingWindow {
        alert.beginSheetModal(for: window, completionHandler: handleResponse)
    } else {
        handleResponse(alert.runModal())
    }
    completion(false)
}







var lastAppUnlockTime:Date?
var lastUnlockTimeByAccountabilityBuddy:Date?

/// Returns true if a full-screen (locked) window is currently on screen. Used to suppress the
/// password grace period there — full-screen habit/focus mode is exactly when accountability
/// matters most, so a recent unlock shouldn't be reusable to slip past the lock.
func isFullScreenWindowCurrentlyShowing()->Bool{
    if mainWindowControllerObj?.window?.styleMask.contains(.fullScreen) ?? false{ return true }
    if mainWindowControllerObj?.isFullScreenVisible ?? false{ return true }
    return false
}

/// - Parameter forPostpone: pass `true` from postpone / extend-postpone gates. Postponing must never
///   reuse a grace window — otherwise a single unlock (e.g. an accountability buddy granting 10 min)
///   can be leveraged into a much longer postpone by extending it within the grace period.
func shouldAskPassword(forPostpone:Bool = false)->Bool{
    // A full-screen (locked) window always re-asks. Postponing used to bypass the grace too, but that
    // re-prompted even moments after the password was entered for the SAME postpone (the flow gates twice:
    // once before the duration picker, once when applying the chosen duration) — so it never unlocked and
    // looped (bug report 2026-07-06). Now a postpone honours the recent-unlock grace: the password is
    // asked once, then again only after the grace (~2 min) — "unlock for the postpone, ask next time".
    // A postpone must honour the recent-unlock grace EVEN in the borderless full-screen routine window
    // (the evening routine runs there). Without the `!forPostpone`, full-screen forced bypassGrace=true,
    // so shouldAskPassword returned true before the grace was ever consulted — the postpone flow's second
    // gate re-prompted the instant after the password was entered, and it looped (report 2026-07-07).
    // The lock screen itself (non-postpone) still always re-asks in full-screen.
    let bypassGrace = isFullScreenWindowCurrentlyShowing() && !forPostpone
    if !bypassGrace{
        if let lastUnlockTimeByAccountabilityBuddy = lastUnlockTimeByAccountabilityBuddy{
            if Date() < lastUnlockTimeByAccountabilityBuddy{
                return false
            }
        }
    }
    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
        if bypassGrace{
            return true
        }
        if let lastAppUnlockTime = lastAppUnlockTime{
            let diffSeconds = Calendar.current.dateComponents([.second], from: lastAppUnlockTime, to: Date()).second ?? 0
            if diffSeconds > 120{
                return true
            }else{
                return false
            }
        }else{
            return true
        }
    }
    return false
}

func isPasswordRequireInOpenSettings() -> Bool{
    if let lastUnlockTimeByAccountabilityBuddy = lastUnlockTimeByAccountabilityBuddy{
        if Date() < lastUnlockTimeByAccountabilityBuddy{
            return false
        }
    }
    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
        if let lastAppUnlockTime = lastAppUnlockTime{
            let diffSeconds = Calendar.current.dateComponents([.second], from: lastAppUnlockTime, to: Date()).second ?? 0
            if diffSeconds > 120{
                return isPasswordRequireInOpenSettingsEnabled()
            }else{
                return false
            }
        }else{
            return isPasswordRequireInOpenSettingsEnabled()
        }
    }
    return false
}

func isPasswordRequireInOpenSettingsEnabled() -> Bool{
    //Super strict focus sessions should block changing settings #1423
    if isFocusModeOn(){
        if !isStrictnessLevelNormal(){
            return true
        }
    }
    //
    
    if isCutOffTimeGoing(){
        if SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff{
            return true
        }
    }
    return SettingsManagerObject.isPasswordRequireInChangeSettings
}






func randomString(length: Int) -> String {
  let letters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}


var defaultStartTime = "08:30"
var defaultShutDownTime = "18:30"
var defaultSleepTime = "21:30"





func showOnboardingProgress(view:NSView, progress:Int){
    return;
    view.addSubview(getOnboardingProgressVcObj().view)
    view.addBottomRightConstraints(subView: getOnboardingProgressVcObj().view)
    onboardingProgressVcObj?.resetData(progress: progress)
}
func hideOnboardingProgress(view:NSView){
    if onboardingProgressVcObj != nil{
        if view.subviews.contains(getOnboardingProgressVcObj().view){
            getOnboardingProgressVcObj().view.removeFromSuperview()
        }
    }
}
//-------------------------------------------------------------------------//

//--------------------------------Onboarding Bell icon----------------------------//

func showOnboardingBellIcon(view:NSView, screen:String){
    return; //removed v 2.28.446
    view.addSubview(getBellVcObj().view)
    view.addBottomLeftConstraints(subView: getBellVcObj().view)
    bellVcObj?.screen = screen
}
func hideOnboardingBellIcon(view:NSView){
    if bellVcObj != nil{
        if view.subviews.contains(getBellVcObj().view){
            getBellVcObj().view.removeFromSuperview()
        }
    }
}
//-------------------------------------------------------------------------//



//Fix posthog identify call#884//
//--------------------------------globalUUID----------------------------//
var globalUUID = ""

func checkAndGetGlobalUUID(){
    if let id = UserDefaults.standard.object(forKey: kUserdefaultsGlobalUUID) as? String{
        globalUUID = id
    }else{
        globalUUID = "fake-" + getUuid()
        UserDefaults.standard.set(globalUUID, forKey: kUserdefaultsGlobalUUID)
    }
}

func deleteGlobalUUID(){
    globalUUID = ""
    UserDefaults.standard.removeObject(forKey: kUserdefaultsGlobalUUID)
}

func connectGlobalAndMacIDWithDistinctUserID(){
    kUserdefaultsIsGlobalUUIDLinked = kUserdefaultsIsGlobalUUIDLinked + (appdelegate!.user?.userId ?? "")
    kUserdefaultsIsMacIdLinked = kUserdefaultsIsMacIdLinked + (appdelegate!.user?.userId ?? "")
    
    if UserDefaults.standard.object(forKey: kUserdefaultsIsGlobalUUIDLinked) == nil{
        allApiObject.capturePosthogIdentify(sAliasID: globalUUID, completionHandler: {boolValue in
            if boolValue{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsGlobalUUIDLinked)
                deleteGlobalUUID()
            }
        })
    }
    if UserDefaults.standard.object(forKey: kUserdefaultsIsMacIdLinked) == nil{
        allApiObject.capturePosthogIdentify(sAliasID: macAddress, completionHandler: {boolValue in
            if boolValue{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsMacIdLinked)
            }
        })
    }
}


//-------------------------------------------------------------------------//


func setAppIconForFocusModeScore(probability:Double?){
    if probability == nil{
        setFocusBearIconToNormal()
        focusModeCloseCurrentUrlForAlignmentScore()
        focusModeCloseCurrentAppForAlignmentScore()
    }else{
        if probability! >= 0.70{
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("productive_icon"))
        }else{
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("notProductive_icon"))
        }
    }
}
func setFocusBearIconToNormal(){
    boxForStatusBarForTooltip?.customToolTip = ""
    if SettingsManagerObject.isOfficeModeEnabled{
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
    }else{
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
    }
}




var boxForStatusBar: customStatusBarBox!


var boxForStatusBarForTooltip: customStatusBarBoxForTooltip!





var totalFocuseTime:Double = 0
var totalDeepFocusedTime:Double = 0 // according to alignment score %
var arrLongTermGoals = [String]()
func getTotalFocuedTime(){
    totalFocuseTime = 0
    totalDeepFocusedTime = 0
    allApiObject.getAllActivityDaySummary(completionHandler: {dic in
        if allActivityTodaySummaryData != nil{
            if let arr = allActivityTodaySummaryData!.value(forKey: "focusSummary") as? [[String:Any]]{
                for item in arr{
                    let duration = item["duration"] as? Double ?? 0
                    totalFocuseTime += duration
                    
                    if let metadata = item["metadata"] as? [String:Any]{
                        if let focus_alignment_score = metadata["focus_alignment_score"] as? String{ 
                            let score = Double(focus_alignment_score) ?? 0
                            let deepWorkDuration = (duration * score) / 100
                            totalDeepFocusedTime += deepWorkDuration
                        }else{
                            totalDeepFocusedTime += duration
                        }
                    }
                    
                }
            }
        }
    })
}


func getAllLongTermGoals(){
    arrLongTermGoals.removeAll()
    allApiObject.getuserLongTermGoals(completionHandler: {arrGoals in
        if let arrGoals = arrGoals{
            arrLongTermGoals = arrGoals
        }
    })
}
func getGoalsAndFocusdJsonForBlockedScript()-> String{
    let json: [String: Any] = [
        "focused_time": totalFocuseTime,
        "long_term_goals": arrLongTermGoals
    ]
    var jsonString =  String(describing: json)
    jsonString = jsonString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? jsonString
    do {
        let jsonResultData =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
            return backToString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? backToString
        }
    } catch let myJSONError {
        print(myJSONError)
    }
    
    return jsonString
}


// Reads whether the app currently has a native-fullscreen window. A fullscreen window sits on its own
// Space, so from a background query `count of windows` can report 0. Reading AXFocusedWindow first primes
// the AX window list; the sweep of any enumerable windows then catches the fullscreen one. Must be called
// after a warm-up read (see exitFullScreen) — the first cold AX query returns empty.
func isAppInFullScreen(runningApp:NSRunningApplication) -> Bool {
    guard !shouldSkipSystemEventsAppleEvent() else { return false }
    let appName = runningApp.localizedName ?? ""
    let script =
    """
    tell application "System Events"
    tell process "\(appName)"
    try
    if value of attribute "AXFullScreen" of (value of attribute "AXFocusedWindow") is true then
    return true
    end if
    end try
    repeat with i from 1 to (count of windows)
    try
    if value of attribute "AXFullScreen" of window i is true then
    return true
    end if
    end try
    end repeat
    end tell
    end tell
    return false
    """
    return executeScriptAndReturnBool(script: script)
}

// Exits an app's native fullscreen with the system-standard ⌃⌘F toggle — the one method every
// fullscreen-capable app honors. An Accessibility *write* to AXFullScreen is unreliable: Safari accepts
// it, but Chrome, Calendar and others silently ignore it, so `set AXFullScreen to false` is a no-op for
// them. We only send the toggle when the app is ACTUALLY fullscreen (else ⌃⌘F would send it INTO
// fullscreen), and activate it first so the keystroke lands on the right app.
func exitFullScreen(runningApp:NSRunningApplication){
    // A Quick Look preview isn't an app window in fullscreen; skip the AppleScript round trips.
    if isQuickLookService(runningApp) { return }
    guard !shouldSkipSystemEventsAppleEvent() else { return }
    // The AX warm-up + isAppInFullScreen (+ the ⌃⌘F keystroke) are 2–3 blocking AppleScript reads,
    // each capped at ~1.2s on the main thread by runAppleScriptSafely. exitFullScreen runs on EVERY
    // app switch (frontApplicationChanged → block checks), so on the main thread those reads stack into
    // a >2s UI freeze — the "App Hanging: App hanging for at least 2000 ms" reported in Sentry. The exit
    // is fire-and-forget (no caller reads a result — it just sends ⌃⌘F), so run the AppleScript off the
    // main thread. See fullScreenExitQueue for why it can't be appleScriptSerialQueue.
    guard Thread.isMainThread else { performExitFullScreen(runningApp: runningApp); return }
    fullScreenExitQueue.async { performExitFullScreen(runningApp: runningApp) }
}

private func performExitFullScreen(runningApp:NSRunningApplication){
    let appName = runningApp.localizedName ?? ""
    // Warm up Accessibility first. The FIRST AX query to an app whose fullscreen window is on its own
    // Space comes back "cold" — `count of windows` = 0 and `window 1` throws -1719 — and only the NEXT
    // query returns the real state. This throwaway read that touches `count of windows`, AXFocusedWindow
    // AND `window 1` primes the AX window list so the detection below is accurate. Without it, detection
    // always reads cold, returns false, and the block never exits fullscreen (verified: builds that
    // issued this extra AX read first worked for every app; removing it broke all of them).
    let warmUp =
        """
        tell application "System Events" to tell process "\(appName)"
        try
        set warmCount to (count of windows)
        end try
        try
        set warmFocused to value of attribute "AXFocusedWindow"
        set warmRole to (role of warmFocused)
        set warmFS to (value of attribute "AXFullScreen" of warmFocused)
        end try
        try
        set warmWin1 to (value of attribute "AXFullScreen" of window 1)
        end try
        end tell
        """
    _ = executeScriptAndReturnString(script: warmUp)
    guard isAppInFullScreen(runningApp: runningApp) else { return }
    runningApp.activate(options: [.activateIgnoringOtherApps])
    let script =
        """
        tell application "System Events"
        keystroke "f" using {command down, control down}
        end tell
        """
    executeScript(script: script)
}

func isRunningAppFullScreen(runningApp:NSRunningApplication, browser: BROWSER?)->Bool{
    // One generic AXFocusedWindow-based read for every app (Safari, Chrome/Chromium, native apps),
    // replacing the old per-browser split and the hard-coded `window 1` that threw -1719 when the
    // fullscreen window was on its own Space with no windows enumerable.
    return isAppInFullScreen(runningApp: runningApp)
}






// Whether the running app (its lowercased localized name) is in a focus mode's allowed_apps list.
// allowed_apps entries are usually app paths ("/Applications/Google Chrome.app"), so we match on the
// app-name component. During a TEACHER session we also accept the case where the running app's name
// CONTAINS the allow-list entry — e.g. an allowed "Chrome" permits the running "Google Chrome".
// Outside a teacher session we keep the strict exact-name match to avoid over-allowing
// (e.g. "Notes" must not allow "Notes Plus").
func isRunningAppInAllowedApps(_ allowedAppPaths: [String], runningAppNameLowercased name: String) -> Bool {
    if name.isEmpty { return false }
    let teacherSession = teacherSessionManagerObject.isTeacherSessionActive()
    for path in allowedAppPaths {
        let allowedName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent.lowercased()
        if allowedName.isEmpty { continue }
        if allowedName == name { return true }
        if teacherSession && name.contains(allowedName) { return true }
    }
    return false
}

func shutDownMac() {
    addLog(text: "shut Down Mac")
    let script = """
        tell application "System Events"
            shut down
        end tell
        """
    var error: NSDictionary?
    runAppleScriptSafely(script, errors: &error)
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Shutdown command executed successfully.")
    }
}


func sleepMac() {
    addLog(text: "sleep Mac")
    let script = """
        tell application "System Events"
            sleep
        end tell
        """
    var error: NSDictionary?
    runAppleScriptSafely(script, errors: &error)
    if let error = error {
        print("Error: \(error)")
    } else {
        print("sleep command executed successfully.")
    }
}

/// Compatibility name for the onboarding callers. Permission is read directly, without an
/// AppleScript, so a prompt timeout or an unavailable Dock property is not mistaken for denial.
func checkAutomationPermissionWithAppleScript() -> Bool {
    !shouldSkipSystemEventsAppleEvent()
}

// MARK: - System Events permission gates

enum SystemEventsAutomationResult: String {
    case granted, denied, consentRequired, unknown

    init(status: Int32) {
        switch status {
        case 0: self = .granted
        case -1743: self = .denied
        case -1744: self = .consentRequired
        default: self = .unknown
        }
    }

    func permitsRuntimeScript(requestInFlight: Bool) -> Bool {
        self == .granted && !requestInFlight
    }
}

private enum SystemEventsAutomationObservation {
    static let lock = NSLock()
    static var requestInFlight = false
    static var lastStatus: Int32?
    static var launchInFlight = false
    static var lastLaunchAttempt: TimeInterval?
}

var isSystemEventsAutomationRequestInFlight: Bool {
    SystemEventsAutomationObservation.lock.lock()
    defer { SystemEventsAutomationObservation.lock.unlock() }
    return SystemEventsAutomationObservation.requestInFlight
}

/// Only the wizard's explicit button invokes this. Runtime probes never request consent.
func beginSystemEventsAutomationRequest() -> Bool {
    SystemEventsAutomationObservation.lock.lock()
    defer { SystemEventsAutomationObservation.lock.unlock() }
    guard !SystemEventsAutomationObservation.requestInFlight else { return false }
    SystemEventsAutomationObservation.requestInFlight = true
    return true
}

func finishSystemEventsAutomationRequest(status: Int32) {
    SystemEventsAutomationObservation.lock.lock()
    SystemEventsAutomationObservation.requestInFlight = false
    SystemEventsAutomationObservation.lock.unlock()
    recordSystemEventsAutomationStatus(status)
}

func recordSystemEventsAutomationStatus(_ status: Int32) {
    SystemEventsAutomationObservation.lock.lock()
    let changed = SystemEventsAutomationObservation.lastStatus != status
    SystemEventsAutomationObservation.lastStatus = status
    SystemEventsAutomationObservation.lock.unlock()
    if changed {
        addLog(text: "System Events permission: pid=\(ProcessInfo.processInfo.processIdentifier) status=\(status) result=\(SystemEventsAutomationResult(status: status).rawValue)")
    }
}

func shouldSkipSystemEventsAppleEvent() -> Bool {
    // Do not query or send an AppleScript while the explicit blocking consent request is pending.
    guard !isSystemEventsAutomationRequestInFlight else { return true }
    let status: Int32
    if let process = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systemevents").first {
        let target = NSAppleEventDescriptor(processIdentifier: process.processIdentifier)
        status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, false)
    } else {
        status = -600 // target not running: unknown, not evidence of a denied grant
        launchSystemEventsForNonpromptingProbeIfNeeded()
    }
    recordSystemEventsAutomationStatus(status)
    return !SystemEventsAutomationResult(status: status)
        .permitsRuntimeScript(requestInFlight: isSystemEventsAutomationRequestInFlight)
}

/// System Events can exit while idle. Launching its background process restores the old
/// AppleEvent auto-launch behavior, without granting access or opening a consent dialog.
/// One launch may be pending, with a ten-second retry interval and bounded registration wait.
private func launchSystemEventsForNonpromptingProbeIfNeeded() {
    let now = ProcessInfo.processInfo.systemUptime
    SystemEventsAutomationObservation.lock.lock()
    guard !SystemEventsAutomationObservation.requestInFlight,
          !SystemEventsAutomationObservation.launchInFlight,
          SystemEventsAutomationObservation.lastLaunchAttempt.map({ now - $0 >= 10 }) ?? true else {
        SystemEventsAutomationObservation.lock.unlock()
        return
    }
    SystemEventsAutomationObservation.launchInFlight = true
    SystemEventsAutomationObservation.lastLaunchAttempt = now
    SystemEventsAutomationObservation.lock.unlock()
    DispatchQueue.global().async {
        defer {
            SystemEventsAutomationObservation.lock.lock()
            SystemEventsAutomationObservation.launchInFlight = false
            SystemEventsAutomationObservation.lock.unlock()
        }
        ensureSystemEventsRunningForAutomation()
        guard !isSystemEventsAutomationRequestInFlight,
              let process = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systemevents").first else { return }
        let target = NSAppleEventDescriptor(processIdentifier: process.processIdentifier)
        let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, false)
        recordSystemEventsAutomationStatus(status)
    }
}

/// Runs off the main thread for either the explicit wizard request or the nonprompting runtime
/// recovery. Opening this LSUIElement does not activate an app window or request Automation.
func ensureSystemEventsRunningForAutomation() {
    let bundleID = "com.apple.systemevents"
    if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty { return }
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        let completion = DispatchSemaphore(value: 0)
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in completion.signal() }
        _ = completion.wait(timeout: .now() + 5)
    }
    var attempts = 0
    while NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty && attempts < 30 {
        usleep(100_000)
        attempts += 1
    }
}

func getWindowFrame(pid: pid_t) -> CGRect? {
    var windowFrame: CGRect?
    
    // Get window information
    if let windowListInfo = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: AnyObject]] {
        for windowInfo in windowListInfo {
            if let id = windowInfo[kCGWindowOwnerPID as String] as? pid_t, id == pid {
                if let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] {
                    let x = bounds["X"] ?? 0
                    let y = bounds["Y"] ?? 0
                    let width = bounds["Width"] ?? 0
                    let height = bounds["Height"] ?? 0
                    
                    // Create CGRect from window bounds
                    windowFrame = CGRect(x: x, y: y, width: width, height: height)
                    break
                }
            }
        }
    }
    
    // Convert window frame to screen coordinates if windowFrame is not nil
    if var windowFrame = windowFrame {
        // Find the screen that contains the window
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: windowFrame.midX, y: windowFrame.midY), $0.frame, false) }) {
            // Convert window's frame to screen coordinates
            let screenFrame = screen.visibleFrame
            windowFrame.origin.x += screenFrame.origin.x
            windowFrame.origin.y += screenFrame.origin.y
        }
    }
    
    return windowFrame
}



func extractSubstring(from text: String, start: String, end: String) -> String? {
    guard let startRange = text.range(of: start),
          let endRange = text.range(of: end, range: startRange.upperBound..<text.endIndex) else {
        return nil
    }

    let substring = text[startRange.upperBound..<endRange.lowerBound]
    return String(substring)
}


func extractValue(from query: String, key:String) -> String? {
    let components = query.components(separatedBy: "&")
    for component in components {
        let pair = component.components(separatedBy: "=")
        if pair.count == 2, pair[0] == key {
            let value = pair[1].replacingOccurrences(of: "+", with: " ")
            return value.removingPercentEncoding
        }
    }
    return nil
}

let nonTimerBasedHabitsObject = NonTimerBasedHabit()







enum BLOCKINGSCHEDULE:Int{
    case _UNTIL_I_FINISH_WORK_ = 0, _WHEN_START_FOCUS_SESSION_, _CUSTOM_SCHEDULE_
}

func startApacheServer() {
    // Call the function to start Apache
    runCommandAsRoot(command: "/usr/sbin/apachectl", arguments: ["start"])
}
func runCommandAsRoot(command: String, arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo") // Use sudo to run as root
    process.arguments = [command] + arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
            print("Command Output:\n\(output)")
        }

        if process.terminationStatus == 0 {
            print("Command executed successfully.")
        } else {
            print("Command failed with exit code: \(process.terminationStatus)")
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}





/// True when the frontmost OTHER app occupies a native (green-button) full-screen Space on the
/// main (menu-bar) display. A native full-screen window covers the entire display INCLUDING the
/// menu-bar strip, whereas a merely-maximised window stops below the menu bar — so a full-height,
/// full-width layer-0 window owned by the frontmost app means we're on its full-screen Space.
/// Used to fall back from the popover (which renders on Focus Bear's own Space and stays hidden
/// there) to the detached window menu, which shows correctly over another app's full-screen Space.
func isFrontmostAppInNativeFullScreen() -> Bool {
    guard let frontApp = NSWorkspace.shared.frontmostApplication,
          frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
    let pid = frontApp.processIdentifier
    guard let mainScreen = NSScreen.main,
          let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
    else { return false }
    let screenH = mainScreen.frame.height
    let screenW = mainScreen.frame.width
    for info in infoList {
        guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int, pid_t(ownerPID) == pid,
              let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
              let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
        else { continue }
        if bounds.height >= screenH - 1 && bounds.width >= screenW - 1 { return true }
    }
    return false
}

/// True when the frontmost OTHER app is covering the whole main screen — EITHER native full-screen (window
/// at y=0 over the menu bar) OR non-native full-screen / a maximised window that fills everything BELOW the
/// menu bar (y≈menuBarHeight). In both cases the popover and a plain window can't reliably render above the
/// app, so the menu must be shown in the overlay NSPanel. Broader than `isFrontmostAppInNativeFullScreen`.
func isFrontmostAppCoveringScreen() -> Bool {
    guard let frontApp = NSWorkspace.shared.frontmostApplication,
          frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
    let pid = frontApp.processIdentifier
    guard let mainScreen = NSScreen.main,
          let infoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
    else { return false }
    let screenH = mainScreen.frame.height
    let screenW = mainScreen.frame.width
    let menuBarHeight = max(0, mainScreen.frame.maxY - mainScreen.visibleFrame.maxY)
    for info in infoList {
        guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int, pid_t(ownerPID) == pid,
              let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
              let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
              let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
        else { continue }
        let coversWidth = bounds.width >= screenW - 1
        let coversHeightBelowMenuBar = bounds.height >= screenH - menuBarHeight - 1
        let flushToTop = bounds.minY <= menuBarHeight + 1
        if coversWidth && coversHeightBelowMenuBar && flushToTop { return true }
    }
    return false
}

func isFocusBearMenuVisible()->Bool{
    if SettingsManagerObject.isMenuPopoverEnabled{
        return appdelegate?.popover.isShown ?? false
    }else{
        return getMenuWindowObject().window?.isVisible ?? false
    }
}


func enableMenuPopover(){
    SettingsManagerObject.isMenuPopoverEnabled = true
    if getMenuWindowObject().window?.isVisible ?? false{
        getMenuWindowObject().window?.close()
    }
    appdelegate?.popover.contentViewController = menuViewControllerObj
    appdelegate?.popover.animates = false
    appdelegate?.popover.behavior = .transient
    allApiObject.capturePosthog(event: "settings-changed-menu-as-popover-enabled", metadata: [:])
    appdelegate?.showPopover()
    //menuViewControllerObj?.view.window?.makeKey()
//    appdelegate?.popover.becomeFirstResponder()
}

func disableMenuPopover(){
    if appdelegate?.popover.isShown ?? false{
        appdelegate?.popover.close()
    }
    SettingsManagerObject.isMenuPopoverEnabled = false
    if let view = menuViewControllerObj?.view as? PopoverContentView{
        if view.backgroundView != nil{
            view.backgroundView?.removeFromSuperview()
            view.backgroundView = nil
        }
    }
    appdelegate?.popover.contentViewController = nil
    menuViewControllerObj?.view.removeFromSuperview()
    menuViewControllerObj = nil
    menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController
    
    getMenuWindowObject().contentViewController = menuViewControllerObj
   
    getMenuWindowObject().window?.contentView?.layoutSubtreeIfNeeded()
    if let frame = appdelegate?.statusbutton?.window?.frame{
        let height = menuViewControllerObj?.view.frame.height ?? 500
        let leading = frame.midX - (300 / 2) // 300 is view's width
        
        getMenuWindowObject().window?.setFrameOrigin(NSPoint(x: leading, y: frame.maxY - height))
    }
    
    
    allApiObject.capturePosthog(event: "settings-changed-menu-as-popover-disabled", metadata: [:])
    appdelegate?.showPopover()
}


func loadMenuWindow(){
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            if !(menuViewControllerObj?.isViewLoaded ?? false){
                menuViewControllerObj?.loadView()
                
            }
            getMenuWindowObject().loadWindow()
            if let frame = appdelegate?.statusbutton?.window?.frame{
                let height = menuViewControllerObj?.view.frame.height ?? 500
                let leading = frame.midX - (300 / 2) // 300 is view's width
                
                getMenuWindowObject().window?.setFrameOrigin(NSPoint(x: leading, y: frame.maxY - height))
            }
        }
    }
}





protocol NudgeWindowDelegate {
    func nudgeDragged()
}


let stageManagerObject = StageManager()


var habitPlayingBeforeMacSleepId = ""//Focus alignment score drops to 0% after resuming from sleep #1321


func quitApplicationSmoothly() {
    addLog(text: "func :-quitApplicationSmoothly")
    // Step 1: End all attached sheets and modal sessions
    
    disableAllAlertsBeforeQuit()
    // Step 2: Wait a bit for UI to settle, then terminate
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        NSApp.terminate(nil)
    }
}

func disableAllAlertsBeforeQuit(){
    addLog(text: "func :-disableAllAlertsBeforeQuit")
    // Snapshot the windows — ending a sheet can mutate NSApp.windows mid-iteration.
    for window in Array(NSApp.windows) {
        // End any sheet attached to the window
        if let sheet = window.attachedSheet {
            window.endSheet(sheet)
        }
    }

    // End the modal session ONCE, only if one is actually running. Calling abortModal() AND
    // stopModal() (the second with no live session) makes AppKit throw NSWindowEndWindowModalSession —
    // an uncatchable Obj-C exception in Swift → SIGABRT. Crashed here when a Pusher-initiated
    // quitAndRestartApp fired while a modal was up (see AppDelegate.quitAndRestartApp / pusherEvents).
    if NSApp.modalWindow != nil {
        NSApp.abortModal()
    }
}



var isExplainingPermissionsWindowShowingFromPomodoro = false
var isExplainingPermissionsWindowShowingFromBlockingSchedule = false

//var isCustomBarIsInFocus = false// when app is not in focus and user try to click close icon of custom bar . then applicationDidBecomeActive func called instead of close action because app become active and because app become active it shows menu (from inside applicationDidBecomeActive func) instead of  closing custom bar. to prevent this we are using isCustomBarIsInFocus variable. so that if user's cursor is on custom bar then menu will not show.



func startMainAppForceQuitMonitoring(){
    appdelegate!.sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsStartMainAppIfNotRunning)
    appdelegate!.sharedDefaults?.synchronize()
    let startMainAppForceQuitMonitoring = Notification.Name("startMainAppForceQuitMonitoring")
    DistributedNotificationCenter.default().post(name: startMainAppForceQuitMonitoring,object: mainAppBundelId)
}

/// #2575: schedule the always-running helper (FBHelper) to relaunch the main app at `date`. Stores the
/// target in the shared suite and pokes the helper via a distributed notification so it starts watching
/// immediately; the helper also reads the key on its own launch (the reboot case) and clears it once it
/// has relaunched us. This is how "turn everything off until tomorrow" brings the app back on its own
/// without adding a LaunchAgent.
func scheduleMainAppRestart(at date: Date){
    appdelegate!.sharedDefaults?.setValue(date, forKeyPath: kUserdefaultsMainAppScheduledRestartDate)
    appdelegate!.sharedDefaults?.synchronize()
    let scheduleMainAppRestart = Notification.Name("scheduleMainAppRestart")
    DistributedNotificationCenter.default().post(name: scheduleMainAppRestart, object: mainAppBundelId)
}

func stopMainAppForceQuitMonitoring(){
    if let state = appdelegate!.sharedDefaults?.object(forKey: kUserdefaultsStartMainAppIfNotRunning) as? Bool{
        if state{
            appdelegate!.sharedDefaults?.setValue(false, forKeyPath: kUserdefaultsStartMainAppIfNotRunning)
            appdelegate!.sharedDefaults?.synchronize()
            
            let stopMainAppForceQuitMonitoring = Notification.Name("stopMainAppForceQuitMonitoring")
            DistributedNotificationCenter.default().post(name: stopMainAppForceQuitMonitoring,object: mainAppBundelId)
        }
    }
}

func getWindowTheme()->String{
    var theme = "LIGHT"
    if mainWindowControllerObj != nil{
        if mainWindowControllerObj!.window?.hasDarkAppearance ?? false{
            theme = "DARK"
        }else {
            theme = "LIGHT"
        }
    }
    return theme
}


// blocking helpers
let validation = urlValidation()
/// The loopback ports Focus Bear's own embedded servers can occupy. `firstAvailablePort(from:)`
/// starts at 50501 and tries 50 ports, so this is that whole span rather than one number.
let focusBearLocalPortRange = 50501...50550

/// Whether a URL is a page Focus Bear itself is serving — the block page, the focus-block reminder,
/// the Firefox helper.
///
/// Exempting only the CURRENT port is not enough, and that is what caused report
/// 2026-09-21_10-04-40. A previous run's server keeps its port until it is reaped, so each launch
/// picks a higher one. A block page a browser is still showing from an earlier run then has a
/// different port from the running app's, stops being recognised as ours, and gets blocked — by a
/// block page that carries the first one as `old_url`. The user's screenshot is that recursion:
/// 50504 blocking 50503, which was itself blocking ankiweb.net.
///
/// Matched on the parsed HOST and PORT, never as a substring, so a hostile URL that merely mentions
/// `localhost:50504` inside its query string is not let through.
func isFocusBearLocalPage(_ url: String) -> Bool {
    let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }
    // URLComponents needs a scheme to find a host; browsers hand us both spellings.
    // The "://" is required, not optional: a bare "localhost:50504/?old_url=x" otherwise matches
    // a scheme pattern, and Foundation then parses "localhost" AS the scheme and reports no host
    // at all — so the app's own block page would be treated as somebody else's page.
    let hasScheme = trimmed.range(of: "^[A-Za-z][A-Za-z0-9+.-]*://", options: .regularExpression) != nil
    guard let components = URLComponents(string: hasScheme ? trimmed : "http://" + trimmed),
          let host = components.host?.lowercased(),
          let port = components.port else { return false }
    guard ["localhost", "127.0.0.1", "::1", "0.0.0.0"].contains(host) else { return false }
    return focusBearLocalPortRange.contains(port)
}

var defaultAllowedUrl = ["focus-block.html",
                         "earnyourscreentime.com",
                         "devtools://",
                         "chrome-extension://",
                         "focusbear.io",
                         "view-source:",
                         "about:blank",
                         "https://focus-bear.github.io",
                         "localhost:50501"]// new added



func isMicroBreaksRunning()->Bool{
    if currentState == ._MICRO_BREAK_{
        if breakWarningWcObj != nil{
            if breakWarningWcObj?.window?.isVisible ?? false{
                return false
            }
        }
        return true
    }
    return false
}

func reloadPermissionsIfNeeded() {
    guard mainWindowControllerObj?.window?.isVisible == true,
          leftMenuVcObj?.boxBlocks.isSelected == true,
          let customVC = customBlockingSchedulesVcObj,
          let containerVC = tabStrictnessContainerVcObj,
          containerVC.containerView.subviews.contains(customVC.view)
    else { return }

    customVC.checkPermissions()
}


