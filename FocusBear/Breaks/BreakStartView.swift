//
//  BreakStartView.swift
//  Focus Bear
//
//  The break start screen, in SwiftUI: the list of break habits, the chair-exercises /
//  full-movement toggle (the app's existing office / work-from-home setting), a brain dump beside the
//  list, and Start with an "automatically next time" checkbox under it.
//
//  Hosted by `breakStartVc` in an `NSHostingView`; see `BreakStartModel` for the behaviour.
//

import SwiftUI
import AppKit

struct BreakStartView: SwiftUI.View {

    @ObservedObject var model: BreakStartModel

    private static let contentWidth: CGFloat = 900
    private static let brainDumpWidth: CGFloat = 300
    private static let listMinHeight: CGFloat = 180
    private static let editorHeight: CGFloat = 200

    private var strings: BreakStartStrings { model.strings }

    var body: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 20) {
                header
                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 14) {
                        modePicker
                        habitList
                    }
                    brainDump
                        .frame(width: BreakStartView.brainDumpWidth)
                }
                startControls
                skipControl
            }
            .frame(maxWidth: BreakStartView.contentWidth)
            .padding(.horizontal, 28)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Header

    private var header: some SwiftUI.View {
        VStack(spacing: 8) {
            Text(model.title)
                .font(.system(size: 26, weight: .semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !model.progressText.isEmpty {
                Text(model.progressText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Mode

    /// The app's office / work-from-home setting, worded as what it actually changes: which break
    /// habits you get. Switching it rebuilds the list below.
    private var modePicker: some SwiftUI.View {
        Picker("", selection: modeBinding) {
            Text(strings.chairExercises)
                .help(strings.chairExercisesTooltip)
                .tag(BreakStartKit.BreakMode.chairExercises)
            Text(strings.fullMovement)
                .help(strings.fullMovementTooltip)
                .tag(BreakStartKit.BreakMode.fullMovement)
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
        .frame(maxWidth: 420)
    }

    private var modeBinding: Binding<BreakStartKit.BreakMode> {
        Binding(get: { model.mode }, set: { model.selectMode($0) })
    }

    // MARK: - Habit list

    private var habitList: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(model.habits) { habit in
                Text(habit.text)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: BreakStartView.listMinHeight, alignment: .topLeading)
    }

    // MARK: - Brain dump

    private var brainDump: some SwiftUI.View {
        BreakStartBrainDumpCard(store: model.notesStore, hint: strings.brainDumpHint,
                                editorHeight: BreakStartView.editorHeight)
    }

    // MARK: - Start

    private var startControls: some SwiftUI.View {
        VStack(spacing: 10) {
            if model.isCountingDown {
                Text(model.countdownText)
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            SwiftUI.Button(action: { model.start() }) {
                Text(model.startButtonTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 10)
            }
            .buttonStyle(BorderedButtonStyle())
            Toggle(strings.autoStartCheckbox, isOn: autoStartBinding)
                .font(.system(size: 13))
        }
    }

    private var autoStartBinding: Binding<Bool> {
        Binding(get: { model.isAutoStartEnabled }, set: { model.setAutoStart($0) })
    }

    // MARK: - Skip

    private var skipControl: some SwiftUI.View {
        SwiftUI.Button(action: { model.skip() }) {
            Text(strings.skipBreak)
                .font(.system(size: 12))
                .underline()
                .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Brain dump card

/// The start screen's brain dump. It edits the user's real brain-dump note through `NotesStore`, so
/// what is typed here is the same note the Notes screen, the dashboard and mobile show — not a
/// break-only scratchpad. The store handles loading, the 2 s debounce and the `PUT /note` upsert.
private struct BreakStartBrainDumpCard: SwiftUI.View {
    @ObservedObject var store: NotesStore
    let hint: String
    let editorHeight: CGFloat

    @StateObject private var editorController = NoteEditorController()

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(store.strings.brainDumpTitle).font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 8)
                if store.isSavingBrainDump {
                    Text(store.strings.saving).font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
            Text(hint)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            NoteRichTextEditor(html: $store.brainDumpBody,
                               placeholder: store.strings.brainDumpPlaceholder,
                               controller: editorController)
                .frame(height: editorHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor)))
                .onChange(of: store.brainDumpBody) { store.brainDumpChanged($0) }
            if let status = store.statusMessage {
                Text(status).font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
