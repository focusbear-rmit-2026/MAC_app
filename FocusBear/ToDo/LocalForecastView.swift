import SwiftUI
import AppKit

/// All new copy is config-driven; bundled EN/ES files cover a stale or unavailable remote config.
enum ForecastText {
    enum Key: String, CaseIterable {
        case tab, introduction, horizon, days, meetings, habits, selfCare, work, available, unprojected
        case loadingProjects, loadingTasks, loadingCalendar, preparingDays, calculating, progressCount
        case capacitySettings, sleep, sleepStarts, sleepEnds, additionalSelfCare, settingsExplanation, settingsInvalid, saveSettings
        case remainingLikelihood, remainingLikelihoodInHorizon
        case meetingTimeOnce, dayPlan, projectWork, blockAbsorbed, likelihood, missingEstimate, noTasks, allWorkComplete, completeBy, completeAfter, outsideHorizon
        case calendarMissing, loadFailed, generatePlan, reviewPlan, reviewExplanation, applySelected, selectAll
        case conflictsHeading, conflictsExplanation, projectEndDate, projectEndDateNoProject
        case keepPlannedDays, plannedDaysLocked, dayPlanFollowsTheDates
        case dayFocusHeading, dayFocusRelief, dayFocusClears, dayFocusRemainder
        case dayFocusPinnedRemainder, dayFocusNothingToMove, postponementLimitNoDate
        // A project's rating reaches its own tasks, so the sheet has to say where a task's deadline
        // came from and what is left to decide for the ones the project fixes.
        case fixedByProjectHeading, fixedByProjectExplanation, inheritedFromProject
        case projectEndsOn, projectHasNoEndDate, moveEarlier, moveLater, reorderNotSaved
        case chooseProject, changeProject, projectNotChanged
        case completeTask, editDuration, noEstimate, durationNotSaved, taskNotCompleted
        case typeADate, reasonYouChoseIt, reasonBroughtForward, reasonPushedBack
        case projectDeadlineHeading, projectDeadlineExplanation, projectDeadlineRow
        case selectAllInProject, selectAllInGroup, noSlotBeforeProjectEnd, majorChanges, minorChanges
        case reprioritiseMenuItem, reprioritiseLink, reprioritiseOverdue, reprioritiseOverCapacity, reprioritiseDismiss
        case noChanges, noPermission, planChanged, planSaved, planPartiallySaved, hardDeadline, postponementLimit
        // No `outcome1`…`outcome5` here: the scale's wording is defined once, in `ToDoStrings`.
        // No `suggestion*` keys either: the field now defaults to the proposed day, so the
        // "use suggested date" button that owned them is gone.
        case currentOutcome, likelihoodInHorizon, outcomeNotSaved, outcomeUnavailable, outcomeMissing, outcome, notSet
        // Names the day's state rather than a negative quantity: "already over capacity" vs
        // "has only N left". The old dayShortfall pair could not say the former at all.
        case dayOverCapacity, dayNotEnoughRoom, noSlot, localOnly, overbooked, close, refresh, loading, pending, noDeadline, previous, proposed, plannedTotal, bufferTotal, notEnoughTimeForTasks
        case forecastTaskWork, unallocatedWorkTime, workTimeExplanation
    }
    private static let block = "localForecastViewInfo"
    static subscript(_ key: Key) -> String {
        if let value = (configjson[block] as? NSDictionary)?[key.rawValue] as? String, !value.isEmpty { return value }
        let language = BundledConfigLanguage.code()
        return bundled[language]?[key.rawValue] ?? bundled["en"]?[key.rawValue] ?? key.rawValue
    }
    private static let bundled: [String: [String: String]] = {
        var result: [String: [String: String]] = [:]
        for (language, file) in BundledConfigLanguage.all {
            guard let url = Bundle.main.url(forResource: file, withExtension: "json"), let data = try? Data(contentsOf: url),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let values = json[block] as? [String: String] else { continue }
            result[language] = values
        }
        return result
    }()
    static func format(_ key: Key, _ replacements: [String: String]) -> String {
        replacements.reduce(self[key]) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
    }
    /// A project's completion line when its work runs past the planning horizon: "Expected completion:
    /// after <the horizon's last day>" — a date the user can read, rather than "This work does not fit
    /// within the selected planning horizon", which named a setting instead of saying when (report
    /// 2026-09-23_10-46-27, follow-up). Falls back to that sentence only when no horizon was built.
    static func completionAfterHorizon(lastDay: Date?) -> String {
        guard let lastDay = lastDay else { return self[.outsideHorizon] }
        return format(.completeAfter, ["<DATE>": date(lastDay)])
    }
    static func date(_ date: Date?) -> String {
        guard let date = date else { return self[.noDeadline] }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: currentLanguageCode); formatter.dateStyle = .medium; formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    /// A buffer can be negative — the day is over its capacity — and `duration` clamps at zero, so
    /// the sign goes back on explicitly rather than through a second formatter.
    static func signedDuration(_ minutes: Double) -> String {
        (minutes < 0 ? "-" : "") + duration(abs(minutes))
    }
    static func duration(_ minutes: Double) -> String {
        let formatter = DateComponentsFormatter()
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: currentLanguageCode)
        formatter.calendar = calendar
        formatter.unitsStyle = .abbreviated; formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: max(0, minutes) * 60) ?? "0"
    }
    /// What the chosen day says about itself, in the shape the PO wrote themselves: "2nd Oct is
    /// already 36 minutes over cap" (report 2026-09-15_20-08-56). It names the day's STATE rather
    /// than asking the reader to interpret a negative quantity, and picks its words from that state —
    /// a day already past its capacity is a different fact from one that simply has too little left.
    /// Days read as `ToDoDates.weekdayDayMonth` ("Fri 2 Oct"), never a relative word, so the sentence
    /// reads the same for today and tomorrow as for any other day.
    static func dayAdvice(_ warning: LocalTimeForecast.DayCapacityWarning) -> String {
        format(warning.load.isOvercommitted ? .dayOverCapacity : .dayNotEnoughRoom,
               ["<DURATION>": duration(warning.amountMinutes),
                "<DATE>": ToDoDates.weekdayDayMonth(warning.day),
                "<SUGGESTED_DATE>": ToDoDates.weekdayDayMonth(warning.suggestedDay)])
    }

    /// The SAME words a task's outcome uses, from the one definition in `ToDoStrings` — the user
    /// asked for that (report 2026-09-11_20-00-34, follow-up "I want the labels we had for outcome
    /// same as task"). The first attempt at this unified both screens onto an *impact* scale
    /// ("Who cares" … "Mind blowing"), which was the wrong axis: outcome means deadline flexibility
    /// here, and `LocalTimeForecast.postponementDays` plans against those very bands
    /// (report 2026-09-15_20-12-49). Both read the same /10 wire value.
    static func outcomeLabel(_ wire: Int) -> String {
        ToDoStrings.load().outcomeLabel(wire)
    }
    static func outcomeValue(_ wire: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.maximumFractionDigits = 1
        return (formatter.string(from: NSNumber(value: min(5, max(1, Double(wire) / 2)))) ?? "1") + " / 5"
    }
    /// Why the plan would not pick a date, in words the user can check against their own data.
    ///
    /// "Completion would exceed the extension allowed by this outcome. Review the scope or priority."
    /// was the old `.postponementLimit` text, and it is close to unreadable: "outcome" and "extension"
    /// are this code's vocabulary, not the user's, and nothing in the sentence is checkable or
    /// actionable ("this list is very unhelpful", report 2026-09-16_22-22-50, follow-up).
    ///
    /// Both of the two common reasons now name **the date the work would actually land on**, which is
    /// the fact the refusal turns on, and the rating band or project deadline it breaches — in the
    /// same words the rating slider uses. The details each sentence needs are passed in rather than
    /// looked up here, because this enum has no store.
    static func conflict(_ reason: LocalTimeForecast.ConflictReason, earliest: Date? = nil,
                         outcome: Int? = nil, projectName: String? = nil, projectEnd: Date? = nil) -> String {
        switch reason {
        case .hardDeadline: return self[.hardDeadline]
        case .postponementLimit:
            guard let earliest = earliest else {
                return format(.postponementLimitNoDate, ["<BAND>": outcomeLabel(outcome ?? 0)])
            }
            return format(.postponementLimit, ["<DATE>": date(earliest), "<BAND>": outcomeLabel(outcome ?? 0)])
        case .outsideHorizon: return self[.outsideHorizon]
        case .missingEstimate: return self[.missingEstimate]
        case .missingOutcome: return self[.outcomeMissing]
        case .projectEndDate:
            guard let earliest = earliest, let name = projectName, let end = projectEnd else {
                return format(.projectEndDateNoProject, ["<DATE>": earliest.map { date($0) } ?? self[.noDeadline]])
            }
            return format(.projectEndDate, ["<DATE>": date(earliest), "<PROJECT>": name, "<ENDDATE>": date(end)])
        }
    }
}

/// The one outcome picker: the task editor, the project settings sheet, the project create sheet and
/// the project heading all present this, so the same number can never be described two ways.
struct ForecastOutcomePicker: View {
    @Binding var wireValue: Int?
    var body: some View {
        let rows = ToDoStrings.load()
        return VStack(alignment: .leading, spacing: 4) {
            Text(ForecastText[.outcome]).font(.localForecastMedium(12))
            Picker("", selection: $wireValue) {
                Text(ForecastText[.notSet]).tag(nil as Int?)
                ForEach(1...ToDoScoring.outcomeSteps, id: \.self) { step in
                    Text(rows.outcomeOptionLabel(displayValue: step)).tag(Optional(step * ToDoScoring.outcomeWireFactor))
                }
                // Legacy odd values are displayed exactly and retained until the user changes them.
                if let value = wireValue, value % ToDoScoring.outcomeWireFactor != 0 {
                    Text(ForecastText.format(.currentOutcome, ["<VALUE>": ForecastText.outcomeValue(value)]) + " · " + rows.outcomeLabel(value)).tag(Optional(value))
                }
            }
            .labelsHidden().pickerStyle(MenuPickerStyle()).font(.localForecastRegular(12))
        }
    }
}

