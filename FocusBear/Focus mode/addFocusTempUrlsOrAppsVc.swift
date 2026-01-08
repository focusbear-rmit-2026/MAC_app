//
//  addFocusTempUrlsOrAppsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class addFocusTempUrlsOrAppsVc: NSViewController {

   
    
    @IBOutlet weak var btnInfo: cursorButton!
    @IBOutlet weak var tblViewKeywords: NSTableView!
    @IBOutlet weak var tblViewUrls: NSTableView!
    @IBOutlet weak var tblViewApps: NSTableView!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnAllow: Button!
    @IBOutlet weak var heightScrollViewApps: NSLayoutConstraint!
    @IBOutlet weak var heightScrollViewUrls: NSLayoutConstraint!
    @IBOutlet weak var heightScrollViewKeyWords: NSLayoutConstraint!
    
    
    @IBOutlet weak var btnaddKeyword: NSButton!
    @IBOutlet weak var lblTitleKeywords: NSTextField!
    @IBOutlet weak var lblTitleUrls: NSTextField!
    @IBOutlet weak var lblTitleApps: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxUrls: NSBox!
    @IBOutlet weak var boxApps: NSBox!
    @IBOutlet weak var boxKeyWords: NSBox!
    var currentFocusModeId = ""
    
    var arrAllowedApps =  [[String:Any]]()
    var arrAllowedUrls = [[String:Any]]()
    var arrAllowedKeywords = [[String:Any]]()
    
    
    var btnInfoTrackingArea: NSTrackingArea?
    var keywordsInfoText = "To avoid you having to add websites individually, we can scan the titles of the web pages you allowed in this session and identify the most common key phrases. For example, if you opened ten pages relating to Figma 'How to link between pages in Figma'. 'How to share Figma files' etc. We can detect that Figma is the most common phrase and add it to your allow list. After that, any web page with 'Figma' in the title will be automatically allowed. We don't store the details of the pages you visit - we immediately discard the information after analysing it."
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnaddKeyword.toolTip = "Add keyword"
        lblTitleKeywords.stringValue = "Allowed keywords:"
        
        lblTitle.stringValue = "Do you want to permanently allow these Apps or URLs that you used during this session?"
        btnAllow.title = "Allow"
        btnCancel.title = buttonCancelText
        lblTitleApps.stringValue = "Apps:"
        lblTitleUrls.stringValue = "URLs:"
        
        if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
            lblTitleApps.stringValue = toolBoxVcInfo.value(forKey: "appsText") as? String ?? lblTitleApps.stringValue
            lblTitleUrls.stringValue = toolBoxVcInfo.value(forKey: "urlsText") as? String ?? lblTitleUrls.stringValue
        }
        
        if let addFocusTempUrlsOrAppsVcInfo = configjson.value(forKey: "addFocusTempUrlsOrAppsVcInfo") as? NSDictionary{
            lblTitle.stringValue = addFocusTempUrlsOrAppsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnAllow.title = addFocusTempUrlsOrAppsVcInfo.value(forKey: "buttonAllowText") as? String ?? btnAllow.title
            lblTitleKeywords.stringValue = addFocusTempUrlsOrAppsVcInfo.value(forKey: "titleKeywords") as? String ?? lblTitleKeywords.stringValue
            keywordsInfoText = addFocusTempUrlsOrAppsVcInfo.value(forKey: "keywordsInfoText") as? String ?? keywordsInfoText
            btnaddKeyword.toolTip = addFocusTempUrlsOrAppsVcInfo.value(forKey: "tooltipAddkeyword") as? String ?? btnaddKeyword.toolTip
        }
        
        
        tblViewApps.delegate = self
        tblViewUrls.delegate = self
        
        
        
        btnInfoTrackingArea = NSTrackingArea.init(rect: btnInfo.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnInfo.addTrackingArea(btnInfoTrackingArea!)
    }
    override func viewWillAppear() {
        arrAllowedApps.removeAll()
        arrAllowedUrls.removeAll()
        arrAllowedKeywords.removeAll()
    }
    func resetView() {
        arrAllowedApps.removeAll()
        arrAllowedUrls.removeAll()
        arrAllowedKeywords.removeAll()
        
        if lastFocusModeTempInfo != nil{
            
            currentFocusModeId = lastFocusModeTempInfo!.id
            for app in lastFocusModeTempInfo!.arrAllowedAppsInCuddlyModeCurrentFocus{
                if app.bundleURL != nil{
                    let item = ["state":true, "item": app.bundleURL!] as [String : Any]
                    arrAllowedApps.append(item)
                }
            }
            for url in lastFocusModeTempInfo!.arrAllowedUrlsInCuddlyModeCurrentFocus{
                let item = ["state":true, "item": url] as [String : Any]
                arrAllowedUrls.append(item)
            }
            
            for keyWord in arrKeywordsToAllowInFocus{
                let item = ["state":false, "item": keyWord] as [String : Any]
                arrAllowedKeywords.append(item)
            }
            
            if arrAllowedApps.count == 0{
                boxApps.isHidden = true
            }else{
                boxApps.isHidden = false
                if arrAllowedApps.count > 5{
                    heightScrollViewApps.constant = (5*29) + 5
                }else if arrAllowedApps.count < 3{
                    heightScrollViewApps.constant = (3*29) + 5
                }else{
                    heightScrollViewApps.constant = CGFloat(arrAllowedApps.count * 29) + 5
                }
                tblViewApps.reloadData()
            }
            
            if arrAllowedUrls.count == 0{
                boxUrls.isHidden = true
            }else{
                boxUrls.isHidden = false
                if arrAllowedUrls.count > 5{
                    heightScrollViewUrls.constant = (5*29) + 5
                }else if arrAllowedUrls.count < 3{
                    heightScrollViewUrls.constant = (3*29) + 5
                }else{
                    heightScrollViewUrls.constant = CGFloat(arrAllowedUrls.count * 29) + 5
                }
                tblViewUrls.reloadData()
            }
            
            
            
           // if arrAllowedKeywords.count == 0{
           //     boxKeyWords.isHidden = true
           // }else{
                boxKeyWords.isHidden = false
                if arrAllowedKeywords.count > 5{
                    heightScrollViewKeyWords.constant = (5*29) + 5
                }else if arrAllowedKeywords.count < 3{
                    heightScrollViewKeyWords.constant = (3*29) + 5
                }else{
                    heightScrollViewKeyWords.constant = CGFloat(arrAllowedKeywords.count * 29) + 5
                }
                tblViewKeywords.reloadData()
           // }
            
        }


  

    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == btnInfoTrackingArea{
            showTooltip(sender: btnInfo, msg: keywordsInfoText, preferredEdge: NSRectEdge.maxX, maxWidthVal:400, autoCloseOnMouseExit: true)
        }
    }
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == btnInfoTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func btnAllowClicked(_ sender: Any) {
        self.view.window?.close()
        
        var appUrlsToadd = [URL]()
        var urlsToadd = [String]()
        
        for i in 0..<arrAllowedApps.count{
            if arrAllowedApps[i]["state"] as? Bool == true{
                if let url = arrAllowedApps[i]["item"] as? URL{
                    appUrlsToadd.append(url)
                }
            }
        }
        
        for i in 0..<arrAllowedUrls.count{
            if arrAllowedUrls[i]["state"] as? Bool == true{
                if let val = arrAllowedUrls[i]["item"] as? String{
                    urlsToadd.append(val)
                }
            }
        }
        
        for i in 0..<arrAllowedKeywords.count{
            if arrAllowedKeywords[i]["state"] as? Bool == true{
                if let val = arrAllowedKeywords[i]["item"] as? String{
                    if !val.isEmpty{
                        urlsToadd.append(val)
                    }
                }
            }
        }
        
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String == currentFocusModeId{
                
                // apps
                var appsArray = [String]()
                var appsUrlArray = [URL]()
                if let arr = arrFocusType[i]["allowed_apps"] as? [String]{
                    appsArray = arr
                }
                for path in appsArray{
                    let url = URL(fileURLWithPath: path)
                    appsUrlArray.append(url)
                }
                for url in appUrlsToadd{
                    var isFoundAlready = false
                    for addedUrl in appsUrlArray{
                        if addedUrl.lastPathComponent.lowercased() == url.lastPathComponent.lowercased(){
                            isFoundAlready = true
                            break;
                        }
                    }
                    if !isFoundAlready{
                        appsArray.append(url.path)
                    }
                }
                arrFocusType[i]["allowed_apps"] = appsArray

                //
                
                
                //urls
                
                var urlsArray = [String]()
                if let arr = arrFocusType[i]["allowed_urls"] as? [String]{
                    urlsArray = arr
                }
                
                
                for url in urlsToadd{
                    var isFoundAlready = false
                    for addedUrl in urlsArray{
                        if addedUrl.lowercased() == url.lowercased(){
                            isFoundAlready = true
                            break;
                        }
                    }
                    if !isFoundAlready{
                        urlsArray.append(url)
                    }
                }
                
                arrFocusType[i]["allowed_urls"] = urlsArray
                
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                updateAllFocusModes()
                

                allApiObject.capturePosthog(event: "add-temp-items-to-focus-mode", metadata: [:])
                break;
            }
        }
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: keywordsInfoText, preferredEdge: NSRectEdge.maxX, maxWidthVal:400, autoCloseOnMouseExit: true)
    }
    @IBAction func btnAddKeyword(_ sender: Any) {
        let item = ["state":false, "item": ""] as [String : Any]
        arrAllowedKeywords.append(item)
        tblViewKeywords.reloadData()
        tblViewKeywords.scrollRowToVisible(tblViewKeywords.numberOfRows - 1)
        if let rowView = tblViewKeywords.view(atColumn: 0, row: tblViewKeywords.numberOfRows - 1, makeIfNecessary: true) as? tblCellOnboardingBlockedUrls{
            rowView.textFieldTitle.setFocus()
        }
    }
}
extension addFocusTempUrlsOrAppsVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tblViewApps{
            return arrAllowedApps.count
        }else if tableView == tblViewUrls{
            return arrAllowedUrls.count
        }else if tableView == tblViewKeywords{
            return arrAllowedKeywords.count
        }
        return 0
    }



    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellOnboardingBlockedUrls"), owner: nil) as? tblCellOnboardingBlockedUrls {
            
            var state = false
        
            cell.btnCheckBox.tag = row
            cell.btnCheckBox.target = self
            
            if tableView == tblViewApps{
                state = arrAllowedApps[row]["state"] as? Bool ?? false
                
                if let url = arrAllowedApps[row]["item"] as? URL{
                    cell.btnCheckBox.title = url.lastPathComponent
                }
                
                cell.btnCheckBox.action = #selector(btnCheckBoxAppClicked(sender:))
            }else if tableView == tblViewUrls{
                state = arrAllowedUrls[row]["state"] as? Bool ?? false
                cell.textFieldTitle.stringValue = arrAllowedUrls[row]["item"] as? String ?? ""
                cell.textFieldTitle.delegate = self
                cell.textFieldTitle.tag = row
                cell.btnCheckBox.action = #selector(btnCheckBoxUrlClicked(sender:))
            }else if tableView == tblViewKeywords{
                state = arrAllowedKeywords[row]["state"] as? Bool ?? false
                cell.textFieldTitle.stringValue = arrAllowedKeywords[row]["item"] as? String ?? ""
                cell.textFieldTitle.delegate = self
                cell.textFieldTitle.tag = row
                cell.btnCheckBox.action = #selector(btnCheckBoxKeyWordClicked(sender:))
            }
            
            if state{
                cell.btnCheckBox.state = .on
            }else{
                cell.btnCheckBox.state = .off
            }
            return cell
        }

        return NSTableCellView()
    }

    @objc func btnCheckBoxAppClicked(sender:NSButton){
        let state = arrAllowedApps[sender.tag]["state"] as? Bool ?? false
        if state{
            arrAllowedApps[sender.tag]["state"] = false
        }else{
            arrAllowedApps[sender.tag]["state"] = true
        }
        
        tblViewApps.reloadData()
    }
    @objc func btnCheckBoxUrlClicked(sender:NSButton){
        let state = arrAllowedUrls[sender.tag]["state"] as? Bool ?? false
        if state{
            arrAllowedUrls[sender.tag]["state"] = false
        }else{
            arrAllowedUrls[sender.tag]["state"] = true
        }
        
        tblViewUrls.reloadData()
    }
    
    @objc func btnCheckBoxKeyWordClicked(sender:NSButton){
        let state = arrAllowedKeywords[sender.tag]["state"] as? Bool ?? false
        if state{
            arrAllowedKeywords[sender.tag]["state"] = false
        }else{
            arrAllowedKeywords[sender.tag]["state"] = true
        }
        
        tblViewKeywords.reloadData()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {

    }
}

