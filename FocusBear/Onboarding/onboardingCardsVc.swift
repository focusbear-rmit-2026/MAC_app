//
//  onboardingCardsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingCardsVc: NSViewController {

    @IBOutlet weak var boxSmall_slide1: NSBox!
    @IBOutlet weak var boxSmall_slide2: NSBox!
    @IBOutlet weak var boxSmall_slide3: NSBox!
    @IBOutlet weak var lblSignupSuccessText: NSTextField!
    @IBOutlet weak var lblTitleSignUpSuccessful: NSTextField!
    @IBOutlet weak var btnGotIt: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    @IBOutlet weak var btnBack: Button!
    var currentSlideIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleSignUpSuccessful.stringValue = "Sign up successful"
        lblSignupSuccessText.stringValue = "Great you're all signed up. I'll just give you a few tips before you start using it."
        
        lblTitle.stringValue = "Important Notes"
        lblSubTitle.stringValue = "Controlling Your Browser"
        lblDescription.stringValue = "When you next open a browser tab, you'll see this popup. The reason we ask for permissions to control your browser is so we can block distracting websites when you activate focus mode."
        btnGotIt.title = "Got it"
        btnBack.title = "Back"
        if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title
            lblTitleSignUpSuccessful.stringValue = dic.value(forKey: "titleSignUpSuccessful") as? String ?? lblTitleSignUpSuccessful.stringValue
            lblSignupSuccessText.stringValue = dic.value(forKey: "signupSuccessText") as? String ?? lblSignupSuccessText.stringValue
            
            lblSubTitle.stringValue = dic.value(forKey: "controllingBrowserText") as? String ?? lblSubTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "controllingBrowserDescription") as? String ?? lblDescription.stringValue
            
            
            arrCurrentDic[0]["subTitle"] = dic.value(forKey: "controllingBrowserText") as? String ?? arrCurrentDic[0]["subTitle"]
            arrCurrentDic[0]["description"] = dic.value(forKey: "controllingBrowserDescription") as? String ?? arrCurrentDic[0]["description"]
            
            arrCurrentDic[1]["subTitle"] = dic.value(forKey: "buildingHabitsText") as? String ?? arrCurrentDic[1]["subTitle"]
            arrCurrentDic[1]["description"] = dic.value(forKey: "buildingHabitsDescription") as? String ?? arrCurrentDic[1]["description"]
            
            arrCurrentDic[2]["subTitle"] = dic.value(forKey: "brainBreaksText") as? String ?? arrCurrentDic[2]["subTitle"]
            arrCurrentDic[2]["description"] = dic.value(forKey: "brainBreaksDescription") as? String ?? arrCurrentDic[2]["description"]
            
            btnBack.title = dic.value(forKey: "buttonBackText") as? String ?? btnBack.title
            
        }
        
        imgView.image = #imageLiteral(resourceName: "brainBreaks_card")
        
    }
    var arrCurrentDic = [["subTitle":"Controlling Your Browser", "description":"When you next open a browser tab, you'll see this popup. The reason we ask for permissions to control your browser is so we can block distracting websites when you activate focus mode.", "image":#imageLiteral(resourceName: "automationPermissions")],
                         ["subTitle":"Building Better Habits", "description":"Focus Bear will help you develop stronger habits in the morning and evening by blocking distractions. But don't worry - if you need to access your computer in a hurry, just click the \"Please spare me\" button in the top right.", "image":#imageLiteral(resourceName: "betterHabits_card")],
                         ["subTitle":"Brain Breaks", "description":"To avoid screen headaches and neck strain, Focus Bear will encourage you to take breaks at regular intervals. We give you a 30 second warning so you can postpone the break if it's a bad time. We also detect if you're in a meeting and don't show breaks as that might lead to awkward screensharing moments otherwise!", "image":#imageLiteral(resourceName: "brainBreaks_card")]]
    
    var arrFinalCurrentDic = [[String : Any]]()
    override func viewWillAppear() {
        var isHabitsDisabled = false

        if let val = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabled) as? Bool{
            isHabitsDisabled = val
        }
        
        if isHabitsDisabled{
            arrFinalCurrentDic = arrCurrentDic
            arrFinalCurrentDic.remove(at: 1)
            boxSmall_slide2.isHidden = true
        }else{
            arrFinalCurrentDic = arrCurrentDic
            boxSmall_slide2.isHidden = false
        }
        currentSlideIndex = 0
        recheckSlideState()
    }

    
    func recheckSlideState(){
        if currentSlideIndex == 0{
            boxSmall_slide1.fillColor = NSColor.systemBlue
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor

            btnBack.isHidden = true
            btnGotIt.title = "Next"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
            }
        }else if currentSlideIndex == arrFinalCurrentDic.count - 1{
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.systemBlue

            btnBack.isHidden = false
            btnGotIt.title = "Got it"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title
            }
        }else if currentSlideIndex == 1{
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.systemBlue
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor

            btnBack.isHidden = false
            btnGotIt.title = "Next"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
            }
        }
        
        
        
        lblSubTitle.stringValue = arrFinalCurrentDic[currentSlideIndex]["subTitle"] as? String ?? ""
        lblDescription.stringValue = arrFinalCurrentDic[currentSlideIndex]["description"] as? String ?? ""
        imgView.image = arrFinalCurrentDic[currentSlideIndex]["image"] as? NSImage
        
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        currentSlideIndex -= 1
        recheckSlideState()
    }
    
    @IBAction func btnGotItClicked(_ sender: Any) {
        if currentSlideIndex == arrFinalCurrentDic.count - 1{
            addLog(text:"btnGotItClicked")
            self.view.window?.close()
            showOnboardingVideoWindow()
        }else{
            addLog(text:"btnNextClicked")
            allApiObject.capturePosthog(event: "reviewed-onboarding-tip", metadata: [:])
            currentSlideIndex += 1
            recheckSlideState()
        }
        
    }
    
}
