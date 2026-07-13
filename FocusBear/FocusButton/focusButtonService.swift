//
//  FocusButtonService.swift
//  FocusBear
//
//  Created by Manish Jain on 11/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import Foundation
import ORSSerial


class focusButtonService: NSObject {
    
    // MARK: - Data Structures
    
    struct TzEntry {
        var display: String = ""
        var offsetMinutes: Int = 0
    }
    
    enum DeviceState: String {
        case disconnected, idle, running, paused
    }
    
    // MARK: - Properties
    
    private var serialPort: ORSSerialPort?
    var isRunning = false
    private var rxThread: Thread?
    
    private var state: DeviceState = .disconnected
    private var remainingSeconds: Int64 = 0
    private var sessionTotalSeconds: Int64 = 0

    private var pendingResponse = false
    private var lastSentCmd = ""
    private var responseCheckTimer: Timer?
    
    private var tzList: [TzEntry] = []
    
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 3
    private var isReconnecting = false
    private var isConnecting = false

    /// Set when the user (or an external process via FocusButtonCommandChannel) asks to stay
    /// disconnected — suppresses auto-reconnect so /dev/cu.usbmodem* stays free (e.g. so firmware can
    /// be reflashed) until an explicit reconnect/start.
    private var userRequestedStayDisconnected = false

    /// Repeating poll that transparently reconnects the button after an involuntary drop
    /// (unplug/replug, sleep, serial glitch like "Device not configured"). Armed by start();
    /// see startReconnectMonitor(). A tick is free while connected — it returns before doing
    /// any port scan — so a short interval costs almost nothing; the only work happens while
    /// disconnected (a lightweight IOKit port enumeration).
    private var reconnectPollTimer: Timer?
    private let reconnectPollInterval: TimeInterval = 10

    /// While a focus session is running, poll the device (STATUS) periodically; if it reports IDLE
    /// (dropped back to the splash/idle screen) we re-push SET|START so the countdown reappears —
    /// the device doesn't always hold the running screen (firmware glitch / stray command).
    private var focusResyncTimer: Timer?
    private let focusResyncInterval: TimeInterval = 15
    /// True while a Late No More notification is taking over the device screen (SET|NOTIFY). The focus
    /// resync must not re-push SET|START during this, or it would clobber the notification takeover.
    private var isShowingNotification = false
    private let hasEverConnectedKey = "focusButtonHasEverConnected"
    /// True once the button has successfully opened at least once (persisted across launches),
    /// so we only auto-scan for people who actually use the device.
    private var hasEverConnected: Bool {
        get { UserDefaults.standard.bool(forKey: hasEverConnectedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasEverConnectedKey) }
    }

    // MARK: - Device validation (don't hold the port unless it's a Focus device)
    //
    // Any ESP32 native-USB board (VID 0x303a) enumerates as an identical
    // /dev/cu.usbmodem* device, so USB descriptors can't tell a Focus Button
    // (M5Dial) apart from other ESP32-S3 gadgets on the same Mac (e.g. a StickS3
    // breathing sensor). Instead we probe on open: a Focus device answers
    // GET|FIRMWAREVER with "FIRMWAREVER|M50-…" (M50 = M5Dial, C30 = VIEWE C3) and
    // STATUS with "INFO|…"; a non-Focus device answers neither. We only keep the
    // port (and send it any commands) once it has identified itself, otherwise we
    // release it so other apps can use it and move on to the next candidate port.
    private var isValidatedFocusDevice = false
    private var validationTimer: Timer?
    private let validationTimeout: TimeInterval = 2.0
    // Accepted hardware-version prefixes from GET|FIRMWAREVER (see focus-button
    // protocol.md). M50 = M5Dial, C30 = VIEWE C3.
    private let acceptedHardwarePrefixes = ["M50", "C30"]
    // Remaining ports to try this connection attempt, and ports already rejected
    // this session so we don't keep re-grabbing a non-Focus device.
    private var pendingCandidatePorts: [String] = []
    private var rejectedPorts: Set<String> = []

    // Regex patterns
    private let tsPfx = try? NSRegularExpression(pattern: "^\\d+\\.\\d+\\|", options: [])
    private let espLog = try? NSRegularExpression(pattern: "^[EWIDV] \\(\\d+|^\\[?\\d+\\]?\\s*\\[?[EWIDV]\\]|^\\[LOG\\]", options: [])
    
    // MARK: - Callbacks
    var onStateChanged: ((DeviceState) -> Void)?
    var onRemainingTimeChanged: ((Int64) -> Void)?
    var onHabitsReceived: (([(id: String, name: String, durationSeconds: Int64)]) -> Void)?
    
    var onError: ((String) -> Void)?
    var onPortDisconnected: (() -> Void)?
    var onDeviceConnected: ((String) -> Void)?

    /// Fired after the device (re)connects and the handshake is sent, so the app can re-push the
    /// current session/habit state onto it. Separate from `onDeviceConnected` (which the settings
    /// screen reassigns) so a persistent app-level restore hook is never clobbered. Without this,
    /// auto-reconnect brings the serial link back but the device stays idle — a focus session/habit
    /// that started while it was disconnected never reappears, and SET|UPDATE (extend) no-ops.
    var onDeviceConnectedRestore: (() -> Void)?

    /// Firmware version reported by the connected device (e.g. "M50-1.5.0"),
    /// or nil when not connected / not yet known. Updated from the device's
    /// reply to GET|FIRMWAREVER. Observe `firmwareVersionDidChange` for updates.
    private(set) var firmwareVersion: String?

    /// Posted on the main thread whenever `firmwareVersion` changes (incl. to nil
    /// on disconnect), so settings UI can refresh the displayed version.
    static let firmwareVersionDidChange = Notification.Name("FocusButtonFirmwareVersionDidChange")

    /// Path of the currently connected serial port (e.g. "/dev/cu.usbmodemXXXX"),
    /// or nil when not connected. Needed to hand the port to the firmware flasher.
    var connectedPortPath: String? { serialPort?.path }

    /// Whether the connected firmware supports emoji-icon sync (>= 1.7.0). Public so settings screens
    /// can decide whether to show icon-sync status at all (older firmware has nothing to report).
    var supportsEmojiIcons: Bool { firmwareSupportsEmoji }

    // MARK: - Public Methods
    
    func start() -> Bool {
        log("FocusButton: Start()")
        userRequestedStayDisconnected = false   // an explicit start/connect clears a prior manual disconnect
        startReconnectMonitor()   // keep trying in the background even if this attempt finds no port

        // Fresh attempt: forget ports rejected on a previous attempt so a device
        // that was transiently unresponsive can be probed again.
        rejectedPorts.removeAll()
        pendingCandidatePorts = candidatePorts()
        guard !pendingCandidatePorts.isEmpty else {
            log("FocusButton: No serial port found")
            onError?("No Focus Button device found. Please check USB connection.")
            return false
        }

        tryNextCandidate()
        return true
    }

