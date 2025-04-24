//
//  customAlertVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/08/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class customAlertVc: NSViewController {

    @IBOutlet weak var btnLink: underLineButton!
    @IBOutlet weak var boxLinkButton: NSBox!
    @IBOutlet weak var checkBox: NSButton!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var completionHandler: ((Bool) -> Void)?
    var timerAutoClose:Timer?
    var buttonLinkUrl:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.buttonColor = NSColor.white.cgColor
    }
    
    func resetData(title:String, body:String?, buttonOkText:String, buttonCancelText:String?, checkBoxText: String?, autoClose:Bool, buttonLinkUrl:String?, buttonLinkText:String?, completionHandler: @escaping (Bool) -> Void){
        self.buttonLinkUrl = buttonLinkUrl
        if buttonLinkUrl != nil{
            boxLinkButton.isHidden = false
        }else{
            boxLinkButton.isHidden = true
        }
        if let title = buttonLinkText{
            btnLink.title = title
        }
        lblTitle.stringValue = title

        if let body = body {
            lblSubTitle.isHidden = false
            lblSubTitle.stringValue = body
        }else{
            lblSubTitle.isHidden = true
        }
        
        btnOk.title = buttonOkText
        if let buttonCancelText = buttonCancelText {
            btnCancel.isHidden = false
            btnCancel.title = buttonCancelText
        }else{
            btnCancel.isHidden = true
        }
        if let checkBoxText = checkBoxText {
            checkBox.isHidden = false
            checkBox.title = checkBoxText
        }else{
            checkBox.isHidden = true
        }
        timerAutoClose?.invalidate()
        timerAutoClose = nil
        if autoClose{
            self.timerAutoClose = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.closeAlert), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerAutoClose!), forMode: RunLoop.Mode.common)
        }
        
        self.completionHandler = completionHandler
    }
    
    override func viewWillDisappear() {
        timerAutoClose?.invalidate()
        timerAutoClose = nil
        boxLinkButton.isHidden = true
    }
    @IBAction func checkBoxClicked(_ sender: Any) {
        
    }
    
    @objc func closeAlert(){
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(false)
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(false)
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(true)
        }
    }
    
    @IBAction func btnLinkClicked(_ sender: Any) {
        if let buttonLinkUrl = buttonLinkUrl {
            if let url = URL(string: buttonLinkUrl){
                NSWorkspace.shared.open(url)
            }
        }
    }
}
