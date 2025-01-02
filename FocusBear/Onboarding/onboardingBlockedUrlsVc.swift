//
//  onboardingBlockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 09/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingBlockedUrlsVc: NSViewController {
    
    @IBOutlet weak var lblBlockedCount: NSTextField!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var lblTip: NSTextField!
    @IBOutlet weak var btnAddUrl: Button!
    @IBOutlet weak var lblEnterUrl: NSTextField!
    @IBOutlet weak var textFieldUrl: NSTextField!
//    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblBottom: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    //@IBOutlet weak var lblTitle: NSTextField!
    
    var arrBlockedUrls:[[String:Any]] = []
    
    var arrBlockedUrlsStructure = [NSMutableDictionary]()
    var lastItemTag = 0
    var categoryOthers = "Others"
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnAddUrl.keyEquivalent = "\r"
        lblTip.stringValue = "In case you're worried - we don't track which websites you're using."
        lblBlockedCount.stringValue = "6 sites will always be blocked." 
        lblEnterUrl.stringValue = "Enter url to block:"
        btnAddUrl.title = "Add url"
        
        // lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "Which sites do you waste time on?"
        lblDescription.stringValue = "You can block certain sites by default to avoid going down rabbit holes."
        lblBottom.stringValue = "If you want to block other sites by default, you can change your Always Blocked settings in Preferences."
        btnContinue.title = "Continue"
        var categorySocialMedia = "Social Media"
        var categoryNews = "News"
        var categoryStreamingServices = "Streaming services"
        
        if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
            //  lblTitle.stringValue = onboardingBlockedUrlsInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = onboardingBlockedUrlsInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblDescription.stringValue = onboardingBlockedUrlsInfo.value(forKey: "description") as? String ?? lblDescription.stringValue
            lblBottom.stringValue = onboardingBlockedUrlsInfo.value(forKey: "bottomText") as? String ?? lblBottom.stringValue
            btnContinue.title = onboardingBlockedUrlsInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblEnterUrl.stringValue = onboardingBlockedUrlsInfo.value(forKey: "enterUrlText") as? String ?? lblEnterUrl.stringValue
            btnAddUrl.title = onboardingBlockedUrlsInfo.value(forKey: "buttonAddUrlText") as? String ?? btnAddUrl.title
            lblTip.stringValue = onboardingBlockedUrlsInfo.value(forKey: "tipText") as? String ?? lblTip.stringValue
            categorySocialMedia = onboardingBlockedUrlsInfo.value(forKey: "categorySocialMedia") as? String ?? categorySocialMedia
            categoryNews = onboardingBlockedUrlsInfo.value(forKey: "categoryNews") as? String ?? categoryNews
            categoryOthers = onboardingBlockedUrlsInfo.value(forKey: "categoryOthers") as? String ?? categoryOthers
            categoryStreamingServices = onboardingBlockedUrlsInfo.value(forKey: "categoryStreamingServices") as? String ?? categoryStreamingServices
        }
        
        textFieldUrl.delegate = self
     
        var dic:NSMutableDictionary = ["category":categorySocialMedia,"isSelected":false,"tag":777,"arrUrls":[NSMutableDictionary](),"isParent":true]
        let arrSocialMediaUrls: [NSMutableDictionary] = [["url":"facebook.com", "isSelected":true, "tag":2], ["url":"x.com", "isSelected":true, "tag":3], ["url":"instagram.com", "isSelected":true, "tag":4], ["url":"tiktok.com", "isSelected":true, "tag":5], ["url":"youtube.com", "isSelected":true, "tag":6], ["url":"reddit.com", "isSelected":true, "tag":9], ["url":"www.linkedin.com/feed/", "isSelected":true, "tag":10]]
        
        dic["arrUrls"] = arrSocialMediaUrls
        
        arrBlockedUrlsStructure.append(dic)
        
        dic = ["category":categoryNews,"isSelected":false,"tag":888,"arrUrls":[NSMutableDictionary](),"isParent":true]
        let arrNewsUrls: [NSMutableDictionary] = [["url":"bbc.com", "isSelected":true, "tag":7], ["url":"cnn.com", "isSelected":true, "tag":8], ["url":"theguardian.com", "isSelected":true, "tag":11], ["url":"abc.net.au", "isSelected":true, "tag":12], ["url":"news", "isSelected":true, "tag":13]]//if any item added set last item tag
        
        dic["arrUrls"] = arrNewsUrls
        
        arrBlockedUrlsStructure.append(dic)
        
        
        dic = ["category":categoryStreamingServices,"isSelected":false,"tag":999,"arrUrls":[NSMutableDictionary](),"isParent":true]
        let arrStreamingUrls: [NSMutableDictionary] = [["url":"netflix", "isSelected":true, "tag":14], ["url":"disney", "isSelected":true, "tag":15], ["url":"hulu", "isSelected":true, "tag":16]]//if any item added set last item tag
        
        dic["arrUrls"] = arrStreamingUrls
        
        arrBlockedUrlsStructure.append(dic)
        
        lastItemTag = 17
        outlineView.reloadData()
        
        allApiObject.capturePosthog(event: "onboarding-blocked-urls-shown", metadata: [:])
        addLog(text: "onboardingBlockedUrlsVc-shown")
        recheckBlockedUrlsCount()
    }
    
    override func viewDidAppear() {
        getOnboardingProgressVcObj().loadView()
        onboardingProgressVcObj?.totalProgress = 26
        onboardingProgressVcObj!.lblTitleProgress.stringValue = onboardingProgressVcObj!.titleActivatingBlockingProgress 
        showOnboardingProgress(view: self.view, progress: 2)
        showOnboardingBellIcon(view: self.view, screen: "onboarding-blocked-urls-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    
    func recheckBlockedUrlsCount(){
        var selectedUrlsCount = 0
        for datadict in arrBlockedUrlsStructure{
            if  datadict.value(forKey: "arrUrls") is  [NSMutableDictionary]{
                let arrdic = datadict.value(forKey: "arrUrls") as! [NSMutableDictionary]
                for dic in arrdic{
                    if let state = dic["isSelected"] as? Bool{
                        if state == true{
                            selectedUrlsCount += 1
                        }
                    }
                }
            }
        }
        
        
        
        var blockSitesCountText = ""
        
        if selectedUrlsCount == 1{
            blockSitesCountText = "1 site will be blocked."
            if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
                blockSitesCountText = onboardingBlockedUrlsInfo.value(forKey: "oneSiteBlockText") as? String ?? blockSitesCountText
            }
            
            blockSitesCountText = blockSitesCountText.replacingOccurrences(of: "<COUNT>", with: "\(selectedUrlsCount)")
        }else{
            blockSitesCountText = "<COUNT> sites will be blocked."
            if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
                blockSitesCountText = onboardingBlockedUrlsInfo.value(forKey: "blockSitesCountText") as? String ?? blockSitesCountText
            }
            
            blockSitesCountText = blockSitesCountText.replacingOccurrences(of: "<COUNT>", with: "\(selectedUrlsCount)")
        }

        lblBlockedCount.stringValue = blockSitesCountText
    }
    override func viewWillAppear() {
        if let item = outlineView.item(atRow: 2){
            outlineView.expandItem(item)
        }
        
        if let item = outlineView.item(atRow: 1){
            outlineView.expandItem(item)
        }
        if let item = outlineView.item(atRow: 0){
            outlineView.expandItem(item)
        }
        
    
        btnAddUrl.isEnabled = false
        textFieldUrl.stringValue = ""
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingBlockedUrlsVc:- Button Continue clicked")
        
        arrBlockedUrls.removeAll()

        for dic in arrBlockedUrlsStructure{
            if let arrUrls = dic["arrUrls"] as? [NSMutableDictionary]{
                for urlDic in arrUrls{
                    arrBlockedUrls.append(["url": urlDic["url"] as? String ?? "", "isSelected": urlDic["isSelected"] as? Bool ?? false])
                }
            }
        }
        print(arrBlockedUrls)
        UserDefaults.standard.set(arrBlockedUrls, forKey: kUserdefaultsBlockedUrlsFromOnboarding)

        if onboardingDistractionTypesVcObj?.checkBoxSecond.state == .on{
            self.view.window?.contentViewController = getOnboardingBlockedAppsVcObject()
        }else{
            self.view.window?.contentViewController = getOnboardingBlockingScheduleVcObject()
        }
        //  ------------------------//
    }
    @IBAction func btnAddUrlClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingBlockedUrlsVc:- Button Add Url clicked")
        let domain = textFieldUrl.stringValue
        for dic in arrBlockedUrlsStructure{
            if let arrUrls = dic["arrUrls"] as? [NSMutableDictionary]{
                for urlDic in arrUrls{
                    if let url = urlDic["url"] as? String {
                        if url.lowercased() == domain.lowercased(){
                            btnAddUrl.isEnabled = false
                            textFieldUrl.stringValue = ""
                            return;
                        }
                    }
                }
            }
        }
        if let lastCategoryInfo = arrBlockedUrlsStructure.last{
            if lastCategoryInfo["isOther"] == nil{
                let dic:NSMutableDictionary = ["category":categoryOthers,"isSelected":false,"tag":1111,"arrUrls":[NSMutableDictionary](),"isParent":true, "isOther":true]
                
                let otherUrls: [NSMutableDictionary] = [["url":domain, "isSelected":true, "tag":lastItemTag]]
                lastItemTag += 1
                
                dic["arrUrls"] = otherUrls
                arrBlockedUrlsStructure.append(dic)
                
            }else{
                if var otherUrls = lastCategoryInfo["arrUrls"] as? [NSMutableDictionary]{
                    otherUrls.append(["url":domain, "isSelected":true, "tag":lastItemTag])
                    lastItemTag += 1
                    
                    lastCategoryInfo["arrUrls"] = otherUrls
                    arrBlockedUrlsStructure[arrBlockedUrlsStructure.count - 1] = lastCategoryInfo
                }
            }
        }
        
        outlineView.reloadData()
        if let item = outlineView.item(atRow: outlineView.numberOfRows - 1){
            outlineView.expandItem(item)
        }
        outlineView.scrollRowToVisible(outlineView.numberOfRows - 1)
        
        allApiObject.capturePosthog(event: "new-block-url-added", metadata: [:])
        
        btnAddUrl.isEnabled = false
        textFieldUrl.stringValue = ""
        UserDefaults.standard.set(true, forKey: kUserdefaultsEditBlockedUrlsOnce)
        btnContinue.isEnabled = true
        recheckBlockedUrlsCount()
    }
    
    func changeStateInCategory(datadict:inout [NSMutableDictionary],newstate:Bool){
        for data in datadict{
            data ["isSelected"] = newstate
        }
    }
    func checkForState(tag:Int,datadict:inout [NSMutableDictionary],sender:NSButton){
        for data in datadict{
            if data.value(forKey: "tag") as? Int == tag{
 
                if (data["isParent"] as? Bool ?? false) == true{
                    if var dic = data.value(forKey: "arrUrls") as? [NSMutableDictionary]{
                        if sender.state == .off || sender.state == .mixed{
                            data ["isSelected"] = false
                            changeStateInCategory(datadict: &dic, newstate: false)
                        }else if sender.state == .on{
                            data ["isSelected"] = true
                            changeStateInCategory(datadict: &dic, newstate: true)
                        }
                    }
                }else{
                    if data.value(forKey: "isSelected") as? Bool  == false{
                        data ["isSelected"] = true
                    }else{
                        data ["isSelected"] = false
                    }
                }
                break;
            }else{
                if var dic = data.value(forKey: "arrUrls") as? [NSMutableDictionary]{
                    checkForState(tag: tag, datadict: &dic, sender: sender)
                }
            }
        }
    }
    
    @objc func btnCheckBoxClicked(sender:NSButton){
        let tag = sender.tag
        print(tag)
        checkForState(tag: tag, datadict: &arrBlockedUrlsStructure, sender: sender)
        
        outlineView.reloadData()
        UserDefaults.standard.set(true, forKey: kUserdefaultsEditBlockedUrlsOnce)
        
    
        for dic in arrBlockedUrlsStructure{
            if let arrUrls = dic["arrUrls"] as? [NSMutableDictionary]{
                for urlDic in arrUrls{
                    if urlDic["isSelected"] as? Bool == true{
                        btnContinue.isEnabled = true
                        recheckBlockedUrlsCount()
                        return;
                    }
                }
            }
        }
        btnContinue.isEnabled = false
        recheckBlockedUrlsCount()
    }
    
}

