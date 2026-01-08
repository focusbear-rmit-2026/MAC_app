//
//  askAppWorkVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 31/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askAppWorkVc: NSViewController {

    @IBOutlet weak var btnSetHabits: Button!
    @IBOutlet weak var btnDoItLater: Button!
    @IBOutlet weak var topSpaceBottomBox: NSLayoutConstraint!
    @IBOutlet weak var spaceBetweenCheckBoxs: NSLayoutConstraint!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblSelect: NSTextField!
    @IBOutlet weak var lblTitleHowMuchCare: NSTextField!
    @IBOutlet weak var checkBoxBuildHabitsCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var lblResult: NSTextField!
    //    @IBOutlet weak var lblTitleAdditionalGoals: NSTextField!
    @IBOutlet weak var stackViewHowMuchCare: NSStackView!
    @IBOutlet weak var btnInfoStayFocused: hoverInfoButton!
    @IBOutlet weak var btnInfoBuildHabits: hoverInfoButton!
    @IBOutlet weak var boxAnythingElse: NSBox!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var checkBoxSecond: NSButton!
    @IBOutlet weak var checkBoxFirst: NSButton!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblCheckBoxSecond: NSTextField!
    @IBOutlet weak var lblCheckBoxFirst: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    @IBOutlet weak var boxDontCare: toggleButtonBox!
    @IBOutlet weak var lblDontCare: NSTextField!
    
    @IBOutlet weak var boxNotCommitted: toggleButtonBox!
    @IBOutlet weak var lblNotCommitted: NSTextField!
    
    @IBOutlet weak var boxCommitted: toggleButtonBox!
    @IBOutlet weak var lblCommitted: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnDoItLater.title = "Uhh I'll do it later"
        btnSetHabits.title = "Yup! Habits are my middle name"
        lblTitleHowMuchCare.stringValue = "Do you want to set up habits now? (takes 5 minutes)"
        
        lblSelect.stringValue = "Select one that apply"
        lblDontCare.stringValue = "Meh - don't really care"
        lblNotCommitted.stringValue = "I probably should do habits but am not that committed"
        lblCommitted.stringValue = "Super committed - this is the main reason i want to use Focus Bear"
        
        
        lblResult.isHidden = true
        lblTitle.stringValue = "Focus Bear"
        lblCheckBoxFirst.stringValue = "Help me develop healthy habits in the morning (e.g. meditate before starting work) and evening (e.g. have dinner with loved ones)"
        lblCheckBoxSecond.stringValue = "Help me stay focused during the work day"
        btnContinue.title = "Continue"

        lblSubTitle.stringValue = "Activate features"
        lblQuestion.stringValue = "We'll do our best to help you achieve your goals 🤩 Which Focus Bear features do you want to activate?"
        
        
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            lblTitle.stringValue = appName
            lblCheckBoxFirst.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxFirstText") as? String ?? lblCheckBoxFirst.stringValue

            if askOccupationVcObj?.isStudentSelected ?? false{
                lblCheckBoxSecond.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxSecondText_study") as? String ?? lblCheckBoxSecond.stringValue
            }else{
                lblCheckBoxSecond.stringValue = askAppWorkVcInfo.value(forKey: "checkBoxSecondText") as? String ?? lblCheckBoxSecond.stringValue
            }
                
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title

