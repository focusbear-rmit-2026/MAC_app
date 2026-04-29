//
//  createUnlockRequestVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class createUnlockRequestVc: NSViewController {

    @IBOutlet weak var btnRefreshStatus: underLineButton!
    @IBOutlet weak var btnCreateRequest: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblDurationRange: NSTextField!
    @IBOutlet weak var lblSelectedDuration: NSTextField!
    @IBOutlet weak var sliderDuration: NSSlider!
    @IBOutlet weak var lblUnlockDurationTitle: NSTextField!
    @IBOutlet var textViewReason: placeHolderTextView!
    @IBOutlet weak var scrollViewReason: NSScrollView!
    @IBOutlet weak var boxTextView: NSBox!
    @IBOutlet weak var lblReason: NSTextField!
    @IBOutlet weak var popUpBtnBuddies: NSPopUpButton!
    @IBOutlet weak var lblRequestTo: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var enterPasswordVcObj: enterPasswordVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Create Unlock Request"
        lblRequestTo.stringValue = "Requesting unlock from"
        lblReason.stringValue = "Reason (optional)"
        lblUnlockDurationTitle.stringValue = "Unlock Duration (optional)"
        lblSelectedDuration.stringValue = "1 hour"
        lblDurationRange.stringValue = "Min: 1 minutes • Max: 24 hours (1440 minutes)"
        btnCreateRequest.title = "Create Request"
        btnRefreshStatus.title = "Refresh Unlock Request's Status"
        var placeHolderString = "Explain why you need this unlock...."
        
        
        if let accountabilityBuddyInfo = configjson.value(forKey: "accountabilityBuddyInfo") as? NSDictionary{
            lblTitle.stringValue = accountabilityBuddyInfo.value(forKey: "titleCreateRequest") as? String ?? lblTitle.stringValue
            lblRequestTo.stringValue = accountabilityBuddyInfo.value(forKey: "titleRequestTo") as? String ?? lblRequestTo.stringValue
            lblReason.stringValue = accountabilityBuddyInfo.value(forKey: "reasonTitle") as? String ?? lblReason.stringValue
            lblUnlockDurationTitle.stringValue = accountabilityBuddyInfo.value(forKey: "unlockDurationTitle") as? String ?? lblUnlockDurationTitle.stringValue
            lblDurationRange.stringValue = accountabilityBuddyInfo.value(forKey: "durationRange") as? String ?? lblDurationRange.stringValue
            btnCreateRequest.title = accountabilityBuddyInfo.value(forKey: "buttonCreateRequest") as? String ?? btnCreateRequest.title
            btnRefreshStatus.title = accountabilityBuddyInfo.value(forKey: "buttonRefreshStatus") as? String ?? btnRefreshStatus.title
            placeHolderString = accountabilityBuddyInfo.value(forKey: "placeHolderString") as? String ?? placeHolderString
        }
        
        textViewReason.placeHolderTitleString = NSAttributedString(string: placeHolderString, attributes: [NSAttributedString.Key.foregroundColor : NSColor.secondaryLabelColor, NSAttributedString.Key.font : textViewReason.font ?? NSFont.systemFont(ofSize: 22)])
        
        
        btnCancel.title = buttonCancelText
        btnCancel.isSecondaryButton = true
        
        
        sliderDuration.minValue = 1
        sliderDuration.maxValue = 1440
    }
    
    override func viewWillAppear() {
        textViewReason.string = ""
        sliderDuration.doubleValue = 60
        popUpBtnBuddies.removeAllItems()
        
        for buddy in arrAllBuddies{
            popUpBtnBuddies.addItem(withTitle: buddy.buddyEmail)
        }
        updateDuration()
    }
    
    func updateDuration(){
        let val = sliderDuration.integerValue
        if val < 60 {
            lblSelectedDuration.stringValue = "\(val)  " + (val > 1 ? minutesText : minuteText)
        }else{
            lblSelectedDuration.stringValue = getStringTime(seconds: val * 60)
        }
    }
    
    @IBAction func popUpBtnBuddiesClicked(_ sender: Any) {
        
    }
    
    @IBAction func sliderDurationClicked(_ sender: Any) {
        updateDuration()
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.enterPasswordVcObj?.btnCancelClicked(self)
    }
    
    @IBAction func btnCreateRequestClicked(_ sender: Any) {
        allApiObject.unlockRequest(withBuddyUserId: arrAllBuddies[popUpBtnBuddies.indexOfSelectedItem].buddyUserId, reason: textViewReason.string, durationMinutes: sliderDuration.integerValue, completionHandler: {result in 
            
        })
    }
    
    @IBAction func btnRefreshStatusClicked(_ sender: Any) {
        allApiObject.getUnlockRequestStatus(completionHandler: {arrData in
            if let arrData = arrData{
                for data in arrData {
                    if let status = data.value(forKey: "status") as? String, let minutes = data.value(forKey: "unlock_duration_minutes") as? Int{
                        if status.lowercased() == "approved"{
                            let now = Date()
                            if let newDate = Calendar.current.date(byAdding: .minute, value: minutes, to: now) {
                                print(newDate)
                                lastUnlockTimeByAccountabilityBuddy = newDate
                                UserDefaults.standard.set(newDate, forKey: kUserdefaultsLastUnlockTimeByAccountabilityBuddy)
                                
                                DispatchQueue.main.async {
                                    self.enterPasswordVcObj?.authenticated()
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}

