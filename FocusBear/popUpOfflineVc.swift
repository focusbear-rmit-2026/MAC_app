//
//  popUpOfflineVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class popUpOfflineVc: NSViewController {

    @IBOutlet weak var btnIAmOnline: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var step = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
  
    override func viewWillAppear() {
        loadStepOne()
    }
    
    func loadStepOne(){
        step = 1
        lblTitle.stringValue = "It seems like you're offline. Please go online to continue with your habits."
        btnIAmOnline.title = "I'm online now"
        
        
        if let popUpOfflineVcInfo = configjson.value(forKey: "popUpOfflineVcInfo") as? NSDictionary{
            lblTitle.stringValue = popUpOfflineVcInfo.value(forKey: "titleOffline") as? String ?? lblTitle.stringValue
            btnIAmOnline.title = popUpOfflineVcInfo.value(forKey: "buttonOnlineText") as? String ?? btnIAmOnline.title
        }
    }
    
    @IBAction func btnIAmOnlineClicked(_ sender: Any) {
        addLog(text: "popUpOfflineVc   btnIAmOnlineClicked")
        
        if Reachability.isConnectedToNetwork() == true {
            internetWorking()
        }else{
            btnIAmOnline.isEnabled = false
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    self.btnIAmOnline.isEnabled = true
                    if !isInternetOn{
                        if self.step == 1{
                            self.step = 2
                            self.lblTitle.stringValue = "Sorry we still can't reach our backend server. Please check your internet and try again. If you are definitely online and are getting this error, please contact team@focusbear.io"
                            self.btnIAmOnline.title = "I'm definitely online"
                            
                            if let popUpOfflineVcInfo = configjson.value(forKey: "popUpOfflineVcInfo") as? NSDictionary{
                                self.lblTitle.stringValue = popUpOfflineVcInfo.value(forKey: "titleStillOffline") as? String ?? self.lblTitle.stringValue
                                self.btnIAmOnline.title = popUpOfflineVcInfo.value(forKey: "buttonDefinitelyOnlineText") as? String ?? self.btnIAmOnline.title
                            }
                            
                        }else{
                            self.loadStepOne()
                        }
                    }else{
                        self.internetWorking()
                    }
                }
            })
            
            
        }
        
    }
    
    func internetWorking(){
        if appdelegate!.user == nil{
            self.view.window?.close()
            appdelegate!.loadCredentialsAndDeviceId()
            return;
        }else if !appdelegate!.isSettingsLoddedInAppdelegate{
            appdelegate?.quitAndRestartApp()
            return;
        }else{//check currentstate
            self.view.window?.close()
            
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_{
                if mainWindowControllerObj != nil{
                    
                    
                    if !mainWindowControllerObj!.window!.isVisible{
                        
                        
                        if currentState == ._MORNING_HABIT_{
                            
                            mainWindowControllerObj?.showWindow(self)
                            showBlankWindowInSecondaryMonitor()
                            if currentAction == ._INPROGRESS_{
                                currentHabitIndex -= 1
                                mainViewControllerObj?.changeMorningHabit()
                            }
                            
                        }else if currentState == ._EVENING_HABIT_{
                            
                            mainWindowControllerObj?.showWindow(self)
                            showBlankWindowInSecondaryMonitor()
                            if currentAction == ._INPROGRESS_{
                                currentHabitIndex -= 1
                                mainViewControllerObj?.changeEveningHabit()
                            }
                            
                            
                        }else if currentState == ._ACTIVITY_{//is case mai abort all process krke sctivity timer set krenge
                            mainViewControllerObj?.setActivityTimer()
                        }

                    }
                    
                    
                }
            }
            

        }
        
    }
}
