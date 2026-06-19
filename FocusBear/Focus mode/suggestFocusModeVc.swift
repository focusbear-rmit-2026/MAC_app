//
//  suggestFocusModeVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/06/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class suggestFocusModeVc: NSViewController {

    @IBOutlet weak var textFieldWorkDuration: NSTextField!
    @IBOutlet var textViewGoal: NSTextView!
    @IBOutlet weak var lblTitleGoal: NSTextField!
    @IBOutlet weak var lblTitleMinutes: NSTextField!
    @IBOutlet weak var lblTitleDuration: NSTextField!
    @IBOutlet weak var checkBox: NSButton!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var completionHandler: ((Bool, Int?, String?) -> Void)?
    var timerAutoClose:Timer?
    var buttonLinkUrl:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.isSecondaryButton = true
        lblTitleDuration.stringValue = "Focus duration:"
        lblTitleMinutes.stringValue = "minutes"
        lblTitleGoal.stringValue = "What do you want to achieve in this focus session?"
        
        textFieldWorkDuration.formatter = IntegerFormatter()
        textFieldWorkDuration.integerValue = 25
        textViewGoal.delegate = self
        
        if let info = configjson.value(forKey: "alertStartWorkFocusMode") as? NSDictionary{
            lblTitleDuration.stringValue = info.value(forKey: "focusDurationLabel") as? String ?? lblTitleDuration.stringValue
            lblTitleMinutes.stringValue = info.value(forKey: "focusDurationUnit") as? String ?? lblTitleMinutes.stringValue
            lblTitleGoal.stringValue = info.value(forKey: "sessionGoal") as? String ?? lblTitleGoal.stringValue
        }
    }
    
    func resetData(title:String, body:String?, buttonOkText:String, buttonCancelText:String?, checkBoxText: String?, autoClose:Bool, completionHandler: @escaping (Bool, Int?, String?) -> Void){
        lblTitle.stringValue = title

        if let body = body {
            lblSubTitle.isHidden = false
            lblSubTitle.stringValue = body
        }else{
            lblSubTitle.isHidden = true
        }
        textFieldWorkDuration.integerValue = 25
        textViewGoal.string = ""
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
    }
    
    @IBAction func checkBoxClicked(_ sender: Any) {
        
    }
    
    @objc func closeAlert(){
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(false, nil, nil)
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(false, nil, nil)
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()
        if completionHandler != nil{
            completionHandler!(true, textFieldWorkDuration.integerValue, textViewGoal.string)
        }
    }
}

extension suggestFocusModeVc: NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            if textView == self.textViewGoal{
                timerAutoClose?.invalidate()
                timerAutoClose = nil
            }
        }
    }
}
