//
//  focusPreferencesViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/02/22.

//

import Cocoa

class focusPreferencesVc: NSViewController, NSMenuDelegate {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var btnBackToCustomBlockingSmall: cursorButton!
    @IBOutlet weak var btnHelp: hoverInfoButton!
    @IBOutlet weak var btnBackToCustomBlocking: NSButton!
    @IBOutlet weak var btnInfoBlockedUrls: hoverInfoButton!
    @IBOutlet weak var heightTblViewApps: NSLayoutConstraint!
    @IBOutlet weak var lblDescriptionAlwaysBlockedUrls: NSTextField!
    @IBOutlet weak var lblTitleBlockApp: NSTextField!
    @IBOutlet weak var bntColorBoxInfo: hoverInfoButton!
    @IBOutlet weak var lblUrlsQuestion: NSTextField!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var btnAdvanced: NSButton!
    @IBOutlet weak var horizontalLineSeprator: NSBox!
    @IBOutlet weak var radioBtnAllowAllApps: NSButton!
    @IBOutlet weak var radioBtnAllowSelectedApps: NSButton!
    
    @IBOutlet weak var radioBtnAllowListApproch: NSButton!
    @IBOutlet weak var radioBtnBlockListApproch: NSButton!
    
    @IBOutlet weak var lblTitleFocusType: NSTextField!
    @IBOutlet weak var boxAllowedWebUrls: NSBox!
    @IBOutlet weak var boxAllowedApps: NSBox!
    @IBOutlet weak var lblNoFocusAdded: NSTextField!
    @IBOutlet weak var boxEmptyFocusType: NSBox!

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
    
    var titleAllowedAllUrls = "Allow all urls"
    var titleAllowedSelectedUrls = "Allow selected urls (works with Safari and Chrome only)"
    
    var titleBlockAllUrls = "Block all urls"
    var titleBlockSelectedUrls = "Block selected urls (works with Safari and Chrome only)"
    
    var allowUrlsQuestionText = "How do you want to allow URLs?"
    var blockUrlsQuestionText = "How do you want to block URLs?"
    
    var toolTipRemove = "Remove"
    var toolTipDuplicate = "Duplicate"
    var toolTipColorBox = "Choose a color to be displayed in the background of the top menu bar icon to help identify the Focus Mode you are running."
    
    let viewWidthDefault = 760
    let viewHeightDefault = 624

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
        addLog(text: "focusPreferencesVc viewdidload start")
        btnBackToCustomBlocking.title = "Back to custom blocking"
        lblTitleBlockApp.stringValue = "Which apps do you want to block?"
        var toolTipAdd = "Add"

        lblUrlsQuestion.stringValue = "How do you want to allow URLs?"
        
        btnAddFocusType.title = "Add Focus Mode"
        btnDuplicateFocusType.title = "Duplicate"
        btnRemoveFocusType.title = "Delete"
        
        radioBtnAllowListApproch.title = "Allow List:"
        radioBtnBlockListApproch.title = "Block List:"
        
        focusPreferencesVcObj = self
        var titleAllowedAllApps = "Allow all apps"
        var titleAllowedSelectedApps = "Allow selected apps"
        var titleFocusType = "Use Focus Modes to stay focused on a certain type of work. Start a focus mode from the Focus Bear menu."
        
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
            
            titleBlockAllUrls = focusPreferencesInfo.value(forKey: "titleBlockedAllUrls") as? String ?? titleBlockAllUrls
            titleBlockSelectedUrls = focusPreferencesInfo.value(forKey: "titleBlockedSelectedUrls") as? String ?? titleBlockSelectedUrls
            radioBtnAllowListApproch.title = focusPreferencesInfo.value(forKey: "titleAllowUrlList") as? String ?? radioBtnAllowListApproch.title
            radioBtnBlockListApproch.title = focusPreferencesInfo.value(forKey: "titleBlockUrlList") as? String ?? radioBtnBlockListApproch.title
            
