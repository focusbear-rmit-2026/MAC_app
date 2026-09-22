//
//  FocusSessionView.swift
//  Focus Bear
//
//  The ongoing-focus-session screen (Figma "1. Ongoing Session"), hosted by focusModeStateVc. Replaces
//  the storyboard scene of the same name: countdown, duration +/-, pause/resume/end, the focus goal,
//  and the session's task queue with an active-task card.
//
//  Every measurement comes from FocusSessionScale so the whole screen re-proportions from the window
//  width instead of hardcoding points (see FocusSessionTokens).
//

import SwiftUI

@available(macOS 11.0, *)
struct FocusSessionScreen: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            let layout = FocusSessionViewportLayout(size: geometry.size)
            let scale = layout.scale
            Group {
                if layout.isWide {
                    desktopContent(layout: layout)
                        .frame(height: layout.contentHeight, alignment: .top)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        stackedContent(scale: scale, isCompact: layout.isCompact, contentWidth: layout.contentWidth)
                            .padding(.leading, scale.pt(FocusSessionLayout.screenPadding))
                            .padding(.trailing, scale.pt(FocusSessionLayout.screenPadding))
                    }
                    .frame(height: layout.contentHeight)
                }
            }
            .padding(.top, scale.pt(FocusSessionLayout.contentTopPadding))
            .padding(.bottom, scale.pt(FocusSessionLayout.screenPadding))
            .frame(width: layout.contentWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(FocusSessionPalette.screenBackground)
        .sheet(item: $store.activeSheet) { sheet in
            switch sheet {
            case .taskPicker: FocusSessionTaskPickerSheet(store: store)
            case .endSessionConfirm: FocusSessionEndConfirmSheet(store: store)
            case .editTask: FocusSessionEditTaskSheet(store: store)
            case .notes: FocusSessionNotesSheet(store: store)
            case .music: FocusSessionMusicSheet(store: store)
            }
        }
    }

    private func desktopContent(layout: FocusSessionViewportLayout) -> some SwiftUI.View {
        let scale = layout.scale
        return HStack(alignment: .top, spacing: scale.pt(FocusSessionLayout.columnGap)) {
            if layout.showsSideRail {
                ScrollView(.vertical, showsIndicators: false) {
                    FocusSessionSideRail(store: store, scale: scale)
                }
                .frame(width: scale.pt(FocusSessionSideRail.widthDesignPixels))
                .padding(.top, layout.sidePanelTopOffset)
            }
            ScrollView(.vertical, showsIndicators: false) {
                sessionColumn(scale: scale, isCompact: layout.isCompact,
                              availableWidth: layout.sessionColumnWidth)
            }
            .frame(width: layout.sessionColumnWidth)
            FocusSessionTaskPanel(store: store, scale: scale, scrolls: true)
                .frame(width: layout.taskPanelWidth)
                .padding(.top, layout.sidePanelTopOffset)
        }
        .padding(.leading, layout.showsSideRail ? 0 : scale.pt(FocusSessionLayout.screenPadding))
        .padding(.trailing, scale.pt(FocusSessionLayout.screenPadding))
    }

    private func stackedContent(scale: FocusSessionScale, isCompact: Bool, contentWidth: CGFloat) -> some SwiftUI.View {
        VStack(alignment: .center, spacing: scale.pt(isCompact ? FocusSessionLayout.cardGap
                                                                   : FocusSessionLayout.sectionGap)) {
                // Stacked and short: the active task comes first. It is what the session is for, and
                // it was falling below the fold underneath the illustration and the session card.
                if isCompact {
                    FocusSessionHeader(store: store, scale: scale, isCompact: true)
                    FocusSessionTaskPanel(store: store, scale: scale, showsQueue: false, isCompact: true)
                    timingRow(scale: scale, availableWidth: stackedWidth(scale: scale, contentWidth: contentWidth))
                    FocusSessionGoalCard(store: store, scale: scale)
                    FocusSessionTaskPanel(store: store, scale: scale, showsActive: false, isCompact: true)
                } else {
                    sessionColumn(scale: scale,
                                  isCompact: false,
                                  availableWidth: stackedWidth(scale: scale, contentWidth: contentWidth))
                    FocusSessionTaskPanel(store: store, scale: scale)
                }
                quickTools(scale: scale)
            }
    }

    private func quickTools(scale: FocusSessionScale) -> some SwiftUI.View {
        HStack {
            SwiftUI.Button { store.activeSheet = .music } label: {
                SwiftUI.Label(store.strings.focusMusicLabel, systemImage: "music.note")
            }
            SwiftUI.Button(action: store.presentNotesLightbox) {
                SwiftUI.Label(store.strings.notesLabel, systemImage: "note.text")
            }
        }.font(scale.font(FocusSessionLayout.rowTitleFont))
    }

    /// The session column is centred in its half, as in the design; the task panel beside it stretches.
    private func sessionColumn(scale: FocusSessionScale, isCompact: Bool, availableWidth: CGFloat) -> some SwiftUI.View {
        VStack(spacing: scale.pt(isCompact ? FocusSessionLayout.rowGap : FocusSessionLayout.cardGap)) {
            FocusSessionHeader(store: store, scale: scale, isCompact: isCompact)
            // The design's focus bear sits between the countdown and the session card, full width. In a
            // short window that costs vertical space the active task needs, so the bear moves beside
            // the timing card instead of above it — see timingRow.
            if !isCompact {
                bear(scale: scale, width: nil)
            }
            if isCompact {
                timingRow(scale: scale, availableWidth: availableWidth)
            } else {
                FocusSessionTimerPanel(store: store, scale: scale)
            }
            FocusSessionGoalCard(store: store, scale: scale)
            if isCompact { quickTools(scale: scale) }
        }
        .frame(maxWidth: .infinity)
    }

    /// The timing card in a short window: half the row, with the bear beside it on the left.
    ///
    /// The user's instruction, over the earlier behaviour of dropping the illustration outright:
    /// "we can still have the bear animation - the timing section could be half the width and the bear
    /// could be on the left". The bear is on the LEFT deliberately — the Figma frames put the
    /// illustration on the right, and the user's description wins where the two disagree, so do not
    /// "fix" this back to the design. Below the side-by-side floor the bear is dropped again rather
    /// than squashed, and the card goes back to full width.
    @ViewBuilder
    private func timingRow(scale: FocusSessionScale, availableWidth: CGFloat) -> some SwiftUI.View {
        if let bearWidth = FocusSessionCompactLayout.bearWidth(availableWidth: availableWidth, scale: scale) {
            HStack(alignment: .center, spacing: scale.pt(FocusSessionLayout.cardGap)) {
                bear(scale: scale, width: bearWidth)
                FocusSessionTimerPanel(store: store, scale: scale, isCompact: true)
                    .frame(maxWidth: .infinity)
            }
        } else {
            FocusSessionTimerPanel(store: store, scale: scale, isCompact: true)
        }
    }

    /// Greyed out while the session is paused, wherever it is drawn.
    private func bear(scale: FocusSessionScale, width: CGFloat?) -> some SwiftUI.View {
        FocusSessionBear(scale: scale, width: width)
            .saturation(store.phase == .paused ? 0 : 1)
            .opacity(store.phase == .paused ? 0.6 : 1)
    }

    /// The width a stacked (single-column) layout actually has for its content.
    private func stackedWidth(scale: FocusSessionScale, contentWidth: CGFloat) -> CGFloat {
        max(0, contentWidth - scale.pt(FocusSessionLayout.screenPadding) * 2)
    }

}

