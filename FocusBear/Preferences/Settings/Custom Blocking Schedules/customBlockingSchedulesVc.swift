//
//  customBlockingSchedulesVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class customBlockingSchedulesVc: NSViewController {

    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnBack: cursorButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Custom Blocking" // todo text
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        
    }
    override func viewWillAppear() {
        tblView.reloadData()
    }
}

extension customBlockingSchedulesVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrBlockingSchedule.count + 1
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellCustomBlockingSchedules"), owner: nil) as? tblCellCustomBlockingSchedules {

            if row >= arrBlockingSchedule.count{
                cell.boxBlockingSchedule.isHidden = true
                cell.boxAddSchedule.isHidden = false
                cell.lblAddNewBlock.stringValue = "➕ Add new block" // todo text
            }else{
                cell.boxBlockingSchedule.isHidden = false
                cell.boxAddSchedule.isHidden = true
                cell.lblTitle.stringValue = arrBlockingSchedule[row].name
                cell.lblTime.stringValue = arrBlockingSchedule[row].displayString
                cell.lblBlockMode.stringValue = arrBlockingSchedule[row].blockLevel.rawValue
                let focusModeID = arrBlockingSchedule[row].focusModeID
                
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
        if sender.tag >= arrBlockingSchedule.count{
            tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: -1, shouldCreateNew: true)
        }else{
            tabStrictnessContainerVcObj?.showBlockingSchedulesView(index: sender.tag, shouldCreateNew: false)
        }
    }
}
