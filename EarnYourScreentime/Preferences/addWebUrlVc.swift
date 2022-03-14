//
//  addWebUrlVc.swift
//  Earn Your Screentime
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
    var currentRow = 0
    var buttonAddText = "Add"
    var buttonSaveText = "Save"
    var titleAddWebUrl = "Add Web Url"
    var titleEditWebUrl = "Edit Web Url"
    
    
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
        lblInvalidDomain.isHidden = true
        btnAdd.keyEquivalent = "\r"
        btnAdd.isEnabled = false
        textField.stringValue = ""
        
        if isAdding{
            btnAdd.title = buttonAddText
            lblTitle.stringValue = titleAddWebUrl
        }else{
            var selectedRow = focusPreferencesVcObj!.tblViewAllowedUrls.selectedRow
            if selectedRow == -1{
                selectedRow = 0
            }
            currentRow = selectedRow
            var urlsArray = [String]()
            if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["urlsArray"] as? [String]{
                urlsArray = arr
            }
            
            textField.stringValue = urlsArray[selectedRow]
            lblTitle.stringValue = titleEditWebUrl
            btnAdd.title = buttonSaveText
        }
    }
    @IBAction func btnAddClicked(_ sender: Any) {
        let domain = textField.stringValue
        if !isValidDomain(domain: domain){
            lblInvalidDomain.isHidden = false
            
            lblInvalidDomain.stringValue = "Please enter a valid domain."

            if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
                if let invalidDomainText = focusPreferencesInfo.value(forKey: "invalidDomainText") as? String{
                    lblInvalidDomain.stringValue = invalidDomainText
                }
            }
            return;
        }
        
        if isAdding{
            var urlsArray = [String]()
            if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["urlsArray"] as? [String]{
                urlsArray = arr
            }
            if !urlsArray.contains(where: {$0.localizedStandardContains(textField.stringValue) }) {
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
            arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["urlsArray"] = urlsArray
            focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
        }else{
            var urlsArray = [String]()
            if let arr = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["urlsArray"] as? [String]{
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
            
            

            arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["urlsArray"] = urlsArray
            focusPreferencesVcObj?.tblViewAllowedUrls.reloadData()
        }
        //google.com already exists in the list
        
        //        for dic in arrFocusType{
        if arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowUrlArray()
        }
        //        }
        
        
        
        self.dismiss(self)
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
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
