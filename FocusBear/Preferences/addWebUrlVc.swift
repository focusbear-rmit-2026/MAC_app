//
//  addWebUrlVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/02/22.

//

import Cocoa

class addWebUrlVc: NSViewController, NSTextFieldDelegate {

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
    
    enum URLADDINGSTATE:Int{
        case _FOCUS_ALLOW_URL = 1111, _FOCUS_BLOCK_URL, _ALL_BLOCK_URL
    }
    
    var currenUrlAddingtState:URLADDINGSTATE = ._FOCUS_BLOCK_URL
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        textField.delegate = self

        btnCancel.title = "Cancel"
        textField.placeholderString = "google.com"
        lblInvalidDomain.stringValue = "Please enter a valid domain."
        
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let buttonCancelText = focusPreferencesInfo.value(forKey: "buttonCancelText") as? String{
                btnCancel.title = buttonCancelText
            }
            if let urlPlaceHolderString = focusPreferencesInfo.value(forKey: "urlPlaceHolderString") as? String{
                textField.placeholderString = urlPlaceHolderString
            }

            if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainText") as? String{
                lblInvalidDomain.stringValue = invalidDomainText
            }
            
            buttonAddText = focusPreferencesInfo.value(forKey: "buttonAddText") as? String ?? buttonAddText
            buttonSaveText = focusPreferencesInfo.value(forKey: "buttonSaveText") as? String ?? buttonSaveText
            titleAddWebUrl = focusPreferencesInfo.value(forKey: "titleAddWebUrl") as? String ?? titleAddWebUrl
            titleEditWebUrl = focusPreferencesInfo.value(forKey: "titleEditWebUrl") as? String ?? titleEditWebUrl
            
        }
        
    }
    override func viewWillAppear() {
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
        
        if isAdding{
            btnAdd.title = buttonAddText
            lblTitle.stringValue = titleAddWebUrl
        }else{
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
        let domain = textField.stringValue
        if domain.contains("*"){

            let string = domain.replacingOccurrences(of: "*", with: "")
            if string.count == 0{
                lblInvalidDomain.isHidden = false
                if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
                    lblInvalidDomain.stringValue = "If you want to allow all urls please select \"Allow all urls\" instead."
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainTextSecond") as? String{
                            lblInvalidDomain.stringValue = invalidDomainText
                        }
                    }
                }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
                    lblInvalidDomain.stringValue = "Adding * will block all urls. Please use another combination."
                    if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
                        if let invalidDomainText = blockedUrlsViewInfo.value(forKey: "invalidDomainText") as? String{
                            lblInvalidDomain.stringValue = invalidDomainText
                        }
                    }
                }else if currenUrlAddingtState == ._ALL_BLOCK_URL{
                    lblInvalidDomain.stringValue = "Adding * will block all urls. Please use another combination."
                    if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
                        if let invalidDomainText = blockedUrlsViewInfo.value(forKey: "invalidDomainText") as? String{
                            lblInvalidDomain.stringValue = invalidDomainText
                        }
                    }
                }
                return;
            }
        }else if !domain.contains("://"){
//            if !isValidDomain(domain: domain){
//                lblInvalidDomain.isHidden = false
//
//                lblInvalidDomain.stringValue = "Please enter a valid domain."
//
//                if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
//                    if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainText") as? String{
//                        lblInvalidDomain.stringValue = invalidDomainText
//                    }
//                }
//                return;
//            }
        }
        if isAdding{
            if currenUrlAddingtState == ._FOCUS_ALLOW_URL{
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["allowed_urls"] as? [String]{
                    urlsArray = arr
                }
                if !urlsArray.contains(where: {$0.lowercased() == textField.stringValue.lowercased() }) {
                    urlsArray.append(textField.stringValue)
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
                    return;
                }
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["allowed_urls"] = urlsArray
                
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                focusPreferencesVcObj?.tblViewAllowedUrls.scrollRowToVisible(urlsArray.count - 1)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                if arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["isOn"] as? Bool == true{
                    appdelegate!.fillAllowUrlArray()
                }
                
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
            }else if currenUrlAddingtState == ._FOCUS_BLOCK_URL{
                var urlsArray = [String]()
                if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["blockUrlsArray"] as? [String]{
                    urlsArray = arr
                }
                if !urlsArray.contains(where: {$0.lowercased() == textField.stringValue.lowercased() }) {
                    urlsArray.append(textField.stringValue)
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
                    return;
                }
              
                
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["blockUrlsArray"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesAdvancedVcObj?.tblView.reloadData()
                focusPreferencesAdvancedVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (urlsArray.count - 1)), byExtendingSelection: false)
                focusPreferencesAdvancedVcObj?.tblView.scrollRowToVisible(urlsArray.count - 1)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                if arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["isOn"] as? Bool == true{
                    appdelegate!.fillAllowUrlArray()// fill block url array
                }
                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
                
            }else if currenUrlAddingtState == ._ALL_BLOCK_URL{
                if !SettingsManagerObject.arrBlockedUrls.contains(where: {$0.lowercased() == textField.stringValue.lowercased() }) {
                    SettingsManagerObject.arrBlockedUrls.append(textField.stringValue)
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
                    return;
                }
                blockedUrlsVcObj?.tblView.reloadData()
                blockedUrlsVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (SettingsManagerObject.arrBlockedUrls.count - 1)), byExtendingSelection: false)
                blockedUrlsVcObj?.tblView.scrollRowToVisible(SettingsManagerObject.arrBlockedUrls.count - 1)
                UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
                SettingsManagerObject.isSettingsChanged = true
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
                    urlsArray[currentRow] = textField.stringValue
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
                    return;
                }

                
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["allowed_urls"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
                focusPreferencesVcObj?.tblViewAllowedUrls.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                if arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["isOn"] as? Bool == true{
                    appdelegate!.fillAllowUrlArray()
                }
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
                    urlsArray[currentRow] = textField.stringValue
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
                    return;
                }
                
                
                var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
                dic["blockUrlsArray"] = urlsArray
                arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
                focusPreferencesAdvancedVcObj?.tblView.reloadData()
                focusPreferencesAdvancedVcObj?.tblView.selectRowIndexes(IndexSet(arrayLiteral: (self.currentRow)), byExtendingSelection: false)
                
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                if arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["isOn"] as? Bool == true{
                    appdelegate!.fillAllowUrlArray()
                }
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
                    SettingsManagerObject.arrBlockedUrls[currentRow] = textField.stringValue
                }else{
                    lblInvalidDomain.isHidden = false
                    lblInvalidDomain.stringValue = "\(textField.stringValue) already exists in the list."
                    if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                        if let urlAlreadyExistsText = focusPreferencesInfo.value(forKey: "urlAlreadyExistsText") as? String{
                            lblInvalidDomain.stringValue = urlAlreadyExistsText.replacingOccurrences(of: "<APPNAME>", with: textField.stringValue)
                        }
                    }
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
}
