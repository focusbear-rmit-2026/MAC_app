//
//  DayPlanRoutineDraft.swift
//  Focus Bear
//
//  In-memory draft of the routine/habit edits made from the Day Plan (the habit "Edit" button and the
//  routine header's "Edit routine timing"). Every edit is applied in two places at once:
//    1. the live runtime state (the `habit` arrays + the routine start-time globals), so the Day Plan
//       and the habit table re-render immediately; and
//    2. a working copy of the user-settings JSON (the same blob the Edit Habits webview saves).
//  Nothing reaches the server until the user clicks "Save and restart app" on the Day Plan banner, which
//  PUTs the working copy through the existing settings-save path and restarts the app so every subsystem
//  re-reads the canonical settings. The draft lives only in memory: quitting without saving discards it.
//

import Foundation

/// Which list of the user-settings JSON a habit (or routine) belongs to.
enum RoutineSettingsSection: Equatable {
    case morning
    case evening
    /// A custom routine, identified by its `activity_sequence_id` (stable across reorders, unlike an index).
    case custom(sequenceId: String)
}

/// Keys of the user-settings JSON touched by the Day Plan editors. Mirrors the web dashboard's
/// `ActivityType` (web_dashboard/src/interfaces/common.interface.ts) and the parser in
/// AppDelegate.readSettingsJsonDictionary.
enum RoutineSettingsKey {
    static let morningActivities = "morning_activities"
    static let eveningActivities = "evening_activities"
    static let customRoutines = "custom_routines"
    static let standaloneActivities = "standalone_activities"
    static let startupTime = "startup_time"
    static let shutdownTime = "shutdown_time"
    static let eveningCutoffTime = "cutoff_time_for_non_high_priority_activities"
    static let routineStartTime = "start_time"
    static let routineEndTime = "end_time"
    static let routineName = "name"
    static let activitySequenceId = "activity_sequence_id"
    static let routineDaysOfWeek = "days_of_week"
    static let routineTrigger = "trigger"

    static let id = "id"
    static let activityType = "activity_type"
    static let icon = "habit_icon"
    static let name = "name"
    static let durationSeconds = "duration_seconds"
    static let completionRequirements = "completion_requirements"
    static let priority = "priority"
    static let daysOfWeek = "days_of_week"
    static let cutoffTime = "cutoff_time_for_doing_activity"
    static let videoUrls = "video_urls"
    static let allowedApps = "allowed_apps"
    static let allowedUrls = "allowed_urls"
    static let runMicroBreaks = "run_micro_breaks"
    static let allowedFocusModeId = "allowed_focus_mode_id"
    static let showSavedDistractingWebsites = "show_saved_distracting_websites"
    static let logQuantity = "log_quantity"
    static let logQuantityQuestions = "log_quantity_questions"
    static let logSummaryType = "log_summary_type"
    static let takeNotes = "take_notes"
    static let choiceType = "choice_type"
    static let checkList = "check_list"
    static let choices = "choices"
    static let textInstructions = "text_instructions"
    static let imageUrls = "image_urls"
    static let imageUrl = "url"
    static let tags = "tags"

    static let questionId = "id"
    static let question = "question"
    static let minValue = "min_value"
    static let maxValue = "max_value"

    static let priorityHigh = "HIGH"
    static let priorityStandard = "STANDARD"
    static let choiceTypeCheckList = "check_list"
    static let logSummarySum = "SUM"
    static let logSummaryAverage = "AVG"

    /// `activity_type` values the web writes on a new habit (`ACTIVITY_SEQUENCE_TYPE`).
    static let activityTypeMorning = "morning"
    static let activityTypeEvening = "evening"
    static let activityTypeStandalone = "standalone"

    /// `trigger` values of a custom routine (web `CUSTOM_ROUTINE_TRIGGER`).
    static let triggerOnDemand = "ON_DEMAND"
    static let triggerOnSchedule = "ON_SCHEDULE"
}

/// The web's `DEFAULT_DURATION` for a habit added to each routine (`newHabit` reducer): morning habits
/// start at 5 minutes (`INIT_NEW_HABIT`), evening ones at 10, custom-routine ones at 1.
enum NewHabitDefaultSeconds {
    static let morning = 300
    static let evening = 600
    static let custom = 60

    static func forSection(_ section: RoutineSettingsSection) -> Int {
        switch section {
        case .morning: return morning
        case .evening: return evening
        case .custom: return custom
        }
    }
}

/// One "log data" question of a habit, in the editor's shape. `minValue`/`maxValue` are kept as text so
/// the form can distinguish "blank" (unset) from 0, like the web editor.
struct HabitLogQuestionEdit: Identifiable, Equatable {
    var id: String
    var question: String
    var minValue: String
    var maxValue: String

    /// Blank min AND max is valid (unset). One without the other, or min >= max, is not (web rules).
    var isValid: Bool {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let minText = minValue.trimmingCharacters(in: .whitespaces)
        let maxText = maxValue.trimmingCharacters(in: .whitespaces)
        if minText.isEmpty && maxText.isEmpty { return true }
        guard let min = Int(minText), let max = Int(maxText) else { return false }
        return min < max
    }
}

