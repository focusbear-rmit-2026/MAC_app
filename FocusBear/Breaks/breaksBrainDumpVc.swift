//
//  breaksBrainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class breaksBrainDumpVc: NSViewController {

    
    
    @IBOutlet weak var bottomSpaceScrollView: NSLayoutConstraint!
    @IBOutlet weak var topSpaceScrollView: NSLayoutConstraint!//50
    @IBOutlet weak var bottomSpaceLblTitle: NSLayoutConstraint!//80
    @IBOutlet weak var topSpaceLblTitle: NSLayoutConstraint!//80
    @IBOutlet var textView: customTexView!
    @IBOutlet weak var scrollView: shadowScrollViewForTextView!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnPostponeBreak: underLineButton!
    
    @IBOutlet weak var btnInfo: NSButton!
    //lbltitlefont 39
//        /lblsubtitlefont 24/
    var timerBreaksScreenIdle: Timer?
    var totalDurationIdleTime = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here
          
        lblTitle.stringValue = "Capture your thoughts before starting your break"
        
        lblSubtitle.stringValue = "Taking regular breaks (every 20 minutes is recommended) is crucial for avoiding eye strain and postural issues. You might be worried that it will take you out of your flow and disrupt your productivity. Let's capture what you were just working on so that you won't lose your train of thought after the break. BTW you'll often find that when you take a break and give your brain some time in the \"default mode network\", you'll come up with novel solutions to a problem you'd been struggling with. Not necessarily a productivity killer at all 😉"
        
        btnMain.title = "Start Break"
        
        
        if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
            lblTitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "description") as? String ?? lblSubtitle.stringValue
            btnMain.title = breaksBrainDumpVcInfo.value(forKey: "buttonStartBreakText") as? String ?? btnMain.title
        }
        
        
        btnPostponeBreak.title = "Postpone break for five minutes"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnPostponeBreak.title = activityInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostponeBreak.title
        }
     
        scrollView.shadowRadius = 1.5
        scrollView.shadowOffset = NSMakeSize(0, 2)
        scrollView.shadowOpacity = 0.15
        scrollView.setShadow()
        
        textView.font = NSFont.systemFont(ofSize: 22)
    }
    
    override func viewWillAppear() {
        btnInfo.isHidden = false
        lblSubtitle.stringValue = "You're going to feel great after this break. Write down what you were just working on so you don't forget."
        
        
        lblProgress.stringValue = thirdVcObj?.lblProgress.stringValue ?? ""

        var totalDuration = 0
        for activity in arrFinalBreakActivities{
            if activity.activity.useTimer{
                totalDuration += activity.activity.durationSeconds
            }
        }
        totalDuration += 30
        totalDurationIdleTime = totalDuration
        DispatchQueue.global().sync{//async {
            if self.timerBreaksScreenIdle != nil{
                self.timerBreaksScreenIdle?.invalidate()
                self.timerBreaksScreenIdle = nil
            }
            self.timerBreaksScreenIdle = Timer.scheduledTimer(timeInterval: TimeInterval(totalDuration), target: self, selector: #selector(self.breaksScreenIdleResetBreaks), userInfo: nil, repeats: false)
            RunLoop.main.add((timerBreaksScreenIdle!), forMode: RunLoop.Mode.common)
        }
        viewDidResize()
    }
    
    override func viewDidAppear() {
        
    }

    func resetBrainDump(){
        
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textView.string = notes
        }else{
            textView.string = ""
        }
        
        var arrPlaceHolders = ["Building an AI-powered coffee mug that can detect when you need a refill",
                               "Optimizing a website for users browsing on a Game Boy Color",
                               "Creating a machine learning algorithm that predicts which coworker will bring donuts to the office next",
                               "Writing a script that generates random passwords that only consist of emojis",
                               "Designing a user interface for a self-driving unicycle"]
        
        
        if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
            if isBreakActivityShowingWhileMeeting && currentState == ._MICRO_BREAK_{
                lblSubtitle.stringValue = "You're going to focus better on the meeting after this break. Write down any quick thoughts you don't forget."
                lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "subTitleMeetings") as? String ?? lblSubtitle.stringValue
            }else{
                lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "subTitle") as? String ?? lblSubtitle.stringValue
            }
            arrPlaceHolders = breaksBrainDumpVcInfo.value(forKey: "placeholders") as? [String] ?? arrPlaceHolders
        }
        
        textView.placeHolderTitleString = NSAttributedString(string: arrPlaceHolders.randomElement() ?? "", attributes: [NSAttributedString.Key.foregroundColor : NSColor.secondaryLabelColor, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 22)])
        
        textView.window?.makeFirstResponder(textView)
        
        let runningApp = lastFrontMostApplication
        if runningApp?.bundleIdentifier != Bundle.main.bundleIdentifier{
            if let appUrl = runningApp?.bundleURL{
                var domain:String?
                let name = appUrl.deletingPathExtension().lastPathComponent
                let nameLowercased = name.lowercased()
                
                if arrBrowsersLowerCasedNames.contains(nameLowercased){
                    var currentBrowser:BROWSER!
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        currentBrowser = browser
                        if let url = getActiveTabUrlOf(browser: currentBrowser){
                            domain = getDomainFromUrl(url: url)
                        }
                    }
                }
                var lastWorkText = "I had <WORK> open. I was about to..."
                if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
                    lastWorkText = breaksBrainDumpVcInfo.value(forKey: "lastWorkText") as? String ?? lastWorkText
                }
                
                if let domain = domain {
                    lastWorkText = lastWorkText.replacingOccurrences(of: "<WORK>", with: domain)
                }else{
                    lastWorkText = lastWorkText.replacingOccurrences(of: "<WORK>", with: name)
                }
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.doesRelativeDateFormatting = false

                // Custom format for "2 Dec at 11:20 am"
                formatter.dateFormat = "d MMM 'at' h:mm a"

                // Get the formatted string
                let dateString = formatter.string(from: Date())
                
                lastWorkText = dateString + ": " + lastWorkText
                let notes = textView.string
                textView.string = lastWorkText + "\n" + notes
            }
        }
    }
    
    override func viewDidLayout() {
        viewDidResize()
    }
    
    func viewDidResize(){
        if self.view.frame.height < 500{
            bottomSpaceScrollView.constant = 15
            topSpaceScrollView.constant = 15
            bottomSpaceLblTitle.constant = 20
            topSpaceLblTitle.constant = 60
            lblTitle.font = NSFont.systemFont(ofSize: 28)
            lblSubtitle.font = NSFont.systemFont(ofSize: 14)
        }else if self.view.frame.height < 600{
            bottomSpaceScrollView.constant = 20
            topSpaceScrollView.constant = 20
            bottomSpaceLblTitle.constant = 30
            topSpaceLblTitle.constant = 60
            lblTitle.font = NSFont.systemFont(ofSize: 31)
            lblSubtitle.font = NSFont.systemFont(ofSize: 16)
        }else if self.view.frame.height < 700{
            bottomSpaceScrollView.constant = 30
            topSpaceScrollView.constant = 30
            bottomSpaceLblTitle.constant = 50
            topSpaceLblTitle.constant = 60
            lblTitle.font = NSFont.systemFont(ofSize: 35)
            lblSubtitle.font = NSFont.systemFont(ofSize: 20)
        }else if self.view.frame.height < 800{
            bottomSpaceScrollView.constant = 40
            topSpaceScrollView.constant = 40
            bottomSpaceLblTitle.constant = 60
            topSpaceLblTitle.constant = 60
            lblTitle.font = NSFont.systemFont(ofSize: 37)
            lblSubtitle.font = NSFont.systemFont(ofSize: 22)
        }else{
            bottomSpaceScrollView.constant = 50
            topSpaceScrollView.constant = 50
            bottomSpaceLblTitle.constant = 80
            topSpaceLblTitle.constant = 80
            lblTitle.font = NSFont.systemFont(ofSize: 39)
            lblSubtitle.font = NSFont.systemFont(ofSize: 24)
        }
    }
    
    @objc func breaksScreenIdleResetBreaks(){
//        getHabitsVcObject().breaksScreenIsIdleResetBreaks()
        showNaturalBreakDetectionWindow(duration: totalDurationIdleTime)
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        btnInfo.isHidden = true
        lblSubtitle.stringValue = "Taking regular breaks (every 20 minutes is recommended) is crucial for avoiding eye strain and postural issues. You might be worried that it will take you out of your flow and disrupt your productivity. Let's capture what you were just working on so that you won't lose your train of thought after the break. BTW you'll often find that when you take a break and give your brain some time in the \"default mode network\", you'll come up with novel solutions to a problem you'd been struggling with. Not necessarily a productivity killer at all 😉"
        
        if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
            lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "description") as? String ?? lblSubtitle.stringValue
        }
    }
    
    override func viewWillDisappear() {
        if self.timerBreaksScreenIdle != nil{
            self.timerBreaksScreenIdle?.invalidate()
            self.timerBreaksScreenIdle = nil
        }
        UserDefaults.standard.set(textView.string, forKey: kUserdefaultsFocusModeNotes)
    }
    
    @IBAction func btnPostponeBreakClicked(_ sender: Any) {
        addLog(text: "[user-action] breaksBrainDumpVc:- button Postpone Clicked")
        if currentState == ._MICRO_BREAK_{
            getHabitsVcObject().abortCurrentState()
            return
        }
    }
    
    @IBAction func btnMainClicked(_ sender: Any) {
        addLog(text: "[user-action] breaksBrainDumpVc:- btnMainClicked")
        getHabitsVcObject().showBreakActivityListView()
    }

}

class customTexView: NSTextView{
    var placeHolderTitleString: NSAttributedString = NSAttributedString(string: "Place Holder Value", attributes: [NSAttributedString.Key.foregroundColor : NSColor.secondaryLabelColor, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 22)])

    override func becomeFirstResponder() -> Bool {
        self.needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)

        if (self.string == "") {
            placeHolderTitleString.draw(at: NSMakePoint(5, 0))
        }
    }
}

