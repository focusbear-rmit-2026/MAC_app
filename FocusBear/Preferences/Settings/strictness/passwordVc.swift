//
//  passwordVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/03/22.


import Cocoa

class passwordVc: NSViewController {
    @IBOutlet weak var lblTitleMain: NSTextField!
    @IBOutlet weak var checkBoxSkipEveningHabitAfterCutOff: NSButton!
    @IBOutlet weak var checkBoxQuitApp: NSButton!
    @IBOutlet weak var checkBoxStopPomodoro: NSButton!
    @IBOutlet weak var checkBoxAbortingShutoff: NSButton!
    @IBOutlet weak var checkBoxSkipEveningHabit: NSButton!
    @IBOutlet weak var checkBoxSkipMorningHabit: NSButton!
    @IBOutlet weak var checkBoxChangeSettings: NSButton!
    @IBOutlet weak var checkBoxUseRelaxFocusMode: NSButton!
    @IBOutlet weak var checkBoxCircumventingBlocks: NSButton!
    @IBOutlet weak var checkBoxOpenPreferencesAfterCutOff: NSButton!
    
    @IBOutlet weak var lblCheckBoxSkipEveningHabitAfterCutOff: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxQuitApp: NSTextField!
    @IBOutlet weak var lblCheckBoxStopPomodoro: NSTextField!
    @IBOutlet weak var lblCheckBoxAbortingShutoff: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipEveningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxSkipMorningHabit: NSTextField!
    @IBOutlet weak var lblCheckBoxChangeSettings: NSTextField!
    @IBOutlet weak var lblCheckBoxUseRelaxFocusMode: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxCircumventingBlocks: ignoreMouseTextField!
    @IBOutlet weak var lblCheckBoxOpenPreferencesAfterCutOff: ignoreMouseTextField!
    
    @IBOutlet weak var lblQuestionPassword: NSTextField!
    @IBOutlet weak var lblTitleAskPassword: NSTextField!
    @IBOutlet weak var btnDisablePassword: NSButton!
    @IBOutlet weak var lblConfirmPassword: NSTextField!
    @IBOutlet weak var lblNewPassword: NSTextField!
    @IBOutlet weak var lblPasswordState: NSTextField!
    @IBOutlet weak var lblInfo: NSTextField!
    @IBOutlet weak var btnChangePassword: NSButton!
    @IBOutlet weak var textFieldNewPassword: NSSecureTextField!
    @IBOutlet weak var textFieldConfirmPassword: NSSecureTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    @IBOutlet weak var btnInfoSetPassword: hoverInfoButton!
    
    @IBOutlet weak var btnInfoChangeSettings: hoverInfoButton!
    @IBOutlet weak var btnInfoSkipMorningHabit: hoverInfoButton!
    @IBOutlet weak var btnInfoSkipEveningHabit: hoverInfoButton!
    @IBOutlet weak var btnSkipEveningHabitAfterCutOff: hoverInfoButton!
    @IBOutlet weak var btnInfoAbortingShutoff: hoverInfoButton!
    @IBOutlet weak var btnInfoStopPomodoro: hoverInfoButton!
    @IBOutlet weak var btnInfoQuitApp: hoverInfoButton!
    @IBOutlet weak var btnInfoUseRelaxFocusMode: hoverInfoButton!
    @IBOutlet weak var btnInfoCircumventingBlocks: hoverInfoButton!
    
    @IBOutlet weak var btnInfoOpenPreferencesAfterCutOff: hoverInfoButton!
    
    
    
