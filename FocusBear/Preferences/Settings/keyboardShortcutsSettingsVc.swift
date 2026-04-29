//
//  keyboardShortcutsSettingsVc.swift
//  Focus Bear
//
//  Settings panel for configuring global keyboard shortcuts:
//    - Open Brain Dump
//    - Open Focus Music
//    - Open Task List
//
//  This is a fully programmatic NSViewController (no storyboard scene required).
//  It mirrors the UI style used by pomodoroSettingsVc for shortcut recording.
//

import Cocoa

// MARK: - Which shortcut row is being recorded in THIS vc instance

private enum RecordingRow {
    case none, brainDump, focusMusic, taskList
}

// Global reference (mirrors pomodoroSettingsVcObj pattern)
var keyboardShortcutsSettingsVcObj: keyboardShortcutsSettingsVc?

class keyboardShortcutsSettingsVc: NSViewController {

    // MARK: UI elements – Brain Dump row

    private let lblTitleBrainDump   = NSTextField(labelWithString: "")
    private let lblShortcutBrainDump = NSTextField(labelWithString: "")
    private let btnRecordBrainDump  = NSButton()
    private let btnClearBrainDump   = NSButton()

    // MARK: UI elements – Focus Music row

    private let lblTitleFocusMusic   = NSTextField(labelWithString: "")
    private let lblShortcutFocusMusic = NSTextField(labelWithString: "")
    private let btnRecordFocusMusic  = NSButton()
    private let btnClearFocusMusic   = NSButton()

    // MARK: UI elements – Task List row

    private let lblTitleTaskList   = NSTextField(labelWithString: "")
    private let lblShortcutTaskList = NSTextField(labelWithString: "")
    private let btnRecordTaskList  = NSButton()
    private let btnClearTaskList   = NSButton()

    // MARK: State

