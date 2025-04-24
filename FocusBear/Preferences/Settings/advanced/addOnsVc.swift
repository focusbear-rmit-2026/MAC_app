//
//  addOnsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class addOnsVc: NSViewController {

    @IBOutlet weak var boxGetLateNoMore: NSBox!
    @IBOutlet weak var lblLateNoMoreAlreadyInstalled: NSTextField!
    @IBOutlet weak var btnGetLateNoMore: Button!
    @IBOutlet weak var lblDescriptionLateNoMore: NSTextField!
    @IBOutlet weak var lblTitleLateNoMore: NSTextField!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let timeTrackerEnabledItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    var stackViewBottomForDownLoadFbtt:NSStackView?
    var btnDownLoad: underLineButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblLateNoMoreAlreadyInstalled.stringValue = "Late No More already installed"
        lblTitle.stringValue = "Add Ons"
        btnGetLateNoMore.title = "Get Late No More"
        lblTitleLateNoMore.stringValue = "Get Late No More"
        lblDescriptionLateNoMore.stringValue = "Late No More gives notifications that escalate in intensity as it gets closer to the meetings start time. If you ignore the popups, you'll get verbal alerts (or a song)."

        

        var focusBearTrackerTitle = "Enable Focus Bear Time Tracker"
        var focusBearTrackerDescriptionTitle = "Analyse your productivity by tracking how much time you spend on different websites and apps. You can automatically categorise time logs into different projects (helpful for timesheets). Data is stored locally for privacy reasons."
        
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            focusBearTrackerTitle = settingsNew.value(forKey: "focusBearTrackerSettingTitle") as? String ?? focusBearTrackerTitle
            focusBearTrackerDescriptionTitle = settingsNew.value(forKey: "focusBearTrackerDescriptionTitle") as? String ?? focusBearTrackerDescriptionTitle
            lblLateNoMoreAlreadyInstalled.stringValue = settingsNew.value(forKey: "lateNoMoreAlreadyInstalledText") as? String ?? lblLateNoMoreAlreadyInstalled.stringValue
            lblTitle.stringValue = settingsNew.value(forKey: "addOnsTitle") as? String ?? lblTitle.stringValue
            lblTitleLateNoMore.stringValue = settingsNew.value(forKey: "titleGetLateNoMore") as? String ?? lblTitleLateNoMore.stringValue
            btnGetLateNoMore.title = settingsNew.value(forKey: "titleGetLateNoMore") as? String ?? btnGetLateNoMore.title
        }
        if let lateNoMorePopUpVcInfo = configjson.value(forKey: "lateNoMorePopUpVcInfo") as? NSDictionary{
            lblDescriptionLateNoMore.stringValue = lateNoMorePopUpVcInfo.value(forKey: "description") as? String ?? lblDescriptionLateNoMore.stringValue
        }
        stackView.addView(timeTrackerEnabledItemVcObj!.view, in: .bottom)
        timeTrackerEnabledItemVcObj?.lblTitle.stringValue = focusBearTrackerTitle
        timeTrackerEnabledItemVcObj?.lblSubTitle.stringValue = focusBearTrackerDescriptionTitle
        timeTrackerEnabledItemVcObj?.delegate = self
        timeTrackerEnabledItemVcObj?.lineBottom.isHidden = true
        
//
        addDownLoadNowOptionFbtt()
