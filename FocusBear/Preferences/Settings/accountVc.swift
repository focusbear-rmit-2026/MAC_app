//
//  accountVc.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 03/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class accountVc: NSViewController {

    
    @IBOutlet weak var lblTitleMain: NSTextField!
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
        
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])
        
        
    }
    
    override func viewWillAppear(){
        addLog(text: "accountVc:- viewWillAppear")
        
        if let userId = appdelegate!.user?.userId{
            lblUserId.stringValue = userId
        }else{
            lblUserId.stringValue = ""
        }
        lblName.stringValue = currentUserName
        lblEmaiId.stringValue = currentUserEmail
        
        var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
        var trialExpiredText = "Your subscription has expired"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }

        }
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            trialExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? trialExpiredText
        }
        if isPurchased == false{
            let daysremaining = daysLeft

            
            if daysremaining <= 0{
                lblVersionState.stringValue = trialExpiredText 
            }else{
                lblVersionState.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
            }
        }else{
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
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitleMain.stringValue = ""
            }else{
                lblTitleMain.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitleMain.stringValue = ""
        }
    }
    
    @IBAction func btnLogoutClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnLogoutClicked")
        let alert = NSAlert()
        alert.setSharingType()
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
                allApiObject.capturePosthog(event: "logout", metadata: [:])
                appdelegate?.logout()
            }
        })
       
    }
    @IBAction func btnRestorePurchaseClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnRestorePurchaseClicked")
        loader.startAnimation(self)
        btnRestorePurchase.isEnabled = false
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"accounts_tab"])
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchase.isEnabled = true
                self.viewWillAppear()
            }
            
        })
    }
}
