//
//  focusPreferencesViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class focusPreferencesVc: NSViewController, NSMenuDelegate {

   
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var btnAdvanced: NSButton!
    @IBOutlet weak var horizontalLineSeprator: NSBox!
    @IBOutlet weak var radioBtnAllowAllApps: NSButton!
    @IBOutlet weak var radioBtnAllowSelectedApps: NSButton!
    
    @IBOutlet weak var radioBtnAllowAllUrls: NSButton!
    @IBOutlet weak var radioBtnAllowSelectedUrls: NSButton!
    
    @IBOutlet weak var lblTitleFocusType: NSTextField!
    @IBOutlet weak var boxAllowedWebUrls: NSBox!
    @IBOutlet weak var boxAllowedApps: NSBox!
    @IBOutlet weak var lblNoFocusAdded: NSTextField!
    @IBOutlet weak var boxEmptyFocusType: NSBox!
//    @IBOutlet weak var toggleButton: CToggleButton!
//    @IBOutlet weak var lblTitle: NSTextField!
//    @IBOutlet weak var lblTitleAllowedUrls: NSTextField!
//    @IBOutlet weak var lblTitleAllowedApps: NSTextField!
    @IBOutlet weak var textFieldSelectedFocusType: NSTextField!
  
    @IBOutlet weak var tblViewAllowedApps: NSTableView!
    @IBOutlet weak var tblViewFocusType: NSTableView!
    @IBOutlet weak var tblViewAllowedUrls: NSTableView!
    
    @IBOutlet weak var btnAddFocusType: NSButton!
    @IBOutlet weak var btnRemoveFocusType: NSButton!
    @IBOutlet weak var btnAddApp: NSButton!
    @IBOutlet weak var btnRemoveApp: NSButton!
    @IBOutlet weak var btnAddUrl: NSButton!
    @IBOutlet weak var btnRemoveUrl: NSButton!
    
    @IBOutlet weak var btnDuplicateFocusType: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        var toolTipAdd = "Add"
        var toolTipRemove = "Remove"
        var toolTipDuplicate = "Duplicate"
        
        
        btnAddFocusType.title = "Add Focus Mode"
        btnDuplicateFocusType.title = "Duplicate"
        btnRemoveFocusType.title = "Delete"
        
        focusPreferencesVcObj = self
        var titleAllowedAllApps = "Allow all apps"
        var titleAllowedSelectedApps = "Allow selected apps"
        
        var titleAllowedAllUrls = "Allow all urls"
        var titleAllowedSelectedUrls = "Allow selected urls (works with Safari and Chrome only)"
        
        var titleFocusType = "Focus Type:"
        
        var noFocusAddedText = "Please add a Focus Type in left panel."
        btnAdvanced.title = "Advanced..."
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            titleAllowedAllApps = focusPreferencesInfo.value(forKey: "titleAllowedAllApps") as? String ?? titleAllowedAllApps
            titleAllowedSelectedApps = focusPreferencesInfo.value(forKey: "titleAllowedSelectedApps") as? String ?? titleAllowedSelectedApps
            titleAllowedAllUrls = focusPreferencesInfo.value(forKey: "titleAllowedAllUrls") as? String ?? titleAllowedAllUrls
            titleAllowedSelectedUrls = focusPreferencesInfo.value(forKey: "titleAllowedSelectedUrls") as? String ?? titleAllowedSelectedUrls
            titleFocusType = focusPreferencesInfo.value(forKey: "titleFocusType") as? String ?? titleFocusType
            noFocusAddedText = focusPreferencesInfo.value(forKey: "noFocusAddedText") as? String ?? noFocusAddedText
            toolTipAdd = focusPreferencesInfo.value(forKey: "toolTipAdd") as? String ?? toolTipAdd
            toolTipRemove = focusPreferencesInfo.value(forKey: "toolTipRemove") as? String ?? toolTipRemove
            toolTipDuplicate = focusPreferencesInfo.value(forKey: "toolTipDuplicate") as? String ?? toolTipDuplicate
            btnAdvanced.title = focusPreferencesInfo.value(forKey: "buttonAdvancedText") as? String ?? btnAdvanced.title
            btnAddFocusType.title = focusPreferencesInfo.value(forKey: "buttonAddFocusTypeText") as? String ?? btnAddFocusType.title
            btnRemoveFocusType.title = focusPreferencesInfo.value(forKey: "buttonDeleteFocusTypeText") as? String ?? btnRemoveFocusType.title
        }
        lblTitleFocusType.stringValue = titleFocusType
        radioBtnAllowAllApps.title = titleAllowedAllApps
        radioBtnAllowSelectedApps.title = titleAllowedSelectedApps
        radioBtnAllowAllUrls.title = titleAllowedAllUrls
        radioBtnAllowSelectedUrls.title = titleAllowedSelectedUrls

        btnDuplicateFocusType.title = toolTipDuplicate
        
        btnDuplicateFocusType.toolTip = toolTipDuplicate
        btnAddFocusType.toolTip = toolTipAdd
        btnRemoveFocusType.toolTip = toolTipRemove
        btnAddApp.toolTip = toolTipAdd
        btnRemoveApp.toolTip = toolTipRemove
        btnAddUrl.toolTip = toolTipAdd
        btnRemoveUrl.toolTip = toolTipRemove
        
        
        lblNoFocusAdded.stringValue = noFocusAddedText
