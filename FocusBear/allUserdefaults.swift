//
//  allUserdefaults.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/07/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


var kUserDefaultsSelectedOccupationIndex = "kUserDefaultsSelectedOccupationIndex"

var kUserDefaultsFirstAppFullLoadDate = "kUserDefaultsFirstAppFullLoadDate"

var kUserdefaultsIsUserLoggedIn = "kUserdefaultsIsUserLoggedIn"
var kUserdefaultsUserSubscriptionCheckDate = "kUserdefaultsUserSubscriptionCheckDate"

var kUserdefaultsDontTellAgain = "kUserdefaultsDontTellAgain"
var kUserdefaultsAppQuitProperly = "kUserdefaultsAppQuitProperly"


var kUserdefaultsTotalTimeSpentOnDistractingSites = "kUserdefaultsTotalTimeSpentOnDistractingSites"
var kUserdefaultsTotalDistractingSitesBlocked = "kUserdefaultsTotalDistractingSitesBlocked"

var kUserdefaultsAlertShownFirstTempAllow = "kUserdefaultsAlertShownFirstTempAllow"

var kUserdefaultsDeviceId = "kUserdefaultsDeviceId"
let kUserdefaultsSelectedJson = "kUserdefaultsSelectedJson"

var kUserdefaultsPasswordSetInOnboarding = "kUserdefaultsPasswordSetInOnboarding"

let kUserdefaultsFirstRunDate = "kUserdefaultsFirstRunDate"// system app first run date hai
var kUserdefaultsImpactMeasurementShown = "kUserdefaultsImpactMeasurementShown"
var kUserdefaultsEnableScreenTimeShown = "kUserdefaultsEnableScreenTimeShown"
var kUserdefaultsScreenTimeEnabledOneTime = "kUserdefaultsScreenTimeEnabledOneTime"

var kUserdefaultsGetLateNoMoreShown = "kUserdefaultsGetLateNoMoreShown"

var kUserdefaultsSurveyShown = "kUserdefaultsSurveyShown"
var kUserdefaultsBeginMorningHabitClickedDate = "kUserdefaultsBeginMorningHabitClickedDate"
var kUserdefaultsBeginEveningHabitClickedDate = "kUserdefaultsBeginEveningHabitClickedDate"

var kUserdefaultsFirefoxPermissionShown = "kUserdefaultsFirefoxPermissionShown"
var kUserdefaultsSigmaOSPermissionShown = "kUserdefaultsSigmaOSPermissionShown"

var kUserdefaultsAllBrowsersPermissionInfo = "kUserdefaultsAllBrowsersPermissionInfo"

var kUserdefaultsBrowsersPermissionsSetByUser = "kUserdefaultsBrowsersPermissionsSetByUser"
var kUserdefaultsIsAnyDistractionSetByUser = "kUserdefaultsIsAnyDistractionSetByUser"



var kUserdefaultsSimplePomodoroAiBlockingSelected = "kUserdefaultsSimplePomodoroAiBlockingSelected"

let kUserdefaultsFirstRun = "kUserdefaultsFirstRun"// for onboarding
let kUserdefaultsAppQuitForUser = "kUserdefaultsAppQuitForUser"
let kUserdefaultsStartHabitNagCount = "kUserdefaultsStartHabitNagCount"
let kUserdefaultsLastNagShowDate = "kUserdefaultsLastNagShowDate"
let kUserdefaultsDontShowNudgeView = "kUserdefaultsDontShowNudgeView"
let kUserdefaultsNoHabitFound = "kUserdefaultsNoHabitFound"
let kUserdefaultsOnboardingIncompleted = "kUserdefaultsOnboardingIncompleted"


let kUserdefaultsControllingBrowserVcShown = "kUserdefaultsControllingBrowserVcShown"

var kUserdefaultsVideoShown = "kUserdefaultsVideoShown"
var kUserdefaultsFocusTipsShown = "kUserdefaultsFocusTipsShown"

var kUserdefaultsShowDockIcon = "kUserdefaultsShowDockIcon"

/// Absent key means "on" — the glow is on by default during focus sessions.
var kUserdefaultsFocusGlowBorderEnabled = "kUserdefaultsFocusGlowBorderEnabled"

let kUserdefaultsLastHabitShowDate = "UserdefaultsLastHabitShowDate"

var kUserdefaultsLastHabitsStartedDate = "kUserdefaultsLastHabitsStartedDate"
var kUserdefaultsLastHabitID = "kUserdefaultsLastHabitID"