/// The reschedule list's own outcome control: the same 1-5 scale, the same words out of
/// `ToDoStrings.outcomeLabel` and the same `/10` wire value as `ForecastOutcomePicker`. Only the
/// affordance differs, deliberately. A menu suits a form filled in once; this is a row-level control
/// the user sweeps down a long list, the app already rates perspiration with a slider in the task
/// editor, and the gesture the PO described is dragging to the far end and watching the row leave
/// (report 2026-09-15_21-00-07).
///
/// The write happens on release, never on the intermediate steps of a drag: every committed change
/// re-flows the list, and re-flowing mid-drag would move the row under the cursor.
struct ForecastOutcomeSlider: View {
    let wireValue: Int?
    var isDisabled = false
    let onCommit: (Int) -> Void

    @SwiftUI.State private var dragging: Double?

    private static let trackWidth: CGFloat = 150
    private static let labelFontSize: CGFloat = 11

    /// The `/5` position for a `/10` wire value, including the legacy odd ones, which round to the
    /// nearest step rather than silently reading as the one below.
    static func displayStep(forWire wire: Int?) -> Int {
        let effective = wire ?? LocalTimeForecast.TaskInput.unratedOutcome
        let step = Int((Double(effective) / Double(ToDoScoring.outcomeWireFactor)).rounded())
        return min(ToDoScoring.outcomeSteps, max(1, step))
    }

    private var step: Int { dragging.map { Int($0) } ?? ForecastOutcomeSlider.displayStep(forWire: wireValue) }
    private var label: String { ToDoStrings.load().outcomeOptionLabel(displayValue: step) }

    var body: some View {
        HStack(spacing: 8) {
            Slider(value: Binding(get: { Double(step) }, set: { dragging = $0.rounded() }),
                   in: 1...Double(ToDoScoring.outcomeSteps), step: 1,
                   onEditingChanged: { isEditing in
                       guard !isEditing, let chosen = dragging else { return }
                       dragging = nil
                       onCommit(Int(chosen) * ToDoScoring.outcomeWireFactor)
                   })
                .frame(width: ForecastOutcomeSlider.trackWidth)
                .accessibilityLabel(Text(ForecastText[.outcome]))
                .accessibilityValue(Text(label))
            Text(label)
                .font(.localForecastRegular(ForecastOutcomeSlider.labelFontSize))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .disabled(isDisabled)
    }
}

/// Shared by all Projects views; the draft still captures and validates the signed-in account.
struct ForecastCapacitySettingsButton: View {
    @ObservedObject var store: LocalForecastStore
    @SwiftUI.State private var showsCapacitySettings = false

    var body: some View {
        ToDoIconButton(systemImage: "gearshape", help: ForecastText[.capacitySettings]) {
            showsCapacitySettings = true
        }
        .accessibilityLabel(Text(ForecastText[.capacitySettings]))
        .disabled(store.isApplying || store.settingsAccount.isEmpty)
        .popover(isPresented: $showsCapacitySettings) {
            ForecastCapacitySettingsView(store: store) { showsCapacitySettings = false }
        }
    }
}

struct LocalTimeForecastView: View {
    @ObservedObject var store: LocalForecastStore
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(ForecastText[.introduction]).font(.localForecastRegular(12)).foregroundColor(.secondary)
                Spacer()
                Picker(ForecastText[.horizon], selection: $store.horizonDays) {
                    ForEach([28, 90, 365], id: \.self) { count in
                        Text(ForecastText.format(.days, ["<COUNT>": String(count)])).tag(count)
                    }
                }.frame(width: 150).onChange(of: store.horizonDays) { _ in store.refresh() }
            }
            Text(ForecastText[.workTimeExplanation]).font(.localForecastRegular(11)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForecastStatus(store: store)
            if let result = store.result {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(result.weeks(calendar: store.calendar)) { week in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(ForecastText.date(week.start)).font(.localForecastSemibold(15))
                                HStack(alignment: .top, spacing: 6) {
                                    ForEach(week.days) { day in
                                        SwiftUI.Button(action: { store.selectedDay = day.date }) {
                                            ForecastDayCard(day: day)
                                        }.buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity).pointingHandCursor()
                                    }
                                }
                            }
                            Divider()
                        }
                    }.padding(.trailing, 6)
                }
            }
        }
        .onAppear { store.refreshIfNeeded() }
        .sheet(isPresented: Binding(get: { store.selectedDay != nil }, set: { if !$0 { store.selectedDay = nil } })) {
            if let date = store.selectedDay { ForecastDayLightbox(store: store, date: date) }
        }
    }
}

private struct ForecastCapacitySettingsView: View {
    @ObservedObject var store: LocalForecastStore
    let close: () -> Void
    @SwiftUI.State private var account: String
    @SwiftUI.State private var draft: LocalTimeForecast.CapacitySettings
    @SwiftUI.State private var saveFailed = false
    init(store: LocalForecastStore, close: @escaping () -> Void) {
        self.store = store; self.close = close
        let account = store.settingsAccount
        _account = SwiftUI.State(initialValue: account)
        _draft = SwiftUI.State(initialValue: LocalForecastPreferences.load(account: account))
    }
    private func clock(_ keyPath: WritableKeyPath<LocalTimeForecast.CapacitySettings, Int>) -> Binding<Date> {
        Binding(get: {
            let minutes = draft[keyPath: keyPath]
            return Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: minutes / 60, minute: minutes % 60)) ?? Date()
        }, set: {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
            draft[keyPath: keyPath] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ForecastText[.capacitySettings]).font(.localForecastSemibold(16))
            DatePicker(ForecastText[.sleepStarts], selection: clock(\.sleepStartMinute), displayedComponents: .hourAndMinute)
            DatePicker(ForecastText[.sleepEnds], selection: clock(\.sleepEndMinute), displayedComponents: .hourAndMinute)
            Stepper(value: $draft.selfCareMinutes, in: 0...1440, step: 15) {
                Text(ForecastText[.additionalSelfCare] + ": " + ForecastText.duration(Double(draft.selfCareMinutes)))
            }
            Text(ForecastText[.settingsExplanation]).font(.localForecastRegular(12)).foregroundColor(.secondary)
            if !draft.isValid || saveFailed {
                Text(ForecastText[saveFailed ? .planChanged : .settingsInvalid]).foregroundColor(.red)
            }
            HStack {
                SwiftUI.Button(ForecastText[.close], action: close)
                Spacer()
                SwiftUI.Button(ForecastText[.saveSettings]) {
                    if store.saveCapacitySettings(draft, expectedAccount: account) { close() } else { saveFailed = true }
                }.disabled(!draft.isValid || store.isApplying)
            }
        }.padding(16).frame(width: 370).font(.localForecastRegular(13))
    }
}

struct ForecastStatus: View {
    @ObservedObject var store: LocalForecastStore
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if store.isLoading {
                if let progress = store.loadProgress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(progressLabel(progress))
                        if let fraction = progress.fraction {
                            ProgressView(value: fraction).progressViewStyle(.linear).frame(maxWidth: 420)
                        } else {
                            ProgressView().scaleEffect(0.65).frame(width: 18, height: 18)
                        }
                    }
                } else { HStack { ProgressView().scaleEffect(0.65); Text(ForecastText[.loading]) } }
            }
            if let error = store.error {
                HStack {
                    Text(error).foregroundColor(.red)
                    SwiftUI.Button(ToDoStrings.load()[.refresh]) { store.refresh() }
                }
            }
            if !store.isLoading && !store.calendarAvailable { Text(ForecastText[.calendarMissing]).foregroundColor(.orange) }
        }.font(.localForecastRegular(12))
    }
    private func progressLabel(_ progress: LocalForecastLoadProgress) -> String {
        let stage: ForecastText.Key
        switch progress.stage {
        case .projects: stage = .loadingProjects
        case .tasks: stage = .loadingTasks
        case .calendar: stage = .loadingCalendar
        case .days: stage = .preparingDays
        case .calculation: stage = .calculating
        }
        guard let total = progress.total, let fraction = progress.fraction else { return ForecastText[stage] }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: currentLanguageCode)
        formatter.numberStyle = .percent; formatter.maximumFractionDigits = 0
        return ForecastText.format(.progressCount, ["<STAGE>": ForecastText[stage],
            "<COUNT>": String(progress.completed), "<TOTAL>": String(total),
            "<PERCENT>": formatter.string(from: NSNumber(value: fraction)) ?? ""])
    }
}

private struct ForecastDayCard: View {
    let day: LocalTimeForecast.Day
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(day.date, style: .date).font(.localForecastSemibold(11)).lineLimit(2)
            amount(.meetings, day.capacity.meetingMinutes, .blue)
            amount(.habits, day.capacity.habitMinutes, .purple)
            amount(.sleep, day.capacity.sleepMinutes, .gray)
            amount(.additionalSelfCare, day.capacity.selfCareMinutes, .gray)
            amount(.forecastTaskWork, day.allocatedWorkMinutes, .orange)
            amount(.unallocatedWorkTime, day.remainingWorkMinutes, .green)
            if day.capacity.overcommittedMinutes > 0 {
                Text(ForecastText.format(.overbooked, ["<DURATION>": ForecastText.duration(day.capacity.overcommittedMinutes)]))
                    .font(.localForecastRegular(10)).foregroundColor(.red)
            }
        }.padding(8).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
    }
    private func amount(_ key: ForecastText.Key, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ForecastText[key]).font(.localForecastRegular(10)).foregroundColor(.secondary)
            Text(ForecastText.duration(value)).font(.localForecastMedium(11)).foregroundColor(color)
        }
    }
}

