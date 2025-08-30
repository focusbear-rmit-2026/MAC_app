//
//  takeBreaksInfoVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/6/24.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class takeBreaksInfoVc: NSViewController {

   
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var lblMostlyCommitted: NSTextField!
    @IBOutlet weak var boxMostlyCommitted: toggleButtonBox!
    
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblSelect: NSTextField!
    @IBOutlet weak var lblTitleHowMuchCare: NSTextField!

    @IBOutlet weak var lblResult: NSTextField!

    @IBOutlet weak var stackViewHowMuchCare: NSStackView!


    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnContinue: Button!
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
        
        lblResult.isHidden = true
        lblTitle.stringValue = appName
        
        lblMostlyCommitted.stringValue = "Mostly committed - I’ll take breaks most of the time"
        
        lblTitleHowMuchCare.stringValue = "How much do you care about taking breaks?"
        lblSelect.stringValue = "Select one that apply"
        lblDontCare.stringValue = "Meh - don't really care"
        lblNotCommitted.stringValue = "I probably should take breaks but am not that committed"
        lblCommitted.stringValue = "Super committed - I vow to take breaks regularly"
        lblSubTitle.stringValue = "Focus Bear can help you remember to take breaks regularly throughout the day. This will help avoid screen headaches and actually improve your productivity. You can even do microworkouts during the breaks 💪"
        lblQuestion.stringValue = "We time breaks so they don't disrupt hyperfocus. Focus Bear will detect when you are less active (based on not typing or moving your mouse) and suggest a break at that time. You can skip/postpone the breaks but your eyes and body will really appreciate it if you do take breaks!"

        btnContinue.title = "Continue"

        if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = takeBreaksInfoVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblQuestion.stringValue = takeBreaksInfoVcInfo.value(forKey: "warningNewText") as? String ?? lblQuestion.stringValue
            lblTitleHowMuchCare.stringValue = takeBreaksInfoVcInfo.value(forKey: "titleHowMuchCare") as? String ?? lblTitleHowMuchCare.stringValue
            lblSelect.stringValue = takeBreaksInfoVcInfo.value(forKey: "selectOneText") as? String ?? lblSelect.stringValue
            lblDontCare.stringValue = takeBreaksInfoVcInfo.value(forKey: "buttonDontCareText") as? String ?? lblDontCare.stringValue
            lblNotCommitted.stringValue = takeBreaksInfoVcInfo.value(forKey: "buttonNotCommittedText") as? String ?? lblNotCommitted.stringValue
            lblCommitted.stringValue = takeBreaksInfoVcInfo.value(forKey: "buttonCommittedText") as? String ?? lblCommitted.stringValue
            lblMostlyCommitted.stringValue = takeBreaksInfoVcInfo.value(forKey: "buttonMostlyCommittedText") as? String ?? lblMostlyCommitted.stringValue
        }
        
        
        if let askBreakTimeVcInfo = configjson.value(forKey: "askBreakTimeVcInfo") as? NSDictionary{
            btnContinue.title = askBreakTimeVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        allApiObject.capturePosthog(event: "take-breaks-info-screen-shown", metadata: [:])
        boxDontCare.customDelegate = self
        boxNotCommitted.customDelegate = self
        boxCommitted.customDelegate = self
        boxMostlyCommitted.customDelegate = self
    }
    
    override func viewWillAppear() {
        viewDidResize()
        btnContinue.isEnabled = false

        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 10)
        showOnboardingBellIcon(view: self.view, screen: "take-breaks-info-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        NotificationCenter.default.removeObserver(self)
        hideOnboardingBellIcon(view: self.view)
    }
    
    @objc func viewDidResize(){
        print("viewDidResize")
        if self.view.frame.height < 750{
            lblSubTitle.font = NSFont.systemFont(ofSize: 15)
        }else{
            lblSubTitle.font = NSFont.systemFont(ofSize: 18)
        }
        if self.view.frame.height < 750{
            lblQuestion.font = NSFont.systemFont(ofSize: 15)
            lblTitleHowMuchCare.font = getBoldFont(size: 13)
            stackViewHowMuchCare.spacing = 8
        }else if self.view.frame.height < 850{
            lblQuestion.font = NSFont.systemFont(ofSize: 18)
            lblTitleHowMuchCare.font = getBoldFont(size: 14)
            stackViewHowMuchCare.spacing = 10
        }else{
            stackViewHowMuchCare.spacing = 12
            lblQuestion.font = NSFont.systemFont(ofSize: 18)
            lblTitleHowMuchCare.font = getBoldFont(size: 15)
        }
        
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        var isBreaksEnabled = false
        if boxCommitted.isSelected{
            isBreaksEnabled = true
            allApiObject.capturePosthog(event: "cares-about-breaks", metadata: ["commitment-level-for-breaks":"committed"]);
        }else if boxMostlyCommitted.isSelected{
            isBreaksEnabled = true
            allApiObject.capturePosthog(event: "cares-about-breaks", metadata: ["commitment-level-for-breaks":"mostly_committed"]);
        }else{
            if boxNotCommitted.isSelected{
                allApiObject.capturePosthog(event: "cares-about-breaks", metadata: ["commitment-level-for-breaks":"not_committed"]);
            }else if boxDontCare.isSelected{
                allApiObject.capturePosthog(event: "cares-about-breaks", metadata: ["commitment-level-for-breaks":"do_not_care"]);
            }
            isBreaksEnabled = false
        }

        addLog(text: "takeBreaksInfoVc:- btnContinueClicked:isBreaksEnabled:- \(isBreaksEnabled)")
        if isBreaksEnabled{
            UserDefaults.standard.set(true, forKey: kUserdefaultsBreaksEnabledFromOnboarding)
            mainViewControllerObj!.showAskBreakTimeVc()
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsBreaksEnabledFromOnboarding)
            appdelegate!.showOnbardingHabit()
        }
        
    }

    func checkContinueButtonState(){
        if boxCommitted.isSelected || boxDontCare.isSelected || boxNotCommitted.isSelected || boxMostlyCommitted.isSelected{
            btnContinue.isEnabled = true
        }else{
            btnContinue.isEnabled = false
        }
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        var msg = "Focus Bear will detect when you are less active (based on not typing or moving your mouse) and suggest a break at that time. You can skip/postpone the breaks but your eyes and body will really appreciate it if you do take breaks!"
        if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
            msg = takeBreaksInfoVcInfo.value(forKey: "infoText") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:300, autoCloseOnMouseExit: true)
    }
}
extension takeBreaksInfoVc: toggleButtonBoxDelegate{
    func toggleButtonBoxClicked(box: NSBox) {
        lblResult.isHidden = false
        if box == boxDontCare{
            boxNotCommitted.isSelected = false
            boxCommitted.isSelected = false
            boxMostlyCommitted.isSelected = false
            lblResult.stringValue =  "No worries. You can always enable breaks later from Preferences > Breaks > Enable Breaks"
            if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
                lblResult.stringValue = takeBreaksInfoVcInfo.value(forKey: "resultDisableBreaksText") as? String ?? lblResult.stringValue
            }
        }else if box == boxNotCommitted{
            boxDontCare.isSelected = false
            boxCommitted.isSelected = false
            boxMostlyCommitted.isSelected = false
            lblResult.stringValue = "No worries. You can always enable breaks later from Preferences > Breaks > Enable Breaks"
            if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
                lblResult.stringValue = takeBreaksInfoVcInfo.value(forKey: "resultDisableBreaksText") as? String ?? lblResult.stringValue
            }
        }else if box == boxCommitted{
            boxDontCare.isSelected = false
            boxNotCommitted.isSelected = false
            boxMostlyCommitted.isSelected = false
            lblResult.stringValue = "Cool. We'll let you set up your breaks right away"
            if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
                lblResult.stringValue = takeBreaksInfoVcInfo.value(forKey: "resultEnableBreaksText") as? String ?? lblResult.stringValue
            }
        }else if box == boxMostlyCommitted{
            boxDontCare.isSelected = false
            boxNotCommitted.isSelected = false
            boxCommitted.isSelected = false
            lblResult.stringValue = "Got it - you can skip breaks if it comes at a bad time"
            if let takeBreaksInfoVcInfo = configjson.value(forKey: "takeBreaksInfoVcInfo") as? NSDictionary{
                lblResult.stringValue = takeBreaksInfoVcInfo.value(forKey: "resultMostlyCommittedText") as? String ?? lblResult.stringValue
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
        
        if !boxMostlyCommitted.isSelected{
            boxMostlyCommitted.fillColor = boxMostlyCommitted.normalColor
            boxMostlyCommitted.borderWidth = 0
        }
        
        checkContinueButtonState()
    }
}
