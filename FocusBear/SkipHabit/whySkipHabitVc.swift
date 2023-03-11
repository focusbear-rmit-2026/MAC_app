//
//  WhySkipHabitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class whySkipHabitVc: NSViewController {

    @IBOutlet weak var btnCanNotDoIt: Button!
    @IBOutlet weak var btnAlreadyDidIt: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Why do you want to skip?"
        btnAlreadyDidIt.title = "I already did it"
        btnCanNotDoIt.title = "Can't do it today"
        
        if let whySkipHabitVcInfo = configjson.value(forKey: "whySkipHabitVcInfo") as? NSDictionary{
            lblTitle.stringValue = whySkipHabitVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnAlreadyDidIt.title = whySkipHabitVcInfo.value(forKey: "buttonAlreadyDidItText") as? String ?? btnAlreadyDidIt.title
            btnCanNotDoIt.title = whySkipHabitVcInfo.value(forKey: "buttonCanNotDoItText") as? String ?? btnCanNotDoIt.title
        }
    }
    
    func skipActivityAlreadyDid(){
        if rememberNextHabitVcObj != nil{
            if thirdVcObj!.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj!.view.removeFromSuperview()
                thirdVcObj?.boxBg.isHidden = false
            }
        }
        if currentAction == ._VISUALIZE_{
            mainViewControllerObj?.showThirdVc()
        }
        if currentAction == ._INPROGRESS_{
            mainViewControllerObj?.showThirdVc()
        }
        
        if currentState == ._ACTIVITY_{

        }else if currentState == ._MORNING_HABIT_{
            thirdVcObj?.morningHabitSkippedAndDoneAlready()
        }else if currentState == ._EVENING_HABIT_{
            //thirdVcObj?.eveningHabitSkipped()
            thirdVcObj?.eveningHabitSkippedAndDoneAlready()
        }
    }
    
    @IBAction func btnAlreadyDidItClicked(_ sender: Any) {
        addLog(text: "whySkipHabitVc:- button AlreadyDidItClicked")
        self.view.removeFromSuperview()
        
        
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if currentState == ._MORNING_HABIT_{
                if SettingsManagerObject.isPasswordRequireInSkipMorning{
                    mainViewControllerObj?.showPasswordView()
                    enterPasswordVcObj?.parentVc = self
                }else{
                    skipActivityAlreadyDid()
                }
                
            }else if currentState == ._EVENING_HABIT_{
                if isHighPrioritySequenceGoing{
                    if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = self
                    }else{
                        skipActivityAlreadyDid()
                    }
                }else{
                    if SettingsManagerObject.isPasswordRequireInSkipEvening{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = self
                    }else{
                        skipActivityAlreadyDid()
                    }
                }
                
            }
            
        }else{
            skipActivityAlreadyDid()
        }
        
    }
    @IBAction func btnCanNotDoItClicked(_ sender: Any) {
        addLog(text: "whySkipHabitVc:- button CanNotDoItClicked")
        self.view.removeFromSuperview()
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if currentState == ._MORNING_HABIT_{
                if SettingsManagerObject.isPasswordRequireInSkipMorning{
                    mainViewControllerObj?.showPasswordView()
                    enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                }else{
                    mainViewControllerObj?.showSkipHabitView()
                }
                
            }else if currentState == ._EVENING_HABIT_{
                if isHighPrioritySequenceGoing{
                    if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                    }else{
                        mainViewControllerObj?.showSkipHabitView()
                    }
                }else{
                    if SettingsManagerObject.isPasswordRequireInSkipEvening{
                        mainViewControllerObj?.showPasswordView()
                        enterPasswordVcObj?.parentVc = getSkipHabitVcObject()
                    }else{
                        mainViewControllerObj?.showSkipHabitView()
                    }
                }
            }
        }else{
            mainViewControllerObj?.showSkipHabitView()
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        addLog(text: "whySkipHabitVc:- button CloseClicked")
        self.view.removeFromSuperview()
    }
}
