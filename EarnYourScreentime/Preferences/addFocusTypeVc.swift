//
//  addFocusTypeVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 18/02/22.

//

import Cocoa

class addFocusTypeVc: NSViewController, NSTextFieldDelegate  {

    @IBOutlet weak var lblViewTitle: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    @IBOutlet weak var lblTitleColor: NSTextField!
    @IBOutlet weak var textFieldFocusType: NSTextField!
    @IBOutlet weak var colorWell: NSColorWell!
    @IBOutlet weak var btnAdd: NSButton!
    @IBOutlet weak var btnCancel: NSButton!
    @IBOutlet weak var lblError: NSTextField!
    
    var isAdding = true
    var buttonAddText = "Add"
    var buttonSaveText = "Save"
    var titleAddFocusType = "Add Focus Type"
    var titleEditFocusType = "Edit Focus Type"
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.title = "Cancel"
        
        
        lblTitleName.stringValue = "Title:"
        lblTitleColor.stringValue = "Color:"
        
        lblError.stringValue = "Focus type with the same name already exist."
        lblError.isHidden = true
        textFieldFocusType.delegate = self
        
        
        if let focusPreferencesInfo = configjson.value(forKey: "focusPreferencesInfo") as? NSDictionary{
            if let buttonCancelText = focusPreferencesInfo.value(forKey: "buttonCancelText") as? String{
                btnCancel.title = buttonCancelText
            }
            if let titleTitle = focusPreferencesInfo.value(forKey: "titleTitle") as? String{
                lblTitleName.stringValue = titleTitle
            }
            if let titleColor = focusPreferencesInfo.value(forKey: "titleColor") as? String{
                lblTitleColor.stringValue = titleColor
            }
            
            if let errorSameFocusType = focusPreferencesInfo.value(forKey: "errorSameFocusType") as? String{
                lblError.stringValue = errorSameFocusType
            }
            
            buttonAddText = focusPreferencesInfo.value(forKey: "buttonAddText") as? String ?? buttonAddText
            buttonSaveText = focusPreferencesInfo.value(forKey: "buttonSaveText") as? String ?? buttonSaveText
            titleAddFocusType = focusPreferencesInfo.value(forKey: "titleAddFocusType") as? String ?? titleAddFocusType
            titleEditFocusType = focusPreferencesInfo.value(forKey: "titleEditFocusType") as? String ?? titleEditFocusType
        }
        
    }
    
    override func viewWillAppear() {
        lblError.isHidden = true
        btnAdd.keyEquivalent = "\r"
        btnAdd.isEnabled = false
        
        if isAdding{
            textFieldFocusType.stringValue = ""
            btnAdd.title = buttonAddText
            lblViewTitle.stringValue = titleAddFocusType
        }else{
            textFieldFocusType.stringValue = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["name"] as? String ?? ""
            if let colorString = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]["color"] as? String{
                let color = HexToColor(hexString: colorString)
                colorWell.color = color
            }
            btnAdd.title = buttonSaveText
            lblViewTitle.stringValue = titleEditFocusType
            
        }
    }

    @IBAction func colorWellClicked(_ sender: Any) {
        if !isAdding{
            if !textFieldFocusType.stringValue.isEmpty{
                btnAdd.isEnabled = true
            }
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    @IBAction func btnAddClicked(_ sender: Any) {
        if isAdding{
            let newName = textFieldFocusType.stringValue.lowercased
            for dic in arrFocusType{
                if let name = dic["name"] as? String{
                    if name.lowercased() == newName(){
                        lblError.isHidden = false
                        return;
                    }
                }
            }
        }else{
            let selectedRow = focusPreferencesVcObj!.tblViewFocusType.selectedRow
            let newName = textFieldFocusType.stringValue.lowercased
            for i in 0..<arrFocusType.count{
                if i != selectedRow{
                    let dic = arrFocusType[i]
                    if let name = dic["name"] as? String{
                        if name.lowercased() == newName(){
                            lblError.isHidden = false
                            return;
                        }
                    }
                }
            }
        }
        
        if isAdding{
            let dic:[String:Any] = ["name":textFieldFocusType.stringValue, "color": getColorString(color: colorWell.color), "appsArray": [], "urlsArray": [], "isOn": false, "isAllowedAllApps":true, "isAllowedAllUrls":true]
            let row = arrFocusType.count-1
            arrFocusType.insert(dic, at: row)//append(dic)
            focusPreferencesVcObj?.tblViewFocusType.insertRows(at: IndexSet(arrayLiteral: row), withAnimation: .effectFade)
            focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: row), byExtendingSelection: false)
            focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(row)
            focusPreferencesVcObj?.checkState()
        }else{
//            let dic:[String:Any] = ["name":textFieldFocusType.stringValue, "color": getColorString(color: colorWell.color), "appsArray": [], "urlsArray": [], "isOn": false]
            var dic = arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow]
            dic["name"] = textFieldFocusType.stringValue
            dic["color"] = getColorString(color: colorWell.color)
            arrFocusType[focusPreferencesVcObj!.tblViewFocusType.selectedRow] = dic
            let selectedRow = focusPreferencesVcObj!.tblViewFocusType.selectedRow
            focusPreferencesVcObj?.tblViewFocusType.reloadData(forRowIndexes: IndexSet(arrayLiteral: selectedRow), columnIndexes: IndexSet(arrayLiteral: 0))
            focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(arrayLiteral: selectedRow), byExtendingSelection: false)
            focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(arrFocusType.count-1)
            focusPreferencesVcObj?.checkState()
        }
        
        lblError.isHidden = true
        self.dismiss(self)
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        resetPomodoroVcFocusListIfNeeded()
        
        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
            if startingFocusWindowControllerObj?.contentViewController == startingFocusModeVcObj{
                startingFocusWindowControllerObj?.close()
            }
        }
    }
    func controlTextDidChange(_ obj: Notification) {
        guard let txtfield = obj.object as? NSTextField else {
            return
        }
        if txtfield == textFieldFocusType{
            lblError.isHidden = true
            if textFieldFocusType.stringValue.count == 0{
                btnAdd.isEnabled = false
            }else{
                btnAdd.isEnabled = true
            }
        }
    }
}