    private var recordingRow: RecordingRow = .none

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardShortcutsSettingsVcObj = self
        buildUI()
        refreshLabels()
        addLog(text: "keyboardShortcutsSettingsVc viewDidLoad")
    }

    // MARK: - UI Construction

    private func buildUI() {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true

        // ── Header ──────────────────────────────────────────────────────────────
        let lblHeader = NSTextField(labelWithString: "Keyboard Shortcuts")
        lblHeader.font = NSFont.boldSystemFont(ofSize: 16)
        lblHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lblHeader)

        let lblDescription = NSTextField(wrappingLabelWithString:
            "Set global keyboard shortcuts to instantly open Brain Dump, Focus Music, or Task List from anywhere on your Mac.")
        lblDescription.translatesAutoresizingMaskIntoConstraints = false
        lblDescription.textColor = .secondaryLabelColor
        contentView.addSubview(lblDescription)

        // ── Rows ────────────────────────────────────────────────────────────────
        let brainDumpRow = makeShortcutRow(
            titleLabel:    lblTitleBrainDump,
            shortcutLabel: lblShortcutBrainDump,
            recordButton:  btnRecordBrainDump,
            clearButton:   btnClearBrainDump,
            title:         "Open Brain Dump:",
            recordAction:  #selector(btnRecordBrainDumpClicked),
            clearAction:   #selector(btnClearBrainDumpClicked)
        )

        let focusMusicRow = makeShortcutRow(
            titleLabel:    lblTitleFocusMusic,
            shortcutLabel: lblShortcutFocusMusic,
            recordButton:  btnRecordFocusMusic,
            clearButton:   btnClearFocusMusic,
            title:         "Open Focus Music:",
            recordAction:  #selector(btnRecordFocusMusicClicked),
            clearAction:   #selector(btnClearFocusMusicClicked)
        )

        let taskListRow = makeShortcutRow(
            titleLabel:    lblTitleTaskList,
            shortcutLabel: lblShortcutTaskList,
            recordButton:  btnRecordTaskList,
            clearButton:   btnClearTaskList,
            title:         "Open Task List:",
            recordAction:  #selector(btnRecordTaskListClicked),
            clearAction:   #selector(btnClearTaskListClicked)
        )

        contentView.addSubview(brainDumpRow)
        contentView.addSubview(focusMusicRow)
        contentView.addSubview(taskListRow)

        // ── Layout ───────────────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            lblHeader.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            lblHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            lblHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            lblDescription.topAnchor.constraint(equalTo: lblHeader.bottomAnchor, constant: 8),
            lblDescription.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            lblDescription.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            brainDumpRow.topAnchor.constraint(equalTo: lblDescription.bottomAnchor, constant: 24),
            brainDumpRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            brainDumpRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            focusMusicRow.topAnchor.constraint(equalTo: brainDumpRow.bottomAnchor, constant: 16),
            focusMusicRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            focusMusicRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            taskListRow.topAnchor.constraint(equalTo: focusMusicRow.bottomAnchor, constant: 16),
            taskListRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            taskListRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            taskListRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    /// Build a single shortcut row: [Title label | Shortcut display | Record button | Clear button]
    private func makeShortcutRow(
        titleLabel: NSTextField,
        shortcutLabel: NSTextField,
        recordButton: NSButton,
        clearButton: NSButton,
        title: String,
        recordAction: Selector,
        clearAction: Selector
    ) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        shortcutLabel.stringValue = "Not set"
        shortcutLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        shortcutLabel.alignment = .center
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.wantsLayer = true
        shortcutLabel.layer?.cornerRadius = 4

        recordButton.title = "Record Shortcut"
        recordButton.bezelStyle = .rounded
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.target = self
        recordButton.action = recordAction

        clearButton.title = "Clear"
        clearButton.bezelStyle = .rounded
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.target = self
        clearButton.action = clearAction

        container.addSubview(titleLabel)
        container.addSubview(shortcutLabel)
        container.addSubview(recordButton)
        container.addSubview(clearButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 160),

            shortcutLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            shortcutLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            shortcutLabel.widthAnchor.constraint(equalToConstant: 100),

            recordButton.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 8),
            recordButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            clearButton.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 8),
            clearButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            clearButton.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),

            container.heightAnchor.constraint(equalToConstant: 36)
        ])

        return container
    }

    // MARK: - Refresh display labels

    func refreshLabels() {
        lblShortcutBrainDump.stringValue = HotkeyService.displayString(
            char: SettingsManagerObject.brainDumpShortcutChar,
            flagInts: SettingsManagerObject.brainDumpShortcutFlags
        )
        lblShortcutFocusMusic.stringValue = HotkeyService.displayString(
            char: SettingsManagerObject.focusMusicShortcutChar,
            flagInts: SettingsManagerObject.focusMusicShortcutFlags
        )
        lblShortcutTaskList.stringValue = HotkeyService.displayString(
            char: SettingsManagerObject.taskListShortcutChar,
            flagInts: SettingsManagerObject.taskListShortcutFlags
        )
    }

    // MARK: - Record button actions

    @objc private func btnRecordBrainDumpClicked() {
        startRecording(row: .brainDump, button: btnRecordBrainDump)
    }

    @objc private func btnRecordFocusMusicClicked() {
        startRecording(row: .focusMusic, button: btnRecordFocusMusic)
    }

    @objc private func btnRecordTaskListClicked() {
        startRecording(row: .taskList, button: btnRecordTaskList)
    }

    private func startRecording(row: RecordingRow, button: NSButton) {
        guard recordingRow == .none else { return }
        recordingRow = row
        activeShortcutRecorder = rowToGlobal(row)
        button.title = "Press shortcut..."
        button.highlight(true)
        // mainWindowController will call shortcutRecorded(char:flagInts:) when key is pressed
        addLog(text: "[keyboardShortcutsSettingsVc] startRecording \(row)")
    }

    // MARK: - Clear button actions

    @objc private func btnClearBrainDumpClicked() {
        clearShortcut(.brainDump)
    }

    @objc private func btnClearFocusMusicClicked() {
        clearShortcut(.focusMusic)
    }

    @objc private func btnClearTaskListClicked() {
        clearShortcut(.taskList)
    }

    private func clearShortcut(_ row: RecordingRow) {
        switch row {
        case .brainDump:
            SettingsManagerObject.brainDumpShortcutChar = ""
            SettingsManagerObject.brainDumpShortcutFlags = []
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.unregisterBrainDump()
        case .focusMusic:
            SettingsManagerObject.focusMusicShortcutChar = ""
            SettingsManagerObject.focusMusicShortcutFlags = []
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.unregisterFocusMusic()
        case .taskList:
            SettingsManagerObject.taskListShortcutChar = ""
            SettingsManagerObject.taskListShortcutFlags = []
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.unregisterTaskList()
        case .none:
            break
        }
        refreshLabels()
        addLog(text: "[keyboardShortcutsSettingsVc] clearShortcut \(row)")
    }

    // MARK: - Called from mainWindowController when a key combo is recorded

    /// Called by mainWindowController.keyDown after it captures a key event while
    /// `activeShortcutRecorder` is not `.none`.
    func shortcutRecorded(char: String, flagInts: [Int]) {
        defer {
            recordingRow = .none
            activeShortcutRecorder = .none
            resetRecordButtonTitles()
        }

        switch recordingRow {
        case .brainDump:
            SettingsManagerObject.brainDumpShortcutChar = char
            SettingsManagerObject.brainDumpShortcutFlags = flagInts
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.registerBrainDump()
        case .focusMusic:
            SettingsManagerObject.focusMusicShortcutChar = char
            SettingsManagerObject.focusMusicShortcutFlags = flagInts
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.registerFocusMusic()
        case .taskList:
            SettingsManagerObject.taskListShortcutChar = char
            SettingsManagerObject.taskListShortcutFlags = flagInts
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.registerTaskList()
        case .none:
            break
        }
        refreshLabels()
        addLog(text: "[keyboardShortcutsSettingsVc] shortcutRecorded char=\(char) flagInts=\(flagInts)")
    }

    func cancelRecording() {
        recordingRow = .none
        activeShortcutRecorder = .none
        resetRecordButtonTitles()
    }

    // MARK: - Helpers

    private func resetRecordButtonTitles() {
        btnRecordBrainDump.title = "Record Shortcut"
        btnRecordBrainDump.highlight(false)
        btnRecordFocusMusic.title = "Record Shortcut"
        btnRecordFocusMusic.highlight(false)
        btnRecordTaskList.title = "Record Shortcut"
        btnRecordTaskList.highlight(false)
    }

    private func rowToGlobal(_ row: RecordingRow) -> ActiveShortcutRecorder {
        switch row {
        case .none:       return .none
        case .brainDump:  return .brainDump
        case .focusMusic: return .focusMusic
        case .taskList:   return .taskList
        }
    }
}