            allowUrlsQuestionText = focusPreferencesInfo.value(forKey: "allowUrlsQuestionText") as? String ?? allowUrlsQuestionText
            blockUrlsQuestionText = focusPreferencesInfo.value(forKey: "blockUrlsQuestionText") as? String ?? blockUrlsQuestionText
            lblTitleBlockApp.stringValue = focusPreferencesInfo.value(forKey: "titleBlockedApps") as? String ?? lblTitleBlockApp.stringValue
            btnBackToCustomBlocking.title = focusPreferencesInfo.value(forKey: "buttonBackToCustomBlocking") as? String ?? btnBackToCustomBlocking.stringValue
        }
        lblTitleFocusType.stringValue = titleFocusType
        radioBtnAllowAllApps.title = titleAllowedAllApps
        radioBtnAllowSelectedApps.title = titleAllowedSelectedApps
        
        
        lblUrlsQuestion.stringValue = allowUrlsQuestionText
        btnDuplicateFocusType.title = toolTipDuplicate
        
        btnDuplicateFocusType.toolTip = toolTipDuplicate
        btnAddFocusType.toolTip = toolTipAdd
        btnRemoveFocusType.toolTip = toolTipRemove
        btnAddApp.toolTip = toolTipAdd
        btnRemoveApp.toolTip = toolTipRemove
        btnAddUrl.toolTip = toolTipAdd
        btnRemoveUrl.toolTip = toolTipRemove
        
        
        lblNoFocusAdded.stringValue = noFocusAddedText

        tblViewAllowedUrls.doubleAction = #selector(tableRowAllowedUrlsDoubleClicked)
        
        let menu = NSMenu()
        menu.delegate = self
        tblViewFocusType.menu = menu
        
        textFieldSelectedFocusType.delegate = self

        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            toolTipColorBox = common.value(forKey: "toolTipColorBoxText") as? String ?? toolTipColorBox
        }
        
        if #available(macOS 11.0, *) {
            btnAddApp.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnAddUrl.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveApp.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
            btnRemoveUrl.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
        
        arrForSearchFromSettings.append(["title": btnAddFocusType.title, "tabId": idFocus, "object": btnAddFocusType as Any])
        arrForSearchFromSettings.append(["title": radioBtnAllowAllApps.title, "tabId": idFocus, "object": radioBtnAllowAllApps as Any])
        arrForSearchFromSettings.append(["title": radioBtnAllowSelectedApps.title, "tabId": idFocus, "object": radioBtnAllowSelectedApps as Any])
        
        arrForSearchFromSettings.append(["title": radioBtnAllowListApproch.title, "tabId": idFocus, "object": radioBtnAllowListApproch as Any])
        arrForSearchFromSettings.append(["title": radioBtnBlockListApproch.title, "tabId": idFocus, "object": radioBtnBlockListApproch as Any])
        
        
        if focusPreferencesAdvancedVcObj == nil{
            focusPreferencesAdvancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesAdvancedVc")) as? focusPreferencesAdvancedVc
            focusPreferencesAdvancedVcObj?.loadView()
        }

        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            if let runScriptBeforeText = focusPreferencesAdvancedInfo.value(forKey: "runScriptBeforeText") as? String {
                arrForSearchFromSettings.append(["title": runScriptBeforeText, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
                
            }
            if let runScriptAfterText = focusPreferencesAdvancedInfo.value(forKey: "runScriptAfterText") as? String{
                arrForSearchFromSettings.append(["title": runScriptAfterText, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
            }

            
            if let title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandBeforeText") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
            }
            if let title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandAfterText") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
            }
            if let title = focusPreferencesAdvancedInfo.value(forKey: "focusAlignmentScoreTitle") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
            }

            arrForSearchFromSettings.append(["title": focusPreferencesAdvancedVcObj?.checkBoxAutoDoNotDisturb.title ?? "", "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.checkBoxAutoDoNotDisturb as Any])
        }
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let title = focusPreferencesInfo.value(forKey: "titleTags") as? String {
                arrForSearchFromSettings.append(["title": title, "tabId": "focusAdvanced", "object": focusPreferencesAdvancedVcObj?.bgBox as Any])
            }
        }
        
        boxAllowedApps.wantsLayer = true
        boxAllowedApps.layer?.cornerRadius = 5
        
        boxAllowedWebUrls.wantsLayer = true
        boxAllowedWebUrls.layer?.cornerRadius = 5
        addLog(text: "focusPreferencesVc viewdidload end")
    }

    override func viewDidLayout() {// after scrollview resize it removes title and not srawing it again so doing this here 
        btnAdvanced.title = btnAdvanced.title
        btnAddFocusType.title = btnAddFocusType.title
    }

    
    func selectFocusModeWithId(id:String){
        for i in 0..<arrFocusType.count{
            let focusMode = arrFocusType[i]
            if focusMode["id"] as? String == id{
                if i != arrFocusType.count - 1{
                    tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: i), byExtendingSelection: false)
                    tblViewFocusType.scrollRowToVisible(i)
                }
                break;
            }
        }
    }
    
    @IBAction func bntColorBoxInfoClicked(_ sender: Any) {
        addLog(text: "[user-action] bntColorBoxInfoClicked")
        showTooltip(sender: bntColorBoxInfo, msg: toolTipColorBox, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
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
    }
    @objc func colorDidChange(){
        if tblViewFocusType.selectedRow == -1{
            return;
        }
        colorWell.color = cp.color
        var focusMode = arrFocusType[tblViewFocusType.selectedRow]
        focusMode["color"] = getColorString(color: colorWell.color)
        arrFocusType[tblViewFocusType.selectedRow] = focusMode
        tblViewFocusType.reloadData(forRowIndexes: IndexSet(arrayLiteral: tblViewFocusType.selectedRow), columnIndexes: IndexSet(arrayLiteral: 0))
        
        tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: tblViewFocusType.selectedRow), byExtendingSelection: false)
        tblViewFocusType.scrollRowToVisible(tblViewFocusType.selectedRow)
        checkState()
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.capturePosthog(event: "edit-focus-mode-colour", metadata: [:])
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
        if (item["isLockedFocus"] as? Bool) != nil{
            item.removeValue(forKey: "isLockedFocus")
        }
        if (item["isRelaxFocus"] as? Bool) != nil{
            item.removeValue(forKey: "isRelaxFocus")
        }
        if (item["isDeepWorkFocus"] as? Bool) != nil{
            item.removeValue(forKey: "isDeepWorkFocus")
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
        item["isPaused"] = false
        item.removeValue(forKey: "id")
        let idFocusMode = getUuid()
        item["id"] = idFocusMode
        var newRow = 0
        if !isDefault{//if default than duplicate will second last //tod test
            newRow = row + 1
        }else{
            newRow = row
        }
        arrFocusType.insert(item, at: newRow)
        sortFocusModes()
        tblViewFocusType.reloadData()
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String == idFocusMode{
                tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: i), byExtendingSelection: false)
                tblViewFocusType.scrollRowToVisible(i)
                break;
            }
        }

        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        allApiObject.addFocusMode(focusType: item)
        allApiObject.capturePosthog(event: "duplicate-focus-mode", metadata: [:])
        resetPomodoroVcFocusListIfNeeded()
        
    }
    @objc func duplicateFocusClicked(){
        makeDuplicateFocus(row: tblViewFocusType.selectedRow)
    }
    @IBAction func btnDuplicateFocusTypeClicked(_ sender: Any) {
        makeDuplicateFocus(row: tblViewFocusType.selectedRow)
    }

    
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
    
    
    override func viewWillAppear() {
        focusPreferencesAdvancedVcObj?.arrAllTags.removeAll()
        for tagInfo in arrAllFocusModeTags{
            focusPreferencesAdvancedVcObj?.arrAllTags.append(tagInfo["text"] ?? "")
        }
        //preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: viewWidthDefault, height: viewHeightDefault)) 
        reloadData()
        if Reachability.isConnectedToNetwork() == false {
            
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    if !isInternetOn{
                        if self.view.window != nil{
                            showAlertNoInternet(window: self.view.window!)
                        }
                    }
                }
            })
            
        }
        
        
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            btnAddFocusType.title = "Add Block List"
            lblTitleFocusType.stringValue = "Use Block Lists to stay focused on a certain type of work."
            
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                btnAddFocusType.title = focusPreferencesInfo.value(forKey: "buttonAddBlockListText") as? String ?? btnAddFocusType.title
                lblTitleFocusType.stringValue = focusPreferencesInfo.value(forKey: "titleBlockList") as? String ?? lblTitleFocusType.stringValue
            }
            btnHelp.isHidden = true
            btnBackToCustomBlockingSmall.isHidden = false
        }else{
            btnAddFocusType.title = "Add Focus Mode"
            lblTitleFocusType.stringValue = "Use Focus Modes to stay focused on a certain type of work. Start a focus mode from the Focus Bear menu."
            
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                btnAddFocusType.title = focusPreferencesInfo.value(forKey: "buttonAddFocusTypeText") as? String ?? btnAddFocusType.title
                lblTitleFocusType.stringValue = focusPreferencesInfo.value(forKey: "titleFocusType") as? String ?? lblTitleFocusType.stringValue
            }
            btnHelp.isHidden = false
            btnBackToCustomBlockingSmall.isHidden = true
        }
        scrollView.scrollToTop()
    }
    
    override func viewDidAppear() {
        scrollView.scrollToTop()
    }
    
    override func viewWillDisappear() {
        focusPreferencesAdvancedVcObj?.arrAllTags.removeAll()
        updateAllFocusModes()
        btnBackToCustomBlocking.isHidden = true
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
            
            tblViewAllowedApps.reloadData()
            tblViewAllowedUrls.reloadData()
        }
    }
    
    @IBAction func radioBtnAllowAllAppsClicked(_ sender: Any) {
        radioBtnAllowAllApps.state = .on
        radioBtnAllowSelectedApps.state = .off
        tblViewAllowedApps.isEnabled = false
        tblViewAllowedApps.isHidden = true
        boxAllowedApps.alphaValue = 0
        tblViewAllowedApps.deselectAll(self)
        btnAddApp.isEnabled = false
        btnRemoveApp.isEnabled = false
        btnAddApp.isHidden = true
        btnRemoveApp.isHidden = true
        
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllApps"] = true
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }

        reSetCurrentFocusMode(focusType:arrFocusType[selectedRow])
        allApiObject.capturePosthog(event: "allowed-all-apps-in-focus-mode", metadata: [:])//#490
    }
    @IBAction func radioBtnAllowSelectedAppsClicked(_ sender: Any) {
        radioBtnAllowAllApps.state = .off
        radioBtnAllowSelectedApps.state = .on
        tblViewAllowedApps.isEnabled = true
        tblViewAllowedApps.isHidden = false
        //        boxAllowedApps.isHidden = false
        boxAllowedApps.alphaValue = 1
        btnAddApp.isEnabled = true
        btnRemoveApp.isEnabled = true
        
        btnAddApp.isHidden = false
        btnRemoveApp.isHidden = false
        tblViewAllowedApps.reloadData()
        
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedAllApps"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }

        reSetCurrentFocusMode(focusType:arrFocusType[selectedRow])
        allApiObject.capturePosthog(event: "allowed-selected-apps-in-focus-mode", metadata: [:])//#490
    }


    
  
    @objc func tableRowAllowedUrlsDoubleClicked(){
        let selectedTow = tblViewAllowedUrls.selectedRow
        if selectedTow == -1{
            return;
        }
        if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
            addWebUrlVcObj!.currenUrlAddingtState = ._ALL_BLOCK_URL
        }else{
            if radioBtnAllowListApproch.state == .on{
                addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_ALLOW_URL
            }else{
                addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
            }
        }
        
        addWebUrlVcObj!.isAdding = false
        self.presentAsSheet(addWebUrlVcObj!)
    }
    
    
    
    @IBAction func btnAddFocusTypeClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
            showSetFocusWindow()
            return;
        }
            
        self.presentAsSheet(addFocusTypeVcObj!)
    }
    
    func checkState(){
        boxEmptyFocusType.isHidden = true
    }
    
    @objc func removeFocusClicked(){
        btnRemoveFocusTypeClicked(self)
    }
    
    @IBAction func btnRemoveFocusTypeClicked(_ sender: Any) {
        if isHardCorePomodoroModeOn{
            let alert = NSAlert()
            alert.setSharingType()
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
        if arrFocusType[selectedRow]["isDefault"] as? Bool == true || arrFocusType[selectedRow]["isMeetings"] as? Bool == true || arrFocusType[selectedRow]["isLockedFocus"] as? Bool == true{//this key will only be awailable in default focus type
            
            let alertFocusModeDefault = NSAlert()
            alertFocusModeDefault.setSharingType()
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
        
        
        
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                if let hardCorePomodoroState = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
                    
                    if hardCorePomodoroState{
                        if let name = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroFocusedName) as? String{
                            if arrFocusType[selectedRow]["name"] as? String == name{
                                //                                UserDefaults.standard.set(textFieldSelectedFocusType.stringValue, forKey: kUserdefaultsHardcorePomodoroFocusedName)
                                
                                //The selected focus mode is enabled in hardcore pomodoro mode. please disable hardcore pomodoro mode to delete this.
                                let alert = NSAlert()
                                alert.setSharingType()
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
        
        let id = arrFocusType[selectedRow]["id"] as? String ?? ""
        for i in 0..<customBlockingScheduleManagerObj.arrBlockingSchedule.count{
            let schedule = customBlockingScheduleManagerObj.arrBlockingSchedule[i]
            if schedule.focusModeID == id{
                let alert = NSAlert()
                alert.setSharingType()
                var alertScheduleUsingFocusMode = "You can’t delete this focus mode because it’s currently assigned to the blocking schedule \"<SCHEDULE>\". Please edit that schedule first and choose a different focus mode."
                var buttonEditBlockingSchedule = "Edit blocking schedule"
                
                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                    alertScheduleUsingFocusMode = focusPreferencesInfo.value(forKey: "alertScheduleUsingFocusMode") as? String ?? alertScheduleUsingFocusMode
                    buttonEditBlockingSchedule = focusPreferencesInfo.value(forKey: "buttonEditBlockingSchedule") as? String ?? buttonEditBlockingSchedule
                }
                
                alert.messageText = alertScheduleUsingFocusMode.replacingOccurrences(of: "<SCHEDULE>", with: schedule.name)
                alert.addButton(withTitle: buttonEditBlockingSchedule)
                alert.addButton(withTitle: buttonCancelText)
                
                alert.beginSheetModal(for: self.view.window!){ result in
                    if result == .alertFirstButtonReturn{
                        //without password bacuse settngs is alreday opened
                        leftMenuVcObj?.boxBlocks.isSelected = true
                        mainViewControllerObj?.showBlocksPreferencesView()
                        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
                        tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: i, shouldCreateNew: false)
                    }
                }
                return;
            }
        }
        
        
        
        if arrFocusType[selectedRow]["isOn"] as? Bool == true || arrFocusType[selectedRow]["isPaused"] as? Bool == true{
            let alertFocusModeOn = NSAlert()
            alertFocusModeOn.setSharingType()
            
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
        alert.setSharingType()
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

                    allApiObject.deleteFocusMode(id: id, completionHandler: {isDeleted in
                        
                        DispatchQueue.main.async {
                            if isDeleted{
                                
                            }else{
                                
                            }
                            
                        }
                        
                    })
                    allApiObject.capturePosthog(event: "delete-focus-mode", metadata: [:])
                    
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
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                //                if var arr =
                
                return
            }
            let urls = openPanel.urls
            
            
            if self.tblViewFocusType.selectedRow != -1{
                var appsArray = [String]()
                var appsUrlArray = [URL]()
                if arrFocusType[self.tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                    if let arr = arrFocusType[self.tblViewFocusType.selectedRow]["blocked_apps"] as? [String]{
                        appsArray = arr
                    }
                }else{
                    if let arr = arrFocusType[self.tblViewFocusType.selectedRow]["allowed_apps"] as? [String]{
                        appsArray = arr
                    }
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
                
                if arrFocusType[self.tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                    arrFocusType[self.tblViewFocusType.selectedRow]["blocked_apps"] = appsArray
                }else{
                    arrFocusType[self.tblViewFocusType.selectedRow]["allowed_apps"] = appsArray
                }
                
                self.tblViewAllowedApps.reloadData()
                self.tblViewAllowedApps.selectRowIndexes(IndexSet(arrayLiteral: (appsArray.count - 1)), byExtendingSelection: false)
                self.tblViewAllowedApps.scrollRowToVisible(appsArray.count - 1)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                reSetCurrentFocusMode(focusType:arrFocusType[self.tblViewFocusType.selectedRow])
                if isContainAlready{
                    self.showAlertAppAlreadyAdded()
                }
                allApiObject.capturePosthog(event: "add-allowed-app-in-focus-mode", metadata: [:])
            }
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
            
            if arrFocusType[self.tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                if var arr = arrFocusType[selectedFocusTypeRow]["blocked_apps"] as? [String]{
                    if arr.count > selectedAppsRow{
                        arr.remove(at: selectedAppsRow)
                    }
                    arrFocusType[selectedFocusTypeRow]["blocked_apps"] = arr
                }
            }else{
                if var arr = arrFocusType[selectedFocusTypeRow]["allowed_apps"] as? [String]{
                    if arr.count > selectedAppsRow{
                        arr.remove(at: selectedAppsRow)
                    }
                    arrFocusType[selectedFocusTypeRow]["allowed_apps"] = arr
                }
            }
            
            self.tblViewAllowedApps.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        reSetCurrentFocusMode(focusType:arrFocusType[selectedFocusTypeRow])
        allApiObject.capturePosthog(event: "remove-allowed-app-in-focus-mode", metadata: [:])//#490
    }
    @IBAction func btnAddUrlClicked(_ sender: Any) {
        
        if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
            addWebUrlVcObj!.currenUrlAddingtState = ._ALL_BLOCK_URL
        }else{
            if radioBtnAllowListApproch.state == .on{
                addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_ALLOW_URL
            }else{
                addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
            }
        }
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
        if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
            if selectedUrlsRow < SettingsManagerObject.arrBlockedUrls.count{
                SettingsManagerObject.arrBlockedUrls.remove(at: selectedUrlsRow)
                tblViewAllowedUrls.reloadData()
                UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
            }
            SettingsManagerObject.isSettingsChanged = true
            UserDefaults.standard.set(true, forKey: kUserdefaultsEditBlockedUrlsOnce)
            allApiObject.capturePosthog(event: "remove-always-blocked-url", metadata: [:])//#490
        }else{
            if arrFocusType.count > selectedFocusTypeRow{
                if radioBtnAllowListApproch.state == .on{
                    if var allowed_urls = arrFocusType[selectedFocusTypeRow]["allowed_urls"] as? [String]{
                        if allowed_urls.count > selectedUrlsRow{
                            allowed_urls.remove(at: selectedUrlsRow)
                        }
                        arrFocusType[selectedFocusTypeRow]["allowed_urls"] = allowed_urls
                        allApiObject.capturePosthog(event: "remove-allowed-url-in-focus-mode", metadata: [:])//#490
                    }
                }else{
                    if var blockUrlsArray = arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] as? [String]{
                        if blockUrlsArray.count > selectedUrlsRow{
                            blockUrlsArray.remove(at: selectedUrlsRow)
                        }
                        arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] = blockUrlsArray
                        allApiObject.capturePosthog(event: "remove-blocked-url-in-focus-mode", metadata: [:])//#490
                    }
                }
                
                self.tblViewAllowedUrls.reloadData()
            }
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            reSetCurrentFocusMode(focusType:arrFocusType[selectedFocusTypeRow])
        }

    }
    
    @IBAction func btnAdvancedClicked(_ sender: Any) {
        if focusPreferencesAdvancedVcObj == nil{
            focusPreferencesAdvancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesAdvancedVc")) as? focusPreferencesAdvancedVc
        }
        self.presentAsSheet(focusPreferencesAdvancedVcObj!)
        
        if let tags = arrFocusType[tblViewFocusType.selectedRow]["tags"] as? [String]{
            focusPreferencesAdvancedVcObj!.tokenField.objectValue = tags
        }else{
            focusPreferencesAdvancedVcObj!.tokenField.objectValue = []
        }
        
        if let isAutoDoNotDisturbEnabled = arrFocusType[tblViewFocusType.selectedRow]["isAutoDoNotDisturbEnabled"] as? Bool{
            if isAutoDoNotDisturbEnabled{
                focusPreferencesAdvancedVcObj!.checkBoxAutoDoNotDisturb.state = .on
            }else{
                focusPreferencesAdvancedVcObj!.checkBoxAutoDoNotDisturb.state = .off
            }
        }else{
            focusPreferencesAdvancedVcObj!.checkBoxAutoDoNotDisturb.state = .off
        }
        allApiObject.capturePosthog(event: "open-advanced-focus-mode-preferences", metadata: [:])
    }
    
    
    @IBAction func radioBtnAllowListApprochClicked(_ sender: Any) {
        radioBtnBlockListApproch.state = .off
        lblUrlsQuestion.stringValue = allowUrlsQuestionText
        
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedListApproach"] = true
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }
        reSetCurrentFocusMode(focusType:arrFocusType[selectedRow])

        tblViewAllowedUrls.isEnabled = true
        tblViewAllowedUrls.isHidden = false
        btnAddUrl.isEnabled = true
        btnRemoveUrl.isEnabled = true
        btnAddUrl.isHidden = false
        btnRemoveUrl.isHidden = false
        tblViewAllowedUrls.reloadData()
        allApiObject.capturePosthog(event: "urls-allow-list-approach-in-focus-mode", metadata: [:])//#490
    }
    
    @IBAction func btnHelpClicked(_ sender: Any) {
        if popoverFocusHelp == nil{
            popoverFocusHelp = NSPopover()
            popoverFocusHelp!.behavior = .transient
            popoverFocusHelp!.animates = false
        }
        if popoverFocusHelp!.isShown{
            popoverFocusHelp?.close()
        }
        let vc = getFocusStartHelpImgVcObject()
        popoverFocusHelp!.contentViewController = vc
        popoverFocusHelp!.contentSize = vc.view.frame.size
        popoverFocusHelp!.show(relativeTo: (sender as! NSButton).bounds, of: sender as! NSButton, preferredEdge: NSRectEdge.minY)
    }
    
    @IBAction func radioBtnBlockListApprochClicked(_ sender: Any) {
        radioBtnAllowListApproch.state = .off

        lblUrlsQuestion.stringValue = blockUrlsQuestionText
        let selectedRow = tblViewFocusType.selectedRow
        if selectedRow != -1{
            arrFocusType[selectedRow]["isAllowedListApproach"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        }
        reSetCurrentFocusMode(focusType:arrFocusType[selectedRow])
        
        tblViewAllowedUrls.isEnabled = true
        tblViewAllowedUrls.isHidden = false
        btnAddUrl.isEnabled = true
        btnRemoveUrl.isEnabled = true
        btnAddUrl.isHidden = false
        btnRemoveUrl.isHidden = false
        tblViewAllowedUrls.reloadData()
        allApiObject.capturePosthog(event: "urls-block-list-approach-in-focus-mode", metadata: [:])//#490
    }

    @objc func btnInfoClicked(sender:NSButton){
        
        var meetingsFocusInfoText = "Meetings focus mode helps restricit use of certain apps when you are attending a meeting. It can block everything else to help you concentrate."
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            meetingsFocusInfoText = focusPreferencesInfo.value(forKey: "meetingsFocusInfoText") as? String ?? meetingsFocusInfoText
        }
        
        showTooltip(sender: sender, msg: meetingsFocusInfoText, preferredEdge: .minY, maxWidthVal:230)
    }
    
        
    @IBAction func tokenFieldClicked(_ sender: Any) {
        print("tokrn field clicked")
    }
    
    @IBAction func btnInfoBlockedUrlsClicked(_ sender: Any) {
        var msg = "Super distracting sites are automatically blocked"
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            msg = focusPreferencesInfo.value(forKey: "infoAlwaysBlockedUrlsText") as? String ?? msg
        }
        
        showTooltip(sender: btnInfoBlockedUrls, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnBackToCustomBlockingClicked(_ sender: Any) {
        self.dismiss(self)
        blockingScheduleEditorVCObj?.reloadFocusModeList()
    }
}

