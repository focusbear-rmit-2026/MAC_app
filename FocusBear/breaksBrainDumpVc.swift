//
//  breaksBrainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/02/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class breaksBrainDumpVc: NSViewController {

    
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var scrollView: shadowScrollViewForTextView!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnMain: Button!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnPostponeBreak: underLineButton!
    
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
    }
    
    override func viewWillAppear() {
        lblProgress.stringValue = thirdVcObj?.lblProgress.stringValue ?? ""
        
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textView.string = notes
        }else{
            textView.string = ""
        }
        
    }
    override func viewWillDisappear() {
        UserDefaults.standard.set(textView.string, forKey: kUserdefaultsFocusModeNotes)
    }
    @IBAction func btnPostponeBreakClicked(_ sender: Any) {
        thirdVcObj?.btnSkipHabitClicked(self)
    }
    
    @IBAction func btnMainClicked(_ sender: Any) {
        mainViewControllerObj?.showBreakActivityListView()
    }

}