extension onboardingBlockedUrlsVc:NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == textFieldUrl{
            if textFieldUrl.stringValue.isEmpty{
                btnAddUrl.isEnabled = false
            }else{
                
                let domain = textFieldUrl.stringValue
                if domain.contains("*"){
                    let string = domain.replacingOccurrences(of: "*", with: "")
                    if string.isEmpty{
                        btnAddUrl.isEnabled = false
                    }else{
                        btnAddUrl.isEnabled = true
                    }
                }else{
                    btnAddUrl.isEnabled = true
                }
            }
        }
    }
}


extension onboardingBlockedUrlsVc: NSOutlineViewDelegate, NSOutlineViewDataSource{
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil{
            return arrBlockedUrlsStructure[index]
        }else{
            return ((item as? NSDictionary)?.value(forKey: "arrUrls") as! [NSMutableDictionary])[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil{
            return arrBlockedUrlsStructure.count
        }else{
            return ((item as? NSDictionary)?.value(forKey: "arrUrls") as? [NSMutableDictionary])?.count ?? 0
            
        }
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if (((item as? NSDictionary)?.value(forKey: "arrUrls") as? [NSMutableDictionary])?.count ?? 0) == 0{
            return false
        }else{
            return true
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier.rawValue else {
            return nil
        }
        
        let cellIdentifier = NSUserInterfaceItemIdentifier("tblCellOnboardingBlockedUrls")
        
        if let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? tblCellOnboardingBlockedUrls{
            
            let data = item as! NSDictionary

            
            if (data["isParent"] as? Bool ?? false) == true{
                setCheckBoxState(datadict: data, btnCheckBox: cell.btnCheckBox)
            }else{
                cell.btnCheckBox.allowsMixedState = false
                if let state = data["isSelected"] as? Bool{
                    if state == true{
                        cell.btnCheckBox.state = .on
                    }else{
                        cell.btnCheckBox.state = .off
                    }
                }
            }

            let tag = data["tag"] as? Int ?? 0

            cell.btnCheckBox.tag = tag
            cell.btnCheckBox.target = self
            cell.btnCheckBox.action = #selector(btnCheckBoxClicked(sender:))

            //cell.lblurl.stringValue = "\(totalfileincurrentRow),\(selectedfileincurrentrow)"
            
            if let url = data["url"] as? String {
                cell.btnCheckBox.title = url
            }else if let category = data["category"] as? String{
                cell.btnCheckBox.title = category
            }

            return cell
        }
        
        
        
        
        return NSTableCellView()
    }
    
 
    func setCheckBoxState(datadict:NSDictionary, btnCheckBox:NSButton){
        var totalfileincurrentRow = 0
        var selectedfileincurrentrow = 0
        if  datadict.value(forKey: "arrUrls") is  [NSMutableDictionary]{
            let arrdic = datadict.value(forKey: "arrUrls") as! [NSMutableDictionary]
            totalfileincurrentRow = arrdic.count
            for dic in arrdic{
                if let state = dic["isSelected"] as? Bool{
                    if state == true{
                        selectedfileincurrentrow += 1
                    }
                }
            }
        }
        
        if totalfileincurrentRow == 0{
            btnCheckBox.state = .on
        }else if totalfileincurrentRow == selectedfileincurrentrow{
            btnCheckBox.allowsMixedState = false
            btnCheckBox.state = .on
        }else if selectedfileincurrentrow == 0{
            btnCheckBox.allowsMixedState = false
            btnCheckBox.state = .off
        }else if selectedfileincurrentrow < totalfileincurrentRow{
            btnCheckBox.allowsMixedState = true
            btnCheckBox.state = .mixed
        }
    }
}
