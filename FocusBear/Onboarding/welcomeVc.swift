//
//  welcomeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeVc: NSViewController {

    @IBOutlet weak var btnAlreadyHaveAccount: underLineButton!
    @IBOutlet weak var lblAllRights: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnAlreadyHaveAccount.title = "I already have a Focus Bear account"
        lblTitleAppName.stringValue = appName
        lblSubTitle.stringValue = "Welcome aboard!"
        lblDescriptionFirst.stringValue = "Focus Bear helps you avoid distractions and build healthy habits."
        lblDescriptionSecond.stringValue = "Let's start out by blocking distractions."
        btnLetsDoIt.title = "Let's do it"
        lblAllRights.stringValue = "© 2022-2023 Focus Bear All Rights Reserved."
        
        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnLetsDoIt.title = welcomeOnboardingVcInfo.value(forKey: "buttonLetsDoItText") as? String ?? btnLetsDoIt.title
            lblAllRights.stringValue = welcomeOnboardingVcInfo.value(forKey: "allRightsReservedText") as? String ?? lblAllRights.stringValue
            
        }
        if let welcomeVcInfo = configjson.value(forKey: "welcomeVcInfo") as? NSDictionary{
            lblDescriptionFirst.stringValue = welcomeVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            lblDescriptionSecond.stringValue = welcomeVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            btnAlreadyHaveAccount.title = welcomeVcInfo.value(forKey: "buttonAlreadyHaveAccountText") as? String ?? btnAlreadyHaveAccount.title
        }
        
        allApiObject.capturePosthog(event: "welcome-aboard-shown", metadata: [:])
    }
    

    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "btnLetsDoItClicked.")
        self.view.window?.contentViewController = getOnboardingBlockedUrlsVcObject()
    }
    @IBAction func btnAlreadyHaveAccountClicked(_ sender: Any) {
        isHabitsDisabled = false
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabled)
        allApiObject.getHabitPacksInfo(breaks_only: false, completionHandler: {arrDic in
            
            if arrDic != nil{
                print(arrDic)
                DispatchQueue.main.async {
                    if habitPacksData != nil{
                        if habitPacksData!.count != 0{
                            let pack = habitPacksData![0]
                            let id = pack["id"] as? String ?? ""
                            if !id.isEmpty{
                                UserDefaults.standard.set(id, forKey: kUserdefaultsPackIdSelected)
                            }
                        }
                    }
                    UserDefaults.standard.set("05:15", forKey: kUserdefaultsStartupTimeFromOnboarding)
                    UserDefaults.standard.set("20:30", forKey: kUserdefaultsShutOffTimeFromOnboarding)
                    
                    UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                }
            }
        })
        
        self.view.window?.close()
        showCustomLoginWindow(isLogin: true)
        askLogInWcObj?.window?.center()
    }
    
}
