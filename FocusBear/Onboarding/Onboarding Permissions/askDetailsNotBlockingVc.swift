//
//  askDetailsNotBlockingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/12/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askDetailsNotBlockingVc: NSViewController {

    @IBOutlet weak var btnOk: NSButton!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Sorry about that 😓 Could you please share your feedback in the box below? We'll do our best to fix it for you!"
        if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "shareFeedbackText") as? String ?? lblTitle.stringValue
        }
        
        btnOk.title = buttonOkText
    }
    override func viewWillAppear() {
        textField.stringValue = ""
        textField.stringValue = "I tried blocking distractions using {insert your browser}. It didn't work because ... I had enabled all the permissions"
        if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
            textField.stringValue = dic.value(forKey: "placeHolderFeedbackText") as? String ?? textField.stringValue
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.dismiss(self)
        allApiObject.capturePosthog(event: "feedback-blocking-not-working", metadata: ["feedback":textField.stringValue])
        getWelcomeOnboardingWindowObject().close()
        if isExplainingPermissionsWindowShowingFromPomodoro{
            if SettingsManagerObject.isGeekModeEnabled{
                appdelegate?.menuShowPomodoroModeView()
                pomodoroVcObj?.goalText = pomodoroVcObj?.intentionToShowAgain ?? ""
            }else{
                appdelegate?.menuShowSimplePomodoroModeView()
                simplePomodoroVcObj?.goalText = simplePomodoroVcObj?.intentionToShowAgain ?? ""
            }
        }else if isExplainingPermissionsWindowShowingFromBlockingSchedule{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                leftMenuVcObj?.showBlocksView()
            }else{
                mainWindowControllerObj?.showWindow(self)
                leftMenuVcObj?.showBlocksView()
            }
            addLog(text: "Showing preferences")
            tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()
        }
        
        addLog(text: "Attempting to upload logs.")
        allApiObject.uploadAppLogs(feedback: textField.stringValue, completionHandler: {uploaded in
            DispatchQueue.main.async {
                if uploaded ?? false{
                    addLog(text: "Feedback and logs successfully shared.")
                }else{
                    addLog(text: "There was some problem in uploading the logs. Please try again.")
                }
            }
        })
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
