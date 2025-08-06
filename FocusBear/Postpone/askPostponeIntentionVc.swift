//
//  askPostponeIntentionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/01/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askPostponeIntentionVc: NSViewController, NSTextViewDelegate {

    @IBOutlet weak var lblMinimumCharacter: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    let minimumCharacterCount = 9
    var minutes = 0
    var secondsToPostpone:Int? = nil
    var showAskFocusModeView:Bool = false
    var lastCurrentState:CURRENTSTATE = ._NOTHING_
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnContinue.title = "Continue"
        lblMinimumCharacter.stringValue = "(Minimum 10 characters)"
        lblTitle.stringValue = "What do you intend to do instead of doing your habits?"
        
        if let askPostponeIntentionVcInfo = configjson.value(forKey: "askPostponeIntentionVcInfo") as? NSDictionary{
            lblTitle.stringValue = askPostponeIntentionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblMinimumCharacter.stringValue = askPostponeIntentionVcInfo.value(forKey: "minimumCharacterText") as? String ?? lblMinimumCharacter.stringValue
            btnContinue.title = askPostponeIntentionVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        textView.delegate = self
    }
    
    func resetData(minutes:Int, secondsToPostpone:Int?, showAskFocusModeView:Bool, lastCurrentState:CURRENTSTATE){
        self.secondsToPostpone = nil
        self.minutes = minutes
        self.secondsToPostpone = secondsToPostpone
        self.showAskFocusModeView = showAskFocusModeView
        self.lastCurrentState = lastCurrentState
        textView.string = ""
        
        if SettingsManagerObject.isRequiredIntentionInPostpone{
            btnContinue.isEnabled = false
            lblMinimumCharacter.isHidden = false
        }else{
            btnContinue.isEnabled = true
            lblMinimumCharacter.isHidden = true
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        self.dismiss(self)
        allApiObject.capturePosthog(event: "postpone-intention", metadata: ["number-of-characters":"\(textView.string.count)"])
        if lastCurrentState == ._MORNING_HABIT_{
            getHabitsVcObject().postponeMorningHabitFor(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, showAskIntention: false)
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled && !textView.string.isEmpty{
                if pomodoroWindowControllerObj != nil{
                    if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                        pomodoroVcObj?.isIntentionFromMorningPostpone = true
                        pomodoroVcObj?.textViewAchieve.string = textView.string
                    }
                }
            }
            
        }else if lastCurrentState == ._EVENING_HABIT_{
            getHabitsVcObject().postponeEveningHabitFor(minutes: minutes, secondsToPostpone: secondsToPostpone, showAskFocusModeView: showAskFocusModeView, showAskIntention: false)
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
            if showAskFocusModeView && SettingsManagerObject.isGeekModeEnabled && !textView.string.isEmpty{
                if pomodoroWindowControllerObj != nil{
                    if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                        pomodoroVcObj?.isIntentionFromMorningPostpone = true
                        pomodoroVcObj?.textViewAchieve.string = textView.string
                    }
                }
            }
        }else if lastCurrentState == ._FOCUS_SUMMARY_{
            getHabitsVcObject().postponeFocusSummaryFor(minutes: minutes, showAskIntention: false)
            if easyPostponeWcObj?.window?.isVisible ?? false{
                easyPostponeWcObj?.window?.close()
            }
            if SettingsManagerObject.isGeekModeEnabled && !textView.string.isEmpty{
                if pomodoroWindowControllerObj != nil{
                    if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                        pomodoroVcObj?.isIntentionFromMorningPostpone = true
                        pomodoroVcObj?.textViewAchieve.string = textView.string
                    }
                }
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
        if mainWindowControllerObj?.window?.isVisible ?? false{
            mainViewControllerObj?.abortCancel()
        }
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textView && SettingsManagerObject.isRequiredIntentionInPostpone{
            if textView.string.count > minimumCharacterCount{
                btnContinue.isEnabled = true
            }else{
                btnContinue.isEnabled = false
            }
        }
    }
}