// MARK: - Header

@available(macOS 11.0, *)
private struct FocusSessionHeader: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    @SwiftUI.ObservedObject private var browserPermissions = BrowserAutomationStatus.shared
    let scale: FocusSessionScale
    var isCompact = false

    var body: some SwiftUI.View {
        VStack(spacing: isCompact ? 0 : scale.pt(FocusSessionLayout.tightGap)) {
            Text(store.headlineTitle)
                .font(scale.font(isCompact ? FocusSessionLayout.sectionFont : FocusSessionLayout.titleFont))
                .foregroundColor(FocusSessionPalette.primaryText)
            if store.showsCountdown {
                Text(store.countdownText)
                    .font(scale.font(isCompact ? FocusSessionLayout.titleFont
                                               : FocusSessionLayout.headlineFont, .medium))
                    .foregroundColor(store.phase == .paused
                                     ? FocusSessionPalette.secondaryText
                                     : FocusSessionPalette.accent)
            }
            if !browserPermissions.deniedBrowsers.isEmpty {
                browserPermissionWarning
                    .padding(.top, scale.pt(FocusSessionLayout.rowGap))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var browserPermissionWarning: some SwiftUI.View {
        let names = browserPermissions.deniedBrowsers.sorted { $0.rawValue < $1.rawValue }
            .compactMap { getCurrentBrowserNameFrom(browser: $0) }.joined(separator: ", ")
        return VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.rowGap)) {
            HStack(alignment: .top, spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(FocusSessionPalette.accent)
                Text(store.strings.browserPermissionMessage.replacingOccurrences(of: "<APPNAME>", with: names))
                    .foregroundColor(FocusSessionPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SwiftUI.Button(store.strings.openAutomationPreferences) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .font(scale.font(FocusSessionLayout.rowTitleFont))
        .padding(scale.pt(FocusSessionLayout.cardPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
            .fill(FocusSessionPalette.accent.opacity(0.1)))
    }
}

// MARK: - Timer panel

@available(macOS 11.0, *)
private struct FocusSessionTimerPanel: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale
    var isCompact = false

    var body: some SwiftUI.View {
        VStack(spacing: scale.pt(isCompact ? FocusSessionLayout.compactPanelPadding : FocusSessionLayout.cardGap)) {
            Text(store.workTitle)
                .font(scale.font(isCompact ? FocusSessionLayout.sectionFont : FocusSessionLayout.headlineFont, .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(isCompact ? 3 : nil)
                .foregroundColor(FocusSessionPalette.primaryText)
            if store.workTitle != store.focusModeName {
                // Changeable unless the session is super-strict or run by a teacher — swapping to a
                // laxer list mid-session is exactly what super-strict exists to prevent
                // (report 2026-09-11_10-15-13).
                if store.canChangeBlockList, !store.switchableBlockLists.isEmpty {
                    Menu {
                        ForEach(store.switchableBlockLists, id: \.id) { list in
                            SwiftUI.Button(list.name) { store.switchBlockList(toId: list.id) }
                        }
                    } label: {
                        Text(store.strings.blockListLabel + " " + store.focusModeName)
                            .font(scale.font(FocusSessionLayout.badgeFont))
                            .foregroundColor(FocusSessionPalette.secondaryText)
                    }
                    .menuStyle(BorderlessButtonMenuStyle())
                    .fixedSize()
                    .help(store.strings.changeBlockList)
                } else {
                    Text(store.strings.blockListLabel + " " + store.focusModeName)
                        .font(scale.font(FocusSessionLayout.badgeFont)).foregroundColor(FocusSessionPalette.secondaryText)
                }
            }
            if store.showsCountdown {
                progressRow
            }
            controlRow
            endSessionLink
        }
        .padding(scale.pt(isCompact ? FocusSessionLayout.compactPanelPadding : FocusSessionLayout.panelPadding))
        .frame(maxWidth: .infinity)
        .background(panelChrome)
    }

    private var progressRow: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
            FocusSessionProgressBar(progress: store.progress, scale: scale)
            // "5 min of 30 min" rather than a bare pair of timestamps, which read as a puzzle.
            Text(store.progressText)
                .font(scale.font(FocusSessionLayout.badgeFont, .medium))
                .foregroundColor(FocusSessionPalette.secondaryText)
        }
    }

    private var controlRow: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
            if store.showsDurationControls {
                adjustButton(label: "-\(focusSessionDurationStepMinutes)",
                             tooltip: store.strings.reduceDurationTooltip,
                             isEnabled: !store.isDurationLocked,
                             action: store.reduceSession)
            }
            primaryControls
            if store.showsDurationControls {
                adjustButton(label: "+\(focusSessionDurationStepMinutes)",
                             tooltip: store.strings.extendDurationTooltip,
                             isEnabled: true,
                             action: store.extendSession)
            }
        }
    }

    @ViewBuilder
    private var primaryControls: some SwiftUI.View {
        switch store.phase {
        case .paused:
            HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
                circleControl(symbol: "play.fill", tooltip: store.strings.resumeTooltip, action: store.resumeSession)
                circleControl(symbol: "stop.fill", tooltip: store.strings.endSessionTooltip, action: store.requestEndSession)
            }
        case .running:
            circleControl(symbol: "pause.fill", tooltip: store.strings.pauseTooltip, action: store.pauseSession)
        case .superFocus, .idle:
            circleControl(symbol: "stop.fill", tooltip: store.strings.endSessionTooltip, action: store.requestEndSession)
        }
    }

    /// The design only offers pause while a session is running — you stop from the paused state. The
    /// storyboard screen this replaces let you stop directly, so keep that as a quiet text action
    /// rather than dropping the behaviour.
    @ViewBuilder
    private var endSessionLink: some SwiftUI.View {
        if store.phase == .running {
            SwiftUI.Button(action: store.requestEndSession) {
                Text(store.strings.endSessionTooltip)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            }
            .buttonStyle(FBButtonStyle())
        }
    }

    private func circleControl(symbol: String, tooltip: String, action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Image(systemName: symbol)
                .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
                .frame(width: scale.pt(FocusSessionLayout.timerControlDiameter),
                       height: scale.pt(FocusSessionLayout.timerControlDiameter))
                .background(circleChrome)
        }
        .buttonStyle(FBButtonStyle())
        .help(tooltip)
    }

    private func adjustButton(label: String,
                              tooltip: String,
                              isEnabled: Bool,
                              action: @escaping () -> Void) -> some SwiftUI.View {
        SwiftUI.Button(action: action) {
            VStack(spacing: 0) {
                Text(label)
                    .font(scale.font(FocusSessionLayout.taskTitleFont, .bold))
                    .foregroundColor(FocusSessionPalette.primaryText)
                Text(store.strings.minutesShortLabel)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            }
            .frame(width: scale.pt(FocusSessionLayout.adjustControlDiameter),
                   height: scale.pt(FocusSessionLayout.adjustControlDiameter))
            .background(circleChrome)
        }
        .buttonStyle(FBButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .help(isEnabled ? tooltip : store.strings.durationLockedInSuperStrictNotice)
    }

    private var circleChrome: some SwiftUI.View {
        Circle()
            .fill(FocusSessionPalette.cardBackground)
            .overlay(Circle().strokeBorder(FocusSessionPalette.border, lineWidth: scale.pt(FocusSessionLayout.hairline)))
            .focusSessionShadow(scale, blur: FocusSessionShadow.controlBlurDesignPixels)
    }

    private var panelChrome: some SwiftUI.View {
        RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.panelCornerRadius))
            .fill(FocusSessionPalette.panelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.panelCornerRadius))
                    .strokeBorder(FocusSessionPalette.border, lineWidth: scale.pt(FocusSessionLayout.panelHairline))
            )
    }
}

