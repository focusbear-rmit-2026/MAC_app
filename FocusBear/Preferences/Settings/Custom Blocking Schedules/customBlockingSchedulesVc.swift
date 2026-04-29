//
//  customBlockingSchedulesVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class customBlockingSchedulesVc: NSViewController {

    @IBOutlet weak var lblTipPermissions: NSTextField!
    @IBOutlet weak var boxTipPermissions: NSBox!
    @IBOutlet weak var btnFixIt: Button!
    @IBOutlet weak var lblAddNewBlock: NSTextField!
    @IBOutlet weak var boxAddNewSchedule: NSBox!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnBack: cursorButton!
    
    var boxPermissionTrackingArea: NSTrackingArea?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Custom Blocking"
        lblAddNewBlock.stringValue = "➕ Add new block"
        tblView.enclosingScrollView?.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        //boxAddNewSchedule.isHidden = true
        btnFixIt.title = "Enable"
        lblTipPermissions.stringValue = "Grant Focus Bear permissions to block."
        
        if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
            lblTitle.stringValue = blockingScheduleEditorVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            if let title = blockingScheduleEditorVcInfo.value(forKey: "buttonAddNewBlock") as? String{
                lblAddNewBlock.stringValue = "➕ \(title)"
            }
        }
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            lblTipPermissions.stringValue = menuInfo.value(forKey: "permissionsNotSetText") as? String ?? lblTipPermissions.stringValue
            btnFixIt.title = menuInfo.value(forKey: "buttonEnable") as? String ?? btnFixIt.title
        }
        
        
        boxPermissionTrackingArea = NSTrackingArea.init(rect: boxTipPermissions.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        boxTipPermissions.addTrackingArea(boxPermissionTrackingArea!)
        
    }
    
    override func viewWillAppear() {
        checkPermissions()
    }
    
    func checkPermissions(){
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            boxTipPermissions.isHidden = false
        }else{
            if !(menuViewControllerObj?.browserPermissionGiven ?? false) || !(menuViewControllerObj?.accessibilityPermissionGiven ?? false) || !(menuViewControllerObj?.systemEventsPermissionGiven ?? false){
                boxTipPermissions.isHidden = false
            }else{
                boxTipPermissions.isHidden = true
            }
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == boxPermissionTrackingArea{
            var msg = lblTipPermissions.stringValue
            if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                msg = "- No permissions granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "noPermissionSet") as? String ?? msg
                }
            }else if !(menuViewControllerObj?.browserPermissionGiven ?? false){
                msg = "- Permission to any browser not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "browserPermissionNotSet") as? String ?? msg
                }
            }else if !(menuViewControllerObj?.accessibilityPermissionGiven ?? false){
                msg = "- Accessibility permission not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "accessibilityNotSet") as? String ?? msg
                }
            }else if !(menuViewControllerObj?.systemEventsPermissionGiven ?? false){
                msg = "- System Events permission not granted"
                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                    msg = menuInfo.value(forKey: "systemEventsPermissionNotSet") as? String ?? msg
                }
            }
            
            
            showTooltipWithOsTahoe(sender: boxTipPermissions, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:400, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == boxPermissionTrackingArea{
            closePopoverTooltipIfVisible()
        }
    }
    
    func scheduleAdded(){
        tblView.reloadData()
        tblView.scrollRowToVisible(tblView.numberOfRows - 1)
    }
    
    func scheduleEditedAt(_ index:Int){
        tblView.reloadData(forRowIndexes: IndexSet(arrayLiteral: index), columnIndexes: IndexSet(arrayLiteral: 0))
    }
    
    
    @IBAction func btnAddNewBlockClicked(_ sender: Any) {
        tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: -1, shouldCreateNew: true)
    }
    
    @IBAction func btnFixItClicked(_ sender: Any) {
        addLog(text:"[user-action] menuViewController:- btnSetPermissionsClicked")// 23/7/25  v 1.26.393
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !(menuViewControllerObj?.browserPermissionGiven ?? false){
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !(menuViewControllerObj?.accessibilityPermissionGiven ?? false){
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }else if !(menuViewControllerObj?.systemEventsPermissionGiven ?? false){
            showExplainingPermissionsWindow(showingFromPomodoro: false)
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
        }
        closeMenuWindowIsVisible()
    }
}

