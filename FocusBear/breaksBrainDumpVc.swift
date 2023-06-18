//
//  breaksBrainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class breaksBrainDumpVc: NSViewController {

    
    
    @IBOutlet var textView: customTexView!
    @IBOutlet weak var scrollView: shadowScrollViewForTextView!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnPostponeBreak: underLineButton!
    
    @IBOutlet weak var btnInfo: NSButton!
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
        var arrPlaceHolders = ["Building an AI-powered coffee mug that can detect when you need a refill",
                               "Optimizing a website for users browsing on a Game Boy Color",
                               "Creating a machine learning algorithm that predicts which coworker will bring donuts to the office next",
                               "Writing a script that generates random passwords that only consist of emojis",
                               "Designing a user interface for a self-driving unicycle"]
        
        
        if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
            if isBreakActivityShowingWhileMeeting && currentState == ._ACTIVITY_{
                lblSubtitle.stringValue = "You're going to focus better on the meeting after this break. Write down any quick thoughts you don't forget."
                lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "subTitleMeetings") as? String ?? lblSubtitle.stringValue
            }else{
                lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "subTitle") as? String ?? lblSubtitle.stringValue
            }
            arrPlaceHolders = breaksBrainDumpVcInfo.value(forKey: "placeholders") as? [String] ?? arrPlaceHolders
        }
        
        lblProgress.stringValue = thirdVcObj?.lblProgress.stringValue ?? ""
        
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textView.string = notes
        }else{
            textView.string = ""
        }
        
        
        
        textView.placeHolderTitleString = NSAttributedString(string: arrPlaceHolders.randomElement() ?? "", attributes: [NSAttributedString.Key.foregroundColor : NSColor.secondaryLabelColor, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 22)])
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        btnInfo.isHidden = true
        lblSubtitle.stringValue = "Taking regular breaks (every 20 minutes is recommended) is crucial for avoiding eye strain and postural issues. You might be worried that it will take you out of your flow and disrupt your productivity. Let's capture what you were just working on so that you won't lose your train of thought after the break. BTW you'll often find that when you take a break and give your brain some time in the \"default mode network\", you'll come up with novel solutions to a problem you'd been struggling with. Not necessarily a productivity killer at all 😉"
        
        if let breaksBrainDumpVcInfo = configjson.value(forKey: "breaksBrainDumpVcInfo") as? NSDictionary{
            lblSubtitle.stringValue = breaksBrainDumpVcInfo.value(forKey: "description") as? String ?? lblSubtitle.stringValue
        }
    }
    override func viewWillDisappear() {
        UserDefaults.standard.set(textView.string, forKey: kUserdefaultsFocusModeNotes)
    }
    @IBAction func btnPostponeBreakClicked(_ sender: Any) {
        if currentState == ._ACTIVITY_{
            mainViewControllerObj?.btnAbortClicked(self)
            return
        }
    }
    
    @IBAction func btnMainClicked(_ sender: Any) {
        mainViewControllerObj?.showBreakActivityListView()
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

