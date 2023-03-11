//
//  shareFeedbackVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class shareFeedbackVc: NSViewController, NSTextViewDelegate {

    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnAskAgain: NSButton!
    @IBOutlet weak var btnShareFeedback: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Can you give us any feedback on the app?"
        btnShareFeedback.title = "Share feedback"
        btnAskAgain.title = "Ask me in 1hr"
        
        if let shareFeedbackVcInfo = configjson.value(forKey: "shareFeedbackVcInfo") as? NSDictionary{
            lblTitle.stringValue = shareFeedbackVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnShareFeedback.title = shareFeedbackVcInfo.value(forKey: "buttonShareFeedbackText") as? String ?? btnShareFeedback.title
            btnAskAgain.title = shareFeedbackVcInfo.value(forKey: "buttonAskAgainText") as? String ?? btnAskAgain.title
        }
        
        textView.delegate = self
    }
    override func viewWillAppear() {
        textView.string = ""
        btnShareFeedback.isEnabled = false
        btnShareFeedback.keyEquivalent = "\r"
    }
    @IBAction func btnShareFeedbackClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "inactivity-nag-feedback", metadata: ["feedback":textView.string])
        self.view.window?.close()
    }
    var postponeTimer: Timer?
    @IBAction func btnAskAgainClicked(_ sender: Any) {
        self.view.window?.close()
        DispatchQueue.global().sync{
            if self.postponeTimer != nil{
                self.postponeTimer?.invalidate()
                self.postponeTimer = nil
            }
            self.postponeTimer = Timer.scheduledTimer(timeInterval: TimeInterval(3600), target: self, selector: #selector(self.showFeedbackWindowAgain), userInfo: nil, repeats: false)
            RunLoop.main.add((postponeTimer!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func showFeedbackWindowAgain(){
        showShareFeedbackWindow()
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textView{
            if textView.string.isEmpty{
                btnShareFeedback.isEnabled = false
            }else{
                btnShareFeedback.isEnabled = true
            }
        }
    }
}
