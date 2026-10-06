//
//  UITestContract+Settings.swift
//  Focus Bear
//
//  Accessibility identifiers for the regression tests of Settings, blocking and the menu-bar menu (RegressionSettingsUITests, RegressionBlockingUITests, RegressionMenuBarUITests).
//  Compiled into the app and the UI-test target, like UITestContract.swift. Each area has its own
//  file so the branches writing those tests never edit the same one.
//

extension UITestContract.Identifier {
    enum SettingsRegression {
        // MARK: Settings sidebar

        static let searchField = "settingsSearchField"
        /// The table of matches under the search field.
        static let searchResults = "settingsSearchResults"
        static let exportDataButton = "settingsExportDataButton"
        static let checkForUpdatesButton = "settingsCheckForUpdatesButton"
        static let releaseNotesButton = "settingsReleaseNotesButton"
        static let versionLabel = "settingsVersionLabel"
        /// Geek / Simple. Segment 0 is Geek, segment 1 Simple (`GeekModeSegmentedControl`).
        static let geekModeControl = "settingsGeekModeControl"

        // MARK: Panes

        /// Pane ids missing from `Settings.Pane`: the values of settingsSideBarVc's `idAdvanced`,
        /// `idBrowserTabLimiter` and `idAlwaysAllowedApps`. Sub-pages are named `Settings.panePrefix + id`
        /// like the sidebar's panes.
        static let advancedPane = "advanced"
        static let tabLimiterPane = "browsertablimiter"
        static let alwaysAllowedAppsPane = "alwaysallowedapps"

        static let focusGlowBorderSwitch = "settingsFocusGlowBorderSwitch"
        static let reduceMotionSwitch = "settingsReduceMotionSwitch"
        static let motivationalMessageSwitch = "settingsMotivationalMessageSwitch"
        static let showToDoPlayerSwitch = "settingsShowToDoPlayerSwitch"
        static let showBreaksInCallSwitch = "settingsShowBreaksInCallSwitch"
        static let pomodoroWorkRatioField = "settingsPomodoroWorkRatioField"
        static let pomodoroBreakRatioField = "settingsPomodoroBreakRatioField"
        /// "For every N minutes you focus…", rewritten as the ratio fields change.
        static let pomodoroRatioDescription = "settingsPomodoroRatioDescription"
        static let strictnessSlider = "settingsStrictnessSlider"
        /// The "How strict do you want Focus Bear to be?" sheet the slider opens.
        static let strictnessSheetSlider = "settingsStrictnessSheetSlider"
        static let strictnessSheetCancelButton = "settingsStrictnessSheetCancelButton"
        /// Each Advanced list row is `advancedRowPrefix + the id of the page it opens` (`idMeetings`…).
        static let advancedRowPrefix = "settingsAdvancedRow_"
        static let officeModeRadio = "settingsOfficeModeRadio"
        static let workFromHomeRadio = "settingsWorkFromHomeRadio"
        /// "No" on the "add an office-friendly break activity?" question, which leaves the mode as it was.
        static let officeModeDeclineButton = "settingsOfficeModeDeclineButton"
        static let permissionsTable = "settingsPermissionsTable"
        static let accountEmail = "settingsAccountEmail"

        // MARK: Blocking panes reached from the Strictness list

        static let tabLimiterRow = "blockingTabLimiterRow"
        static let alwaysAllowedAppsRow = "blockingAlwaysAllowedAppsRow"
        static let tabLimiterSwitch = "blockingTabLimiterSwitch"
        static let tabLimiterCountField = "blockingTabLimiterCountField"
        static let tabLimiterStepper = "blockingTabLimiterStepper"
        /// "Cancel" on the "Browser Permissions Required" question the switch asks first.
        static let tabLimiterPermissionCancelButton = "blockingTabLimiterPermissionCancelButton"
        static let alwaysAllowedAppsTable = "blockingAlwaysAllowedAppsTable"
        static let alwaysAllowedAppsAddButton = "blockingAlwaysAllowedAppsAddButton"
        static let alwaysAllowedAppsRemoveButton = "blockingAlwaysAllowedAppsRemoveButton"