    /// Connect to the next candidate port and probe it. If none remain, all
    /// detected ports failed validation (no Focus device present).
    private func tryNextCandidate() {
        while let next = pendingCandidatePorts.first, rejectedPorts.contains(next) {
            pendingCandidatePorts.removeFirst()
        }
        guard !pendingCandidatePorts.isEmpty else {
            log("FocusButton: No Focus Button device responded on any candidate port")
            onError?("No Focus Button device found. Please check USB connection.")
            return
        }
        let portName = pendingCandidatePorts.removeFirst()
        connect(portName: portName)
    }

    /// Arm a repeating poll that reconnects the Focus Button after an involuntary drop, so long as
    /// it has connected at least once before. Without this, a drop (unplug/replug, sleep, or a serial
    /// glitch) leaves the button offline until the app is relaunched — which silently no-op's Late No
    /// More device countdowns and habit signals (they only send when connected). Idempotent; the tick
    /// is a cheap no-op while connected/connecting.
    func startReconnectMonitor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.reconnectPollTimer == nil else { return }
            self.log("FocusButton: reconnect monitor armed (every \(Int(self.reconnectPollInterval))s)")
            let timer = Timer.scheduledTimer(withTimeInterval: self.reconnectPollInterval, repeats: true) { [weak self] _ in
                self?.attemptAutoReconnect()
            }
            timer.tolerance = self.reconnectPollInterval / 2   // let the OS coalesce wakeups; not time-critical
            self.reconnectPollTimer = timer
        }
    }

    private func attemptAutoReconnect() {
        guard !userRequestedStayDisconnected else { return }  // user/external asked to stay disconnected (e.g. reflashing)
        guard hasEverConnected else { return }             // never auto-scan for non-button users
        guard !isConnected, !isConnecting else { return }  // already connected / attempt in flight
        // Only try when a device is actually present, so we don't spam start()'s "not found" error
        // (or churn) every tick while the button is simply unplugged. candidatePorts() returns any
        // plausible ports; start()'s validation then rejects them if they aren't a Focus device.
        guard !candidatePorts().isEmpty else { return }
        log("FocusButton: auto-reconnect — button offline but present, reconnecting")
        _ = start()
    }
    
    func start(withPort portName: String) -> Bool {
        log("FocusButton: Start() with port: \(portName)")
        connect(portName: portName)
        return true
    }
    
    func stop() {
        // Explicit stop (e.g. user turned the add-on off) — halt auto-reconnect too. Involuntary
        // drops go through disconnect() directly, which leaves the monitor armed so it reconnects.
        reconnectPollTimer?.invalidate()
        reconnectPollTimer = nil
        stopFocusResync()
        disconnect()
    }

    /// True only once the serial port is actually open (unlike `isRunning`, which is set optimistically
    /// the moment a connection attempt begins).
    var isConnected: Bool { serialPort?.isOpen == true }

    /// Human-readable summary of the USB serial devices macOS currently sees, for the settings UI.
    var availablePortsSummary: String {
        let ports = getUSBSerialPorts()
        guard !ports.isEmpty else { return "no USB serial devices found" }
        return ports.map { $0.path.replacingOccurrences(of: "/dev/", with: "") }.joined(separator: ", ")
    }

    func getAvailablePorts() -> [String] {
        let ports = ORSSerialPortManager.shared().availablePorts
        return ports.map { $0.path }
    }
    
    func getUSBSerialPorts() -> [(path: String, name: String)] {
        let ports = ORSSerialPortManager.shared().availablePorts
        return ports.compactMap { port in
            let path = port.path
            let name = port.name
            
            // Filter for USB serial devices (both /tty.* and /cu.*)
            if path.contains("usb") ||
                path.contains("cu.") ||
                name.lowercased().contains("usb") ||
                name.lowercased().contains("serial") {
                return (path: path, name: name.isEmpty ? path : name)
            }
            return nil
        }
    }
    
    func startFocusSession(seconds: Int) {
        log("FocusButton: StartFocusSession()")
        sendCmd("SET|START|\(seconds)")
        applyState(.running)
        armFocusResync()
    }

    /// Arm the periodic focus-session resync (idempotent). Each tick only polls STATUS — a silent read.
    /// handleInfo then re-pushes SET|START if the device reports IDLE (dropped back to the splash/idle
    /// screen while a session is still running). We deliberately do NOT re-push SET|START while the
    /// device is already RUNNING: SET|START plays a beep on the device (handle_start_cmd → play_beep),
    /// so re-pushing every tick would beep repeatedly. Stops when the session ends / device disconnects.
    private func armFocusResync() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.focusResyncTimer == nil else { return }
            let t = Timer.scheduledTimer(withTimeInterval: self.focusResyncInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard isFocusModeRunning, self.isConnected else {
                    self.stopFocusResync(); return
                }
                // Leave a Late No More takeover alone — don't poke the device while it's showing.
                if self.isShowingNotification { return }
                self.sendCmd("STATUS")   // → INFO|<state>|<remaining>… ; handleInfo re-establishes if IDLE
            }
            t.tolerance = self.focusResyncInterval / 3
            self.focusResyncTimer = t
        }
    }

    private func stopFocusResync() {
        focusResyncTimer?.invalidate()
        focusResyncTimer = nil
    }

    func pauseFocusSession() {
        log("FocusButton: PauseFocusSession()")
        sendCmd("SET|PAUSE")
        applyState(.paused)
    }
    
    func resumeFocusSession() {
        log("FocusButton: ResumeFocusSession()")
        sendCmd("SET|RESUME")
        applyState(.running)
    }
    
    func finishFocusSession() {
        log("FocusButton: FinishFocusSession()")
        stopFocusResync()
        sendCmd("SET|CANCEL")
        applyState(.idle)
    }
    
    func updateFocusDuration(seconds: Int) {
        log("FocusButton: UpdateFocusDuration()")
        sendCmd("SET|UPDATE|\(seconds)")
        applyState(.idle)
    }
    
    func updateHabitDuration(seconds: Int) {
        log("FocusButton: updateHabitDuration()")
        sendCmd("SET|UPDATE|\(seconds)")
        applyState(.idle)
    }
    
    func sendMorningHabitsToFocusDevice(){
        // Don't refresh the habit list while the device is showing a running/paused session — the
        // SET|CLEARHABITS + SET|HABITS clobbers it (a focus SET|START countdown goes blank; a running
        // SET|STARTHBID habit finishes immediately / returns to idle). NOTE: this leaves the list stale
        // during a routine, so if a habit is started whose id isn't already in the device's list the
        // device rejects SET|STARTHBID with ERROR|invalid_state. Proper fix (WIP): push the full routine
        // list once while idle at routine start so every id is present, or self-heal on invalid_state.
        guard state != .running, state != .paused else {
            log("FocusButton: skip sendMorningHabits — a session is showing on the device")
            return
        }
        log("FocusButton: sendMorningHabitsToFocusDevice()")
        clearHabits()
        var arrHabits = [(id: String, name: String, durationSeconds: Int)]()
        for i in 0..<arrFilteredMorningHabits.count{
            let id = arrFilteredMorningHabits[i].id ?? ""
            let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredMorningHabits)
            if !isActivityCompleted{
                // Emoji-capable firmware (≥1.7.0) shows the habit's emoji in the RUNNING ring. The emoji
                // lives in the habit_icon field (NOT the name), so compose "<icon> <name>": the firmware
                // derives the bitmap key from the leading emoji and strips it from the text label. Older
                // firmware can't render emoji, so send the plain name.
                let h = arrFilteredMorningHabits[i]
                let deviceName = (firmwareSupportsEmoji && !h.habitIcon.isEmpty) ? "\(h.habitIcon) \(h.nameWithoutIcon)" : h.nameWithoutIcon
                arrHabits.append((id: h.fakeIdForDevice, name: deviceName, durationSeconds: h.durationSeconds))
            }
        }
        sendHabits(habits: arrHabits)
    }
    
    func sendEveningHabitsToFocusDevice(){
        // See sendMorningHabitsToFocusDevice — don't clobber a running/paused session on the device.
        guard state != .running, state != .paused else {
            log("FocusButton: skip sendEveningHabits — a session is showing on the device")
            return
        }
        log("FocusButton: sendEveningHabitsToFocusDevice()")
        clearHabits()
        var arrHabits = [(id: String, name: String, durationSeconds: Int)]()
        let runningLate = isCutOffTimeGoing()
        for i in 0..<arrFilteredEveningHabits.count{
            let id = arrFilteredEveningHabits[i].id ?? ""
            let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredEveningHabits)
            if !isActivityCompleted{
                // Match the Day Plan / playback: once past the cutoff the evening routine skips
                // non-high-priority habits (AppDelegate: "evening habit skipped — running late"), so
                // don't send those to the device either. Sending the full list left the button out of
                // sync with the habits that actually run (a skipped habit starts then finishes at once).
                if runningLate && !arrFilteredEveningHabits[i].isPriorityHigh { continue }
                // See sendMorningHabits: compose "<habit_icon> <name>" for emoji-capable firmware (≥1.7.0).
                let h = arrFilteredEveningHabits[i]
                let deviceName = (firmwareSupportsEmoji && !h.habitIcon.isEmpty) ? "\(h.habitIcon) \(h.nameWithoutIcon)" : h.nameWithoutIcon
                arrHabits.append((id: h.fakeIdForDevice, name: deviceName, durationSeconds: h.durationSeconds))
            }
        }
        sendHabits(habits: arrHabits)
    }

    func isActivityCompleted(id:String, habits:[habit])->Bool{
        if currentHabitIndex == -1{
            return false
        }
        if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_{
            return false // user is in postponed habit list so no need to remove completed
        }
        // before v 3.33.498 check was wrong"- currentAction != ._START_
        if currentAction == ._START_{
            return false // user is in firstvc habit list so no need to remove completed
        }
        for i in 0..<currentHabitIndex + 1{
            let habit = habits[i]
            if habit.id == id{
                return true
            }
        }
        return false
    }
    
    
    func clearHabits() {
        log("FocusButton: clearHabits()")
        sendCmd("SET|CLEARHABITS")
    }
    
    func sendHabits(habits: [(id: String, name: String, durationSeconds: Int)]) {
        log("FocusButton: sendHabits(): \(habits)")
        if habits.isEmpty {
            log("FocusButton: !! No habits to send.")
            return
        }
        
        let entries = habits.map { "\($0.id),\($0.name),\($0.durationSeconds)" }
        sendCmd("SET|HABITS|" + entries.joined(separator: "|"))

        // Push the habit-name emoji so the device can show them in the RUNNING ring (firmware ≥ 1.7.0).
        // Runs after SET|HABITS and is best-effort / cached device-side, so it never blocks habit sync.
        if firmwareSupportsEmoji {
            lastEmojiHabitNames = habits.map { $0.name }
            emojiSyncKind = .habit
            emojiSync.syncEmojis(fromHabitNames: lastEmojiHabitNames)
        }
    }

    /// The last habit names whose emoji were synced, so the Focus Button screen can re-check icon status
    /// on demand (opening the screen) without waiting for the next routine load.
    private var lastEmojiHabitNames: [String] = []

    /// Re-run the emoji sync for the last-loaded habits (cached icons are skipped via GET|EMOJILIST, so
    /// this is cheap). Drives the Focus Button screen's icon-upload status. Returns false if there's
    /// nothing to check (unsupported firmware / no emoji habits loaded yet).
    @discardableResult
    func refreshEmojiIcons() -> Bool {
        guard firmwareSupportsEmoji, isConnected else { return false }
        // Every habit icon the user has — across morning, evening AND custom routines — so opening the
        // Focus Button screen pre-caches the full set (EmojiSync dedupes to unique emoji; the device
        // caches them, so each routine's running-ring icon is ready). Not just the last-synced routine.
        let allHabits = arrAllDaysMorningHabits + arrAllDaysEveningHabits
            + arrAllCustomRoutine.flatMap { $0.arrAllHabits }
        let names = allHabits.compactMap { $0.habitIcon.isEmpty ? nil : "\($0.habitIcon) \($0.nameWithoutIcon)" }
        guard !names.isEmpty else { return false }
        emojiSyncKind = .habit
        emojiSync.syncEmojis(fromHabitNames: names)
        return true
    }
    
    func startHabit(habitId: String) {
        log("FocusButton: StartHabit() - \(habitId)")
        // Start by unique habit id, not list position. The value passed in is a
        // fakeIdForDevice (the id sent in SET|HABITS), and the device list is a
        // filtered subset (completed habits are skipped) so positions no longer
        // match ids. SET|STARTHB takes a 1-based position and would start the
        // wrong habit; SET|STARTHBID takes the id. Matches windows-app-v2.
        sendCmd("SET|STARTHBID|\(habitId)")
        applyState(.running)
    }

    /// Show a Late No More countdown on the device. The device counts down from
    /// `countdownSeconds` (background ramps green→yellow→orange→red) and beeps
    /// every 3s once it hits 0, until `dismissNotification()` is called.
    /// No-op if the button isn't connected.
    func showNotification(text: String, countdownSeconds: Int = 120) {
        let sanitized = sanitizeForCommand(text)
        guard !sanitized.isEmpty else { return }
        log("FocusButton: showNotification() - \(sanitized) (\(countdownSeconds)s)")
        // A Late No More notification takes over the device screen (firmware saves the prior state).
        // Mark it so the focus resync pauses — otherwise its periodic SET|START would switch the
        // device back to the focus countdown and the notification would never stick.
        isShowingNotification = true
        if countdownSeconds > 0 {
            sendCmd("SET|NOTIFY|\(sanitized)|\(countdownSeconds)")
        } else {
            sendCmd("SET|NOTIFY|\(sanitized)")
        }
        // Once the countdown hits 0:00 the firmware alarm-beeps every 3s until SET|NOTIFYDISMISS, and
        // the app only dismisses when the user acts on the reminder popup — so an ignored reminder
        // beeps the button indefinitely. Cap it: auto-dismiss a short grace after the countdown ends.
        armNotificationAutoDismiss(afterCountdown: countdownSeconds > 0 ? countdownSeconds : 120)
    }

    private var notifyAutoDismissTimer: Timer?
    /// How long the device alarm may beep past 0:00 before we force a dismiss on an unacknowledged
    /// reminder (5 min — matches the firmware alarm cap NOTIFY_ALARM_MAX_S).
    private let notifyAlarmGraceSeconds = 300
    private func armNotificationAutoDismiss(afterCountdown countdownSeconds: Int) {
        let total = TimeInterval(max(countdownSeconds, 0) + notifyAlarmGraceSeconds)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notifyAutoDismissTimer?.invalidate()
            let t = Timer.scheduledTimer(withTimeInterval: total, repeats: false) { [weak self] _ in
                guard let self = self, self.isShowingNotification else { return }
                self.log("FocusButton: auto-dismissing Late No More notification (unacknowledged, alarm beeping)")
                self.dismissNotification()
            }
            t.tolerance = 2
            self.notifyAutoDismissTimer = t
        }
    }

    /// End the Late No More countdown on the device and restore its prior screen.
    func dismissNotification() {
        log("FocusButton: dismissNotification()")
        isShowingNotification = false
        notifyAutoDismissTimer?.invalidate()
        notifyAutoDismissTimer = nil
        sendCmd("SET|NOTIFYDISMISS")
    }

    /// Make the device beep, mirroring an audio alert the Mac just played.
    /// No-op if the button isn't connected; silent on boards without a buzzer.
    func beep() {
        log("FocusButton: beep()")
        sendCmd("SET|BEEP")
    }

    /// Strip characters that would break the pipe/newline-delimited serial
    /// protocol and cap the length (the firmware copies into a 64-byte buffer).
    private func sanitizeForCommand(_ text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count > 60 ? String(cleaned.prefix(60)) : cleaned
    }

    func pauseHabit() {
        log("FocusButton: PauseHabit()")
        sendCmd("SET|PAUSE")
        applyState(.paused)
    }
    
    func resumeHabit() {
        log("FocusButton: ResumeHabit()")
        sendCmd("SET|RESUME")
        applyState(.running)
    }
    
    func cancelHabit() {
        log("FocusButton: finishHabit()")
        sendCmd("SET|CANCEL")
        applyState(.idle)
    }
    
    func removeHabits(habits: [(id: String, name: String, durationSeconds: Int)]) {
        if habits.isEmpty {
            log("FocusButton: !! No habits to remove.")
            return
        }
        
        let entries = habits.map { "\($0.id),\($0.name),0" }
        sendCmd("SET|HABITS|" + entries.joined(separator: "|"))
    }
    
    // MARK: - Serial Connection
    
    private func connect(portName: String) {
        log("FocusButton: Connect() to \(portName)")
        
        guard !isConnecting, serialPort?.isOpen != true else {
            log("FocusButton: Already connecting or connected")
            return
        }
        
        guard let port = ORSSerialPort(path: portName) else {
            log("FocusButton: Failed to create serial port for: \(portName)")
            return
        }
        
        isConnecting = true
        isValidatedFocusDevice = false
        serialPort = port

        port.baudRate = 115200//2000000
        port.parity = .none
        port.numberOfStopBits = 1
        port.numberOfDataBits = 8
        port.shouldEchoReceivedData = false

        // Do NOT assert DTR/RTS. On ESP32 boards these lines drive EN (reset) and GPIO0 via the
        // auto-reset circuit, so holding them high holds the chip in reset — the Focus Button freezes
        // on its splash screen for as long as the app is connected. Leaving them deasserted lets the
        // device boot and run its firmware normally.
        port.dtr = false
        port.rts = false

        port.delegate = self
        
        port.open()
        
        // Start RX reading thread
        isRunning = true
        rxThread = Thread { [weak self] in
            self?.rxLoop()
        }
        rxThread?.start()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            if self?.isConnecting == true && self?.serialPort?.isOpen != true {
                self?.log("FocusButton: Connection timeout")
                self?.onError?("Connection timeout - device not responding")
                self?.disconnect()
            }
        }
    }
    
    private func disconnect() {
        log("FocusButton: Disconnect()")

        emojiSync.cancel()   // stop any in-progress emoji upload / its retry timers
        teardownPort()

        reconnectAttempts = 0
        isReconnecting = false
        pendingCandidatePorts.removeAll()

        applyState(.disconnected)
        onPortDisconnected?()
        log("FocusButton: -- Disconnected")
    }

    // MARK: - Manual (user / external) disconnect

    /// True while a manual disconnect is in effect (auto-reconnect suppressed).
    var isManuallyDisconnected: Bool { userRequestedStayDisconnected }

    /// Manually disconnect and STAY disconnected: closes the serial port (releasing /dev/cu.usbmodem*,
    /// e.g. so firmware can be reflashed) and suppresses auto-reconnect until an explicit reconnect/
    /// start. Triggerable from the UI or from another process via FocusButtonCommandChannel.
    func manualDisconnect() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.log("FocusButton: manualDisconnect() — staying disconnected, suppressing auto-reconnect")
            self.userRequestedStayDisconnected = true
            self.disconnect()
        }
    }

    /// Clear a manual disconnect and reconnect.
    func manualReconnect() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.log("FocusButton: manualReconnect()")
            self.userRequestedStayDisconnected = false
            _ = self.start()
        }
    }

    /// Close and release the current serial port + RX thread + timers, without
    /// resetting the candidate list or notifying disconnect. Shared by
    /// disconnect() and the "reject this port, try the next one" path.
    private func teardownPort() {
        isRunning = false
        isConnecting = false
        responseCheckTimer?.invalidate()
        responseCheckTimer = nil
        validationTimer?.invalidate()
        validationTimer = nil

        if let port = serialPort {
            port.delegate = nil
            if port.isOpen {
                port.close()
            }
            serialPort = nil
        }

        rxThread?.cancel()
        rxThread = nil

        reconnectAttempts = 0
        isReconnecting = false
        isValidatedFocusDevice = false
        validationTimer?.invalidate()
        validationTimer = nil
        setFirmwareVersion(nil)

        applyState(.disconnected)
        onPortDisconnected?()
        log("FocusButton: -- Disconnected")
    }
    
    // MARK: - Serial Communication
    
    // MARK: - Emoji sync (habit-name emoji → RUNNING-ring bitmaps, firmware ≥ 1.7.0)

    /// Emoji-icon upload progress for UI (Add-ons screen sets this): (done, total) missing icons this
    /// sync. Delivered on the main thread.
    var onEmojiProgress: ((_ done: Int, _ total: Int) -> Void)?
    /// Progress for the FOCUS-mode emoji pool sync — separate from habit-icon progress even though both
    /// go through the one serial uploader (only one runs at a time). Delivered on the main thread.
    var onFocusEmojiProgress: ((_ done: Int, _ total: Int) -> Void)?
    private enum EmojiSyncKind { case habit, focus }
    private var emojiSyncKind: EmojiSyncKind = .habit

    /// Uploads the emoji in the loaded habit names to the device. Writes via `sendRawLine` (not
    /// `sendCmd`) so its ACK-gated lockstep isn't disrupted by the no-response STATUS watchdog.
    private lazy var emojiSync: EmojiSync = {
        let sync = EmojiSync(
            send: { [weak self] line in self?.sendRawLine(line) },
            log:  { [weak self] msg in self?.log(msg) })
        sync.onProgress = { [weak self] done, total in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch self.emojiSyncKind {
                case .habit: self.onEmojiProgress?(done, total)
                case .focus: self.onFocusEmojiProgress?(done, total)
                }
            }
        }
        return sync
    }()

    /// Firmware 1.7.0 added the emoji-bitmap commands. Parse the `M50-1.7.0` version and gate on it so
    /// we don't spray GET|EMOJILIST at older/other devices (which would just answer ERROR or nothing).
    private var firmwareSupportsEmoji: Bool {
        guard let v = firmwareVersion,
              let dash = v.firstIndex(of: "-") else { return false }
        let nums = v[v.index(after: dash)...].split(separator: ".").compactMap { Int($0) }
        guard nums.count >= 2 else { return false }
        return (nums[0], nums[1]) >= (1, 7)
    }

    /// Firmware 1.8.0 (Focus-Button #29) added the FOCUS-mode emoji pool (SET|FOCUSEMOJIS): the device
    /// picks one of up to 5 declared emoji at random when a plain FOCUS session starts.
    private var firmwareSupportsFocusEmoji: Bool {
        guard let v = firmwareVersion, let dash = v.firstIndex(of: "-") else { return false }
        let nums = v[v.index(after: dash)...].split(separator: ".").compactMap { Int($0) }
        guard nums.count >= 2 else { return false }
        return (nums[0], nums[1]) >= (1, 8)
    }

    /// Set the FOCUS-mode emoji pool (up to 5) the device randomly draws from at the start of each plain
    /// focus session. Declares the eligible keys with SET|FOCUSEMOJIS, then uploads any missing bitmaps
    /// via the same chunked SET|EMOJI path as habit emoji (cached keys are skipped; a declared key whose
    /// bitmap isn't cached yet falls back gracefully device-side). Call when the user's selection changes,
    /// not on every habit sync.
    func syncFocusEmojiPool(_ emoji: [String]) {
        guard firmwareSupportsFocusEmoji else { return }
        let keys = Array(EmojiSync.uniqueEmojiKeys(in: emoji).prefix(5))
        log("FocusButton: SET|FOCUSEMOJIS pool = [\(keys.joined(separator: ", "))]")
        sendRawLine("SET|FOCUSEMOJIS|" + keys.joined(separator: "|"))
        if firmwareSupportsEmoji, !emoji.isEmpty {
            emojiSyncKind = .focus
            emojiSync.syncEmojis(fromHabitNames: emoji)
        }
    }

    /// Write a raw line to the device without the command/response-check machinery. Used by the emoji
    /// uploader, which runs its own ACK-gated lockstep and must not have STATUS injected mid-transfer.
    func sendRawLine(_ line: String) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.sendRawLine(line) }
            return
        }
        guard let port = serialPort, port.isOpen, !isConnecting else { return }
        port.send((line + "\n").data(using: .utf8) ?? Data())
    }

    private func sendCmd(_ cmd: String) {
        // The serial write and the watchdog Timer scheduled below are run-loop bound, so every
        // command must go out on the main thread. The local "start focus" path already runs on the
        // main thread; the remote path (Pusher "focus-mode-started" handler) can fire on a background
        // thread, where the Timer never arms and the write silently no-ops — which is why starting a
        // session from the phone correctly started it on the Mac but never signalled the Focus Button.
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.sendCmd(cmd) }
            return
        }
        guard let port = serialPort, port.isOpen, !isConnecting else {
            log("FocusButton: Cannot send command - port not open")
            return
        }
        
        if cmd != "STATUS" {
            lastSentCmd = cmd
            pendingResponse = true
            
            // Start response check timer
            responseCheckTimer?.invalidate()
            responseCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.responseCheckTick()
            }
        }
        
        let command = cmd + "\n"
        log("FocusButton: SendCmd >> \(cmd)")
        
        // Send data (this doesn't throw, but may fail silently)
        port.send(command.data(using: .utf8) ?? Data())
    }
    
    private func responseCheckTick() {
        responseCheckTimer?.invalidate()
        
        guard pendingResponse else { return }
        pendingResponse = false
        
        log("FocusButton: ?? No response to '\(lastSentCmd)' — querying STATUS")
        
        if let port = serialPort, port.isOpen {
            sendCmd("STATUS")
        }
    }
    
    // MARK: - RX Loop
    
    private func rxLoop() {
        while isRunning {
            guard let port = serialPort, port.isOpen else {
                Thread.sleep(forTimeInterval: 0.1)
                continue
            }
            
            // ORSSerialPort uses delegate for incoming data
            // So we just keep the thread alive
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    // MARK: - Line Parser
    
    private func stripTimestamp(from line: String) -> String {
        if let match = tsPfx?.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           let range = Range(match.range, in: line) {
            return String(line[range.upperBound...])
        }
        return line
    }
    
    private func handleLine(_ raw: String) {
        // We received a valid response — disarm the response-check timer
        pendingResponse = false
        responseCheckTimer?.invalidate()
        
        let line = stripTimestamp(from: raw)
        log("FocusButton: HandleLine << \(line)")
        
        let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count > 0 else { return }
        
        switch parts[0].uppercased() {
        case "FIRMWAREVER":
            // Reply to GET|FIRMWAREVER, e.g. "FIRMWAREVER|M50-1.5.0". The hardware prefix identifies
            // the Focus device (M50 = M5Dial, C30 = VIEWE C3) — anything else is not one of our
            // devices. Also record the version for the settings display.
            if parts.count >= 2 {
                setFirmwareVersion(parts[1].trimmingCharacters(in: .whitespaces))
                let hw = parts[1].uppercased()
                if acceptedHardwarePrefixes.contains(where: { hw.hasPrefix($0) }) {
                    markValidatedFocusDevice(parts[1])
                } else {
                    log("FocusButton: Unrecognised FIRMWAREVER '\(parts[1])' — not a Focus device")
                }
            }

        case "INFO":
            // A STATUS reply also proves this is a Focus device (covers older
            // firmware that predates GET|FIRMWAREVER).
            markValidatedFocusDevice("INFO")
            handleInfo(parts)

        case "EVENT":
            handleEvent(parts)
            
        case "HABITCOUNT":
            if parts.count >= 2, let count = Int(parts[1]), count > 0 {
                for i in 1...count {
                    sendCmd("GET|HABIT|h\(i)")
                }
            }
            
        case "HABIT":
            if parts.count >= 4, let duration = Int64(parts[3]) {
                let habitId = parts[1]
                let habitName = parts[2]
                // Handle habit received
                onHabitsReceived?([(id: habitId, name: habitName, durationSeconds: duration)])
            }

        case "EMOJILIST", "EMOJI":
            emojiSync.handleDeviceLine(parts)

        case "ACK" where parts.count >= 2 && parts[1].uppercased() == "EMOJI":
            emojiSync.handleDeviceLine(parts)

        case "ERROR" where parts.count >= 2 && EmojiSync.isEmojiErrorCode(parts[1].lowercased()):
            emojiSync.handleDeviceLine(parts)

        default:
            break
        }
    }

    private func setFirmwareVersion(_ version: String?) {
        let newValue = (version?.isEmpty == true) ? nil : version
        guard newValue != firmwareVersion else { return }
        firmwareVersion = newValue
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: focusButtonService.firmwareVersionDidChange, object: self)
        }
    }
    
    private func handleInfo(_ parts: [String]) {
        guard parts.count >= 2 else { return }
        
        let newState: DeviceState
        switch parts[1].uppercased() {
        case "RUNNING": newState = .running
        case "PAUSED": newState = .paused
        case "IDLE": newState = .idle
        default: newState = state
        }
        
        if parts.count >= 3, let rem = Int64(parts[2]) {
            remainingSeconds = rem
            onRemainingTimeChanged?(rem)
        }


        applyState(newState)

        // If the device has fallen back to IDLE (splash) while a focus session is still running in
        // the app, re-establish the countdown so the button keeps showing the session.
        if newState == .idle, isFocusModeRunning, let end = endFocusModeTime {
            let remaining = Int(end.timeIntervalSinceNow)
            if remaining > 0 {
                log("FocusButton: device idle during a running focus session — re-pushing SET|START|\(remaining)")
                sendCmd("SET|START|\(remaining)")
                applyState(.running)
            }
        }
    }
    
    private func handleEvent(_ parts: [String]) {
        guard parts.count >= 2 else { return }
        
        switch parts[1].uppercased() {
        case "START", "STARTHB":
            
            if !isFocusModeRunning && parts[1].uppercased() == "START"{
                if parts.count >= 3, let total = Int64(parts[2]) {
                    sessionTotalSeconds = total
                    remainingSeconds = total
                    onRemainingTimeChanged?(total)
                    
                    let diffMinutes = Int(total/60)
                    
                    startFocusModeFromFocusDeviceButton(diffMinutes: diffMinutes, shouldUpdateFocusButton: false, goal: nil, initiatedByRecording: false)
                }
            }
            
            
            if parts[1].uppercased() == "STARTHB" && parts.count >= 4 {
                let name = parts[3].trimmingCharacters(in: .whitespaces).lowercased()
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                    
                    if currentAction != ._INPROGRESS_{
                        if currentState == ._MORNING_HABIT_{
                            getHabitsVcObject().startMorningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: false)
                        }else if currentState == ._EVENING_HABIT_{
                            getHabitsVcObject().startEveningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: false)
                        }
                    }
                }else {
                    if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_{
                        getHabitsVcObject().stopPostponeEndTimer()
                        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                        if currentState == ._POSTPONE_MORNING_HABIT_{
                            getHabitsVcObject().startMorningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: false)
                        }else if currentState == ._POSTPONE_EVENING_HABIT_{
                            getHabitsVcObject().startEveningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: false)
                        }
                    }
                    
                }
                
            }
            applyState(.running)
            
        case "PAUSE":
            if parts.count >= 3, let rem = Int64(parts[2]) {
                remainingSeconds = rem
                onRemainingTimeChanged?(rem)
                
                if isFocusModeRunning{
                    pauseFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: false)
                    return;
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                        log("FocusButton: Try pause habit")
                        if timerViewcontrollerObj != nil {
                            if currentAction == ._INPROGRESS_ && !(timerViewcontrollerObj?.isActivityPaused ?? false) && (timerViewcontrollerObj?.timer?.isValid ?? false){
                                if timerViewcontrollerObj?.timer != nil {
                                    log("FocusButton: Successfully paused habit")
                                    timerViewcontrollerObj?.btnPauseClicked(self)
                                }
                            }
                        }
                    }
                    
                }
                
            }
            applyState(.paused)
            
        case "RESUME":
            if parts.count >= 3, let rem = Int64(parts[2]) {
                remainingSeconds = rem
                onRemainingTimeChanged?(rem)
                
                if resumeFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: false){
                    log("FocusButton: Successfully Resumed focus mode from focus device button")
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                        log("FocusButton: Try resume habit")
                        if timerViewcontrollerObj != nil {
                            if currentAction == ._INPROGRESS_ && (timerViewcontrollerObj?.isActivityPaused ?? false){
                                if timerViewcontrollerObj?.timer != nil {
                                    log("FocusButton: Successfully resumed habit")
                                    timerViewcontrollerObj?.btnPauseClicked(self)
                                }
                            }
                        }
                    }
                }
            }
            applyState(.running)
            
        case "CANCEL":
            applyState(.idle)
            if isFocusModeOnOrPaused(){
                finishFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: false)
            }else{
                
            }
            
        case "DONE":
            applyState(.idle)
            
        case "LISTEN":
            if parts.count >= 3 {
                if parts[2].uppercased() == "START"{
                    recorder.requestPermissionAndStartRecording()
                    // A device-initiated recording runs with the menu closed, so the whole voice
                    // flow (listening → transcript → action/error) is invisible; tell the menu to
                    // surface itself in listening state.
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: VoiceEvents.deviceListening, object: nil)
                    }
                }else if parts[2].uppercased() == "END"{
                    recorder.stopRecording()
                }
            }
            
        default:
            break
        }
    }
  
    // MARK: - State Management
    
    private func applyState(_ newState: DeviceState) {
        state = newState
        onStateChanged?(newState)
    }
    
    /// All plausible Focus Button ports, in priority order, de-duplicated.
    ///
    /// Previously this returned a single "best" port and the caller held it
    /// blindly. It now returns every candidate so start()/tryNextCandidate() can
    /// probe each one and keep only the port that actually identifies as a Focus
    /// device — important when a non-Focus ESP32-S3 board (e.g. a StickS3) is
    /// plugged in alongside a real M5Dial. Only cu.usbmodem* ports qualify,
    /// matching the original behaviour.
    private func candidatePorts() -> [String] {
        log("FocusButton: candidatePorts()")

        // Priority buckets (highest first).
        let focusKeywords = ["FOCUSBUTTON", "FOCUS-BUTTON", "FOCUS BUTTON"]
        let espKeywords = ["ESP32", "ESP8266", "ESPRESSIF"]
        let m5Keywords = ["M5STACK", "M5 STACK"]
        let serialKeywords = [
            "CP210", "CP2102", "CP2104", "CP2105", "CP2108",
            "CH34", "CH340", "CH341", "CH343", "CH344", "CH347", "CH348", "CH349", "CH9101", "CH9102", "CH9103", "CH9104",
            "FTDI", "FT230", "FT231", "FT232", "FT234",
            "SILICON LABS",
            "PROLIFIC", "PL2303"
        ]

        var fb: [String] = [], esp: [String] = [], m5: [String] = [], kw: [String] = [], other: [String] = []

        for port in ORSSerialPortManager.shared().availablePorts {
            let portPath = port.path
            // Only cu.usbmodem* ports are eligible (as before).
            guard portPath.lowercased().contains("cu.usbmodem") else { continue }

            let portName = port.name.uppercased()
            let portPathUpper = portPath.uppercased()
            log("FocusButton: Checking port: \(portPath) - Name: \(port.name)")

            if focusKeywords.contains(where: { portName.contains($0) }) {
                fb.append(portPath)
            } else if espKeywords.contains(where: { portName.contains($0) }) || portPathUpper.contains("ESP") {
                esp.append(portPath)
            } else if m5Keywords.contains(where: { portName.contains($0) }) {
                m5.append(portPath)
            } else if serialKeywords.contains(where: { portName.contains($0) || portPathUpper.contains($0) }) {
                kw.append(portPath)
            } else {
                // A bare usbmodem device (native-USB ESP32 boards report no
                // useful name) — still a candidate, just lowest priority.
                other.append(portPath)
            }
        }

        // Concatenate in priority order, keeping first occurrence of each path.
        var seen = Set<String>()
        let ordered = (fb + esp + m5 + kw + other).filter { seen.insert($0).inserted }
        log("FocusButton: candidate ports (priority order): \(ordered)")
        return ordered
    }
    
    private func extractHexValue(from string: String) -> String? {
        // Extract hex value like 0x303A or 303A
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.hasPrefix("0x") {
            return String(trimmed.dropFirst(2))
        } else if let range = trimmed.range(of: "[0-9A-Fa-f]+", options: .regularExpression) {
            return String(trimmed[range])
        }
        
        return nil
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        //onLogMessage?(message)
        addLog(text: message)
        print(message) // Also print to console for debugging
    }
}

