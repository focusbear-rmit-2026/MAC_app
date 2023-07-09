//
//  menuTourPopoverVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class menuTourPopoverVc: NSViewController {

    @IBOutlet weak var lblMainTitle: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var heightScrollView: NSLayoutConstraint!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var btnClose: NSButton!
    @IBOutlet weak var lblCurrentIndex: NSTextField!
    @IBOutlet weak var btnNext: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrList = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tblView.delegate = self
        tblView.dataSource = self
        tblView.reloadData()
        lblMainTitle.stringValue = "Focus Bear Menu"
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            lblMainTitle.stringValue = menuTourVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
        }
    }
    
    func showCurrentMessage(title:String, description:String, buttonTitle:String, indexText:String, arrList:[String], progress:Int){
        lblTitle.stringValue = title
        lblDescription.stringValue = description
        btnNext.title = buttonTitle
        lblCurrentIndex.stringValue = indexText
        progressBar.doubleValue = Double(progress)
        self.arrList = arrList
        if arrList.count == 0{
            scrollView.isHidden = true
        }else{
            scrollView.isHidden = false
            tblView.reloadData()
            heightScrollView.constant = tblView.frame.height
            DispatchQueue.global().async {
                usleep(50000)
                DispatchQueue.main.async {
                    self.heightScrollView.constant = self.tblView.frame.height
                }
            }
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        menuTourVcObj!.btnCloseClicked(self)
    }
    @IBAction func btnNextClicked(_ sender: Any) {
        menuTourVcObj!.btnNextClickedFromPopover()
    }
}


extension menuTourPopoverVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrList.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            if row >= arrList.count{
               return cell
            }
            cell.lblTitle.stringValue = arrList[row]
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
}
