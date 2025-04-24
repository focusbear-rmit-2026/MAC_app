//
//  blockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 15/03/22.


import Cocoa

class blockedUrlsVc: NSViewController {

    @IBOutlet weak var checkBoxImmediatelyBlock: NSButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnAddUrl: NSButton!
    @IBOutlet weak var btnRemoveUrl: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        checkBoxImmediatelyBlock.title = "Immediately block super distracting sites"
        lblTitle.stringValue = "Super Distracting Sites"
        tblView.doubleAction = #selector(tableRowAllowedUrlsDoubleClicked)
        lblSubTitle.stringValue = "\"Block these URLs even if you're not in a focus block. You might want to put social media or news sites that you would rather not use at any time. You can always set up an evening routine activity where you explicitly allow access to Facebook so that you can still stay connected - just not during your morning routine/work day.\""
        
        if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
            if let title = blockedUrlsViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let subTitleText = blockedUrlsViewInfo.value(forKey: "subTitleText") as? String{
                lblSubTitle.stringValue = subTitleText
            }
            checkBoxImmediatelyBlock.title = blockedUrlsViewInfo.value(forKey: "checkBoxText") as? String ?? checkBoxImmediatelyBlock.title
        }
        
        if #available(macOS 11.0, *) {
            btnAddUrl.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveUrl.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idBlockedUrls, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idBlockedUrls, "object": lblTitle as Any])
    }
    override func viewWillAppear() {
        tblView.reloadData()
        if SettingsManagerObject.immediatelyBlockDistractingSites{
            checkBoxImmediatelyBlock.state = .on
        }else{
            checkBoxImmediatelyBlock.state = .off
        }
    }

    @IBAction func btnAddUrlClicked(_ sender: Any) {
        if isExpired{
            if SettingsManagerObject.arrBlockedUrls.count >= alwaysBlockedUrlsCountInExpireApp{
                var titleLimitedBlockUrls = "Max 3 blocked urls can be added in Basic version."
                if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                    titleLimitedBlockUrls = upgradeToProNagVcInfo.value(forKey: "titleLimitedBlockUrls") as? String ?? titleLimitedBlockUrls
                }
                showUpgradeToProNagWindow(titleText: titleLimitedBlockUrls, reason: "add_always_blocked_url")
                return;
            }
        }
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
        UserDefaults.standard.set(true, forKey: kUserdefaultsEditBlockedUrlsOnce)
        allApiObject.capturePosthog(event: "remove-always-blocked-url", metadata: [:])//#490
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
    
    
    
    @IBAction func checkBoxImmediatelyBlockClicked(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        if checkBoxImmediatelyBlock.state == .on{
            SettingsManagerObject.immediatelyBlockDistractingSites = true
            allApiObject.capturePosthog(event: "settings-changed-immediately-block-url-enabled", metadata: [:])
        }else{
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            allApiObject.capturePosthog(event: "settings-changed-immediately-block-url-disabled", metadata: [:])
        }
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
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