    let viewHeightDefault = 511
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleMain.stringValue = "Password"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitleMain.stringValue = settingsNew.value(forKey: "passwordSettingTitle") as? String ?? lblTitleMain.stringValue
        }
        lblCheckBoxUseRelaxFocusMode.stringValue = "Allow using relax focus mode"
        lblTitleAskPassword.stringValue = "Ask for password:"
        lblQuestionPassword.stringValue = "When do you want to require a password?"
       
        lblCheckBoxQuitApp.stringValue = "Quitting/deactivating app"
        lblCheckBoxStopPomodoro.stringValue = "Stopping Super pomodoro mode"
        lblCheckBoxAbortingShutoff.stringValue = "Aborting shutoff"
        lblCheckBoxSkipEveningHabit.stringValue = "Skipping evening routine"
        lblCheckBoxSkipMorningHabit.stringValue = "Skipping morning routine"
        lblCheckBoxChangeSettings.stringValue = "Changing settings"
        
        
        lblCheckBoxCircumventingBlocks.stringValue = "Changing settings that allow circumventing blocks"
        btnDisablePassword.title = "Disable Password"
        lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = "Skipping evening routine after cutoff time"
        
        lblCheckBoxOpenPreferencesAfterCutOff.stringValue = "Require password for opening Preferences after cutoff time"
        
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{

            btnDisablePassword.title = passwordPreferencesInfo.value(forKey: "buttonDisablePasswordText") as? String ?? btnDisablePassword.title
            lblTitleAskPassword.stringValue = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String ?? lblTitleAskPassword.stringValue
            lblQuestionPassword.stringValue = passwordPreferencesInfo.value(forKey: "questionPassword") as? String ?? lblQuestionPassword.stringValue
            lblCheckBoxQuitApp.stringValue = passwordPreferencesInfo.value(forKey: "buttonQuitAppText") as? String ?? lblCheckBoxQuitApp.stringValue
            lblCheckBoxStopPomodoro.stringValue = passwordPreferencesInfo.value(forKey: "buttonStopPomodoroText") as? String ?? lblCheckBoxStopPomodoro.stringValue
            lblCheckBoxAbortingShutoff.stringValue = passwordPreferencesInfo.value(forKey: "buttonAbortingShutoffText") as? String ?? lblCheckBoxAbortingShutoff.stringValue
            lblCheckBoxSkipEveningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitText") as? String ?? lblCheckBoxSkipEveningHabit.stringValue
            lblCheckBoxSkipMorningHabit.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipMorningHabitText") as? String ?? lblCheckBoxSkipMorningHabit.stringValue
            lblCheckBoxChangeSettings.stringValue = passwordPreferencesInfo.value(forKey: "buttonChangeSettingsText") as? String ?? lblCheckBoxChangeSettings.stringValue
            lblCheckBoxSkipEveningHabitAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonSkipEveningHabitAfterCutOffText") as? String ?? lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
            lblCheckBoxUseRelaxFocusMode.stringValue = passwordPreferencesInfo.value(forKey: "buttonUseRelaxFocusModeText") as? String ?? lblCheckBoxUseRelaxFocusMode.stringValue
            lblCheckBoxCircumventingBlocks.stringValue = passwordPreferencesInfo.value(forKey: "buttonCircumventingBlocksText") as? String ?? lblCheckBoxCircumventingBlocks.stringValue
            lblCheckBoxOpenPreferencesAfterCutOff.stringValue = passwordPreferencesInfo.value(forKey: "buttonOpenPreferencesAfterCutOffText") as? String ?? lblCheckBoxOpenPreferencesAfterCutOff.stringValue
        }
        

        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            if let titleChangePassword = passwordPreferencesInfo.value(forKey: "titleChangePassword") as? String{
                arrForSearchFromSettings.append(["title": titleChangePassword, "tabId": idPassword, "object": lblTitle as Any])
            }
            if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
                arrForSearchFromSettings.append(["title": titleSetPassword, "tabId": idPassword, "object": lblTitle as Any])
            }
            if let title = passwordPreferencesInfo.value(forKey: "titleAskPassword") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": idPassword, "object": lblTitleAskPassword as Any])
            }
        }
            
         
        
        checkBoxChangeSettings.toolTip = lblCheckBoxChangeSettings.stringValue
        checkBoxSkipMorningHabit.toolTip = lblCheckBoxSkipMorningHabit.stringValue
        checkBoxSkipEveningHabit.toolTip = lblCheckBoxSkipEveningHabit.stringValue
        checkBoxSkipEveningHabitAfterCutOff.toolTip = lblCheckBoxSkipEveningHabitAfterCutOff.stringValue
        checkBoxAbortingShutoff.toolTip = lblCheckBoxAbortingShutoff.stringValue
        checkBoxStopPomodoro.toolTip = lblCheckBoxStopPomodoro.stringValue
        checkBoxQuitApp.toolTip = lblCheckBoxQuitApp.stringValue
        checkBoxUseRelaxFocusMode.toolTip = lblCheckBoxUseRelaxFocusMode.stringValue
        checkBoxCircumventingBlocks.toolTip = lblCheckBoxCircumventingBlocks.stringValue
        
        checkBoxOpenPreferencesAfterCutOff.toolTip = lblCheckBoxOpenPreferencesAfterCutOff.stringValue

        setupPostponeCheckboxes()
    }

    // MARK: Postpone password checkboxes (separate from Skip) — added in code, just below the skip
    // rows. Local device settings, persisted to UserDefaults.
    private var checkBoxPostponeMorning: NSButton?
    private var checkBoxPostponeEvening: NSButton?
    private var checkBoxPostponeAfterCutOff: NSButton?
    private var btnInfoPostponeMorning: hoverInfoButton?
    private var btnInfoPostponeEvening: hoverInfoButton?
    private var btnInfoPostponeAfterCutOff: hoverInfoButton?
    // "Shortening habits on the Day Plan" — added in code directly below the postpone rows. Synced
    // under kIsPasswordRequireInShortenHabits (the same key the Windows app uses).
    private var checkBoxShortenHabits: NSButton?
    private var btnInfoShortenHabits: hoverInfoButton?

    private func setupPostponeCheckboxes() {
        // The skip/action password checkboxes are constraint-chained siblings in a plain view (NOT an
        // NSStackView) — each row's top is pinned to the previous row's bottom. Insert the three postpone
        // checkboxes into that chain directly below the "skip evening after cutoff" row: re-hang whatever
        // currently sits below the anchor beneath the last postpone row instead.
        guard let anchor = checkBoxSkipEveningHabitAfterCutOff, let container = anchor.superview else { return }
        func make(_ title: String, _ action: Selector) -> NSButton {
            let cb = NSButton(checkboxWithTitle: title, target: self, action: action)
            cb.translatesAutoresizingMaskIntoConstraints = false
            return cb
        }
        // Config-driven titles (passwordPreferencesInfo), matching the skip rows, with English fallbacks.
        var titleMorning = "Postponing morning routine"
        var titleEvening = "Postponing evening routine"
        var titleAfterCutOff = "Postponing evening routine after cutoff time"
        var titleShorten = "Shortening habits on the Day Plan"
        if let info = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary {
            titleMorning = info.value(forKey: "buttonPostponeMorningHabitText") as? String ?? titleMorning
            titleEvening = info.value(forKey: "buttonPostponeEveningHabitText") as? String ?? titleEvening
            titleAfterCutOff = info.value(forKey: "buttonPostponeEveningHabitAfterCutOffText") as? String ?? titleAfterCutOff
            titleShorten = info.value(forKey: "buttonShortenHabitsText") as? String ?? titleShorten
        }
        let m = make(titleMorning, #selector(checkBoxPostponeMorningClicked))
        let e = make(titleEvening, #selector(checkBoxPostponeEveningClicked))
        let c = make(titleAfterCutOff, #selector(checkBoxPostponeAfterCutOffClicked))
        let sh = make(titleShorten, #selector(checkBoxShortenHabitsClicked))
        sh.toolTip = titleShorten
        checkBoxPostponeMorning = m; checkBoxPostponeEvening = e; checkBoxPostponeAfterCutOff = c
        checkBoxShortenHabits = sh

        // The constraint that currently hangs the next row below the anchor (anchor.bottom -> next.top).
        let followingTop = container.constraints.first {
            $0.firstAttribute == .top && $0.secondAttribute == .bottom &&
            ($0.secondItem as? NSView) === anchor && ($0.firstItem as? NSView) !== anchor
        }
        let followingView = followingTop?.firstItem as? NSView
        let spacing: CGFloat = 10
        let followingSpacing = followingTop?.constant ?? spacing
        followingTop?.isActive = false

        for cb in [m, e, c, sh] { container.addSubview(cb) }
        var constraints: [NSLayoutConstraint] = []
        var previous: NSView = anchor
        for cb in [m, e, c, sh] {
            constraints.append(cb.leadingAnchor.constraint(equalTo: anchor.leadingAnchor))
            constraints.append(cb.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: spacing))
            previous = cb
        }
        // Reconnect the row that used to follow the anchor beneath the last postpone row (if any).
        if let following = followingView {
            constraints.append(following.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: followingSpacing))
        }
        NSLayoutConstraint.activate(constraints)

        setupPostponeInfoButtons(in: container)
        refreshPostponeCheckboxStates()
    }

    /// Adds an NSInfo hover-info button in the right-edge column for each postpone row, matching the
    /// skip rows. centerX aligns to an existing skip-row info button's column; centerY to each checkbox.
    private func setupPostponeInfoButtons(in container: NSView) {
        guard let m = checkBoxPostponeMorning, let e = checkBoxPostponeEvening, let c = checkBoxPostponeAfterCutOff,
              let sh = checkBoxShortenHabits else { return }
        let columnRef: NSView? = btnSkipEveningHabitAfterCutOff ?? btnInfoSkipEveningHabit
        func makeInfo(_ action: Selector) -> hoverInfoButton {
            let b = hoverInfoButton()
            b.translatesAutoresizingMaskIntoConstraints = false
            b.bezelStyle = .shadowlessSquare
            b.isBordered = false
            b.imagePosition = .imageOnly
            b.imageScaling = .scaleProportionallyUpOrDown
            b.image = NSImage(named: NSImage.infoName)
            b.target = self
            b.action = action
            // hoverInfoButton.awakeFromNib installs this tracking area (hover auto-shows the tooltip);
            // replicate it here since programmatically-created views don't get awakeFromNib.
            b.addTrackingArea(NSTrackingArea(rect: .zero, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: b, userInfo: nil))
            return b
        }
        let im = makeInfo(#selector(btnInfoPostponeMorningClicked))
        let ie = makeInfo(#selector(btnInfoPostponeEveningClicked))
        let ic = makeInfo(#selector(btnInfoPostponeAfterCutOffClicked))
        let ish = makeInfo(#selector(btnInfoShortenHabitsClicked))
        btnInfoPostponeMorning = im; btnInfoPostponeEvening = ie; btnInfoPostponeAfterCutOff = ic
        btnInfoShortenHabits = ish

        var cons: [NSLayoutConstraint] = []
        for (btn, row) in [(im, m), (ie, e), (ic, c), (ish, sh)] {
            container.addSubview(btn)
            cons.append(btn.widthAnchor.constraint(equalToConstant: 16))
            cons.append(btn.heightAnchor.constraint(equalToConstant: 16))
            cons.append(btn.centerYAnchor.constraint(equalTo: row.centerYAnchor))
            if let ref = columnRef {
                cons.append(btn.centerXAnchor.constraint(equalTo: ref.centerXAnchor))
            } else {
                cons.append(btn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14))
            }
        }
        NSLayoutConstraint.activate(cons)
    }

    private func refreshPostponeCheckboxStates() {
        checkBoxPostponeMorning?.state = SettingsManagerObject.isPasswordRequireInPostponeMorning ? .on : .off
        checkBoxPostponeEvening?.state = SettingsManagerObject.isPasswordRequireInPostponeEvening ? .on : .off
        checkBoxPostponeAfterCutOff?.state = SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff ? .on : .off
        checkBoxShortenHabits?.state = SettingsManagerObject.isPasswordRequireInShortenHabits ? .on : .off
    }

    private func setPostpone(_ value: Bool, key: String, set: (Bool) -> Void) {
        SettingsManagerObject.isSettingsChanged = true
        set(value)
        UserDefaults.standard.set(value, forKey: key)
    }

    @objc private func checkBoxPostponeMorningClicked() {
        setPostpone(checkBoxPostponeMorning?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeMorning) { SettingsManagerObject.isPasswordRequireInPostponeMorning = $0 }
    }
    @objc private func checkBoxPostponeEveningClicked() {
        setPostpone(checkBoxPostponeEvening?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeEvening) { SettingsManagerObject.isPasswordRequireInPostponeEvening = $0 }
    }
    @objc private func checkBoxPostponeAfterCutOffClicked() {
        setPostpone(checkBoxPostponeAfterCutOff?.state == .on, key: SettingsManagerObject.kUserdefaultsPasswordRequireInPostponeEveningAfterCutOff) { SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff = $0 }
    }

    @objc private func checkBoxShortenHabitsClicked() {
        let isOn = checkBoxShortenHabits?.state == .on
        setPostpone(isOn, key: SettingsManagerObject.kUserdefaultsPasswordRequireInShortenHabits) { SettingsManagerObject.isPasswordRequireInShortenHabits = $0 }
        allApiObject.capturePosthog(event: isOn ? "require-password-in-shorten-habits-enabled" : "require-password-in-shorten-habits-disabled", metadata: [:])
    }

    @objc private func btnInfoShortenHabitsClicked() {
        var toolTip = "Enable this to require your password when shortening a habit from the Day Plan, so the choice stays intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary {
            toolTip = tooltips.value(forKey: "strictness_Password_ShortenHabits") as? String ?? toolTip
        }
        if let s = btnInfoShortenHabits { showTooltip(sender: s, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal: 350) }
    }

    @objc private func btnInfoPostponeMorningClicked() {
        var toolTip = "Enable this to require your password when postponing your morning routine, so the choice stays intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary {
            toolTip = tooltips.value(forKey: "strictness_Password_PostponeMorningHabit") as? String ?? toolTip
        }
        if let s = btnInfoPostponeMorning { showTooltip(sender: s, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal: 350) }
    }
    @objc private func btnInfoPostponeEveningClicked() {
        var toolTip = "Enable this to require your password when postponing your evening routine, so the choice stays intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary {
            toolTip = tooltips.value(forKey: "strictness_Password_PostponeEveningHabit") as? String ?? toolTip
        }
        if let s = btnInfoPostponeEvening { showTooltip(sender: s, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal: 350) }
    }
    @objc private func btnInfoPostponeAfterCutOffClicked() {
        var toolTip = "Enable this to require your password when postponing your evening routine after the cutoff time, so the choice stays intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary {
            toolTip = tooltips.value(forKey: "strictness_Password_PostponeEveningHabitAfterCutOffTime") as? String ?? toolTip
        }
        if let s = btnInfoPostponeAfterCutOff { showTooltip(sender: s, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal: 350) }
    }

    override func viewWillAppear() {
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
//            preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: (preferencesWindowControllerObj?.settingsTabDefaultWidthForBigFonts ?? 0) + (preferencesWindowControllerObj?.extraSpaceWidthInSettingsTab ?? 0), height: viewHeightDefault + (preferencesWindowControllerObj?.extraSpaceHeightInSettingsTab ?? 0)))
        }else{
//            preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: (preferencesWindowControllerObj?.settingsTabDefaultWidth ?? 0) + (preferencesWindowControllerObj?.extraSpaceWidthInSettingsTab ?? 0), height: viewHeightDefault + (preferencesWindowControllerObj?.extraSpaceHeightInSettingsTab ?? 0)))
        }
        resetView()
    }//your password has been disabled.
    //

    override func viewDidAppear() {
        super.viewDidAppear()
        // Always reset the settings list to the top whenever this screen is shown (it may have been left
        // scrolled down from a previous visit). Deferred so it runs after the final layout pass.
        DispatchQueue.main.async { [weak self] in self?.scrollToTop() }
    }

    private func scrollToTop() {
        guard let scrollView = checkBoxSkipMorningHabit?.enclosingScrollView ?? view.enclosingScrollView,
              let docView = scrollView.documentView else { return }
        let clip = scrollView.contentView
        // Top is y=0 for a flipped document view, else the highest y (content height minus the visible height).
        let topY = docView.isFlipped ? 0 : max(0, docView.bounds.height - clip.bounds.height)
        clip.setBoundsOrigin(NSPoint(x: clip.bounds.origin.x, y: topY))
        scrollView.reflectScrolledClipView(clip)
    }

    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here
        btnChangePassword.title = btnChangePassword.title
    }
    
    func resetView(){
        textFieldNewPassword.stringValue = ""
        textFieldConfirmPassword.stringValue = ""
        lblNewPassword.stringValue = "New Password"
        lblConfirmPassword.stringValue = "Confirm Password"

        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
            lblTitle.stringValue = "Set Password"
            btnChangePassword.title = "Set Password"
            textFieldNewPassword.placeholderString = "New Password"
            textFieldConfirmPassword.placeholderString = "Confirm Password"
            lblPasswordState.stringValue = "You do not have a password set."
            
            btnDisablePassword.isHidden = true
            
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleSetPassword = passwordPreferencesInfo.value(forKey: "titleSetPassword") as? String{
                    lblTitle.stringValue = titleSetPassword
                }
                if let buttonSetPasswordText = passwordPreferencesInfo.value(forKey: "buttonSetPasswordText") as? String{
                    btnChangePassword.title = buttonSetPasswordText
                }
                if let newPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "newPasswordPlaceholderText") as? String{
                    textFieldNewPassword.placeholderString = newPasswordPlaceholderText
                    lblNewPassword.stringValue = newPasswordPlaceholderText
                }
                if let confirmPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "confirmPasswordPlaceholderText") as? String{
                    textFieldConfirmPassword.placeholderString = confirmPasswordPlaceholderText
                    lblConfirmPassword.stringValue = confirmPasswordPlaceholderText
                }
                if let passwordNotSetText = passwordPreferencesInfo.value(forKey: "passwordNotSetText") as? String{
                    lblPasswordState.stringValue = passwordNotSetText
                }
            }
            checkBoxQuitApp.isEnabled = false
            checkBoxStopPomodoro.isEnabled = false
            checkBoxAbortingShutoff.isEnabled = false
            checkBoxSkipEveningHabit.isEnabled = false
            checkBoxSkipMorningHabit.isEnabled = false
            checkBoxChangeSettings.isEnabled = false
            checkBoxSkipEveningHabitAfterCutOff.isEnabled = false
            checkBoxUseRelaxFocusMode.isEnabled = false
            checkBoxCircumventingBlocks.isEnabled = false
            checkBoxOpenPreferencesAfterCutOff.isEnabled = false
            checkBoxShortenHabits?.isEnabled = false
        }else{
            lblTitle.stringValue = "Change Password"
            btnChangePassword.title = "Change Password"
            textFieldNewPassword.placeholderString = "*****"
            textFieldConfirmPassword.placeholderString = "*****"
            lblPasswordState.stringValue = "You have an active password set."
            
            btnDisablePassword.isHidden = false
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let titleChangePassword = passwordPreferencesInfo.value(forKey: "titleChangePassword") as? String{
                    lblTitle.stringValue = titleChangePassword
                }
                if let buttonChangePasswordText = passwordPreferencesInfo.value(forKey: "buttonChangePasswordText") as? String{
                    btnChangePassword.title = buttonChangePasswordText
                }
                if let passwordSetText = passwordPreferencesInfo.value(forKey: "passwordSetText") as? String{
                    lblPasswordState.stringValue = passwordSetText
                }
                
                if let newPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "newPasswordPlaceholderText") as? String{
                    lblNewPassword.stringValue = newPasswordPlaceholderText
                }
                if let confirmPasswordPlaceholderText = passwordPreferencesInfo.value(forKey: "confirmPasswordPlaceholderText") as? String{
                    lblConfirmPassword.stringValue = confirmPasswordPlaceholderText
                }
                
            }
            checkBoxQuitApp.isEnabled = true
            checkBoxStopPomodoro.isEnabled = true
            checkBoxAbortingShutoff.isEnabled = true
            checkBoxSkipEveningHabit.isEnabled = true
            checkBoxSkipMorningHabit.isEnabled = true
            checkBoxChangeSettings.isEnabled = true
            checkBoxSkipEveningHabitAfterCutOff.isEnabled = true
            checkBoxUseRelaxFocusMode.isEnabled = true
            checkBoxCircumventingBlocks.isEnabled = true
            checkBoxOpenPreferencesAfterCutOff.isEnabled = true
            checkBoxShortenHabits?.isEnabled = true
        }
        
        
        
        if SettingsManagerObject.isPasswordRequireInChangeSettings{
            checkBoxChangeSettings.state = .on
        }else{
            checkBoxChangeSettings.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
            checkBoxCircumventingBlocks.state = .on
        }else{
            checkBoxCircumventingBlocks.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff{
            checkBoxOpenPreferencesAfterCutOff.state = .on
        }else{
            checkBoxOpenPreferencesAfterCutOff.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipMorning{
            checkBoxSkipMorningHabit.state = .on
        }else{
            checkBoxSkipMorningHabit.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipEvening{
            checkBoxSkipEveningHabit.state = .on
        }else{
            checkBoxSkipEveningHabit.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
            checkBoxSkipEveningHabitAfterCutOff.state = .on
        }else{
            checkBoxSkipEveningHabitAfterCutOff.state = .off
        }
        refreshPostponeCheckboxStates()
        
        if SettingsManagerObject.isPasswordRequireInAbortShutoff{
            checkBoxAbortingShutoff.state = .on
        }else{
            checkBoxAbortingShutoff.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInStopPomodoro{
            checkBoxStopPomodoro.state = .on
        }else{
            checkBoxStopPomodoro.state = .off
        }
        
        if SettingsManagerObject.isPasswordRequireInQuitApp{
            checkBoxQuitApp.state = .on
        }else{
            checkBoxQuitApp.state = .off
        }
        if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
            checkBoxUseRelaxFocusMode.state = .on
        }else{
            checkBoxUseRelaxFocusMode.state = .off
        }

    }
    
    
    @IBAction func checkBoxUseRelaxFocusModeClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxUseRelaxFocusMode.state == .on{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = true
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-enabled", metadata: [:])
        }else{
            SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode = false
            allApiObject.capturePosthog(event: "require-password-in-use-relax-focus-mode-disabled", metadata: [:])
        }
    }
    @IBAction func checkBoxQuitAppClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxQuitApp.state == .on{
            SettingsManagerObject.isPasswordRequireInQuitApp = true
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInQuitApp = false
            allApiObject.capturePosthog(event: "require-password-in-quitting-app-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxStopPomodoroClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxStopPomodoro.state == .on{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = true
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInStopPomodoro = false
            allApiObject.capturePosthog(event: "require-password-in-stop-pomodoro-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxAbortingShutoffClicked(_ sender: Any) {
        SettingsManagerObject.isPasswordRequireInAbortShutoff = true
        if checkBoxAbortingShutoff.state == .on{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = true
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInAbortShutoff = false
            allApiObject.capturePosthog(event: "require-password-in-using-mac-late-at-night-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxSkipEveningHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipEveningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEvening = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEvening = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-disabled", metadata: [:])//#490
        }
    }
    @IBAction func checkBoxSkipEveningHabitAfterCutOffClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipEveningHabitAfterCutOff.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = true
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff = false
            allApiObject.capturePosthog(event: "require-password-in-skip-evening-routine-after-cutoff-disabled", metadata: [:])//#490
        }
        
    }
    
    @IBAction func checkBoxSkipMorningHabitClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxSkipMorningHabit.state == .on{
            SettingsManagerObject.isPasswordRequireInSkipMorning = true
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInSkipMorning = false
            allApiObject.capturePosthog(event: "require-password-in-skip-morning-routine-disabled", metadata: [:])//#490
        }
    }
    
    @IBAction func checkBoxChangeSettingsClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxChangeSettings.state == .on{
            SettingsManagerObject.isPasswordRequireInChangeSettings = true
            allApiObject.capturePosthog(event: "require-password-in-change-settings-enabled", metadata: [:])//#490
        }else{
            SettingsManagerObject.isPasswordRequireInChangeSettings = false
            allApiObject.capturePosthog(event: "require-password-in-change-settings-disabled", metadata: [:])//#490
        }
    }
    
    
    @IBAction func checkBoxCircumventingBlocksClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxCircumventingBlocks.state == .on{
            SettingsManagerObject.isPasswordRequireInCircumventingBlocks = true
            allApiObject.capturePosthog(event: "require-password-in-allow-circumventing-blocks-enabled", metadata: [:])//#1015
        }else{
            SettingsManagerObject.isPasswordRequireInCircumventingBlocks = false
            allApiObject.capturePosthog(event: "require-password-in-allow-circumventing-blocks-disabled", metadata: [:])//#1015
        }
    }
    
    @IBAction func checkBoxOpenPreferencesAfterCutOffClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxOpenPreferencesAfterCutOff.state == .on{
            SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff = true
            allApiObject.capturePosthog(event: "require-password-in-preferences-after-cutoff-enabled", metadata: [:])//#1071
        }else{
            SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff = false
            allApiObject.capturePosthog(event: "require-password-in-preferences-after-cutoff-disabled", metadata: [:])//#1071
        }
    }
    
    
    
    @IBAction func btnDisablePasswordClicked(_ sender: Any) {
        
        var alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to disable your password?"
        if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
            if let passwordDisableAskText = passwordPreferencesInfo.value(forKey: "passwordDisableAskText") as? String{
                alert.messageText = passwordDisableAskText
            }
        }
        alert.informativeText = ""
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.putUserLocalDeviceSettings()
                self.resetView()
                allApiObject.capturePosthog(event: "disable-password", metadata: [:])
                alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "Your password has been disabled."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let passwordDisableDoneText = passwordPreferencesInfo.value(forKey: "passwordDisableDoneText") as? String{
                        alert.messageText = passwordDisableDoneText
                    }
                }
                alert.informativeText = ""
                alert.alertStyle = NSAlert.Style.warning
                alert.addButton(withTitle: buttonOkText)
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                        print("okclicked")
                        // self.txtFieldEmail.stringValue = ""
                    }
                })
            }
        })
    }
    
    @IBAction func btnChangePasswordClicked(_ sender: Any) {

        if textFieldNewPassword.stringValue.isEmpty{
            var passwordBlankAlertTitle = "Password cannot be blank."
            var passwordBlankAlertSubTitle = "Please enter a valid password."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "passwordBlankAlertTitle") as? String{
                    passwordBlankAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "passwordBlankAlertSubTitle") as? String{
                    passwordBlankAlertSubTitle = title
                }
            }
            alertforvalidation(question: passwordBlankAlertTitle, text: passwordBlankAlertSubTitle)//
            return
        }
        if textFieldConfirmPassword.stringValue.isEmpty{
            var confirmPasswordBlankAlertTitle = "Confirm password cannot be blank."
            var confirmPasswordBlankAlertSubTitle = "Please enter a valid \"Confirm password\"."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "confirmPasswordBlankAlertTitle") as? String{
                    confirmPasswordBlankAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "confirmPasswordBlankAlertSubTitle") as? String{
                    confirmPasswordBlankAlertSubTitle = title
                }
            }
            alertforvalidation(question: confirmPasswordBlankAlertTitle, text: confirmPasswordBlankAlertSubTitle)
            return
        }
        
        if textFieldNewPassword.stringValue == textFieldConfirmPassword.stringValue{
            let base64password = textFieldConfirmPassword.stringValue.toBase64()
            
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
                allApiObject.capturePosthog(event: "set-password", metadata: [:])
                var passwordSetAlertTitle = "Password successfully set."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let title = passwordPreferencesInfo.value(forKey: "passwordSetAlertTitle") as? String{
                        passwordSetAlertTitle = title
                    }
                }
                alertforvalidation(question: passwordSetAlertTitle, text: "")
            }else{
                allApiObject.capturePosthog(event: "change-password", metadata: [:])
                var passwordChagedAlertTitle = "Password successfully changed."
                if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                    if let title = passwordPreferencesInfo.value(forKey: "passwordChagedAlertTitle") as? String{
                        passwordChagedAlertTitle = title
                    }
                }
                alertforvalidation(question: passwordChagedAlertTitle, text: "")
            }
            
            UserDefaults.standard.set(base64password, forKey: SettingsManagerObject.kUserdefaultsAppPassword)
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
            
            resetView()
            
        }else{
            var passwordNotMatchAlertTitle = "Passwords do not match."
            var passwordNotMatchAlertSubTitle = "Confirm Password does not match with the main password. Please re enter."
            if let passwordPreferencesInfo = configjson.value(forKey: "passwordPreferencesInfo") as? NSDictionary{
                if let title = passwordPreferencesInfo.value(forKey: "passwordNotMatchAlertTitle") as? String{
                    passwordNotMatchAlertTitle = title
                }
                if let title = passwordPreferencesInfo.value(forKey: "passwordNotMatchAlertSubTitle") as? String{
                    passwordNotMatchAlertSubTitle = title
                }
            }
            alertforvalidation(question: passwordNotMatchAlertTitle, text: passwordNotMatchAlertSubTitle)
            return
        }
    }
    func alertforvalidation(question: String, text: String) {
        let alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonOkText)

        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                // self.txtFieldEmail.stringValue = ""
            }
        })
        
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
    @IBAction func btnInfoSetPasswordClicked(_ sender: Any) {
        var toolTip = "Make sure that your account is secure! Click here to set a password, and remember to choose a strong and unique combination of characters for enhanced account protection."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SetPassword") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSetPassword, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoChangeSettingsClicked(_ sender: Any) {
        var toolTip = "Secure adjustments! Tick this box to enforce password entry for setting changes, adding a secure barrier to prevent any unintended or unauthorized modifications."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_ChangeSettings") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoChangeSettings, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoSkipMorningHabitClicked(_ sender: Any) {
        var toolTip = "Password-protected mornings! Enable this setting to require a password when postponing or skipping your morning routine, ensuring that your choice is intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipMorningHabit") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSkipMorningHabit, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoSkipEveningHabitClicked(_ sender: Any) {
        var toolTip = "Password-protected evenings! Enable this setting to require a password when postponing or skipping your evening routine, ensuring that your choice is intentional."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipEveningHabit") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoSkipEveningHabit, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnSkipEveningHabitAfterCutOffClicked(_ sender: Any) {
        var toolTip = "Password shield for evenings! Select this option to enforce password entry when adjusting your evening routine after the cutoff time, this is just to make sure that your choice is intentional and securing the consistency of your nighttime habits."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_SkipEveningHabitAfterCutOffTime") as? String ?? toolTip
        }
        showTooltip(sender: btnSkipEveningHabitAfterCutOff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoAbortingShutoffClicked(_ sender: Any) {
        var toolTip = "Late-night access control! Tick this box to demand your password when using your computer late at night, offering secure and intentional access during nighttime hours."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_AbortingShutoff") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoAbortingShutoff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoStopPomodoroClicked(_ sender: Any) {
        var toolTip = "Guard your focus zone! Activate this setting to require a password when stopping the Super Pomodoro mode."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_StopSuperPomodoro") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoStopPomodoro, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoQuitAppClicked(_ sender: Any) {
        var toolTip = "Secure goodbyes! Enable this setting to require a password when you decide to quit the Focus Bear, adding an extra layer of security to your intentional exits."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_QuitApp") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoQuitApp, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoUseRelaxFocusModeClicked(_ sender: Any) {
        var toolTip = "Browse freely with control! Enable this feature to require a password when allowing the use of Relax Focus mode, adding a security layer to your leisurely internet sessions."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_UseRelaxFocusMode") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoUseRelaxFocusMode, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    
    @IBAction func btnInfoCircumventingBlocksClicked(_ sender: Any) {
        var toolTip = "Some settings like \"Show Dock Icon\" and \"Restart after force quit\" can reduce the strictness of blocking. If you tick this box, it will prompt for a password if the setting is changed to the less strict version."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            toolTip = tooltips.value(forKey: "strictness_Password_CircumventingBlocks") as? String ?? toolTip
        }
        showTooltip(sender: btnInfoCircumventingBlocks, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
    @IBAction func btnInfoOpenPreferencesAfterCutOffClicked(_ sender: Any) {
        var toolTip = lblCheckBoxOpenPreferencesAfterCutOff.stringValue
//        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
//            toolTip = tooltips.value(forKey: "strictness_Password_CircumventingBlocks") as? String ?? toolTip
//        }
        showTooltip(sender: btnInfoOpenPreferencesAfterCutOff, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
