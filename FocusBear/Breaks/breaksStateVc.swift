//
//  breaksStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 12/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

class breaksStateVc: NSViewController {


    @IBOutlet weak var lblNextBreakTime: NSTextField!
    @IBOutlet weak var btnEnableMicroBreaks: Button!
    @IBOutlet weak var lblEnableBreaks: NSTextField!
    @IBOutlet weak var btnStartMicroBreaks: Button!

    var isViewVisible = false
    var timerReload:Timer?

    // Inline "breaks are off — pick a frequency and turn them back on" control, shown only in the
    // breaks-disabled state (SwiftUI, hosted over this AppKit view).
    private var freqPickerHost: NSView?

    /// The frequency the user has selected in the picker but NOT yet turned breaks on with (nil = no
    /// pending change). Drives (a) preserving the selection across the reload timer and (b) the
    /// "you changed the interval but didn't turn breaks on" prompt when leaving the tab.
    private var pendingFrequencyMinutes: Int?

    /// The saved break frequency (break_after_minutes), falling back to 60. What the picker seeds to.
    private var savedFrequencyMinutes: Int { breakAfterMinutes > 0 ? breakAfterMinutes : 60 }

    /// True when the picker is visible and the user picked a frequency different from the saved one
    /// without turning breaks on. Read by leftMenuVc before allowing a tab switch.
    var hasUnsavedFrequencyChange: Bool {
        guard let host = freqPickerHost, !host.isHidden else { return false }
        guard let pending = pendingFrequencyMinutes else { return false }
        return pending != savedFrequencyMinutes
    }