//        NotificationCenter.default.addObserver(self, selector: #selector(btnToggleClicked), name: Notification.Name("toggle"), object: nil)
        
      //  tblViewFocusType.doubleAction = #selector(tableRowFocusTypeDoubleClicked)
        tblViewAllowedUrls.doubleAction = #selector(tableRowAllowedUrlsDoubleClicked)
        
        let menu = NSMenu()
        
        menu.delegate = self
//        menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        tblViewFocusType.menu = menu

        textFieldSelectedFocusType.delegate = self
        
        
        
        
        
    }
    
    var cp = NSColorPanel.shared
    @IBAction func btnShowColorPanelClicked(_ sender: Any) {
        
        cp = NSColorPanel.shared
        cp.color = colorWell.color
        cp.mode = .RGB
        cp.setTarget(self)
        cp.setAction(#selector(colorDidChange))
        cp.makeKeyAndOrderFront(self)
        cp.isContinuous = false// qki api call hogi isliye false kiya
        cp.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        //  self.perform(#selector(colorDidChange), with: nil, afterDelay: 3)
    }
    @objc func colorDidChange(){
        if tblViewFocusType.selectedRow == -1{
            return;
        }
        colorWell.color = cp.color
        var dic = arrFocusType[tblViewFocusType.selectedRow]
        dic["color"] = getColorString(color: colorWell.color)
        arrFocusType[tblViewFocusType.selectedRow] = dic
        tblViewFocusType.reloadData(forRowIndexes: IndexSet(arrayLiteral: tblViewFocusType.selectedRow), columnIndexes: IndexSet(arrayLiteral: 0))
        
        tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: tblViewFocusType.selectedRow), byExtendingSelection: false)
        tblViewFocusType.scrollRowToVisible(tblViewFocusType.selectedRow)
        checkState()
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
            DispatchQueue.main.async {
                print("*************************api called*****************")
                
            }
        })
    }
    
    @objc private func tableViewDuplicateItemClicked(_ sender: AnyObject) {
        makeDuplicateFocus(row: tblViewFocusType.clickedRow)
    }
    
    func makeDuplicateFocus(row:Int){
        guard row >= 0 else { return }
        var isDefault = false
        var item = arrFocusType[row]
        if (item["isDefault"] as? Bool) != nil{
            isDefault = true
            item.removeValue(forKey: "isDefault")
        }
        if (item["isMeetings"] as? Bool) != nil{
            item.removeValue(forKey: "isMeetings")
        }
        let oldName = item["name"] as? String ?? ""
        var count = 1
        var newName = oldName + " \(count)"
        var isNameAvailable = false
        while !isNameAvailable {
            if !isFocusNameAvailable(newName: newName){
                count += 1
                newName = oldName + " \(count)"
            }else{
                isNameAvailable = true
            }
        }
        item["name"] = newName
        item["isOn"] = false
        item.removeValue(forKey: "id")
        let id = getUuid()
        item["id"] = id
        var newRow = 0
        if !isDefault{//if default than duplicate will second last //tod test
            newRow = row + 1
        }else{
            newRow = row
        }
        arrFocusType.insert(item, at: newRow)
        
        
        tblViewFocusType.insertRows(at: IndexSet(arrayLiteral: newRow), withAnimation: .effectFade)
        tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: newRow), byExtendingSelection: false)
        tblViewFocusType.scrollRowToVisible(newRow)
        focusPreferencesVcObj?.checkState()

        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        allApiObject.addFocusMode(focusType: item, completionHandler: { newDic in
            if newDic != nil{
                DispatchQueue.main.async {
//                    item["id"] = newDic!.value(forKey: "id") as? String ?? ""//["id"] as? String ?? ""
                    
                }
            }
            
        })
        
        
    }
    @IBAction func btnDuplicateFocusTypeClicked(_ sender: Any) {
        makeDuplicateFocus(row: tblViewFocusType.selectedRow)
    }
