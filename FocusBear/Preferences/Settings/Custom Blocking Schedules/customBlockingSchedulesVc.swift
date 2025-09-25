//
//  customBlockingSchedulesVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class customBlockingSchedulesVc: NSViewController {

    @IBOutlet weak var lblAddNewBlock: NSTextField!
    @IBOutlet weak var boxAddNewSchedule: NSBox!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnBack: cursorButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Custom Blocking" // todo text
        lblAddNewBlock.stringValue = "➕ Add new block"
        tblView.enclosingScrollView?.contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        boxAddNewSchedule.isHidden = true
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
        }
    }
    
    override func viewWillAppear() {
        
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
                cell.lblAddNewBlock.stringValue = "➕ Add new block" // todo text
            }else{
                cell.boxBlockingSchedule.isHidden = false
                cell.boxAddSchedule.isHidden = true
                cell.lblTitle.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].name
                cell.lblTime.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].displayString
                cell.lblBlockMode.stringValue = customBlockingScheduleManagerObj.arrBlockingSchedule[row].blockLevelString
                
           
                
                let focusModeID = customBlockingScheduleManagerObj.arrBlockingSchedule[row].focusModeID
                
                for focusMode in arrFocusType{
                    if focusMode["id"] as? String == focusModeID{
                        cell.lblFocusModeName.stringValue = focusMode["name"] as? String ?? ""
                        break;
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
}
