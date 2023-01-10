//
//  addWebUrlVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/02/22.

//

import Cocoa

class addWebUrlVc: NSViewController, NSTextViewDelegate, NSTextFieldDelegate {

    @IBOutlet weak var lblEnterUrl: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblInstructionSThird: NSTextField!
    @IBOutlet weak var lblInstructionSecond: NSTextField!
    @IBOutlet weak var lblInstructionFirst: NSTextField!
    @IBOutlet weak var lblInvalidDomain: NSTextField!
    @IBOutlet weak var btnAdd: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isAdding = true
//    var viewLoddedFromFocusType = true
    
    var currentRow = 0
    var buttonAddText = "Add"
    var buttonSaveText = "Save"
    var titleAddWebUrl = "Add Web Url"
    var titleEditWebUrl = "Edit Web Url"
    
    var urlAlreadyExistsText = "<APPNAME> already exists in the list."
    
    enum URLADDINGSTATE:Int{
        case _FOCUS_ALLOW_URL = 1111, _FOCUS_BLOCK_URL, _ALL_BLOCK_URL
    }
    
    var currenUrlAddingtState:URLADDINGSTATE = ._FOCUS_BLOCK_URL
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        textView.delegate = self
        textField.delegate = self
        
        btnCancel.title = "Cancel"
//        textField.placeholderString = "google.com"
        lblInvalidDomain.stringValue = "Please enter a valid domain."
        
        lblEnterUrl.stringValue = "Enter single or multiple urls(one in each line)"
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let buttonCancelText = focusPreferencesInfo.value(forKey: "buttonCancelText") as? String{
                btnCancel.title = buttonCancelText
            }
//            if let urlPlaceHolderString = focusPreferencesInfo.value(forKey: "urlPlaceHolderString") as? String{
//                textField.placeholderString = urlPlaceHolderString
//            }