//            lblTitleHowMuchCare.stringValue = askAppWorkVcInfo.value(forKey: "titleHowMuchCare") as? String ?? lblTitleHowMuchCare.stringValue
            lblSelect.stringValue = askAppWorkVcInfo.value(forKey: "selectOneText") as? String ?? lblSelect.stringValue
            lblDontCare.stringValue = askAppWorkVcInfo.value(forKey: "buttonDontCareText") as? String ?? lblDontCare.stringValue
            lblNotCommitted.stringValue = askAppWorkVcInfo.value(forKey: "buttonNotCommittedText") as? String ?? lblNotCommitted.stringValue
            lblCommitted.stringValue = askAppWorkVcInfo.value(forKey: "buttonCommittedText") as? String ?? lblCommitted.stringValue
            lblSubTitle.stringValue = askAppWorkVcInfo.value(forKey: "titleActivateFeatures") as? String ?? lblSubTitle.stringValue
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "subTitleActivateFeatures") as? String ?? lblQuestion.stringValue
            
            lblTitleHowMuchCare.stringValue = askAppWorkVcInfo.value(forKey: "titleSetHabits") as? String ?? lblTitleHowMuchCare.stringValue
            btnDoItLater.title = askAppWorkVcInfo.value(forKey: "buttonDoItLater") as? String ?? btnDoItLater.title
            btnSetHabits.title = askAppWorkVcInfo.value(forKey: "buttonSetHabits") as? String ?? btnSetHabits.title
        }
        allApiObject.capturePosthog(event: "goals-screen-shown", metadata: [:])
        boxDontCare.customDelegate = self
        boxNotCommitted.customDelegate = self
        boxCommitted.customDelegate = self
        
        lblSelect.isHidden = true
        boxDontCare.isHidden = true
        boxNotCommitted.isHidden = true
        boxCommitted.isHidden = true
    }
    
    override func viewWillAppear() {
        viewDidResize()
        checkBoxFirst.state = .off
        checkBoxSecond.state = .off
        btnContinue.isEnabled = false
        boxAnythingElse.isHidden = true
//       / NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification, object: nil, queue: nil) { notification in
            
//        }
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
        checkContinueButtonState()
        btnDoItLater.buttonColor = NSColor.white.cgColor
    }
    
    override func viewDidAppear() {
        getOnboardingProgressVcObj().loadView()
        onboardingProgressVcObj?.totalProgress = 14
        onboardingProgressVcObj!.lblTitleProgress.stringValue = onboardingProgressVcObj!.titleSettingHabitsProgress
        showOnboardingProgress(view: self.view, progress: 2)
        showOnboardingBellIcon(view: self.view, screen: "goals-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        NotificationCenter.default.removeObserver(self)
        hideOnboardingBellIcon(view: self.view)
    }
    
    @objc func viewDidResize(){
        print("viewDidResize")
        if self.view.frame.height < 700{
            stackViewHowMuchCare.spacing = 12
            spaceBetweenCheckBoxs.constant = 10
            lblCheckBoxFirst.font = NSFont.systemFont(ofSize: 16)
            lblCheckBoxSecond.font = NSFont.systemFont(ofSize: 16)
            lblSubTitle.font = NSFont.systemFont(ofSize: 22)
            lblQuestion.font = NSFont.systemFont(ofSize: 18)
        }else{
            stackViewHowMuchCare.spacing = 14
            spaceBetweenCheckBoxs.constant = 25
            lblCheckBoxFirst.font = NSFont.systemFont(ofSize: 19)
            lblCheckBoxSecond.font = NSFont.systemFont(ofSize: 19)
            lblSubTitle.font = NSFont.systemFont(ofSize: 24)
            lblQuestion.font = NSFont.systemFont(ofSize: 20)
        }

    }
    
    @IBAction func btnInfoBuildHabitsClicked(_ sender: Any) {
        var msg = "Focus Bear can help you with morning and evening routines. The app will guide you through habits like mindfulness, journalling, exercise, planning your day or anything you care about."
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            msg = askAppWorkVcInfo.value(forKey: "infoBuildHabitsText") as? String ?? msg
        }
        showTooltip(sender: btnInfoBuildHabits, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoStayFocusedClicked(_ sender: Any) {
        var msg = "Focus Bear can help block distracting websites and apps while you're working to help you get more done."
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            msg = askAppWorkVcInfo.value(forKey: "infoStayFocusedText") as? String ?? msg
        }
        showTooltip(sender: btnInfoStayFocused, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        let isDoNotCareSelected = boxDontCare.isSelected
        let isNotCommittedSelected = boxNotCommitted.isSelected
        let isCommittedSelected = boxCommitted.isSelected
        
        var bGoalStayFocused = false
        var bGoalHealthyHabits = false
        var careFactorHabitsForPosthog = ""//
        if checkBoxFirst.state == .on && checkBoxSecond.state == .on{
            if isDoNotCareSelected{
                bGoalStayFocused = true;
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"do_not_care"]);
                careFactorHabitsForPosthog = "do_not_care"
            }else if isNotCommittedSelected{ //still no habits and just focus
                bGoalStayFocused = true;
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"not_committed"])
                careFactorHabitsForPosthog = "not_committed"
            }else if isCommittedSelected{ // ALL habits
                bGoalHealthyHabits = true
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"committed"])
                allApiObject.capturePosthog(event: "activate-all-features", metadata: [:])
                careFactorHabitsForPosthog = "committed"
            }
        }else if checkBoxFirst.state == .on{
            if isDoNotCareSelected{
                bGoalStayFocused = true;
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"do_not_care"]);
                careFactorHabitsForPosthog = "do_not_care"
            }else if isNotCommittedSelected{
                bGoalStayFocused = true;
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"not_committed"])
                careFactorHabitsForPosthog = "not_committed"
            }else if isCommittedSelected{
                bGoalHealthyHabits = true
                allApiObject.capturePosthog(event: "cares-about-habits", metadata: ["care-factor":"committed"])
                allApiObject.capturePosthog(event: "activate-habits-only", metadata: [:])
                careFactorHabitsForPosthog = "committed"
            }
        }else if checkBoxSecond.state == .on{
            bGoalStayFocused = true
            allApiObject.capturePosthog(event: "activate-productivity-only", metadata: [:])
            careFactorHabitsForPosthog = "do_not_care"
        }
        if !careFactorHabitsForPosthog.isEmpty{
            UserDefaults.standard.set(careFactorHabitsForPosthog, forKey: kUserDefaultsCareFactorHabitsForPosthog)
        }

        isHabitsDisabled = !bGoalHealthyHabits
