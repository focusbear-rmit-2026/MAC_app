//
//  confirmRunScriptVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/02/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class confirmRunScriptVc: NSViewController {

    @IBOutlet weak var textViewShellScript: NSTextView!
    @IBOutlet weak var lblAppleScript: NSTextField!
    @IBOutlet weak var lblTitleShellScript: NSTextField!
    @IBOutlet weak var lblTitleAppleScript: NSTextField!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var checkBoxDontShowThisAgain: NSButton!
    @IBOutlet weak var stackViewShellScript: NSStackView!
    @IBOutlet weak var stackViewAppleScript: NSStackView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var scriptPath:String?
    var shellCommand:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Confirm you want to run a Apple/shell script"
        lblSubTitle.stringValue = "Your settings are configured to run this command before/after this {habit/focus mode}. Are you sure you want to run this?"
        lblTitleAppleScript.stringValue = "Apple Script:"
        lblTitleShellScript.stringValue = "Shell Script:"
        btnCancel.title = "No - this looks scary"
        btnOk.title = "Yup!"
        checkBoxDontShowThisAgain.title = "Don't show this again"
        
        if let confirmRunScriptVcInfo = configjson.value(forKey: "confirmRunScriptVcInfo") as? NSDictionary{
            lblTitle.stringValue = confirmRunScriptVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = confirmRunScriptVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblTitleAppleScript.stringValue = confirmRunScriptVcInfo.value(forKey: "titleAppleScript") as? String ?? lblTitleAppleScript.stringValue
            lblTitleShellScript.stringValue = confirmRunScriptVcInfo.value(forKey: "titleShellScript") as? String ?? lblTitleShellScript.stringValue
            btnCancel.title = confirmRunScriptVcInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
            btnOk.title = confirmRunScriptVcInfo.value(forKey: "buttonContinueText") as? String ?? btnOk.title
            checkBoxDontShowThisAgain.title = confirmRunScriptVcInfo.value(forKey: "buttonDontShowAgainText") as? String ?? checkBoxDontShowThisAgain.title
        }
        
        btnCancel.buttonColor = NSColor.white.cgColor
    }
    func reloadData(focusMode:String, scriptPath:String?, shellCommand:String?){
        self.scriptPath = scriptPath
        self.shellCommand = shellCommand
        var subTitle = "Your settings are configured to run this command before/after this <FOCUSMODE>. Are you sure you want to run this?"
        if let confirmRunScriptVcInfo = configjson.value(forKey: "confirmRunScriptVcInfo") as? NSDictionary{
            subTitle = confirmRunScriptVcInfo.value(forKey: "subTitle") as? String ?? subTitle
        }
        subTitle = subTitle.replacingOccurrences(of: "<FOCUSMODE>", with: "\(focusMode)")
        lblSubTitle.stringValue = subTitle
        if let scriptPath = scriptPath{
            stackViewAppleScript.isHidden = false
            lblAppleScript.stringValue = scriptPath
        }else{
            stackViewAppleScript.isHidden = true
        }
        if let shellCommand = shellCommand{
            stackViewShellScript.isHidden = false
            textViewShellScript.string = shellCommand
        }else{
            stackViewShellScript.isHidden = true
        }
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        if checkBoxDontShowThisAgain.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
        }
        self.view.window?.close()
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        if checkBoxDontShowThisAgain.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
        }
        self.view.window?.close()
        if let scriptPath = scriptPath {
            runAppleScriptFile(path: scriptPath)
        }
        if let shellCommand = shellCommand {
            runShellCommand(command: shellCommand)
        }
    }
}