            if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainText") as? String{
                lblInvalidDomain.stringValue = invalidDomainText
            }
            
            buttonAddText = focusPreferencesInfo.value(forKey: "buttonAddText") as? String ?? buttonAddText
            buttonSaveText = focusPreferencesInfo.value(forKey: "buttonSaveText") as? String ?? buttonSaveText
            titleAddWebUrl = focusPreferencesInfo.value(forKey: "titleAddWebUrl") as? String ?? titleAddWebUrl
            titleEditWebUrl = focusPreferencesInfo.value(forKey: "titleEditWebUrl") as? String ?? titleEditWebUrl
            
            
            urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String ?? urlAlreadyExistsText
            lblEnterUrl.stringValue = focusPreferencesInfo.value(forKey: "enterMultiUrlText") as? String ?? lblEnterUrl.stringValue
            
        }
        
    }
    override func viewWillAppear() {

        
        if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
            lblInstructionFirst.stringValue = "To allow a certain website: domain.com"
            lblInstructionSecond.stringValue = "To allow all subdomains of a website: *.domain.com"
            lblInstructionSThird.stringValue = "To allow any web pages that contain text in the URL or page title: reactnative or React Native"
            lblInstructionSThird.isHidden = false

            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                lblInstructionFirst.stringValue = focusPreferencesInfo.value(forKey: "allowUrlInstructionFirstText") as? String ?? lblInstructionFirst.stringValue
                lblInstructionSecond.stringValue = focusPreferencesInfo.value(forKey: "allowUrlInstructionSecondText") as? String ?? lblInstructionSecond.stringValue
                lblInstructionSThird.stringValue = focusPreferencesInfo.value(forKey: "allowUrlInstructionThirdText") as? String ?? lblInstructionSThird.stringValue
            }
            
        }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL || currenUrlAddingtState == ._ALL_BLOCK_URL{
            lblInstructionFirst.stringValue = "To block a certain website: domain.com"
            lblInstructionSecond.stringValue = "To block all subdomains of a website: *.domain.com"
            lblInstructionSThird.isHidden = true
            
            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                lblInstructionFirst.stringValue = focusPreferencesInfo.value(forKey: "blockUrlInstructionFirstText") as? String ?? lblInstructionFirst.stringValue
                lblInstructionSecond.stringValue = focusPreferencesInfo.value(forKey: "blockUrlInstructionSecondText") as? String ?? lblInstructionSecond.stringValue
            }
        }
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        
        lblInvalidDomain.isHidden = true
        btnAdd.keyEquivalent = "\r"
        btnAdd.isEnabled = false
        
        textField.stringValue = ""
        textView.string = ""
        if isAdding{
            btnAdd.title = buttonAddText
            lblTitle.stringValue = titleAddWebUrl
            textField.isHidden = true
            textView.enclosingScrollView?.isHidden = false
            lblEnterUrl.isHidden = false
        }else{
            lblEnterUrl.isHidden = true
            textField.isHidden = false
            textView.enclosingScrollView?.isHidden = true
            if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
                var selectedRow = focusPreferencesVcObj!.tblViewAllowedUrls.selectedRow
                if selectedRow == -1{
                    selectedRow = 0
                }
                currentRow = selectedRow
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
                    urlsArray = arr
                }
                
                textField.stringValue = urlsArray[selectedRow]
                lblTitle.stringValue = titleEditWebUrl
                btnAdd.title = buttonSaveText
            }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
                var selectedRow = focusPreferencesVcObj!.tblViewAllowedUrls.selectedRow
                if selectedRow == -1{
                    selectedRow = 0
                }
                currentRow = selectedRow
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["blockUrlsArray"] as? [String]{
                    urlsArray = arr
                }
                
                textField.stringValue = urlsArray[selectedRow]
                lblTitle.stringValue = titleEditWebUrl
                btnAdd.title = buttonSaveText
            }else if currenUrlAddingtState == ._ALL_BLOCK_URL{
                var selectedRow = blockedUrlsVcObj!.tblView.selectedRow
                if selectedRow == -1{
                    selectedRow = 0
                }
                currentRow = selectedRow
                textField.stringValue = SettingsManagerObject.arrBlockedUrls[selectedRow]
                lblTitle.stringValue = titleEditWebUrl
                btnAdd.title = buttonSaveText
            }
        }
    }
    @IBAction func btnAddClicked(_ sender: Any) {
        //let domain = textView.string//textField.stringValue
        var arrDomain = [String]()
        var domain = ""
        if isAdding{
            domain = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
//            domain = domain.trimmingCharacters(in: .whitespaces)
            arrDomain = domain.components(separatedBy: "\n")
//            if let lastItem = arrDomain.last{
//                if lastItem.isEmpty{
//                    //arrDomain.removeLast()
//                }
//            }
            arrDomain = arrDomain.filter{ !$0.isEmpty }
            print(arrDomain)
        }else{
            domain = textField.stringValue
        }
//        var isStartFound = false
//        if !isAdding{
//            if domain.contains("*"){
//                let string = domain.replacingOccurrences(of: "*", with: "")
//                if string.count == 0{
//                    isStartFound = true
//                }
//            }
//        }else{
//            var i = 0
//            var arrCount = arrDomain.count
//            while i < arrCount{
//                if arrDomain[i].contains("*"){
//                    let string = arrDomain[i].replacingOccurrences(of: "*", with: "")
//                    if string.count == 0{
//                        arrDomain.remove(at: i)
//                        arrCount -= 1
//                    }else{
//                        i += 1
//                    }
//                }else{
//                    i += 1
//                }
//            }
//            if arrDomain.count == 0{
//                isStartFound = true
//            }
//        }
//
//        if isStartFound{
//            lblInvalidDomain.isHidden = false
//            if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
//                lblInvalidDomain.stringValue = "Adding * will allow all urls. Please use another combination."//"If you want to allow all urls please select \"Allow all urls\" instead." text
//                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
//                    if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainTextSecond") as? String{
//                        //lblInvalidDomain.stringValue = invalidDomainText
//                    }
//                }
//            }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
//                lblInvalidDomain.stringValue = "Adding * will block all urls. Please use another combination."
//                if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
//                    if let invalidDomainText = blockedUrlsViewInfo.value(forKey: "invalidDomainText") as? String{
//                        lblInvalidDomain.stringValue = invalidDomainText
//                    }
//                }
//            }else if currenUrlAddingtState == ._ALL_BLOCK_URL{
//                lblInvalidDomain.stringValue = "Adding * will block all urls. Please use another combination."
//                if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
//                    if let invalidDomainText = blockedUrlsViewInfo.value(forKey: "invalidDomainText") as? String{
//                        lblInvalidDomain.stringValue = invalidDomainText
//                    }
//                }
//            }
//
//
//            return;
//        }
        
        func cehckIsItemAlreadyAdded(urlsArray: [String])->Bool{
            
            var i = 0
            var arrCount = arrDomain.count
            while i < arrCount{
                if urlsArray.contains(where: {$0.lowercased() == arrDomain[i].lowercased() }) {
                    arrDomain.remove(at: i)
                    arrCount -= 1
                }else{
                    i += 1
                }
            }
            
            if arrDomain.count == 0{
                return true
            }
            
            return false
        }
        
        if isAdding{
            if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
                var urlsArray = [String]()
                var isOnboardingProcess = false
                if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) != nil{
                    if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
                        urlsArray = arr
                    }
                }else{
                    if preloadFocusModesWindowControllerObj != nil{
                        if preloadFocusModesWindowControllerObj!.window?.isVisible ?? false{
                            if preloadFocusModeAppsVcObj != nil{
                                if let arr = preloadFocusModeAppsVcObj?.arrUrls{
                                    urlsArray = arr
                                    isOnboardingProcess = true
                                }
                            }
                        }
                    }
                }
                
                if cehckIsItemAlreadyAdded(urlsArray: urlsArray){
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: domain)
                    return;
                }else{
                    for item in arrDomain{
                        urlsArray.append(item)
                    }
                }
                
              