/// The session progress bar. Drawn by hand rather than with ProgressView so it keeps the design's
/// height and fully-rounded caps at every scale.
@available(macOS 11.0, *)
private struct FocusSessionProgressBar: SwiftUI.View {
    let progress: Double
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        GeometryReader { geometry in
            let height = scale.pt(FocusSessionLayout.progressBarHeight)
            ZStack(alignment: .leading) {
                Capsule().fill(FocusSessionPalette.mutedFill)
                Capsule()
                    .fill(FocusSessionPalette.accent)
                    .frame(width: max(0, geometry.size.width * CGFloat(progress)))
            }
            .frame(height: height)
        }
        .frame(height: scale.pt(FocusSessionLayout.progressBarHeight))
    }
}

// MARK: - Focus goal

@available(macOS 11.0, *)
private struct FocusSessionGoalCard: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    @SwiftUI.State private var isExpanded = false
    let scale: FocusSessionScale

    /// Enough room for a sentence or two without dominating the column.
    private static let editorHeightDesignPixels: CGFloat = 260

    var body: some SwiftUI.View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                goalEditor
                if store.isGoalLocked {
                    Text(store.strings.focusGoalLockedNotice)
                        .font(scale.font(FocusSessionLayout.badgeFont))
                        .foregroundColor(FocusSessionPalette.secondaryText)
                }
            }.padding(.top, scale.pt(FocusSessionLayout.inlineGap))
        } label: {
            VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
                Text(store.strings.focusGoalLabel)
                    .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                    .foregroundColor(FocusSessionPalette.primaryText)
                if !isExpanded, !store.focusGoal.isEmpty {
                    Text(store.focusGoal)
                        .font(scale.font(FocusSessionLayout.badgeFont))
                        .foregroundColor(FocusSessionPalette.secondaryText)
                        .lineLimit(2)
                }
            }
        }
        .padding(scale.pt(FocusSessionLayout.cardPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardChrome(scale: scale))
    }

    @ViewBuilder
    private var goalEditor: some SwiftUI.View {
        if store.isGoalLocked {
            Text(store.focusGoal.isEmpty ? store.strings.focusGoalPlaceholder : store.focusGoal)
                .font(scale.font(FocusSessionLayout.bodyFont))
                .foregroundColor(FocusSessionPalette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            TextEditor(text: $store.focusGoal)
                .font(scale.font(FocusSessionLayout.bodyFont))
                .frame(height: scale.pt(Self.editorHeightDesignPixels))
        }
    }
}