struct LocalForecastPortfolioView: View {
    @ObservedObject var store: LocalForecastStore
    let openProject: (Project) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForecastStatus(store: store)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(store.result?.projects ?? []) { result in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                SwiftUI.Button(action: {
                                    if let project = store.projects.first(where: { $0.id == result.id }) { openProject(project) }
                                }) { Text(store.projectName(result.id)).font(.localForecastSemibold(15)) }.buttonStyle(PlainButtonStyle())
                                Spacer()
                                if let outcome = store.projects.first(where: { $0.id == result.id })?.outcome {
                                    Text(ForecastText.outcomeValue(outcome)).font(.localForecastRegular(11)).foregroundColor(.secondary)
                                }
                            }
                            ForecastProjectEstimate(store: store, projectID: result.id)
                            if let finish = result.completionDate {
                                Text(ForecastText.format(.completeBy, ["<DATE>": ForecastText.date(finish)]))
                                    .font(.localForecastRegular(12)).foregroundColor(.secondary)
                            }
                        }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(ToDoTheme.card).cornerRadius(8)
                    }
                }.padding(.trailing, 6)
            }
        }.onAppear { store.refreshIfNeeded() }
    }
}

struct ForecastProjectEstimate: View {
    @ObservedObject var store: LocalForecastStore
    let projectID: String
    var body: some View {
        if let result = store.result?.projects.first(where: { $0.id == projectID }) {
            if let deadline = result.project.dueDate, let lastDay = store.result?.days.last?.date,
               store.calendar.startOfDay(for: deadline) > lastDay,
               result.hasUnallocatedWork, result.unknownTaskCount == 0 {
                Text(ForecastText[.outsideHorizon]).font(.localForecastRegular(12)).foregroundColor(.secondary)
            } else if result.isFinished {
                // "100% of remaining work fits" is true but reads as a forecast; there is no
                // remaining work to forecast (report 2026-09-15_17-41-45).
                Text(ForecastText[.allWorkComplete]).font(.localForecastSemibold(12)).foregroundColor(.green)
            } else if let percent = result.likelyCompletionPercent {
                Text(ForecastText.format(result.project.dueDate == nil ? .remainingLikelihoodInHorizon : .remainingLikelihood, ["<PERCENT>": String(percent)]))
                    .font(.localForecastSemibold(12)).foregroundColor(percent < 100 ? .orange : .green)
            } else {
                Text(ForecastText[result.unknownTaskCount > 0 ? .missingEstimate : .noTasks])
                    .font(.localForecastRegular(12)).foregroundColor(.secondary)
            }
        }
    }
}

