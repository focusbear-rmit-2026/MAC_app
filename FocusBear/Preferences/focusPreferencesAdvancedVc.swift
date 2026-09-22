//
//  focusPreferencesAdvancedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import TrueTime


class focusPreferencesAdvancedVc: NSViewController {
    
    @IBOutlet weak var btnCheckBoxSuggestWorkFocusMode: NSButton!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var popUpBtnFocusAlignmentScore: NSPopUpButton!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var tblViewApps: NSTableView!
    @IBOutlet weak var btnRemoveApp: cursorButton!
    @IBOutlet weak var btnAddApp: cursorButton!
    @IBOutlet weak var boxHeaderBlockUrlsAndApps: NSBox!
    @IBOutlet weak var stackViewUrlsAndApps: NSStackView!
    @IBOutlet weak var boxBlockApps: NSBox!
    @IBOutlet weak var boxBlockUrls: NSBox!
    @IBOutlet weak var btnShowBlockedUrlsAndApps: cursorButton!
    @IBOutlet weak var lblTitleBlockedUrlsAndApps: NSTextField!
    @IBOutlet weak var btnShowScripts: cursorButton!
    @IBOutlet weak var lblTitleScripts: NSTextField!
    @IBOutlet weak var lineSepraterScripts: NSBox!
    @IBOutlet weak var boxShellScriptAfter: NSBox!
    @IBOutlet weak var boxShellScriptBefore: NSBox!
    @IBOutlet weak var boxAppleScriptAfter: NSBox!
    @IBOutlet weak var boxAppleScriptBefore: NSBox!
    @IBOutlet weak var checkBoxRunShellAfterFocus: NSButton!
    @IBOutlet weak var checkBoxRunShellBeforeFocus: NSButton!
    
    @IBOutlet var textViewRunShelltBeforeFocus: NSTextView!
    @IBOutlet var textViewRunShelltAfterFocus: NSTextView!
    
    @IBOutlet weak var lineHorizontal: NSBox!
    @IBOutlet weak var boxTableView: NSBox!
    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lblInstructionBlockedApps: NSTextField!
    @IBOutlet weak var lblInstructionBlockedUrls: NSTextField!
    @IBOutlet weak var btnAddUrl: cursorButton!
    @IBOutlet weak var btnRemoveUrl: cursorButton!
    @IBOutlet weak var lblTitleBlockedApps: NSTextField!
    @IBOutlet weak var lblTitleBlockedUrls: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblUrlCurrentApplescriptAfter: NSTextField!
    @IBOutlet weak var lblUrlCurrentApplescriptBefore: NSTextField!
    @IBOutlet weak var lblTitleCurrentApplescriptAfter: NSTextField!
    @IBOutlet weak var lblTitleCurrentApplescriptBefore: NSTextField!
    @IBOutlet weak var checkBoxRunScriptAfterFocus: NSButton!
    @IBOutlet weak var checkBoxRunScriptBeforeFocus: NSButton!
    @IBOutlet weak var btnSelectAppleScriptBeforeFocus: NSButton!
    @IBOutlet weak var btnSelectAppleScriptAfterFocus: NSButton!
    @IBOutlet weak var btnOk: NSButton!
    
    @IBOutlet weak var lblTitleTags: NSTextField!
    @IBOutlet weak var btnInfoTags: hoverInfoButton!
    
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet weak var btnDndInfo: hoverInfoButton!
    @IBOutlet weak var checkBoxAutoDoNotDisturb: NSButton!

    // "Use AI for this block list" — the per-block-list AI relevance toggle (is_ai_enabled). Owned by the
    // block list, NOT by blocking schedules (see CLAUDE.md). This is the storyboard checkbox: connect it
    // to this outlet and wire its action to `checkBoxUseAiClicked(_:)`. (It was previously created in
    // code, which double-rendered on top of the storyboard control — #2571 15.)
    @IBOutlet weak var checkBoxUseAi: NSButton!
    private var useAiTitle = "Use AI for this block list"

    var isShellScriptBeforeFocusEdited = false
    var isShellScriptAfterFocusEdited = false
    var toolTipDndMode = "Turn on Do Not Disturb automatically when starting a focus mode."
    
    var defaultTokenMenu = NSMenu()
    var arrAllTags = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        textViewRunShelltAfterFocus.delegate = self
        textViewRunShelltBeforeFocus.delegate = self
        
        tokenField.delegate = self
        