// MARK: - Task panel

@available(macOS 11.0, *)
private struct FocusSessionTaskPanel: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale
    var showsActive = true
    var showsQueue = true
    var isCompact = false
    var scrolls = false

    var body: some SwiftUI.View {
        Group {
            if scrolls {
                ScrollView(.vertical, showsIndicators: true) { panelContent }
            } else { panelContent }
        }
        .frame(maxHeight: scrolls ? .infinity : nil, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.panelCornerRadius))
                .fill(FocusSessionPalette.panelBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.panelCornerRadius))
                        .strokeBorder(FocusSessionPalette.border,
                                      lineWidth: scale.pt(FocusSessionLayout.panelHairline))
                )
        )
    }

    private var panelContent: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.sectionGap)) {
            if let error = store.taskEditError { Text(error).foregroundColor(FocusSessionPalette.destructive) }
            if showsActive { activeSection }
            if showsQueue { queueSection }
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var activeSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
                Text(store.strings.activeTaskLabel)
                    .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                    .foregroundColor(FocusSessionPalette.primaryText)
                Circle()
                    .fill(FocusSessionPalette.accent)
                    .frame(width: scale.pt(FocusSessionLayout.inlineGap),
                           height: scale.pt(FocusSessionLayout.inlineGap))
            }
            activeCard
        }
    }

    @ViewBuilder
    private var activeCard: some SwiftUI.View {
        if let active = store.activeTask {
            VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
                HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    if let emoji = active.iconEmoji {
                        Text(emoji).font(scale.font(FocusSessionLayout.headlineFont))
                    }
                    FocusSessionSelectableText(text: active.title,
                                               font: scale.font(FocusSessionLayout.taskTitleFont, .semibold),
                                               lineLimit: isCompact ? 3 : nil)
                        .foregroundColor(FocusSessionPalette.primaryText)
                    Spacer(minLength: 0)
                    SwiftUI.Button(action: { store.editTask(id: active.id) }) {
                        Image(systemName: "square.and.pencil")
                            .font(scale.font(FocusSessionLayout.rowTitleFont))
                            .foregroundColor(FocusSessionPalette.secondaryText)
                    }
                    .buttonStyle(FBButtonStyle())
                    .disabled(store.isTaskEditingLocked)
                    .opacity(store.isTaskEditingLocked ? 0.4 : 1)
                    .help(store.strings.editTaskMenuItem)
                }
                HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                    if let project = active.projectName, !project.isEmpty, project != store.workTitle {
                        FocusSessionProjectChip(name: project, scale: scale, icon: store.projectIcon(named: project))
                    }
                    if let score = active.topScore {
                        FocusSessionTopScoreBadge(score: score, strings: store.strings, scale: scale)
                    }
                    FocusSessionDurationBadge(minutes: active.durationMinutes, strings: store.strings, scale: scale)
                }
                // The design distinguishes the active task only by the heading above the card. This
                // adds the running state and the time on it to the card itself — a deliberate
                // departure from frames 4:81633 / 4:81826, which show neither.
                FocusSessionRunningIndicator(isRunning: store.isTaskRunning,
                                             label: store.timeOnTaskText,
                                             scale: scale)
                if !active.details.isEmpty {
                    // Selectable: task notes are often a link to the document the task is about,
                    // and it was impossible to copy one out of here.
                    FocusSessionSelectableText(text: active.details,
                                               font: scale.font(FocusSessionLayout.bodyFont),
                                               lineLimit: isCompact ? 3 : nil)
                        .foregroundColor(FocusSessionPalette.primaryText)
                }
                FocusSessionAttachmentsView(taskID: active.id, scale: scale)
                    .id(active.id)
                FocusSessionSubtasksView(store: store, scale: scale)
                // Sized to its label rather than the design's full-width bar: completing the task is
                // one of several things you can do here and shouldn't be the loudest thing on screen.
                HStack {
                    SwiftUI.Button(action: store.markActiveTaskComplete) {
                        HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
                            Image(systemName: "checkmark")
                                .font(scale.font(FocusSessionLayout.badgeFont, .semibold))
                            Text(store.strings.markCompleteButton)
                                .font(scale.font(FocusSessionLayout.rowTitleFont, .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, scale.pt(FocusSessionLayout.taskCardPadding))
                        .frame(height: scale.pt(FocusSessionLayout.compactButtonHeight))
                        .background(
                            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                                .fill(FocusSessionPalette.accent)
                        )
                    }
                    .buttonStyle(FBButtonStyle())
                    .disabled(store.isTaskEditingLocked || store.isSavingSubtask)
                    .opacity(store.isTaskEditingLocked || store.isSavingSubtask ? 0.5 : 1)
                    Spacer(minLength: 0)
                }
            }
            .padding(scale.pt(FocusSessionLayout.taskCardPadding))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.taskCardCornerRadius))
                    .fill(FocusSessionPalette.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.taskCardCornerRadius))
                            .strokeBorder(FocusSessionPalette.border,
                                          lineWidth: scale.pt(FocusSessionLayout.hairline))
                    )
                    .focusSessionShadow(scale)
            )
        } else {
            // The empty state is the whole card, not a caption: "it should let me click to add a task
            // and have it bring up the task selection modal" (report 2026-09-15_16-46-10). It opens the
            // same picker the queue's + button does.
            SwiftUI.Button(action: store.presentTaskPicker) {
                HStack(alignment: .top, spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                    VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
                        Text(store.strings.noActiveTaskTitle)
                            .font(scale.font(FocusSessionLayout.taskTitleFont, .semibold))
                            .foregroundColor(FocusSessionPalette.primaryText)
                        Text(store.strings.noActiveTaskBody)
                            .font(scale.font(FocusSessionLayout.bodyFont))
                            .foregroundColor(FocusSessionPalette.secondaryText)
                        SwiftUI.Label(store.strings.addTaskButton, systemImage: "plus.circle.fill")
                            .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                            .foregroundColor(FocusSessionPalette.accent)
                    }
                    Spacer(minLength: 0)
                }
                .padding(scale.pt(FocusSessionLayout.taskCardPadding))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardChrome(scale: scale))
                .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
            .disabled(store.isTaskEditingLocked)
            .opacity(store.isTaskEditingLocked ? 0.5 : 1)
            .help(store.strings.addTasksTooltip)
        }
    }

    private var queueSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            HStack {
                Text(store.strings.taskQueueHeading(count: store.outstandingQueuedTasks.count))
                    .font(scale.font(FocusSessionLayout.sectionFont))
                    .foregroundColor(FocusSessionPalette.primaryText)
                Spacer()
                SwiftUI.Button(action: store.presentTaskPicker) {
                    Image(systemName: "plus")
                        .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                        .foregroundColor(FocusSessionPalette.invertedText)
                        .frame(width: scale.pt(FocusSessionLayout.timerControlDiameter / 3),
                               height: scale.pt(FocusSessionLayout.timerControlDiameter / 3))
                        .background(
                            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                                .fill(FocusSessionPalette.primaryText)
                        )
                }
                .buttonStyle(FBButtonStyle())
                .disabled(store.isTaskEditingLocked)
                .opacity(store.isTaskEditingLocked ? 0.5 : 1)
                .help(store.strings.addTasksTooltip)
            }
            if store.queuedTasks.isEmpty {
                Text(store.strings.emptyQueueLabel)
                    .font(scale.font(FocusSessionLayout.bodyFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            } else {
                VStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    ForEach(store.queuedTasks) { task in
                        FocusSessionQueueRow(store: store, task: task, scale: scale)
                    }
                }
            }
        }
    }
}