private struct ForecastDayLightbox: View {
    @ObservedObject var store: LocalForecastStore
    let date: Date
    @SwiftUI.State private var showsHabits = false
    @SwiftUI.State private var showsMeetings = false
    private var blocks: [ScheduleBlock] {
        let start = store.calendar.startOfDay(for: date)
        guard let input = store.dayInputs.first(where: { store.calendar.isDate($0.date, inSameDayAs: date) }) else { return [] }
        return LocalTimeForecast.detailBlocks(store.blocksByDay[start] ?? [], on: start,
            settings: input.settings, availableFrom: input.availableFrom, calendar: store.calendar)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ForecastText[.dayPlan] + " · " + ForecastText.date(date)).font(.localForecastSemibold(20))
                Spacer()
                SwiftUI.Button(ForecastText[.close]) { store.selectedDay = nil }.keyboardShortcut(.cancelAction)
            }
            if let day = store.result?.days.first(where: { store.calendar.isDate($0.date, inSameDayAs: date) }) {
                Text(ForecastText.format(.meetingTimeOnce, ["<DURATION>": ForecastText.duration(day.capacity.meetingMinutes)]))
                    .font(.localForecastRegular(12)).foregroundColor(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForecastDayCard(day: day)
                        dayGroup(.habits, rows: blocks.filter { $0.kind == .habit },
                                 minutes: day.capacity.habitMinutes, expanded: $showsHabits)
                        dayGroup(.meetings, rows: blocks.filter { $0.kind == .meeting },
                                 minutes: day.capacity.meetingMinutes, expanded: $showsMeetings)
                        Divider()
                        Text(ForecastText[.projectWork]).font(.localForecastSemibold(15))
                        ForEach(Array(day.allocations.enumerated()), id: \.offset) { _, allocation in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(store.taskName(allocation.taskID)).font(.localForecastMedium(12))
                                Text(store.projectName(allocation.projectID) + " · " + ForecastText.duration(allocation.workMinutes))
                                    .font(.localForecastRegular(11)).foregroundColor(.secondary)
                                if allocation.absorbedBlockMinutes > 0 {
                                    Text(ForecastText.format(.blockAbsorbed, ["<DURATION>": ForecastText.duration(allocation.absorbedBlockMinutes)]))
                                        .font(.localForecastRegular(11)).foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
        }.padding(18).frame(width: 660, height: 640).font(.localForecastRegular(13))
    }

    private func dayGroup(_ title: ForecastText.Key, rows: [ScheduleBlock], minutes: Double,
                          expanded: Binding<Bool>) -> some View {
        DisclosureGroup(isExpanded: expanded) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, block in
                    HStack(alignment: .top) {
                        Text(block.start, style: .time).frame(width: 70, alignment: .leading)
                        VStack(alignment: .leading) {
                            Text(block.title)
                            if let routine = block.routineName {
                                Text(routine).font(.localForecastRegular(11)).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(ForecastText.duration(Double(block.durationSeconds) / 60)).foregroundColor(.secondary)
                    }.padding(8).background(ToDoTheme.card).cornerRadius(6)
                }
            }.padding(.top, 6)
        } label: {
            // A DisclosureGroup's label is inert on macOS — only the caret toggles it — so clicking
            // the word "Meetings" did nothing (report 2026-09-11_20-54-18). The whole row is the
            // target now, which is what a heading with a caret beside it looks like it should do.
            HStack {
                Text(ForecastText[title]).font(.localForecastSemibold(15))
                Spacer()
                Text(ForecastText.duration(minutes)).foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture { if !rows.isEmpty { expanded.wrappedValue.toggle() } }
            .pointingHandCursor()
        }
        .disabled(rows.isEmpty)
    }
}

/// Whether to offer the reschedule plan, and why.
///
/// Pure, so the thresholds can be argued with in a test rather than in the UI — and they are the
/// part that matters. A suggestion that appears too often becomes wallpaper the user learns to
/// ignore, which wastes the feature rather than promoting it.
enum ReprioritiseSuggestion {
    enum Reason: Equatable {
        case overdue(Int)
        /// The worst SINGLE day inside `horizonDays`, and how far over it is.
        case dayOverCapacity(Double)
    }

    /// The PO's rule, verbatim: "The banner should appear if they have > 4 overdue tasks or the next
    /// 5 days have negative buffer of 2h or more" (report 2026-09-16_22-22-50, follow-up). "> 4" is
    /// taken literally — five or more.
    ///
    /// This replaces a threshold of ten that was measured from the account's own backlog. The measured
    /// number was the better-argued one, but it is not the number the PO asked for, and they asked
    /// twice.
    static let overdueThreshold = 5

    /// "Massively over", not merely over. The Day Plan's existing banner already fires at ANY
    /// over-commitment, and a day fifteen minutes over is fixed by working through lunch. Two hours
    /// is a day no amount of effort rescues, which is when re-prioritising is the real answer.
    static let massivelyOverMinutes: Double = 120

    /// How far ahead the capacity reason looks, **including today**: today plus the next four.
    ///
    /// The window is the whole bug. `worstDayOvercommitMinutes` used to take the maximum across the
    /// forecast's entire ninety-day horizon while the sentence read "Today is <DURATION> over" — so a
    /// day in early October was reported as today's problem ("Today is not 3h18m over" / "it says 4h
    /// over", report 2026-09-16_22-22-50). The number was real; the day it belonged to was not today.
    ///
    /// The same constant bounds the query and feeds the sentence, so the two cannot drift apart again.
    static let horizonDays = 5

    /// A declined suggestion stays declined for a week. Per-day would nag up to seven times for one
    /// persistent backlog; forever would spend the feature the first time the user was merely busy.
    static let dismissalDays = 7

    /// `nil` means say nothing.
    ///
    /// `worstDayOvercommitMinutes` is the worst SINGLE day in the window, never the sum across it.
    /// That distinction decides whether this banner is useful or wallpaper: five days' deficits added
    /// together reach two hours for almost anyone busy in almost any week, which would put the banner
    /// on screen permanently. One day two hours over is a real signal about a real day.
    static func reason(overdueCount: Int, worstDayOvercommitMinutes: Double,
                       dismissedAt: Date?, now: Date, calendar: Calendar) -> Reason? {
        if let dismissedAt = dismissedAt,
           let expires = calendar.date(byAdding: .day, value: dismissalDays, to: dismissedAt),
           now < expires {
            return nil
        }
        if overdueCount >= overdueThreshold { return .overdue(overdueCount) }
        if worstDayOvercommitMinutes >= massivelyOverMinutes { return .dayOverCapacity(worstDayOvercommitMinutes) }
        return nil
    }

    /// The banner's sentence. The Day Plan does not use this — its existing over-capacity banner
    /// already says the same thing, and a second one beside it would be noise.
    static func text(for reason: Reason) -> String {
        switch reason {
        case .overdue(let count):
            return ForecastText.format(.reprioritiseOverdue, ["<COUNT>": String(count)])
        case .dayOverCapacity(let minutes):
            // The sentence must describe what the number actually measures. Saying "Today is" over a
            // figure drawn from a ninety-day horizon is what the PO kept seeing and kept rejecting.
            return ForecastText.format(.reprioritiseOverCapacity, [
                "<DURATION>": ForecastText.duration(minutes),
                "<DAYS>": String(horizonDays),
            ])
        }
    }
}

/// Where a declined suggestion is remembered. Per account, because two people on one Mac have
/// different backlogs.
enum ReprioritiseSuggestionDismissal {
    private static func key(_ account: String) -> String { "reprioritiseSuggestionDismissedAt.v1." + account }

    static func dismissedAt(account: String, defaults: UserDefaults = .standard) -> Date? {
        guard !account.isEmpty else { return nil }
        return defaults.object(forKey: key(account)) as? Date
    }

    static func dismiss(account: String, now: Date = Date(), defaults: UserDefaults = .standard) {
        guard !account.isEmpty else { return }
        defaults.set(now, forKey: key(account))
    }
}

/// Selecting a whole project's proposals at once ("Allow selecting all tasks in a project to be
/// rescheduled", report 2026-09-16_10-31-49).
enum ForecastGroupSelection {
    enum State: Equatable { case none, some, all }

    /// The rows in this group a select-all may actually take.
    ///
    /// Only rows that can be applied count. A row the user cannot write — no permission, or a
    /// project that is not synced — must not be swept in by a control that then silently does
    /// nothing with it. Tasks fixed by a hard deadline never reach this list at all: the plan has
    /// no change to propose for them, so there is nothing here to skip.
    static func selectableIDs(_ changes: [LocalTimeForecast.DueDateChange],
                              canApply: (LocalTimeForecast.DueDateChange) -> Bool) -> [String] {
        changes.filter { $0.kind == .task }.filter(canApply).map(\.id)
    }

    /// A bulk control takes TASK date changes and nothing else.
    ///
    /// A project-deadline row moves a whole project's deadline. That is why it was given its own
    /// flagged section, and it is the same reason no "select all" may sweep it up — "Select all
    /// editable changes shouldn't select the project due date assignments"
    /// (report 2026-09-16_17-47-42). It stays individually selectable, one deliberate click at a
    /// time. This is the sheet-wide button's rule and the per-project one's, so the two cannot drift.
    static func bulkSelectableIDs(_ changes: [LocalTimeForecast.DueDateChange],
                                  canApply: (LocalTimeForecast.DueDateChange) -> Bool) -> [String] {
        selectableIDs(changes, canApply: canApply)
    }

    static func state(selectableIDs: [String], selected: Set<String>) -> State {
        guard !selectableIDs.isEmpty else { return .none }
        let chosen = selectableIDs.filter { selected.contains($0) }.count
        if chosen == 0 { return .none }
        return chosen == selectableIDs.count ? .all : .some
    }

    /// Everything selected → clear the group; anything else → select all of it. A part-filled box
    /// offers to finish the job, so "some" selects the rest rather than clearing what is there.
    static func toggled(selectableIDs: [String], selected: Set<String>) -> Set<String> {
        var updated = selected
        if state(selectableIDs: selectableIDs, selected: selected) == .all {
            selectableIDs.forEach { updated.remove($0) }
        } else {
            selectableIDs.forEach { updated.insert($0) }
        }
        return updated
    }

    static func symbol(for state: State) -> String {
        switch state {
        case .none: return "square"
        case .some: return "minus.square"
        case .all: return "checkmark.square.fill"
        }
    }
}

/// Sizes the reschedule rows share, so the row-action column and the space kept clear for the
/// scroller are stated once rather than guessed at in three places.
enum ForecastRowMetrics {
    /// Reserved for a row's trailing action button. Fixed, so a long title cannot squeeze it away.
    static let actionWidth: CGFloat = 20
    /// Kept clear inside the scroll view so a trailing control never sits under the vertical
    /// scroller — which is what clipped the complete button (report 2026-09-16_09-27-24).
    static let scrollerClearance: CGFloat = 14
    static let groupCornerRadius: CGFloat = 8
    static let groupPadding: CGFloat = 10
}

/// The proposal list, grouped by the project each row belongs to.
///
/// A project-level fact — "this project's rating is stricter than these tasks' own" — belongs once
/// above its group, not on every row. Printed per row it appeared four times verbatim on a
/// four-task project, next to four copies of the project chip, which is noise rather than
/// explanation (report 2026-09-16_06-40-52, follow-up). Groups keep the order the plan produced:
/// each project appears where its first row did, so the list is still read top to bottom as "what
/// gets done first".
enum ForecastChangeGrouping {
    struct Group: Identifiable {
        /// The project these rows share. `nil` only for rows the snapshot has no project for.
        let projectID: String?
        let changes: [LocalTimeForecast.DueDateChange]
        var id: String { projectID ?? "__unprojected" }
    }

    /// A project's own row groups with its tasks — it is the same project, and a heading that named
    /// it twice would be the duplication this exists to remove.
    static func key(for change: LocalTimeForecast.DueDateChange, taskProjectID: (String) -> String?) -> String? {
        change.kind == .project ? change.itemID : taskProjectID(change.itemID)
    }

    /// How far a proposal moves a task, in whole days. **Absolute**: a task dragged nine days
    /// earlier is as big an interference as one pushed nine days later, and the PO wants to
    /// scrutinise interference, not lateness.
    static func daysMoved(_ change: LocalTimeForecast.DueDateChange, calendar: Calendar) -> Int {
        guard let previous = change.previousDate else { return Int.max }
        let from = calendar.startOfDay(for: previous), to = calendar.startOfDay(for: change.proposedDate)
        return abs(calendar.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// Major or minor, split on days moved.
    ///
    /// "Major changes (moved > 5 days)" / "Minor changes (moved < 5 days)"
    /// (report 2026-09-16_17-49-54). Those two leave 5 itself unhomed, so **5 counts as major**: the
    /// boundary errs toward the pile the user said they want to read rather than the one they said
    /// they do not care about. A row with no previous date is a task that had no deadline at all,
    /// which is a bigger claim than any number of days, so it is major too.
    static func isMajor(_ change: LocalTimeForecast.DueDateChange, calendar: Calendar) -> Bool {
        daysMoved(change, calendar: calendar) >= majorThresholdDays
    }

    static let majorThresholdDays = 5

    /// Project-deadline rows are split out of the grouped task list entirely.
    ///
    /// Grouped with its own tasks, a project row was indistinguishable from them — same checkbox,
    /// same arrow, same date format, reading as just another task in the card ("It's quite unclear
    /// that the bottom point is about setting a due date for the project", report
    /// 2026-09-16_09-39-02). The consequences are wildly different: one moves a task, the other
    /// moves a whole project's deadline. They now live in separate sections with separate wording.
    static func split(_ changes: [LocalTimeForecast.DueDateChange])
        -> (tasks: [LocalTimeForecast.DueDateChange], projectDeadlines: [LocalTimeForecast.DueDateChange]) {
        (changes.filter { $0.kind == .task }, changes.filter { $0.kind == .project })
    }

    static func groups(_ changes: [LocalTimeForecast.DueDateChange],
                       taskProjectID: (String) -> String?) -> [Group] {
        var order: [String] = []
        var byKey: [String: [LocalTimeForecast.DueDateChange]] = [:]
        for change in changes {
            let identifier = key(for: change, taskProjectID: taskProjectID) ?? "__unprojected"
            if byKey[identifier] == nil { order.append(identifier) }
            byKey[identifier, default: []].append(change)
        }
        return order.map { identifier in
            Group(projectID: identifier == "__unprojected" ? nil : identifier,
                  changes: byKey[identifier] ?? [])
        }
    }
}

/// The same project grouping, for the rows the planner refused.
///
/// "It should have the same grouping by project" (report 2026-09-16_22-22-50, follow-up) — so this
/// deliberately mirrors `ForecastChangeGrouping.groups` rather than inventing a second convention:
/// same key, same first-seen ordering, same `nil` for rows with no project.
enum ForecastConflictGrouping {
    struct Group: Identifiable {
        let projectID: String?
        let conflicts: [LocalTimeForecast.PlanConflict]
        var id: String { projectID ?? "__unprojected" }
    }

    static func groups(_ conflicts: [LocalTimeForecast.PlanConflict],
                       taskProjectID: (String) -> String?) -> [Group] {
        var order: [String] = []
        var byKey: [String: [LocalTimeForecast.PlanConflict]] = [:]
        for conflict in conflicts {
            let key = (conflict.kind == .project ? conflict.itemID : taskProjectID(conflict.itemID)) ?? "__unprojected"
            if byKey[key] == nil { order.append(key) }
            byKey[key, default: []].append(conflict)
        }
        return order.map { key in
            Group(projectID: key == "__unprojected" ? nil : key, conflicts: byKey[key] ?? [])
        }
    }
}

/// One proposed move: what it is, where it is going, and how far it may be pushed. Its project is
/// named once by the group heading above it rather than on the row.
///
/// A struct rather than a function on the sheet because the row can swap itself for a project
/// picker, and "is this row's picker open" is state that belongs to the row.
/// One row the planner would not pick a date for — with the date it has, the reason in checkable
/// words, and the field that lets the user answer it.
///
/// Typing a date here does not write anything: `WorkPlan.adoptingManualDates` turns the row into a
/// proposal, which then goes through exactly the same review-and-apply path as every other row.
private struct ForecastConflictRow: View {
    @ObservedObject var store: LocalForecastStore
    let conflict: LocalTimeForecast.PlanConflict
    @SwiftUI.State private var isEditingDate = false

    private var isEditable: Bool { !store.isApplying && !store.isLoading }
    private var changeID: String { store.changeID(for: conflict) }
    private var currentDate: Date? {
        conflict.kind == .task ? store.dueDate(forTaskID: conflict.itemID)
            : store.projectDueDate(forProjectID: conflict.itemID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(store.name(for: conflict))
                .font(.localForecastMedium(13))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                // The date it has now — the thing the old list left out, and without which the
                // refusal below cannot be checked against anything.
                Text(ForecastText.date(currentDate) + " →")
                    .font(.localForecastRegular(12)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                dateControl
                Spacer(minLength: 0)
            }
            Text(store.conflictReason(conflict))
                .font(.localForecastRegular(12)).foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Same control and same grammar as the proposal rows (`ToDoDueDateField` / `ToDoDueDateParser`),
    /// so `2y`, `14d`, `3wk`, `fri` and `28 sep` mean here what they mean everywhere else.
    @ViewBuilder private var dateControl: some View {
        if isEditingDate {
            ToDoDueDateField(day: Binding(
                get: { store.manualDate(forChangeID: changeID) ?? conflict.earliestCompletionDate ?? Date() },
                set: { store.setManualDate($0, forChangeID: changeID) }
            ), strings: ToDoStrings.load())
            .frame(maxWidth: 260)
        } else {
            Text(ToDoStrings.load()[.editDueDate])
                .font(.localForecastMedium(12))
                .foregroundColor(ToDoTheme.accent)
                .underline(isEditable)
                .contentShape(Rectangle())
                .onTapGesture { if isEditable { isEditingDate = true } }
                .pointingHandCursor()
        }
    }
}

private struct ForecastChangeRow: View {
    @ObservedObject var store: LocalForecastStore
    let change: LocalTimeForecast.DueDateChange
    @SwiftUI.Binding var selected: Set<String>
    /// The chip becomes a typeable dropdown when clicked, and goes back to a chip once a project is
    /// chosen — the row is a dense list item, so the control only takes the space while it is in use.
    @SwiftUI.State private var isPickingProject = false
    @SwiftUI.State private var isEditingDuration = false
    @SwiftUI.State private var isEditingDate = false
    @SwiftUI.State private var durationDraft = ""

    private var isEditable: Bool { store.canApply(change) && !store.isApplying && !store.isLoading }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // The title must be the part that yields, and the button the part that does not.
            //
            // This was a `Toggle` whose `Text` label sized itself to the whole title, beside a
            // `Spacer(minLength: 8)`: a long title made the row demand more width than the sheet had,
            // the spacer collapsed to its minimum, and the complete button was pushed past the
            // trailing edge and clipped — a row that could not be completed
            // (report 2026-09-16_09-27-24). That is the fixed-width-sibling-versus-flexible-column
            // failure that has collapsed a Day Plan column twice this week, and the cure is the same:
            // let the flexible column really be flexible (`fixedSize` vertical-only, so it wraps
            // rather than demanding width, and `maxWidth: .infinity` to absorb what is left), and
            // give the fixed sibling a reserved frame plus layout priority so it is placed first and
            // cannot be squeezed out at any panel width.
            HStack(alignment: .top, spacing: 8) {
                Toggle(isOn: Binding(get: { selected.contains(change.id) }, set: {
                    if $0 { selected.insert(change.id) } else { selected.remove(change.id) }
                })) {
                    Text(store.name(for: change))
                        .font(.localForecastMedium(13))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!isEditable)
                .frame(maxWidth: .infinity, alignment: .leading)
                if change.kind == .task { completeButton.layoutPriority(1) }
            }
            if isPickingProject {
                projectPicker
            } else {
                // Fixed-size items first, then a trailing Spacer, so this line packs from the left
                // and never stretches the row wider than the panel.
                HStack(spacing: 6) {
                    Text(ForecastText.date(change.previousDate) + " →")
                        .font(.localForecastRegular(12)).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    proposedDateControl
                    if change.kind == .task {
                        durationBadge
                        moveToProjectButton
                    }
                    Spacer(minLength: 0)
                }
                whyThisDate
            }
            if change.kind == .task {
                ForecastOutcomeSlider(wireValue: store.outcome(forTaskID: change.itemID), isDisabled: !isEditable) {
                    store.setTaskOutcome($0, forTaskID: change.itemID)
                }
            }
            if !store.canApply(change) { Text(ForecastText[.noPermission]).font(.localForecastRegular(11)).foregroundColor(.orange) }
        }
    }

    /// Tick the task off without leaving the plan. It sits at the right end of the row, away from
    /// the selection checkbox at the left, because the two do very different things and a
    /// mis-click costs a write.
    /// The proposed date, and the way to overrule it. Clicking it swaps in `ToDoDueDateField` — the
    /// same control and the same `ToDoDueDateParser` grammar the task editor and the snooze field
    /// use, so `2y`, `14d`, `3wk`, `mo`, `fri` and `28 sep` mean here exactly what they mean there.
    /// No second date parser: one grammar, one place it is defined.
    @ViewBuilder private var proposedDateControl: some View {
        if isEditingDate {
            ToDoDueDateField(day: Binding(
                get: { store.manualDate(forChangeID: change.id) ?? change.proposedDate },
                set: { store.setManualDate($0, forChangeID: change.id) }
            ), strings: ToDoStrings.load())
            .frame(maxWidth: 260)
        } else {
            let isOverridden = store.manualDate(forChangeID: change.id) != nil
            Text(ForecastText.date(change.proposedDate))
                .font(.localForecastMedium(12))
                .foregroundColor(isOverridden ? ToDoTheme.accent : .secondary)
                .underline(isEditable)
                .contentShape(Rectangle())
                .onTapGesture { if isEditable { isEditingDate = true } }
                .pointingHandCursor()
                .help(ForecastText[.typeADate])
        }
    }

    /// Why the plan chose this date. "Not clear why it changed it from 18th to 16th" was half the
    /// complaint (report 2026-09-16_09-40-20): whatever the planner decides, the row has to say what
    /// it decided and on what grounds, rather than presenting a bare new date.
    @ViewBuilder private var whyThisDate: some View {
        if store.manualDate(forChangeID: change.id) != nil {
            Text(ForecastText[.reasonYouChoseIt]).font(.localForecastRegular(11)).foregroundColor(ToDoTheme.accent)
        } else if let previous = change.previousDate,
                  store.calendar.startOfDay(for: change.proposedDate) < store.calendar.startOfDay(for: previous) {
            Text(ForecastText[.reasonBroughtForward]).font(.localForecastRegular(11)).foregroundColor(.secondary)
        } else {
            Text(ForecastText[.reasonPushedBack]).font(.localForecastRegular(11)).foregroundColor(.secondary)
        }
    }

    private var completeButton: some View {
        SwiftUI.Button(action: { store.completeTask(change.itemID) }) {
            Image(systemName: "checkmark.circle").font(.system(size: 13))
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .disabled(!isEditable)
        .help(ForecastText[.completeTask])
        // A reserved width, so the button is never the thing that gives when the title is long.
        .frame(width: ForecastRowMetrics.actionWidth, alignment: .trailing)
    }

    /// The task's estimate, and the control that edits it. Clicking swaps the badge for a field; the
    /// text is read by `QuickAddTaskParser.durationMinutes(fromFieldText:)`, the SAME parser the Day
    /// Plan's duration field uses, so `45m`, `1h30` and a bare `45` mean here what they mean there.
    @ViewBuilder private var durationBadge: some View {
        if isEditingDuration {
            TextField("", text: $durationDraft, onCommit: commitDuration)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.localForecastRegular(11))
                .frame(width: 64)
        } else {
            let minutes = store.durationMinutes(forTaskID: change.itemID)
            ToDoChip(text: minutes.map { QuickAddTaskParser.durationLabel($0) } ?? ForecastText[.noEstimate],
                     tint: ToDoTheme.separator)   // i18n-ignore: numeric duration token
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isEditable else { return }
                    durationDraft = minutes.map { QuickAddTaskParser.durationLabel($0) } ?? ""
                    isEditingDuration = true
                }
                .pointingHandCursor()
                .help(ForecastText[.editDuration])
        }
    }

    private func commitDuration() {
        isEditingDuration = false
        guard let minutes = QuickAddTaskParser.durationMinutes(fromFieldText: durationDraft) else { return }
        store.setDuration(minutes: minutes, forTaskID: change.itemID)
    }

    /// Reassigning is still per task, but the row no longer carries a project name to click — the
    /// group heading names it once instead — so the gesture moved onto a compact button with the
    /// same tooltip and the same picker behind it.
    private var moveToProjectButton: some View {
        SwiftUI.Button(action: { isPickingProject = true }) {
            Image(systemName: "folder").font(.system(size: 11))
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .disabled(!isEditable)
        .help(ForecastText[.changeProject])
        .frame(width: ForecastRowMetrics.actionWidth, alignment: .center)
    }

    private var projectPicker: some View {
        SearchableComboBoxField(options: store.projectPickerOptions,
                                selectedId: Binding(
                                    get: { store.projectID(forTaskID: change.itemID) },
                                    // A cleared field means "no project chosen", which on this
                                    // screen means *no change* — every task here belongs to a
                                    // project, and a stray click must not unfile one.
                                    set: { chosen in
                                        guard let chosen = chosen else { return }
                                        isPickingProject = false
                                        store.reassign(taskID: change.itemID, toProjectID: chosen)
                                    }),
                                clearedOptionTitle: ForecastText[.chooseProject])
            .frame(width: 220, height: 24)
    }
}

struct ForecastReschedulePlanSheet: View {
    @ObservedObject var store: LocalForecastStore
    @SwiftUI.State private var selected: Set<String> = []
    /// Major opens, minor stays shut: the user wants to scrutinise one and skim the other.
    @SwiftUI.State private var isMajorExpanded = true
    @SwiftUI.State private var isMinorExpanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ForecastText[.reviewPlan]).font(.localForecastSemibold(20))
                Spacer()
                SwiftUI.Button(ForecastText[.close]) { store.showsWorkPlan = false }
                    .disabled(store.isApplying || store.isLoading).keyboardShortcut(.cancelAction)
                    .pointingHandCursor()
            }
            Text(ForecastText[.reviewExplanation]).font(.localForecastRegular(12)).foregroundColor(.secondary)
            // The lock is the user's to set: it was a hardcoded rule, and someone who wants the next
            // two days re-planned had no way to ask (report 2026-09-21_07-45-21). The sentence under
            // it explains what ticking it does, and is shown only while it is true — without it the
            // absence of any row for today or tomorrow looked like the plan missing them rather than
            // the rule it is (report 2026-09-17_09-04-13).
            Toggle(ForecastText[.keepPlannedDays], isOn: $store.locksPlannedDays)
                .font(.localForecastRegular(12))
                .disabled(store.isApplying || store.isLoading)
                .pointingHandCursor()
            if store.locksPlannedDays {
                Text(ForecastText[.plannedDaysLocked]).font(.localForecastRegular(12)).foregroundColor(.secondary)
            }
            // Applying now moves the task in the Day Plan as well as changing its deadline. Saying so
            // matters because the previous behaviour was the opposite and looked like nothing had
            // happened: the dates changed and the over-committed day kept every task on it
            // (report 2026-09-17_09-04-13, follow-up).
            Text(ForecastText[.dayPlanFollowsTheDates]).font(.localForecastRegular(12)).foregroundColor(.secondary)
            if let message = store.applyMessage { Text(message).foregroundColor(.orange) }
            if let plan = store.workPlan {
                if plan.changes.isEmpty { Text(ForecastText[.noChanges]) }
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Each project's tasks sit inside their own bordered card. Grouping alone did
                        // not read as grouping — "it's not obvious that the tasks are grouped
                        // together by project. I think it needs a border around them"
                        // (report 2026-09-16_09-27-24) — and the PO was looking at it.
                        // Major / minor is the OUTER split, projects grouped inside it. Two
                        // groupings cannot both be outermost, and this is the axis the PO said they
                        // care about — "I want to scrutinise major changes but don't care about minor
                        // changes" (report 2026-09-16_17-49-54) — so it is the one that decides what
                        // is on screen at all. Project grouping still does its job inside each pile.
                        // The day the user asked to fix comes first and open. Its rows are then taken
                        // OUT of the major/minor piles below rather than repeated in them.
                        // Projects first: "Put projects at risk at the top because if they change,
                        // tasks will change too" (report 2026-09-21_07-45-21, follow-up). Deciding a
                        // project's deadline can rewrite every task under it, so reviewing tasks
                        // first means reviewing work that a later decision may undo.
                        let plannedSplit = ForecastChangeGrouping.split(plan.changes)
                        projectDeadlineSection(plannedSplit.projectDeadlines)
                        let focused = store.dayFocusChanges
                        dayFocusSection(focused)
                        let focusedIDs = Set(focused.map(\.id))
                        let split = ForecastChangeGrouping.split(plan.changes.filter { !focusedIDs.contains($0.id) })
                        let major = split.tasks.filter { ForecastChangeGrouping.isMajor($0, calendar: store.calendar) }
                        let minor = split.tasks.filter { !ForecastChangeGrouping.isMajor($0, calendar: store.calendar) }
                        changeAccordion(major, titleKey: .majorChanges, isExpanded: $isMajorExpanded)
                        changeAccordion(minor, titleKey: .minorChanges, isExpanded: $isMinorExpanded)
                        conflictsSection(plan.reviewableConflicts)
                        fixedByProjectSection
                    }
                    // Keep the scroll content clear of the vertical scroller. Without this a control
                    // at a row's trailing edge sits underneath it and is clipped, which is what made
                    // the complete button unreachable (report 2026-09-16_09-27-24).
                    .padding(.trailing, ForecastRowMetrics.scrollerClearance)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack {
                    SwiftUI.Button(ForecastText[.selectAll]) {
                        selected = Set(ForecastGroupSelection.bulkSelectableIDs(plan.changes) { store.canApply($0) })
                    }
                        .disabled(store.isApplying || store.isLoading)
                        .pointingHandCursor()
                    Spacer()
                    SwiftUI.Button(ForecastText[.applySelected]) { store.applySelected(selected) }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 32))
                        .disabled(selected.isEmpty || store.isApplying || store.isLoading || !store.calendarAvailable)
                }
            }
            // While the plan is still loading there is no list or action row yet, so the short header
            // content used to sit at the top of the fixed 620pt sheet with a big empty gap below it. Fill
            // that space and centre the spinner so the loading state reads as one screen, not a half-empty
            // one; once the plan arrives the list fills the sheet as before.
            if store.workPlan == nil {
                Spacer(minLength: 0)
                HStack { Spacer(); ProgressView(); Spacer() }
                Spacer(minLength: 0)
            } else if store.isApplying || store.isLoading {
                ProgressView()
            }
        }
        .padding(18).frame(width: 660, height: 620).font(.localForecastRegular(13))
        // A row that left the plan — pinned to a fixed date, or displaced by one that was — must not
        // stay ticked and be applied from under the user.
        .onChange(of: store.workPlan?.changes.map(\.id) ?? []) { ids in selected.formIntersection(ids) }
    }

    /// The project these rows share, named once, with the one project-level fact that applies to all
    /// of them underneath it.
    ///
    /// The proposals that clear the day the user asked to fix — first, open, and named.
    ///
    /// "It still didn't improve the day plan for Monday - there were several tasks that should have
    /// been proposed to move but they weren't in the list" (report 2026-09-16_22-22-50, follow-up).
    /// They were in the list. Today and tomorrow are locked, so every proposal that can help an
    /// over-committed day moves it by a day or two — which is *by definition* the "Minor changes"
    /// pile, and that pile is collapsed because the PO asked for it to be. The lock and the grouping
    /// are each right and between them they hid the entire useful output.
    ///
    /// So the answer is not to un-collapse minor changes for everyone — that would undo an explicit
    /// instruction for the whole-backlog case it was asked for. It is that "fix Monday" is a
    /// different question from "re-prioritise everything", and deserves its own answer at the top.
    ///
    /// The relief line is the honest half: five rows that do not add up to the gap are worse than
    /// being told the gap cannot be closed from here.
    @ViewBuilder private func dayFocusSection(_ changes: [LocalTimeForecast.DueDateChange]) -> some View {
        if let focus = store.dayFocus, let relief = store.dayFocusRelief {
            let day = ForecastText.date(focus.day)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    accordionSelectAll(changes)
                    Text(ForecastText.format(.dayFocusHeading, ["<DAY>": day, "<COUNT>": String(changes.count)]))
                        .font(.localForecastSemibold(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if changes.isEmpty {
                    Text(ForecastText.format(.dayFocusNothingToMove, ["<DAY>": day]))
                        .font(.localForecastRegular(12)).foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(reliefSentence(relief, day: day))
                        .font(.localForecastRegular(12))
                        .foregroundColor(relief.clearsTheDay ? .secondary : .orange)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(ForecastChangeGrouping.groups(changes,
                                                          taskProjectID: { store.projectID(forTaskID: $0) })) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            groupHeading(group)
                            ForEach(group.changes) { change in
                                ForecastChangeRow(store: store, change: change, selected: $selected).id(change.id)
                            }
                        }
                        .padding(ForecastRowMetrics.groupPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: ForecastRowMetrics.groupCornerRadius)
                                        .stroke(ToDoTheme.separator))
                    }
                }
            }
            .padding(.bottom, 4)
        }
    }

    /// What the offered moves actually achieve, said in one sentence rather than left to be inferred
    /// from five rows of arithmetic.
    private func reliefSentence(_ relief: ForecastDayFocus.Relief, day: String) -> String {
        let freed = ForecastText.duration(relief.freedMinutes)
        if relief.clearsTheDay {
            return ForecastText.format(.dayFocusClears, ["<FREED>": freed, "<DAY>": day])
        }
        let opening = ForecastText.format(.dayFocusRelief, [
            "<FREED>": freed, "<SHORTFALL>": ForecastText.duration(relief.shortfallMinutes), "<DAY>": day,
        ])
        let remaining = ForecastText.duration(relief.remainingMinutes)
        // When what is left is exactly the work the user pinned, say so — the screen has then done
        // everything it is allowed to do and the answer is elsewhere.
        let tail = relief.remainderIsPinned
            ? ForecastText.format(.dayFocusPinnedRemainder, [
                "<DAY>": day, "<REMAINING>": remaining, "<COUNT>": String(relief.immovableCount)])
            : ForecastText.format(.dayFocusRemainder, ["<DAY>": day, "<REMAINING>": remaining])
        return opening + " " + tail
    }

    /// The rows the planner refused, grouped by project, dated, and answerable.
    ///
    /// "Also this list is very unhelpful. It should have the same grouping by project and show due
    /// date and let me reschedule manually if I want to" (report 2026-09-16_22-22-50, follow-up).
    /// It was a flat list of titles and red sentences with no project, no date and nothing to do —
    /// and these are precisely the tasks the automatic pass gave up on, which makes it the worst
    /// possible place to leave the user without an action.
    @ViewBuilder private func conflictsSection(_ conflicts: [LocalTimeForecast.PlanConflict]) -> some View {
        if !conflicts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(ForecastText[.conflictsHeading]).font(.localForecastSemibold(13)).padding(.top, 4)
                Text(ForecastText[.conflictsExplanation])
                    .font(.localForecastRegular(12)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(ForecastConflictGrouping.groups(conflicts,
                                                        taskProjectID: { store.projectID(forTaskID: $0) })) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        if let projectID = group.projectID {
                            ToDoChip(text: "#" + store.projectName(projectID), tint: ToDoTheme.accent)   // i18n-ignore: the user's own project name
                        }
                        ForEach(group.conflicts) { conflict in
                            ForecastConflictRow(store: store, conflict: conflict).id(conflict.id)
                        }
                    }
                    .padding(ForecastRowMetrics.groupPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: ForecastRowMetrics.groupCornerRadius)
                                    .stroke(ToDoTheme.separator))
                }
            }
        }
    }

    /// The rating note names the rating and the band, never a "deadline": saying "Deadline set by
    /// <project>" about a project with no due date read as the app inventing one
    /// (report 2026-09-16_06-40-52). Rating and end date are different claims and the screen must
    /// not use one word for both.
    @ViewBuilder private func groupHeading(_ group: ForecastChangeGrouping.Group) -> some View {
        if let projectID = group.projectID {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    groupSelectAll(group)
                    ToDoChip(text: "#" + store.projectName(projectID), tint: ToDoTheme.accent)   // i18n-ignore: the user's own project name
                    Spacer(minLength: 0)
                }
                if let inherited = store.inheritedOutcome(inProject: projectID,
                                                          taskIDs: group.changes.map(\.itemID)) {
                    Text(ForecastText.format(.inheritedFromProject, [
                        "<PROJECT>": store.projectName(projectID),
                        "<OUTCOME>": ForecastText.outcomeValue(inherited) + " · " + ForecastText.outcomeLabel(inherited),
                    ]))
                    .font(.localForecastRegular(11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }.padding(.top, 6)
        }
    }

    /// One collapsible pile of proposals, grouped by project inside it.
    ///
    /// Major opens expanded and minor collapsed, because the whole point is to read one and skim the
    /// other. An empty pile renders nothing at all rather than an accordion with nothing behind it.
    @ViewBuilder private func changeAccordion(_ changes: [LocalTimeForecast.DueDateChange],
                                              titleKey: ForecastText.Key,
                                              isExpanded: SwiftUI.Binding<Bool>) -> some View {
        if !changes.isEmpty {
            DisclosureGroup(isExpanded: isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ForecastChangeGrouping.groups(changes,
                                                          taskProjectID: { store.projectID(forTaskID: $0) })) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            groupHeading(group)
                            ForEach(group.changes) { change in
                                ForecastChangeRow(store: store, change: change, selected: $selected)
                                    // Pin each row's state to its own change, so a control left open
                                    // on one row can never be carried onto another when the plan
                                    // re-flows under it.
                                    .id(change.id)
                            }
                        }
                        .padding(ForecastRowMetrics.groupPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: ForecastRowMetrics.groupCornerRadius)
                                .stroke(ToDoTheme.separator)
                        )
                    }
                }
                .padding(.top, 6)
            } label: {
                HStack(spacing: 6) {
                    // The select-all sits OUTSIDE the toggle area on purpose: `disclosureLabelTap`
                    // makes its whole subtree a toggle, so a checkbox inside it would open and close
                    // the accordion instead of ticking. Only the title carries the tap.
                    accordionSelectAll(changes)
                    Text(ForecastText.format(titleKey, ["<COUNT>": String(changes.count)]))
                        .font(.localForecastSemibold(13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // The whole title toggles, not just the caret — the PO reported that as a
                        // bug on another screen today (report 2026-09-16_08-45-58).
                        .disclosureLabelTap(isExpanded)
                }
            }
        }
    }

    /// Tick every proposal in one accordion at once.
    ///
    /// "it needs to let me select all in the minor changes accordion"
    /// (report 2026-09-16_17-49-54, follow-up). Without it, "I don't care about minor changes" still
    /// costs a click per row, which is the opposite of why the pile was collapsed.
    ///
    /// **Major gets one too.** They only asked for minor, but withholding it from major would not
    /// actually force per-row scrutiny — the sheet-wide "Select all editable changes" already takes
    /// every task including the major ones — so the only thing an asymmetry would achieve is making
    /// the coarser, less scoped control the only way to accept a read-through major list. Same
    /// control, same semantics, both piles.
    ///
    /// Scoped to the accordion: selecting every minor change must leave the major pile untouched,
    /// because accepting the minor ones wholesale while still reading the major ones one at a time
    /// is the entire point of the split.
    @ViewBuilder private func accordionSelectAll(_ changes: [LocalTimeForecast.DueDateChange]) -> some View {
        // The SAME function the sheet-wide button and the per-project box read, so a third control
        // cannot drift from the other two — drift between two copies is what put project deadlines
        // into a bulk select in the first place (report 2026-09-16_17-47-42). It inherits that
        // exclusion for free: a project's deadline is never swept up here either.
        let ids = ForecastGroupSelection.bulkSelectableIDs(changes) { store.canApply($0) }
        if !ids.isEmpty {
            let state = ForecastGroupSelection.state(selectableIDs: ids, selected: selected)
            SwiftUI.Button(action: { selected = ForecastGroupSelection.toggled(selectableIDs: ids, selected: selected) }) {
                Image(systemName: ForecastGroupSelection.symbol(for: state))
                    .font(.system(size: 13))
                    .foregroundColor(state == .none ? .secondary : ToDoTheme.accent)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .disabled(store.isApplying || store.isLoading)
            .help(ForecastText.format(.selectAllInGroup, ["<COUNT>": String(ids.count)]))
        }
    }

    /// Tick every proposal in this project at once. Tri-state, because "some of them are already
    /// ticked" is a real and common third answer: an empty box selects the group, a part-filled box
    /// offers to finish it, and a full box clears it.
    ///
    /// It only ever takes rows that can actually be applied, so it cannot appear to select something
    /// and then quietly do nothing with it.
    @ViewBuilder private func groupSelectAll(_ group: ForecastChangeGrouping.Group) -> some View {
        let ids = ForecastGroupSelection.selectableIDs(group.changes) { store.canApply($0) }
        if !ids.isEmpty {
            let state = ForecastGroupSelection.state(selectableIDs: ids, selected: selected)
            SwiftUI.Button(action: { selected = ForecastGroupSelection.toggled(selectableIDs: ids, selected: selected) }) {
                Image(systemName: ForecastGroupSelection.symbol(for: state))
                    .font(.system(size: 13))
                    .foregroundColor(state == .none ? .secondary : ToDoTheme.accent)
            }
            .buttonStyle(PlainButtonStyle())
            .pointingHandCursor()
            .disabled(store.isApplying || store.isLoading)
            .help(ForecastText.format(.selectAllInProject, ["<COUNT>": String(ids.count)]))
        }
    }

    /// Changing a whole PROJECT's deadline, kept well away from the task rows.
    ///
    /// These used to sit inside the project's own card looking exactly like a task row — same
    /// checkbox, same `old → new`, same date format — so the row that moves an entire project's
    /// deadline was indistinguishable from one that moves a single task
    /// (report 2026-09-16_09-39-02, "needs to be super clear"). Its own section, its own heading, a
    /// warning tint, and a full sentence naming the project and saying what is being set, rather
    /// than a bare name and an arrow.
    @ViewBuilder private func projectDeadlineSection(_ changes: [LocalTimeForecast.DueDateChange]) -> some View {
        if !changes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill").foregroundColor(.orange).font(.system(size: 11))
                    Text(ForecastText[.projectDeadlineHeading]).font(.localForecastSemibold(13))
                }
                Text(ForecastText[.projectDeadlineExplanation])
                    .font(.localForecastRegular(11)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(changes) { change in
                    Toggle(isOn: Binding(get: { selected.contains(change.id) }, set: {
                        if $0 { selected.insert(change.id) } else { selected.remove(change.id) }
                    })) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(ForecastText.format(.projectDeadlineRow, [
                                "<PROJECT>": store.projectName(change.itemID),
                                "<DATE>": ForecastText.date(change.proposedDate),
                            ]))
                            .font(.localForecastMedium(13))
                            .fixedSize(horizontal: false, vertical: true)
                            Text(ForecastText[.previous] + ": " + ForecastText.date(change.previousDate))
                                .font(.localForecastRegular(11)).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .disabled(!store.canApply(change) || store.isApplying || store.isLoading)
                    if !store.canApply(change) {
                        Text(ForecastText[.noPermission]).font(.localForecastRegular(11)).foregroundColor(.orange)
                    }
                }
            }
            .padding(ForecastRowMetrics.groupPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ForecastRowMetrics.groupCornerRadius)
                    .stroke(Color.orange.opacity(0.6))
            )
            .padding(.top, 6)
        }
    }

    /// Tasks whose project has fixed their dates. They are deliberately a section of THIS sheet
    /// rather than a screen of their own: the user arrives here asking "what moves?", and the honest
    /// answer for these is "not the date, only the order" — an answer that belongs beside the dates
    /// it is refusing, not behind another click.
    @ViewBuilder private var fixedByProjectSection: some View {
        // Deadlines inside the next fortnight first — see `FixedProjectPriority`. These cannot be
        // date-moved, so they sit at the bottom; that is wrong for a project due next week.
        let groups = LocalTimeForecast.FixedProjectPriority.prioritised(store.fixedProjectOrders,
                                                                        calendar: store.calendar)
        if !groups.isEmpty {
            Text(ForecastText[.fixedByProjectHeading]).font(.localForecastSemibold(13)).padding(.top, 8)
            Text(ForecastText[.fixedByProjectExplanation]).font(.localForecastRegular(11)).foregroundColor(.secondary)
            ForEach(groups, id: \.projectID) { group in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ToDoChip(text: "#" + store.projectName(group.projectID), tint: ToDoTheme.accent)   // i18n-ignore: the user's own project name
                        Text(group.endDate.map { ForecastText.format(.projectEndsOn, ["<DATE>": ForecastText.date($0)]) }
                             ?? ForecastText[.projectHasNoEndDate])
                            .font(.localForecastRegular(11)).foregroundColor(.secondary)
                    }
                    ForEach(Array(group.taskIDs.enumerated()), id: \.element) { position, taskID in
                        fixedTaskRow(taskID, position: position, in: group)
                    }
                }.padding(.top, 4)
            }
        }
    }

    private func fixedTaskRow(_ taskID: String, position: Int, in group: LocalTimeForecast.FixedProjectOrder) -> some View {
        HStack(spacing: 8) {
            Text("\(position + 1).").font(.localForecastRegular(12)).foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(store.taskName(taskID)).font(.localForecastMedium(13))
                Text(ForecastText.date(store.dueDate(forTaskID: taskID)))
                    .font(.localForecastRegular(11)).foregroundColor(.secondary)
            }
            Spacer()
            SwiftUI.Button { store.moveTask(taskID, within: group.taskIDs, earlier: true) } label: { Image(systemName: "arrow.up") }
                .help(ForecastText[.moveEarlier])
                .disabled(!store.canMoveTask(taskID, within: group.taskIDs, earlier: true))
            SwiftUI.Button { store.moveTask(taskID, within: group.taskIDs, earlier: false) } label: { Image(systemName: "arrow.down") }
                .help(ForecastText[.moveLater])
                .disabled(!store.canMoveTask(taskID, within: group.taskIDs, earlier: false))
        }
    }
}

