//
//  askLogInVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askLogInVc: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var btnSignUp: Button!
    @IBOutlet weak var btnSignIn: Button!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Win your habits.\nAmp up your productivity."
        lblMessage.stringValue = "Sign In with a Focus Bear account to manage your time without thinking about it. Having an account helps you Set your computer use hours, create a custom morning and night routine, and customize your focus modes for different activities."
        var btnSignInTitle = "Sign In"
        var btnSignUpTitle = "Sign Up"
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
            btnSignInTitle = askLogInVcInfo.value(forKey: "buttonSignInText") as? String ?? btnSignInTitle
            btnSignUpTitle = askLogInVcInfo.value(forKey: "buttonSignUpText") as? String ?? btnSignUpTitle
        }
        
//        btnSignIn.isBordered = false
//        btnSignIn.wantsLayer = true
//        btnSignIn.layer?.cornerRadius = 8
//        btnSignIn.layer?.backgroundColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1).cgColor
//
//        var paragraph = NSMutableParagraphStyle()
//        paragraph.alignment = .center
//        var attrs = [NSAttributedString.Key.foregroundColor: NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1), NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
//        var attrString: NSAttributedString = NSAttributedString(string: btnSignInTitle, attributes: attrs)
//        btnSignIn.attributedTitle = attrString
        
        btnSignIn.title = btnSignInTitle
        
        
        
        btnSignUp.isBordered = false
//        btnSignUp.wantsLayer = true
//        btnSignUp.layer?.cornerRadius = 8
//        btnSignUp.layer?.backgroundColor = NSColor.clear.cgColor
//        btnSignUp.layer?.borderWidth = 1
//        btnSignUp.layer?.borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1).cgColor
//
//        paragraph = NSMutableParagraphStyle()
//        paragraph.alignment = .center
//        attrs = [NSAttributedString.Key.foregroundColor: NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1), NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
//        attrString = NSAttributedString(string: btnSignUpTitle, attributes: attrs)
//        btnSignUp.attributedTitle = attrString
        
        btnSignUp.title = btnSignUpTitle
        btnSignUp.buttonColor = NSColor.clear.cgColor
        
//        232 136 0
//        let image = #imageLiteral(resourceName: "Pattern")
//        self.boxBg.fillColor = NSColor(patternImage: image)
        
    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        addLog(text:"btnSignUpClicked")
        self.view.window?.close()
        appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
        appdelegate!.login(isLogin: false)
    }
    @IBAction func btnSignInClicked(_ sender: Any) {
        addLog(text:"btnSignInClicked")
        self.view.window?.close()
        appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
        appdelegate!.login(isLogin: true)
    }
}