/// The active card's subtasks use the existing task record, with each change confirmed by the
/// server before replacing the displayed values. Failed writes keep the add-field draft intact.
private struct FocusSessionSubtasksView: SwiftUI.View {
    @ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale

    private var busy: Bool { store.isLoadingSubtasks || store.isSavingSubtask }

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.inlineGap)) {
            if store.isLoadingSubtasks {
                ProgressView().scaleEffect(0.65).frame(height: scale.pt(FocusSessionLayout.rowGap))
            }
            addSubtaskField
            ForEach(store.activeSubtasks.indices, id: \.self) { index in
                HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                    Toggle(isOn: Binding(
                        get: { store.activeSubtasks[index].is_completed },
                        set: { store.setSubtaskCompleted(at: index, completed: $0) }
                    )) {
                        Text(store.activeSubtasks[index].name)
                            .font(scale.font(FocusSessionLayout.rowTitleFont))
                            .strikethrough(store.activeSubtasks[index].is_completed)
                            .foregroundColor(FocusSessionPalette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }.toggleStyle(CheckboxToggleStyle())
                    Spacer(minLength: 0)
                    SwiftUI.Button(action: { store.removeSubtask(at: index) }) {
                        Image(systemName: "trash")
                            .font(scale.font(FocusSessionLayout.bodyFont))
                            .foregroundColor(FocusSessionPalette.secondaryText)
                    }.buttonStyle(FBButtonStyle()).help(store.strings.removeSubtask)
                }
                .padding(scale.pt(FocusSessionLayout.inlineGap))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                        .strokeBorder(FocusSessionPalette.border, lineWidth: scale.pt(FocusSessionLayout.hairline))
                )
                .disabled(busy || store.isTaskEditingLocked)
            }
            if let error = store.subtaskError {
                Text(error).font(scale.font(FocusSessionLayout.bodyFont)).foregroundColor(.red)
                SwiftUI.Button(store.strings.retryButton) { store.loadActiveSubtasks(force: true) }
                    .font(scale.font(FocusSessionLayout.bodyFont)).disabled(busy)
            }
        }
    }

    private var addSubtaskField: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
            SwiftUI.Button(action: store.addSubtask) {
                Image(systemName: "plus")
                    .font(scale.font(FocusSessionLayout.rowTitleFont, .medium))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            }.buttonStyle(FBButtonStyle()).help(store.strings.addSubtask)
                .disabled(store.subtaskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            TextField(store.strings.subtaskPlaceholder, text: $store.subtaskName, onCommit: store.addSubtask)
                .textFieldStyle(PlainTextFieldStyle())
                .font(scale.font(FocusSessionLayout.rowTitleFont))
        }
        .padding(scale.pt(FocusSessionLayout.cardPadding))
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                .fill(FocusSessionPalette.mutedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                        .strokeBorder(FocusSessionPalette.border,
                                      style: StrokeStyle(lineWidth: scale.pt(FocusSessionLayout.hairline), dash: [3]))
                )
        )
        .disabled(busy || store.isTaskEditingLocked || store.subtaskError != nil)
    }
}

