//
//  trialExpiredNag.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class trialExpiredNag: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnUserId: NSButton!
    @IBOutlet weak var lblTitleUserId: NSTextField!
    @IBOutlet weak var textFieldUserId: NSTextField!
    @IBOutlet weak var lblSubscriptionExpired: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRestorePurchases: Button!
    @IBOutlet weak var lblSyncInfo: NSTextField!
    @IBOutlet weak var lblMoneyBack: NSTextField!
    @IBOutlet weak var btnUpgradeNow: Button!

    @IBOutlet weak var lblTitleAppName: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
       
        btnRestorePurchases.buttonColor = NSColor.clear.cgColor
        
        
        let buttonBlueColor = NSColor(red: 52/255, green: 175/255, blue: 233/255, alpha: 1)
        let buttonDarkBlueColor = NSColor(red: 34/255, green: 126/255, blue: 230/255, alpha: 1)
        btnUpgradeNow.borderColor = buttonBlueColor.cgColor
        btnUpgradeNow.buttonColor = buttonBlueColor.cgColor
        btnUpgradeNow.titleColor = NSColor.white
        btnUpgradeNow.buttonDownColor = buttonDarkBlueColor.cgColor
        
        textFieldUserId.isEditable = false
        textFieldUserId.isSelectable = true
        
        
        
        
        lblTitleAppName.stringValue = appName

        btnUpgradeNow.title = "Reactivate"
        lblSubscriptionExpired.stringValue = "Focus Bear subscription expired"
        lblDescription.stringValue = "Normally I'd guide you through your morning routine at this time. Click Reactivate to set up your Focus Bear subscription and enjoy the productivity and health benefits from the app again."
        
        lblMoneyBack.stringValue = "30 days money back guarantee"
        lblSyncInfo.stringValue = "After you pay, click the Sync Payment Status button below"
        
        btnRestorePurchases.title = "Sync Payment Status"
        btnUserId.toolTip = "Copy user id"
        lblTitleUserId.stringValue = "Your user id:"
        
        if let trialExpiredNagInfo = configjson.value(forKey: "trialExpiredNagInfo") as? NSDictionary{
            btnUpgradeNow.title = trialExpiredNagInfo.value(forKey: "buttonUpgradeNowText") as? String ?? btnUpgradeNow.title
            lblDescription.stringValue = trialExpiredNagInfo.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            lblSubscriptionExpired.stringValue = trialExpiredNagInfo.value(forKey: "subscriptionExpiredText") as? String ?? lblSubscriptionExpired.stringValue
        }
        
        
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            lblMoneyBack.stringValue = upgradeNowVcInfo.value(forKey: "moneyBackText") as? String ?? lblMoneyBack.stringValue
            lblSyncInfo.stringValue = upgradeNowVcInfo.value(forKey: "syncInfoText") as? String ?? lblSyncInfo.stringValue
            btnRestorePurchases.title = upgradeNowVcInfo.value(forKey: "buttonRestoreText") as? String ?? btnRestorePurchases.title
            btnUserId.toolTip = upgradeNowVcInfo.value(forKey: "toolTipCopyId") as? String ?? btnUserId.toolTip
            lblTitleUserId.stringValue = upgradeNowVcInfo.value(forKey: "titleUserId") as? String ?? lblTitleUserId.stringValue
        }
        
       
    }
    override func viewWillAppear() {
        addLog(text: "upgradeNowVc:- viewWillAppear.")
        if !isPurchased && daysLeft <= 0{
            lblSubscriptionExpired.isHidden = false
        }else{
            lblSubscriptionExpired.isHidden = true
        }
        textFieldUserId.stringValue = appdelegate!.user?.userId ?? ""
    }
    @IBAction func btnUserIdClicked(_ sender: Any) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(appdelegate!.user?.userId ?? "", forType: .string)
        
        var msg = "Copied"
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            msg = upgradeNowVcInfo.value(forKey: "toolTipCopied") as? String ?? msg
        }
        showTooltip(sender: btnUserId, msg: msg, preferredEdge: NSRectEdge.minY, maxWidthVal:230)
        DispatchQueue.global().async {
            sleep(2)
            DispatchQueue.main.async {
                popoverTooltip?.close()
            }
        }
    }
    @IBAction func btnUpgradeNowClicked(_ sender: Any) {
        addLog(text: "btnUpgradeNowClicked.")
        let buynow_path = upgradeNowUrl
        NSWorkspace.shared.open(URL(string: buynow_path)!)
        upgradeButtonWasClicked = true
    }
    @IBAction func btnRestorePurchasesClicked(_ sender: Any) {
        addLog(text: "btnRestorePurchasesClicked.")
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"upgrade_nag"])
        self.loader.startAnimation(self)
        self.btnRestorePurchases.isEnabled = false
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchases.isEnabled = true

                if daysLeft > 0{
                    self.view.window?.close()
                }
                
                if !isPurchased && daysLeft <= 0{
                    self.lblSubscriptionExpired.isHidden = false
                }else{
                    self.lblSubscriptionExpired.isHidden = true
                }
                
            }
            
        })
    }
}
