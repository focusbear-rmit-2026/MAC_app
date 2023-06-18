//
//  popUpCheckListVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class popUpCheckListVc: NSViewController {

    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrCheckList = [[String:Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func resetView(title:String, list:[String]){
        lblTitle.stringValue = title
        arrCheckList.removeAll()
        for item in list{
            arrCheckList.append(["title": item, "state": false])
        }
        tblView.reloadData()
    }
}
extension popUpCheckListVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrCheckList.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellOnboardingBlockedUrls"), owner: nil) as? tblCellOnboardingBlockedUrls {
            
            if row < arrCheckList.count{
                cell.btnCheckBox.title = arrCheckList[row]["title"] as? String ?? ""
                
                if let state = arrCheckList[row]["state"] as? Bool{
                    if state{
                        cell.btnCheckBox.state = .on
                    }else{
                        cell.btnCheckBox.state = .off
                    }
                }
                cell.btnCheckBox.target = self
                cell.btnCheckBox.tag = row
                cell.btnCheckBox.action = #selector(btnCheckBoxClicked(sender:))
            }
            return cell
        }
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
    
    @objc func btnCheckBoxClicked(sender:NSButton){
        if let state = arrCheckList[sender.tag]["state"] as? Bool{
            if state{
                arrCheckList[sender.tag]["state"] = false
            }else{
                arrCheckList[sender.tag]["state"] = true
            }
        }
        
        tblView.reloadData()
    }
}