        btnCheckBoxSuggestWorkFocusMode.title = "Automatically suggest starting this focus mode when any allowed URL/App is opened"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            btnCheckBoxSuggestWorkFocusMode.title = focusPreferencesInfo.value(forKey: "checkBoxSuggestWorkFocusMode") as? String ?? btnCheckBoxSuggestWorkFocusMode.title
        }
        
        lblFocusAlignmentScore.stringValue = "Show distracting site popup only when focus alignment score is less than"
        
        lblTitleScripts.stringValue = "Run scripts before/after habits"
        lblTitleBlockedUrlsAndApps.stringValue = "Blocked URLs and Apps"
        lblTitleBlockedApps.stringValue = "Blocked Apps"
        lblInstructionBlockedApps.stringValue = "The Apps here will be blocked during this focus mode. Useful if you want to allow some apps but block others. For example, you could have Safari as an allowed app but block Google Chrome"
        
        
        
        lblTitleTags.stringValue = "Reporting Tags:"
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            toolTipDndMode = focusPreferencesAdvancedInfo.value(forKey: "autoOnDoNotDisturbText") as? String ?? toolTipDndMode
        }
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            checkBoxAutoDoNotDisturb.title = focusPreferencesInfo.value(forKey: "checkBoxDoNotDisturbText") as? String ?? checkBoxAutoDoNotDisturb.title
            lblTitleTags.stringValue = focusPreferencesInfo.value(forKey: "titleTags") as? String ?? lblTitleTags.stringValue
        }
        
        
        checkBoxAutoDoNotDisturb.title = "Block Notifications while focusing"
        
        
        
        checkBoxRunShellBeforeFocus.title = "Run shell script before starting focus mode."
        checkBoxRunShellAfterFocus.title = "Run shell script after finishing focus mode."
        
        lblInstructionBlockedUrls.stringValue = "The URLs here will be blocked during this focus mode. Useful if you want to allow some websites but block others. For example, you could have *.google.com as an allowed URL but block games.google.com"
        var runScriptBeforeText = "Run apple script before starting focus mode."
        var runScriptAfterText = "Run apple script after starting focus mode."
        var titleCurrentAppleScript = "Current Apple script:"
        var buttonSelectScriptText = "Select Apple script"
        var titleBlockedUrls = "Blocked URLs"
        
        var toolTipAdd = "Add"
        var toolTipRemove = "Remove"
        
        
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            runScriptBeforeText = focusPreferencesAdvancedInfo.value(forKey: "runScriptBeforeText") as? String ?? runScriptBeforeText
            runScriptAfterText = focusPreferencesAdvancedInfo.value(forKey: "runScriptAfterText") as? String ?? runScriptAfterText
            titleCurrentAppleScript = focusPreferencesAdvancedInfo.value(forKey: "titleCurrentAppleScript") as? String ?? titleCurrentAppleScript
            buttonSelectScriptText = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectScriptText") as? String ?? buttonSelectScriptText
            titleBlockedUrls = focusPreferencesAdvancedInfo.value(forKey: "titleBlockedUrls") as? String ?? titleBlockedUrls

            toolTipAdd = focusPreferencesAdvancedInfo.value(forKey: "toolTipAdd") as? String ?? toolTipAdd
            toolTipRemove = focusPreferencesAdvancedInfo.value(forKey: "toolTipRemove") as? String ?? toolTipRemove
            lblInstructionBlockedUrls.stringValue = focusPreferencesAdvancedInfo.value(forKey: "instructionText") as? String ?? lblInstructionBlockedUrls.stringValue
            
            checkBoxRunShellBeforeFocus.title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandBeforeText") as? String ?? checkBoxRunShellBeforeFocus.title
            checkBoxRunShellAfterFocus.title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandAfterText") as? String ?? checkBoxRunShellAfterFocus.title
    
            lblTitleScripts.stringValue = focusPreferencesAdvancedInfo.value(forKey: "titleScripts") as? String ?? lblTitleScripts.stringValue
            lblTitleBlockedUrlsAndApps.stringValue = focusPreferencesAdvancedInfo.value(forKey: "titleBlockedUrlsAndApps") as? String ?? lblTitleBlockedUrlsAndApps.stringValue
            lblTitleBlockedApps.stringValue = focusPreferencesAdvancedInfo.value(forKey: "titleBlockedApps") as? String ?? lblTitleBlockedApps.stringValue
            lblInstructionBlockedApps.stringValue = focusPreferencesAdvancedInfo.value(forKey: "instructionBlockedApps") as? String ?? lblInstructionBlockedApps.stringValue
            lblFocusAlignmentScore.stringValue = focusPreferencesAdvancedInfo.value(forKey: "focusAlignmentScoreTitle") as? String ?? lblFocusAlignmentScore.stringValue
        }
        
        checkBoxRunScriptBeforeFocus.title = runScriptBeforeText
        lblTitleCurrentApplescriptBefore.stringValue = titleCurrentAppleScript
        btnSelectAppleScriptBeforeFocus.title = buttonSelectScriptText
        
        checkBoxRunScriptAfterFocus.title = runScriptAfterText
        lblTitleCurrentApplescriptAfter.stringValue = titleCurrentAppleScript
        btnSelectAppleScriptAfterFocus.title = buttonSelectScriptText
        
        lblTitleBlockedUrls.stringValue = titleBlockedUrls
        btnOk.title = buttonOkText
        tblView.doubleAction = #selector(tableRowBlockedUrlsDoubleClicked)

        btnAddUrl.toolTip = toolTipAdd
        btnRemoveUrl.toolTip = toolTipRemove
        
        
        if #available(macOS 11.0, *) {
            btnAddUrl.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveUrl.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
            btnAddApp.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveApp.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }

        popUpBtnFocusAlignmentScore.removeAllItems()
        popUpBtnFocusAlignmentScore.addItems(withTitles: arrFocusAlignmentScore)

        setupUseAiCheckbox()
    }

    /// Applies the config-driven title to the storyboard "Use AI for this block list" checkbox. Its
    /// state is set per selected mode where the rest of the advanced fields are populated, and toggling
    /// it runs `checkBoxUseAiClicked`.
    private func setupUseAiCheckbox() {
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary {
            useAiTitle = focusPreferencesAdvancedInfo.value(forKey: "checkBoxUseAiForBlockListText") as? String ?? useAiTitle
        }
        checkBoxUseAi?.title = useAiTitle
    }

    @IBAction func checkBoxUseAiClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        guard row >= 0, row < arrFocusType.count else { return }
        let enabled = (checkBoxUseAi?.state ?? .off) == .on
        arrFocusType[row]["is_ai_enabled"] = enabled
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.capturePosthog(
            event: enabled ? "settings-changed-enable-ai-for-block-list" : "settings-changed-disable-ai-for-block-list",
            metadata: [:])
        // Persist to the server so the choice follows the user across devices (per-mode fields round-trip
        // through the focus mode's metadata — see CLAUDE.md).
        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: { _ in })
    }
    
    override func viewWillAppear() {
        isShellScriptBeforeFocusEdited = false
        isShellScriptAfterFocusEdited = false
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }

        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if row != -1{
            if let isScriptEnabled = arrFocusType[row]["isScriptBeforeFocusEnabled"] as? Bool{
                if isScriptEnabled{
                    checkBoxRunScriptBeforeFocus.state = .on
                }else{
                    checkBoxRunScriptBeforeFocus.state = .off
                }
            }else{
                checkBoxRunScriptBeforeFocus.state = .off
            }
            
            if let isScriptEnabled = arrFocusType[row]["isScriptAfterFocusEnabled"] as? Bool{
                if isScriptEnabled{
                    checkBoxRunScriptAfterFocus.state = .on
                }else{
                    checkBoxRunScriptAfterFocus.state = .off
                }
            }else{
                checkBoxRunScriptAfterFocus.state = .off
            }
            
            if let isShellCommandEnabled = arrFocusType[row]["isShellCommandBeforeFocusEnabled"] as? Bool{
                if isShellCommandEnabled{
                    checkBoxRunShellBeforeFocus.state = .on
                }else{
                    checkBoxRunShellBeforeFocus.state = .off
                }
            }else{
                checkBoxRunShellBeforeFocus.state = .off
            }
            
            if let isShellCommandEnabled = arrFocusType[row]["isShellCommandAfterFocusEnabled"] as? Bool{
                if isShellCommandEnabled{
                    checkBoxRunShellAfterFocus.state = .on
                }else{
                    checkBoxRunShellAfterFocus.state = .off
                }
            }else{
                checkBoxRunShellAfterFocus.state = .off
            }
            if let shellCommand = arrFocusType[row]["shellCommandBeforeFocusText"] as? String{
                textViewRunShelltBeforeFocus.string = shellCommand
            }else{
                textViewRunShelltBeforeFocus.string = ""
            }
            
            if let shellCommand = arrFocusType[row]["shellCommandAfterFocusText"] as? String{
                textViewRunShelltAfterFocus.string = shellCommand
            }else{
                textViewRunShelltAfterFocus.string = ""
            }

            if let focusAlignmentScore = arrFocusType[row]["focusAlignmentScoreThreshold"] as? Int{
                popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(focusAlignmentScore)")
            }else{
                popUpBtnFocusAlignmentScore.selectItem(withTitle: "\(defaultFocusAlignmentScoreToShowDistractingPopUp)")
            }

            
            if checkBoxRunScriptBeforeFocus.state == .on{
                btnSelectAppleScriptBeforeFocus.isEnabled = true
            }else{
                btnSelectAppleScriptBeforeFocus.isEnabled = false
            }
            if checkBoxRunScriptAfterFocus.state == .on{
                btnSelectAppleScriptAfterFocus.isEnabled = true
            }else{
                btnSelectAppleScriptAfterFocus.isEnabled = false
            }
            
            if checkBoxRunShellBeforeFocus.state == .on{
                textViewRunShelltBeforeFocus.isEditable = true
            }else{
                textViewRunShelltBeforeFocus.isEditable = false
            }
            if checkBoxRunShellAfterFocus.state == .on{
                textViewRunShelltAfterFocus.isEditable = true
            }else{
                textViewRunShelltAfterFocus.isEditable = false
            }
       
            if let scriptPath = arrFocusType[row]["scriptPathBeforeFocus"] as? String{
                lblUrlCurrentApplescriptBefore.stringValue = scriptPath
                lblUrlCurrentApplescriptBefore.toolTip = scriptPath
            }else{
                lblUrlCurrentApplescriptBefore.toolTip = ""
                lblUrlCurrentApplescriptBefore.stringValue = "Please select a apple script."
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    lblUrlCurrentApplescriptBefore.stringValue = focusPreferencesAdvancedInfo.value(forKey: "pleaseSelectScriptText") as? String ?? lblUrlCurrentApplescriptBefore.stringValue
                }
                    
            }
            
            if let scriptPath = arrFocusType[row]["scriptPathAfterFocus"] as? String{
                lblUrlCurrentApplescriptAfter.stringValue = scriptPath
                lblUrlCurrentApplescriptAfter.toolTip = scriptPath
            }else{
                lblUrlCurrentApplescriptAfter.toolTip = ""
                lblUrlCurrentApplescriptAfter.stringValue = "Please select a apple script."
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    lblUrlCurrentApplescriptAfter.stringValue = focusPreferencesAdvancedInfo.value(forKey: "pleaseSelectScriptText") as? String ?? lblUrlCurrentApplescriptAfter.stringValue
                }
            }
          

            if let isAllowedListApproach = arrFocusType[row]["isAllowedListApproach"] as? Bool{
                if arrFocusType[row]["isDefault"] as? Bool == true{
                    lineHorizontal.isHidden = true
                    boxBlockUrls.isHidden = true
                    boxBlockApps.isHidden = true
                    boxHeaderBlockUrlsAndApps.isHidden = true
                    btnCheckBoxSuggestWorkFocusMode.isHidden = true
                }else if arrFocusType[row]["isRelaxFocus"] as? Bool == true{
                    lineHorizontal.isHidden = true
                    boxBlockUrls.isHidden = true
                    boxBlockApps.isHidden = true
                    boxHeaderBlockUrlsAndApps.isHidden = true
                    btnCheckBoxSuggestWorkFocusMode.isHidden = true
                }else{
                    if arrFocusType[row]["isMeetings"] as? Bool == true{
                        btnCheckBoxSuggestWorkFocusMode.isHidden = true
                    }else{
                        btnCheckBoxSuggestWorkFocusMode.isHidden = false
                    }
                    if isAllowedListApproach{
                        lineHorizontal.isHidden = false
                        boxBlockUrls.isHidden = false
                        boxBlockApps.isHidden = false
                        boxHeaderBlockUrlsAndApps.isHidden = false
                    }else{
                        lineHorizontal.isHidden = false
                        boxBlockUrls.isHidden = true
                        boxBlockApps.isHidden = false
                        boxHeaderBlockUrlsAndApps.isHidden = false
                    }
                }
            }
            tblView.reloadData()
            tblViewApps.reloadData()
            
            
            let autoSuggestFocusModeOnAllowedURL = arrFocusType[row]["autoSuggestFocusModeOnAllowedURL"] as? Bool ?? false
            btnCheckBoxSuggestWorkFocusMode.state = autoSuggestFocusModeOnAllowedURL ? .on : .off

            // Absent means AI on (matches isAIBlockingEnabled()'s veto-only reading of is_ai_enabled).
            let isAiEnabled = arrFocusType[row]["is_ai_enabled"] as? Bool ?? true
            checkBoxUseAi?.state = isAiEnabled ? .on : .off
        }

        btnShowScripts.image = NSImage(named: "NSTouchBarGoForwardTemplate")
        boxAppleScriptAfter.isHidden = true
        boxAppleScriptBefore.isHidden = true
        boxShellScriptAfter.isHidden = true
        boxShellScriptBefore.isHidden = true
        lineSepraterScripts.isHidden = true

        btnShowBlockedUrlsAndApps.image = NSImage(named: "NSTouchBarGoForwardTemplate")
        stackViewUrlsAndApps.isHidden = true
        showFullScrollView()
    }

    override func viewDidAppear() {
        showFullScrollView()
    }
    
    @objc func tableRowBlockedUrlsDoubleClicked(){
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let selectedTow = tblView.selectedRow
        if selectedTow == -1{
            return;
        }
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
        addWebUrlVcObj!.isAdding = false
        self.presentAsSheet(addWebUrlVcObj!)
    }
    @IBAction func checkBoxRunScriptBeforeFocusClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunScriptBeforeFocus.state == .on{
            arrFocusType[row]["isScriptBeforeFocusEnabled"] = true
            btnSelectAppleScriptBeforeFocus.isEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-enable-script-before-focus", metadata: [:])//#490
        }else{
            arrFocusType[row]["isScriptBeforeFocusEnabled"] = false
            btnSelectAppleScriptBeforeFocus.isEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-script-before-focus", metadata: [:])//#490
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
    }
    
    func showFullScrollView(){
        DispatchQueue.global().async {
            usleep(50000)
            DispatchQueue.main.async {
                self.view.window?.setFrame(NSRect(x: 0, y: 0, width: self.view.frame.width, height: self.boxBg.frame.height), display: true)
            }
        }
    }
    
    @IBAction func checkBoxRunScriptAfterFocusClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunScriptAfterFocus.state == .on{
            arrFocusType[row]["isScriptAfterFocusEnabled"] = true
            btnSelectAppleScriptAfterFocus.isEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-enable-script-after-focus", metadata: [:])//#490
        }else{
            arrFocusType[row]["isScriptAfterFocusEnabled"] = false
            btnSelectAppleScriptAfterFocus.isEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-script-after-focus", metadata: [:])//#490
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

    }
    
    @IBAction func checkBoxRunShellCommandBeforeFocusClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunShellBeforeFocus.state == .on{
            arrFocusType[row]["isShellCommandBeforeFocusEnabled"] = true
            textViewRunShelltBeforeFocus.isEditable = true
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-before-focus", metadata: [:])
            self.view.window?.makeFirstResponder(textViewRunShelltBeforeFocus)
        }else{
            arrFocusType[row]["isShellCommandBeforeFocusEnabled"] = false
            textViewRunShelltBeforeFocus.isEditable = false
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-before-focus", metadata: [:])
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

        
    }
    
    @IBAction func checkBoxRunShellCommandAfterFocusClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunShellAfterFocus.state == .on{
            arrFocusType[row]["isShellCommandAfterFocusEnabled"] = true
            textViewRunShelltAfterFocus.isEditable = true
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-after-focus", metadata: [:])
            self.view.window?.makeFirstResponder(textViewRunShelltAfterFocus)
        }else{
            arrFocusType[row]["isShellCommandAfterFocusEnabled"] = false
            textViewRunShelltAfterFocus.isEditable = false
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-after-focus", metadata: [:])
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

    }
    
    @IBAction func btnSelectAppleScriptBeforeClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.message = "Please select a script file"
        dialog.prompt = "Select"
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            dialog.message = focusPreferencesAdvancedInfo.value(forKey: "selectScriptFileText") as? String ?? dialog.message
            dialog.prompt = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectText") as? String ?? dialog.prompt
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                dialog.sharingType = .none
            }
        }
        dialog.allowedFileTypes = ["scpt"]
        dialog.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
            if modalResponse.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = dialog.url {
                    arrFocusType[row]["scriptPathBeforeFocus"] = url.path
                    self.lblUrlCurrentApplescriptBefore.stringValue = url.path
                    self.lblUrlCurrentApplescriptBefore.toolTip = url.path
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

                    allApiObject.capturePosthog(event: "set-apple-script-before-starting-focus-mode", metadata: [:])
                }
            }
        })
    }
    
    @IBAction func btnSelectAppleScriptAfterClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.message = "Please select a script file"
        dialog.prompt = "Select"
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            dialog.message = focusPreferencesAdvancedInfo.value(forKey: "selectScriptFileText") as? String ?? dialog.message
            dialog.prompt = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectText") as? String ?? dialog.prompt
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                dialog.sharingType = .none
            }
        }
        dialog.allowedFileTypes = ["scpt"]
        dialog.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
            if modalResponse.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = dialog.url {
                    arrFocusType[row]["scriptPathAfterFocus"] = url.path
                    self.lblUrlCurrentApplescriptAfter.stringValue = url.path
                    self.lblUrlCurrentApplescriptAfter.toolTip = url.path
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

                    allApiObject.capturePosthog(event: "set-apple-script-after-completing-focus-mode", metadata: [:])
                }
            }
        })
    }

    @IBAction func btnAddUrlClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
        addWebUrlVcObj!.isAdding = true
        self.presentAsSheet(addWebUrlVcObj!)
    }
    
    @IBAction func btnRemoveUrlClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let selectedFocusTypeRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if selectedFocusTypeRow == -1{
            return
        }
        
        let selectedUrlsRow = tblView.selectedRow
        if selectedUrlsRow == -1{
            return
        }
        
        if arrFocusType.count > selectedFocusTypeRow{

            if var blockUrlsArray = arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] as? [String]{
                if blockUrlsArray.count > selectedUrlsRow{
                    blockUrlsArray.remove(at: selectedUrlsRow)
                }
                arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] = blockUrlsArray
            }
            self.tblView.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

        allApiObject.capturePosthog(event: "remove-blocked-url-in-focus-mode", metadata: [:])//#490

        reSetCurrentFocusMode(focusType:arrFocusType[selectedFocusTypeRow])
        
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else {
            dismiss(self)
            return
        }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        let oldFocusAlignmentScoreThreshold = arrFocusType[row]["focusAlignmentScoreThreshold"] as? Int ?? -1
        let focusAlignmentScoreThreshold = Int(popUpBtnFocusAlignmentScore.titleOfSelectedItem ?? "") ?? 80
        if oldFocusAlignmentScoreThreshold != focusAlignmentScoreThreshold{
            arrFocusType[row]["focusAlignmentScoreThreshold"] = focusAlignmentScoreThreshold
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.capturePosthog(event: "focus-alignment-score-threshold-changed", metadata: [:])
        }

        
        if isShellScriptBeforeFocusEdited || isShellScriptAfterFocusEdited{

            if isShellScriptBeforeFocusEdited{
                arrFocusType[row]["shellCommandBeforeFocusText"] = textViewRunShelltBeforeFocus.string
                allApiObject.capturePosthog(event: "set-shell-command-before-starting-focus-mode", metadata: [:])
            }
            
            
            if isShellScriptAfterFocusEdited{
                arrFocusType[row]["shellCommandAfterFocusText"] = textViewRunShelltAfterFocus.string
                allApiObject.capturePosthog(event: "set-shell-command-after-completing-focus-mode", metadata: [:])
            }
     
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }
        self.dismiss(self)
    }

    @IBAction func btnDndInfoClicked(_ sender: Any) {
        showTooltip(sender: btnDndInfo, msg: toolTipDndMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    @IBAction func btnInfoTagsClicked(_ sender: Any) {
        var tagsInfoText = "Add tags to be able to prepare time logs for specific focus blocks. Examples of tags would be: billable, jones, client, Project 1."
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            tagsInfoText = focusPreferencesInfo.value(forKey: "tagsInfoText") as? String ?? tagsInfoText
        }
        showTooltip(sender: btnInfoTags, msg: tagsInfoText, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @objc private func menuItemClicked(_ menuItem: NSMenuItem) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        if let fieldEditor = tokenField?.currentEditor() {
            let textRange = fieldEditor.selectedRange
            let replaceString = menuItem.title
            fieldEditor.replaceCharacters(in: textRange, with: replaceString)
            fieldEditor.selectedRange = NSMakeRange(textRange.location, (replaceString as NSString).length)
        }
    }
    
    @IBAction func btnShowBlockedUrlsAndAppsClicked(_ sender: Any) {
        if stackViewUrlsAndApps.isHidden{
            btnShowBlockedUrlsAndApps.image = NSImage(named: "NSTouchBarGoDownTemplate")
            stackViewUrlsAndApps.isHidden = false
            showFullScrollView()
        }else{
            btnShowBlockedUrlsAndApps.image = NSImage(named: "NSTouchBarGoForwardTemplate")
            stackViewUrlsAndApps.isHidden = true
        }
    }
    @IBAction func btnShowScriptsClicked(_ sender: Any) {
        if boxAppleScriptBefore.isHidden{
            btnShowScripts.image = NSImage(named: "NSTouchBarGoDownTemplate")
            boxAppleScriptAfter.isHidden = false
            boxAppleScriptBefore.isHidden = false
            boxShellScriptAfter.isHidden = false
            boxShellScriptBefore.isHidden = false
            lineSepraterScripts.isHidden = false
            showFullScrollView()
        }else{
            btnShowScripts.image = NSImage(named: "NSTouchBarGoForwardTemplate")
            boxAppleScriptAfter.isHidden = true
            boxAppleScriptBefore.isHidden = true
            boxShellScriptAfter.isHidden = true
            boxShellScriptBefore.isHidden = true
            lineSepraterScripts.isHidden = true
        }
    }
    @IBAction func btnAddAppClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowedFileTypes = ["app"]
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                openPanel.sharingType = .none
            }
        }
        openPanel.prompt = "Select"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let title = focusPreferencesInfo.value(forKey: "buttonSelectAppText") as? String{
                openPanel.prompt = title
            }
        }
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                //                if var arr =
                
                return
            }
            let urls = openPanel.urls
            
            let selectedFocusTypeRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
            if selectedFocusTypeRow == -1{
                return
            }


            var appsArray = [String]()
            var appsUrlArray = [URL]()
            if let arr = arrFocusType[selectedFocusTypeRow]["blockAppsArray"] as? [String]{
                appsArray = arr
            }
            
            for path in appsArray{
                let url = URL(fileURLWithPath: path)
                appsUrlArray.append(url)
            }
            var isContainAlready = false
            for url in urls{
                var isFoundAlready = false
                for addedUrl in appsUrlArray{
                    if addedUrl.lastPathComponent.lowercased() == url.lastPathComponent.lowercased(){
                        isFoundAlready = true
                        break;
                    }
                }
                if !isFoundAlready{
                    appsArray.append(url.path)
                }else{
                    isContainAlready = true
                }
            }
            
            arrFocusType[selectedFocusTypeRow]["blockAppsArray"] = appsArray
            
            self.tblViewApps.reloadData()
            self.tblViewApps.selectRowIndexes(IndexSet(arrayLiteral: (appsArray.count - 1)), byExtendingSelection: false)
            self.tblViewApps.scrollRowToVisible(appsArray.count - 1)
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            if isContainAlready{
                self.showAlertAppAlreadyAdded()
            }
            allApiObject.capturePosthog(event: "add-blocked-app-in-focus-mode", metadata: [:])
            
        }
        
    }
    func showAlertAppAlreadyAdded(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var messageText = "Some of the apps selected are already present in the list."
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            messageText = focusPreferencesInfo.value(forKey: "appAlreadyExistsText") as? String ?? messageText
        }
        alert.messageText = messageText
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
            }
        })
    }
    @IBAction func btnRemoveAppClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let selectedFocusTypeRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if selectedFocusTypeRow == -1{
            return
        }
        let selectedAppsRow = tblViewApps.selectedRow
        if selectedAppsRow == -1{
            return
        }
        if arrFocusType.count > selectedFocusTypeRow{
            if var blockAppsArray = arrFocusType[selectedFocusTypeRow]["blockAppsArray"] as? [String]{
                if blockAppsArray.count > selectedAppsRow{
                    blockAppsArray.remove(at: selectedAppsRow)
                }
                arrFocusType[selectedFocusTypeRow]["blockAppsArray"] = blockAppsArray
            }
            self.tblViewApps.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.capturePosthog(event: "remove-blocked-app-in-focus-mode", metadata: [:])
        reSetCurrentFocusMode(focusType:arrFocusType[selectedFocusTypeRow])
    }
    
    @IBAction func checkBoxAutoDoNotDisturbClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxAutoDoNotDisturb.state == .on{

            if !isAccessibilityEnabled(isPrompt: false){
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "To turn on Do Not Disturb when starting a Focus Mode, Focus Bear needs Accessibility permissions. Would you like to give the permissions now?"
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    alert.messageText = focusPreferencesAdvancedInfo.value(forKey: "needDndPermissionText") as? String ?? alert.messageText
                }
                alert.addButton(withTitle: buttonOkText)
                alert.addButton(withTitle: buttonCancelText)
                alert.beginSheetModal(for: self.view.window!, completionHandler: { response in
                    guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
                    if response == .alertFirstButtonReturn{
                        _ = isAccessibilityEnabled(isPrompt: true)
                        arrFocusType[row]["isAutoDoNotDisturbEnabled"] = true
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.capturePosthog(event: "settings-changed-enable-dnd", metadata: [:])//#490
                    }else{
                        self.checkBoxAutoDoNotDisturb.state = .off
                    }
                })

            }else{
                arrFocusType[row]["isAutoDoNotDisturbEnabled"] = true
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                allApiObject.capturePosthog(event: "settings-changed-enable-dnd", metadata: [:])//#490
            }

        }else{
            arrFocusType[row]["isAutoDoNotDisturbEnabled"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.capturePosthog(event: "settings-changed-disable-dnd", metadata: [:])//#490
        }

    }
    
    @IBAction func popUpBtnFocusAlignmentScoreClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        
    }
    
    @IBAction func btnCheckBoxSuggestWorkFocusModeClicked(_ sender: Any) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if btnCheckBoxSuggestWorkFocusMode.state == .on{
            arrFocusType[row]["autoSuggestFocusModeOnAllowedURL"] = true
        }else{
            arrFocusType[row]["autoSuggestFocusModeOnAllowedURL"] = false
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
    }
}

extension focusPreferencesAdvancedVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tblView{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
                if row != -1{
                    if let blockUrlsArray = arrFocusType[row]["blockUrlsArray"] as? [String]{
                        btnRemoveUrl.isEnabled = false
                        return blockUrlsArray.count
                    }
                }
                
            }
        }else if tableView == tblViewApps{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
                if row != -1{
                    if let blockUrlsArray = arrFocusType[row]["blockAppsArray"] as? [String]{
                        btnRemoveApp.isEnabled = false
                        return blockUrlsArray.count
                    }
                }
                
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            
            if tableView == tblView{
                if let blockUrlsArray = arrFocusType[focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0]["blockUrlsArray"] as? [String]{
                    if row < blockUrlsArray.count{
                        cell.lblTitle.stringValue = blockUrlsArray[row]
                        cell.imgView.image = NSImage(named: NSImage.networkName)
                    }else{
                        cell.lblTitle.stringValue = ""
                        cell.imgView.image = nil
                    }
                }
            }else if tableView == tblViewApps{
                if let blockUrlsArray = arrFocusType[focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0]["blockAppsArray"] as? [String]{
                    if row < blockUrlsArray.count{
                        let url = URL(fileURLWithPath: blockUrlsArray[row])
                        cell.lblTitle.stringValue = url.lastPathComponent
                        cell.imgView.image = NSWorkspace.shared.icon(forFile: url.path)
                    }else{
                        cell.lblTitle.stringValue = ""
                        cell.imgView.image = nil
                    }
                }
            }
            return cell
        }
        
        return NSTableCellView()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard let tblview = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tblview.selectedRow
    
        if tblview == tblView{
            if selectedRow == -1{
                btnRemoveUrl.isEnabled = false
            }else{
                btnRemoveUrl.isEnabled = true
            }
        }else if tblview == tblViewApps{
            if selectedRow == -1{
                btnRemoveApp.isEnabled = false
            }else{
                btnRemoveApp.isEnabled = true
            }
        }
    }
    

}