//    func focusModeStarted(){
//        for i in 0..<arrFocusType.count{
//            if arrFocusType[i]["isOn"] as? Bool == true{
//                if tblViewFocusType.selectedRow == i{
//                  //  toggleButton.isOn = true
//                    break;
//                }
//            }
//        }
//    }
//
//    func focusModeFinished(){
//        for i in 0..<arrFocusType.count{
//            if arrFocusType[i]["isOn"] as? Bool == false{
//                if tblViewFocusType.selectedRow == i{
////                    toggleButton.isOn = false
//                    break;
//                }
//            }
//        }
//    }
    
    func isFocusNameAvailable(newName:String)->Bool{
        for focus in arrFocusType{
            if let name = focus["name"] as? String{
                if newName.lowercased() == name.lowercased(){
                    return false
                }
            }
        }
        return true
    }
    func menuWillOpen(_ menu: NSMenu) {
        var duplicateText = "Duplicate"
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            duplicateText = focusPreferencesInfo.value(forKey: "duplicateText") as? String ?? duplicateText
        }
        menu.removeAllItems()
        if tblViewFocusType.clickedRow != -1{
             menu.addItem(NSMenuItem(title: duplicateText, action: #selector(tableViewDuplicateItemClicked(_:)), keyEquivalent: ""))
        }
        
    }
//    var cp = NSColorPanel.shared
    override func viewWillAppear() {
        reloadData()
    }
    
    func reloadData(){
        tblViewFocusType.reloadData()
        checkState()
        
        if arrFocusType.count != 0{
            if tblViewFocusType.selectedRow == -1{
                tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: false)
            }
            if let name = arrFocusType[tblViewFocusType.selectedRow]["name"] as? String{
                textFieldSelectedFocusType.stringValue = name
            }else{
                textFieldSelectedFocusType.stringValue = ""
            }
            if let isOn = arrFocusType[tblViewFocusType.selectedRow]["isOn"] as? Bool{
              //  toggleButton.isOn = isOn
            }else{
               // toggleButton.isOn = false
            }
            
            tblViewAllowedApps.reloadData()
            tblViewAllowedUrls.reloadData()
        }
    }
    
    @IBAction func radioBtnAllowAllAppsClicked(_ sender: Any) {
        radioBtnAllowAllApps.state = .on
        radioBtnAllowSelectedApps.state = .off
        tblViewAllowedApps.isEnabled = false
        tblViewAllowedApps.deselectAll(self)
        btnAddApp.isEnabled = false
        btnRemoveApp.isEnabled = false
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllApps"] = true
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.editFocusMode(focusType: arrFocusType[selectedRow], completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        if arrFocusType[selectedRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowAppArray()
        }
        
        
    }
    @IBAction func radioBtnAllowSelectedAppsClicked(_ sender: Any) {
        radioBtnAllowAllApps.state = .off
        radioBtnAllowSelectedApps.state = .on
        tblViewAllowedApps.isEnabled = true
        btnAddApp.isEnabled = true
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllApps"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.editFocusMode(focusType: arrFocusType[selectedRow], completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        if arrFocusType[selectedRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowAppArray()
        }
    }
    @IBAction func radioBtnAllowAllUrlsClicked(_ sender: Any) {
        radioBtnAllowAllUrls.state = .on
        radioBtnAllowSelectedUrls.state = .off
        tblViewAllowedUrls.isEnabled = false
        tblViewAllowedUrls.deselectAll(self)
        btnAddUrl.isEnabled = false
        btnRemoveUrl.isEnabled = false
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllUrls"] = true
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.editFocusMode(focusType: arrFocusType[selectedRow], completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        if arrFocusType[selectedRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowUrlArray()
        }
    }
    @IBAction func radioBtnAllowSelectedUrlsClicked(_ sender: Any) {
        radioBtnAllowAllUrls.state = .off
        radioBtnAllowSelectedUrls.state = .on
        tblViewAllowedUrls.isEnabled = true
        btnAddUrl.isEnabled = true
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllUrls"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.editFocusMode(focusType: arrFocusType[selectedRow], completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        if arrFocusType[selectedRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowUrlArray()
        }
    }
    
//    @objc func tableRowFocusTypeDoubleClicked(){
//        let selectedTow = tblViewFocusType.selectedRow
//        if selectedTow == -1{
//            return;
//        }
//        if let state = arrFocusType[selectedTow]["isDefault"] as? Bool{//this key will only be awailable in default focus type
//            if state{
//                return
//            }
//        }
//        if let state = arrFocusType[selectedTow]["isMeetings"] as? Bool{//this key will only be awailable in Meetings focus type
//            if state{
//                return
//            }
//        }
//
//        
//        addFocusTypeVcObj?.isAdding = false
//        self.presentAsSheet(addFocusTypeVcObj!)
//        
//    }
    @objc func tableRowAllowedUrlsDoubleClicked(){
        let selectedTow = tblViewAllowedUrls.selectedRow
        if selectedTow == -1{
            return;
        }
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_ALLOW_URL
        addWebUrlVcObj!.isAdding = false
        self.presentAsSheet(addWebUrlVcObj!)
    }
    //todo toggle class kaam ki hai kya ab
