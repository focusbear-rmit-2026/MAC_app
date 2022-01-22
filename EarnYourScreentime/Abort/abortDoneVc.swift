//
//  abortDoneVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 07/01/22.
//  
//

import Cocoa

class abortDoneVc: NSViewController {
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Aborted"
        lblSubTitle.stringValue = "You’ve successfully aborted Earn Your Screen Time. The app won’t show habit prompts until you activate it again from the menu icon. If you aborted it because of a problem with the app, please email team@earnyourscreentime.com"
        if let abortInfo = configjson.value(forKey: "abortInfo") as? NSDictionary{
            if let abortDoneInfo = abortInfo.value(forKey: "abortDoneInfo") as? NSDictionary{
                
                if let title = abortDoneInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                
                if let subTitle = abortDoneInfo.value(forKey: "subTitle") as? String{
                    lblSubTitle.stringValue = subTitle + " " + emailID
                }
            }
        }
    }
    
    func startTimer() {
        currentTimer = 0
        totalDuration = 5
      //  self.lblTimerEmergency.stringValue = "\(minute):\(second)"
        DispatchQueue.global().async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
    }
    
    @objc func performTimerCount() {
        
        currentTimer += 1
        DispatchQueue.main.async {
     //       self.lblTimerEmergency.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    mainViewControllerObj?.disableApp()
                }
            }
        }
    }
}