extension LocalTimeForecast.TaskInput {
    /// The task being edited as the forecast sees it, so the editor's warning and its suggestion row
    /// always judge the same candidate.
    static func draft(_ task: ToDoTask, projectID: String?, durationMinutes: Int) -> Self {
        .init(id: task.id, projectID: projectID, estimatedMinutes: Double(durationMinutes),
              outcome: task.outcome ?? LocalTimeForecast.TaskInput.unratedOutcome,
              perspiration: task.effectivePerspiration,
              dueDate: ToDoDates.parse(task.due_date))
    }
}

/// The whole decision behind the editor's due-date advice, out of the view so it can be tested
/// through the same calls the view makes rather than by hand-assembling arguments.
enum ForecastDueDateAdvisor {
    /// What the line under the date field says. Exactly one of these at a time — the screen makes one
    /// claim about a date, never two that can disagree (report 2026-09-15_20-08-56).
    enum Advice: Equatable {
        case none
        case calculating
        case failed(String)
        /// The task does not fit anywhere in the horizon, so there is no day to propose.
        case doesNotFit
        /// The work fits, but only after the project it belongs to has ended — so there is no day
        /// inside the project to propose. A different fact from "does not fit anywhere", and the
        /// user needs to be told which (report 2026-09-16_17-52-37).
        case pastProjectEnd(Date)
        case shortfall(LocalTimeForecast.DayCapacityWarning)
    }

