//
//  addFocusTypeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/02/22.

//

import Cocoa

class addFocusTypeVc: NSViewController, NSTextFieldDelegate  {

    @IBOutlet weak var bntColorBoxInfo: NSButton!
    @IBOutlet weak var lblViewTitle: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    @IBOutlet weak var lblTitleColor: NSTextField!
    @IBOutlet weak var textFieldFocusType: NSTextField!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var btnAdd: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var lblError: NSTextField!
    
//    var isAdding = true
    var buttonAddText = "Add"
    var titleAddFocusType = "Add Focus Type"
//    var titleEditFocusType = "Edit Focus Type"
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.title = "Cancel"
        
        
        lblTitleName.stringValue = "Title:"
        lblTitleColor.stringValue = "Color:"
        
        lblError.stringValue = "Focus type with the same name already exist."
        lblError.isHidden = true
        textFieldFocusType.delegate = self
        
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let buttonCancelText = focusPreferencesInfo.value(forKey: "buttonCancelText") as? String{
                btnCancel.title = buttonCancelText
            }
            if let titleTitle = focusPreferencesInfo.value(forKey: "titleTitle") as? String{
                lblTitleName.stringValue = titleTitle
            }
            if let titleColor = focusPreferencesInfo.value(forKey: "titleColor") as? String{
                lblTitleColor.stringValue = titleColor
            }
            
            if let errorSameFocusType = focusPreferencesInfo.value(forKey: "errorSameFocusType") as? String{
                lblError.stringValue = errorSameFocusType
            }
            
            buttonAddText = focusPreferencesInfo.value(forKey: "buttonAddText") as? String ?? buttonAddText
//            buttonSaveText = focusPreferencesInfo.value(forKey: "buttonSaveText") as? String ?? buttonSaveText
            titleAddFocusType = focusPreferencesInfo.value(forKey: "titleAddFocusType") as? String ?? titleAddFocusType
//            titleEditFocusType = focusPreferencesInfo.value(forKey: "titleEditFocusType") as? String ?? titleEditFocusType
        }
        
        btnInfoColorBoxTrackingArea = NSTrackingArea.init(rect: bntColorBoxInfo.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        bntColorBoxInfo.addTrackingArea(btnInfoColorBoxTrackingArea!)
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            toolTipColorBox = common.value(forKey: "toolTipColorBoxText") as? String ?? toolTipColorBox
        }
        
    }
    
    var btnInfoColorBoxTrackingArea: NSTrackingArea?
    var toolTipColorBox = "Choose a color to be displayed in the background of the top menu bar icon to help identify the Focus Mode you are running"
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == btnInfoColorBoxTrackingArea{
            showTooltip(sender: bntColorBoxInfo, msg: toolTipColorBox, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
    }
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == btnInfoColorBoxTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    @IBAction func bntColorBoxInfoClicked(_ sender: Any) {
        addLog(text: "[user-action] bntColorBoxInfoClicked")
        showTooltip(sender: bntColorBoxInfo, msg: toolTipColorBox, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    override func viewWillAppear() {
        colorWell.color = NSColor.random
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
       
        
        lblError.isHidden = true
        btnAdd.keyEquivalent = "\r"
        btnAdd.isEnabled = false
        
//        if isAdding{
            textFieldFocusType.stringValue = ""
            btnAdd.title = buttonAddText
            lblViewTitle.stringValue = titleAddFocusType
//        }
        
//        else{
//            textFieldFocusType.stringValue = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["name"] as? String ?? ""
//            if let colorString = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["color"] as? String{
//                let color = HexToColor(hexString: colorString)
//                colorWell.color = color
//            }
//            btnAdd.title = buttonSaveText
//            lblViewTitle.stringValue = titleEditFocusType
//
//        }
    }
    
    var cp = NSColorPanel.shared
    @IBAction func btnShowColorPanelClicked(_ sender: Any) {
        cp = NSColorPanel.shared
        cp.mode = .RGB
        cp.setTarget(self)
        cp.setAction(#selector(colorDidChange))
        cp.makeKeyAndOrderFront(self)
        cp.isContinuous = false// qki api call hogi isliye false kiya
        cp.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        cp.color = colorWell.color
    }
    
    @objc func colorDidChange(){
        colorWell.color = cp.color
    }
    
    @IBAction func colorWellClicked(_ sender: Any) {
//        if !isAdding{
//            if !textFieldFocusType.stringValue.isEmpty{
//                btnAdd.isEnabled = true
//            }
//        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func btnAddClicked(_ sender: Any) {
        //        if isAdding{
        let newName = textFieldFocusType.stringValue.lowercased
        for dic in arrFocusType{
            if let name = dic["name"] as? String{
                if name.lowercased() == newName(){
                    lblError.isHidden = false
                    return;
                }
            }
        }
        let id = getUuid()
        let dic:[String:Any] = ["id":id, "name":textFieldFocusType.stringValue, "color": getColorString(color: colorWell.color), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]//, "isAllowedAllUrls":true , "isBlockedAllUrls":false#453
        
        let row = focusPreferencesVcObj?.tblViewFocusType.numberOfRows ?? 0
        arrFocusType.insert(dic, at: row)
        sortFocusModes()
        
        for i in 0..<arrFocusType.count{
            if let idFocusMode = arrFocusType[i]["id"] as? String{
                if idFocusMode == id{
                    focusPreferencesVcObj?.tblViewFocusType.insertRows(at: IndexSet(arrayLiteral: i), withAnimation: .effectFade)
                    focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: i), byExtendingSelection: false)
                    focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(i)
                    break;
                }
            }
        }
        
        
        
        focusPreferencesVcObj?.checkState()
        
        
        lblError.isHidden = true
        self.dismiss(self)
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        resetPomodoroVcFocusListIfNeeded()
        
//        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
//            if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
//                startingFocusWindowControllerObj?.close()
//            }
//        }
        
        allApiObject.addFocusMode(focusType: dic)
        allApiObject.capturePosthog(event: "add-new-focus-mode", metadata: [:])
    }
    func controlTextDidChange(_ obj: Notification) {
        guard let txtfield = obj.object as? NSTextField else {
            return
        }
        if txtfield == textFieldFocusType{
            lblError.isHidden = true
            if textFieldFocusType.stringValue.count > 250{
//                textFieldFocusType.currentEditor()?.deleteBackward(nil)//
                let index = textFieldFocusType.stringValue.index(textFieldFocusType.stringValue.startIndex, offsetBy: 250)
                textFieldFocusType.stringValue = String(textFieldFocusType.stringValue.prefix(upTo: index))
            }
            if textFieldFocusType.stringValue.count == 0{
                btnAdd.isEnabled = false
            }else{
                btnAdd.isEnabled = true
            }
        }
    }
    
}
