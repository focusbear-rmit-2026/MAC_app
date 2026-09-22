//
//  FocusSessionSheets.swift
//  Focus Bear
//
//  The modals of the ongoing-focus-session screen:
//    • "Select Tasks"      (Figma 1.2)   — search + tick existing to-dos, then queue them
//    • "Create new task"   (Figma 1.2.1) — a second page of the same sheet, reached by its footer
//    • "End session early?"(Figma 1.1A)  — the confirmation in front of the paused session
//

import SwiftUI

// MARK: - Select tasks / create task

@available(macOS 11.0, *)
struct FocusSessionTaskPickerSheet: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore

    /// The sheet is a panel at the design's dialog width (1180 design pixels); its height is capped to
    /// the screen by `focusSessionSheetFrame` so the footer buttons cannot fall off a short display.
    private static let sheetWidthDesignPixels: CGFloat = 1180
    private static let rowHeightDesignPixels: CGFloat = 130

    private var scale: FocusSessionScale {
        FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
    }

    var body: some SwiftUI.View {
        Group {
            switch store.pickerPage {
            case .selectTasks: selectTasksPage
            case .createTask: createTaskPage
            case .filters: FocusSessionFiltersPage(store: store, scale: scale)
            }
        }
        .focusSessionSheetFrame(widthDesignPixels: Self.sheetWidthDesignPixels, scale: scale)
        .background(FocusSessionPalette.panelBackground)
    }

    // MARK: Select tasks

    private var selectTasksPage: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            header
            searchRow
            sourceCaption
            taskList
            footer
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
    }

    private var searchRow: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            FocusSessionSearchField(placeholder: store.strings.searchTaskPlaceholder,
                                    text: $store.pickerQuery,
                                    scale: scale,
                                    onCommit: store.runPickerSearch)
            SwiftUI.Button(action: store.presentFilters) {
                Image(systemName: store.appliedFilters.isEmpty
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                    .font(scale.font(FocusSessionLayout.sectionFont))
                    .foregroundColor(store.appliedFilters.isEmpty
                                     ? FocusSessionPalette.primaryText
                                     : FocusSessionPalette.accent)
                    .padding(scale.pt(FocusSessionLayout.cardPadding))
                    .background(cardChrome(scale: scale))
            }
            .buttonStyle(FBButtonStyle())
            .help(store.strings.filterTasksTooltip)
        }
    }

    /// Says which list is on screen — the Day Plan, the to-do list, or a search across all to-dos.
    private var sourceCaption: some SwiftUI.View {
        Text(caption)
            .font(scale.font(FocusSessionLayout.badgeFont))
            .foregroundColor(FocusSessionPalette.secondaryText)
    }

    private var caption: String {
        switch store.pickerSource {
        case .dayPlan: return store.strings.pickerFromDayPlan
        case .toDoList: return store.strings.pickerFromToDoList
        case .search: return store.strings.pickerFromSearch
        }
    }

    @ViewBuilder
    private var taskList: some SwiftUI.View {
        if store.isLoadingPickerTasks {
            centeredMessage(store.strings.fetchingTasks)
        } else if store.visiblePickerTasks.isEmpty {
            centeredMessage(store.pickerSource == .search
                            ? store.strings.noMatchingTasks
                            : store.strings.noTasksToPick)
        } else {
            ScrollView {
                VStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                    ForEach(store.visiblePickerTasks) { task in
                        pickerRow(task)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func pickerRow(_ task: FocusSessionPickerTask) -> some SwiftUI.View {
        let isSelected = store.selectedPickerTaskIds.contains(task.id)
        return SwiftUI.Button(action: { store.togglePickerSelection(task.id) }) {
            HStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(isSelected ? FocusSessionPalette.accent : FocusSessionPalette.secondaryText)
                if let emoji = task.iconEmoji {
                    Text(emoji).font(scale.font(FocusSessionLayout.taskTitleFont))
                }
                VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.tightGap)) {
                    Text(task.title)
                        .font(scale.font(FocusSessionLayout.rowTitleFont, .semibold))
                        .foregroundColor(FocusSessionPalette.primaryText)
                        .lineLimit(1)
                    HStack(spacing: scale.pt(FocusSessionLayout.inlineGap)) {
                        if let project = task.projectName, !project.isEmpty {
                            FocusSessionProjectChip(name: project, scale: scale, icon: store.projectIcon(for: task))
                        }
                        if let score = task.topScore {
                            FocusSessionTopScoreBadge(score: score, strings: store.strings, scale: scale)
                        }
                        FocusSessionDurationBadge(
                            minutes: max(1, task.durationSeconds / FocusSessionClock.secondsPerMinute),
                            strings: store.strings,
                            scale: scale
                        )
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(scale.pt(FocusSessionLayout.cardPadding))
            .frame(maxWidth: .infinity, minHeight: scale.pt(Self.rowHeightDesignPixels), alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                    .fill(isSelected
                          ? FocusSessionPalette.accent.opacity(0.12)
                          : FocusSessionPalette.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                            .strokeBorder(isSelected ? FocusSessionPalette.accent : FocusSessionPalette.border,
                                          lineWidth: scale.pt(FocusSessionLayout.hairline))
                    )
            )
        }
        .buttonStyle(FBButtonStyle())
    }

    private var footer: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            SwiftUI.Button(action: { store.pickerPage = .createTask }) {
                HStack(spacing: scale.pt(FocusSessionLayout.tightGap)) {
                    Image(systemName: "plus")
                    Text(store.strings.createNewTaskButton)
                }
                .font(scale.font(FocusSessionLayout.rowTitleFont))
                .foregroundColor(FocusSessionPalette.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: scale.pt(FocusSessionLayout.primaryButtonHeight))
                .background(
                    RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                        .fill(FocusSessionPalette.mutedFill)
                )
            }
            .buttonStyle(FBButtonStyle())

            FocusSessionPrimaryButton(title: store.strings.queueTasksButton(count: store.selectedPickerTaskIds.count),
                                      scale: scale,
                                      isEnabled: !store.selectedPickerTaskIds.isEmpty,
                                      action: store.queueSelectedTasks)
        }
    }

    // MARK: Create task

    private var createTaskPage: some SwiftUI.View {
        FocusSessionCreateTaskPage(store: store, scale: scale)
    }

    // MARK: Shared

    private var header: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
            Text(store.strings.selectTasksTitle)
                .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
            Spacer()
            SwiftUI.Button(action: { store.activeSheet = nil }) {
                Image(systemName: "xmark")
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.secondaryText)
            }
            .buttonStyle(FBButtonStyle())
            .help(store.strings.closeButton)
        }
    }

    private func centeredMessage(_ message: String) -> some SwiftUI.View {
        Text(message)
            .font(scale.font(FocusSessionLayout.bodyFont))
            .foregroundColor(FocusSessionPalette.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Second page of the task sheet — the design's "Create new task" form. Shares its fields with the
/// edit sheet and posts through the same `PUT /to-do` upsert (without an id, so the server inserts).
@available(macOS 11.0, *)
private struct FocusSessionCreateTaskPage: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore
    let scale: FocusSessionScale

    @SwiftUI.State private var edits = FocusSessionTaskEdits()
    @SwiftUI.State private var didSeedDraft = false

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusSessionLayout.cardGap)) {
            HStack(spacing: scale.pt(FocusSessionLayout.rowGap)) {
                SwiftUI.Button(action: { store.pickerPage = .selectTasks }) {
                    Image(systemName: "arrow.left")
                        .font(scale.font(FocusSessionLayout.rowTitleFont))
                        .foregroundColor(FocusSessionPalette.primaryText)
                }
                .buttonStyle(FBButtonStyle())
                Text(store.strings.createTaskTitle)
                    .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                    .foregroundColor(FocusSessionPalette.primaryText)
                Spacer()
            }
            ScrollView {
                FocusSessionTaskForm(store: store, edits: $edits, scale: scale, showsStatus: false)
            }
            if store.editFailed {
                Text(store.strings.couldNotSaveTask)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.destructive)
            }
            FocusSessionSecondaryButton(title: store.strings.cancelButton, scale: scale) {
                store.pickerPage = .selectTasks
            }
            FocusSessionPrimaryButton(
                title: store.isSavingTask ? store.strings.savingTask : store.strings.createTaskButton,
                scale: scale,
                isEnabled: !store.isSavingTask && edits.isValid
            ) {
                store.createTask(edits) { _ in }
            }
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .onAppear {
            // `Date()` in a property initialiser would freeze at the sheet's first construction.
            guard !didSeedDraft else { return }
            didSeedDraft = true
            edits = store.newTaskDraft
        }
    }
}

