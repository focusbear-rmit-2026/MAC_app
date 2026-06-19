//
//  onboardingAllowedUrlsVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 27/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingAllowedUrlsVc: NSViewController {

    @IBOutlet weak var lblChangeThisLater: NSTextField!
    @IBOutlet weak var btnCheckBoxSelectAll: NSButton!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var btnSkip: hoverUnderlineButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblTitleChooseFromList: NSTextField!
    @IBOutlet weak var btnAdd: Button!
    @IBOutlet weak var textFieldUrl: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrAllowedUrlsStructure = [[String : Any]]()
    var lastItemTag = 0
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblChangeThisLater.stringValue = "you can change this later"
        lblTitle.stringValue = "What websites do you use for work?"
        lblSubtitle.stringValue = "We'll use these to kick off your focus sessions."
        btnAdd.title = "+"
        lblTitleChooseFromList.stringValue = "Choose from suggested websites:"
        btnContinue.title = "That’s all"
        btnSkip.title = "Skip"
        
        var placeholderText = "Add a URL or keyword"
        
        if let info = configjson["onboardingAllowedUrlsVcInfo"] as? [String: Any] {
            lblTitle.stringValue = info["title"] as? String ?? lblTitle.stringValue
            lblSubtitle.stringValue = info["subtitle"] as? String ?? lblSubtitle.stringValue
            lblTitleChooseFromList.stringValue = info["titleChooseFromList"] as? String ?? lblTitleChooseFromList.stringValue
            btnContinue.title = info["buttonContinue"] as? String ?? btnContinue.title
            btnSkip.title = info["buttonSkip"] as? String ?? btnSkip.title

            placeholderText = info["textFieldPlaceholder"] as? String ?? placeholderText
        }
        
        if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
            lblChangeThisLater.stringValue = onboardingBlockedUrlsInfo.value(forKey: "bottomText") as? String ?? lblChangeThisLater.stringValue
        }
        
        setPlaceHolder(placeholderText: placeholderText)
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 1, progress: 0.5)
        

        textFieldUrl.textColor = .labelColor
        textFieldUrl.delegate = self
    }
    
    func setPlaceHolder(placeholderText:String){
        let placeHolderColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        let placeholder = NSAttributedString(
            string: placeholderText,
            attributes: [
                .foregroundColor: placeHolderColor,
                .font: textFieldUrl.font ?? NSFont.systemFont(ofSize: 13)
            ]
        )
        textFieldUrl.placeholderAttributedString = placeholder
    }
    
    func resetUrlsList(){
        // set allow urls list
        var arrAllUrls = [[String : Any]]()
        if let occupationSpecificRelevantData = occupationSpecificRelevantSitesForFocusMode{
            let userRelevantSites = occupationSpecificRelevantData["user_relevant_sites"] as? [String] ?? []
            for site in userRelevantSites{
                let urlInfo = ["url":site, "isSelected":true, "tag":lastItemTag] as [String : Any]
                lastItemTag += 1
                arrAllUrls.append(urlInfo)
            }
            
        }
        
        //Ensure the suggested websites list is reliably loaded and displayed v 3.31.476:-
        if arrAllUrls.count == 0{
            let sites = ["docs.google.com", "sheets.google.com"]
            for site in sites{
                let urlInfo = ["url":site, "isSelected":true, "tag":lastItemTag] as [String : Any]
                lastItemTag += 1
                arrAllUrls.append(urlInfo)
            }
        }
        arrAllowedUrlsStructure = arrAllUrls
        outlineView.reloadData()
    }

    override func viewWillAppear() {
        if let item = outlineView.item(atRow: 0){
            outlineView.expandItem(item)
        }
        
        allApiObject.capturePosthog(event: "onboarding-allowed-urls-shown", metadata: [:])
        btnAdd.isEnabled = false
        textFieldUrl.stringValue = ""
    }
    
    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "when you go to one of these sites, i'll start a focus session for you"
        if let onboardingAllowedUrlsVcInfo = configjson.value(forKey: "onboardingAllowedUrlsVcInfo") as? NSDictionary{
            bubbleText = onboardingAllowedUrlsVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: "when you go to one of these sites, i'll start a focus session for you", horizontalOffset: 25, fontSize: 13)
        }
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnAddClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingAllowedUrlsVc:- Button Add Url clicked")
        let domain = textFieldUrl.stringValue
        for urlDic in arrAllowedUrlsStructure{
            if let url = urlDic["url"] as? String {
                if url.lowercased() == domain.lowercased(){
                    btnAdd.isEnabled = false
                    textFieldUrl.stringValue = ""
                    return;
                }
            }
        }
        
        arrAllowedUrlsStructure.append(["url":domain, "isSelected":true, "tag":lastItemTag])
        lastItemTag += 1
        
        outlineView.reloadData()
        if let item = outlineView.item(atRow: outlineView.numberOfRows - 1){
            outlineView.expandItem(item)
        }
        outlineView.scrollRowToVisible(outlineView.numberOfRows - 1)
        
        allApiObject.capturePosthog(event: "new-allow-url-added", metadata: [:])
        
        btnAdd.isEnabled = false
        textFieldUrl.stringValue = ""
        btnContinue.isEnabled = true
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingAllowedUrlsVc:- Button skip clicked")
        allApiObject.capturePosthog(event: "onboarding-allowed-urls-skipped", metadata: [:])
        getOnboardingVcObject().navigate(to: ._BLOCKED_URLS_)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboardingAllowedUrlsVc:- Button continue clicked")
        var arrAllowedUrls:[String] = []

        for urlDic in arrAllowedUrlsStructure{
            if urlDic["isSelected"] as? Bool == true{
                arrAllowedUrls.append(urlDic["url"] as? String ?? "")
            }
        }
        
        if occupationSpecificRelevantSitesForFocusMode != nil{
            occupationSpecificRelevantSitesForFocusMode?["user_relevant_sites"] = arrAllowedUrls
        }else{
            occupationSpecificRelevantSitesForFocusMode = [String:Any]()
            occupationSpecificRelevantSitesForFocusMode?["user_relevant_sites"] = arrAllowedUrls
        }
        
        getOnboardingVcObject().navigate(to: ._BLOCKED_URLS_)
    }
    
    @IBAction func btnCheckBoxSelectAllClicked(_ sender: NSButton) {
        if sender.state == .off || sender.state == .mixed{
            allApiObject.capturePosthog(event: "allowed-category-unchecked", metadata: [:])
            for i in 0..<arrAllowedUrlsStructure.count{
                arrAllowedUrlsStructure[i]["isSelected"] = false
            }
        }else if sender.state == .on{
            for i in 0..<arrAllowedUrlsStructure.count{
                arrAllowedUrlsStructure[i]["isSelected"] = true
            }
            allApiObject.capturePosthog(event: "allowed-category-checked", metadata: [:])
        }
        setCheckBoxState()
        outlineView.reloadData()
    }
    
    func setCheckBoxState(){
        var totalfileincurrentRow = 0
        var selectedfileincurrentrow = 0
        totalfileincurrentRow = arrAllowedUrlsStructure.count
        for dic in arrAllowedUrlsStructure{
            if let state = dic["isSelected"] as? Bool{
                if state == true{
                    selectedfileincurrentrow += 1
                }
            }
        }
        
        if totalfileincurrentRow == 0{
            btnCheckBoxSelectAll.state = .on
            btnContinue.isEnabled = false
        }else if totalfileincurrentRow == selectedfileincurrentrow{
            btnCheckBoxSelectAll.allowsMixedState = false
            btnCheckBoxSelectAll.state = .on
            btnContinue.isEnabled = true
        }else if selectedfileincurrentrow == 0{
            btnCheckBoxSelectAll.allowsMixedState = false
            btnCheckBoxSelectAll.state = .off
            btnContinue.isEnabled = false
        }else if selectedfileincurrentrow < totalfileincurrentRow{
            btnCheckBoxSelectAll.allowsMixedState = true
            btnCheckBoxSelectAll.state = .mixed
            btnContinue.isEnabled = true
        }
    }
}