//    @objc func btnToggleClicked(notification: Notification) {
//        if let state = notification.userInfo!["isOn"] as? Bool, let row = notification.userInfo!["index"] as? Int{
//            print(row)
//            print(state)
//
//            if state{
//                if isDiscourageDefaultFocusVcVisible{
//                    toggleButton.isOn = false
//                    return
//                }
//                //if state{
//                for i in 0..<arrFocusType.count{
//                    if arrFocusType[i]["isOn"] as? Bool == true{
//                        let alert = NSAlert()
//                        alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
//                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                            if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
//                                alert.messageText = focusAlreadyRunningText
//                            }
//                        }
//                        alert.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
//                        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
//                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
//
//                            }
//                        })
//
//                        toggleButton.isOn = false
//                        return;
//                    }
//                }
//                toggleButton.isOn = false
//
//
//
//
////                if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true{
////                    let alertConfirmation = NSAlert()
////                    alertConfirmation.messageText = "Are you sure? It's pretty easy to get distracted without using a more restrictive focus mode"
////                    alertConfirmation.addButton(withTitle: "Shutup I know what I'm doing")
////                    alertConfirmation.addButton(withTitle: "Bah I guess you're right - CANCEL!")
////
////                    alertConfirmation.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
////                        if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
////                            print("Shutup I know what I'm doing")
////
////                            self.secondsAlert = NSAlert()
////                            self.secondsAlert!.messageText = "Ok good luck! (You'll need it 😅)"
////                            self.secondsAlert!.informativeText = "05:00"
////                            self.secondsCount = 5
////                            self.secondsAlert?.addButton(withTitle: "")
////                            self.secondsAlert!.beginSheetModal(for: self.view.window!, completionHandler: nil)
////                            self.secondsAlert!.buttons.first?.isHidden = true
////
////                            self.currentSecond = 0
////                            self.secondsCount = 5
////                            let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.secondsCount-self.currentSecond)
////                            var minute = "\(m)"
////                            var second = "\(s)"
////                            if minute.count == 1 {
////                                minute = "0\(m)"
////                            }
////                            if second.count == 1 {
////                                second = "0\(s)"
////                            }
////                            self.secondsAlert!.informativeText = "\(minute):\(second)"
////
////                            DispatchQueue.main.async {
////                                self.timerSeconds = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.changeAlertCount), userInfo: nil, repeats: true)
////                            }
////
////
////                        }
////                    })
////                    self.presentAsSheet(getDiscourageDefaultFocusVcObject())
////                    getDiscourageDefaultFocusVcObject().resetData()
////                    return;
////                }else{
//                     showStartingFocusMode(focusModeIndex: tblViewFocusType.selectedRow, focusType: arrFocusType[tblViewFocusType.selectedRow]["name"] as? String ?? "")
////                }
//
//
//
//
//
//
//
//                return;
//
//            }else{
//                if isDiscourageDefaultFocusVcVisible{
//                    toggleButton.isOn = true
//                    return
//                }
//                toggleButton.isOn = true
//                showAbortingFocusModeVc()
//            }
//
//        }
//    }
//    var secondsAlert: NSAlert?
//    var secondsCount = 5
//    var currentSecond = 0
//    var timerSeconds:Timer?
//    @objc func changeAlertCount(){
//        self.secondsAlert!.buttons.first?.isHidden = true
//        currentSecond += 1
//        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.secondsCount-self.currentSecond)
//        var minute = "\(m)"
//        var second = "\(s)"
//
//        if minute.count == 1 {
//            minute = "0\(m)"
//        }
//        if second.count == 1 {
//            second = "0\(s)"
//        }
//
////        DispatchQueue.main.async {
//            self.secondsAlert?.informativeText = "\(minute):\(second)"
////        }
//        if self.secondsCount <= self.currentSecond {
//            self.timerSeconds?.invalidate()
//            self.secondsAlert?.window.close()
//            self.secondsAlert = nil
//            self.timerSeconds = nil
//        }
//    }
    @IBAction func btnAddFocusTypeClicked(_ sender: Any) {
//        addFocusTypeVcObj?.isAdding = true
        self.presentAsSheet(addFocusTypeVcObj!)
    }

    func checkState(){
        if arrFocusType.count == 0{
//            toggleButton.isHidden = true
            textFieldSelectedFocusType.isHidden = true
            radioBtnAllowSelectedUrls.isHidden = true
            radioBtnAllowAllUrls.isHidden = true
            radioBtnAllowSelectedApps.isHidden = true
            radioBtnAllowAllApps.isHidden = true
            boxAllowedApps.isHidden = true
            boxAllowedWebUrls.isHidden = true
            boxEmptyFocusType.isHidden = false
            btnRemoveFocusType.isEnabled = false
            horizontalLineSeprator.isHidden = true
        }else{
//            toggleButton.isHidden = false
            textFieldSelectedFocusType.isHidden = false
            boxAllowedApps.isHidden = false
            radioBtnAllowSelectedUrls.isHidden = false
            radioBtnAllowAllUrls.isHidden = false
            radioBtnAllowSelectedApps.isHidden = false
            radioBtnAllowAllApps.isHidden = false
            boxAllowedWebUrls.isHidden = false
            boxEmptyFocusType.isHidden = true
            btnRemoveFocusType.isEnabled = true
            horizontalLineSeprator.isHidden = false
        }
    }
    
    
    @IBAction func btnRemoveFocusTypeClicked(_ sender: Any) {
        if isHardCorePomodoroModeOn{
            let alert = NSAlert()
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                if state{
                    alert.window.sharingType = .none
                }
            }
            //            alert.messageText = "Can not delete."
            alert.messageText = "HardCore Pomodoro mode is on. Please abort the HardCore Pomodoro mode to delete it."
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                if let hardCorePomodoroIsOnMessageText = focusPreferencesInfo.value(forKey: "hardCorePomodoroIsOnMessageText") as? String{
                    alert.messageText = hardCorePomodoroIsOnMessageText
                }
            }
            alert.beginSheetModal(for: self.view.window!, completionHandler:nil)
            return
        }
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow == -1{
            return
        }
        if let state = arrFocusType[selectedRow]["isDefault"] as? Bool{//this key will only be awailable in default focus type
            if state{
                let alertFocusModeDefault = NSAlert()
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alertFocusModeDefault.window.sharingType = .none
                    }
                }
                alertFocusModeDefault.messageText = "Can not delete."
                alertFocusModeDefault.informativeText = "The Default focus type cannot be deleted."
                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                    if let focusCanNotDeleteTitle = focusPreferencesInfo.value(forKey: "focusCanNotDeleteTitle") as? String{
                        alertFocusModeDefault.messageText = focusCanNotDeleteTitle
                    }
                    if let focusCanNotDeleteSubTitle = focusPreferencesInfo.value(forKey: "focusCanNotDeleteSubTitle") as? String{
                        alertFocusModeDefault.informativeText = focusCanNotDeleteSubTitle
                    }
                }
                alertFocusModeDefault.beginSheetModal(for: self.view.window!, completionHandler:nil)
                return
            }
        }
        
        
        if let state = arrFocusType[selectedRow]["isMeetings"] as? Bool{//this key will only be awailable in default focus type
            if state{
                let alertFocusModeDefault = NSAlert()
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        alertFocusModeDefault.window.sharingType = .none
                    }
                }
                alertFocusModeDefault.messageText = "Can not delete."
                alertFocusModeDefault.informativeText = "The Default focus type cannot be deleted."
                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                    if let focusCanNotDeleteTitle = focusPreferencesInfo.value(forKey: "focusCanNotDeleteTitle") as? String{
                        alertFocusModeDefault.messageText = focusCanNotDeleteTitle
                    }
                    if let focusCanNotDeleteSubTitle = focusPreferencesInfo.value(forKey: "focusCanNotDeleteSubTitle") as? String{
                        alertFocusModeDefault.informativeText = focusCanNotDeleteSubTitle
                    }
                }

                alertFocusModeDefault.beginSheetModal(for: self.view.window!, completionHandler:nil)
                return
            }
        }
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
                    
                    if hardCorePomodoroState{
                        if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                            if arrFocusType[selectedRow]["name"] as? String == name{
//                                UserDefaults.standard.set(textFieldSelectedFocusType.stringValue, forKey: kUserdefaultsHardcorePomodoroFocusedName)
                                
                                //The selected focus mode is enabled in hardcore pomodoro mode. please disable hardcore pomodoro mode to delete this.
                                let alert = NSAlert()
                                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                                    if state{
                                        alert.window.sharingType = .none
                                    }
                                }
                                alert.messageText = "The selected focus mode is enabled in hardcore pomodoro mode. please disable hardcore pomodoro mode to delete this."
                                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                                    if let disablePomodoroModeAlertText = focusPreferencesInfo.value(forKey: "disablePomodoroModeAlertText") as? String{
                                        alert.messageText = disablePomodoroModeAlertText
                                    }
                                }
                                alert.addButton(withTitle: buttonOkText)
                                alert.beginSheetModal(for: self.view.window!, completionHandler:nil)
                                return
                                
                            }
                        }
                        
                    }
                    
                }
            }
            
        }
        
        if arrFocusType[selectedRow]["isOn"] as? Bool == true{
            let alertFocusModeOn = NSAlert()
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                if state{
                    alertFocusModeOn.window.sharingType = .none
                }
            }
            alertFocusModeOn.messageText = "Focus mode is on. Please abort the focus mode to delete it."
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                if let focusModeOnText = focusPreferencesInfo.value(forKey: "focusModeOnText") as? String{
                    alertFocusModeOn.messageText = focusModeOnText
                }
            }
            alertFocusModeOn.beginSheetModal(for: self.view.window!, completionHandler:nil)
            return
        }
        
        let alert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
        alert.alertStyle = .informational

        
        var deleteFocusTypeMessageText = "Are you sure you want to delete the selected Focus type?"
        var yesText = "Yes"
        var noText = "No"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            deleteFocusTypeMessageText = focusPreferencesInfo.value(forKey: "deleteFocusTypeMessageText") as? String ?? deleteFocusTypeMessageText
            yesText = focusPreferencesInfo.value(forKey: "yesText") as? String ?? yesText
            noText = focusPreferencesInfo.value(forKey: "noText") as? String ?? noText
        }
        
        alert.messageText = deleteFocusTypeMessageText
        alert.addButton(withTitle: yesText)
        alert.addButton(withTitle: noText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                if arrFocusType.count > selectedRow{

                    let id = arrFocusType[selectedRow]["id"] as? String ?? ""
                    arrFocusType.remove(at: selectedRow)
                    self.tblViewFocusType.reloadData()
                    self.checkState()
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    resetPomodoroVcFocusListIfNeeded()
                    if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                        if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
                            startingFocusWindowControllerObj?.close()
                        }
                    }
                    
                    
                    allApiObject.deleteFocusMode(id: id, completionHandler: {isDeleted in
                       
                        DispatchQueue.main.async {
                            if isDeleted{
                                
                            }else{
                                
                            }
                            
                        }
                        
                    })
                    
                    
                }
            }
        })
        
    }
    
    @IBAction func btnAddAppClicked(_ sender: Any) {

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.directoryURL = URL(fileURLWithPath: "/Applications")
        openPanel.allowedFileTypes = ["app"]
        
        
        openPanel.prompt = "Select"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let title = focusPreferencesInfo.value(forKey: "buttonSelectAppText") as? String{
                openPanel.prompt = title
            }
        }
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                //                if var arr =
                
                return
            }
            let urls = openPanel.urls
            
            
            if self.tblViewFocusType.selectedRow != -1{
                var appsArray = [String]()
                var appsUrlArray = [URL]()
                if let arr = arrFocusType[self.tblViewFocusType.selectedRow]["allowed_apps"] as? [String]{
                    appsArray = arr
                }
                //
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
                arrFocusType[self.tblViewFocusType.selectedRow]["allowed_apps"] = appsArray
                self.tblViewAllowedApps.reloadData()
                self.tblViewAllowedApps.selectRowIndexes(IndexSet(arrayLiteral: (appsArray.count - 1)), byExtendingSelection: false)
                self.tblViewAllowedApps.scrollRowToVisible(appsArray.count - 1)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                appdelegate!.fillAllowAppArray()
                if isContainAlready{
                    self.showAlertAppAlreadyAdded()
                }
                
                allApiObject.editFocusMode(focusType: arrFocusType[self.tblViewFocusType.selectedRow], completionHandler: {newDic in
                    DispatchQueue.main.async {

                    }
                })
            }
        }
        
    }//this app is already added in the list.
    func showAlertAppAlreadyAdded(){
        let alert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
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
//    Some of the items selected are already present in the list.
    @IBAction func btnRemoveAppClicked(_ sender: Any) {
        let selectedFocusTypeRow = tblViewFocusType.selectedRow
        if selectedFocusTypeRow == -1{
            return
        }
        
        let selectedAppsRow = tblViewAllowedApps.selectedRow
        if selectedAppsRow == -1{
            return
        }
        
        if arrFocusType.count > selectedFocusTypeRow{

            if var arr = arrFocusType[selectedFocusTypeRow]["allowed_apps"] as? [String]{
                if arr.count > selectedAppsRow{
                    arr.remove(at: selectedAppsRow)
                }
                arrFocusType[selectedFocusTypeRow]["allowed_apps"] = arr
            }
            self.tblViewAllowedApps.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: arrFocusType[selectedFocusTypeRow], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
        if arrFocusType[selectedFocusTypeRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowAppArray()
        }
    }
    @IBAction func btnAddUrlClicked(_ sender: Any) {
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_ALLOW_URL
        addWebUrlVcObj!.isAdding = true
        self.presentAsSheet(addWebUrlVcObj!)
    }
    @IBAction func btnRemoveUrlClicked(_ sender: Any) {
        let selectedFocusTypeRow = tblViewFocusType.selectedRow
        if selectedFocusTypeRow == -1{
            return
        }
        
        let selectedUrlsRow = tblViewAllowedUrls.selectedRow
        if selectedUrlsRow == -1{
            return
        }
        
        if arrFocusType.count > selectedFocusTypeRow{

            if var arr = arrFocusType[selectedFocusTypeRow]["allowed_urls"] as? [String]{
                if arr.count > selectedUrlsRow{
                    arr.remove(at: selectedUrlsRow)
                }
                arrFocusType[selectedFocusTypeRow]["allowed_urls"] = arr
            }
            self.tblViewAllowedUrls.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: arrFocusType[selectedFocusTypeRow], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
        if arrFocusType[selectedFocusTypeRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowUrlArray()
        }
    }
    
    @IBAction func btnAdvancedClicked(_ sender: Any) {
        if focusPreferencesAdvancedVcObj == nil{
            focusPreferencesAdvancedVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesAdvancedVc")) as? focusPreferencesAdvancedVc
        }
        self.presentAsSheet(focusPreferencesAdvancedVcObj!)
    }
//    @IBAction func colorWellClicked(_ sender: Any) {
//        if tblViewFocusType.selectedRow == -1{
//            return;
//        }
//        var dic = arrFocusType[tblViewFocusType.selectedRow]
//        dic["color"] = getColorString(color: colorWell.color)
//
//        arrFocusType[tblViewFocusType.selectedRow] = dic
//        tblViewFocusType.reloadData(forRowIndexes: IndexSet(arrayLiteral: tblViewFocusType.selectedRow), columnIndexes: IndexSet(arrayLiteral: 0))
//        
//        tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: tblViewFocusType.selectedRow), byExtendingSelection: false)
//        tblViewFocusType.scrollRowToVisible(tblViewFocusType.selectedRow)
//        checkState()
//        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
//    }
}
extension focusPreferencesVc:NSTextFieldDelegate{
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldSelectedFocusType{
                let selectedRow = tblViewFocusType.selectedRow
                let newName = textFieldSelectedFocusType.stringValue.lowercased
                for i in 0..<arrFocusType.count{
                    if i != selectedRow{
                        let dic = arrFocusType[i]
                        if let name = dic["name"] as? String{
                            if name.lowercased() == newName(){
                                let alert = NSAlert()
                                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                                    if state{
                                        alert.window.sharingType = .none
                                    }
                                }
                                alert.messageText = "Focus type with the same name already exist."
                                
                                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                                    if let errorSameFocusType = focusPreferencesInfo.value(forKey: "errorSameFocusType") as? String{
                                        alert.messageText = errorSameFocusType
                                    }
                                }
                                alert.addButton(withTitle: buttonOkText)
                                alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
                                
                                if let name = arrFocusType[tblViewFocusType.selectedRow]["name"] as? String{
                                    textFieldSelectedFocusType.stringValue = name
                                }
                                return;
                            }
                        }
                    }
                }
                
                
                var dic = arrFocusType[selectedRow]
                let oldName = dic["name"] as? String ?? ""
                dic["name"] = textFieldSelectedFocusType.stringValue
                
                
                textFieldSelectedFocusType.isEnabled = false
                
                arrFocusType[selectedRow] = dic
                tblViewFocusType.reloadData(forRowIndexes: IndexSet(arrayLiteral: selectedRow), columnIndexes: IndexSet(arrayLiteral: 0))
                
                tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: false)
                tblViewFocusType.scrollRowToVisible(selectedRow)
                checkState()
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                

                
                
                // if auto pomodoro mode is on and if hardcore pomodoro is also enabled then if user change focus mode name which is selected in hardcore pomodoro focus then hardcore pomodoro focus name should be change here :-
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
                    if state{
                        if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
                            
                            if hardCorePomodoroState{
                                if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                                    if oldName == name{
                                        UserDefaults.standard.set(textFieldSelectedFocusType.stringValue, forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName)
                                    }
                                }
                                
                            }
                            
                        }
                    }
                    
                }
                //
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async { [self] in
                        print("*************************api called*****************")
                        textFieldSelectedFocusType.isEnabled = true
                    }
                })
  
            }
        }
    }
}