/// Everything the Day Plan habit editor can change, mapped 1:1 onto the settings JSON by
/// `DayPlanRoutineDraft.applyHabitEdit`. Read from the habit's JSON entry via `habitEditValues(id:)`.
struct HabitEditValues: Equatable {
    static let weekdayCodes = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]   // web `DaysOfWeek` enum, in display order
    static let maxDurationMinutes = 999                                        // web MAXIMUM_ALLOWED_MINUTES
    static let maxDurationSeconds = maxDurationMinutes * HabitDurationText.secondsPerMinute
    static let minDurationSeconds = 1
    static let maxSecondsPart = HabitDurationText.secondsPerMinute - 1
    static let noNote = NO_NOTE

    var icon: String
    var name: String
    var usesTimer: Bool
    /// The routine player's unit (`duration_seconds`); the editor shows it as minutes + seconds.
    var durationSeconds: Int
    var completionRequirement: String
    var isHighPriority: Bool
    var daysOfWeek: Set<String>
    var cutoffEnabled: Bool
    var cutoffMinutes: Int
    var videoUrls: [String]
    var allowedApps: [String]
    var allowedUrls: [String]
    var runMicroBreaks: Bool
    var allowedFocusModeId: String
    var showSavedDistractingWebsites: Bool
    var logQuantity: Bool
    var logQuestions: [HabitLogQuestionEdit]
    var logSummaryType: String
    var takeNotes: String
    var checklist: [String]
    var textInstructions: String
    var imageUrls: [String]
    var tags: [String]
    /// Random sub-habit choices aren't editable here (they're a nested editor on the web); the count is
    /// shown so the user knows they exist and are preserved untouched.
    var randomChoiceCount: Int

    var usesFocusMode: Bool { !allowedFocusModeId.isEmpty }
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isDurationValid: Bool { (Self.minDurationSeconds...Self.maxDurationSeconds).contains(durationSeconds) }
    var durationMinutesPart: Int {
        get { durationSeconds / HabitDurationText.secondsPerMinute }
        set { durationSeconds = Self.clampedSeconds(minutes: newValue, seconds: durationSecondsPart) }
    }
    var durationSecondsPart: Int {
        get { durationSeconds % HabitDurationText.secondsPerMinute }
        set { durationSeconds = Self.clampedSeconds(minutes: durationMinutesPart, seconds: newValue) }
    }

    /// Recomposes a minutes + seconds pair, keeping each part in its field's range (the total is
    /// validated separately so an over-long entry shows the message instead of silently shrinking).
    static func clampedSeconds(minutes: Int, seconds: Int) -> Int {
        let minutesPart = max(0, min(maxDurationMinutes, minutes))
        let secondsPart = max(0, min(maxSecondsPart, seconds))
        return minutesPart * HabitDurationText.secondsPerMinute + secondsPart
    }
    var orderedDays: [String] { Self.weekdayCodes.filter { daysOfWeek.contains($0) } }

    /// List fields are saved trimmed, with blank rows dropped.
    static func cleaned(_ items: [String]) -> [String] {
        items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    /// The form for a habit being added to `section`: the web's `INIT_NEW_HABIT` (blank name/icon, a timer of
    /// the routine's default length, must-do, every day, nothing else set) — no cutoff, no apps, no questions.
    static func newHabit(in section: RoutineSettingsSection) -> HabitEditValues {
        HabitEditValues(
            icon: "", name: "", usesTimer: true,
            durationSeconds: NewHabitDefaultSeconds.forSection(section),
            completionRequirement: "", isHighPriority: true, daysOfWeek: Set(weekdayCodes),
            cutoffEnabled: false, cutoffMinutes: DayPlanRoutineDraft.defaultCutoffMinutes(),
            videoUrls: [], allowedApps: [], allowedUrls: [], runMicroBreaks: false, allowedFocusModeId: "",
            showSavedDistractingWebsites: false, logQuantity: false, logQuestions: [],
            logSummaryType: RoutineSettingsKey.logSummarySum, takeNotes: noNote, checklist: [],
            textInstructions: "", imageUrls: [], tags: [], randomChoiceCount: 0)
    }
}

/// The routine-level fields of a custom routine, as the custom-routine editor shows them. Mirrors the
/// web's `CustomRoutineType` (web_dashboard/src/interfaces/setting.interface.ts:97).
struct CustomRoutineEditValues: Equatable {
    /// The web's `INIT_CUSTOM_ROUTINE`: no name, scheduled (not on-demand), every day, starting now and
    /// running for an hour.
    static let defaultLengthMinutes = 60

    var name: String
    var triggerOnDemand: Bool
    var daysOfWeek: Set<String>
    var startMinutes: Int
    var endMinutes: Int

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var orderedDays: [String] { HabitEditValues.weekdayCodes.filter { daysOfWeek.contains($0) } }

    /// An on-demand routine is started by hand, so its window is bookkeeping only; a scheduled one must
    /// have a real window (the API rejects `end_time <= start_time`).
    var isWindowValid: Bool { triggerOnDemand || endMinutes > startMinutes }

    static func newRoutine(now: Date = Date()) -> CustomRoutineEditValues {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        let start = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return CustomRoutineEditValues(
            name: "", triggerOnDemand: false, daysOfWeek: Set(HabitEditValues.weekdayCodes),
            startMinutes: start,
            endMinutes: min(DayPlanRoutineDraft.lastMinuteOfDay, start + defaultLengthMinutes))
    }
}

/// One habit of a custom routine as the routine editor lists it (name + the label the Day Plan uses).
struct CustomRoutineHabitSummary: Identifiable, Equatable {
    var id: String
    var name: String
    var durationLabel: String
}

/// A custom routine as the manager's list shows it.
struct CustomRoutineSummary: Identifiable, Equatable {
    /// The routine's `activity_sequence_id` — what `RoutineSettingsSection.custom` is keyed by, and
    /// stable across reordering (unlike the array index the on-demand panel's play button uses).
    var id: String
    var values: CustomRoutineEditValues
    var habits: [CustomRoutineHabitSummary]

    /// AppDelegate.readSettingsJsonDictionary drops a custom routine with no habits, so an empty one
    /// would silently vanish on the post-save restart. The editor warns instead of failing quietly.
    var isEmpty: Bool { habits.isEmpty }
}

final class DayPlanRoutineDraft {
    static let shared = DayPlanRoutineDraft()

    /// The working copy of the user-settings JSON with the drafted edits applied. `nil` until the first
    /// edit — that's the "no draft" state the banner keys off.
    private(set) var settings: NSMutableDictionary?
    private(set) var isSaving = false
    private let savedSettingsJSON: () -> String?

    /// `savedSettingsJSON` is the saved user-settings blob; tests pass a fixture instead of UserDefaults.
    init(savedSettingsJSON: @escaping () -> String? = { SensitiveDefaults.string(forKey: kUserdefaultsSelectedJson) }) {
        self.savedSettingsJSON = savedSettingsJSON
    }

    var hasChanges: Bool { settings != nil }

    // MARK: Reading

    /// The habit's section + its JSON entry (from the draft if one exists, else the saved settings).
    func habitEntry(id: String) -> (section: RoutineSettingsSection, entry: NSMutableDictionary)? {
        workingSettings().flatMap { locateHabit(id: id, in: $0) }
    }

    private func locateHabit(id: String, in root: NSMutableDictionary) -> (section: RoutineSettingsSection, entry: NSMutableDictionary)? {
        if let entry = findHabit(id: id, in: root[RoutineSettingsKey.morningActivities]) { return (.morning, entry) }
        if let entry = findHabit(id: id, in: root[RoutineSettingsKey.eveningActivities]) { return (.evening, entry) }
        for routine in customRoutineEntries(root) {
            guard let sequenceId = routine[RoutineSettingsKey.activitySequenceId] as? String else { continue }
            if let entry = findHabit(id: id, in: routine[RoutineSettingsKey.standaloneActivities]) {
                return (.custom(sequenceId: sequenceId), entry)
            }
        }
        return nil
    }

    /// The section a Day Plan habit group belongs to, resolved from any habit id in it.
    func routineSection(forHabitId id: String) -> RoutineSettingsSection? { habitEntry(id: id)?.section }

