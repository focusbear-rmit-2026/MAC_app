//
//  askAccountVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askAccountVc: NSViewController {

    @IBOutlet weak var btnSignUp: Button!
    @IBOutlet weak var btnNotRightNow: Button!
    @IBOutlet weak var lblTip: NSTextField!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Setting up a Focus Bear Account"
        lblSubtitle.stringValue = "How about setting up an account so you can sync your block preferences across your devices?"
        lblTip.stringValue = "Setting up an account doesm't cost anything - you still get a 31 day free trial- but it is necessary to enable the more advanced features."
       
        btnNotRightNow.title = "Not right now"
        btnSignUp.title = "Sure - let me sign up"
        
        
        if let dic = configjson.value(forKey: "askAccountVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubtitle.stringValue = dic.value(forKey: "descriptionText") as? String ?? lblSubtitle.stringValue
            lblTip.stringValue = dic.value(forKey: "tipText") as? String ?? lblTip.stringValue
            
            btnNotRightNow.title = dic.value(forKey: "buttonNotRightNowText") as? String ?? btnNotRightNow.title
            btnSignUp.title = dic.value(forKey: "buttonSignUpText") as? String ?? btnSignUp.title
        }
        btnNotRightNow.buttonColor = NSColor.white.cgColor
        
        allApiObject.capturePosthog(event: "setting-up-account-shown", metadata: [:])
    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        self.view.window?.close()
        showAskLoginWindow()
    }
    @IBAction func btnNotRightNowClicked(_ sender: Any) {
        let alert = NSAlert()
        alert.setSharingType()
        var alertText = "If you feel like setting up an account, just click on the Focus Bear menu icon."

        if let dic = configjson.value(forKey: "askAccountVcInfo") as? NSDictionary{
            alertText = dic.value(forKey: "alertText") as? String ?? alertText
        }

        alert.messageText = alertText
        alert.addButton(withTitle: buttonOkText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            self.view.window?.close()
        })
    }
}