//                if !urlsArray.contains(where: {$0.lowercased() == textView.string.lowercased() }) {
//                    urlsArray.append(textView.string)
//                }else{
//                    lblInvalidDomain.isHidden = false
//                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
//                    return;
//                }
                
                
                if isOnboardingProcess{//todo test
                    preloadFocusModeAppsVcObj?.arrUrls = urlsArray
                    preloadFocusModeAppsVcObj?.tblView.reloadData()
                    preloadFocusModeAppsVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                    preloadFocusModeAppsVcObj?.tblView.scrollRowToVisible(urlsArray.count - 1)
                }else{
                    var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                    dic["allowed_urls"] = urlsArray
                    
                    arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                    focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                    focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                    focusPreferencesVcObj?.tblViewAllowedUrls.scrollRowToVisible(urlsArray.count - 1)
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

                    reSetCurrentFocusMode(focusType:arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow])
                    
                    allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                        DispatchQueue.main.async {
                            
                        }
                    })
                    allApiObject.capturePosthog(event: "add-allowed-url-in-focus-mode", metadata: [:])
                }
                
                
                
            }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["blockUrlsArray"] as? [String]{
                    urlsArray = arr
                }
//                if !urlsArray.contains(where: {$0.lowercased() == textView.string.lowercased() }) {
//                    urlsArray.append(textView.string)
//                }else{
//                    lblInvalidDomain.isHidden = false
//                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
//                    return;
//                }
              
                if cehckIsItemAlreadyAdded(urlsArray: urlsArray){
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: domain)
                    return;
                }else{
                    for item in arrDomain{
                        urlsArray.append(item)
                    }
                }
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["blockUrlsArray"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                
                if focusPreferencesVcObj?.radioBtnBlockListApproch.state == .on{
                    focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                    focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                    focusPreferencesVcObj?.tblViewAllowedUrls.scrollRowToVisible(urlsArray.count - 1)
                }else{
                    focusPreferencesAdvancedVcObj?.tblView.reloadData()
                    focusPreferencesAdvancedVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                    focusPreferencesAdvancedVcObj?.tblView.scrollRowToVisible(urlsArray.count - 1)
                }
                
                
                
                
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

                reSetCurrentFocusMode(focusType:arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow])
                
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
                allApiObject.capturePosthog(event: "add-blocked-url-in-focus-mode", metadata: [:])
                
            }else if currenUrlAddingtState == ._ALL_BLOCK_URL{
//                if !SettingsManagerObject.arrBlockedUrls.contains(where: {$0.lowercased() == textView.string.lowercased() }) {
//                    SettingsManagerObject.arrBlockedUrls.append(textView.string)
//                }else{
//                    lblInvalidDomain.isHidden = false
//                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
//                    return;
//                }
                if cehckIsItemAlreadyAdded(urlsArray: SettingsManagerObject.arrBlockedUrls){
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: domain)
                    return;
                }else{
                    for item in arrDomain{
                        SettingsManagerObject.arrBlockedUrls.append(item)
                    }
                }
                blockedUrlsVcObj?.tblView.reloadData()
                blockedUrlsVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (SettingsManagerObject.arrBlockedUrls.count - 1)), byExtendingSelection: false)
                blockedUrlsVcObj?.tblView.scrollRowToVisible(SettingsManagerObject.arrBlockedUrls.count - 1)
                UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
                SettingsManagerObject.isSettingsChanged = true
                allApiObject.capturePosthog(event: "add-always-blocked-url", metadata: [:])
            }
        }else{
            if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
                    urlsArray = arr
                }
                var isContainAlready = false
                for i in 0..<urlsArray.count{
                    if i != currentRow{
                        if urlsArray[i].lowercased() == domain.lowercased(){
                            isContainAlready = true
                            break;
                        }
                    }
                }
                
                if !isContainAlready {
                    urlsArray[currentRow] = domain
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
                    return;
                }

                
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["allowed_urls"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                
                reSetCurrentFocusMode(focusType:arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow])
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
                
            }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["blockUrlsArray"] as? [String]{
                    urlsArray = arr
                }
                var isContainAlready = false
                for i in 0..<urlsArray.count{
                    if i != currentRow{
                        if urlsArray[i].lowercased() == domain.lowercased(){
                            isContainAlready = true
                            break;
                        }
                    }
                }
                
                if !isContainAlready {
                    urlsArray[currentRow] = domain
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
                    return;
                }
                
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["blockUrlsArray"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesAdvancedVcObj?.tblView.reloadData()
                focusPreferencesAdvancedVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                
                
                if focusPreferencesVcObj?.radioBtnBlockListApproch.state == .on{
                    focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                    focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                }else{
                    focusPreferencesAdvancedVcObj?.tblView.reloadData()
                    focusPreferencesAdvancedVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                }
                
                
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                reSetCurrentFocusMode(focusType:arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow])
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
                
            }else{
                var isContainAlready = false
                for i in 0..<SettingsManagerObject.arrBlockedUrls.count{
                    if i != currentRow{
                        if SettingsManagerObject.arrBlockedUrls[i].lowercased() == domain.lowercased(){
                            isContainAlready = true
                            break;
                        }
                    }
                }
                if !isContainAlready {
                    SettingsManagerObject.arrBlockedUrls[currentRow] = domain
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textView.string)
                    return;
                }
                blockedUrlsVcObj?.tblView.reloadData()
                blockedUrlsVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (currentRow)), byExtendingSelection: false)
//                blockedUrlsVcObj?.tblView.scrollRowToVisible(currentRow)//no need visible h isiliye to select kr paya or edit bhi
                UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
                SettingsManagerObject.isSettingsChanged = true
            }
        }

        

        
        
        
        self.dismiss(self)
        
    }
    func isValidDomain(domain:String?) -> Bool {
        
        guard domain != nil else { return false }
        
        let regEx = "[A-Z0-9a-z._%+-]+\\.[A-Za-z]{2,}"
        
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        return pred.evaluate(with: domain)
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        guard let txtfield = obj.object as? NSTextField else {
            return
        }
        lblInvalidDomain.isHidden = true
        if txtfield == textField{
            if textField.stringValue.count == 0{
                btnAdd.isEnabled = false
            }else{
                btnAdd.isEnabled = true
            }
        }
    }
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textView{
            lblInvalidDomain.isHidden = true
            if textView.string.count == 0{
                btnAdd.isEnabled = false
            }else{
                btnAdd.isEnabled = true
            }
        }
    }
}