    static func advice(day: Date?, candidate: LocalTimeForecast.TaskInput, slot: LocalTimeForecast.SlotSuggestion?,
                       forecast: LocalTimeForecast.Result?, isLoading: Bool, error: String?,
                       calendar: Calendar) -> Advice {
        if isLoading { return .calculating }
        guard let forecast = forecast else { return error.map(Advice.failed) ?? .none }
        guard let slot = slot else { return .none }
        if slot.exceedsProjectEnd, let end = slot.projectEnd { return .pastProjectEnd(end) }
        guard slot.proposedDay != nil else { return .doesNotFit }
        guard let day = day,
              let warning = LocalTimeForecast.capacityWarning(forChosenDay: day, candidate: candidate,
                                                              forecast: forecast, proposedDay: slot.proposedDay,
                                                              calendar: calendar) else { return .none }
        return .shortfall(warning)
    }

    static func text(for advice: Advice) -> String? {
        switch advice {
        case .none: return nil
        case .calculating: return ForecastText[.loading]
        case .failed(let message): return message
        case .doesNotFit: return ForecastText[.noSlot]
        case .pastProjectEnd(let end):
            return ForecastText.format(.noSlotBeforeProjectEnd, ["<DATE>": ForecastText.date(end)])
        case .shortfall(let warning): return ForecastText.dayAdvice(warning)
        }
    }