extension focusPreferencesVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tblViewFocusType{
            // locked in current focus should not be visible in focus prefrences //486 - Remove Locked Focus
            return arrFocusType.count - 1
        }else if tableView == tblViewAllowedApps{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = tblViewFocusType.selectedRow
                if row != -1{
                    let isRelaxFocus = arrFocusType[row]["isRelaxFocus"] as? Bool ?? false
                    if isRelaxFocus{
                        btnRemoveApp.isEnabled = false
                        return 0
                    }
                    
                    if arrFocusType[row]["isDefault"] as? Bool == true {
                        if let arr = arrFocusType[row]["blocked_apps"] as? [String]{
                            btnRemoveApp.isEnabled = false
                            return arr.count
                        }else{
                            btnRemoveApp.isEnabled = false
                            return 0
                        }
                    }else{
                        if let arr = arrFocusType[row]["allowed_apps"] as? [String]{
                            btnRemoveApp.isEnabled = false
                            return arr.count
                        }else{
                            btnRemoveApp.isEnabled = false
                            return 0
                        }
                    }
                }
                
            }
        }else if tableView == tblViewAllowedUrls{
            if arrFocusType.count == 0{
                return 0
            }else {
                let row = tblViewFocusType.selectedRow
                if row != -1{
                    let isRelaxFocus = arrFocusType[row]["isRelaxFocus"] as? Bool ?? false
                    if isRelaxFocus{
                        btnRemoveApp.isEnabled = false
                        return 0
                    }
                    if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                        btnRemoveUrl.isEnabled = false
                        return SettingsManagerObject.arrBlockedUrls.count
                    }else{
                        if let isAllowedListApproach = arrFocusType[tblViewFocusType.selectedRow]["isAllowedListApproach"] as? Bool{
                            if isAllowedListApproach{
                                if let allowed_urls = arrFocusType[row]["allowed_urls"] as? [String]{
                                    btnRemoveUrl.isEnabled = false
                                    return allowed_urls.count
                                }
                            }else{
                                if let blockUrlsArray = arrFocusType[row]["blockUrlsArray"] as? [String]{
                                    btnRemoveUrl.isEnabled = false
                                    return blockUrlsArray.count
                                }else{
                                    btnRemoveUrl.isEnabled = false
                                    return 0
                                }
                            }
                        }
                    }
                    
                    
                }
                
            }
        }
        return 0
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            
            if tableView == tblViewFocusType{
                cell.stackViewButtons.isHidden = true
                cell.btnRemove.toolTip = toolTipRemove
                cell.btnDuplicate.toolTip = toolTipDuplicate
                
                cell.btnRemove.target = self
                cell.btnRemove.action = #selector(removeFocusClicked)

                cell.btnDuplicate.target = self
                cell.btnDuplicate.action = #selector(duplicateFocusClicked)
                
                if arrFocusType[row]["isDefault"] as? Bool == true || arrFocusType[row]["isMeetings"] as? Bool == true || arrFocusType[row]["isLockedFocus"] as? Bool == true || arrFocusType[row]["isRelaxFocus"] as? Bool == true || arrFocusType[row]["isDeepWorkFocus"] as? Bool == true{
                    cell.btnRemove.isHidden = true
                }else{
                    cell.btnRemove.isHidden = false
                }
                if arrFocusType[row]["isDefault"] as? Bool == true{
                    cell.btnDuplicate.isHidden = true
                }else{
                    cell.btnDuplicate.isHidden = false
                }
                
                if let name = arrFocusType[row]["name"] as? String{
                    cell.lblTitle.stringValue = name
                }else{
                    cell.lblTitle.stringValue = ""
                }
                if let color = arrFocusType[row]["color"] as? String{
                    cell.boxColor.fillColor = HexToColor(hexString: color)
                }else{
                    
                }
                
                if arrFocusType[row]["isMeetings"] as? Bool == true{
                    cell.btnInfo.isHidden = false
                }else{
                    cell.btnInfo.isHidden = true
                }
                cell.btnInfo.target = self
                cell.btnInfo.action = #selector(btnInfoClicked(sender:))
            }else if tableView == tblViewAllowedApps{
                
                if tblViewFocusType.selectedRow != -1{
                    
                    if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                        if let arr = arrFocusType[tblViewFocusType.selectedRow]["blocked_apps"] as? [String]{
                            if row < arr.count{
                                let url = URL(fileURLWithPath: arr[row])
                                cell.lblTitle.stringValue = url.lastPathComponent
                                cell.imgView.image = NSWorkspace.shared.icon(forFile: url.path)
                            }else{
                                cell.lblTitle.stringValue = ""
                                cell.imgView.image = nil
                            }
                        }
                    }else{
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
                }
            }else if tableView == tblViewAllowedUrls{
                if tblViewFocusType.selectedRow != -1{
                    
                    var urlsArr = [String]()
                    if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                        urlsArr = SettingsManagerObject.arrBlockedUrls
                    }else{
                        
                        if let isAllowedListApproach = arrFocusType[tblViewFocusType.selectedRow]["isAllowedListApproach"] as? Bool{
                            if isAllowedListApproach{
                                if let allowed_urls = arrFocusType[tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
                                    urlsArr = allowed_urls
                                }
                            }else{
                                if let blockUrlsArray = arrFocusType[tblViewFocusType.selectedRow]["blockUrlsArray"] as? [String]{
                                    urlsArr = blockUrlsArray
                                }
                            }
                        }
                    }
                    if row < urlsArr.count{
                        cell.lblTitle.stringValue = urlsArr[row]
                        cell.imgView.image = NSImage(named: NSImage.networkName)
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
    //    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    
    //    }
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let customView = TableRowViewResult()
        
        return customView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard let tblview = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tblview.selectedRow
        if tblview == tblViewFocusType{
            
            let isRelaxFocus = arrFocusType[selectedRow]["isRelaxFocus"] as? Bool ?? false
            
            for row in 0..<tblViewFocusType.numberOfRows{
                if row == selectedRow{
                    if let cell = tblViewFocusType.view(atColumn: 0, row: selectedRow, makeIfNecessary: true) as? tblCellFocusPreferences{
                        cell.stackViewButtons.isHidden = false
                    }
                }else{
                    if let cell = tblViewFocusType.view(atColumn: 0, row: row, makeIfNecessary: true) as? tblCellFocusPreferences{
                        cell.stackViewButtons.isHidden = true
                    }
                }
            }
            
            btnRemoveApp.isEnabled = false
            btnRemoveUrl.isEnabled = false
            
            boxAllowedWebUrls.alphaValue = 1
            tblViewAllowedUrls.isEnabled = true
            tblViewAllowedUrls.isHidden = false
            
            if isRelaxFocus{
                radioBtnAllowAllApps.isHidden = false
                radioBtnAllowSelectedApps.isHidden = true
                lblTitleBlockApp.isHidden = true
                heightTblViewApps.constant = 185
                tblViewAllowedApps.isEnabled = false
                tblViewAllowedApps.isHidden = true
                boxAllowedApps.alphaValue = 0
                btnAddApp.isEnabled = false
                btnRemoveApp.isEnabled = false
                btnAddApp.isHidden = false
                btnRemoveApp.isHidden = false
                
                tblViewAllowedApps.reloadData()
                
            }else if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                radioBtnAllowAllApps.isHidden = true
                radioBtnAllowSelectedApps.isHidden = true
                lblTitleBlockApp.isHidden = false
                heightTblViewApps.constant = 140
                tblViewAllowedApps.isEnabled = true
                tblViewAllowedApps.isHidden = false
                boxAllowedApps.alphaValue = 1
                btnAddApp.isEnabled = true
                btnRemoveApp.isEnabled = true
                btnAddApp.isHidden = false
                btnRemoveApp.isHidden = false
                
                if arrFocusType[tblViewFocusType.selectedRow]["blocked_apps"]  == nil{
                    arrFocusType[tblViewFocusType.selectedRow]["blocked_apps"] = []
                }
                arrFocusType[tblViewFocusType.selectedRow]["allowed_apps"] = []
                tblViewAllowedApps.reloadData()
            }else{
                radioBtnAllowAllApps.isHidden = false
                radioBtnAllowSelectedApps.isHidden = false
                lblTitleBlockApp.isHidden = true
                heightTblViewApps.constant = 130
                if let isAllowedAllApps = arrFocusType[tblViewFocusType.selectedRow]["isAllowedAllApps"] as? Bool{
                    if isAllowedAllApps{
                        radioBtnAllowAllApps.state = .on
                        radioBtnAllowSelectedApps.state = .off
                        tblViewAllowedApps.isEnabled = false
                        tblViewAllowedApps.isHidden = true
                        boxAllowedApps.alphaValue = 0
                        tblViewAllowedApps.deselectAll(self)
                        btnAddApp.isEnabled = false
                        btnRemoveApp.isEnabled = false
                        btnAddApp.isHidden = true
                        btnRemoveApp.isHidden = true
                    }else{
                        radioBtnAllowAllApps.state = .off
                        radioBtnAllowSelectedApps.state = .on
                        tblViewAllowedApps.isEnabled = true
                        tblViewAllowedApps.isHidden = false
                        boxAllowedApps.alphaValue = 1
                        btnAddApp.isEnabled = true
                        btnRemoveApp.isEnabled = true
                        btnAddApp.isHidden = false
                        btnRemoveApp.isHidden = false
                    }
                }
                
                tblViewAllowedApps.reloadData()
                
            }
            if isRelaxFocus{
                radioBtnAllowListApproch.isHidden = true
                radioBtnBlockListApproch.isHidden = true
                btnInfoBlockedUrls.isHidden = true
                lblDescriptionAlwaysBlockedUrls.isHidden = true
                lblUrlsQuestion.stringValue = "All websites are allowed"
                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                    lblUrlsQuestion.stringValue = focusPreferencesInfo.value(forKey: "allWebsitesAllowedText") as? String ?? lblUrlsQuestion.stringValue
                }
                boxAllowedWebUrls.alphaValue = 0
                tblViewAllowedUrls.isEnabled = false
                tblViewAllowedUrls.isHidden = true
                tblViewAllowedUrls.reloadData()
                radioBtnAllowAllApps.state = .on
                radioBtnAllowSelectedApps.state = .off
            } else if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true {
                radioBtnAllowListApproch.isHidden = true
                radioBtnBlockListApproch.isHidden = true
                btnInfoBlockedUrls.isHidden = true
                lblDescriptionAlwaysBlockedUrls.isHidden = false
                lblDescriptionAlwaysBlockedUrls.stringValue = "Below is the list of Always Blocked URLs:"
                
                lblUrlsQuestion.stringValue = "When you use this focus mode, all websites will be allowed except for your Always Blocked URLs"
                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                    lblUrlsQuestion.stringValue = focusPreferencesInfo.value(forKey: "descriptionAlwaysBlockedUrls") as? String ?? lblUrlsQuestion.stringValue
                    lblDescriptionAlwaysBlockedUrls.stringValue = focusPreferencesInfo.value(forKey: "titleBlockedUrls") as? String ?? lblDescriptionAlwaysBlockedUrls.stringValue
                }
                
                if leftMenuVcObj?.boxBlocks.isSelected ?? false{
                    lblUrlsQuestion.stringValue = "When you use this block list, all websites will be allowed except for your Always Blocked URLs"
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        lblUrlsQuestion.stringValue = focusPreferencesInfo.value(forKey: "descriptionForCustomBlocking") as? String ?? lblUrlsQuestion.stringValue
                    }
                }
                
                
                tblViewAllowedUrls.reloadData()
                
            }else{
                radioBtnAllowListApproch.isHidden = false
                radioBtnBlockListApproch.isHidden = false
                btnInfoBlockedUrls.isHidden = false
                lblDescriptionAlwaysBlockedUrls.isHidden = true
                
                if let isAllowedListApproach = arrFocusType[tblViewFocusType.selectedRow]["isAllowedListApproach"] as? Bool{
                    if isAllowedListApproach{
                        radioBtnAllowListApproch.state = .on
                        radioBtnBlockListApproch.state = .off
                        
                        lblUrlsQuestion.stringValue = allowUrlsQuestionText
                        
                        tblViewAllowedUrls.isEnabled = true
                        tblViewAllowedUrls.isHidden = false
                        btnAddUrl.isEnabled = true
                        btnRemoveUrl.isEnabled = true
                        btnAddUrl.isHidden = false
                        btnRemoveUrl.isHidden = false
                        
                    }else{
                        
                        radioBtnAllowListApproch.state = .off
                        radioBtnBlockListApproch.state = .on
                        
                        lblUrlsQuestion.stringValue = blockUrlsQuestionText
                        
                        tblViewAllowedUrls.isEnabled = true
                        tblViewAllowedUrls.isHidden = false
                        btnAddUrl.isEnabled = true
                        btnRemoveUrl.isEnabled = true
                        btnAddUrl.isHidden = false
                        btnRemoveUrl.isHidden = false
                        
                    }
                }
                tblViewAllowedUrls.reloadData()
                
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
            
            
            // default focus modes and meetings focus mode are not allowed to change names but user can change color
            if arrFocusType[tblViewFocusType.selectedRow]["isDefault"] as? Bool == true || arrFocusType[tblViewFocusType.selectedRow]["isMeetings"] as? Bool == true || arrFocusType[tblViewFocusType.selectedRow]["isLockedFocus"] as? Bool == true || arrFocusType[tblViewFocusType.selectedRow]["isDeepWorkFocus"] as? Bool == true || isRelaxFocus{//this key will only be awailable in default focus type
                
                textFieldSelectedFocusType.isEditable = false
                textFieldSelectedFocusType.isSelectable = false
                return
                
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
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
}

var tblSelectionColor:NSColor = NSColor(red: 233/255, green: 144/255, blue: 44/255, alpha: 1)
class TableRowViewResult: NSTableRowView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.layer?.cornerRadius = 5
        if isSelected == true {
            tblSelectionColor.set()
            dirtyRect.fill()
        }
    }
}





