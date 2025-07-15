//
//  askLogInVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0

class askLogInVc: NSViewController {
    
    @IBOutlet weak var btnInfo: NSButton!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var btnSignUp: Button!
    @IBOutlet weak var btnSignInWithEmail: underLineButton!
    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnSignInWithGoogle: underLineButton!
    @IBOutlet weak var btnSignInWithApple: underLineButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Win your habits.\nAmp up your productivity."
        lblMessage.stringValue = "Sign In with a Focus Bear account to manage your time without thinking about it. Having an account helps you Set your computer use hours, create a custom morning and night routine, and customize your focus modes for different activities."
        
        btnSignInWithEmail.title = "Sign In with Email"
        btnSignInWithGoogle.title = "Sign In with Google"
        btnSignInWithApple.title = "Sign In with Apple"
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
            btnSignInWithEmail.title = askLogInVcInfo.value(forKey: "buttonSignInEmailText") as? String ?? btnSignInWithEmail.title
            btnSignInWithGoogle.title = askLogInVcInfo.value(forKey: "buttonSignInGoogleText") as? String ?? btnSignInWithGoogle.title
            btnSignInWithApple.title = askLogInVcInfo.value(forKey: "buttonSignInAppleText") as? String ?? btnSignInWithApple.title
        }

        btnSignUp.isBordered = false

        if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
            btnSignUp.title = customLoginVcInfo.value(forKey: "buttonCreateAccountText") as? String ?? btnSignUp.title
        }
        allApiObject.capturePosthog(event: "pre-signin-view-shown", metadata: [:])
    }
    override func viewWillAppear() {
        appdelegate!.menuItemUninstall.isHidden = false
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            appdelegate!.menuItemUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? appdelegate!.menuItemUninstall.title
        }
        btnInfo.isHidden = false
        lblMessage.stringValue = "Learn why this is needed"
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "descriptionText") as? String ?? lblMessage.stringValue
        }
        
        
        //remember email address #1308   15/3/25
        if UserDefaults.standard.object(forKey: kUserDefaultsLastUserLoginWithGoogle) != nil{
            addLog(text:"trySignInWithGoogle:- because last user was logged in with google and it was a automatic logged out")
            trySignInWithGoogle()
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastUserLoginWithGoogle)
        }else if let lastUserEmail = UserDefaults.standard.object(forKey: kUserDefaultsLastUserEmailBeforeLogout) as? String{
            addLog(text:"showCustomLoginWindow:- because last user email found")
            showCustomLoginWindow(isLogin: true)
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    customLoginVcObj?.textFieldEmail.stringValue = lastUserEmail
                }
            }
        }
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "pre-signin-view-info-icon-clicked", metadata: [:])
        
        lblMessage.stringValue = "Sign In with a Focus Bear account to manage your time without thinking about it. Having an account helps you Set your computer use hours, create a custom morning and night routine, and customize your focus modes for different activities."
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
        }
        btnInfo.isHidden = true
    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        addLog(text:"[user-action] btnSignUpClicked")
        allApiObject.capturePosthog(event: "button-signup-with-email-clicked", metadata: [:])
        self.view.window?.close()
        showCustomLoginWindow(isLogin: false)
    }
    
    @IBAction func btnSignInWithEmailClicked(_ sender: Any) {
        addLog(text:"[user-action] btnSignInClicked")
        allApiObject.capturePosthog(event: "button-signin-with-google-clicked", metadata: [:])
//        self.view.window?.close()
        showCustomLoginWindow(isLogin: true) 
    }
    
    var loginComingSoonMsgVcObj:loginComingSoonMsgVc?
    func loginComingSoonMsgVcObject()->loginComingSoonMsgVc{
        if loginComingSoonMsgVcObj == nil{
            loginComingSoonMsgVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("loginComingSoonMsgVc")) as? loginComingSoonMsgVc
        }
        return loginComingSoonMsgVcObj!
    }
    
    @IBAction func btnSignInWithGoogleClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-signin-with-email-clicked", metadata: [:])
        addLog(text:"[user-action] btnSignInWithGoogleClicked")
        trySignInWithGoogle()
    }
    
    func trySignInWithGoogle(){
        askLogInWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
        Auth0
            .webAuth()
            .connection("google-oauth2") // The connection name for Google
            .audience("https://auth.focusbear.io/api/v2/")
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    print("Logged in with Google: \(credentials)")
                    // Handle successful login, save credentials, or transition to the next screen
                    print(credentials.accessToken)
                    DispatchQueue.main.async {
                        self.view.window?.close()
                        appdelegate!.statusbutton?.action = nil
                        appdelegate!.user = AuthUser(from: credentials.accessToken)
                        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
                        let _ = appdelegate!.credentialsManager.store(credentials: credentials)
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                        appdelegate!.loadCredentialsAndDeviceId()
                        UserDefaults.standard.set(true, forKey: kUserDefaultsLastUserLoginWithGoogle)
                    }
                case .failure(let error):
                    print("Google login failed: \(error)")
                    // Handle login failure, show an error message
                    DispatchQueue.main.async {
                        askLogInWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
                    }
                }
            }
    }
    
    @IBAction func btnSignInWithAppleClicked(_ sender: Any) {
//        Auth0
//            .webAuth()
//            .connection("apple") // The connection name for Apple
//            .start { result in
//                switch result {
//                case .success(let credentials):
//                    print("Logged in with Apple: \(credentials)")
//                    // Handle successful login, save credentials, or transition to the next screen
//
//                    self.view.window?.close()
//                    appdelegate!.statusbutton?.action = nil
//                    appdelegate!.user = AuthUser(from: credentials.accessToken)
//                    allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
//                    let _ = appdelegate!.credentialsManager.store(credentials: credentials)
//                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
//                    appdelegate!.loadCredentialsAndDeviceId()
//
//                case .failure(let error):
//                    print("Apple login failed: \(error)")
//                    // Handle login failure, show an error message
//                }
//            }
//
//
//        return;
        addLog(text:"[user-action] btnSignInWithAppleClicked")
        allApiObject.capturePosthog(event: "button-signin-with-apple-clicked", metadata: [:])
        self.presentAsSheet(loginComingSoonMsgVcObject())
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
