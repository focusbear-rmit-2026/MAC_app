//
//  setUpAccountVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 25/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0

class setUpAccountVc: NSViewController {
    
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnSignUp: Button!
    @IBOutlet weak var btnStayAnonymous: Button!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblSubtile: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleViewLeft:BubbleView?
    var titleSignupFailed = "Signup failed."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Set up an account"
        lblSubtile.stringValue = "Stay focused across all your devices - no matter where you work."
        btnStayAnonymous.title = "I’ll stay anonymous"
        btnSignUp.title = "Sign me up, Scotty!"
        
        if let setUpAccountVcInfo = configjson["setUpAccountVcInfo"] as? [String: Any] {
            
            lblTitle.stringValue =  setUpAccountVcInfo["titleText"] as? String ?? lblTitle.stringValue
            
            lblSubtile.stringValue = setUpAccountVcInfo["subtitleText"] as? String ?? lblSubtile.stringValue
            
            btnStayAnonymous.title = setUpAccountVcInfo["buttonStayAnonymous"] as? String ?? btnStayAnonymous.title
            
            btnSignUp.title = setUpAccountVcInfo["buttonSignUp"] as? String ?? btnSignUp.title
            
            titleSignupFailed = setUpAccountVcInfo["titleSignupFailed"] as? String ?? titleSignupFailed
        }
        
        
        btnStayAnonymous.isSecondaryButton = true
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "setup-account-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // Show left bubble with offset 40px ABOVE center (negative value)
        
        var bubbleLeftText = "That way, we can work together on your computer and phone!"

        if let setUpAccountVcInfo = configjson["setUpAccountVcInfo"] as? [String: Any] {
            bubbleLeftText = setUpAccountVcInfo["bubbleLeftText"] as? String ?? bubbleLeftText
        }

        if bubbleViewLeft == nil{
            bubbleViewLeft = PopupManager.showPopup(for: imgView, edge: .minX, selfView: self.view, text: bubbleLeftText, verticalOffset: -50, horizontalOffset: 50)
        }
    }
    
    @IBAction func btnStayAnonymousClicked(_ sender: Any) {
        addLog(text: "[user-action] setUpAccountVc:-btnStayAnonymousClicked")
        allApiObject.capturePosthog(event: "button-stay-anonymous-clicked", metadata: [:])
        perfromCreateFakeAccount()
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-sign-me-up-clicked", metadata: [:])
        addLog(text: "[user-action] setUpAccountVc:-btnSignUpClicked")
        getOnboardingVcObject().navigate(to: ._PRIVACY_POLICY_)
    }
    
    func perfromCreateFakeAccount(){
        addLog(text: "perfrom Create Fake Account")
        let password = "Passw0rd!"
        var email = "anonymoususer+\(getUuid())@focusbear.io"
        
        if isTestUser{
            email = "internaltest+\(getUuid())@focusbear.io"
        }
        
        
        loader.startAnimation(self)
        btnSignUp.isEnabled = false
        self.btnStayAnonymous.isEnabled = false
        
        Auth0
            .authentication()
            .signup(email:email,
                    password: password,
                    connection: "Username-Password-Authentication",
                    userMetadata: [:])
            .start { result in
                
                
                
                switch result {
                case .success(let user):
                    print("User signed up: \(user)")
                    allApiObject.capturePosthog(event: "register-homemade", metadata: [:])
                    DispatchQueue.main.async {
                        Auth0
                            .authentication()
                            .login(usernameOrEmail: email,
                                   password: password,
                                   realmOrConnection: "Username-Password-Authentication",
                                   audience:"https://auth.focusbear.io/api/v2/",
                                   scope: "openid profile email offline_access")
                            .start { result in
                                
                                DispatchQueue.main.async {
                                    self.loader.stopAnimation(self)
                                    self.btnSignUp.isEnabled = true
                                    self.btnStayAnonymous.isEnabled = true
                                }
                                switch result {
                                case .success(let credentials):
                                    addLog(text: "Obtained credentials")
                                    DispatchQueue.main.async {
                                        if !getCustomLoginVcObject().isViewLoaded{
                                            getCustomLoginVcObject().loadView()
                                        }
                                        getCustomLoginVcObject().loginDone(credentials: credentials, isLogin: false)
                                    }
                                case .failure(let error):
                                    addLog(text: "login failed after signup")
                                    print("Failed with: \(error)")
                                    DispatchQueue.main.async {
                                        
                                        self.alertforvalidation(question: self.titleSignupFailed, text: error.localizedDescription)
                                    }
                                }
                            }
                        
                    }
                    
                    
                case .failure(let error):
                    addLog(text: "signup failed")
                    print("Failed with: \(error)")
                    DispatchQueue.main.async {
                        self.loader.stopAnimation(self)
                        self.btnSignUp.isEnabled = true
                        self.btnStayAnonymous.isEnabled = true
                        
                        
                        if error.code == "invalid_password"{
                            var message = self.titleSignupFailed
                            var info = error.localizedDescription
                            message = error.info["message"] as? String ?? ""
                            info = error.info["policy"] as? String ?? ""
                            self.alertforvalidation(question: message, text: info)
                        }else{
                            self.alertforvalidation(question: self.titleSignupFailed, text: error.localizedDescription)
                        }
                    }
                }
            }
    }
    
    func alertforvalidation(question: String, text: String) {
        let alert: NSAlert = NSAlert()
        alert.setSharingType()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonOkText)
        
        alert.beginSheetModal(for: view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                // self.txtFieldEmail.stringValue = ""
            }
        })
        
    }
}