    func habitEditValues(id: String) -> HabitEditValues? {
        guard let entry = habitEntry(id: id)?.entry else { return nil }
        let completion = entry[RoutineSettingsKey.completionRequirements] as? String
        let durationSeconds = entry[RoutineSettingsKey.durationSeconds] as? Int ?? 0
        let cutoff = entry[RoutineSettingsKey.cutoffTime] as? String
        let questions = (entry[RoutineSettingsKey.logQuantityQuestions] as? [NSDictionary] ?? []).map { q -> HabitLogQuestionEdit in
            let min = q[RoutineSettingsKey.minValue] as? Int
            let max = q[RoutineSettingsKey.maxValue] as? Int
            // The API stores "unset" as 0/0 (web denormalises on the boundary); show that as blank.
            let unset = (min ?? 0) == 0 && (max ?? 0) == 0
            return HabitLogQuestionEdit(id: q[RoutineSettingsKey.questionId] as? String ?? UUID().uuidString,
                                        question: q[RoutineSettingsKey.question] as? String ?? "",
                                        minValue: unset ? "" : String(min ?? 0),
                                        maxValue: unset ? "" : String(max ?? 0))
        }
        let images = (entry[RoutineSettingsKey.imageUrls] as? [NSDictionary] ?? []).compactMap { $0[RoutineSettingsKey.imageUrl] as? String }
        return HabitEditValues(
            icon: entry[RoutineSettingsKey.icon] as? String ?? "",
            name: entry[RoutineSettingsKey.name] as? String ?? "",
            usesTimer: completion == nil,
            durationSeconds: max(HabitEditValues.minDurationSeconds, min(HabitEditValues.maxDurationSeconds, durationSeconds)),
            completionRequirement: completion ?? "",
            isHighPriority: (entry[RoutineSettingsKey.priority] as? String ?? RoutineSettingsKey.priorityHigh) == RoutineSettingsKey.priorityHigh,
            daysOfWeek: Set((entry[RoutineSettingsKey.daysOfWeek] as? [String] ?? HabitEditValues.weekdayCodes).map { $0.uppercased() }),
            cutoffEnabled: !(cutoff ?? "").isEmpty,
            cutoffMinutes: cutoff.map { Self.minutes(fromTimeString: $0) } ?? Self.defaultCutoffMinutes(),
            videoUrls: entry[RoutineSettingsKey.videoUrls] as? [String] ?? [],
            allowedApps: entry[RoutineSettingsKey.allowedApps] as? [String] ?? [],
            allowedUrls: entry[RoutineSettingsKey.allowedUrls] as? [String] ?? [],
            runMicroBreaks: entry[RoutineSettingsKey.runMicroBreaks] as? Bool ?? false,
            allowedFocusModeId: entry[RoutineSettingsKey.allowedFocusModeId] as? String ?? "",
            showSavedDistractingWebsites: entry[RoutineSettingsKey.showSavedDistractingWebsites] as? Bool ?? false,
            logQuantity: entry[RoutineSettingsKey.logQuantity] as? Bool ?? false,
            logQuestions: questions,
            logSummaryType: entry[RoutineSettingsKey.logSummaryType] as? String ?? RoutineSettingsKey.logSummarySum,
            takeNotes: entry[RoutineSettingsKey.takeNotes] as? String ?? HabitEditValues.noNote,
            checklist: entry[RoutineSettingsKey.checkList] as? [String] ?? [],
            textInstructions: entry[RoutineSettingsKey.textInstructions] as? String ?? "",
            imageUrls: images,
            tags: entry[RoutineSettingsKey.tags] as? [String] ?? [],
            randomChoiceCount: (entry[RoutineSettingsKey.choices] as? [Any])?.count ?? 0)
    }

    /// The routine's start time as minutes since midnight, from the draft/saved settings.
    func routineStartMinutes(_ section: RoutineSettingsSection) -> Int? {
        guard let root = workingSettings() else { return nil }
        switch section {
        case .morning:
            return (root[RoutineSettingsKey.startupTime] as? String).map { Self.minutes(fromTimeString: $0) }
        case .evening:
            return (root[RoutineSettingsKey.shutdownTime] as? String).map { Self.minutes(fromTimeString: $0) }
        case .custom(let sequenceId):
            return (customRoutineEntry(sequenceId: sequenceId, in: root)?[RoutineSettingsKey.routineStartTime] as? String)
                .map { Self.minutes(fromTimeString: $0) }
        }
    }

    /// Global evening cutoff, distinct from a must-do habit's individual late cutoff.
    func eveningCutoffMinutes() -> Int? {
        guard let text = workingSettings()?[RoutineSettingsKey.eveningCutoffTime] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return Self.minutes(fromTimeString: text)
    }

    /// Follow the global routine window across midnight; per-habit late cutoffs remain independent.
    static func isEveningCutoffValid(_ cutoff: Int?, eveningStart: Int, morningStart: Int?) -> Bool {
        guard (0..<1440).contains(eveningStart) else { return false }
        guard let cutoff = cutoff else { return true }
        guard (0..<1440).contains(cutoff) else { return false }
        guard let morning = morningStart, (0..<1440).contains(morning) else { return true }
        let routineWindow = (morning - eveningStart + 1440) % 1440
        let untilCutoff = (cutoff - eveningStart + 1440) % 1440
        return routineWindow > 0 && untilCutoff <= routineWindow
    }

    /// The routine's display name for the "When do you want … to start?" prompt.
    func routineDisplayName(_ section: RoutineSettingsSection) -> String {
        switch section {
        case .morning: return ScheduleText.routineNameMorning
        case .evening: return ScheduleText.routineNameEvening
        case .custom(let sequenceId):
            return arrAllCustomRoutine.first { $0.sequenceId == sequenceId }?.title ?? ScheduleText.routineNameCustom
        }
    }

    // MARK: Editing

    /// Writes the form back to the habit's JSON entry and to every live `habit` copy of it. Returns false
    /// if the habit can't be found in the settings (nothing changed).
    @discardableResult
    func applyHabitEdit(id: String, values: HabitEditValues) -> Bool {
        guard let root = workingSettings(), let (section, entry) = locateHabit(id: id, in: root) else { return false }
        writeHabitEntry(entry, values: values, section: section)
        settings = root
        updateLiveHabits(id: id, values: values, section: section)
        return true
    }