//        var breaks_only = false
        if isHabitsDisabled{
//            breaks_only = true
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsHabitsDisabledFromOnboarding)
            mainViewControllerObj!.showSelectHabitsLaterInfoVc()
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabledFromOnboarding)
            mainViewControllerObj!.showInstalltHabitPacksVc()
            
            /*
            btnContinue.isEnabled = false
            loader.startAnimation(self)
            allApiObject.getHabitPacksInfo(breaks_only: breaks_only, completionHandler: {arrDic in
                DispatchQueue.main.async {
                    self.btnContinue.isEnabled = true
                    self.loader.stopAnimation(self)
                }
                DispatchQueue.main.async {
                    mainViewControllerObj!.showAdditionalGoalsVc()
                }
            })
             */
        }
        
        addLog(text: "askAppWorkVc:- btnContinueClicked:isHabitsDisabled:- \(isHabitsDisabled)")
    }
    @IBAction func checkBoxFirstClicked(_ sender: Any) {
        addLog(text: "[user-action] askAppWorkVc:- checkBoxFirstClicked")
        if checkBoxFirst.state == .off{
            boxAnythingElse.isHidden = true
            boxCommitted.isSelected = false
        }else{
            boxAnythingElse.isHidden = false
            boxCommitted.isSelected = true
        }
        checkContinueButtonState()
    }
    @IBAction func checkBoxSecondClicked(_ sender: Any) {
        addLog(text: "[user-action] askAppWorkVc:- checkBoxSecondClicked")
        checkContinueButtonState()
    }
    func checkContinueButtonState(){
        btnContinue.isEnabled = false
        if checkBoxFirst.state == .off && checkBoxSecond.state == .off{
            btnContinue.isEnabled = false
            btnDoItLater.isHidden = true
            btnSetHabits.isHidden = true
            btnContinue.isHidden = false
        }else if checkBoxFirst.state == .off && checkBoxSecond.state == .on{
            btnContinue.isEnabled = true
            btnContinue.isHidden = false
            btnSetHabits.isHidden = true
            btnDoItLater.isHidden = true
        }else if checkBoxFirst.state == .on{
            btnContinue.isEnabled = true
            btnContinue.isHidden = true
            btnSetHabits.isHidden = false
            btnDoItLater.isHidden = false
//            if boxCommitted.isSelected || boxDontCare.isSelected || boxNotCommitted.isSelected{
//                btnContinue.isEnabled = true
//            }else{
//                btnContinue.isEnabled = false
//            }
        }
    }
    
    @IBAction func btnDoItLaterClicked(_ sender: Any) {
        boxCommitted.isSelected = false
        boxDontCare.isSelected = true
        boxNotCommitted.isSelected = false
        btnContinueClicked(self)
    }
    
    @IBAction func btnSetHabitsClicked(_ sender: Any) {
        boxCommitted.isSelected = true
        boxDontCare.isSelected = false
        boxNotCommitted.isSelected = false
        btnContinueClicked(self)
    }
}
extension askAppWorkVc: toggleButtonBoxDelegate{
    func toggleButtonBoxClicked(box: NSBox) {
        lblResult.isHidden = false
        if box == boxDontCare{
            boxNotCommitted.isSelected = false
            boxCommitted.isSelected = false
            lblResult.stringValue =  "Ok no worries. We'll let you focus on focusing!"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                lblResult.stringValue = askAppWorkVcInfo.value(forKey: "resultFocusOnlyText") as? String ?? lblResult.stringValue
            }
        }else if box == boxNotCommitted{
            boxDontCare.isSelected = false
            boxCommitted.isSelected = false
            lblResult.stringValue = "Got it. We won't activate the habit features for now but you can activate them later."
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                lblResult.stringValue = askAppWorkVcInfo.value(forKey: "resultNoHabitsText") as? String ?? lblResult.stringValue
            }
        }else if box == boxCommitted{
            boxDontCare.isSelected = false
            boxNotCommitted.isSelected = false
            lblResult.stringValue = "Cool. We'll let you set up your habits right away"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                lblResult.stringValue = askAppWorkVcInfo.value(forKey: "resultHabitsText") as? String ?? lblResult.stringValue
            }
        }
        if !boxDontCare.isSelected{
            boxDontCare.fillColor = boxDontCare.normalColor
            boxDontCare.borderWidth = 0
        }
        if !boxNotCommitted.isSelected{
            boxNotCommitted.fillColor = boxNotCommitted.normalColor
            boxNotCommitted.borderWidth = 0
        }
        if !boxCommitted.isSelected{
            boxCommitted.fillColor = boxCommitted.normalColor
            boxCommitted.borderWidth = 0
        }
        checkContinueButtonState()
    }
}
