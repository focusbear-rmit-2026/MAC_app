//
//  chooseCommunityVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/02/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class chooseCommunityVc: NSViewController {

    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "What community system would you prefer to use?"
        textField.placeholderString = "Enter community name"
        btnOk.title = buttonOkText
        btnCancel.title = buttonCancelText
        
        btnCancel.isSecondaryButton = true
        
        popUpBtn.removeAllItems()
        popUpBtn.addItem(withTitle: "")
        
        var arrayCommunityOptions = ["Sub-Reddit", "Facebook Messenger Community", "Facebook Group", "Other"]

        if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
            lblTitle.stringValue = helpVcInfo.value(forKey: "titleChooseCommunity") as? String ?? lblTitle.stringValue
            textField.placeholderString = helpVcInfo.value(forKey: "placeHolderEnterCommunity") as? String ?? textField.placeholderString
            arrayCommunityOptions = helpVcInfo.value(forKey: "arrayCommunityOptions") as? [String] ?? arrayCommunityOptions
        }

        popUpBtn.addItems(withTitles: arrayCommunityOptions)
        
        textField.delegate = self
    }
    override func viewWillAppear() {
        textField.isHidden = true
        btnOk.isEnabled = false
        popUpBtn.selectItem(at: 0)
    }
    @IBAction func popUpBtnClicked(_ sender: Any) {
        if popUpBtn.indexOfSelectedItem == 0{
            btnOk.isEnabled = false
        }else if popUpBtn.indexOfSelectedItem == popUpBtn.itemTitles.count - 1{
            textField.isHidden = false
            textField.stringValue = ""
            textField.setFocus()
            btnOk.isEnabled = false
        }else{
            textField.isHidden = true
            btnOk.isEnabled = true
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        var community = ""
        
        if popUpBtn.indexOfSelectedItem == popUpBtn.itemTitles.count - 1{
            community = textField.stringValue
        }else{
            community = popUpBtn.titleOfSelectedItem ?? ""
        }
        if community.isEmpty {
            return;
        }
        allApiObject.capturePosthog(event: "choose-community-system", metadata: ["community":community])
        self.dismiss(self)
    }
}//allApiObject.capturePosthog(event: "complete-first-routine", metadata: ["routine-type":"first_routine"])

extension chooseCommunityVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == self.textField{
                if self.textField.stringValue.isEmpty{
                    btnOk.isEnabled = false
                }else{
                    btnOk.isEnabled = true
                }
            }
        }
    }
}