    /// Appends a new habit to the routine's list, the way the web's `newHabit` reducer does: a fresh UUID,
    /// the routine's `activity_sequence_id` (a sibling's, else the routine's own, else a new one), the
    /// routine's `activity_type`, then the form written through the same field mapping as an edit. Returns
    /// the new id, or nil when the routine isn't in the settings (nothing changed).
    @discardableResult
    func applyHabitAdd(routine section: RoutineSettingsSection, values: HabitEditValues) -> String? {
        guard let root = workingSettings(), let list = habitList(for: section, in: root, createIfMissing: true) else { return nil }
        let siblings = list.compactMap { $0 as? NSDictionary }
        let id = UUID().uuidString.lowercased()
        let entry = NSMutableDictionary()
        entry[RoutineSettingsKey.id] = id
        entry[RoutineSettingsKey.activitySequenceId] = siblings.first?[RoutineSettingsKey.activitySequenceId] as? String
            ?? Self.routineSequenceId(section) ?? UUID().uuidString.lowercased()
        entry[RoutineSettingsKey.activityType] = Self.activityType(for: section)
        // The web's INIT_NEW_HABIT sets priority on every routine's habits; writeHabitEntry only maintains it
        // where the editor shows it (evening/custom), so a morning habit gets the web's default here.
        entry[RoutineSettingsKey.priority] = RoutineSettingsKey.priorityHigh
        // A custom routine's habits must carry a subset of the routine's days (the editor doesn't write days
        // for them): inherit a sibling's, else the routine's, else every day like the web.
        if case .custom(let sequenceId) = section {
            entry[RoutineSettingsKey.daysOfWeek] = siblings.first?[RoutineSettingsKey.daysOfWeek] as? [String]
                ?? customRoutineEntry(sequenceId: sequenceId, in: root)?[RoutineSettingsKey.routineDaysOfWeek] as? [String]
                ?? HabitEditValues.weekdayCodes
        }
        writeHabitEntry(entry, values: values, section: section)
        list.add(entry)
        settings = root
        addLiveHabit(id: id, values: values, section: section)
        return id
    }

    /// Removes the habit from its routine's list. Mirrors the web's `removeHabit`, which is a plain
    /// splice: a habit's position is just its array index and no other key references it, so nothing
    /// else needs renumbering. Returns false if the habit isn't in the settings (nothing changed).
    @discardableResult
    func applyHabitDelete(id: String) -> Bool {
        guard let root = workingSettings(), let (list, index) = locateHabitList(id: id, in: root) else { return false }
        list.removeObject(at: index)
        settings = root
        removeLiveHabit(id: id)
        return true
    }

    /// Atomically stages the routine start and (for evening only) global cutoff in the existing
    /// save/restart draft. Invalid input changes neither the draft nor live timing globals.
    @discardableResult
    func applyRoutineTiming(_ section: RoutineSettingsSection, minutes: Int, eveningCutoffMinutes: Int? = nil) -> Bool {
        guard !isSaving, (0..<1440).contains(minutes), let root = workingSettings() else { return false }
        if section == .evening {
            let morning = (root[RoutineSettingsKey.startupTime] as? String).map { Self.minutes(fromTimeString: $0) }
            guard Self.isEveningCutoffValid(eveningCutoffMinutes, eveningStart: minutes, morningStart: morning) else { return false }
        }
        let timeString = Self.timeString(fromMinutes: minutes)
        switch section {
        case .morning:
            root[RoutineSettingsKey.startupTime] = timeString
            startTimeString = timeString
            startTime = getTimeFromString(val: timeString)
        case .evening:
            root[RoutineSettingsKey.shutdownTime] = timeString
            shutOffTimeString = timeString
            shutOffTime = getTimeFromString(val: timeString)
            if let cutoff = eveningCutoffMinutes {
                let cutoffString = Self.timeString(fromMinutes: cutoff)
                root[RoutineSettingsKey.eveningCutoffTime] = cutoffString
                cutOffTimeString = cutoffString
                cutOffTime = getTimeFromString(val: cutoffString)
            } else {
                root.removeObject(forKey: RoutineSettingsKey.eveningCutoffTime)
                cutOffTimeString = ""
                cutOffTime = nil
            }
        case .custom(let sequenceId):
            guard let entry = customRoutineEntry(sequenceId: sequenceId, in: root) else { return false }
            // The API rejects end_time <= start_time, so moving the start past the end drags the end
            // along, keeping the routine's length (capped at the end of the day).
            let oldStart = (entry[RoutineSettingsKey.routineStartTime] as? String).map { Self.minutes(fromTimeString: $0) } ?? minutes
            let oldEnd = (entry[RoutineSettingsKey.routineEndTime] as? String).map { Self.minutes(fromTimeString: $0) }
            entry[RoutineSettingsKey.routineStartTime] = timeString
            var newEnd: Int? = nil
            if let end = oldEnd, end <= minutes {
                newEnd = min(Self.lastMinuteOfDay, minutes + max(end - oldStart, 1))
                entry[RoutineSettingsKey.routineEndTime] = Self.timeString(fromMinutes: newEnd!)
            }
            for i in arrAllCustomRoutine.indices where arrAllCustomRoutine[i].sequenceId == sequenceId {
                arrAllCustomRoutine[i].startTime = getTimeFromString(val: timeString)
                if let end = newEnd { arrAllCustomRoutine[i].endTime = getTimeFromString(val: Self.timeString(fromMinutes: end)) }
            }
        }
        settings = root
        requestDayPlanRefresh()   // the time globals have no didSet, unlike the habit arrays
        NotificationCenter.default.post(name: LocalForecastPreferences.didChange, object: nil)
        return true
    }

    // MARK: Custom routines

    /// Every custom routine in the draft (or, with no draft yet, the saved settings), in settings order.
    func customRoutineSummaries() -> [CustomRoutineSummary] {
        guard let root = workingSettings() else { return [] }
        return customRoutineEntries(root).compactMap { entry in
            guard let sequenceId = entry[RoutineSettingsKey.activitySequenceId] as? String else { return nil }
            return CustomRoutineSummary(id: sequenceId,
                                        values: Self.routineValues(entry),
                                        habits: Self.habitSummaries(entry))
        }
    }

    func customRoutineValues(sequenceId: String) -> CustomRoutineEditValues? {
        guard let root = workingSettings(), let entry = customRoutineEntry(sequenceId: sequenceId, in: root) else { return nil }
        return Self.routineValues(entry)
    }

    private static func routineValues(_ entry: NSDictionary) -> CustomRoutineEditValues {
        let start = (entry[RoutineSettingsKey.routineStartTime] as? String).map { minutes(fromTimeString: $0) } ?? 0
        let end = (entry[RoutineSettingsKey.routineEndTime] as? String).map { minutes(fromTimeString: $0) }
        let days = (entry[RoutineSettingsKey.routineDaysOfWeek] as? [String]) ?? HabitEditValues.weekdayCodes
        return CustomRoutineEditValues(
            name: entry[RoutineSettingsKey.routineName] as? String ?? "",
            triggerOnDemand: (entry[RoutineSettingsKey.routineTrigger] as? String)?.uppercased() == RoutineSettingsKey.triggerOnDemand,
            daysOfWeek: Set(days.map { $0.uppercased() }),
            startMinutes: start,
            endMinutes: end ?? min(lastMinuteOfDay, start + CustomRoutineEditValues.defaultLengthMinutes))
    }

