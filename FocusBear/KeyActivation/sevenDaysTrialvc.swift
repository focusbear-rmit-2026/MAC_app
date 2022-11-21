//
//  sevenDaysTrialvc.swift
//  Focus Bear
//
//  Created by Prashant on 20/11/19.
//  Copyright © 2019 Wise Tech Labs Private Limited. All rights reserved.
//

import Cocoa

class sevenDaysTrialvc: NSViewController {

  
    @IBOutlet weak var lblAppName: NSTextField!
    @IBOutlet weak var lblGetLicenseKey: NSTextField!
    @IBOutlet weak var lblDaysRemaining: NSTextField!
    @IBOutlet weak var lblTrialPeriod: NSTextField!
    @IBOutlet weak var btnEnterLicenseKey: NSButton!
    @IBOutlet weak var btncontinueTrial: SYFlatButton!
    @IBOutlet weak var lbldescription: NSTextField!
    @IBOutlet weak var lbldaysRemaining: NSTextField!
    @IBOutlet weak var btnactivatenow: SYFlatButton!
    @IBOutlet weak var imgviewlogo: NSImageView!
    @IBOutlet weak var imglogobox: NSBox!
    var firstrun = false
    var daysremaining = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var titleText = "Focus Bear"
        var description = "We offer a 21-day trial period, during which you can evaluate Focus Bear at your leisure. The trial is a FULLY functional Trial and you can evaluate all the features."
        var buttonStartTrialText = "START 21-DAY FREE TRIAL"
        var buttonContinueTrialText = "Continue Trial"
        var buttonRegisterNowText = "Register Now"
        var trialPeriodText = "Trial period"
        var daysRemainingText = "Days Remaining"
        var getLicenseKeyDescription = "if you do not have a license key, get one!"
        var buttonBuyNowText = "Buy now"
        var buttonlicensekeyText = "Sync Payment Status"
        
        if let trialNagInfo = configjson.value(forKey: "trialNagInfo") as? NSDictionary{
            if let title = trialNagInfo.value(forKey: "title") as? String{
                titleText = title
            }
            if let text = trialNagInfo.value(forKey: "description") as? String{
                description = text
            }
            if let text = trialNagInfo.value(forKey: "buttonStartTrialText") as? String{
                buttonStartTrialText = text
            }
            if let text = trialNagInfo.value(forKey: "buttonContinueTrialText") as? String{
                buttonContinueTrialText = text
            }
            if let text = trialNagInfo.value(forKey: "buttonRegisterNowText") as? String{
                buttonRegisterNowText = text
            }
            if let text = trialNagInfo.value(forKey: "trialPeriodText") as? String{
                trialPeriodText = text
            }
            if let text = trialNagInfo.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }
            if let text = trialNagInfo.value(forKey: "getLicenseKeyDescription") as? String{
                getLicenseKeyDescription = text
            }
            if let text = trialNagInfo.value(forKey: "buttonBuyNowText") as? String{
                buttonBuyNowText = text
            }
//            if let text = trialNagInfo.value(forKey: "buttonlicensekeyText") as? String{
//                buttonlicensekeyText = text//text // 
//            }
        }
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            buttonlicensekeyText = accountVcInfo.value(forKey: "buttonRestoreText") as? String ?? buttonlicensekeyText
        }
        
        lblAppName.stringValue = titleText
        lbldescription.stringValue = description

        
        lblTrialPeriod.stringValue = trialPeriodText
        lbldaysRemaining.stringValue = daysRemainingText
        lblGetLicenseKey.stringValue = getLicenseKeyDescription
        btnactivatenow.title = buttonBuyNowText
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: buttonlicensekeyText, attributes: attrs)
        
        btnEnterLicenseKey.attributedTitle = attrString
        
        
        
        
        daysremaining = daysLeft
//        if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
//            let secondsBetween = Date().timeIntervalSince(date)
//            let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
//            daysremaining = daysFreeTrial-numberOfDays_afterinstall
            if daysremaining < 0 {
                daysremaining = 0
            }
//            if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//                daysremaining = 0
//            }
            if daysremaining == daysFreeTrial{
                if firstrun == true{
                    btncontinueTrial.title = buttonStartTrialText
                }else{
                    btncontinueTrial.title = buttonContinueTrialText
                }
            }else if daysremaining == 0{
//                if UserDefaults.standard.object(forKey: "trialExpired") == nil{
//                    UserDefaults.standard.set(true, forKey: "trialExpired")
//                }
                btncontinueTrial.title = buttonRegisterNowText
            }else{
                btncontinueTrial.title = buttonContinueTrialText
            }
            
            lbldaysRemaining.stringValue = "\(daysremaining)"
                
//        }
//        else{
//            daysremaining = daysFreeTrial
//            lbldaysRemaining.stringValue = "\(daysremaining)"
//            btncontinueTrial.title = buttonStartTrialText
//        }

        
        
    }
    //if you do not have a license key, get one!
    @IBAction func btnActivatenow(_ sender: Any) {
        activationWindowControllerObj?.showActivateNowVc()
        activateNowvcObj?.btnback.isHidden = false
//        purchaseNow_clicked()
    }
    @IBAction func enterLicenseKeyClicked(_ sender: Any) {
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
//                self.loader.stopAnimation(self)
//                self.btnRestorePurchase.isEnabled = true
//                self.viewWillAppear()
                if daysLeft > 0{
                    self.view.window?.close()
                }
            }
            
        })
        return;
        //
        activationWindowControllerObj?.showActivateNowVc()
        activateNowvcObj?.btnback.isHidden = false
    }
    @IBAction func btncontineTrial(_ sender: Any) {
        if daysremaining == 0{
            activationWindowControllerObj?.showActivateNowVc()
            activateNowvcObj?.btnback.isHidden = false
//            purchaseNow_clicked()
        }else{
            self.view.window?.close()
            appdelegate?.initialWork()           
        }
        
    }
}