extension addFocusTempUrlsOrAppsVc:NSTextFieldDelegate{
    func controlTextDidEndEditing(_ obj: Notification) {
        
        if let textField = obj.object as? NSTextField{
            if arrAllowedKeywords.count != 0{
                if let cellView = tblViewKeywords.view(atColumn: 0, row: textField.tag, makeIfNecessary: false) as? tblCellOnboardingBlockedUrls{
                    if cellView.textFieldTitle == textField{
                        if textField.tag >= arrAllowedKeywords.count{
                            return;
                        }
                        if textField.stringValue.isEmpty{
                            textField.stringValue = arrAllowedKeywords[textField.tag]["item"] as? String ?? ""
                            return;
                        }
                        for i in 0..<arrAllowedKeywords.count{
                            if i != textField.tag{
                                if((arrAllowedKeywords[i]["item"] as? String ?? "").caseInsensitiveCompare(textField.stringValue) == .orderedSame){
                                   
                                    var alreadyExistsText = "<APPNAME> already exists in the list."
                                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                                        alreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String ?? alreadyExistsText
                                    }
                                    alreadyExistsText = alreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                                    textField.stringValue = arrAllowedKeywords[textField.tag]["item"] as? String ?? ""
                                    
                                    let alert = NSAlert()
                                    alert.messageText = alreadyExistsText
                                    alert.addButton(withTitle: buttonOkText)
                                    alert.beginSheetModal(for: self.view.window!)
                                    return;
                                }
                            }
                        }
                        arrAllowedKeywords[textField.tag]["item"] = textField.stringValue
                        tblViewKeywords.reloadData()
                        return;
                    }
                }
            }
            
            if arrAllowedUrls.count != 0{
                if let cellView = tblViewUrls.view(atColumn: 0, row: textField.tag, makeIfNecessary: false) as? tblCellOnboardingBlockedUrls{
                    if cellView.textFieldTitle == textField{
                        if textField.tag >= arrAllowedUrls.count{
                            return;
                        }
                        if textField.stringValue.isEmpty{
                            textField.stringValue = arrAllowedUrls[textField.tag]["item"] as? String ?? ""
                            return;
                        }
                        arrAllowedUrls[textField.tag]["item"] = textField.stringValue
                        tblViewUrls.reloadData()
                    }
                }
            }
        }
    }
}