    /// Show the frequency picker filling this view; hides the plain label/button behind it. Seeded with
    /// the user's in-progress choice if any, else the current effective frequency (falls back to 60).
    private func showFrequencyPicker() {
        let seed = pendingFrequencyMinutes ?? savedFrequencyMinutes
        if freqPickerHost == nil {
            let view = BreakFrequencyEnableView(initialMinutes: seed, onChange: { [weak self] minutes in
                self?.pendingFrequencyMinutes = minutes
            }, onEnable: { [weak self] minutes in
                self?.enableBreaks(withFrequency: minutes)
            })
            let host = NSHostingView(rootView: view)
            host.translatesAutoresizingMaskIntoConstraints = false
            // The host is pinned to fill this view, so it must NOT impose the SwiftUI content's own size
            // on Auto Layout. The content uses maxHeight: .infinity to centre itself, which makes the
            // hosting view's intrinsic height enormous; with the required edge pins below, that forced the
            // window far taller than the intended small size (past the screen bounds). Let the edge
            // constraints alone size it.
            if #available(macOS 13.0, *) {
                host.sizingOptions = []
            } else {
                host.setContentHuggingPriority(.defaultLow, for: .vertical)
                host.setContentHuggingPriority(.defaultLow, for: .horizontal)
                host.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                host.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }
            self.view.addSubview(host)
            NSLayoutConstraint.activate([
                host.topAnchor.constraint(equalTo: self.view.topAnchor),
                host.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                host.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            ])
            freqPickerHost = host
        }
        freqPickerHost?.isHidden = false
    }

    private func hideFrequencyPicker() {
        freqPickerHost?.removeFromSuperview()
        freqPickerHost = nil
        pendingFrequencyMinutes = nil
    }

    /// Turn breaks on using the frequency the user has selected in the picker (called from the
    /// leave-tab confirm prompt in leftMenuVc).
    func turnOnBreaksWithPendingFrequency() {
        enableBreaks(withFrequency: pendingFrequencyMinutes ?? savedFrequencyMinutes)
    }

    /// Discard the in-progress picker selection (called from the leave-tab confirm prompt).
    func discardPendingFrequencyChange() {
        pendingFrequencyMinutes = nil
        hideFrequencyPicker()
    }

    /// Turn breaks back on with the chosen frequency (mirrors btnEnableMicroBreaksClicked, plus the
    /// frequency override the picker collected).
    private func enableBreaks(withFrequency minutes: Int) {
        addLog(text: "[user-action] breaksStateVc:- enable breaks from picker @ \(minutes) min")
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isMicroBreaksEnabled = true
        allApiObject.capturePosthog(event: "settings-changed-enable-breaks",
                                    metadata: ["break_frequency_minutes": "\(minutes)"])
        SettingsManagerObject.putUserLocalDeviceSettings()
        // Persist the chosen frequency to break_after_minutes (the single source of truth — synced to the
        // server and re-cached) rather than a separate local key that would then shadow the server value.
        // saveNewBreakFrequency also updates the live breakAfterMinutes global and restarts the break timer.
        BreakFrequencyStreakTracker.shared.saveNewBreakFrequency(minutes)
        hideFrequencyPicker()
        reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnEnableMicroBreaks.title = "Enable Breaks"
        btnStartMicroBreaks.title = "Start Break"
        
        if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
            btnEnableMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonEnableBreaks") as? String ?? btnEnableMicroBreaks.title
            btnStartMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonStartBreak") as? String ?? btnStartMicroBreaks.title
        }
    }
    
    override func viewWillAppear() {
        isViewVisible = true
        reloadData()
        
        self.timerReload?.invalidate()
        self.timerReload = nil
        DispatchQueue.global().sync {
            self.timerReload = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.reloadIfNeeded), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerReload!), forMode: RunLoop.Mode.common)
        }
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
        self.timerReload?.invalidate()
        self.timerReload = nil
    }
    
    @objc func reloadIfNeeded(){
        if isViewVisible{
            reloadData()
        }else{
            self.timerReload?.invalidate()
            self.timerReload = nil
        }
    }

    func reloadData() {
        addLog(text:"breaksStateVc:- reloadData")
        // Only tear the picker down when we're NOT going to show it. Otherwise leave the existing host in
        // place (showFrequencyPicker no-ops when it already exists) so the user's in-progress selection
        // survives the 3-second reload timer — recreating it every tick reset the choice back to current.
        let willShowFrequencyPicker = arrAllbreakActivities.count > 0 && isAppEnable && !SettingsManagerObject.isMicroBreaksEnabled
        if !willShowFrequencyPicker {
            hideFrequencyPicker()
        }
        if arrAllbreakActivities.count == 0 {
            btnEnableMicroBreaks.title = "Edit Habits"
            lblEnableBreaks.stringValue = "No break activities added yet."

            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnEnableMicroBreaks.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? btnEnableMicroBreaks.title
            }
            
            if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "noBreakAddedText") as? String ?? lblEnableBreaks.stringValue
            }
            
            lblEnableBreaks.isHidden = false
            btnEnableMicroBreaks.isHidden = false
            lblNextBreakTime.isHidden = true
            btnStartMicroBreaks.isHidden = true
            return;
        }
        
        if !isAppEnable{
            btnEnableMicroBreaks.title = "Activate Distraction Blocking"
            lblEnableBreaks.stringValue = "Distraction Blocking is currently paused. You can turn it back on anytime to stay focused."

            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                btnEnableMicroBreaks.title = menuInfo.value(forKey: "menuItemReactivateTitle") as? String ?? btnEnableMicroBreaks.title
            }
            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                lblEnableBreaks.stringValue = habitsStateVcInfo.value(forKey: "titleAppDisabled") as? String ?? lblEnableBreaks.stringValue
            }
            
            lblEnableBreaks.isHidden = false
            btnEnableMicroBreaks.isHidden = false
            lblNextBreakTime.isHidden = true
            btnStartMicroBreaks.isHidden = true
            return;
        }
        
        btnEnableMicroBreaks.title = "Enable Breaks"
        btnStartMicroBreaks.title = "Start Break"
        
        if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
            btnEnableMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonEnableBreaks") as? String ?? btnEnableMicroBreaks.title
            btnStartMicroBreaks.title = breakStateVcInfo.value(forKey: "buttonStartBreak") as? String ?? btnStartMicroBreaks.title
        }
        var isBreakEnabled = SettingsManagerObject.isMicroBreaksEnabled
        
        if !isBreakEnabled{
            // Breaks turned off → let the user pick a frequency and turn them back on right here, instead
            // of just a plain "Enable Breaks" button.
            lblEnableBreaks.isHidden = true
            btnEnableMicroBreaks.isHidden = true
            lblNextBreakTime.isHidden = true
            btnStartMicroBreaks.isHidden = true
            showFrequencyPicker()
            return;
        }
        if let disableBreaksForTodayDate = UserDefaults.standard.object(forKey: kUserdefaultsDisableBreaksForToday) as? Date{
            if Calendar.current.isDateInToday(disableBreaksForTodayDate){
                isBreakEnabled = false
                lblEnableBreaks.stringValue = "You’ve paused breaks for today. They’ll be back tomorrow to help you recharge and focus."
                if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                    lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "pausedBreaksText") as? String ?? lblEnableBreaks.stringValue
                }
                lblEnableBreaks.isHidden = false
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = true
                btnStartMicroBreaks.isHidden = true
                return;
            }
        }
        
        if getHabitsVcObject().breakTimer != nil && isBreakEnabled{
            if getHabitsVcObject().breakTimer!.isValid{
              //  boxNextBreak.isHidden = false
                let currentTime = Date()
                let breakTime = getHabitsVcObject().breakTimer!.fireDate
                let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                var timeText = "\(diffMinute) \(minutesText)"
                if diffMinute < 1{
                    timeText = "< 1 \(minuteText)"
                }
                var nextBreakText = "Next break in: <DURATION>"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    nextBreakText = menuInfo.value(forKey: "nextBreakText") as? String ?? nextBreakText
                }
                nextBreakText = nextBreakText.replacingOccurrences(of: "<DURATION>", with: timeText)
                lblNextBreakTime.stringValue = nextBreakText
                
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
                if diffMinute < 1{//show the break as soon as there are 5 seconds of inactivity
                    let diffSeconds = Calendar.current.dateComponents([.second], from: currentTime, to: breakTime).second ?? 0
                    if diffSeconds < 5{
                        lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                        }
                    }
                }
            }
        }else{
            if isShutOffTimeGoing(){
                lblEnableBreaks.isHidden = false
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = true
                btnStartMicroBreaks.isHidden = true
                lblEnableBreaks.stringValue = "App is in shutoff state"
                if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                    lblEnableBreaks.stringValue = breakStateVcInfo.value(forKey: "shutoffTimeText") as? String ?? lblEnableBreaks.stringValue
                }
            }else if currentState == ._MICRO_BREAK_{ // if by any chance user is on this view (for example break warning is visible beacuse during warning state is micro break)
                lblNextBreakTime.stringValue = "It's time for a break. Waiting for a good moment"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    lblNextBreakTime.stringValue = menuInfo.value(forKey: "waitingBreakTimeText") as? String ?? lblNextBreakTime.stringValue
                }
                
                
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
            }else if getHabitsVcObject().breakTimer == nil{
                lblNextBreakTime.stringValue = "No upcoming break has been scheduled yet."
                if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
                    lblNextBreakTime.stringValue = breakStateVcInfo.value(forKey: "noBreakScheduledText") as? String ?? lblNextBreakTime.stringValue
                }
                lblEnableBreaks.isHidden = true
                btnEnableMicroBreaks.isHidden = true
                lblNextBreakTime.isHidden = false
                btnStartMicroBreaks.isHidden = false
            }
        }
    }
    
    @IBAction func btnEnableMicroBreaksClicked(_ sender: Any) {
        if arrAllbreakActivities.count == 0 {
            addLog(text:"[user-action] habitsStateVc:- No break activities added :- button Edit Habits clicked")
            leftMenuVcObj?.showEditHabitsView()
            return;
        }
        
        if !isAppEnable{
            addLog(text:"[user-action] breaksStateVc:- button Reactivate clicked")
            appdelegate?.menuItem_Reactivate()
            return;
        }
        addLog(text:"[user-action] breaksStateVc:- button Enable breaks clicked")
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isMicroBreaksEnabled = true
        allApiObject.capturePosthog(event: "settings-changed-enable-breaks", metadata: [:])
        SettingsManagerObject.putUserLocalDeviceSettings()
        reloadData()
    }
    
    @IBAction func btnStartMicroBreaksClicked(_ sender: Any) {
        addLog(text:"[user-action] breaksStateVc:- button Start Micro breaks clicked")
        menuViewControllerObj?.btnStartBreakClicked(self)
    }

}

