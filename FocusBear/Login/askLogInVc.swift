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
    
    //    var isCustomLoginAvailable = false
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
        
        
        
        btnSignIn.title = btnSignInTitle
        btnSignUp.title = btnSignUpTitle
        btnSignUp.isBordered = false
        
        
        
        btnSignIn.buttonColor = NSColor.clear.cgColor
        
        
        //        if #available(OSX 12.0, *) {
        //            isCustomLoginAvailable = false// ager ye kiya to event bi capture krne honge universal login mai
        //        }else{
        //            isCustomLoginAvailable = true
        //        }
        //        isCustomLoginAvailable = true
    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        addLog(text:"btnSignUpClicked")
        
//        if Reachability.isConnectedToNetwork() == false {
//            if self.view.window != nil{
//                showAlertNoInternet(window: self.view.window!)
//            }
//            return
//        }
        
        self.view.window?.close()
        
        //        if !isCustomLoginAvailable {
        //            appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
        //            appdelegate!.login(isLogin: false)
        //        }else{
        showCustomLoginWindow(isLogin: false)
        //        }
        
    }
    @IBAction func btnSignInClicked(_ sender: Any) {
        addLog(text:"btnSignInClicked")
        
//        if Reachability.isConnectedToNetwork() == false {
//            if self.view.window != nil{
//                showAlertNoInternet(window: self.view.window!)
//            }
//            return
//        }
        
        self.view.window?.close()
        
        //        if !isCustomLoginAvailable {
        //            appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
        //            appdelegate!.login(isLogin: true)
        //        }else{
        showCustomLoginWindow(isLogin: true)
        //        }
        
    }
    func showAlertNoInternet(window:NSWindow){
        var noInternetTitle = "No Internet Connection"
        var noInternetSubTitle = "Make sure your device is connected to the internet."
        addLog(text: "No Internet Connection")
        if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{//useful text
            if let text = activationNagInfo.value(forKey: "noInternetTitle") as? String{
                noInternetTitle = text
            }
            if let text = activationNagInfo.value(forKey: "noInternetSubTitle") as? String{
                noInternetSubTitle = text
            }
        }
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = noInternetTitle
        alert.informativeText = noInternetSubTitle
        alert.alertStyle = .warning
        alert.addButton(withTitle:  buttonOkText)
        alert.beginSheetModal(for: window, completionHandler: {_ in
            
        })
    }
}

//
