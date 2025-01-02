//
//  bellSuggestionsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/11/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class bellSuggestionsVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnShareLogs: Button!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Please share your feedback or if you have suggestions please write below."
        btnShareLogs.title = "Share feedback"
        
        if let bellSuggestionsVcInfo = configjson.value(forKey: "bellSuggestionsVcInfo") as? NSDictionary{
            lblTitle.stringValue = bellSuggestionsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnShareLogs.title = bellSuggestionsVcInfo.value(forKey: "buttonShareLogsText") as? String ?? btnShareLogs.title
        }
        
        
        btnCancel.title = buttonCancelText
        btnCancel.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        textView.string = ""
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func btnShareLogsClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            allApiObject.capturePosthog(event: "user-left-feedback-not-logged-in", metadata: ["feedback":self.textView.string])
            self.textView.string = ""
            self.dismiss(self)
        }else{
            let message = self.textView.string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self.textView.string
            self.view.addSubview(getLogsUploadingVcObjObj().view)
            self.view.addConstraints(subView: getLogsUploadingVcObjObj().view)
            loader.startAnimation(self)
            btnCancel.isEnabled = false
            btnShareLogs.isEnabled = false
            allApiObject.uploadAppLogs(feedback: message, completionHandler: {uploaded in
                DispatchQueue.main.async {
                    getLogsUploadingVcObjObj().view.removeFromSuperview()
                    self.textView.string = ""
                    if uploaded ?? false{//screen:screen;
                        var logsUploadDoneText = "Feedback and logs successfully shared."
                        if let bellSuggestionsVcInfo = configjson.value(forKey: "bellSuggestionsVcInfo") as? NSDictionary{
                            logsUploadDoneText = bellSuggestionsVcInfo.value(forKey: "alertSuccessText") as? String ?? logsUploadDoneText
                        }
                        self.showAlert(msg: logsUploadDoneText, completionHandler: {bool in
                            self.loader.stopAnimation(self)
                            self.btnCancel.isEnabled = true
                            self.btnShareLogs.isEnabled = true
                            self.dismiss(self)
                        })
                    }else{
                        var logsUploadErrorText = "There was some problem in uploading the logs. Please try again."
                        if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
                            logsUploadErrorText = helpVcInfo.value(forKey: "logsUploadErrorText") as? String ?? logsUploadErrorText
                        }
                        self.showAlert(msg: logsUploadErrorText, completionHandler: {bool in
                            self.loader.stopAnimation(self)
                            self.btnCancel.isEnabled = true
                            self.btnShareLogs.isEnabled = true
                            self.dismiss(self)
                        })
                    }
                    
                }
            })
        }
    }
    
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in

            completionHandler(true)
            return
        })
    }
}