    private static func habitSummaries(_ entry: NSDictionary) -> [CustomRoutineHabitSummary] {
        (entry[RoutineSettingsKey.standaloneActivities] as? [NSDictionary] ?? []).compactMap { habit in
            guard let id = habit[RoutineSettingsKey.id] as? String else { return nil }
            let icon = (habit[RoutineSettingsKey.icon] as? String ?? "").trimmingCharacters(in: .whitespaces)
            let name = habit[RoutineSettingsKey.name] as? String ?? ""
            let completion = habit[RoutineSettingsKey.completionRequirements] as? String
            let label = (completion?.isEmpty == false)
                ? ScheduleText.customRoutineHabitUntilDone
                : HabitDurationText.short(seconds: habit[RoutineSettingsKey.durationSeconds] as? Int ?? 0)
            return CustomRoutineHabitSummary(id: id, name: icon.isEmpty ? name : "\(icon) \(name)", durationLabel: label)
        }
    }

    /// Appends a custom routine the way the web's `INIT_CUSTOM_ROUTINE` builds one: its own `id` AND
    /// `activity_sequence_id` (both fresh UUIDs), a `trigger`, days, a start/end window and an empty
    /// `standalone_activities` list. Returns the new routine's `activity_sequence_id`.
    @discardableResult
    func applyCustomRoutineAdd(values: CustomRoutineEditValues) -> String? {
        guard let root = workingSettings(), let list = customRoutineList(in: root, createIfMissing: true) else { return nil }
        let sequenceId = UUID().uuidString.lowercased()
        let entry = NSMutableDictionary()
        entry[RoutineSettingsKey.id] = UUID().uuidString.lowercased()
        entry[RoutineSettingsKey.activitySequenceId] = sequenceId
        entry[RoutineSettingsKey.standaloneActivities] = NSMutableArray()
        Self.writeRoutineEntry(entry, values: values)
        list.add(entry)
        settings = root
        arrAllCustomRoutine.append(Self.liveRoutine(sequenceId: sequenceId, values: values))
        return sequenceId
    }

    /// Writes the routine-level form back to the routine's JSON entry and its runtime copy.
    @discardableResult
    func applyCustomRoutineEdit(sequenceId: String, values: CustomRoutineEditValues) -> Bool {
        guard let root = workingSettings(), let entry = customRoutineEntry(sequenceId: sequenceId, in: root) else { return false }
        Self.writeRoutineEntry(entry, values: values)
        // A custom routine's habits must carry a subset of the routine's days (the API's rule), so
        // narrowing the routine's days narrows theirs too.
        let days = values.orderedDays
        for habit in (entry[RoutineSettingsKey.standaloneActivities] as? [NSMutableDictionary] ?? []) {
            let existing = (habit[RoutineSettingsKey.daysOfWeek] as? [String] ?? days).map { $0.uppercased() }
            let narrowed = days.filter { existing.contains($0) }
            habit[RoutineSettingsKey.daysOfWeek] = narrowed.isEmpty ? days : narrowed
        }
        settings = root
        for i in arrAllCustomRoutine.indices where arrAllCustomRoutine[i].sequenceId == sequenceId {
            arrAllCustomRoutine[i].title = values.trimmedName
            arrAllCustomRoutine[i].triggerOnDemand = values.triggerOnDemand
            arrAllCustomRoutine[i].days_of_week = days
            arrAllCustomRoutine[i].startTime = getTimeFromString(val: Self.timeString(fromMinutes: values.startMinutes))
            arrAllCustomRoutine[i].endTime = getTimeFromString(val: Self.timeString(fromMinutes: values.endMinutes))
        }
        requestDayPlanRefresh()   // title/trigger changes don't go through a habit array's didSet
        return true
    }

    /// Removes the routine and every habit in it (the web's `updateCustomRoutines` splice).
    @discardableResult
    func applyCustomRoutineDelete(sequenceId: String) -> Bool {
        guard let root = workingSettings(), let list = customRoutineList(in: root, createIfMissing: false) else { return false }
        guard let index = list.enumerated().first(where: {
            ($0.element as? NSDictionary)?[RoutineSettingsKey.activitySequenceId] as? String == sequenceId
        })?.offset else { return false }
        list.removeObject(at: index)
        settings = root
        arrAllCustomRoutine.removeAll { $0.sequenceId == sequenceId }
        return true
    }

    /// Moves a habit within its routine's list — the settings array's order IS the routine's running
    /// order, so a move is a plain remove-and-insert in both the JSON and the runtime arrays.
    @discardableResult
    func applyHabitMove(in section: RoutineSettingsSection, from: Int, to: Int) -> Bool {
        guard let root = workingSettings(), let list = habitList(for: section, in: root, createIfMissing: false),
              from != to, (0..<list.count).contains(from), (0..<list.count).contains(to) else { return false }
        let entry = list.object(at: from)
        list.removeObject(at: from)
        list.insert(entry, at: to)
        settings = root
        moveLiveHabit(in: section, from: from, to: to)
        return true
    }

    private func moveLiveHabit(in section: RoutineSettingsSection, from: Int, to: Int) {
        func move(_ habits: inout [habit]) {
            guard habits.indices.contains(from), habits.indices.contains(to) else { return }
            habits.insert(habits.remove(at: from), at: to)
        }
        switch section {
        case .morning:
            move(&arrAllDaysMorningHabits); move(&arrPreFilteredMorningHabits); move(&arrFilteredMorningHabits)
        case .evening:
            move(&arrAllDaysEveningHabits); move(&arrPreFilteredEveningHabits); move(&arrFilteredEveningHabits)
        case .custom(let sequenceId):
            for i in arrAllCustomRoutine.indices where arrAllCustomRoutine[i].sequenceId == sequenceId {
                move(&arrAllCustomRoutine[i].arrAllHabits)
                move(&arrAllCustomRoutine[i].arrAllPreFilterHabits)
                move(&arrAllCustomRoutine[i].arrAllFilteredHabits)
            }
        }
    }

    private static func writeRoutineEntry(_ entry: NSMutableDictionary, values: CustomRoutineEditValues) {
        entry[RoutineSettingsKey.routineName] = values.trimmedName
        entry[RoutineSettingsKey.routineTrigger] = values.triggerOnDemand ? RoutineSettingsKey.triggerOnDemand
                                                                         : RoutineSettingsKey.triggerOnSchedule
        entry[RoutineSettingsKey.routineDaysOfWeek] = values.orderedDays
        entry[RoutineSettingsKey.routineStartTime] = timeString(fromMinutes: values.startMinutes)
        // The API rejects `end_time <= start_time`, so an on-demand routine (whose window is bookkeeping
        // only, and which the editor doesn't ask about) still gets a valid one.
        let end = values.endMinutes > values.startMinutes
            ? values.endMinutes
            : min(lastMinuteOfDay, values.startMinutes + CustomRoutineEditValues.defaultLengthMinutes)
        entry[RoutineSettingsKey.routineEndTime] = timeString(fromMinutes: end)
    }