// MARK: - ORSSerialPortDelegate

extension focusButtonService: ORSSerialPortDelegate {
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        log("FocusButton: Serial port opened — probing device identity")

        isConnecting = false
        isValidatedFocusDevice = false

        // Probe the device before trusting it. We do NOT send SET|TIME or hold
        // the port for the app yet — that only happens once the device answers
        // as a Focus device (see markValidatedFocusDevice / handleLine). Sending
        // SET|TIME to an unknown board could poke a non-Focus device (e.g. a
        // StickS3 breathing sensor) we have no business writing to.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.serialPort?.isOpen == true else { return }
            self.sendCmd("GET|FIRMWAREVER")   // → FIRMWAREVER|M50-… on a Focus device
            self.sendCmd("STATUS")            // → INFO|… on a Focus device
        }

        // If nothing identifies as a Focus device in time, release this port and
        // move on to the next candidate.
        validationTimer?.invalidate()
        validationTimer = Timer.scheduledTimer(withTimeInterval: validationTimeout, repeats: false) { [weak self] _ in
            self?.validationTimedOut()
        }
    }

    /// Called once the connected device has identified itself as a Focus device
    /// (via FIRMWAREVER M50/C30 or a STATUS→INFO reply). Only now do we perform
    /// the real connection setup and tell the app we're connected.
    private func markValidatedFocusDevice(_ hardware: String) {
        guard !isValidatedFocusDevice else { return }
        isValidatedFocusDevice = true
        validationTimer?.invalidate()
        validationTimer = nil
        pendingCandidatePorts.removeAll()   // found our device; stop probing others
        let path = serialPort?.path ?? "?"
        log("FocusButton: Validated Focus device (\(hardware)) on \(path)")

        guard let port = serialPort, port.isOpen else { return }

        let localDate = Date()
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let localEpoch = Int64(localDate.timeIntervalSince1970) + Int64(timezoneOffset)
        sendCmd("SET|TIME|\(localEpoch)")
        sendCmd("GET|HABITCOUNT")

        applyState(.idle)
        hasEverConnected = true   // remember (persisted) so auto-reconnect kicks in after future drops
        DispatchQueue.main.async { [weak self] in
            self?.onDeviceConnected?(path)
            self?.onDeviceConnectedRestore?()   // re-push the running session/habit onto the device
        }
    }

    /// No Focus device identified on this port within the timeout — release it
    /// (so esptool/loggers/other apps can use it) and try the next candidate.
    private func validationTimedOut() {
        validationTimer?.invalidate()
        validationTimer = nil
        guard !isValidatedFocusDevice else { return }

        let path = serialPort?.path
        log("FocusButton: Port \(path ?? "?") did not identify as a Focus Button — releasing it")
        if let path = path {
            rejectedPorts.insert(path)   // don't re-grab this non-Focus device
        }
        teardownPort()
        tryNextCandidate()
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        log("FocusButton: Serial port closed")
        isConnecting = false
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        // Convert received data to string and process line by line
        guard let receivedString = String(data: data, encoding: .utf8) else { return }
        
        let lines = receivedString.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                // Skip ESP log noise
                if let espLog = espLog,
                   let match = espLog.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) {
                    continue
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.handleLine(trimmed)
                }
            }
        }
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        log("FocusButton: Serial port error: \(error.localizedDescription)")
        let message = error.localizedDescription
        DispatchQueue.main.async { [weak self] in
            self?.onError?("Connection error: \(message)")   // surface it to the settings UI
            self?.disconnect()
        }
    }
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        log("FocusButton: Serial port removed")
        DispatchQueue.main.async { [weak self] in
            self?.disconnect()
        }
    }
}


