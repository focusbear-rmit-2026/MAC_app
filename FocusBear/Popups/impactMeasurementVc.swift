//
//  impactMeasurementVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/09/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class impactMeasurementVc: NSViewController {
    
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Analyse Your Sleep and Mood"
        lblDescription.stringValue = "Would you like to track your sleep and mood to see if Focus Bear is making a positive difference to your life? This would help us too by giving us (anonymous) data about the impact of our app."
        lblSubTitle.stringValue = "Data we'll collect"
        lblPointFirst.stringValue = "Hours of sleep"
        lblPointSecond.stringValue = "Your mood and energy level"
        lblPointThird.stringValue = "How productive you felt at the end of the day"
        btnCancel.title = "No thanks"
        btnOk.title = "Ok sure"
        
        
        if let impactMeasurementVcInfo = configjson.value(forKey: "impactMeasurementVcInfo") as? NSDictionary{
            lblTitle.stringValue = impactMeasurementVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = impactMeasurementVcInfo.value(forKey: "description") as? String ?? lblDescription.stringValue
            lblSubTitle.stringValue = impactMeasurementVcInfo.value(forKey: "subTitleText") as? String ?? lblSubTitle.stringValue
            lblPointFirst.stringValue = impactMeasurementVcInfo.value(forKey: "pointFirstText") as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = impactMeasurementVcInfo.value(forKey: "pointSecondText") as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = impactMeasurementVcInfo.value(forKey: "pointThirdText") as? String ?? lblPointThird.stringValue
            btnCancel.title = impactMeasurementVcInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
            btnOk.title = impactMeasurementVcInfo.value(forKey: "buttonOkText") as? String ?? btnOk.title
        }
        
        
        
        btnCancel.isSecondaryButton = true
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        btnCancel.isEnabled = false
        var packId = "f522e5d0-6e40-4dd4-9010-338529a7223e"
        if let impactMeasurementVcInfo = configjson.value(forKey: "impactMeasurementVcInfo") as? NSDictionary{
            packId = impactMeasurementVcInfo.value(forKey: "packId") as? String ?? packId
        }
        allApiObject.getSettings(isFirstTime: true, packId:packId, completionHandler: {val in
            let settings = val?.mutableCopy() as? NSMutableDictionary
            DispatchQueue.main.async {
                if settings != nil{
                    do {
                        let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                        if let str = String(data: data, encoding: String.Encoding.utf8){
                            UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                        }
                        let alert = NSAlert()
                        alert.setSharingType()
                        var alertChangeLanguageInfoText = "Focus Bear will restart for the changes to take effect."
                        
                        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                            alertChangeLanguageInfoText = preferencesInfo.value(forKey: "alertChangeLanguageInfoText") as? String ?? alertChangeLanguageInfoText
                        }
                        
                        alert.messageText = alertChangeLanguageInfoText
                        alert.addButton(withTitle: buttonOkText)
                        self.dismiss(self)
                        alert.beginSheetModal(for: mainWindowControllerObj!.window!, completionHandler: { (modalResponse) in
                            appdelegate?.quitAndRestartApp()
                        })
                    } catch let error as NSError {
                        print(error)
                    }
                }else{
                    self.dismiss(self)
                }
            }
        }
        )
        
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
        firstViewControllerObj?.showConfirmRoutineDurationViewIfNeeded()
    }
}
