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
//  It mirrors the UI style used by pomodoroSettingsVc for shortcut recording:
//    - Click on the shortcut recorder box to start recording (no extra button)
//    - A clear button (cross in circle) is embedded inside the blue-bordered recorder box
//    - Matches the exact visual pattern of pomodoroSettingsVc
//

import Cocoa

// Global reference (mirrors pomodoroSettingsVcObj pattern)
var keyboardShortcutsSettingsVcObj: keyboardShortcutsSettingsVc?

// NSScrollView document views are non-flipped by default (origin bottom-left).
// This subclass flips the coordinate system so content lays out from the top.
private class FlippedView: NSView {
    override var isFlipped: Bool { return true }
}

class keyboardShortcutsSettingsVc: NSViewController {

    // MARK: UI elements – Brain Dump row
    // Title label (left of recorder box)
    private let lblTitleBrainDump    = NSTextField(labelWithString: "")
    // Recorder box (mirrors boxRecordShortcutPomodoro)
    private let boxRecordBrainDump   = NSBox()
    // Label inside recorder box (mirrors lblrecordShorcutPomodoro)
    private let lblShortcutBrainDump = NSTextField(labelWithString: "")
    // Clear button inside recorder box (mirrors btnClearShortcutPomodoro)
    private let btnClearBrainDump    = NSButton()

    // MARK: UI elements – Focus Music row
    private let lblTitleFocusMusic    = NSTextField(labelWithString: "")
    private let boxRecordFocusMusic   = NSBox()
    private let lblShortcutFocusMusic = NSTextField(labelWithString: "")
    private let btnClearFocusMusic    = NSButton()

    // MARK: UI elements – Task List row
    private let lblTitleTaskList    = NSTextField(labelWithString: "")
    private let boxRecordTaskList   = NSBox()
    private let lblShortcutTaskList = NSTextField(labelWithString: "")
    private let btnClearTaskList    = NSButton()

