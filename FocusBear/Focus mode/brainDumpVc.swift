//
//  brainDumpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class brainDumpVc: NSViewController, NSTextViewDelegate {

    
    @IBOutlet weak var lineTopSpace: NSLayoutConstraint!
    @IBOutlet var textViewWorkNote: NSTextView!
    @IBOutlet weak var lblTitleWorkNote: NSTextField!
    @IBOutlet weak var lblTimeRemaining: NSTextField!
    @IBOutlet weak var lblTitleTimeRemaining: NSTextField!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet weak var lblTitleIntention: NSTextField!
    
    var timer:Timer?
    
    
    var titleWorkNoteFirst = "Things I'll do in my next break:"
    var titleWorkNoteSecond = "Things you wanted to do in your break:"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleIntention.stringValue = "Intention:"
        lblTitleTimeRemaining.stringValue = "Time remaining:"
        lblTitleWorkNote.stringValue = "Dump down ideas you have so you don't forget - anything you write here will remain forever unless you delete it"
        
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
            lblTitleTimeRemaining.stringValue = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? lblTitleTimeRemaining.stringValue
            titleWorkNoteFirst = brainDumpVcInfo.value(forKey: "titleWorkNoteFirst") as? String ?? titleWorkNoteFirst
            titleWorkNoteSecond = brainDumpVcInfo.value(forKey: "titleWorkNoteSecond") as? String ?? titleWorkNoteSecond
            lblTitleWorkNote.stringValue = brainDumpVcInfo.value(forKey: "writeThingsHereText") as? String ?? lblTitleWorkNote.stringValue
        }
//        lblTitleWorkNote.stringValue = titleWorkNoteFirst
        textViewIntention.delegate = self
    }
    override func viewWillAppear() {
        
        if isFocusModeOn(){
//            lblTitleWorkNote.stringValue = titleWorkNoteFirst
            startRefreshRemainingTimer()
            textViewIntention.isEditable = true
            textViewIntention.enclosingScrollView?.isHidden = false
            lblTitleIntention.stringValue = "Intention:"
            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
            }
            lineTopSpace.constant = 66
        }else{
            lblTimeRemaining.stringValue = "0"
            textViewIntention.isEditable = false
            textViewIntention.isSelectable = false
            textViewIntention.enclosingScrollView?.isHidden = true
            lblTitleIntention.stringValue = "You're currently not in a focus session"
            if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
                lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
            }
            lineTopSpace.constant = 10
        }
        textViewIntention.string = whatToAchieveInFocusBlock
        
        if let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String {
            textViewWorkNote.string = notes
        }else{
            textViewWorkNote.string = ""
        }
    }
    override func viewWillDisappear() {
        timer?.invalidate()
        UserDefaults.standard.set(textViewWorkNote.string, forKey: kUserdefaultsFocusModeNotes)
    }
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textViewIntention{
            whatToAchieveInFocusBlock = textView.string
        }
    }
    func focusModeStarted(){
//        lblTitleWorkNote.stringValue = titleWorkNoteFirst
        startRefreshRemainingTimer()
        textViewIntention.isEditable = true
        textViewIntention.enclosingScrollView?.isHidden = false
        lblTitleIntention.stringValue = "Intention:"
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleIntentionText") as? String ?? lblTitleIntention.stringValue
        }
        lineTopSpace.constant = 66
    }
    func focusModeFinished(){
        lblTimeRemaining.stringValue = "0"
        timer?.invalidate()
        timer = nil
        textViewIntention.isEditable = false
        textViewIntention.isSelectable = false
        textViewIntention.enclosingScrollView?.isHidden = true
        lblTitleIntention.stringValue = "You're currently not in a focus session"
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            lblTitleIntention.stringValue = brainDumpVcInfo.value(forKey: "titleNotFocusSession") as? String ?? lblTitleIntention.stringValue
        }
        lineTopSpace.constant = 10
    }
    func breakStarted(){
//        lblTitleWorkNote.stringValue = titleWorkNoteSecond
    }
    func setRemainingTime(){
        if let date = endFocusModeTime{
            let secondsBetween = date.timeIntervalSince(Date())
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
            var hour = "\(h)"
            var minute = "\(m)"
            var second = "\(s)"
            
            if hour.count == 1 {
                hour = "0\(h)"
            }
            
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            
            DispatchQueue.main.async {
                if h == 0{
                    self.lblTimeRemaining.stringValue = "\(minute):\(second)"
                }else{
                    self.lblTimeRemaining.stringValue = "\(hour):\(minute):\(second)"
                }
            }
  
        }else{
            lblTimeRemaining.stringValue = "0"
        }
    }
    func startRefreshRemainingTimer() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
            lblTimeRemaining.stringValue = "0"
        }
        setRemainingTime()
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func performTimerCount() {
        if !isFocusModeOn(){
            timer?.invalidate()
        }
        DispatchQueue.main.async {
            self.setRemainingTime()
        }
    }
}