// MARK: - Break-frequency enable control (SwiftUI)

/// Shown when breaks are turned off: reminds the user why breaks help, lets them choose how often they'd
/// like one, and turns breaks back on with that frequency in a single tap — so they can re-enable AND
/// re-tune the frequency without leaving this screen.
struct BreakFrequencyEnableView: View {
    let onChange: (Int) -> Void
    let onEnable: (Int) -> Void

    private static let presets = [30, 45, 60, 90, 120]
    // The app defines global `State`/`Button` types that shadow SwiftUI's — qualify them.
    @SwiftUI.State private var minutes: Int

    init(initialMinutes: Int, onChange: @escaping (Int) -> Void, onEnable: @escaping (Int) -> Void) {
        self.onChange = onChange
        self.onEnable = onEnable
        let seed = BreakFrequencyEnableView.presets.contains(initialMinutes) ? initialMinutes : 60
        _minutes = SwiftUI.State(initialValue: seed)
    }

    /// Reads a translated string from the `breakStateVcInfo` config block, falling back to English.
    static func configText(_ key: String, _ fallback: String) -> String {
        (configjson.value(forKey: "breakStateVcInfo") as? NSDictionary)?.value(forKey: key) as? String ?? fallback
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(BreakFrequencyEnableView.configText("breakFrequencyTitleText", "Breaks are off"))
                .font(.system(size: 20, weight: .semibold))
            Text(BreakFrequencyEnableView.configText("breakFrequencyDescriptionText", "Regular breaks keep your energy, focus and posture up. Choose how often you'd like one, then turn breaks back on."))
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Picker("", selection: $minutes) {
                ForEach(BreakFrequencyEnableView.presets, id: \.self) { Text("\($0) min").tag($0) } // i18n-ignore
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .frame(maxWidth: 340)
            .onChange(of: minutes) { newValue in onChange(newValue) }
            Text(BreakFrequencyEnableView.configText("breakFrequencyEveryText", "A break every <MINUTES> minutes")
                .replacingOccurrences(of: "<MINUTES>", with: "\(minutes)"))
                .font(.caption)
                .foregroundColor(.secondary)
            SwiftUI.Button(BreakFrequencyEnableView.configText("breakFrequencyEnableButtonText", "Turn breaks on")) { onEnable(minutes) }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 40))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
