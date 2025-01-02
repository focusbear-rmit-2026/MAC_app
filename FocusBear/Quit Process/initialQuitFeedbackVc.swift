//
//  initialQuitFeedbackVC.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 30/09/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa
import Foundation

class initialQuitFeedbackVc: NSViewController, NSTextViewDelegate {

    @IBOutlet weak var btnCancelQuit: Button!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lblTitleMain: NSTextField!
    @IBOutlet weak var btnQuitApp: Button!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleMain.stringValue = "Quitting.."
        lblTitle.stringValue = "Sorry that Focus Bear didn't meet your expectations 😭"
        btnQuitApp.title = "Turn Focus Bear off"
        lblDescription.stringValue = "Can you let us know what went wrong so we can improve the app?"
        lblSubTitle.stringValue = "You were hoping that Focus Bear would do this - \"goals\". It obviously hasn't delivered on that expectation."
        btnCancelQuit.title = "I didn’t mean it. Let me do my habits!"
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingTitle = quitInfo.value(forKey: "quittingTitle") as? String{
                lblTitleMain.stringValue = quittingTitle
            }
            if let initialQuitFeedbackVcInfo = quitInfo.value(forKey: "initialQuitFeedbackVcInfo") as? NSDictionary{
                lblTitle.stringValue = initialQuitFeedbackVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
                lblSubTitle.stringValue = initialQuitFeedbackVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
                lblDescription.stringValue = initialQuitFeedbackVcInfo.value(forKey: "description") as? String ?? lblDescription.stringValue
                btnQuitApp.title = initialQuitFeedbackVcInfo.value(forKey: "buttonQuitText") as? String ?? btnQuitApp.title
            }
        }
            
        if let abortInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingCountDownInfo = abortInfo.value(forKey: "quittingCountDownInfo") as? NSDictionary{
                btnCancelQuit.title = quittingCountDownInfo.value(forKey: "buttonQuitCancelText") as? String ?? btnCancelQuit.title
            }
        }
        
        textView.delegate = self
        btnQuitApp.buttonColor = NSColor.white.cgColor
    }
    override func viewWillAppear() {
        var subTitle = "You were hoping that Focus Bear would do this - \"<GOALS>\". It obviously hasn't delivered on that expectation."
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let initialQuitFeedbackVcInfo = quitInfo.value(forKey: "initialQuitFeedbackVcInfo") as? NSDictionary{
                subTitle = initialQuitFeedbackVcInfo.value(forKey: "subTitle") as? String ?? subTitle
            }
        }
        
        if let goals  = UserDefaults.standard.object(forKey: kUserDefaultsCustomGoals) as? String{
            lblSubTitle.isHidden = false
            lblSubTitle.stringValue = subTitle.replacingOccurrences(of: "<GOALS>", with: goals)
        }else{
            lblSubTitle.isHidden = true
        }
        
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
            imgViewGif.isHidden = true
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
            imgViewGif.isHidden = false
        }
        textView.string = ""
        loader.stopAnimation(self)
    }
    override func viewWillDisappear() {
        if enterPasswordVcObj != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                enterPasswordVcObj?.view.removeFromSuperview()
            }
        }
    }
    var enterPasswordVcObj: enterPasswordVc?
    func resetData(){
        if shouldAskPassword(){
            if SettingsManagerObject.isPasswordRequireInQuitApp{
                if self.enterPasswordVcObj == nil{
                    self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
                }
                self.view.addSubview(self.enterPasswordVcObj!.view)
                self.view.addConstraints(subView: self.enterPasswordVcObj!.view)
                self.enterPasswordVcObj?.removeConstraints()
                addLog(text: "Showing enter password view from quit")
            }
            
        }
    }
    
    
    @IBAction func btnQuitAppClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"quit within first two days", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled(), "feedback":self.textView.string])
        loader.startAnimation(self)
        btnQuitApp.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            self.loader.stopAnimation(self)
            self.btnQuitApp.isEnabled = true
            UserDefaults.standard.set("quit within first two days", forKey: kUserDefaultsLastQuitReason)
            appdelegate?.quitAppForUser()
        }
    }
    
    @IBAction func btnCancelQuitClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            if textView == self.textView{

            }
        }
    }
}