@available(macOS 11.0, *)
private struct FocusSessionQueueRow: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let task: FocusSessionTask
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
            if let emoji = task.iconEmoji {
                Text(emoji).font(scale.font(FocusSessionLayout.taskTitleFont))
            }
            VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
                titleText
                HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                    if let score = task.topScore {
                        FocusSessionTopScoreBadge(score: score, strings: store.strings, scale: scale)
                    }
                    FocusSessionDurationBadge(minutes: task.durationMinutes, strings: store.strings, scale: scale)
                }
            }
            Spacer(minLength: scale.pt(FocusSessionLayout.inlineGap))
            rowMenu
        }
        .padding(.vertical, scale.pt(FocusSessionLayout.cardPadding))
        .padding(.leading, scale.pt(FocusSessionLayout.cardPaddingLeading))
        .padding(.trailing, scale.pt(FocusSessionLayout.cardPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardChrome(scale: scale))
    }

    @ViewBuilder
    private var titleText: some SwiftUI.View {
        if task.status.isCompleted {
            Text(task.title)
                .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                .foregroundColor(FocusSessionPalette.secondaryText)
                .strikethrough(true)
        } else {
            Text(task.title)
                .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
        }
    }

    /// The design's per-row overflow menu. "Move up"/"Move down" stand in for its drag handle —
    /// reordering by drag is not implemented (see the PR description).
    private var rowMenu: some SwiftUI.View {
        Menu {
            if !task.status.isCompleted {
                SwiftUI.Button(action: { store.completeTask(id: task.id) }) {
                    Label(store.strings.menuMarkComplete, systemImage: "checkmark.circle")
                }
                SwiftUI.Button(action: { store.focusOnTask(id: task.id) }) {
                    Label(store.strings.menuFocusOnThisInstead, systemImage: "target")
                }
            }
            SwiftUI.Button(action: { store.editTask(id: task.id) }) {
                Label(store.strings.editTaskMenuItem, systemImage: "pencil")
            }
            if store.canMoveTask(id: task.id, by: -1) {
                SwiftUI.Button(action: { store.moveTask(id: task.id, by: -1) }) {
                    Label(store.strings.menuMoveUp, systemImage: "arrow.up")
                }
            }
            if store.canMoveTask(id: task.id, by: 1) {
                SwiftUI.Button(action: { store.moveTask(id: task.id, by: 1) }) {
                    Label(store.strings.menuMoveDown, systemImage: "arrow.down")
                }
            }
            SwiftUI.Button(action: { store.removeTask(id: task.id) }) {
                Label(store.strings.menuRemoveFromQueue, systemImage: "minus.circle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(scale.font(FocusSessionLayout.rowTitleFont))
                .foregroundColor(FocusSessionPalette.secondaryText)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        // macOS draws menu labels title-only unless the style says otherwise, so a systemImage on a
        // menu item is specified and then silently never rendered (report 2026-09-15_16-53-24).
        .menuItemIcons()
        .modifier(HiddenMenuIndicator())
        .frame(width: scale.pt(FocusSessionLayout.menuButtonWidth), alignment: .trailing)
        .disabled(store.isTaskEditingLocked)
        .opacity(store.isTaskEditingLocked ? 0.4 : 1)
    }
}

/// The card's own running state: a pulsing accent dot plus how long the task has been active this
/// session. Shown greyed and static when the session is paused.
@available(macOS 11.0, *)
/// Text the user can select and copy. `Text` alone cannot be selected, and task notes are often a
/// link to the document the task is about — there was no way to get one out of the card.
/// `.textSelection` is macOS 12+, so below that this falls back to plain `Text`; the app still
/// supports macOS 11 (Auth0 / TweetNacl).
@available(macOS 11.0, *)
private struct FocusSessionSelectableText: SwiftUI.View {
    let text: String
    let font: Font
    var lineLimit: Int?

    var body: some SwiftUI.View {
        if #available(macOS 12.0, *) {
            SwiftUI.Text(text).font(font).lineLimit(lineLimit).textSelection(.enabled)
        } else {
            SwiftUI.Text(text).font(font).lineLimit(lineLimit)
        }
    }
}

private struct FocusSessionRunningIndicator: SwiftUI.View {
    let isRunning: Bool
    let label: String
    let scale: FocusSessionScale

    private static let dotDesignPixels: CGFloat = 20
    @SwiftUI.State private var isPulsing = false

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
            Circle()
                .fill(isRunning ? FocusSessionPalette.accent : FocusSessionPalette.secondaryText)
                .frame(width: scale.pt(Self.dotDesignPixels), height: scale.pt(Self.dotDesignPixels))
                .opacity(isRunning && isPulsing ? 0.35 : 1)
                .animation(isRunning ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : nil)
            Text(label)
                .font(scale.font(FocusSessionLayout.badgeFont, .medium))
                .foregroundColor(isRunning ? FocusSessionPalette.accent : FocusSessionPalette.secondaryText)
        }
        .onAppear { isPulsing = isRunning }
    }
}

