//
//  savedSitesForLaterVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/02/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class savedSitesForLaterVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRemove: NSButton!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!

    var arrWebsitesInfo = [WebsiteInfo]()
    struct WebsiteInfo{
        var state:Bool = false
        var info:NSDictionary?
    }
    var titleTimeRemainingText = "Time remaining:"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Sites you saved for relax mode:"
        btnRemove.toolTip = "Remove Selected URLs"

        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
        }
        
        if let relaxModeVcInfo = configjson.value(forKey: "relaxModeVcInfo") as? NSDictionary{
            lblTitle.stringValue = relaxModeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnRemove.toolTip = relaxModeVcInfo.value(forKey: "toolTipRemoveUrls") as? String ?? btnRemove.toolTip
        }
        
    }
    func reloadData() {
        arrWebsitesInfo.removeAll()
        loader.startAnimation(self)
        loader.isHidden = false
        tblView.reloadData()
        
        allApiObject.getSavedWebsite(completionHandler: {arrJson in
            
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.loader.isHidden = true
                if arrJson != nil{
                    for info in arrJson!{
                        let websiteInfo = WebsiteInfo(state: false, info: info)
                        self.arrWebsitesInfo.append(websiteInfo)
                    }
                    self.tblView.reloadData()
                }
                if self.arrWebsitesInfo.count == 0{
                    self.view.window?.close()
                    addLog(text: "savedSitesForLaterVc: urls count is 0:- close window")
                }
            }
        })
    }
    

    @IBAction func btnRemoveClicked(_ sender: Any) {
        var i = 0
        var totalArrayCount = arrWebsitesInfo.count
        while i < totalArrayCount{
            if arrWebsitesInfo[i].state {
                if let info = arrWebsitesInfo[i].info{
                    let id = info.value(forKey: "id") as? String ?? ""
                    allApiObject.deleteSavedWebsite(UUID: id, completionHandler: {result in
                        
                    })
                }
                arrWebsitesInfo.remove(at: i)
                totalArrayCount -= 1
            }else{
                i += 1
            }
        }
        tblView.reloadData()
    }
}


extension savedSitesForLaterVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrWebsitesInfo.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellUrlRelaxMode"), owner: nil) as? tblCellUrlRelaxMode {

            cell.lblTitle.stringValue = arrWebsitesInfo[row].info!.value(forKey: "url") as? String ?? ""
            cell.checkBox.target = self
            cell.checkBox.tag = row
            cell.checkBox.action = #selector(btnCheckBoxXlixked(sender:))
            
            if arrWebsitesInfo[row].state {
                cell.checkBox.state = .on
            }else{
                cell.checkBox.state = .off
            }
            return cell
        }

        return NSTableCellView()
    }
    
    @objc func btnCheckBoxXlixked(sender:NSButton){
        if arrWebsitesInfo[sender.tag].state {
            arrWebsitesInfo[sender.tag].state = false
        }else{
            arrWebsitesInfo[sender.tag].state = true
        }
        tblView.reloadData()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblView.selectedRow == -1{
            return
        }
        var url = arrWebsitesInfo[tblView.selectedRow].info!.value(forKey: "url") as? String ?? ""
        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
            url = "http://"+url
        }
        NSWorkspace.shared.open(URL(string: url)!)
        tblView.reloadData()
        addLog(text: "[user-action] savedSitesForLaterVc:- OpenUrlClicked")
        allApiObject.capturePosthog(event: "saved-for-later-open-url-clicked", metadata: [:])
    }
}