// MARK: - End session confirmation

@available(macOS 11.0, *)
struct FocusSessionEndConfirmSheet: SwiftUI.View {
    @SwiftUI.ObservedObject var store: FocusSessionStore

    private static let sheetWidthDesignPixels: CGFloat = 660

    private var scale: FocusSessionScale {
        FocusSessionScale(contentWidth: FocusSessionTokens.designWidthPoints)
    }

    var body: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusSessionLayout.cardGap)) {
            Text(store.strings.endSessionConfirmTitle)
                .font(scale.font(FocusSessionLayout.sectionFont, .semibold))
                .foregroundColor(FocusSessionPalette.primaryText)
            Text(store.strings.endSessionConfirmBody)
                .font(scale.font(FocusSessionLayout.bodyFont))
                .multilineTextAlignment(.center)
                .foregroundColor(FocusSessionPalette.secondaryText)

            SwiftUI.Button(action: { store.activeSheet = nil }) {
                Text(store.strings.cancelButton)
                    .font(scale.font(FocusSessionLayout.rowTitleFont))
                    .foregroundColor(FocusSessionPalette.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: scale.pt(FocusSessionLayout.primaryButtonHeight))
                    .background(
                        RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                            .fill(FocusSessionPalette.mutedFill)
                    )
            }
            .buttonStyle(FBButtonStyle())

            SwiftUI.Button(action: store.endSession) {
                Text(store.strings.endSessionConfirmButton)
                    .font(scale.font(FocusSessionLayout.rowTitleFont, .medium))
                    .foregroundColor(FocusSessionPalette.invertedText)
                    .frame(maxWidth: .infinity)
                    .frame(height: scale.pt(FocusSessionLayout.primaryButtonHeight))
                    .background(
                        RoundedRectangle(cornerRadius: scale.pt(FocusSessionLayout.cardCornerRadius))
                            .fill(FocusSessionPalette.primaryText)
                    )
            }
            .buttonStyle(FBButtonStyle())
        }
        .padding(scale.pt(FocusSessionLayout.panelPadding))
        .frame(width: scale.pt(Self.sheetWidthDesignPixels))
        .background(FocusSessionPalette.panelBackground)
    }
}