/// The design's orange "DURATION: 30 MINS" pill.
@available(macOS 11.0, *)
struct FocusSessionDurationBadge: SwiftUI.View {
    let minutes: Int
    let strings: FocusSessionStrings
    let scale: FocusSessionScale

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
            Image(systemName: "clock")
                .font(scale.font(FocusSessionLayout.badgeFont))
            Text(strings.durationBadge(minutes: minutes))
                .font(scale.font(FocusSessionLayout.badgeFont, .semibold))
        }
        .foregroundColor(FocusSessionPalette.accent)
        .padding(.horizontal, scale.pt(FocusSessionLayout.cardPadding))
        .padding(.vertical, scale.pt(FocusSessionLayout.tightGap))
        .background(
            Capsule().fill(FocusSessionPalette.accent.opacity(0.15))
        )
    }
}

// MARK: - Shared chrome

/// The design's overflow menu is a bare glyph. `menuIndicator` only exists from macOS 12, so on 11 the
/// disclosure chevron stays — a cosmetic difference, not a functional one.
@available(macOS 11.0, *)
private struct HiddenMenuIndicator: ViewModifier {
    func body(content: Content) -> some SwiftUI.View {
        if #available(macOS 12.0, *) {
            content.menuIndicator(.hidden)
        } else {
            content
        }
    }
}