extension focusPreferencesAdvancedVc:NSTextViewDelegate{
    func textDidBeginEditing(_ notification: Notification) {
        print("textDidBeginEditing")
        if let textView = notification.object as? NSTextView{
            if textView == textViewRunShelltBeforeFocus{
                isShellScriptBeforeFocusEdited = true
            }else if textView == textViewRunShelltAfterFocus{
                isShellScriptAfterFocusEdited = true
            }
        }
    }
}
extension focusPreferencesAdvancedVc:NSTextFieldDelegate, NSTokenFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
        if let tokenfield = obj.object as? NSTokenField{
            if tokenfield == self.tokenField{
                let selectedRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
                var dic = arrFocusType[selectedRow]
                dic["tags"] = self.tokenField.objectValue as? [String] ?? []

                arrFocusType[selectedRow] = dic
            }
        }
    }

    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }
    func tokenField(_ tokenField: NSTokenField,
                    menuForRepresentedObject representedObject: Any) -> NSMenu? {
        defaultTokenMenu.removeAllItems()
        for habit in arrAllTags{//
            let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
            item.target = self
            defaultTokenMenu.addItem(item)
        }
        
        return defaultTokenMenu
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return arrAllTags.filter { $0.lowercased().hasPrefix(substring.lowercased()) }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return [] }
        DispatchQueue.global().async {
            //usleep(50000)
            DispatchQueue.main.async {
                guard !ManagedBlockingRuntime.shared.isSettingsLocked else { return }
                
                let selectedRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
                var dic = arrFocusType[selectedRow]
                //dic["tags"] = self.tokenField.objectValue as? [String] ?? []
                let tags = self.tokenField.objectValue as? [String] ?? []
                
                var finalTags = [String]()
                for i in 0..<tags.count{
                    if !finalTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                        finalTags.append(tags[i])
                        if !self.arrAllTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                            self.arrAllTags.append(tags[i])
                        }
                    }
                }
                dic["tags"] = finalTags
                arrFocusType[selectedRow] = dic
                self.tokenField.objectValue = finalTags
            }
        }
        return tokens
    }
    
}
