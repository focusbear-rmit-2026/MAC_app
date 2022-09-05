//
//  blockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 15/03/22.


import Cocoa

class blockedUrlsVc: NSViewController {

    @IBOutlet weak var btnAddUrl: NSButton!
    @IBOutlet weak var btnRemoveUrl: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Always Blocked URLs"
        tblView.doubleAction = #selector(tableRowAllowedUrlsDoubleClicked)
        blockedUrlsVcObj = self
        
        if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
            if let title = blockedUrlsViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
        }
        
    }
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    @IBAction func btnAddUrlClicked(_ sender: Any) {
        addWebUrlVcObj!.currenUrlAddingtState = ._ALL_BLOCK_URL
        addWebUrlVcObj!.isAdding = true
        self.presentAsSheet(addWebUrlVcObj!)
    }
    
    @IBAction func btnRemoveUrlClicked(_ sender: Any) {
        let selectedUrlsRow = tblView.selectedRow
        if selectedUrlsRow == -1{
            return
        }
        if selectedUrlsRow < SettingsManagerObject.arrBlockedUrls.count{
            SettingsManagerObject.arrBlockedUrls.remove(at: selectedUrlsRow)
            tblView.reloadData()
            UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
        }
        SettingsManagerObject.isSettingsChanged = true
        
    }
    @objc func tableRowAllowedUrlsDoubleClicked(){
        let selectedTow = tblView.selectedRow
        if selectedTow == -1{
            return;
        }
        addWebUrlVcObj!.currenUrlAddingtState = ._ALL_BLOCK_URL
        addWebUrlVcObj!.isAdding = false
        self.presentAsSheet(addWebUrlVcObj!)
    }
}

extension blockedUrlsVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {

        if SettingsManagerObject.arrBlockedUrls.count == 0{
            btnRemoveUrl.isEnabled = false
        }else{
            btnRemoveUrl.isEnabled = true
        }
        return SettingsManagerObject.arrBlockedUrls.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            
            

            if row < SettingsManagerObject.arrBlockedUrls.count{
                cell.lblTitle.stringValue = SettingsManagerObject.arrBlockedUrls[row]
                cell.imgView.image = NSImage(named: NSImage.networkName)
            }else{
                cell.lblTitle.stringValue = ""
                cell.imgView.image = nil
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
    
        if tblview == tblView{
            if selectedRow == -1{
                btnRemoveUrl.isEnabled = false
            }else{
                btnRemoveUrl.isEnabled = true
            }
        }
    }
    

}