/// The bordered white card used for every task row and secondary panel in the design.
@available(macOS 11.0, *)
func cardChrome(scale: FocusSessionScale) -> some SwiftUI.View {
    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
        .fill(FocusSessionPalette.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                .strokeBorder(FocusSessionPalette.border, lineWidth: scale.pt(FocusSessionLayout.hairline))
        )
        .focusSessionShadow(scale)
}

/// The active task's files use the same authenticated loading and in-app preview as task details.
/// Identity follows the active to-do, so switching tasks cannot leave the prior task's files visible.
@available(macOS 11.0, *)
private struct FocusSessionAttachmentsView: SwiftUI.View {
    @StateObject private var attachments: ToDoAttachmentsStore
    @SwiftUI.State private var previewedAttachment: ToDoAttachment?
    private let strings: ToDoStrings
    let scale: FocusSessionScale

    init(taskID: String, scale: FocusSessionScale) {
        let strings = ToDoStrings.load()
        self.strings = strings
        self.scale = scale
        _attachments = StateObject(wrappedValue: ToDoAttachmentsStore(taskId: taskID, strings: strings, showStatus: { _ in }))
    }

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
            if !attachments.attachments.isEmpty {
                Text(strings[.attachments])
                    .font(scale.font(FocusSessionLayout.bodyFont, .semibold))
                    .foregroundColor(FocusSessionPalette.primaryText)
                ToDoAttachmentsList(store: attachments, strings: strings, unavailableMessage: "",
                                    maximumListHeight: scale.pt(160), allowsEditing: false,
                                    onPreview: { previewedAttachment = $0 })
            }
        }
        .onAppear { attachments.load() }
        .sheet(item: $previewedAttachment) { attachment in
            ToDoAttachmentPreviewSheet(attachment: attachment, strings: strings) { previewedAttachment = nil }
        }
    }
}