var kUserdefaultsLastHabitRunningInfo = "kUserdefaultsLastHabitRunningInfo"
var kUserdefaultsLastCustomRoutineHabitRunningInfo = "kUserdefaultsLastCustomRoutineHabitRunningInfo"

var kUserdefaultsLastSequencePostponeInfo = "kUserdefaultsLastSequencePostponeInfo"

var kUserdefaultsLastSequenceSelectHabitsInfo = "kUserdefaultsLastSequenceSelectHabitsInfo"

var kUserdefaultsLastBreakActivityPostponeInfo = "kUserdefaultsLastBreakActivityPostponeInfo"
var kUserdefaultsMicroBreaksDoneCount = "kUserdefaultsMicroBreaksDoneCount"


var kUserdefaultsNotesAddedInOfflineCsv = "kUserdefaultsNotesAddedInOfflineCsv"
var kUserdefaultsTagsColumnAddedInStatsCsv = "kUserdefaultsTagsColumnAddedInStatsCsv"

var kUserdefaultsEditBlockedUrlsOnce = "kUserdefaultsEditBlockedUrlsOnce"

var kUserdefaultsShutOffCancelledForEveningRoutine = "kUserdefaultsShutOffCancelledForEveningRoutine"
var kUserdefaultsLastFocusSavedIntention = "kUserdefaultsLastFocusSavedIntention"

/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsAllFocusModesTags` (SecureStore registers the base).
let kUserdefaultsAllFocusModesTagsBase = "kUserdefaultsAllFocusModesTags"
var kUserdefaultsAllFocusModesTags = kUserdefaultsAllFocusModesTagsBase
var kUserdefaultsIsAppEnabled = "kUserdefaultsIsAppEnabled"
var kUserdefaultsLastAppAbortedDate = "kUserdefaultsLastAppAbortedDate"
var kUserdefaultsLastFocusModeDoneDate = "kUserdefaultsLastFocusModeDoneDate"
var kUserdefaultsLastFocusModeMinutes = "kUserdefaultsLastFocusModeMinutes"   // menu quick-start default duration

var kUserdefaultsLastInactivityNagShowDate = "kUserdefaultsLastInactivityNagShowDate"

var kUserdefaults4HourReActivateTime = "kUserdefaults4HourReActivateTime"
var kUserdefaultsShutdownAborted = "kUserdefaultsShutdownAborted"
var kUserdefaultsEveningHabitsShowedTillDate = "kUserdefaultsEveningHabitsShowedTillDate"//agar evening habit ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to evening habit vapas na aay
var kUserdefaultsFocusSummaryShowedTillDate = "kUserdefaultsFocusSummaryShowedTillDate"//agar Focus Summary ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to Focus Summary vapas na aay


var kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate = "kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate"




var kUserdefaultsPackIdSelected = "kUserdefaultsPackIdSelected"

var kUserdefaultsStartupTimeFromOnboarding = "kUserdefaultsStartupTimeFromOnboarding"
var kUserdefaultsShutOffTimeFromOnboarding = "kUserdefaultsShutOffTimeFromOnboarding"
var kUserdefaultsSleepTimeFromOnboarding = "kUserdefaultsSleepTimeFromOnboarding"
//var kUserdefaultsBreakDurationValue = "kUserdefaultsBreakDurationValue"
var kUserdefaultsBreaksEnabledFromOnboarding = "kUserdefaultsBreaksEnabledFromOnboarding"


var kUserdefaultsHabitSkipEasinessFromOnboarding = "kUserdefaultsHabitSkipEasinessFromOnboarding"
var kUserdefaultsBlockedUrlsFromOnboarding = "kUserdefaultsBlockedUrlsFromOnboarding"
var kUserdefaultsBlockedAppsFromOnboarding = "kUserdefaultsBlockedAppsFromOnboarding"

//var kUserdefaultsSelectedFolder = "kUserdefaultsSelectedFolder"

/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsArrFocusTypes` (SecureStore registers the base).
let kUserdefaultsArrFocusTypesBase = "kUserdefaultsArrFocusTypes"
var kUserdefaultsArrFocusTypes = kUserdefaultsArrFocusTypesBase
var kUserdefaults24HoursClearPasswordTime = "kUserdefaults24HoursClearPasswordTime"
var kUserdefaultsSelectedLanguage = "kUserdefaultsSelectedLanguage"
var kUserdefaultsScreenTimeEnabled = "kUserdefaultsScreenTimeEnabled"

