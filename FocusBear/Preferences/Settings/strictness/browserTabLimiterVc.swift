//
//  browserTabLimiterVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class browserTabLimiterVc: NSViewController {
    
    @IBOutlet weak var boxMaxTabLimit: NSBox!
    @IBOutlet weak var lblTitleTabLimitCount: NSTextField!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var textFieldTabLimitCount: NSTextField!
    @IBOutlet weak var stepperTabLimitCount: NSStepper!
    
    let enableTabLimiterItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Browser tab limiter:"
        
        var titleTabLimitCount = "Max tab limit:"
        var checkBoxTabLimiterText = "Prevent user from opening more browser tabs"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblTitle.stringValue = preferencesInfo.value(forKey: "titleTabLimiter") as? String ?? lblTitle.stringValue
            titleTabLimitCount = preferencesInfo.value(forKey: "titleTabLimitCount") as? String ?? titleTabLimitCount
            checkBoxTabLimiterText = preferencesInfo.value(forKey: "checkBoxTabLimiterText") as? String ?? checkBoxTabLimiterText
        }
        var strictness_BrowserTabLimiter = "Too many tabs can mess with your productivity. Set a limit of tabs across all browsers"
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            strictness_BrowserTabLimiter = tooltips.value(forKey: "strictness_BrowserTabLimiter") as? String ?? strictness_BrowserTabLimiter
        }
        
        lblTitleTabLimitCount.stringValue = titleTabLimitCount
        textFieldTabLimitCount.formatter = IntegerFormatter()
        textFieldTabLimitCount.delegate = self

        stackView.insertView(enableTabLimiterItemVcObj!.view, at: 0, in: .top)
        enableTabLimiterItemVcObj?.lblTitle.stringValue = checkBoxTabLimiterText
        enableTabLimiterItemVcObj?.lblSubTitle.isHidden = true
        enableTabLimiterItemVcObj?.delegate = self
        enableTabLimiterItemVcObj?.toolTip = strictness_BrowserTabLimiter
        
        arrForSearchFromSettings.append(["title": checkBoxTabLimiterText, "tabId": idBrowserTabLimiter, "object": enableTabLimiterItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleTabLimitCount, "tabId": idBrowserTabLimiter, "object": boxMaxTabLimit as Any])
        
        
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxTabLimiterText, "tabId": idBrowserTabLimiter, "object": enableTabLimiterItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleTabLimitCount, "tabId": idBrowserTabLimiter, "object": boxMaxTabLimit as Any])
    }
    override func viewWillAppear() {
        stepperTabLimitCount.maxValue = 999
        stepperTabLimitCount.minValue = 1
        textFieldTabLimitCount.integerValue = SettingsManagerObject.maxTabLimitCount
        stepperTabLimitCount.integerValue = SettingsManagerObject.maxTabLimitCount
        
        if SettingsManagerObject.isTabLimiterEnabled{
            enableTabLimiterItemVcObj?.btnSwitch.state = .on
        }else{
            enableTabLimiterItemVcObj?.btnSwitch.state = .off
        }
    }
    @IBAction func stepperTabLimitCountClicked(_ sender: Any) {
        textFieldTabLimitCount.integerValue = stepperTabLimitCount.integerValue
        SettingsManagerObject.maxTabLimitCount = stepperTabLimitCount.integerValue
        SettingsManagerObject.isSettingsChanged = true
        allApiObject.capturePosthog(event: "settings-changed-tab-limiter-count", metadata: ["count":SettingsManagerObject.maxTabLimitCount])//
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
}

extension browserTabLimiterVc: NSTextFieldDelegate{
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldTabLimitCount{
                if textFieldTabLimitCount.stringValue.isEmpty{
                    textFieldTabLimitCount.integerValue = SettingsManagerObject.maxTabLimitCount
                    return;
                }
                if textFieldTabLimitCount.integerValue < 1{
                    var msg = "Tab count can not be 0."
                    if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                        msg = preferencesInfo.value(forKey: "alertTabCountText") as? String ?? msg
                    }
                    showAlert(msg: msg, completionHandler: {_ in
                        //if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{ // todo need to cechk 
                         //   tabview.selectedTabViewItemIndex = preferencesSettingsIndex
                        //}
                        if settingsSideBarVcObj != nil{
                            settingsSideBarVcObj?.tblView.selectRowIndexes(IndexSet(integer: settingsSideBarVcObj!.strictnessSettingsIndex), byExtendingSelection: false)
                        }

                        self.textFieldTabLimitCount.integerValue = SettingsManagerObject.maxTabLimitCount
                        textfield.setFocus()
                    })
                    return;
                }
                let count = textfield.integerValue
                if SettingsManagerObject.maxTabLimitCount == count{
                    return;
                }
                SettingsManagerObject.isSettingsChanged = true
                
                stepperTabLimitCount.integerValue = textFieldTabLimitCount.integerValue
                SettingsManagerObject.maxTabLimitCount = stepperTabLimitCount.integerValue
                
                allApiObject.capturePosthog(event: "settings-changed-tab-limiter-count", metadata: ["count":SettingsManagerObject.maxTabLimitCount])//
                
            }
        }
    }
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            
            completionHandler(true)
            return
        })
    }
}
extension browserTabLimiterVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == enableTabLimiterItemVcObj{
            if state == .on{
                if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                    enableTabLimiterItemVcObj?.btnSwitch.state = .off
                    
                    let alertWarning = NSAlert()
                    alertWarning.setSharingType()
                    alertWarning.messageText = "Browser Permissions Required"
                    alertWarning.informativeText = "To enable the Browser Tab Limiter, permissions to manage browser tabs are required. Would you like to grant these permissions now?"
                    alertWarning.addButton(withTitle: buttonOkText)
                    alertWarning.addButton(withTitle: buttonCancelText)
                    
                    if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                        alertWarning.messageText = preferencesInfo.value(forKey: "alertWarningBrowserPermissionsTitle") as? String ?? alertWarning.messageText
                        alertWarning.informativeText = preferencesInfo.value(forKey: "alertWarningBrowserPermissionsInfo") as? String ?? alertWarning.informativeText
                    }
                    
                    alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                        if modalResponse == .alertFirstButtonReturn{
                            showExplainingPermissionsWindow(showingFromPomodoro: false)
                            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser) // if ok clicked then then only save here
                            self.view.window?.close()
                        }
                    })
                    return;//
                }
            }
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isTabLimiterEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-tab-limiter", metadata: [:])
            }else{
                SettingsManagerObject.isTabLimiterEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-tab-limiter", metadata: [:])
            }
        }
    }
}