    // MARK: UI elements – Start Focus row
    private let lblTitleFocusSession    = NSTextField(labelWithString: "")
    private let boxRecordFocusSession   = NSBox()
    private let lblShortcutFocusSession = NSTextField(labelWithString: "")
    private let btnClearFocusSession    = NSButton()
    
    
    // MARK: State
    // Uses ActiveShortcutRecorder (from HotkeyService.swift) — no separate RecordingRow enum needed
    private var recordingRow: ActiveShortcutRecorder = .none
    private let normalBorderColor = NSColor.gray
    private var lblHeader: NSTextField?
    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }
    
    
    // All Strings
    private var keyboardShortcutsSettingTitle = "Keyboard Shortcuts"
    private var recordingPlaceholder = "Record Shortcut"
    private var descriptionText = "Set global keyboard shortcuts to instantly open Brain Dump, Focus Music, or Task List from anywhere on your Mac."
    private var brainDumpTitle = "Open Brain Dump:"
    private var focusMusicTitle = "Open Focus Music:"
    private var taskListTitle = "Open Task List:"
    private var startFocusSessionTitle = "Start focus session:"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardShortcutsSettingsVcObj = self
        
        
        if let keyboardShortcutsSettingsVcInfo = configjson.value(forKey: "keyboardShortcutsSettingsVcInfo") as? NSDictionary{
            keyboardShortcutsSettingTitle = keyboardShortcutsSettingsVcInfo.value(forKey: "keyboardShortcutsSettingTitle") as? String ?? keyboardShortcutsSettingTitle
            recordingPlaceholder = keyboardShortcutsSettingsVcInfo.value(forKey: "recordingPlaceholder") as? String ?? recordingPlaceholder
            descriptionText = keyboardShortcutsSettingsVcInfo.value(forKey: "descriptionText") as? String ?? descriptionText
            brainDumpTitle = keyboardShortcutsSettingsVcInfo.value(forKey: "brainDumpTitle") as? String ?? brainDumpTitle
            focusMusicTitle = keyboardShortcutsSettingsVcInfo.value(forKey: "focusMusicTitle") as? String ?? focusMusicTitle
            taskListTitle = keyboardShortcutsSettingsVcInfo.value(forKey: "taskListTitle") as? String ?? taskListTitle
            startFocusSessionTitle = keyboardShortcutsSettingsVcInfo.value(forKey: "focusSessionTitle") as? String ?? startFocusSessionTitle
        }
        
        
        
        buildUI()
        refreshLabels()
        arrForSearchFromSettings.append(["title": keyboardShortcutsSettingTitle, "tabId": idKeyboardShortcuts, "object": self.lblHeader as Any])
        addLog(text: "keyboardShortcutsSettingsVc viewDidLoad")
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        recordingRow = .none
        activeShortcutRecorder = .none
        refreshBoxBorders()
        refreshLabels()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        cancelRecording()
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
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        let contentView = FlippedView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = contentView
        contentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor).isActive = true

        // ── Header ──────────────────────────────────────────────────────────────
        let lblHeader = NSTextField(labelWithString: keyboardShortcutsSettingTitle)
        lblHeader.font = NSFont.boldSystemFont(ofSize: 16)
        lblHeader.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(lblHeader)
        
        self.lblHeader = lblHeader

        let lblDescription = NSTextField(wrappingLabelWithString: descriptionText)
        lblDescription.translatesAutoresizingMaskIntoConstraints = false
        lblDescription.textColor = .secondaryLabelColor
        contentView.addSubview(lblDescription)

        // ── Rows ────────────────────────────────────────────────────────────────
        let brainDumpRow = makeShortcutRow(
            titleLabel:    lblTitleBrainDump,
            recorderBox:   boxRecordBrainDump,
            shortcutLabel: lblShortcutBrainDump,
            clearButton:   btnClearBrainDump,
            title:         brainDumpTitle,
            recordAction:  #selector(boxBrainDumpClicked),
            clearAction:   #selector(btnClearBrainDumpClicked)
        )

        let focusMusicRow = makeShortcutRow(
            titleLabel:    lblTitleFocusMusic,
            recorderBox:   boxRecordFocusMusic,
            shortcutLabel: lblShortcutFocusMusic,
            clearButton:   btnClearFocusMusic,
            title:         focusMusicTitle,
            recordAction:  #selector(boxFocusMusicClicked),
            clearAction:   #selector(btnClearFocusMusicClicked)
        )

        let taskListRow = makeShortcutRow(
            titleLabel:    lblTitleTaskList,
            recorderBox:   boxRecordTaskList,
            shortcutLabel: lblShortcutTaskList,
            clearButton:   btnClearTaskList,
            title:         taskListTitle,
            recordAction:  #selector(boxTaskListClicked),
            clearAction:   #selector(btnClearTaskListClicked)
        )
        
        let focusSessionRow = makeShortcutRow(
            titleLabel:    lblTitleFocusSession,
            recorderBox:   boxRecordFocusSession,
            shortcutLabel: lblShortcutFocusSession,
            clearButton:   btnClearFocusSession,
            title:         startFocusSessionTitle,
            recordAction:  #selector(boxFocusSessionClicked),
            clearAction:   #selector(btnClearFocusSessionClicked)
        )
        

        contentView.addSubview(brainDumpRow)
        contentView.addSubview(focusMusicRow)
        contentView.addSubview(taskListRow)
        contentView.addSubview(focusSessionRow)

        // ── Layout ───────────────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            lblHeader.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            lblHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            lblHeader.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -24),

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
            
            focusSessionRow.topAnchor.constraint(equalTo: taskListRow.bottomAnchor, constant: 16),
            focusSessionRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            focusSessionRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            focusSessionRow.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    /// Build a single shortcut row matching the pomodoroSettingsVc pattern:
    /// [Title label | NSBox (recorder: shortcut label + embedded clear button)]
    ///
    /// Clicking the recorder box starts recording (no separate "Record" button).
    /// The clear button (cross in circle) is embedded inside the box — hidden when no shortcut set.
    private func makeShortcutRow(
        titleLabel: NSTextField,
        recorderBox: NSBox,
        shortcutLabel: NSTextField,
        clearButton: NSButton,
        title: String,
        recordAction: Selector,
        clearAction: Selector
    ) -> NSView {

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // ── Title label ─────────────────────────────────────────────────────────
        titleLabel.stringValue = title
        titleLabel.font = NSFont.systemFont(ofSize: 13)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Recorder box (mirrors boxRecordShortcutPomodoro) ────────────────────
        recorderBox.boxType = .custom
   //     recorderBox.borderType = .lineBorder
        recorderBox.borderWidth = 1.5
        recorderBox.cornerRadius = 6
        recorderBox.borderColor = normalBorderColor
        recorderBox.fillColor = NSColor.controlBackgroundColor
        recorderBox.translatesAutoresizingMaskIntoConstraints = false

        // ── Shortcut label inside box (mirrors lblrecordShorcutPomodoro) ─────────
        shortcutLabel.stringValue = recordingPlaceholder
        shortcutLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        shortcutLabel.alignment = .left
        shortcutLabel.textColor = .secondaryLabelColor
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.isEditable = false
        shortcutLabel.isBordered = false
        shortcutLabel.drawsBackground = false

        // ── Clear button inside box (mirrors btnClearShortcutPomodoro) ───────────
        // "Cross in a circle" style, embedded inside the recorder box
        if #available(macOS 11.0, *) {
            let xmarkImage = NSImage(systemSymbolName: "xmark.circle.fill",
                                     accessibilityDescription: "Clear shortcut")
            clearButton.image = xmarkImage
        } else {
            clearButton.title = "✕"
        }
        clearButton.isBordered = false
        clearButton.bezelStyle = .circular
        clearButton.imageScaling = .scaleProportionallyDown
        clearButton.contentTintColor = .secondaryLabelColor
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.target = self
        clearButton.action = clearAction
        clearButton.isHidden = true   // hidden when no shortcut set (matches Pomodoro pattern)

        // ── Transparent click-to-record overlay button (matches btnRecordShortcutPomodoro) ──
        // This fills the box so the user can click anywhere on the recorder to start recording.
        let recordOverlay = NSButton()
        recordOverlay.title = ""
        recordOverlay.isBordered = false
        recordOverlay.bezelStyle = .rounded
        recordOverlay.translatesAutoresizingMaskIntoConstraints = false
        recordOverlay.target = self
        recordOverlay.action = recordAction
        recordOverlay.setAccessibilityLabel(recordingPlaceholder)

        // ── Assemble box internals ───────────────────────────────────────────────
        // NSBox.addSubview adds to contentView, so constrain to contentView anchors
        // (not box anchors) to avoid the border inset clipping the hit-test area.
        
        recorderBox.addSubview(shortcutLabel)   // on top of overlay
        recorderBox.addSubview(recordOverlay)   // behind everything (z-order: first = bottom)
        recorderBox.addSubview(clearButton)     // topmost (so it gets clicks over overlay)

        let boxContent = recorderBox.contentView!
        NSLayoutConstraint.activate([
            // Overlay covers entire box content area
            recordOverlay.topAnchor.constraint(equalTo: boxContent.topAnchor),
            recordOverlay.bottomAnchor.constraint(equalTo: boxContent.bottomAnchor),
            recordOverlay.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor),
            recordOverlay.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor),

            // Shortcut label: left-aligned, vertically centred, leaves room for clear button
            shortcutLabel.centerYAnchor.constraint(equalTo: boxContent.centerYAnchor),
            shortcutLabel.leadingAnchor.constraint(equalTo: boxContent.leadingAnchor, constant: 8),
            shortcutLabel.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),

            // Clear button: right-aligned inside box
            clearButton.centerYAnchor.constraint(equalTo: boxContent.centerYAnchor),
            clearButton.trailingAnchor.constraint(equalTo: boxContent.trailingAnchor, constant: -6),
            clearButton.widthAnchor.constraint(equalToConstant: 18),
            clearButton.heightAnchor.constraint(equalToConstant: 18)
        ])

        // ── Assemble container ───────────────────────────────────────────────────
        container.addSubview(titleLabel)
        container.addSubview(recorderBox)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 160),

            recorderBox.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            recorderBox.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            recorderBox.widthAnchor.constraint(equalToConstant: 200),
            recorderBox.heightAnchor.constraint(equalToConstant: 28)
        ])

        return container
    }

    // MARK: - Box click actions (start recording — mirrors btnRecordShortcutPomodoroClicked)

    @objc func boxBrainDumpClicked() {
        startRecording(row: .brainDump,
                       box: boxRecordBrainDump,
                       shortcutLabel: lblShortcutBrainDump,
                       clearButton: btnClearBrainDump)
    }

    @objc func boxFocusMusicClicked() {
        startRecording(row: .focusMusic,
                       box: boxRecordFocusMusic,
                       shortcutLabel: lblShortcutFocusMusic,
                       clearButton: btnClearFocusMusic)
    }

    @objc func boxTaskListClicked() {
        startRecording(row: .taskList,
                       box: boxRecordTaskList,
                       shortcutLabel: lblShortcutTaskList,
                       clearButton: btnClearTaskList)
    }

    @objc func boxFocusSessionClicked() {
        startRecording(row: .focusSession,
                       box: boxRecordFocusSession,
                       shortcutLabel: lblShortcutFocusSession,
                       clearButton: btnClearFocusSession)
    }
    
    /// Mirrors pomodoroSettingsVc.btnRecordShortcutPomodoroClicked
    private func startRecording(row: ActiveShortcutRecorder,
                                box: NSBox,
                                shortcutLabel: NSTextField,
                                clearButton: NSButton) {
        // Reset any in-progress recording first — re-registers the previous shortcut before switching
        if recordingRow != .none {
            cancelRecording()
        }
        recordingRow = row
        activeShortcutRecorder = row

        // Unregister the Carbon global hotkey for the shortcut being re-recorded.
        // Carbon intercepts at the system level before NSEvent dispatch — if the shortcut
        // is still registered, pressing it fires the action instead of being captured.
        // (Mirrors appdelegate?.unregisterPomodoroShortcut() in pomodoroSettingsVc.)
        switch row {
        case .brainDump:  HotkeyService.shared.unregisterBrainDump()
        case .focusMusic: HotkeyService.shared.unregisterFocusMusic()
        case .taskList:   HotkeyService.shared.unregisterTaskList()
        case .focusSession:   HotkeyService.shared.unregisterFocusSession()
        case .none: break
        }

        // Visual feedback: blue border + cleared label + hide clear button (mirrors Pomodoro)
        box.borderColor = NSColor.systemBlue
        shortcutLabel.stringValue = ""
        clearButton.isHidden = true

        self.view.window?.makeFirstResponder(nil)
        addLog(text: "[keyboardShortcutsSettingsVc] startRecording \(row)")
    }

    // MARK: - Clear button actions (mirrors btnClearShortcutPomodoroClicked)

    @objc private func btnClearBrainDumpClicked() {
        clearShortcut(.brainDump)
    }

    @objc private func btnClearFocusMusicClicked() {
        clearShortcut(.focusMusic)
    }

    @objc private func btnClearTaskListClicked() {
        clearShortcut(.taskList)
    }
    
    @objc private func btnClearFocusSessionClicked() {
        clearShortcut(.focusSession)
    }
    
    /// Mirrors pomodoroSettingsVc.btnClearShortcutPomodoroClicked
    private func clearShortcut(_ row: ActiveShortcutRecorder) {
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
        case .focusSession:
            SettingsManagerObject.startPomodoroShortcutChar = ""
            SettingsManagerObject.startPomodoroShortcutFlags = []
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.unregisterFocusSession()
        case .none:
            break
        }
        refreshLabels()
        refreshBoxBorders()
        addLog(text: "[keyboardShortcutsSettingsVc] clearShortcut \(row)")
    }

    // MARK: - Called from mainWindowController when a key combo is recorded

    /// Called by mainWindowController.keyDown after it captures a key event while
    /// `activeShortcutRecorder` is not `.none`.
    /// Mirrors the pomodoroSettingsVc shortcut-saved flow: resets border, shows clear button.
    func shortcutRecorded(char: String, flagInts: [Int]) {
        defer {
            recordingRow = .none
            activeShortcutRecorder = .none
            refreshBoxBorders()
            refreshLabels()
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
        case .focusSession:
            SettingsManagerObject.startPomodoroShortcutChar = char
            SettingsManagerObject.startPomodoroShortcutFlags = flagInts
            SettingsManagerObject.isSettingsChanged = true
            HotkeyService.shared.registerFocusSession()
        case .none:
            break
        }
        addLog(text: "[keyboardShortcutsSettingsVc] shortcutRecorded char=\(char) flagInts=\(flagInts)")
    }

    func cancelRecording() {
        // Re-register the shortcut that was unregistered in startRecording() before we clear state.
        // Without this, pressing ESC leaves the shortcut permanently dead until app restart.
        // Mirrors pomodoroSettingsVc.resetCurrentRecording() which calls registerPomodoroShortcut()
        // before clearing recording state.
        switch recordingRow {
        case .brainDump:  HotkeyService.shared.registerBrainDump()
        case .focusMusic: HotkeyService.shared.registerFocusMusic()
        case .taskList:   HotkeyService.shared.registerTaskList()
        case .focusSession: HotkeyService.shared.registerFocusSession()
        case .none: break
        }
        recordingRow = .none
        activeShortcutRecorder = .none
        refreshBoxBorders()
        refreshLabels()
    }

    // MARK: - Refresh helpers (mirror pomodoroSettingsVc.reload_newShotShortcut)

    /// Update shortcut label text and clear-button visibility for all rows.
    func refreshLabels() {
        refreshRow(
            char: SettingsManagerObject.brainDumpShortcutChar,
            flagInts: SettingsManagerObject.brainDumpShortcutFlags,
            shortcutLabel: lblShortcutBrainDump,
            clearButton: btnClearBrainDump
        )
        refreshRow(
            char: SettingsManagerObject.focusMusicShortcutChar,
            flagInts: SettingsManagerObject.focusMusicShortcutFlags,
            shortcutLabel: lblShortcutFocusMusic,
            clearButton: btnClearFocusMusic
        )
        refreshRow(
            char: SettingsManagerObject.taskListShortcutChar,
            flagInts: SettingsManagerObject.taskListShortcutFlags,
            shortcutLabel: lblShortcutTaskList,
            clearButton: btnClearTaskList
        )
        refreshRow(
            char: SettingsManagerObject.startPomodoroShortcutChar,
            flagInts: SettingsManagerObject.startPomodoroShortcutFlags,
            shortcutLabel: lblShortcutFocusSession,
            clearButton: btnClearFocusSession
        )
    }

    private func refreshRow(char: String,
                            flagInts: [Int],
                            shortcutLabel: NSTextField,
                            clearButton: NSButton) {
        // Check raw stored values directly — do NOT compare display string, which returns "Not set"
        // for unset shortcuts (not "" or recordingPlaceholder).
        if char.isEmpty && flagInts.isEmpty {
            shortcutLabel.stringValue = recordingPlaceholder
            shortcutLabel.textColor = .secondaryLabelColor
            clearButton.isHidden = true
        } else {
            shortcutLabel.stringValue = HotkeyService.displayString(char: char, flagInts: flagInts)
            shortcutLabel.textColor = .labelColor
            clearButton.isHidden = false  // show embedded clear button (mirrors Pomodoro)
        }
    }

    /// Reset all box borders to normal (matches pomodoroSettingsVc border reset on viewWillAppear).
    private func refreshBoxBorders() {
        boxRecordBrainDump.borderColor  = normalBorderColor
        boxRecordFocusMusic.borderColor = normalBorderColor
        boxRecordTaskList.borderColor   = normalBorderColor
        boxRecordFocusSession.borderColor = normalBorderColor
    }
}
