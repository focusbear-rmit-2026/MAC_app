//
//  FocusStartAdvancedScreen.swift
//  Focus Bear
//
//  Figma "0.1/ Set Duration", "0.2/ Set Goal" and "0.3.x/ Set Blocking" are one screen, not three: a
//  centre column of three accordion cards with exactly one expanded, the bear commenting on whichever
//  card is open, and "‹ Go back / Regular Options" top-left to drop back to the simple screen.
//

import SwiftUI

private struct FocusStartExpandedCardTopKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        if let next = nextValue() { value = next }
    }
}

/// The primary action's rendered bounds, measured against the visible page rather than its
/// scroll document. Visual QA checks this preference at the actual native window sizes.
struct FocusStartPrimaryActionFrameKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        if let next = nextValue() { value = next }
    }
}

@available(macOS 11.0, *)
struct FocusStartAdvancedScreen: SwiftUI.View {
    @ObservedObject var state: FocusStartState
    @ObservedObject private var managedRuntime = ManagedBlockingRuntime.shared
    @SwiftUI.State private var activeCardTop: CGFloat = 0

    /// #2571: id of a 1pt anchor at the very bottom of the scroll content, used to scroll the last
    /// (blocking) card's strictness controls into view when it expands.
    private static let bottomAnchorID = "focusStartBottomAnchor"