extension onboardingAllowedUrlsVc: NSOutlineViewDelegate, NSOutlineViewDataSource{
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil{
            return arrAllowedUrlsStructure[index]
        }else{
            return ((item as? NSDictionary)?.value(forKey: "arrUrls") as! [NSMutableDictionary])[index]
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil{
            return arrAllowedUrlsStructure.count
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
    
    @objc func btnCheckBoxClicked(sender:NSButton){
        let tag = sender.tag
        print(tag)
        for i in 0..<arrAllowedUrlsStructure.count{
            var data = arrAllowedUrlsStructure[i]
            if data["tag"] as? Int == tag{
 
                if data["isSelected"] as? Bool  == false{
                    data ["isSelected"] = true
                    arrAllowedUrlsStructure[i] = data
                    allApiObject.capturePosthog(event: "allow-url-checked", metadata: [:])
                }else{
                    data ["isSelected"] = false
                    arrAllowedUrlsStructure[i] = data
                    allApiObject.capturePosthog(event: "allow-url-unchecked", metadata: [:])
                }
                break;
            }
        }
        
        outlineView.reloadData()
        setCheckBoxState()
    }
}

extension onboardingAllowedUrlsVc:NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == textFieldUrl{
            if textFieldUrl.stringValue.isEmpty{
                btnAdd.isEnabled = false
            }else{
                
                let domain = textFieldUrl.stringValue
                if domain.contains("*"){
                    let string = domain.replacingOccurrences(of: "*", with: "")
                    if string.isEmpty{
                        btnAdd.isEnabled = false
                    }else{
                        btnAdd.isEnabled = true
                    }
                }else{
                    btnAdd.isEnabled = true
                }
            }
        }
    }
}
