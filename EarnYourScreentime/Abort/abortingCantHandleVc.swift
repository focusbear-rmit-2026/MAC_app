//
//  abortingStartingSmallVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 10/01/22.
//  
//

import Cocoa

class abortingCantHandleVc: NSViewController, NSTextViewDelegate {

    @IBOutlet weak var lblTitleEmail: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblDescription2: NSTextField!
    @IBOutlet weak var btnMain: NSButton!
    @IBOutlet weak var textFieldEmail: NSTextField!
    @IBOutlet var textViewFeedback: NSTextView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblDescription3: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    
    var isViewStartingSmall = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        textViewFeedback.delegate = self
        lblTitle.stringValue = "Aborting.."
        lblTitleEmail.stringValue = "Your Email (if you want us to reply):"
        
        if let abortInfo = configjson.value(forKey: "abortInfo") as? NSDictionary{
            if let abortingTitle = abortInfo.value(forKey: "abortingTitle") as? String{
                lblTitle.stringValue = abortingTitle
            }
            if let abortingConfirmInfo = abortInfo.value(forKey: "abortingConfirmInfo") as? NSDictionary{
                if let dropDown_3 = abortingConfirmInfo.value(forKey: "dropDown_3") as? NSDictionary{
                    if let emailTitle = dropDown_3.value(forKey: "emailTitle") as? String{
                       lblTitleEmail.stringValue = emailTitle
                    }
                }
            }
        }
    }
    
    override func viewWillAppear() {
        if kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
        }
    }
    func resetView(isAnyHabitRemoved:Bool){
        textViewFeedback.string = ""
        textFieldEmail.stringValue = ""
        btnMain.isEnabled = false
        
        
        
        
        if isViewStartingSmall{
            lblSubtitle.stringValue = "Starting small.."
            if isAnyHabitRemoved{
                lblDescription.stringValue = "We’ve reset your habits and break activities for you. They’re now each only 30 seconds long which should make it more manageable. We removed a few activities so that the total morning routine is 5 minutes long"
            }else{
                lblDescription.stringValue = "We’ve reset your habits and break activities for you. They’re now each only 30 seconds long which should make it more manageable."
            }
            let text = "You can alter your settings later from the top toolbar icon <icon>"

            lblDescription2.attributedStringValue = attechIconWithString(text: text)
            lblDescription3.stringValue = "Can you share some feedback about why your habits were too hard?﹡"
            
            btnMain.title = "Start shortened routine"
        }else{
            lblSubtitle.stringValue = "Giving up on your morning routine"
            lblDescription.stringValue = "No problems. You’re in control."
            lblDescription2.attributedStringValue = attechIconWithString(text: "Feel free to reactivate Earn Your Screen Time from top toolbar icon <icon>")
            lblDescription3.stringValue = "Can you share feedback about the app?﹡"
            btnMain.title = "Deactivate routine + breaks"
            
        }
        
        if let abortInfo = configjson.value(forKey: "abortInfo") as? NSDictionary{
            if let abortingConfirmInfo = abortInfo.value(forKey: "abortingConfirmInfo") as? NSDictionary{
                if let dropDown_3 = abortingConfirmInfo.value(forKey: "dropDown_3") as? NSDictionary{

                    if isViewStartingSmall{
                        if let startSmallInfo = dropDown_3.value(forKey: "startSmallInfo") as? NSDictionary{
                            if let subTitle = startSmallInfo.value(forKey: "subTitle") as? String{
                                lblSubtitle.stringValue = subTitle
                            }
                            if isAnyHabitRemoved{
                                if let activityResetText = startSmallInfo.value(forKey: "activityResetText") as? String, let activityRemovedText = startSmallInfo.value(forKey: "activityRemovedText") as? String{
                                    lblDescription.stringValue = activityResetText + " " + activityRemovedText
                                }
                            }else{
                                if let activityResetText = startSmallInfo.value(forKey: "activityResetText") as? String{
                                    lblDescription.stringValue = activityResetText
                                }
                            }
                            if let changeSettingsText = startSmallInfo.value(forKey: "changeSettingsText") as? String{
                                lblDescription2.attributedStringValue = attechIconWithString(text: changeSettingsText)
                            }
                            if let shareFeedbackText = startSmallInfo.value(forKey: "shareFeedbackText") as? String{
                                lblDescription3.stringValue = shareFeedbackText
                            }
                            if let buttonTitle = startSmallInfo.value(forKey: "buttonTitle") as? String{
                                btnMain.title = buttonTitle
                            }
                        }
                    }else{
                        if let givingUpInfo = dropDown_3.value(forKey: "givingUpInfo") as? NSDictionary{
                            if let subTitle = givingUpInfo.value(forKey: "subTitle") as? String{
                                lblSubtitle.stringValue = subTitle
                            }
                            if let description = givingUpInfo.value(forKey: "description") as? String{
                                lblDescription.stringValue = description
                            }
                            if let changeSettingsText = givingUpInfo.value(forKey: "changeSettingsText") as? String{
                                lblDescription2.attributedStringValue = attechIconWithString(text: changeSettingsText)
                            }
                            if let shareFeedbackText = givingUpInfo.value(forKey: "shareFeedbackText") as? String{
                                lblDescription3.stringValue = shareFeedbackText
                            }
                            if let buttonTitle = givingUpInfo.value(forKey: "buttonTitle") as? String{
                                btnMain.title = buttonTitle
                            }
                        }
                    }
                }
            }
        }
        
    }
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == textViewFeedback{
                if textView.string.isEmpty{
                    btnMain.isEnabled = false
                }else{
                    btnMain.isEnabled = true
                }
        }
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        if isViewStartingSmall{
            //30 seconds work
            if lastCurrentState == ._MORNING_HABIT_{
                UserDefaults.standard.set(true, forKey: kUserdefaultsShowPomodoroView)
            }else{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
            }
            
            var logType = ""
            var activity = ""
            if lastCurrentState == ._MORNING_HABIT_{
                logType = "morning routine abort"
                activity = "morning routine"
            }else if lastCurrentState == ._EVENING_HABIT_{
                logType = "evening routine abort"
                activity = "evening routine"
            }else if lastCurrentState == ._ACTIVITY_{
                logType = "break abort"
                activity = "break"
            }
            
            addEntryInCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Start shortened routine", feedback: textViewFeedback.string)
            
            appdelegate?.quitAndRestartApp()//agar ye ni ayga to aage ka flow set kro
//            getAbortJsonToUpload(emailAddress: textFieldEmail.stringValue, feedback: textViewFeedback.string, abortReason: "Start shortened routine", completionHandler: {dic in
//                DispatchQueue.main.async {
//                    appdelegate?.quitAndRestartApp()//agar ye ni ayga to aage ka flow set kro
//                }
//            })
        }else{
            var logType = ""
            var activity = ""
            if lastCurrentState == ._MORNING_HABIT_{
                logType = "morning routine abort"
                activity = "morning routine"
            }else if lastCurrentState == ._EVENING_HABIT_{
                logType = "evening routine abort"
                activity = "evening routine"
            }else if lastCurrentState == ._ACTIVITY_{
                logType = "break abort"
                activity = "break"
            }
            
            addEntryInCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Deactivate routine + breaks", feedback: textViewFeedback.string)
            
            mainViewControllerObj?.showAbortDoneView()
//            getAbortJsonToUpload(emailAddress: textFieldEmail.stringValue, feedback: textViewFeedback.string, abortReason: "Deactivate routine + breaks", completionHandler: {dic in
//                DispatchQueue.main.async {
//                    mainViewControllerObj?.showAbortDoneView()
//                }
//            })
        }
    }
}