// MARK: - Firmware update / flashing

/// Checks Cloudflare R2 for newer Focus Button firmware and flashes it via esptool,
/// mirroring the Windows in-app updater. The published `focusbuttonupdate.ini` (an
/// `[application]` section with `program_version` and `program_url`) points at a
/// `Firmware-<board>.zip` containing firmware.bin (flashed at 0x10000);
/// bootloader/partitions are unchanged on an upgrade and a failed app-image
/// write never touches the bootloader, so the device stays recoverable.
final class FocusButtonFirmwareUpdater {
    static let shared = FocusButtonFirmwareUpdater()

    static let appOffset = "0x10000"

    /// Cloudflare R2 INI describing the latest published firmware. This is the macOS
    /// counterpart of the Windows app's `FocusButtonUpdateIniFileURL`, so both platforms
    /// pull firmware from the same place.
    private let updateIniURL = "https://downloads.focusbear.io/update/focusbutton/focusbuttonupdate.ini"

    enum UpdaterError: LocalizedError {
        case noReleaseFound
        case downloadFailed
        case firmwareBinMissing
        case esptoolNotFound
        case flashFailed(String)

        var errorDescription: String? {
            switch self {
            case .noReleaseFound:        return "Couldn't find any Focus Button firmware update information."
            case .downloadFailed:        return "Failed to download the firmware."
            case .firmwareBinMissing:    return "The downloaded firmware package didn't contain firmware.bin."
            case .esptoolNotFound:       return "esptool was not found. Install it with: brew install esptool"
            case .flashFailed(let m):    return "Flashing failed: \(m)"
            }
        }
    }