    /// One line per day the user actually lands on, so "the forecast disagrees with me about
    /// tomorrow" can be settled from the log instead of guessed at (report 2026-09-15_17-59-04,
    /// follow-up "I don't see the warning - there should be one tomorrow").
    static func diagnostic(day: Date?, candidate: LocalTimeForecast.TaskInput, slot: LocalTimeForecast.SlotSuggestion?,
                           forecast: LocalTimeForecast.Result?, calendar: Calendar) -> String? {
        guard let day = day, let forecast = forecast else { return nil }
        let available = forecast.days.first { calendar.isDate($0.date, inSameDayAs: day) }
            .map { LocalTimeForecast.availableMinutes(on: $0, for: candidate.id) }
        let load = LocalTimeForecast.dayLoad(on: day, forecast: forecast, calendar: calendar)
        return "forecast day capacity: day=\(ToDoDates.ymd(day))"
            + " needed=\(candidate.estimatedMinutes.map { String(Int($0)) } ?? "none")m"
            + " available=\(available.map { String(Int($0)) } ?? "not-forecast")m"
            + " capacity=\(load.map { String(Int($0.capacityMinutes)) } ?? "not-forecast")m"
            + " committed=\(load.map { String(Int($0.committedMinutes)) } ?? "not-forecast")m"
            + " over=\(load.map { String(Int($0.overcommittedMinutes)) } ?? "not-forecast")m"
            + " proposed=\(slot?.proposedDay.map(ToDoDates.ymd) ?? "none")"
    }
}