extension focusPreferencesVc:NSTextFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldSelectedFocusType{
                if textFieldSelectedFocusType.stringValue.count > 250{
                    let index = textfield.stringValue.index(textfield.stringValue.startIndex, offsetBy: 250)
                    textfield.stringValue = String(textfield.stringValue.prefix(upTo: index))
                }
            }
        }
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldSelectedFocusType{
                let selectedRow = tblViewFocusType.selectedRow
                let newName = textFieldSelectedFocusType.stringValue.lowercased
                if textFieldSelectedFocusType.stringValue.isEmpty{
                    if let name = arrFocusType[tblViewFocusType.selectedRow]["name"] as? String{
                        textFieldSelectedFocusType.stringValue = name
                    }
                    return;
                }
                for i in 0..<arrFocusType.count{
                    if i != selectedRow{
                        let dic = arrFocusType[i]
                        if let name = dic["name"] as? String{
                            if name.lowercased() == newName(){
                                let alert = NSAlert()
                                alert.setSharingType()
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
                
                if isHardCorePomodoroModeOn{
                    if dic["isOn"] as? Bool == true{
                        hardcodePmodoroFocusModeName = textFieldSelectedFocusType.stringValue
                    }
                }
                let idFocusMode = dic["id"] as? String ?? ""
                textFieldSelectedFocusType.isEnabled = false
                
                arrFocusType[selectedRow] = dic

                
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
                
                sortFocusModes()
                
                tblViewFocusType.reloadData()
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["id"] as? String == idFocusMode{
                        tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: i), byExtendingSelection: false)
                        tblViewFocusType.scrollRowToVisible(i)
                        break;
                    }
                }
                checkState()
                
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                
                textFieldSelectedFocusType.isEnabled = true
                allApiObject.capturePosthog(event: "change-focus-mode-name", metadata: [:])
                resetPomodoroVcFocusListIfNeeded()
            }
        }
    }
    
}