    /// A published firmware build: its version and the zip URL to download it from.
    struct Release { let version: String; let downloadURL: URL }

    /// Split a "M50-1.5.0" firmware string into (hardware: "M50", version: "1.5.0").
    static func parse(firmwareVersion: String) -> (hardware: String, version: String) {
        if let dash = firmwareVersion.firstIndex(of: "-") {
            return (String(firmwareVersion[..<dash]),
                    String(firmwareVersion[firmwareVersion.index(after: dash)...]))
        }
        return ("", firmwareVersion)
    }

    /// True if `latest` is a strictly higher semantic version than `installed`.
    /// Both may carry a leading "v"; missing components count as 0.
    static func isNewer(_ latest: String, than installed: String) -> Bool {
        func comps(_ s: String) -> [Int] {
            s.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                .split(separator: ".").map { Int($0.prefix(while: \.isNumber)) ?? 0 }
        }
        let a = comps(latest), b = comps(installed)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    /// Fetch the latest published firmware build from the Cloudflare R2 INI.
    /// Parses the `[application]` section's `program_version` and `program_url`,
    /// mirroring the Windows app's `ReadUpdateDetails`.
    func fetchLatestRelease() async throws -> Release {
        guard let url = URL(string: updateIniURL) else { throw UpdaterError.noReleaseFound }
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        // URLSession.data(for:) requires macOS 12; deployment target is 11, so use dataTask.
        let data = try await fetchData(for: req)
        guard let text = String(data: data, encoding: .utf8) else { throw UpdaterError.noReleaseFound }
        let ini = Self.parseINI(text)["application"] ?? [:]
        guard let version = ini["program_version"], !version.isEmpty,
              let urlStr = ini["program_url"], let downloadURL = URL(string: urlStr) else {
            throw UpdaterError.noReleaseFound
        }
        return Release(version: version, downloadURL: downloadURL)
    }

    /// Minimal INI parser: `[section]` headers and `key=value` lines (values may contain
    /// `=`). Comments (`;`/`#`) and blank lines are ignored; keys are lowercased.
    static func parseINI(_ text: String) -> [String: [String: String]] {
        var result: [String: [String: String]] = [:]
        var section = ""
        for rawLine in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix(";") || line.hasPrefix("#") { continue }
            if line.hasPrefix("[") && line.hasSuffix("]") {
                section = String(line.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces).lowercased()
            } else if let eq = line.firstIndex(of: "=") {
                let key = line[..<eq].trimmingCharacters(in: .whitespaces).lowercased()
                let value = line[line.index(after: eq)...].trimmingCharacters(in: .whitespaces)
                result[section, default: [:]][key] = value
            }
        }
        return result
    }