/// Everything the editor's due-date row has to say about the forecast, directly under the date field
/// it is about: whether it is still calculating, whether the task fits at all, and how short the
/// chosen day is. The "Next available date … [Use suggested date]" row it replaces is gone — a
/// button to accept a proposal is pointless once the field already holds it, which is what
/// `onProposal` arranges (report 2026-09-15_20-08-56).
struct ForecastDueDateAdvice: View {
    @ObservedObject var store: LocalForecastStore
    let task: ToDoTask
    let projectID: String?
    let durationMinutes: Int
    let selectedDate: Date?
    /// The day the app proposes, handed to the editor so a new task's date can default to it. Same
    /// value, same call, so a default and a proposal can never name different days.
    var onProposal: (Date) -> Void = { _ in }
    var log: (String) -> Void = { addLog(text: $0) }

    /// The proposal is a full horizon-wide allocation of every task. Recomputing it inside `body`
    /// re-ran it on every keystroke in the task editor, which is what made typing a title lag —
    /// nothing was hitting the network (report 2026-09-11_21-40-33). It is cached against the
    /// inputs that can change the answer instead.
    @SwiftUI.State private var cached: LocalTimeForecast.SlotSuggestion?
    @SwiftUI.State private var cachedInputs: SlotInputs?

    private static let fontSize: CGFloat = 11
    private static let calendarNoteFontSize: CGFloat = 11

    /// Everything the next-slot calculation reads. The task's title is deliberately not here.
    private struct SlotInputs: Equatable {
        let snapshot: UUID
        let taskID: String
        let projectID: String?
        let durationMinutes: Int
        let outcome: Int
        let perspiration: Int
        let dueDate: Date?
    }

    private var inputs: SlotInputs {
        SlotInputs(snapshot: store.snapshotToken, taskID: task.id, projectID: projectID,
                   durationMinutes: durationMinutes, outcome: task.outcome ?? LocalTimeForecast.TaskInput.unratedOutcome,
                   perspiration: task.effectivePerspiration, dueDate: ToDoDates.parse(task.due_date))
    }

    private var candidate: LocalTimeForecast.TaskInput {
        .draft(task, projectID: projectID, durationMinutes: durationMinutes)
    }

    private var advice: ForecastDueDateAdvisor.Advice {
        ForecastDueDateAdvisor.advice(day: selectedDate, candidate: candidate, slot: cached,
                                      forecast: store.result, isLoading: store.isLoading,
                                      error: store.error, calendar: store.calendar)
    }

    private func refreshSlot() {
        let current = inputs
        guard cachedInputs != current else { return }
        cachedInputs = current
        cached = store.result == nil ? nil
            : LocalTimeForecast.nextSlot(for: candidate, days: store.dayInputs, projects: store.projectInputs,
                                         tasks: store.taskInputs, calendar: store.calendar)
        if let line = ForecastDueDateAdvisor.diagnostic(day: selectedDate, candidate: candidate, slot: cached,
                                                        forecast: store.result, calendar: store.calendar) {
            log(line)
        }
        if let proposal = cached?.proposedDay { onProposal(proposal) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let text = ForecastDueDateAdvisor.text(for: advice) {
                Text(text)
                    .font(.localForecastRegular(ForecastDueDateAdvice.fontSize))
                    .foregroundColor(advice == .calculating ? .secondary : .orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if store.result != nil && !store.calendarAvailable {
                Text(ForecastText[.calendarMissing])
                    .font(.localForecastRegular(ForecastDueDateAdvice.calendarNoteFontSize))
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: refreshSlot)
        .onChange(of: inputs) { _ in refreshSlot() }
    }
}

private extension Font {
    static func localForecastRegular(_ size: CGFloat) -> Font { Font(getRegularFont(size: size)) }
    static func localForecastMedium(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }
    static func localForecastSemibold(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }
}