    var body: some SwiftUI.View {
        GeometryReader { proxy in
            let scale = FocusStartScale(contentWidth: proxy.size.width)
            let compact = proxy.size.width < scale.pt(FocusStartLayout.contentColumnWidth
                + FocusStartLayout.advancedModeLinkColumnWidth + FocusStartLayout.bearCircleDiameter)
            // At unusually narrow widths, keep the readable card reachable instead of clipping it.
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    ScrollViewReader { scrollProxy in
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: scale.pt(24)) {
                                // #2571 (3): the back link always sits on its own row at the top-left,
                                // so it no longer reserves a fixed left column that pushed everything
                                // off-centre. The centre column is then balanced by equal flexible space
                                // on each side, so it stays centred at every window size (the bear draws
                                // in the right side's space).
                                modeLink(scale, compact: compact)
                                HStack(alignment: .top, spacing: scale.pt(24)) {
                                    Color.clear.frame(maxWidth: .infinity)
                                    centreColumn(scale, compact: compact)
                                    ZStack(alignment: .top) {
                                        if let bearScale = bearScale(in: proxy.size.width, contentScale: scale) {
                                            bearColumn(bearScale, contentScale: scale)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .top)
                                }
                                .coordinateSpace(name: "focusStartAdvancedColumns")
                                .onPreferenceChange(FocusStartExpandedCardTopKey.self) { top in
                                    if let top = top, abs(top - activeCardTop) > 0.5 { activeCardTop = top }
                                }
                                // #2571: anchor at the very bottom so expanding the last (blocking) card
                                // can scroll its strictness controls into view — they sit below the fold
                                // otherwise, since the screen doesn't scroll on expand by itself.
                                Color.clear.frame(height: 1).id(Self.bottomAnchorID)
                            }
                            .padding(.horizontal, compact ? 12 : 0)
                            .padding(.bottom, scale.pt(FocusStartLayout.screenBottomInset))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                        .frame(maxHeight: .infinity)
                        .onChange(of: state.expandedCard) { card in
                            // Only the last card has content below the fold; scroll it fully into view.
                            guard card == .blocking else { return }
                            DispatchQueue.main.async {
                                withAnimation { scrollProxy.scrollTo(Self.bottomAnchorID, anchor: .bottom) }
                            }
                        }
                    }
                    primaryActionFooter(scale, compact: compact)
                }
                .frame(width: max(proxy.size.width, scale.pt(FocusStartLayout.contentColumnWidth) + 24),
                       height: proxy.size.height, alignment: .topLeading)
            }
            .background(FocusStartPalette.screenBackground)
        }
        .coordinateSpace(name: "focusStartViewport")
        // #2571 (NEW-B): renders `.fastTooltip` tips at the root so they float above the scroll/clip.
        .fastTooltipLayer()
    }

    /// Keep the action available while long project suggestions or blocking options scroll.
    /// It occupies its own space, so the footer never covers the last card or its controls.
    private func primaryActionFooter(_ scale: FocusStartScale, compact: Bool) -> some SwiftUI.View {
        FocusStartPrimaryButton(title: state.strings.startSessionButton,
                                scale: scale,
                                isEnabled: state.isStartEnabled,
                                action: state.onStart)
            .frame(width: scale.pt(FocusStartLayout.contentColumnWidth))
            .background(GeometryReader { proxy in
                Color.clear.preference(key: FocusStartPrimaryActionFrameKey.self,
                    value: proxy.frame(in: .named("focusStartViewport")))
            })
            .padding(.top, scale.pt(32))
            .padding(.bottom, scale.pt(40))
            // #2571 (3): centre the Start button under the now-centred centre column.
            .frame(maxWidth: .infinity, alignment: .center)
            .background(FocusStartPalette.screenBackground)
    }

    /// The centre column is centred, so each side gets half of the leftover width; the bear draws in
    /// the right half. Since centring halves the space the bear used to get, let it shrink further
    /// (down to `bearMinFactor`) before hiding, so it stays visible in a small window (#2571 3).
    private static let bearMinFactor: CGFloat = 0.35
    private func bearScale(in width: CGFloat, contentScale scale: FocusStartScale) -> FocusStartScale? {
        let gap = scale.pt(24)
        let sideRegion = (width - scale.pt(FocusStartLayout.contentColumnWidth) - gap * 2) / 2
        guard sideRegion >= FocusStartLayout.bearCircleDiameter * Self.bearMinFactor / 2 else { return nil }
        return FocusStartScale(decorationFactor: min(scale.factor, sideRegion * 2 / FocusStartLayout.bearCircleDiameter),
                               minimum: Self.bearMinFactor)
    }

    private func modeLink(_ scale: FocusStartScale, compact: Bool = false) -> some SwiftUI.View {
        FocusStartModeLink(topLine: state.strings.goSimpleLinkTop,
                           bottomLine: state.strings.goSimpleLinkBottom,
                           pointsBack: true, scale: scale, action: state.onSwitchMode)
            // #2571 (3): now a top-left row for every size (not a side column), so a modest top offset.
            .padding(.top, compact ? 12 : scale.pt(48))
            .padding(.leading, compact ? 0 : scale.pt(60))
    }

    private func centreColumn(_ scale: FocusStartScale, compact: Bool) -> some SwiftUI.View {
        VStack(spacing: scale.pt(FocusStartLayout.cardStackGap)) {
            if let tip = state.permissionsTip {
                FocusStartPermissionsBanner(tip: tip,
                                            buttonTitle: state.strings.fixPermissionsButton,
                                            scale: scale,
                                            action: state.onFixPermissions)
            }
            title(scale)
                .padding(.bottom, scale.pt(FocusStartLayout.cardStackTopInset))
            trackExpandedCard(.duration, content: durationCard(scale))
            trackExpandedCard(.goal, content: goalCard(scale))
            trackExpandedCard(.blocking, content: blockingCard(scale))
            if let progress = state.superFocusProgress {
                Text(progress)
                    .font(scale.font(FocusStartLayout.summaryFont))
                    .foregroundColor(FocusStartPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            if !state.unfocusedTimerText.isEmpty {
                Text(state.unfocusedTimerText)
                    .font(scale.font(FocusStartLayout.summaryFont))
                    .foregroundColor(FocusStartPalette.secondaryText)
            }
        }
        .frame(width: scale.pt(FocusStartLayout.contentColumnWidth))
        // #2571 (3): the back link is now a row above this column, so it no longer needs the tall
        // title inset that used to clear the side link column. Trimmed a further 10pt to tighten the
        // gap between the back link and the title.
        .padding(.top, max(0, scale.pt(24) - 10))
    }

    private func trackExpandedCard<Content: SwiftUI.View>(_ card: FocusStartCard, content: Content) -> some SwiftUI.View {
        content.background(GeometryReader { proxy in
            Color.clear.preference(key: FocusStartExpandedCardTopKey.self,
                value: state.expandedCard == card ? proxy.frame(in: .named("focusStartAdvancedColumns")).minY : nil)
        })
    }

    /// "Start **an advanced** focus session" — the emphasis is a separate run in the brand orange.
    /// Built as three `Text`s rather than an attributed string because macOS 11 has no `AttributedString`.
    private func title(_ scale: FocusStartScale) -> some SwiftUI.View {
        if let postponeTitle = state.postponeTitle {
            return AnyView(Text(postponeTitle)
                .font(scale.font(FocusStartLayout.headlineFont, .semibold))
                .foregroundColor(FocusStartPalette.primaryText)
                .multilineTextAlignment(.center))
        }
        return AnyView((Text(state.strings.advancedTitlePrefix)
            .foregroundColor(FocusStartPalette.primaryText)
         + Text(state.strings.advancedTitleEmphasis)
            .foregroundColor(FocusStartPalette.accent)
         + Text(state.strings.advancedTitleSuffix)
            .foregroundColor(FocusStartPalette.primaryText))
            .font(scale.font(FocusStartLayout.headlineFont, .semibold))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.8))
    }

    // MARK: - Cards

    private func durationCard(_ scale: FocusStartScale) -> some SwiftUI.View {
        FocusStartAccordionCard(title: state.strings.durationCardTitle,
                                summary: state.durationSummary,
                                systemIcon: "hourglass",
                                isExpanded: state.expandedCard == .duration,
                                scale: scale,
                                onToggle: { state.toggleCard(.duration) }) {
            VStack(spacing: scale.pt(FocusStartLayout.cardContentGap)) {
                FocusStartDurationDial(duration: $state.duration,
                                       strings: state.strings,
                                       scale: scale,
                                       isEnabled: state.isDurationEditable)
                HStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
                    labelledControl(state.strings.untimedModeLabel, scale) {
                        FocusStartToggle(isOn: $state.duration.isUntimed, scale: scale)
                    }
                    Spacer(minLength: 0)
                }
                breakSettingsSection(scale)
                if state.isAdvancedOptionsEnabled {
                    HStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
                        labelledControl(state.strings.superFocusLabel, scale) {
                            FocusStartToggle(isOn: $state.isSuperFocusOn, scale: scale)
                                .disabled(!state.isSuperFocusEditable)
                        }
                        if state.isSuperFocusOn {
                            superFocusCountPicker(scale)
                            Text(state.strings.superFocusSessionsUnit)
                                .font(scale.font(FocusStartLayout.bodyFont))
                                .foregroundColor(FocusStartPalette.primaryText)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    /// #2449: break length and micro-breaks moved out of the timing row into their own collapsed
    /// section, so the card leads with the session length. The header keeps stating both settings, so
    /// collapsing it never hides what the session will actually do.
    private func breakSettingsSection(_ scale: FocusStartScale) -> some SwiftUI.View {
        FocusStartDisclosureSection(title: state.strings.breakSettingsTitle,
                                    summary: state.breakSettingsSummary,
                                    systemIcon: "pause.circle",
                                    isExpanded: state.isBreakSettingsExpanded,
                                    scale: scale,
                                    onToggle: { state.isBreakSettingsExpanded.toggle() }) {
            VStack(alignment: .leading, spacing: scale.pt(FocusStartLayout.rowGap)) {
                HStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
                    HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
                        Text(state.strings.enableMicroBreaksLabel)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .fixedSize(horizontal: false, vertical: true)
                        FocusStartToggle(isOn: $state.isMicroBreaksOn, scale: scale)
                            .disabled(!state.isDurationEditable)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
                        Text(state.strings.breakFrequencyLabel)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .fixedSize(horizontal: false, vertical: true)
                        breakFrequencyPicker(scale)
                        Text(state.strings.breakDurationUnit)
                            .font(scale.font(FocusStartLayout.summaryFont))
                    }.frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text(state.strings.microBreaksExplainer)
                    .font(scale.font(FocusStartLayout.summaryFont))
                    .foregroundColor(FocusStartPalette.supportingText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func goalCard(_ scale: FocusStartScale) -> some SwiftUI.View {
        FocusStartAccordionCard(title: state.strings.goalCardTitle,
                                summary: state.goalSummary,
                                systemIcon: "trophy",
                                isExpanded: state.expandedCard == .goal,
                                scale: scale,
                                onToggle: { state.toggleCard(.goal) }) {
            VStack(spacing: scale.pt(FocusStartLayout.cardContentGap)) {
                projectSelection(scale)
                selectedTasks(scale)
                taskSuggestions(scale)
            }
        }
    }

    private func projectSelection(_ scale: FocusStartScale) -> some SwiftUI.View {
        // #2571 (NEW-B): the "+" is disabled while the field is empty and enabled once there's text;
        // pressing Enter adds the intention just like clicking "+"; and the matching projects get a
        // "Projects" heading so it's clear what the list below the field is.
        let goalIsEmpty = state.projectQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(alignment: .leading, spacing: scale.pt(FocusStartLayout.rowGap)) {
            if state.showsProjectSearch {
                HStack(spacing: scale.pt(12)) {
                    searchField(state.strings.goalPlaceholder, text: $state.projectQuery, scale,
                                onCommit: state.useCustomGoal)
                    iconButton("plus", label: state.strings.useGoal, scale: scale, action: state.useCustomGoal)
                        .disabled(goalIsEmpty)
                        .opacity(goalIsEmpty ? 0.35 : 1)
                }
                if state.isLoadingProjects { ProgressView().controlSize(.small) }
                if !state.visibleProjects.isEmpty {
                    Text(state.strings.projectsHeading)
                        .font(scale.font(FocusStartLayout.summaryFont, .semibold))
                        .foregroundColor(FocusStartPalette.secondaryText)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: scale.pt(18)) {
                            ForEach(Array(state.visibleProjects.prefix(12))) { project in
                                projectChip(project, scale)
                            }
                        }
                        // #2571 (NEW-B): the horizontal scroll clips tight, cutting the chips' bottom
                        // border — a little vertical padding keeps the full stroke visible.
                        .padding(.vertical, 2)
                    }
                }
            } else {
                selectedGoal(scale)
            }
        }
    }

    private func projectChip(_ project: Project, _ scale: FocusStartScale) -> some SwiftUI.View {
        SwiftUI.Button { state.selectProject(project) } label: {
            HStack(spacing: scale.pt(18)) {
                Text(project.iconEmoji ?? "")
                VStack(alignment: .leading, spacing: scale.pt(8)) {
                    Text(project.name).lineLimit(1)
                    projectImportance(project, scale)
                }
                Image(systemName: state.selectedProjectID == project.id ? "checkmark.circle.fill" : "plus")
            }
            .font(scale.font(FocusStartLayout.summaryFont))
            .foregroundColor(FocusStartPalette.primaryText)
            .padding(scale.pt(22))
            .background(FocusStartPalette.fieldFill)
            .clipShape(RoundedRectangle(cornerRadius: scale.pt(12)))
            .overlay(RoundedRectangle(cornerRadius: scale.pt(12)).stroke(FocusStartPalette.border))
        }.buttonStyle(FBButtonStyle())
    }

    @ViewBuilder
    private func projectImportance(_ project: Project, _ scale: FocusStartScale) -> some SwiftUI.View {
        // The project's own rating, in the same words a task's uses — legacy `importance` said
        // "Critical" here where every other screen says "Hard deadline" (report
        // 2026-09-15_20-12-49). Known metadata only: do not invent forecast risk from the old
        // server allocator.
        if let outcome = project.outcome {
            Text(state.todoStrings.outcomeLabel(outcome))
                .font(scale.font(32, .medium))
                .foregroundColor(FocusStartPalette.accent)
                .padding(.horizontal, scale.pt(16)).padding(.vertical, scale.pt(5))
                .background(FocusStartPalette.thumbFill)
                .clipShape(Capsule())
                .help(state.todoStrings[.outcome])
        }
    }

    private func selectedGoal(_ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: scale.pt(18)) {
            if let project = state.selectedProject { Text(project.iconEmoji ?? "") }
            VStack(alignment: .leading, spacing: scale.pt(8)) {
                Text(state.goal).lineLimit(2)
                if let project = state.selectedProject { projectImportance(project, scale) }
            }
            Spacer(minLength: 0)
            iconButton("pencil", label: state.strings.changeGoal, scale: scale, action: state.editGoal)
            iconButton("xmark", label: state.strings.clearGoal, scale: scale, action: state.clearGoal)
        }
        .font(scale.font(FocusStartLayout.summaryFont))
        .padding(scale.pt(24))
        .background(FocusStartPalette.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: scale.pt(20)))
        .overlay(RoundedRectangle(cornerRadius: scale.pt(20)).stroke(FocusStartPalette.border))
    }

    private func selectedTasks(_ scale: FocusStartScale) -> some SwiftUI.View {
        VStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
            Text(state.strings.tasksLabel)
                .font(scale.font(FocusStartLayout.bodyFont))
                .foregroundColor(FocusStartPalette.primaryText)
            ForEach(state.selectedTasks) { task in selectedTask(task, scale) }
            if state.showsTaskSearch {
                searchField(state.strings.taskPlaceholder, text: $state.taskQuery, scale)
            } else {
                taskSearchToggle(state.strings.addMoreTasks, scale) { state.isTaskSearchExpanded = true }
            }
        }
    }

    private func taskSearchToggle(_ title: String,
                                  _ scale: FocusStartScale,
                                  action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(title, action: action)
            .buttonStyle(FBButtonStyle())
            .font(scale.font(FocusStartLayout.summaryFont))
            .foregroundColor(FocusStartPalette.accent)
    }

    private func selectedTask(_ task: ToDoTask, _ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: scale.pt(18)) {
            VStack(alignment: .leading, spacing: scale.pt(10)) {
                Text(task.title).lineLimit(2)
                taskMetadata(task, scale)
            }
            Spacer(minLength: 0)
            iconButton("xmark", label: state.strings.removeTask, scale: scale) { state.removeSelectedTask(task.id) }
        }
        .font(scale.font(FocusStartLayout.summaryFont))
        .padding(scale.pt(24))
        .background(FocusStartPalette.fieldFill)
        .clipShape(RoundedRectangle(cornerRadius: scale.pt(20)))
        .overlay(RoundedRectangle(cornerRadius: scale.pt(20)).stroke(FocusStartPalette.border))
    }

    private func taskMetadata(_ task: ToDoTask, _ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: scale.pt(12)) {
            if let score = task.top_score, score.isFinite {
                Label(state.todoStrings[.topScore] + " " + String(format: "%.1f", locale: Locale.current, score), systemImage: "bolt.fill")
                    .foregroundColor(.white)
                    .padding(.horizontal, scale.pt(16)).padding(.vertical, scale.pt(8))
                    .background(FocusStartPalette.secondaryAccent).clipShape(Capsule())
            }
            if task.durationSeconds > 0 {
                Label(state.todoStrings.format(.durationMinutes, ToDoStrings.countToken,
                    "\(Int(ceil(Double(task.durationSeconds) / 60)))"), systemImage: "clock")
                    .foregroundColor(FocusStartPalette.accent)
                    .padding(.horizontal, scale.pt(16)).padding(.vertical, scale.pt(8))
                    .background(FocusStartPalette.metadataBackground).clipShape(Capsule())
            }
        }
        .font(scale.font(32, .medium))
    }

    @ViewBuilder
    private func taskSuggestions(_ scale: FocusStartScale) -> some SwiftUI.View {
        if state.showsTaskSearch {
            VStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
                if state.isLoadingTasks { ProgressView().controlSize(.small) }
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(state.visibleTaskSuggestions) { task in taskSuggestion(task, scale) }
                    }
                }
                .frame(height: scale.pt(min(4, CGFloat(state.visibleTaskSuggestions.count)) * 120))
                // `hasAskedForTasks` matters as much as the other three: before the first load
                // completes the list is empty and nothing is in flight, and saying "no matching
                // tasks" then is a claim we have not earned.
                if !state.isLoadingTasks && state.hasAskedForTasks
                    && state.visibleTaskSuggestions.isEmpty && state.workChoiceError == nil {
                    Text(state.strings.noMatchingTasks).font(scale.font(FocusStartLayout.summaryFont))
                        .foregroundColor(FocusStartPalette.secondaryText)
                }
                if state.hasMoreTasks && state.taskQuery.isEmpty {
                    SwiftUI.Button(state.strings.moreTasks) { state.loadTaskSuggestions(more: true) }
                        .disabled(state.isLoadingTasks)
                }
                if let error = state.workChoiceError {
                    Text(error).font(scale.font(FocusStartLayout.summaryFont))
                    SwiftUI.Button(state.strings.retryWorkChoices) { state.loadWorkChoices() }
                }
            }
        }
    }

    private func taskSuggestion(_ task: ToDoTask, _ scale: FocusStartScale) -> some SwiftUI.View {
        SwiftUI.Button { state.selectTask(task) } label: {
            HStack(spacing: scale.pt(16)) {
                Text(task.iconEmoji ?? "")
                VStack(alignment: .leading, spacing: scale.pt(8)) {
                    Text(task.title).lineLimit(2).multilineTextAlignment(.leading)
                    taskMetadata(task, scale)
                }
                Spacer(minLength: scale.pt(12))
                Image(systemName: "plus")
            }
            .font(scale.font(FocusStartLayout.summaryFont))
            .foregroundColor(FocusStartPalette.primaryText)
            .padding(scale.pt(20))
            .frame(minHeight: scale.pt(120))
            .contentShape(Rectangle())
        }.buttonStyle(FBButtonStyle())
    }

    private func blockingCard(_ scale: FocusStartScale) -> some SwiftUI.View {
        FocusStartAccordionCard(title: state.strings.blockingCardTitle,
                                summary: state.blockingSummary,
                                systemIcon: "nosign",
                                isExpanded: state.expandedCard == .blocking,
                                scale: scale,
                                onToggle: { state.toggleCard(.blocking) }) {
            VStack(spacing: scale.pt(FocusStartLayout.cardContentGap)) {
                if managedRuntime.isSettingsLocked { managedSafetySummary(scale) }
                // #2571 (16): show which block list is applied right next to the label — the list stays
                // expanded after selecting, so the active choice wasn't obvious otherwise.
                HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
                    Text(state.strings.chooseBlockListLabel)
                        .font(scale.font(FocusStartLayout.bodyFont))
                        .foregroundColor(FocusStartPalette.primaryText)
                    if let selected = state.selectedBlockList {
                        Text(selected.name)
                            .font(scale.font(FocusStartLayout.bodyFont, .semibold))
                            .foregroundColor(FocusStartPalette.accent)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                blockListRow(scale)
                if let notice = state.blockingScheduleNotice {
                    Text(notice)
                        .font(scale.font(FocusStartLayout.summaryFont))
                        .foregroundColor(FocusStartPalette.warning)
                        .multilineTextAlignment(.center)
                }
                // A running blocking schedule is not a session, so this screen stays available — it
                // just says what is already being blocked, in the secondary colour so it reads as
                // status rather than as a problem.
                if let schedule = state.activeBlockingScheduleText {
                    Text(schedule)
                        .font(scale.font(FocusStartLayout.summaryFont))
                        .foregroundColor(FocusStartPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                SwiftUI.Button(action: state.onEditBlockLists) {
                    Text(state.strings.editBlockListsButton)
                        .font(scale.font(FocusStartLayout.summaryFont, .medium))
                        .foregroundColor(FocusStartPalette.accent)
                        .underline()
                }
                .buttonStyle(FBButtonStyle())
                Text(state.strings.strictnessLabel)
                    .font(scale.font(FocusStartLayout.bodyFont))
                    .foregroundColor(FocusStartPalette.primaryText)
                strictnessRow(scale)
                if state.isFocusAlignmentScoreVisible {
                    alignmentScoreRow(scale)
                }
            }
        }
    }

    private func managedSafetySummary(_ scale: FocusStartScale) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(18)) {
            Label(ManagedBlockingText.value("safetyTitle", fallback: "Safety mode"), systemImage: "shield.lefthalf.fill")
                .font(scale.font(FocusStartLayout.bodyFont, .semibold))
            Text(ManagedBlockingText.value("safetyExplanation", fallback: "Your school and parent manage these website categories. Personal focus sessions can add more restrictions."))
            if managedRuntime.syncState == .recovery {
                Text(ManagedBlockingText.value("recoveryStatus", fallback: "Reconnect to restore verified school controls. Settings stay locked; only essential recovery websites are available."))
                    .foregroundColor(FocusStartPalette.warning)
            } else if managedRuntime.syncState == .loading {
                Text(ManagedBlockingText.value("checkingControls", fallback: "Checking school and parent controls…"))
            } else if let policy = managedRuntime.activePolicy {
                Text(ManagedBlockingText.value("activePolicy", fallback: "Active now: <POLICY>")
                    .replacingOccurrences(of: "<POLICY>", with: policy.name))
                Text(policy.blockedCategories.map { ManagedBlockingText.category($0) }.joined(separator: ", "))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(ManagedBlockingText.value("noActivePolicy", fallback: "No school or home safety window is active now."))
            }
            SwiftUI.Button(ManagedBlockingText.value("safetyTitle", fallback: "Safety mode"), action: state.onEditBlockLists)
                .buttonStyle(FBButtonStyle()).foregroundColor(FocusStartPalette.accent)
        }
        .font(scale.font(FocusStartLayout.summaryFont))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(scale.pt(24))
        .overlay(RoundedRectangle(cornerRadius: scale.pt(20)).stroke(FocusStartPalette.border))
    }

    /// One of the goal card's two search wells: a magnifier, then the field itself.
    private func searchField(_ placeholder: String,
                             text: Binding<String>,
                             _ scale: FocusStartScale,
                             onCommit: @escaping () -> Void = {}) -> some SwiftUI.View {
        HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
            Image(systemName: "magnifyingglass")
                .font(scale.font(FocusStartLayout.summaryFont))
                .foregroundColor(FocusStartPalette.secondaryText)
            TextField(placeholder, text: text, onCommit: onCommit)
                .textFieldStyle(PlainTextFieldStyle())
                .font(scale.font(FocusStartLayout.fieldFont))
        }
        .focusStartField(scale)
    }

    // MARK: - Card rows

    /// A settings row's label paired with its control. Both are `fixedSize` so a narrow window
    /// squeezes the gaps rather than truncating "Untimed mode:" to "Untimed m…".
    private func labelledControl<Control: SwiftUI.View>(_ label: String,
                                                        _ scale: FocusStartScale,
                                                        @ViewBuilder control: () -> Control) -> some SwiftUI.View {
        HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
            Text(label)
                .font(scale.font(FocusStartLayout.bodyFont))
                .foregroundColor(FocusStartPalette.primaryText)
                .fixedSize()
            control()
        }
        .fixedSize()
    }

    private var matchingBlockLists: [(offset: Int, element: FocusStartBlockList)] {
        Array(state.blockLists.enumerated()).filter {
            state.blockListQuery.isEmpty || $0.element.name.localizedCaseInsensitiveContains(state.blockListQuery)
        }
    }

    /// A finite viewport avoids an ideal-height collapse inside the screen's outer scroll view.
    private func blockListRow(_ scale: FocusStartScale) -> some SwiftUI.View {
        let rows = matchingBlockLists
        let rowHeight = max(scale.pt(96), 24 + scale.pt(44))
        return VStack(spacing: 0) {
            HStack {
                searchField(state.strings.blockListPlaceholder, text: $state.blockListQuery, scale)
                if !state.blockListQuery.isEmpty {
                    iconButton("xmark", label: state.strings.clearSearch, scale: scale) { state.blockListQuery = "" }
                }
            }
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    if rows.isEmpty {
                        Text(state.strings.noMatchingBlockLists)
                            .font(scale.font(FocusStartLayout.summaryFont))
                            .foregroundColor(FocusStartPalette.secondaryText)
                            .frame(height: rowHeight)
                    }
                    ForEach(rows, id: \.element.id) { index, item in
                        blockListChoice(item, index: index, scale: scale).frame(height: rowHeight)
                    }
                }
            }
            .frame(height: rowHeight * CGFloat(min(5, max(1, rows.count))))
        }
        .overlay(RoundedRectangle(cornerRadius: scale.pt(20)).stroke(FocusStartPalette.border))
        .clipShape(RoundedRectangle(cornerRadius: scale.pt(20)))
    }

    private func blockListChoice(_ item: FocusStartBlockList, index: Int, scale: FocusStartScale) -> some SwiftUI.View {
        let aiEnabled = !item.isDefault && !item.isRelaxFocus && item.isAIEnabled && state.isAiBlockingOn
        let isSelected = state.selectedBlockListIndex == index
        return HStack(spacing: scale.pt(12)) {
            SwiftUI.Button {
                guard state.isBlockListEditable else { return }
                state.selectedBlockListIndex = index
                state.onBlockListChanged()
            } label: {
                HStack(spacing: scale.pt(12)) {
                    Text(item.name).lineLimit(1)
                    Text(state.strings.appsAndWebsitesCount.replacingOccurrences(of: FocusStartPlaceholder.count, with: "\(item.itemCount)"))
                        .foregroundColor(isSelected ? FocusStartPalette.selectionText : FocusStartPalette.secondaryText).lineLimit(1)
                    Text(aiEnabled ? state.strings.aiEnabledBadge : state.strings.aiDisabledBadge)
                        .font(scale.font(FocusStartLayout.badgeFont, .medium))
                        .padding(scale.pt(8)).foregroundColor(.white)
                        // #2571: the "AI off" badge used secondaryText (a translucent gray) which, in dark
                        // mode, composited with the selected row's light-orange fill and disappeared — so it
                        // was made an opaque fill. #2603: systemGray was still too light for the white label
                        // (~2:1). darkGray is a fixed mid-dark gray: white on it is ~7.6:1 (AAA), and being
                        // darker than light rows yet lighter than dark-mode rows it stays visible on any row.
                        .background(aiEnabled ? FocusStartPalette.accent : Color(NSColor.darkGray))
                        .cornerRadius(scale.pt(8))
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }.buttonStyle(FBButtonStyle()).disabled(!state.isBlockListEditable)
            // #2571 (16): a bold white checkmark in a filled orange circle marks the applied block list,
            // right-aligned in a fixed slot just left of the edit icon (hidden when unselected so rows
            // stay aligned). The filled badge reads clearly as "this one is selected".
            ZStack {
                Circle().fill(FocusStartPalette.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: scale.pt(22), weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: scale.pt(48), height: scale.pt(48))
            .opacity(isSelected ? 1 : 0)
            // "Locked Focus" has no editable block-list config and is hidden from the Block Lists editor,
            // so showing a pencil that opens an editor without it is misleading — omit it. (#2644)
            if !item.isLockedFocus {
                iconButton("pencil", label: state.strings.editBlockListsButton + ": " + item.name, scale: scale) {
                    state.onEditBlockList(item.id)
                }
            }
        }
        .font(scale.font(FocusStartLayout.summaryFont))
        .foregroundColor(state.selectedBlockListIndex == index ? FocusStartPalette.accent : FocusStartPalette.primaryText)
        .padding(scale.pt(22))
        .background(state.selectedBlockListIndex == index ? FocusStartPalette.thumbFill : FocusStartPalette.surface)
        // #2571: an orange border makes the applied block list's row unmistakable.
        .overlay(Rectangle().strokeBorder(isSelected ? FocusStartPalette.accent : Color.clear,
                                          lineWidth: scale.pt(3)))
    }

    private func iconButton(_ icon: String, label: String, scale: FocusStartScale, action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Image(systemName: icon)
                .font(scale.font(FocusStartLayout.summaryFont, .medium))
                .foregroundColor(FocusStartPalette.accent)
                .frame(minWidth: 24, minHeight: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
        .accessibilityLabel(label)
        // #2571 (NEW-B): fast custom tooltip — the native `.help()` is slow and sometimes never shows.
        .fastTooltip(label)
    }

    private func summarySeparator(_ scale: FocusStartScale) -> some SwiftUI.View {
        Text(FocusStartSummaryBuilder.separator)
            .font(scale.font(FocusStartLayout.summaryFont, .medium))
            .foregroundColor(FocusStartPalette.primaryText)
            .opacity(0.5)
    }

    /// The design's "AI Enabled" pill. It is also the old simple screen's AI-blocking radio: tapping
    /// it toggles AI relevance checking, or shows the upgrade nag when the trial has lapsed.
    private func aiBadge(_ scale: FocusStartScale) -> some SwiftUI.View {
        SwiftUI.Button(action: state.toggleAiBlocking) {
            Text(state.isAiBlockingOn ? state.strings.aiEnabledBadge : state.strings.aiDisabledBadge)
                .font(scale.font(FocusStartLayout.badgeFont, .semibold))
                .foregroundColor(state.isAiBlockingOn ? .white : FocusStartPalette.primaryText)
                .padding(.horizontal, scale.pt(14))
                .padding(.vertical, scale.pt(11))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.badgeCornerRadius))
                        .fill(state.isAiBlockingOn ? FocusStartPalette.accent : FocusStartPalette.trackFill)
                )
        }
        .buttonStyle(FBButtonStyle())
    }

    private func strictnessRow(_ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: 0) {
            ForEach(FocusStartStrictness.allCases, id: \.rawValue) { level in
                FocusStartRadioOption(title: state.strings.strictnessTitle(level),
                                      subtitle: state.strings.strictnessDescription(level),
                                      isSelected: state.strictness == level,
                                      scale: scale,
                                      action: { state.strictness = level })
                    .disabled(!state.isStrictnessEditable)
                if level != FocusStartStrictness.allCases.last { Spacer(minLength: scale.pt(24)) }
            }
        }
        .opacity(state.isStrictnessEditable ? 1 : 0.5)
    }

    private func alignmentScoreRow(_ scale: FocusStartScale) -> some SwiftUI.View {
        HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
            Text(state.strings.focusAlignmentScoreLabel)
                .font(scale.font(FocusStartLayout.summaryFont))
                .foregroundColor(FocusStartPalette.primaryText)
            Menu("\(state.focusAlignmentScore)") {
                ForEach(arrFocusAlignmentScore, id: \.self) { value in
                    SwiftUI.Button(value) { state.focusAlignmentScore = Int(value) ?? state.focusAlignmentScore }
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .font(scale.font(FocusStartLayout.summaryFont))
            .frame(width: scale.pt(180))
        }
    }

    private func breakFrequencyPicker(_ scale: FocusStartScale) -> some SwiftUI.View {
        Menu("\(state.breakFrequencyMinutes)") {
            ForEach(Array(Set(FocusStartAdvancedScreen.breakFrequencyChoices + [state.breakFrequencyMinutes])).sorted(), id: \.self) { value in
                SwiftUI.Button("\(value)") { state.breakFrequencyMinutes = value }
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .font(scale.font(FocusStartLayout.bodyFont))
        .frame(width: scale.pt(120))
        .focusStartField(scale, height: FocusStartLayout.smallFieldHeight, horizontalPadding: 20)
        .disabled(!state.isDurationEditable || !state.isMicroBreaksOn)
    }

    private func superFocusCountPicker(_ scale: FocusStartScale) -> some SwiftUI.View {
        Menu("\(state.superFocusSessionCount)") {
            ForEach(FocusStartAdvancedScreen.superFocusCountChoices, id: \.self) { value in
                SwiftUI.Button("\(value)") { state.superFocusSessionCount = value }
            }
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .font(scale.font(FocusStartLayout.bodyFont))
        .frame(width: scale.pt(120))
        .focusStartField(scale, height: FocusStartLayout.smallFieldHeight, horizontalPadding: 20)
        .disabled(!state.isSuperFocusEditable)
    }

    // MARK: - Bear

    private func bearColumn(_ scale: FocusStartScale, contentScale: FocusStartScale) -> some SwiftUI.View {
        FocusStartBearPanel(imageName: "focusStartBearAdvanced",
                            bearWidthDesignPixels: FocusStartLayout.bearWidthAdvanced,
                            bubbleText: bubbleText,
                            scale: scale)
            .padding(.top, max(0, activeCardTop > 0 ? activeCardTop - contentScale.pt(50) : contentScale.pt(330)))
    }

    private var bubbleText: String {
        switch state.expandedCard {
        case .duration: return state.strings.durationBubble
        case .goal: return state.strings.goalBubble
        case .blocking: return state.strings.blockingBubble
        }
    }

    /// The break lengths the old free-text field realistically produced, offered as a menu so the
    /// screen has no numeric text entry to validate.
    static let breakFrequencyChoices = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120]
    /// Matches the old "how many focus sessions" dropdown (2…20).
    static let superFocusCountChoices = Array(2...20)
}