        // MARK: Block list editor

        static let blockListCreateButton = "blockListCreateButton"
        /// A block list's card in the left rail is `blockListCardPrefix + its name`.
        static let blockListCardPrefix = "blockListCard:"
        static let blockListDeleteButton = "blockListDeleteButton"
        static let blockListRenameButton = "blockListRenameButton"
        static let blockListNameField = "blockListNameField"
        static let blockListEditButton = "blockListEditButton"
        /// The search field; typing in it also offers the quick-add cards below.
        static let blockListSearchField = "blockListSearchField"
        /// Quick-add card that adds the typed text as a website (or keyword).
        static let blockListAddWebsiteCard = "blockListAddWebsiteCard"
        /// Quick-add card for the installed app that best matches the typed text.
        static let blockListAddAppCard = "blockListAddAppCard"
        /// Quick-add card shown when no installed app matches; it opens the file picker.
        static let blockListAddAppManuallyCard = "blockListAddAppManuallyCard"
        /// A website or app in the list is `blockListEntryPrefix + its stored value` (domain or app path).
        static let blockListEntryPrefix = "blockListEntry:"
        static let blockListRemoveEntryButton = "blockListRemoveEntryButton"
        /// The "Add Block List" sheet.
        static let addBlockListNameField = "addBlockListNameField"
        static let addBlockListAddButton = "addBlockListAddButton"
        static let addBlockListCancelButton = "addBlockListCancelButton"
        /// "A block list with this name already exists."
        static let addBlockListError = "addBlockListError"
        /// The block list's Advanced sheet.
        static let blockListUseAiCheckbox = "blockListUseAiCheckbox"
        static let blockListAdvancedOkButton = "blockListAdvancedOkButton"

        // MARK: Blocking schedules

        static let scheduleAddButton = "blockingScheduleAddButton"
        /// A schedule's card in the list is `scheduleCardPrefix + its name`.
        static let scheduleCardPrefix = "blockingScheduleCard:"
        static let schedulePresets = "blockingSchedulePresets"
        /// A preset tile is `schedulePresetPrefix + its index in SchedulePreset.all`; the last is Custom.
        static let schedulePresetPrefix = "blockingSchedulePreset_"
        static let scheduleEditor = "blockingScheduleEditorForm"
        static let scheduleNameField = "blockingScheduleNameField"
        /// A day pill is `scheduleDayPrefix + its weekday` (1 = Sunday … 7 = Saturday, as Calendar counts).
        static let scheduleDayPrefix = "blockingScheduleDay_"
        /// A strictness choice is `scheduleStrictnessPrefix + 0, 1 or 2` (Flexible, Moderate, Strict).
        static let scheduleStrictnessPrefix = "blockingScheduleStrictness_"
        static let scheduleSaveButton = "blockingScheduleSaveButton"
        static let scheduleCancelButton = "blockingScheduleCancelButton"
        static let scheduleDeleteButton = "blockingScheduleDeleteButton"
        /// "No thanks" on the "Allow permissions to block…" question after the first schedule is created.
        static let schedulePermissionsDeclineButton = "blockingSchedulePermissionsDeclineButton"

        // MARK: Menu-bar popover

        static let menuStartFocusButton = "menuBarStartFocusButton"
        static let menuFocusGoalField = "menuBarFocusGoalField"
        static let menuBreaksRow = "menuBarBreaksRow"
        static let menuStartBreakLink = "menuBarStartBreakLink"
        static let menuDayPlanRow = "menuBarDayPlanRow"
        static let menuViewFullDayPlanLink = "menuBarViewFullDayPlanLink"
        static let menuToolsRow = "menuBarToolsRow"
        static let menuFocusMusicButton = "menuBarFocusMusicButton"
        static let menuNotesButton = "menuBarNotesButton"
        static let menuToDoPlayerButton = "menuBarToDoPlayerButton"
        static let menuPinButton = "menuBarPinButton"
        static let menuMicButton = "menuBarMicButton"
        /// The quit popup the popover's power button raises instead of quitting.
        static let quitPopup = "quitPopup"
    }
}