let kUserdefaultsFocusAddedFromFirstHabit = "kUserdefaultsFocusAddedFromFirstHabit"
//var kUserdefaultsDontShowToolBoxAutomatically = "kUserdefaultsShowToolBoxAutomatically"
//var kUserdefaultsDontShowToolBoxAutomaticallyForActivity = "kUserdefaultsDontShowToolBoxAutomaticallyForActivity"

/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsFocusModeNotes` (SecureStore registers the base).
let kUserdefaultsFocusModeNotesBase = "kUserdefaultsFocusModeNotes"
var kUserdefaultsFocusModeNotes = kUserdefaultsFocusModeNotesBase

// #2142: set once the saved local brain dump has been migrated to the backend (PUT /note). After that
// the native Notes view (FocusBear/Notes) loads the brain dump from the API, so we never re-seed it.
var kUserdefaultsBrainDumpSentToWebView = "kUserdefaultsBrainDumpSentToWebView"

let kUserdefaultsFocusCompletedTourShown = "kUserdefaultsFocusCompletedTourShown"

let kUserdefaultsPomodoroTourShown = "kUserdefaultsPomodoroTourShown"

//let kUserdefaultsAdditionalGoals = "kUserdefaultsAdditionalGoals"

//let kUserdefaultsSitesUnlockedInPomodoroBreakAlertShown = "kUserdefaultsSitesUnlockedInPomodoroBreakAlertShown"
let kUserdefaultsIsAdvancedPomodoroEnabled = "kUserdefaultsIsAdvancedPomodoroEnabled"


let kUserdefaultsStartRoutineButtonClicked = "kUserdefaultsStartRoutineButtonClicked"

let kUserdefaultsIsCompletedFocusWindowOnTop = "kUserdefaultsIsCompletedFocusWindowOnTop"

let kUserdefaultsGlobalUUID = "kUserdefaultsGlobalUUID"


let kUserdefaultsToDoPlayerWindowClosedFirstTime = "kUserdefaultsToDoPlayerWindowClosedFirstTime"

var kUserdefaultsDisableBreaksForToday = "kUserdefaultsDisableBreaksForToday"

var kUserdefaultsIsHabitsDisabledFromOnboarding = "kUserdefaultsIsHabitsDisabledFromOnboarding"

/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsLastHabitSavedNotes` (SecureStore registers the base).
let kUserdefaultsLastHabitSavedNotesBase = "kUserdefaultsLastHabitSavedNotes"
var kUserdefaultsLastHabitSavedNotes = kUserdefaultsLastHabitSavedNotesBase
/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsLastActivitySavedNotes` (SecureStore registers the base).
let kUserdefaultsLastActivitySavedNotesBase = "kUserdefaultsLastActivitySavedNotes"
var kUserdefaultsLastActivitySavedNotes = kUserdefaultsLastActivitySavedNotesBase
/// The unsuffixed key: sign-in appends the user id to `kUserdefaultsLastCustomRoutineHabitSavedNotes` (SecureStore registers the base).
let kUserdefaultsLastCustomRoutineHabitSavedNotesBase = "kUserdefaultsLastCustomRoutineHabitSavedNotes"
var kUserdefaultsLastCustomRoutineHabitSavedNotes = kUserdefaultsLastCustomRoutineHabitSavedNotesBase


var kUserdefaultsLastSpecaialActivitySavedNotes = "kUserdefaultsLastSpecaialActivitySavedNotes"
var kUserdefaultsAllTracks = "kUserdefaultsAllTracks"
// User-added Spotify track/album/playlist links (Focus Music), separate from
// kUserdefaultsAllTracks which is overwritten wholesale from the backend on every launch.
var kUserdefaultsCustomSpotifyTracks = "kUserdefaultsCustomSpotifyTracks"
// User-added YouTube/YouTube Music links (Focus Music), same idea as kUserdefaultsCustomSpotifyTracks.
var kUserdefaultsYouTubeMusicTracks = "kUserdefaultsYouTubeMusicTracks"
// Track id last started via the Play button — used to resume the same track when the
// post-session-start "want to play some focus music?" prompt is accepted.
var kUserdefaultsLastPlayedTrackId = "kUserdefaultsLastPlayedTrackId"
var kUserdefaultsDontConfirmBeforeExecuteScript = "kUserdefaultsDontConfirmBeforeExecuteScript"

var kUserdefaultsIsGlobalUUIDLinked = "kUserdefaultsIsGlobalUUIDLinked"
var kUserdefaultsIsMacIdLinked = "kUserdefaultsIsMacIdLinked"

var kUserdefaultsLastFocusModeStrictness = "kUserdefaultsLastFocusModeStrictness"
// Whether the running focus session was started by the app (a Late No More meeting, or an
// approved-postpone accountability buddy) rather than by the user. Persisted beside the strictness
// above and restored with it, so an auto-started session stays stoppable after a relaunch.
// See FocusSessionStopPermission.swift.
var kUserdefaultsIsFocusSessionAutoStarted = "kUserdefaultsIsFocusSessionAutoStarted"

// Suppresses the "Want to play some focus music?" prompt shown after a focus session starts.
var kUserdefaultsDontAskFocusMusicPrompt = "kUserdefaultsDontAskFocusMusicPrompt"
// The user's saved answer to the focus-music prompt: "ask" (default, prompt each focus session),
// "play" (auto-start music), "off" (stay silent). Surfaced as a toggle in Settings → Accessibility
// (on = play) and synced to the account (see SettingsManager.focusMusicAutoStart). Per-user suffixed.
var kUserdefaultsFocusMusicAutoStartPreference = "kUserdefaultsFocusMusicAutoStartPreference"
var kUserDefaultsOpenTodoPlayerFirstTime = "kUserDefaultsOpenTodoPlayerFirstTime"

var kUserDefaultsHideAppModeOption = "kUserDefaultsHideAppModeOption"
//var kUserDefaultsHideShowBrainDumpOption = "kUserDefaultsHideShowBrainDumpOption"


var kUserDefaultsBlockPageTourShowed = "kUserDefaultsBlockPageTourShowed"

var kUserDefaultsHowHeardAboutApp = "kUserDefaultsHowHeardAboutApp"

/// The unsuffixed key: sign-in appends the user id to `kUserDefaultsLastQuitReason` (SecureStore registers the base).
let kUserDefaultsLastQuitReasonBase = "kUserDefaultsLastQuitReason"
var kUserDefaultsLastQuitReason = kUserDefaultsLastQuitReasonBase
var kUserdefaultsManageTaskFirstTime = "kUserdefaultsManageTaskFirstTime"


var kUserdefaultsLastBreaksStartTime = "kUserdefaultsLastBreaksStartTime"
var kUserdefaultsArrayBreaksDurations = "kUserdefaultsArrayBreaksDurations"
var kUserdefaultsLastBreakEndTime = "kUserdefaultsLastBreakEndTime" // added on 24/7/25 v 1.26.394 //Mac app shows “Time since last break: 39m” but I actually had my laptop closed for 39m and just opened it now. It should show more like 2minutes
// Wall-clock time the next break is due. Persisted so that plain stop/reschedule events (pause/resume,
// settings reload, a deferred break) preserve how far the countdown has progressed instead of restarting
// a full interval each time — otherwise the countdown can perpetually reset and breaks stop firing.
var kUserdefaultsNextBreakDueTime = "kUserdefaultsNextBreakDueTime"


var kUserDefaultsCustomGoals = "kUserDefaultsCustomGoals"
var kUserDefaultsSelectedOccupationForPosthog = "kUserDefaultsSelectedOccupation"
var kUserDefaultsSelectedOccupationForPosthogKey = "kUserDefaultsSelectedOccupation"


//let kUserDefaultsLastNudgeScoreWindowXPoisition = "nudgeScoreWindowXPoisition"

let kUserDefaultsLastUserEmailBeforeLogout = "kUserDefaultsLastUserEmailBeforeLogout"
let kUserDefaultsLastUserLoginWithGoogle = "kUserDefaultsLastUserLoginWithGoogle"
let kUserDefaultsAppRestartedNormally = "kUserDefaultsAppRestartedNormally"

var kUserdefaultsLastShutdownAbortedDate = "kUserdefaultsLastShutdownAbortedDate"

var kUserdefaultsFocusStatsExpanded = "kUserdefaultsFocusStatsExpanded"
var kUserdefaultsFocusAllThingsExpanded = "kUserdefaultsFocusAllThingsExpanded"



var kUserdefaultsStartMainAppIfNotRunning = "kUserdefaultsStartMainAppIfNotRunning"

// #2575: a Date in the shared suite. When set, the always-running helper (FBHelper) relaunches the main
// app once this time passes, then clears the key. Written by scheduleMainAppRestart() when the user picks
// "turn everything off until tomorrow". Must match the identical constant in FBHelper/globalFile.swift.
let kUserdefaultsMainAppScheduledRestartDate = "kUserdefaultsMainAppScheduledRestartDate"

var kUserdefaultsBrowsersTabAuditReportSaveDate = "kUserdefaultsBrowsersTabAuditReportSaveDate"

var kUserdefaultsLastUnlockTimeByAccountabilityBuddy = "kLastUnlockTimeByAccountabilityBuddy"



var kUserDefaultsLastRoutinePostponeEndDate = "kLastRoutinePostponeEndDate" // v 2.28.454
var kUserDefaultsLastRoutinePostponeState = "kLastRoutinePostponeState"// morning/ evening/ focus summary  // v 2.28.454
// Set once the persisted routine postpone has been checked against the meeting-postpone cap — see
// `PersistedPostponeRestore`.
var kUserDefaultsPersistedPostponeCapChecked = "kPersistedPostponeCapChecked"
// End date of the routine postpone a meeting focus session is covering — see `MeetingPostponeSession`.
var kUserDefaultsMeetingSessionPostponeEndDate = "kMeetingSessionPostponeEndDate"

var kUserDefaultsBlockingScheduleAddedFirstTime = "kBlockingScheduleAddedFirstTime"// v2.29.461

// Break frequency prompt streak tracking (#1144). `var` (not `let`) so they get the userId appended on
// login (see AppDelegate) — keeps each account's off-streak / frequency separate on a shared device.
var kUserdefaultsBreakOffDates         = "kFBBreakOffDates"
var kUserdefaultsBreakOffPromptShown   = "kFBBreakOffPromptShownDate"

var kUserdefaultsHiddenFocusModeIDs = "kHiddenFocusModeIDs"
// IDs of TOOLS sidebar rows the user hid via the hover ✕ (restored via the TOOLS gear icon).
var kUserdefaultsHiddenToolIds = "kUserdefaultsHiddenToolIds"
var kUserdefaultsLastFocusModeId = "kLastRunningFocusModeId"
// Block list the user last picked on the Focus-time (pomodoro) screen. Dedicated key so it isn't
// clobbered by kUserdefaultsLastFocusModeId, which any focus mode (incl. scheduled blocking) sets.
var kUserdefaultsLastPomodoroFocusModeId = "kLastPomodoroFocusModeId"

var kUserdefaultsLastHabitsIdsBeforePostpone = "kRemainingHabitIdsBeforePostpone"
var kUserdefaultsPrefilterLastHabitsIdsBeforePostpone = "kPrefilterRemainingHabitIdsBeforePostpone"

var kUserdefaultsLastRunningFocusModeInfo = "kLastRunningFocusModeInfo"

var kUserdefaultsIsGuestAccount = "kUserdefaultsIsGuestAccount"

// WiFi profile auto-switching (#1000)
let kUserdefaultsWiFiProfileMappings = "kFBWiFiProfileMappings"

// Personal data SecureStore keeps encrypted (FocusBear/Security/SensitiveKeyRegistry.swift).
let kUserdefaultsDayPlanTasksByDay = "dayPlanTasksByDay"
let kUserdefaultsScheduleEventPrivateNotes = "scheduleEventPrivateNotes"
let kUserdefaultsScheduleEventLocalOverrides = "scheduleEventLocalOverrides"
let kUserdefaultsAiBlockingLogEntries = "aiBlockingLogEntries"
let kAccountabilityBuddySessionPersistKey = "kAccountabilityBuddySessionPersist"
/// SettingsManager appends the user id to its copies of these at sign-in.
let kUserdefaultsArrBlockedUrlsBase = "kUserdefaultsArrBlockedUrls"
let kUserdefaultsArrBlockedAppsBase = "kUserdefaultsArrBlockedApps"
let kUserdefaultsArrAlwaysAllowedAppsBase = "kUserdefaultsArrAlwaysAllowedApps"
let kUserdefaultsLocalDeviceSettingsBase = "kUserdefaultsLocalDeviceSettings"


// Talking clock (#1674)
var kUserdefaultsTalkingClockEnabled = "kUserdefaultsTalkingClockEnabled"
var kUserdefaultsTalkingClockInterval = "kUserdefaultsTalkingClockInterval"
var kUserdefaultsTalkingClockQuietStart = "kUserdefaultsTalkingClockQuietStart"
var kUserdefaultsTalkingClockQuietEnd = "kUserdefaultsTalkingClockQuietEnd"
var kUserdefaultsTalkingClockSuppressMeetings = "kUserdefaultsTalkingClockSuppressMeetings"
