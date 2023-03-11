//
//  onboardingCardsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingCardsVc: NSViewController {

    @IBOutlet weak var btnLink: underLineButton!
    @IBOutlet weak var boxSmall_slide4: NSBox!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var boxSmall_slide0: NSBox!
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
    
    @IBOutlet weak var lblExploreTips: NSTextField!
    
    
    @IBOutlet weak var btnBack: Button!
    var currentSlideIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblExploreTips.stringValue = "Click next to explore the tips to use Focus Bear."
        
        
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
            
            
            arrCurrentDic[1]["subTitle"] = dic.value(forKey: "controllingBrowserText") as? String ?? arrCurrentDic[1]["subTitle"]
            arrCurrentDic[1]["description"] = dic.value(forKey: "controllingBrowserDescription") as? String ?? arrCurrentDic[1]["description"]
            
            arrCurrentDic[2]["subTitle"] = dic.value(forKey: "buildingHabitsText") as? String ?? arrCurrentDic[2]["subTitle"]
            arrCurrentDic[2]["description"] = dic.value(forKey: "buildingHabitsDescription") as? String ?? arrCurrentDic[2]["description"]
            
            arrCurrentDic[3]["subTitle"] = dic.value(forKey: "brainBreaksText") as? String ?? arrCurrentDic[3]["subTitle"]
            arrCurrentDic[3]["description"] = dic.value(forKey: "brainBreaksDescription") as? String ?? arrCurrentDic[3]["description"]
            
            arrCurrentDic[4]["subTitle"] = dic.value(forKey: "privacyText") as? String ?? arrCurrentDic[4]["subTitle"]
            arrCurrentDic[4]["description"] = dic.value(forKey: "privacyDescription") as? String ?? arrCurrentDic[4]["description"]
            arrCurrentDic[4]["buttonText"] = dic.value(forKey: "buttonPrivacyText") as? String ?? arrCurrentDic[4]["buttonText"]
            
            btnBack.title = dic.value(forKey: "buttonBackText") as? String ?? btnBack.title
            lblExploreTips.stringValue = dic.value(forKey: "exploreTipsText") as? String ?? lblExploreTips.stringValue
        }
        
        imgView.image = #imageLiteral(resourceName: "brainBreaks_card")
        
        
     
    }
    var arrCurrentDic = [[:],
                         ["subTitle":"Controlling Your Browser", "description":"When you next open a browser tab, you'll see this popup. The reason we ask for permissions to control your browser is so we can block distracting websites when you activate focus mode.", "image":#imageLiteral(resourceName: "automationPermissions")],
                         ["subTitle":"Building Better Habits", "description":"Focus Bear will help you develop stronger habits in the morning and evening by blocking distractions. But don't worry - if you need to access your computer in a hurry, just click the \"Please spare me\" button in the top right.", "image":#imageLiteral(resourceName: "betterHabits_card")],
                         ["subTitle":"Brain Breaks", "description":"To avoid screen headaches and neck strain, Focus Bear will encourage you to take breaks at regular intervals. We give you a 30 second warning so you can postpone the break if it's a bad time. We also detect if you're in a meeting and don't show breaks as that might lead to awkward screensharing moments otherwise!", "image":#imageLiteral(resourceName: "brainBreaks_card")],
                         ["subTitle":"Privacy and Security", "description":"We take your privacy and security very seriously. We do not log which websites or apps you use. We do sync your habit data to our server but this is only to support cross device distraction blocking. Your data is encrypted and we don't let anyone else see it. for more details or feel free to email team@focusbear.io. Refer to our privacy policy:", "buttonText":"Click here to view Privacy Policy", "image":NSImage(named: NSImage.applicationIconName)]]
    
    var arrFinalCurrentDic = [[String : Any]]()
    var isHabitsDisabled = false
    var isLogin:Bool = false
    override func viewWillAppear() {
        
        if isLogin{
            lblTitleSignUpSuccessful.stringValue = "Sign in successful"
            lblSignupSuccessText.stringValue = "Great you're all signed in. I'll just give you a few tips before you start using it."
            
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                lblTitleSignUpSuccessful.stringValue = dic.value(forKey: "titleSignInSuccessful") as? String ?? lblTitleSignUpSuccessful.stringValue
                lblSignupSuccessText.stringValue = dic.value(forKey: "signinSuccessText") as? String ?? lblSignupSuccessText.stringValue
            }
        }else{
            lblTitleSignUpSuccessful.stringValue = "Sign up successful"
            lblSignupSuccessText.stringValue = "Great you're all signed up. I'll just give you a few tips before you start using it."
            
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                lblTitleSignUpSuccessful.stringValue = dic.value(forKey: "titleSignUpSuccessful") as? String ?? lblTitleSignUpSuccessful.stringValue
                lblSignupSuccessText.stringValue = dic.value(forKey: "signupSuccessText") as? String ?? lblSignupSuccessText.stringValue
            }
            
        }
        
        isHabitsDisabled = false
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabled) as? Bool{
            isHabitsDisabled = val
        }
        if isHabitsDisabled{
            arrFinalCurrentDic = arrCurrentDic
            arrFinalCurrentDic.remove(at: 2)
            boxSmall_slide2.isHidden = true
        }else{
            arrFinalCurrentDic = arrCurrentDic
            boxSmall_slide2.isHidden = false
        }
        currentSlideIndex = 0
        recheckSlideState()
    }

    
    func recheckSlideState(){
        btnLink.isHidden = true
        if currentSlideIndex == 0{
            boxSmall_slide0.fillColor = NSColor.systemBlue
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide4.fillColor = NSColor.quaternaryLabelColor
            
            lblTitle.isHidden = true
            lblSubTitle.isHidden = true
            lblDescription.isHidden = true
            imgView.isHidden = true
            lblTitleSignUpSuccessful.isHidden = false
            lblSignupSuccessText.isHidden = false
            lblExploreTips.isHidden = false
            imgViewAppIcon.isHidden = false
            
            btnBack.isHidden = true
            btnGotIt.title = "Next"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
            }
            
            return;
        }
        lblSubTitle.isHidden = false
        lblDescription.isHidden = false
        imgView.isHidden = false
        lblTitle.isHidden = false
        lblTitleSignUpSuccessful.isHidden = true
        lblSignupSuccessText.isHidden = true
        lblExploreTips.isHidden = true
        imgViewAppIcon.isHidden = true
        
        if currentSlideIndex == 1{
            boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide1.fillColor = NSColor.systemBlue
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide4.fillColor = NSColor.quaternaryLabelColor
            
            btnBack.isHidden = false
            btnGotIt.title = "Next"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
            }
        }else if currentSlideIndex == 2{
            
            if  isHabitsDisabled{
                boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide3.fillColor = NSColor.systemBlue
                boxSmall_slide4.fillColor = NSColor.quaternaryLabelColor
                
                btnBack.isHidden = false
                btnGotIt.title = "Next"
                if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                    btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
                }
            }else{
                boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide2.fillColor = NSColor.systemBlue
                boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide4.fillColor = NSColor.quaternaryLabelColor
                btnBack.isHidden = false
                btnGotIt.title = "Next"
                if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                    btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
                }
            }
            
            
        }else if currentSlideIndex == 3{
            
            if currentSlideIndex == arrFinalCurrentDic.count - 1{
                boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide4.fillColor = NSColor.systemBlue
                btnBack.isHidden = false
                btnLink.isHidden = false
                btnLink.title = arrFinalCurrentDic[currentSlideIndex]["buttonText"] as? String ?? ""
                btnGotIt.title = "Got it"
                if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                    btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title
                }
            }else{
                boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
                boxSmall_slide3.fillColor = NSColor.systemBlue
                boxSmall_slide4.fillColor = NSColor.quaternaryLabelColor
                btnBack.isHidden = false
                
                btnGotIt.title = "Next"
                if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                    btnGotIt.title = dic.value(forKey: "buttonNextText") as? String ?? btnGotIt.title
                }
            }
            
        }else if currentSlideIndex == 4{
            boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide4.fillColor = NSColor.systemBlue
            btnBack.isHidden = false
            btnLink.isHidden = false
            btnLink.title = arrFinalCurrentDic[currentSlideIndex]["buttonText"] as? String ?? ""
            btnGotIt.title = "Got it"
            if let dic = configjson.value(forKey: "onboardingCardsInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title
            }
        }

        lblSubTitle.stringValue = arrFinalCurrentDic[currentSlideIndex]["subTitle"] as? String ?? ""
        lblDescription.stringValue = arrFinalCurrentDic[currentSlideIndex]["description"] as? String ?? ""
        imgView.image = arrFinalCurrentDic[currentSlideIndex]["image"] as? NSImage
        
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        addLog(text:"onboardingCardsVc:- btnBackClicked")
        currentSlideIndex -= 1
        recheckSlideState()
    }
    
    @IBAction func btnGotItClicked(_ sender: Any) {
        if currentSlideIndex == arrFinalCurrentDic.count - 1{
            addLog(text:"onboardingCardsVc:- btnGotItClicked")
            
            if shouldShowOnboardingBlockedUrlsView{
                self.view.window?.windowController?.contentViewController = getOnboardingBlockedUrlsVcObject()
            }else{
                self.view.window?.close()
                showPreloadFocusModesWindow()
            }

        }else{
            addLog(text:"onboardingCardsVc:- btnNextClicked")
            allApiObject.capturePosthog(event: "reviewed-onboarding-tip", metadata: [:])
            currentSlideIndex += 1
            
            recheckSlideState()
        }
        
    }
    
    @IBAction func btnLickClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/en/privacy-policy"){
            NSWorkspace.shared.open(url)
        }
    }
}


