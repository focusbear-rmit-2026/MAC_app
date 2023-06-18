//
//  askLogInVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askLogInVc: NSViewController {
    
    @IBOutlet weak var btnInfo: NSButton!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var btnSignUp: Button!
    @IBOutlet weak var btnSignIn: underLineButton!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    //    var isCustomLoginAvailable = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Win your habits.\nAmp up your productivity."
        lblMessage.stringValue = "Sign In with a Focus Bear account to manage your time without thinking about it. Having an account helps you Set your computer use hours, create a custom morning and night routine, and customize your focus modes for different activities."
        var btnSignInTitle = "Sign In"
//        var btnSignUpTitle = "Sign Up"
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
            btnSignInTitle = askLogInVcInfo.value(forKey: "buttonSignInText") as? String ?? btnSignInTitle
//            btnSignUpTitle = askLogInVcInfo.value(forKey: "buttonSignUpText") as? String ?? btnSignUpTitle
        }
        
        
        
        btnSignIn.title = btnSignInTitle
//        btnSignUp.title = btnSignUpTitle
        btnSignUp.isBordered = false
        
        
        
        if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
            btnSignUp.title = customLoginVcInfo.value(forKey: "buttonCreateAccountText") as? String ?? btnSignUp.title
        }

    }
    override func viewWillAppear() {
        appdelegate!.menuItemUninstall.isHidden = false
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            appdelegate!.menuItemUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? appdelegate!.menuItemUninstall.title
        }
        btnInfo.isHidden = false
        lblMessage.stringValue = "Nearly done! Let's grab a few details to save your habits."
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "descriptionText") as? String ?? lblMessage.stringValue
        }
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        lblMessage.stringValue = "Sign In with a Focus Bear account to manage your time without thinking about it. Having an account helps you Set your computer use hours, create a custom morning and night routine, and customize your focus modes for different activities."
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
        }
        btnInfo.isHidden = true
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