extension focusPreferencesVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tblViewFocusType{
            
            return arrFocusType.count
        }else if tableView == tblViewAllowedApps{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = tblViewFocusType.selectedRow
                if row != -1{
                    if let arr = arrFocusType[row]["allowed_apps"] as? [String]{
                        btnRemoveApp.isEnabled = false
                        return arr.count
                    }
                }
                
            }
        }else if tableView == tblViewAllowedUrls{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = tblViewFocusType.selectedRow
                if row != -1{
                    if let arr = arrFocusType[row]["allowed_urls"] as? [String]{
                        btnRemoveUrl.isEnabled = false
                        return arr.count
                    }
                }
                
            }
        }
        return 2
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {

            if tableView == tblViewFocusType{
                if let name = arrFocusType[row]["name"] as? String{
                    cell.lblTitle.stringValue = name
                }else{
                    cell.lblTitle.stringValue = ""
                }
                if let color = arrFocusType[row]["color"] as? String{
                    cell.boxColor.fillColor = HexToColor(hexString: color)
                }else{

                }
                
            }else if tableView == tblViewAllowedApps{
                
                if tblViewFocusType.selectedRow != -1{
                    if let arr = arrFocusType[tblViewFocusType.selectedRow]["allowed_apps"] as? [String]{
                        
                        if row < arr.count{
                            let url = URL(fileURLWithPath: arr[row])
                            cell.lblTitle.stringValue = url.lastPathComponent
                            cell.imgView.image = NSWorkspace.shared.icon(forFile: url.path)
                        }else{
                            cell.lblTitle.stringValue = ""
                            cell.imgView.image = nil
                        }

                    }
                }
            }else if tableView == tblViewAllowedUrls{
                if tblViewFocusType.selectedRow != -1{
                    if let arr = arrFocusType[tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
//                        let url = URL(fileURLWithPath: arr[row])
                        if row < arr.count{
                            cell.lblTitle.stringValue = arr[row]
                            cell.imgView.image = NSImage(named: NSImage.networkName)
                        }else{
                            cell.lblTitle.stringValue = ""
                            cell.imgView.image = nil
                        }
                    }
                }
            }
            return cell
        }
        
        return NSTableCellView()
    }
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {

//    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard let tblview = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tblview.selectedRow
        if tblview == tblViewFocusType
        {
            btnRemoveApp.isEnabled = false
            btnRemoveUrl.isEnabled = false
            tblViewAllowedApps.reloadData()
            tblViewAllowedUrls.reloadData()

            if let isAllowedAllApps = arrFocusType[tblViewFocusType.selectedRow]["isAllowedAllApps"] as? Bool{
                if isAllowedAllApps{
                   radioBtnAllowAllApps.state = .on
                   radioBtnAllowSelectedApps.state = .off
                   tblViewAllowedApps.isEnabled = false
                   tblViewAllowedApps.deselectAll(self)
                   btnAddApp.isEnabled = false
                   btnRemoveApp.isEnabled = false
                }else{
                    radioBtnAllowAllApps.state = .off
                    radioBtnAllowSelectedApps.state = .on
                    tblViewAllowedApps.isEnabled = true
                    btnAddApp.isEnabled = true
                }
            }
            //"isAllowedAllUrls"
            
            if let isAllowedAllUrls = arrFocusType[tblViewFocusType.selectedRow]["isAllowedAllUrls"] as? Bool{
                if isAllowedAllUrls{
                   radioBtnAllowAllUrls.state = .on
                   radioBtnAllowSelectedUrls.state = .off
                   tblViewAllowedUrls.isEnabled = false
                   tblViewAllowedUrls.deselectAll(self)
                   btnAddUrl.isEnabled = false
                   btnRemoveUrl.isEnabled = false
                }else{
                    radioBtnAllowAllUrls.state = .off
                    radioBtnAllowSelectedUrls.state = .on
                    tblViewAllowedUrls.isEnabled = true
                    btnAddUrl.isEnabled = true
                }
            }
            
            if let name = arrFocusType[tblViewFocusType.selectedRow]["name"] as? String{
                textFieldSelectedFocusType.stringValue = name
            }else{
                textFieldSelectedFocusType.stringValue = ""
            }
            if let color = arrFocusType[tblViewFocusType.selectedRow]["color"] as? String{
                colorWell.color = HexToColor(hexString: color)
            }else{

            }
            
            if let isOn = arrFocusType[tblViewFocusType.selectedRow]["isOn"] as? Bool{
               // toggleButton.isOn = isOn
            }else{
               // toggleButton.isOn = false
            }
            
            // default focus modes and meetings focus mode are not allowed to change names but user can change color
            if let state = arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool{//this key will only be awailable in default focus type
                if state{
                    textFieldSelectedFocusType.isEditable = false
                    textFieldSelectedFocusType.isSelectable = false
                    return
                }
            }
            if let state = arrFocusType[tblViewFocusType.selectedRow]["isMeetings"] as? Bool{//this key will only be awailable in Meetings focus type
                if state{
                    textFieldSelectedFocusType.isEditable = false
                    textFieldSelectedFocusType.isSelectable = false
                    return
                }
            }
            
            textFieldSelectedFocusType.isEditable = true
            
        }else if tblview == tblViewAllowedApps{
            if selectedRow == -1{
                btnRemoveApp.isEnabled = false
            }else{
                btnRemoveApp.isEnabled = true
            }
        }else if tblview == tblViewAllowedUrls{
            if selectedRow == -1{
                btnRemoveUrl.isEnabled = false
            }else{
                btnRemoveUrl.isEnabled = true
            }
        }
    }
    
//    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
//        if textFieldSelectedFocusType.isFocused{
//            textFieldSelectedFocusType.window?.makeFirstResponder(nil)
//            return false
//        }else{
//            return true
//        }
//    }

}