    private static func liveRoutine(sequenceId: String, values: CustomRoutineEditValues) -> routine {
        routine(title: values.trimmedName,
                sequenceId: sequenceId,
                startTime: getTimeFromString(val: timeString(fromMinutes: values.startMinutes)),
                endTime: getTimeFromString(val: timeString(fromMinutes: values.endMinutes)),
                triggerOnDemand: values.triggerOnDemand,
                days_of_week: values.orderedDays)
    }

    // MARK: Saving

    /// PUTs the draft through the same endpoint the Edit Habits webview uses, caches the server's
    /// canonical copy, then restarts the app so every subsystem re-reads it. On failure the draft is kept
    /// and `onFailure` gets the HTTP status (0 = no response) plus the server's validation message, if any.
    func saveAndRestart(onFailure: @escaping (_ statusCode: Int, _ serverMessage: String?) -> Void) {
        guard let draft = settings, !isSaving else { return }
        isSaving = true
        allApiObject.putUserSettings(settings: draft, isOnboarding: false) { [weak self] saved, statusCode, serverMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false
                guard statusCode == 200, let saved = saved,
                      let data = try? JSONSerialization.data(withJSONObject: saved, options: .prettyPrinted),
                      let json = String(data: data, encoding: .utf8) else {
                    addLog(text: "DayPlanRoutineDraft: save failed with status \(statusCode): \(serverMessage ?? "")")
                    onFailure(statusCode, serverMessage)
                    return
                }
                SensitiveDefaults.set(json, forKey: kUserdefaultsSelectedJson)
                self.settings = nil
                DayPlanAnalytics.capture(DayPlanAnalytics.routineDraftSaved)
                appdelegate?.quitAndRestartApp(coverWithSplash: true)
            }
        }
    }

    // MARK: - JSON helpers

    /// The draft if there is one, else a deeply-mutable parse of the saved settings blob.
    private func workingSettings() -> NSMutableDictionary? {
        if let draft = settings { return draft }
        guard let json = savedSettingsJSON(),
              let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data, options: [.mutableContainers]) as? NSMutableDictionary
        else { return nil }
        return root
    }

    private func findHabit(id: String, in list: Any?) -> NSMutableDictionary? {
        (list as? [NSMutableDictionary])?.first { $0[RoutineSettingsKey.id] as? String == id }
    }

    /// Every habit list of the settings JSON, as the mutable arrays JSONSerialization parsed (so a
    /// removal lands in the draft itself, not in a bridged copy).
    private func habitLists(in root: NSMutableDictionary) -> [NSMutableArray] {
        let routineLists = [root[RoutineSettingsKey.morningActivities], root[RoutineSettingsKey.eveningActivities]]
        let customLists = customRoutineEntries(root).map { $0[RoutineSettingsKey.standaloneActivities] }
        return (routineLists + customLists).compactMap { $0 as? NSMutableArray }
    }

    private func locateHabitList(id: String, in root: NSMutableDictionary) -> (list: NSMutableArray, index: Int)? {
        for list in habitLists(in: root) {
            for (index, entry) in list.enumerated() where (entry as? NSDictionary)?[RoutineSettingsKey.id] as? String == id {
                return (list, index)
            }
        }
        return nil
    }

    /// The routine's habit list, as the mutable array JSONSerialization parsed (an add must land in the
    /// draft itself). A routine whose list key is missing gets an empty one when `createIfMissing`.
    private func habitList(for section: RoutineSettingsSection, in root: NSMutableDictionary, createIfMissing: Bool) -> NSMutableArray? {
        let owner: NSMutableDictionary
        let key: String
        switch section {
        case .morning: (owner, key) = (root, RoutineSettingsKey.morningActivities)
        case .evening: (owner, key) = (root, RoutineSettingsKey.eveningActivities)
        case .custom(let sequenceId):
            guard let routine = customRoutineEntry(sequenceId: sequenceId, in: root) else { return nil }
            (owner, key) = (routine, RoutineSettingsKey.standaloneActivities)
        }
        if let list = owner[key] as? NSMutableArray { return list }
        guard createIfMissing else { return nil }
        let list = NSMutableArray()
        owner[key] = list
        return list
    }

    /// The `activity_sequence_id` the section itself carries — only a custom routine has one; the morning
    /// and evening lists are keyed by their habits' shared sequence id.
    private static func routineSequenceId(_ section: RoutineSettingsSection) -> String? {
        if case .custom(let sequenceId) = section { return sequenceId }
        return nil
    }

    private static func activityType(for section: RoutineSettingsSection) -> String {
        switch section {
        case .morning: return RoutineSettingsKey.activityTypeMorning
        case .evening: return RoutineSettingsKey.activityTypeEvening
        case .custom: return RoutineSettingsKey.activityTypeStandalone
        }
    }

    private func customRoutineEntries(_ root: NSMutableDictionary) -> [NSMutableDictionary] {
        root[RoutineSettingsKey.customRoutines] as? [NSMutableDictionary] ?? []
    }

    /// The `custom_routines` array as the mutable one JSONSerialization parsed, so an add/remove lands
    /// in the draft itself rather than in a bridged copy.
    private func customRoutineList(in root: NSMutableDictionary, createIfMissing: Bool) -> NSMutableArray? {
        if let list = root[RoutineSettingsKey.customRoutines] as? NSMutableArray { return list }
        guard createIfMissing else { return nil }
        let list = NSMutableArray()
        root[RoutineSettingsKey.customRoutines] = list
        return list
    }

    private func customRoutineEntry(sequenceId: String, in root: NSMutableDictionary) -> NSMutableDictionary? {
        customRoutineEntries(root).first { $0[RoutineSettingsKey.activitySequenceId] as? String == sequenceId }
    }

    private func writeHabitEntry(_ entry: NSMutableDictionary, values: HabitEditValues, section: RoutineSettingsSection) {
        let cleaned = HabitEditValues.cleaned
        entry[RoutineSettingsKey.icon] = values.icon.trimmingCharacters(in: .whitespaces)
        entry[RoutineSettingsKey.name] = values.trimmedName
        if values.usesTimer {
            entry[RoutineSettingsKey.durationSeconds] = values.durationSeconds
            entry.removeObject(forKey: RoutineSettingsKey.completionRequirements)   // web: undefined ⇒ timer habit
        } else {
            entry[RoutineSettingsKey.completionRequirements] = values.completionRequirement.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Keys the API validates as "absent or typed" (UUID, military time, enum, non-empty array
        // element) are REMOVED rather than written empty — `allowed_focus_mode_id: ""` is a 400
        // ("must be a UUID"), and the web only ever writes these when set.
        // Priority + late cutoff are evening/custom-routine options on the web; morning habits keep theirs
        // (the API rejects a cutoff on a morning habit, so that key is only touched for evening habits).
        if section != .morning {
            entry[RoutineSettingsKey.priority] = values.isHighPriority ? RoutineSettingsKey.priorityHigh : RoutineSettingsKey.priorityStandard
        }
        if section == .evening {
            if values.isHighPriority && values.cutoffEnabled {
                entry[RoutineSettingsKey.cutoffTime] = Self.timeString(fromMinutes: values.cutoffMinutes)
            } else {
                entry.removeObject(forKey: RoutineSettingsKey.cutoffTime)
            }
        }
        // A custom routine's habits inherit the routine's days (the API requires a subset of them), so
        // the editor doesn't show or write days for them.
        if case .custom = section {} else {
            entry[RoutineSettingsKey.daysOfWeek] = values.orderedDays
        }
        entry[RoutineSettingsKey.videoUrls] = cleaned(values.videoUrls)
        let apps = values.usesFocusMode ? [] : cleaned(values.allowedApps)
        let urls = values.usesFocusMode ? [] : cleaned(values.allowedUrls).map(Self.stripScheme)
        entry[RoutineSettingsKey.allowedApps] = apps
        entry[RoutineSettingsKey.allowedUrls] = urls
        entry[RoutineSettingsKey.runMicroBreaks] = values.runMicroBreaks && !(apps.isEmpty && urls.isEmpty)
        if values.usesFocusMode {
            entry[RoutineSettingsKey.allowedFocusModeId] = values.allowedFocusModeId
        } else {
            entry.removeObject(forKey: RoutineSettingsKey.allowedFocusModeId)
        }
        entry[RoutineSettingsKey.showSavedDistractingWebsites] = values.showSavedDistractingWebsites
        // A habit with random choices logs per choice; the API rejects log_quantity / a non-SUM
        // log_summary_type on the parent, so its log keys are left exactly as they were.
        if values.randomChoiceCount == 0 { writeLogQuestions(entry, values: values) }
        entry[RoutineSettingsKey.takeNotes] = values.takeNotes
        writeChecklist(entry, items: cleaned(values.checklist))
        entry[RoutineSettingsKey.textInstructions] = values.textInstructions
        writeImages(entry, urls: cleaned(values.imageUrls))
        let tags = cleaned(values.tags)
        if !tags.isEmpty || entry[RoutineSettingsKey.tags] != nil { entry[RoutineSettingsKey.tags] = tags }
    }

    private func writeLogQuestions(_ entry: NSMutableDictionary, values: HabitEditValues) {
        let existing = entry[RoutineSettingsKey.logQuantityQuestions] as? [NSMutableDictionary] ?? []
        let questions: [NSMutableDictionary] = values.logQuantity ? values.logQuestions.map { q in
            // Merge onto the stored question so keys this editor doesn't show (descriptions, links) survive.
            let dict = existing.first { $0[RoutineSettingsKey.questionId] as? String == q.id } ?? NSMutableDictionary()
            dict[RoutineSettingsKey.questionId] = q.id
            dict[RoutineSettingsKey.question] = q.question.trimmingCharacters(in: .whitespacesAndNewlines)
            dict[RoutineSettingsKey.minValue] = Int(q.minValue.trimmingCharacters(in: .whitespaces)) ?? 0
            dict[RoutineSettingsKey.maxValue] = Int(q.maxValue.trimmingCharacters(in: .whitespaces)) ?? 0
            dict[RoutineSettingsKey.logSummaryType] = values.logSummaryType
            return dict
        } : []
        entry[RoutineSettingsKey.logQuantity] = values.logQuantity && !questions.isEmpty
        entry[RoutineSettingsKey.logQuantityQuestions] = questions
        entry[RoutineSettingsKey.logSummaryType] = values.logSummaryType
    }

    private func writeChecklist(_ entry: NSMutableDictionary, items: [String]) {
        if !items.isEmpty {
            entry[RoutineSettingsKey.choiceType] = RoutineSettingsKey.choiceTypeCheckList
            entry[RoutineSettingsKey.checkList] = items
        } else {
            entry.removeObject(forKey: RoutineSettingsKey.checkList)
            if entry[RoutineSettingsKey.choiceType] as? String == RoutineSettingsKey.choiceTypeCheckList {
                entry.removeObject(forKey: RoutineSettingsKey.choiceType)
            }
        }
    }

    private func writeImages(_ entry: NSMutableDictionary, urls: [String]) {
        let existing = entry[RoutineSettingsKey.imageUrls] as? [NSMutableDictionary] ?? []
        entry[RoutineSettingsKey.imageUrls] = urls.map { url -> NSMutableDictionary in
            existing.first { $0[RoutineSettingsKey.imageUrl] as? String == url }
                ?? NSMutableDictionary(dictionary: [RoutineSettingsKey.imageUrl: url])
        }
    }

    // MARK: - Live state

    /// Mirrors `writeHabitEntry` onto a runtime `habit` struct the way AppDelegate.readSettingsJsonDictionary
    /// derives it (icon-prefixed name, the 86400s non-timer sentinel, log_quantity needs questions, …).
    private static func applyValues(_ values: HabitEditValues, section: RoutineSettingsSection, to h: inout habit) {
        let cleaned = HabitEditValues.cleaned
        let apps = values.usesFocusMode ? [] : cleaned(values.allowedApps)
        let urls = values.usesFocusMode ? [] : cleaned(values.allowedUrls).map(stripScheme)
        let questions = values.logQuantity ? values.logQuestions.map { q in
            quantityQuestion(id: q.id,
                             minValue: Int(q.minValue.trimmingCharacters(in: .whitespaces)) ?? 0,
                             maxValue: Int(q.maxValue.trimmingCharacters(in: .whitespaces)) ?? 0,
                             question: q.question.trimmingCharacters(in: .whitespacesAndNewlines),
                             logQuantityType: values.logSummaryType,
                             minValueDescription: "", maxValueDescription: "")
        } : []
        let icon = values.icon.trimmingCharacters(in: .whitespaces)
        let name = values.trimmedName

        h.habitIcon = icon
        h.nameWithoutIcon = name
        h.name = icon.isEmpty ? name : "\(icon) \(name)"
        h.useTimer = values.usesTimer
        h.durationSeconds = values.usesTimer ? values.durationSeconds : nonTimerDurationSentinel
        h.completion_requirements = values.usesTimer ? "" : values.completionRequirement.trimmingCharacters(in: .whitespacesAndNewlines)
        if section != .morning { h.isPriorityHigh = values.isHighPriority }
        if section == .evening {
            h.cutOffTime = (values.isHighPriority && values.cutoffEnabled)
                ? getTimeFromString(val: timeString(fromMinutes: values.cutoffMinutes)) : nil
        }
        if case .custom = section {} else { h.days_of_week = values.orderedDays }
        h.urlsArray = cleaned(values.videoUrls)
        h.allowApps = apps
        h.allowUrls = urls
        h.openSpecificApps = !apps.isEmpty
        h.run_micro_breaks = values.runMicroBreaks && !(apps.isEmpty && urls.isEmpty)
        h.allowedFocusMode = values.allowedFocusModeId
        h.showSavedDistractingWebsites = values.showSavedDistractingWebsites
        if values.randomChoiceCount == 0 {
            h.logQuantityQuestions = questions
            h.logQuantity = !questions.isEmpty
        }
        h.take_notes = values.takeNotes
        h.checkList = cleaned(values.checklist)
        h.text_instructions = values.textInstructions
        h.imgUrls = cleaned(values.imageUrls)
    }

    private func updateLiveHabits(id: String, values: HabitEditValues, section: RoutineSettingsSection) {
        func replace(in habits: inout [habit]) {
            for i in habits.indices where habits[i].id == id { Self.applyValues(values, section: section, to: &habits[i]) }
        }
        replace(in: &arrAllDaysMorningHabits)
        replace(in: &arrPreFilteredMorningHabits)
        replace(in: &arrFilteredMorningHabits)
        replace(in: &arrAllDaysEveningHabits)
        replace(in: &arrPreFilteredEveningHabits)
        replace(in: &arrFilteredEveningHabits)
        for i in arrAllCustomRoutine.indices {
            replace(in: &arrAllCustomRoutine[i].arrAllHabits)
            replace(in: &arrAllCustomRoutine[i].arrAllPreFilterHabits)
            replace(in: &arrAllCustomRoutine[i].arrAllFilteredHabits)
        }
    }

    /// AppDelegate.readSettingsJsonDictionary gives a non-timer habit a day-long duration.
    static let nonTimerDurationSentinel = 86400

    /// Appends the new habit to the routine's runtime arrays (their didSet re-renders the Day Plan). It goes
    /// on the end, so the routine player's index into the filtered list is untouched; the filtered list only
    /// gets it when it's scheduled today, the same test AppDelegate applies when a routine starts.
    private func addLiveHabit(id: String, values: HabitEditValues, section: RoutineSettingsSection) {
        var new = habit(id: id, name: "", durationSeconds: values.durationSeconds, urlsArray: [], logQuantity: false,
                        logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "",
                        activity_sequence_id: Self.routineSequenceId(section) ?? "", run_micro_breaks: false,
                        take_notes: values.takeNotes, isPriorityHigh: values.isHighPriority, days_of_week: values.orderedDays,
                        text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: values.usesTimer,
                        checkList: [], tutorial: "")
        Self.applyValues(values, section: section, to: &new)
        let isScheduledToday = isScheduledForWeekday(new.days_of_week, currentWeekDay: Date().dayOfWeek())
        switch section {
        case .morning:
            new.fakeIdForDevice = "\(arrAllDaysMorningHabits.count + 1)"
            arrAllDaysMorningHabits.append(new)
            arrPreFilteredMorningHabits.append(new)
            if isScheduledToday { arrFilteredMorningHabits.append(new) }
        case .evening:
            new.fakeIdForDevice = "\(arrAllDaysEveningHabits.count + 1)"
            arrAllDaysEveningHabits.append(new)
            arrPreFilteredEveningHabits.append(new)
            if isScheduledToday { arrFilteredEveningHabits.append(new) }
        case .custom(let sequenceId):
            for i in arrAllCustomRoutine.indices where arrAllCustomRoutine[i].sequenceId == sequenceId {
                arrAllCustomRoutine[i].arrAllHabits.append(new)
                arrAllCustomRoutine[i].arrAllPreFilterHabits.append(new)
                arrAllCustomRoutine[i].arrAllFilteredHabits.append(new)
            }
        }
    }

    /// Drops the habit from every runtime array (the arrays' didSet re-renders the Day Plan). The
    /// routine player indexes into the FILTERED list of the running routine, so removing a habit ahead
    /// of the one playing shifts that index down to keep it on the same habit. (The editor never offers
    /// deleting the habit that's playing itself.)
    private func removeLiveHabit(id: String) {
        func remove(from habits: inout [habit], drivesPlayer: Bool) {
            guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
            if drivesPlayer, let playingId = currentHabitPlaying?.id,
               let playingIndex = habits.firstIndex(where: { $0.id == playingId }), index < playingIndex, currentHabitIndex > 0 {
                currentHabitIndex -= 1
            }
            habits.remove(at: index)
        }
        remove(from: &arrAllDaysMorningHabits, drivesPlayer: false)
        remove(from: &arrPreFilteredMorningHabits, drivesPlayer: false)
        remove(from: &arrFilteredMorningHabits, drivesPlayer: true)
        remove(from: &arrAllDaysEveningHabits, drivesPlayer: false)
        remove(from: &arrPreFilteredEveningHabits, drivesPlayer: false)
        remove(from: &arrFilteredEveningHabits, drivesPlayer: true)
        for i in arrAllCustomRoutine.indices {
            remove(from: &arrAllCustomRoutine[i].arrAllHabits, drivesPlayer: false)
            remove(from: &arrAllCustomRoutine[i].arrAllPreFilterHabits, drivesPlayer: false)
            remove(from: &arrAllCustomRoutine[i].arrAllFilteredHabits, drivesPlayer: true)
        }
    }

    // MARK: - Time / URL formatting

    static func minutes(fromTimeString value: String) -> Int {
        let time = getTimeFromString(val: value)
        return time.hour * 60 + time.minute
    }

    static let lastMinuteOfDay = 23 * 60 + 59

    static func timeString(fromMinutes minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    /// Web default for a new late cutoff: 30 min after the global cutoff, else after shutdown, else 21:00.
    static func defaultCutoffMinutes() -> Int {
        let base = cutOffTime ?? shutOffTime
        guard let time = base else { return 21 * 60 }
        return (time.hour * 60 + time.minute + 30) % (24 * 60)
    }

    /// The web strips the scheme from allowed URLs before saving.
    static func stripScheme(_ url: String) -> String {
        url.replacingOccurrences(of: "^https?://", with: "", options: .regularExpression)
    }
}
