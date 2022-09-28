//
//  accountVc.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 03/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class accountVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRestorePurchase: Button!
    @IBOutlet weak var lblRestore: NSTextField!
    @IBOutlet weak var lblUserId: NSTextField!
    @IBOutlet weak var lblTitleUserId: NSTextField!
    @IBOutlet weak var btnLogout: NSButton!
    @IBOutlet weak var lblEmaiId: NSTextField!
    @IBOutlet weak var lblTitleEmailId: NSTextField!
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblVersionState: NSTextField!
    
    var restoreText = "If you've already purchased Focus Bear subscription, you can restore that purchase."
    
        
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do view setup here.
        btnRestorePurchase.title = "Sync Payment Status"
        
        lblTitleUserId.stringValue = "User Id:"
        lblTitle.stringValue = "Your Account Information"
        lblTitleName.stringValue = "Name:"
        lblTitleEmailId.stringValue = "Email Id:"
        btnLogout.title = "Logout"
        
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            lblTitle.stringValue = accountVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleName.stringValue = accountVcInfo.value(forKey: "titleNameText") as? String ?? lblTitleName.stringValue
            lblTitleEmailId.stringValue = accountVcInfo.value(forKey: "titleEmailIdText") as? String ?? lblTitleEmailId.stringValue
            btnLogout.title = accountVcInfo.value(forKey: "buttonLogoutText") as? String ?? btnLogout.title
            lblTitleUserId.stringValue = accountVcInfo.value(forKey: "titleUserIdText") as? String ?? lblTitleUserId.stringValue
            restoreText = accountVcInfo.value(forKey: "restoreText") as? String ?? restoreText
            btnRestorePurchase.title = accountVcInfo.value(forKey: "buttonRestoreText") as? String ?? btnRestorePurchase.title
        }
    }
   
    override func viewWillAppear(){
        
        if let userId = appdelegate!.user?.userId{
            lblUserId.stringValue = userId
        }else{
            lblUserId.stringValue = ""
        }
//        if let user = User(from: appdelegate?.credential?.idToken ?? ""){
//            lblName.stringValue = user.name
//            lblEmaiId.stringValue = user.email
//        }else{
//            lblName.stringValue = ""
//            lblEmaiId.stringValue = ""
//        }
        lblName.stringValue = currentUserName
        lblEmaiId.stringValue = currentUserEmail
        
        var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
        var trialExpiredText = "Your subscription has expired"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
//            if let text = common.value(forKey: "trialExpiredText") as? String{
//                trialExpiredText = text
//            }
        }
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            trialExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? trialExpiredText
        }
        if isPurchased == false{
            let daysremaining = daysLeft
//            if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
//                let secondsBetween = Date().timeIntervalSince(date)
//                let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
//                daysremaining = daysFreeTrial-numberOfDays_afterinstall
//                if daysremaining < 0 {
//                    daysremaining = 0
//                }
//                if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//                    daysremaining = 0
//                }
//                if daysremaining == 0{
//                    if UserDefaults.standard.object(forKey: "trialExpired") == nil{
//                        UserDefaults.standard.set(true, forKey: "trialExpired")
//                    }
//                }
//            }else{
//                daysremaining = daysFreeTrial
//            }
            
            if daysremaining <= 0{
                lblVersionState.stringValue = trialExpiredText 
            }else{
                lblVersionState.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
            }
        }else{
//            UserDefaults.standard.removeObject(forKey: "trialExpired")
            lblVersionState.stringValue = "Registered Version"
            if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                lblVersionState.stringValue = accountVcInfo.value(forKey: "registeredVersionText") as? String ?? lblVersionState.stringValue
            }
        }
        
        if !isPurchased{
            lblRestore.stringValue = restoreText
        }else{
            lblRestore.stringValue = ""
        }
    }
    
    @IBAction func btnLogoutClicked(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to logout?"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            alert.messageText = accountVcInfo.value(forKey: "logoutAlertText") as? String ?? alert.messageText
        }
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                appdelegate?.logout()
            }
        })
       
    }
    @IBAction func btnRestorePurchaseClicked(_ sender: Any) {
        loader.startAnimation(self)
        btnRestorePurchase.isEnabled = false
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchase.isEnabled = true
                self.viewWillAppear()
            }
            
        })
    }
}