//
        
        arrForSearchFromSettings.append(["title": timeTrackerEnabledItemVcObj!.lblTitle.stringValue, "tabId": idAddOns, "object": timeTrackerEnabledItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": lblTitleLateNoMore.stringValue, "tabId": idAddOns, "object": boxGetLateNoMore as Any])
    }
    
    func addDownLoadNowOptionFbtt(){
        var titleDownloadTimeTrackerText = "Focus Bear Time Tracker needs to be downloaded and installed as a separate component."
        var buttonDownloadTimeTrackerText = "Download Now"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            titleDownloadTimeTrackerText = settingsNew.value(forKey: "titleDownloadTimeTrackerText") as? String ?? titleDownloadTimeTrackerText
            buttonDownloadTimeTrackerText = settingsNew.value(forKey: "buttonDownloadTimeTrackerText") as? String ?? buttonDownloadTimeTrackerText
        }
        
        
        let label = NSTextField(labelWithString: titleDownloadTimeTrackerText)
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.alignment = NSTextAlignment.left
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = NSColor.labelColor
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        btnDownLoad = underLineButton(title: buttonDownloadTimeTrackerText, target: self, action: #selector(btnDownLoadClicked))
        btnDownLoad?.isBordered = false
        btnDownLoad?.font = getRegularFont(size: 12)
        
        // Create the horizontal stack view
        let horizontalStackView = NSStackView()
        horizontalStackView.orientation = .horizontal
        horizontalStackView.spacing = 0
        horizontalStackView.alignment = .centerY
        
        // Add label and button to the horizontal stack view
        horizontalStackView.addArrangedSubview(label)
        horizontalStackView.addArrangedSubview(btnDownLoad!)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: horizontalStackView, attribute: .top, multiplier: 1.0, constant: 10)
        horizontalStackView.addConstraint(top)
        
        btnDownLoad!.setContentHuggingPriority(.defaultHigh, for: .vertical)
        btnDownLoad!.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        let topBtn = NSLayoutConstraint(item: btnDownLoad!, attribute: .top, relatedBy: .equal, toItem: horizontalStackView, attribute: .top, multiplier: 1.0, constant: 10)
        horizontalStackView.addConstraint(topBtn)
        
        horizontalStackView.alignment = .bottom
        stackViewBottomForDownLoadFbtt = horizontalStackView
        timeTrackerEnabledItemVcObj?.stackViewMain.addView(horizontalStackView, in: .bottom)
    }
    override func viewWillAppear() {
        if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool == true{
            timeTrackerEnabledItemVcObj?.btnSwitch.state = .on
        }else{
            timeTrackerEnabledItemVcObj?.btnSwitch.state = .off
        }
        
        if FileManager.default.fileExists(atPath: "/Applications/Late No More.app"){
            btnGetLateNoMore.isEnabled = false
            lblLateNoMoreAlreadyInstalled.isHidden = false
        }else{
            btnGetLateNoMore.isEnabled = true
            lblLateNoMoreAlreadyInstalled.isHidden = true
        }
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app"){
            stackViewBottomForDownLoadFbtt?.isHidden = true
        }else{
            stackViewBottomForDownLoadFbtt?.isHidden = false
        }

    }
    @objc func btnDownLoadClicked(){
        print("btndownloadclicked")
        if let url = URL(string: "https://downloads.focusbear.io/fbtt/FocusBearTimeTracker.dmg"){
            NSWorkspace.shared.open(url)
        }
    }
    @IBAction func btnGetLateNoMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/en/late-no-more"){
            NSWorkspace.shared.open(url)
        }
    }
    
    func highlightAdvanceAanalyticsItemBox(){
        if let object = timeTrackerEnabledItemVcObj?.bgBox{
            object.wantsLayer = true
            object.layer?.cornerRadius = 3
            object.layer?.borderWidth = 1
            object.layer?.borderColor = NSColor.labelColor.cgColor
            DispatchQueue.global().async {
                sleep(2)
                DispatchQueue.main.async {
                    object.layer?.cornerRadius = 0
                    object.layer?.borderWidth = 0
                    object.layer?.borderColor = NSColor.clear.cgColor
                    object.wantsLayer = false
                }
            }
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}


extension addOnsVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == timeTrackerEnabledItemVcObj{
            if state == .on{
                if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabledOneTime) == nil{
                    object.btnSwitch.state = .off
                    showTimeTrackerWindow(showingAutomatically:false)
                }else{
                    if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app"){
                        enableTimeTracker()
                    }else{
                        let alert = NSAlert()
                        alert.setSharingType()
                        alert.alertStyle = .informational
                        object.btnSwitch.state = .off
                        
                        
                        var titleDownloadTimeTrackerText = "Focus Bear Time Tracker needs to be downloaded and installed as a separate component."
                        var buttonDownloadTimeTrackerText = "Download Now"
                        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
                            titleDownloadTimeTrackerText = settingsNew.value(forKey: "titleDownloadTimeTrackerText") as? String ?? titleDownloadTimeTrackerText
                            buttonDownloadTimeTrackerText = settingsNew.value(forKey: "buttonDownloadTimeTrackerText") as? String ?? buttonDownloadTimeTrackerText
                        }
                        
                        
                        alert.messageText = titleDownloadTimeTrackerText
                        alert.addButton(withTitle: buttonDownloadTimeTrackerText)
                        alert.addButton(withTitle: buttonCancelText)

                        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                if let url = URL(string: "https://downloads.focusbear.io/fbtt/FocusBearTimeTracker.dmg"){
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        })
                    }
                }
            }else{
                allApiObject.capturePosthog(event: "settings-changed-disable-time-tracker", metadata: [:])
                UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
                writeSettingForScreeenTime(habitInfo: "")
            }
        }
    }
    
    
}