extension customBlockingSchedulesVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if customBlockingScheduleManagerObj.arrBlockingSchedule.count > 3{
            boxAddNewSchedule.isHidden = false
            return customBlockingScheduleManagerObj.arrBlockingSchedule.count
        }else{
            boxAddNewSchedule.isHidden = true
            return customBlockingScheduleManagerObj.arrBlockingSchedule.count + 1
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellCustomBlockingSchedules"), owner: nil) as? tblCellCustomBlockingSchedules {

            if row >= customBlockingScheduleManagerObj.arrBlockingSchedule.count{
                cell.boxBlockingSchedule.isHidden = true
                cell.boxAddSchedule.isHidden = false
                cell.lblAddNewBlock.stringValue = "➕ Add new block"
                if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                    if let title = blockingScheduleEditorVcInfo.value(forKey: "buttonAddNewBlock") as? String{
                        lblAddNewBlock.stringValue = "➕ \(title)"
                    }
                }
            }else{
                cell.boxBlockingSchedule.isHidden = false
                cell.boxAddSchedule.isHidden = true
                cell.lblTitle.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].name
                cell.lblTime.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].displayString
                cell.lblBlockMode.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].blockLevelString
                
           
                
                let focusModeID = customBlockingScheduleManagerObj.arrBlockingSchedule[row].focusModeID
                cell.lblFocusModeName.stringValue = ""
                var isFocusModeFound = false
                for focusMode in arrFocusType{
                    if focusMode["id"] as? String == focusModeID{
                        cell.lblFocusModeName.stringValue = focusMode["name"] as? String ?? ""
                        isFocusModeFound = true
                        break;
                    }
                }
                if !isFocusModeFound{
                    cell.lblFocusModeName.stringValue = "Update block list ⚠️"
                    if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                        if let errorBlockListMissing = blockingScheduleEditorVcInfo.value(forKey: "errorBlockListMissing") as? String{
                            cell.lblFocusModeName.stringValue = errorBlockListMissing
                        }
                    }
                }
            }
            
            cell.btnMain.tag = row
            cell.btnMain.target = self
            cell.btnMain.action = #selector(btnBlockingScheduleClicked)
            return cell
        }
        
        return NSTableCellView()
    }

    @objc func btnBlockingScheduleClicked(sender:NSButton){
        if sender.tag >= customBlockingScheduleManagerObj.arrBlockingSchedule.count{
            tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: -1, shouldCreateNew: true)
        }else{
            tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: sender.tag, shouldCreateNew: false)
        }
    }
    
    func firstScheduleCreatedCheckPermissions(){
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Allow permissions to block distracting websites and apps"
            alertWarning.informativeText = "You will need to allow permissions to block distracting websites and distracting apps."
            var buttonBlockText = "Grant permissions"
            var buttonNoText = "No thanks"
            if let blockingScheduleEditorVcInfo = configjson.value(forKey: "blockingScheduleEditorVcInfo") as? NSDictionary{
                alertWarning.messageText = blockingScheduleEditorVcInfo.value(forKey: "permissionsMessageText") as? String ?? alertWarning.messageText
                alertWarning.informativeText = blockingScheduleEditorVcInfo.value(forKey: "permissionsInformativeText") as? String ?? alertWarning.informativeText
                buttonBlockText = blockingScheduleEditorVcInfo.value(forKey: "permissionsButtonGrantPermissions") as? String ?? buttonBlockText
                buttonNoText = blockingScheduleEditorVcInfo.value(forKey: "permissionsButtonNo") as? String ?? buttonNoText
            }
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if modalResponse == .alertFirstButtonReturn{
                    showExplainingPermissionsWindow(showingFromPomodoro: false, showingFromBlockingSchedule: true)
                    self.view.window?.close()
                }
            })
            return;
        }
    }
}
