//
//  enableAIBlockingVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 02/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class enableAIBlockingVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnNoThanks: Button!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var lblDescriptionThirdPoint: NSTextField!
    @IBOutlet weak var lblHeadingThirdPoint: NSTextField!
    @IBOutlet weak var lblDescriptionSecondPoint: NSTextField!
    @IBOutlet weak var lblHeadingSecondPoint: NSTextField!
    @IBOutlet weak var lblDescriptionFirstPoint: NSTextField!
    @IBOutlet weak var lblHeadingFirstPoint: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Do you want to use AI to block distractions?"
        lblSubTitle.stringValue = "Focus Bear can use AI to detect if you’re getting distracted and guide you back on track."
        lblHeadingFirstPoint.stringValue = "Anonymous:"
        lblDescriptionFirstPoint.stringValue = "we don’t tell the AI who you are"
        lblHeadingSecondPoint.stringValue = "Private:"
        lblDescriptionSecondPoint.stringValue = "we don’t track your website usage or let the AI provider train models based on your data"
        lblHeadingThirdPoint.stringValue = "Opt out at any time:"
        lblDescriptionThirdPoint.stringValue = "you can stop using AI at any point"
        
        btnNoThanks.title = "No thanks"
        btnContinue.title = "Make me indistractible"
        
        if let enableAIBlockingVcInfo = configjson.value(forKey: "enableAIBlockingVcInfo") as? NSDictionary {

            lblTitle.stringValue = enableAIBlockingVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue

            lblSubTitle.stringValue = enableAIBlockingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue

            lblHeadingFirstPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "headingFirstPoint") as? String ?? lblHeadingFirstPoint.stringValue

            lblDescriptionFirstPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "descriptionFirstPoint") as? String ?? lblDescriptionFirstPoint.stringValue

            lblHeadingSecondPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "headingSecondPoint") as? String ?? lblHeadingSecondPoint.stringValue

            lblDescriptionSecondPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "descriptionSecondPoint") as? String ?? lblDescriptionSecondPoint.stringValue

            lblHeadingThirdPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "headingThirdPoint") as? String ?? lblHeadingThirdPoint.stringValue

            lblDescriptionThirdPoint.stringValue = enableAIBlockingVcInfo.value(forKey: "descriptionThirdPoint") as? String ?? lblDescriptionThirdPoint.stringValue

            btnNoThanks.title = enableAIBlockingVcInfo.value(forKey: "buttonNoThanks") as? String ?? btnNoThanks.title

            btnContinue.title = enableAIBlockingVcInfo.value(forKey: "buttonContinue") as? String ?? btnContinue.title
        }

        
        btnNoThanks.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "enable-ai-blocking-screen-shown", metadata: [:])
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    
    @objc func viewDidResize(){
        if self.view.frame.height < 700{
            lblTitle.font = NSFont.systemFont(ofSize: 28)
            lblSubTitle.font = NSFont.systemFont(ofSize: 22)
            lblHeadingFirstPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblHeadingSecondPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblHeadingThirdPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblDescriptionFirstPoint.font = NSFont.systemFont(ofSize: 14)
            lblDescriptionSecondPoint.font = NSFont.systemFont(ofSize: 14)
            lblDescriptionThirdPoint.font = NSFont.systemFont(ofSize: 14)

//            topSpaceCollectionView.constant = 35
//            stackViewStudy.spacing = 7
//            stackViewEmployee.spacing = 7
        }else if self.view.frame.height < 900{
            lblTitle.font = NSFont.systemFont(ofSize: 32)
            lblSubTitle.font = NSFont.systemFont(ofSize: 23)
            lblHeadingFirstPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblHeadingSecondPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblHeadingThirdPoint.font = NSFont.boldSystemFont(ofSize: 15)
            lblDescriptionFirstPoint.font = NSFont.systemFont(ofSize: 14)
            lblDescriptionSecondPoint.font = NSFont.systemFont(ofSize: 14)
            lblDescriptionThirdPoint.font = NSFont.systemFont(ofSize: 14)
        }else{
            lblTitle.font = NSFont.systemFont(ofSize: 35)
            lblSubTitle.font = NSFont.systemFont(ofSize: 24)
            lblHeadingFirstPoint.font = NSFont.boldSystemFont(ofSize: 17)
            lblHeadingSecondPoint.font = NSFont.boldSystemFont(ofSize: 17)
            lblHeadingThirdPoint.font = NSFont.boldSystemFont(ofSize: 17)
            lblDescriptionFirstPoint.font = NSFont.systemFont(ofSize: 16)
            lblDescriptionSecondPoint.font = NSFont.systemFont(ofSize: 16)
            lblDescriptionThirdPoint.font = NSFont.systemFont(ofSize: 16)
        }
    }
    
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        addLog(text: "[user-action] enable ai blocking view:- button No thanks clicked.")
        allApiObject.capturePosthog(event: "opt-in-for-ai-no", metadata: [:])
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showAskAppWorkVc()
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] enable ai blocking view:- button Continue clicked.")
        allApiObject.capturePosthog(event: "opt-in-for-ai-yes", metadata: [:])
        mainViewControllerObj?.showAskOccupationVc()
    }
}
