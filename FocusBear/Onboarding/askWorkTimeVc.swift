//
//  askWorkTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askWorkTimeVc: NSViewController {

  
    @IBOutlet weak var lblDescriptionShutOffTime: NSTextField!
    @IBOutlet weak var lblDescriptionStartupTime: NSTextField!
    @IBOutlet weak var lblTitleShutDownTime: NSTextField!
    @IBOutlet weak var lblTitleStartupTime: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var datePickerShutDownTime: NSDatePicker!
    @IBOutlet weak var datePickerStartTime: NSDatePicker!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var textStartupTime = "Choose the absolute earliest time you ever plan to start your morning routine. You can start your morning routine at any time after <SHUTOFFTIME>. Before <STARTTIME> your computer will be locked because you should be sleeping 😴 (you can still unlock it if you have an emergency)."
    var textShutOffTime = "At <SHUTOFFTIME>, Focus Bear will take over your computer and other devices and guide you through your evening routine to help you wind down for the evening."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "Set Startup and Shutdown time"
        btnContinue.title = "Continue"
        
        lblTitleStartupTime.stringValue = "Startup Time:"
        lblTitleShutDownTime.stringValue = "Shutdown Time:"
        
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            lblTitle.stringValue = askAppWorkVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        if let askWorkTimeVcInfo = configjson.value(forKey: "askWorkTimeVcInfo") as? NSDictionary{
            lblTitleStartupTime.stringValue = askWorkTimeVcInfo.value(forKey: "titleStartupTime") as? String ?? lblTitleStartupTime.stringValue
            lblTitleShutDownTime.stringValue = askWorkTimeVcInfo.value(forKey: "titleShutDownTime") as? String ?? lblTitleShutDownTime.stringValue
            textStartupTime = askWorkTimeVcInfo.value(forKey: "descriptionStartupTime") as? String ?? textStartupTime
            textShutOffTime = askWorkTimeVcInfo.value(forKey: "descriptionShutDownTime") as? String ?? textShutOffTime
            lblQuestion.stringValue = askWorkTimeVcInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        datePickerStartTime.dateValue = getDateFromString(date: "5:15", dateFormat: "HH:mm") ?? Date()
        datePickerShutDownTime.dateValue = getDateFromString(date: "20:30", dateFormat: "HH:mm") ?? Date()
        resetView()
    }
    func resetView(){
        
        
        let startTime = getStringFromDate(date: datePickerStartTime.dateValue, dateFormat: "HH:mm")
        let shutOffTime = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "HH:mm")
        
        
        var descriptionStartupTime = textStartupTime
        var descriptionShutOffTime = textShutOffTime
        
        descriptionStartupTime = descriptionStartupTime.replacingOccurrences(of: "<SHUTOFFTIME>", with: shutOffTime)
        descriptionStartupTime = descriptionStartupTime.replacingOccurrences(of: "<STARTTIME>", with: startTime)
        
        descriptionShutOffTime = descriptionShutOffTime.replacingOccurrences(of: "<SHUTOFFTIME>", with: shutOffTime)
        
        
        lblDescriptionStartupTime.stringValue = descriptionStartupTime
        lblDescriptionShutOffTime.stringValue = descriptionShutOffTime
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        let startTime = getStringFromDate(date: datePickerStartTime.dateValue, dateFormat: "HH:mm")
        let shutOffTime = getStringFromDate(date: datePickerShutDownTime.dateValue, dateFormat: "HH:mm")
        
        UserDefaults.standard.set(startTime, forKey: kUserdefaultsStartupTimeFromOnboarding)
        UserDefaults.standard.set(shutOffTime, forKey: kUserdefaultsShutOffTimeFromOnboarding)
        
        appdelegate!.showOnbardingHabit()
    }
    @IBAction func datePickerShutDownTimeClicked(_ sender: Any) {
        resetView()
    }
    
    @IBAction func datePickerStartTimeClicked(_ sender: Any) {
        resetView()
    }
}