    /// Download + unzip the firmware package and return the firmware.bin URL.
    func downloadFirmwareBin(release: Release) async throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusButtonFirmware-\(release.version)", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let zip = dir.appendingPathComponent(release.downloadURL.lastPathComponent)
        // URLSession.download(from:) requires macOS 12; the deployment target is 11, so use
        // the downloadTask completion-handler API (macOS 10.9+) wrapped in a continuation.
        try await downloadFile(from: release.downloadURL, to: zip)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-o", zip.path, "-d", dir.path]
        try unzip.run(); unzip.waitUntilExit()

        let bin = dir.appendingPathComponent("firmware.bin")
        guard FileManager.default.fileExists(atPath: bin.path) else {
            throw UpdaterError.firmwareBinMissing
        }
        return bin
    }

    /// macOS 11-compatible data fetch. `URLSession.data(for:)` is macOS 12+, so this wraps the
    /// older `dataTask(with:completionHandler:)`.
    private func fetchData(for request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data = data else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: data)
            }
            task.resume()
        }
    }

    /// macOS 11-compatible file download. `URLSession.download(from:)` is macOS 12+, so this
    /// wraps the older `downloadTask(with:completionHandler:)` and moves the downloaded temp
    /// file to `destination` inside the handler (the temp file is removed once it returns).
    private func downloadFile(from url: URL, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let tempURL = tempURL else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                do {
                    try? FileManager.default.removeItem(at: destination)
                    try FileManager.default.moveItem(at: tempURL, to: destination)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }

    /// Locate an esptool executable: app bundle, common Homebrew/pip locations, then PATH.
    func resolveEsptool() -> String? {
        if let bundled = Bundle.main.url(forResource: "esptool", withExtension: nil)?.path,
           FileManager.default.isExecutableFile(atPath: bundled) {
            return bundled
        }
        let candidates = ["/opt/homebrew/bin/esptool", "/usr/local/bin/esptool",
                          "/opt/homebrew/bin/esptool.py", "/usr/local/bin/esptool.py"]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        for name in ["esptool", "esptool.py"] {
            let which = Process()
            which.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            which.arguments = ["which", name]
            let pipe = Pipe(); which.standardOutput = pipe
            try? which.run(); which.waitUntilExit()
            if which.terminationStatus == 0,
               let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !out.isEmpty {
                return out
            }
        }
        return nil
    }

    /// Flash firmware.bin at the app offset. Blocking — call off the main thread.
    /// The caller must release the serial port (focusButtonServiceObject.stop()) first.
    func flash(firmwareBin: URL, port: String, baud: Int = 460800) throws {
        guard let esptool = resolveEsptool() else { throw UpdaterError.esptoolNotFound }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: esptool)
        p.arguments = ["--port", port, "--baud", "\(baud)",
                       "--before", "default_reset", "--after", "hard_reset",
                       "write_flash", FocusButtonFirmwareUpdater.appOffset, firmwareBin.path]
        let pipe = Pipe()
        p.standardOutput = pipe; p.standardError = pipe
        do { try p.run() } catch { throw UpdaterError.flashFailed(error.localizedDescription) }
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            let tail = output.split(separator: "\n").suffix(4).joined(separator: " ")
            throw UpdaterError.flashFailed(tail.isEmpty ? "exit \(p.terminationStatus)" : tail)
        }
    }
}







