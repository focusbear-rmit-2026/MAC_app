//
//  askLogInVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0
import AuthenticationServices

class askLogInVc: NSViewController, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var customViewMessageBox: NSView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var lblOr: NSTextField!
    @IBOutlet weak var lblTitleCreateAccount: NSTextField!
    @IBOutlet weak var btnSignIn: underLineButton!
    @IBOutlet weak var boxButtonSignUpWithEmail: boxButton!
    @IBOutlet weak var boxButtonSignUpWithApple: boxButton!
    @IBOutlet weak var boxButtonSignUpWithGoogle: boxButton!
    
    var bubbleView:BubbleView?
    var messageBoxView: NSView?
    var hideWorkItem: DispatchWorkItem?
    var bubbleContinueInBrowserView:BubbleView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblOr.stringValue = "OR"
        
        var buttonSignUpWithGoogle = "Regístrate con Google"
        var buttonSignUpWithApple = "Regístrate con Apple"
        var buttonSignUpWithEmail = "Regístrate con correo electrónico"
        var buttonSignInOldAccountText = "¿Ya tienes una cuenta de Focus Bear? Inicia sesión"
        var buttonCreateAccount = "Crea tu cuenta"
        
        lblSubTitle.stringValue = "We use Auth0, our secure login partner, to sign you in."
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            buttonSignUpWithGoogle = askLogInVcInfo.value(forKey: "buttonSignUpWithGoogle") as? String ?? buttonSignUpWithGoogle
            buttonSignUpWithApple = askLogInVcInfo.value(forKey: "buttonSignUpWithApple") as? String ?? buttonSignUpWithApple
            buttonSignUpWithEmail = askLogInVcInfo.value(forKey: "buttonSignUpWithEmail") as? String ?? buttonSignUpWithEmail
            buttonSignInOldAccountText = askLogInVcInfo.value(forKey: "buttonSignInOldAccountText") as? String ?? buttonSignInOldAccountText
            buttonCreateAccount = askLogInVcInfo.value(forKey: "buttonCreateAccount") as? String ?? buttonCreateAccount
            lblOr.stringValue = askLogInVcInfo.value(forKey: "orText") as? String ?? lblOr.stringValue
            lblSubTitle.stringValue = askLogInVcInfo.value(forKey: "subTitleText") as? String ?? lblSubTitle.stringValue
        }
        allApiObject.capturePosthog(event: "pre-signin-view-shown", metadata: [:])
        boxButtonSignUpWithGoogle.setTitle(buttonSignUpWithGoogle)
        boxButtonSignUpWithGoogle.setImage(NSImage(named: "google_logo"))
        boxButtonSignUpWithGoogle.target = self
        boxButtonSignUpWithGoogle.action = #selector(signUpWithGoogle)
        
        boxButtonSignUpWithApple.setTitle(buttonSignUpWithApple)
        boxButtonSignUpWithApple.setImage(NSImage(named: "apple_logo"))
        boxButtonSignUpWithApple.target = self
        boxButtonSignUpWithApple.action = #selector(signUpWithApple)
        
        boxButtonSignUpWithEmail.setButtonColor(NSColor.white)
        boxButtonSignUpWithEmail.setTitle(buttonSignUpWithEmail)
        boxButtonSignUpWithEmail.setImage(NSImage(named: "email"))
        boxButtonSignUpWithEmail.target = self
        boxButtonSignUpWithEmail.action = #selector(signUpWithEmail)
        
        btnSignIn.title = buttonSignInOldAccountText
        lblTitleCreateAccount.stringValue = buttonCreateAccount
        btnSignIn.setAccessibilityIdentifier(UITestContract.Identifier.Login.goToSignInButton)
        boxButtonSignUpWithEmail.setAccessibilityIdentifier(UITestContract.Identifier.Login.signUpWithEmailButton)
        boxButtonSignUpWithGoogle.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.signUpWithGoogleButton)
        boxButtonSignUpWithApple.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.signUpWithAppleButton)
    }
    
    override func viewWillAppear() {
        appdelegate!.menuItemUninstall.isHidden = false
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            appdelegate!.menuItemUninstall.title = common.value(forKey: "buttonUninstallText") as? String ?? appdelegate!.menuItemUninstall.title
        }
        
        //remember email address #1308   15/3/25
        // Only auto-retrigger Google sign-in for the Old user logout case — NOT
        // during onboarding. A fresh Google sign-up sets kUserDefaultsLastUserLoginWithGoogle, and
        // completeRemainingOnboarding re-attaches askLogInVc, so this viewWillAppear fires again and
        // would pop the Auth0 prompt a second time. Guard it out while onboarding is active.
        if currentState != ._ONBOARDING_, UserDefaults.standard.object(forKey: kUserDefaultsLastUserLoginWithGoogle) != nil{
            addLog(text:"trySignInWithGoogle:- because last user was logged in with google and it was a automatic logged out")
            trySignInWithGoogle()
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastUserLoginWithGoogle)
        }
    }
    
    override func viewDidAppear() {
        var bubbleText = "One account, all your devices - let's get you set up!"
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            bubbleText = askLogInVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 50)
        }
    }
    

    func showMessageBoxFor(sender: NSBox) {
        // Cancel previous timer
        if bubbleContinueInBrowserView != nil{
            return;
        }
        
        hideWorkItem?.cancel()
        hideWorkItem = nil

        // Remove existing box
        messageBoxView?.removeFromSuperview()
        
        var title = "Continue in your browser"
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            title = askLogInVcInfo.value(forKey: "continueInBrowser") as? String ?? title
        }
  
        bubbleContinueInBrowserView = PopupManager.showPopup(for: boxButtonSignUpWithApple, edge: .maxX, selfView: self.view, text: title, horizontalOffset: 10, image: NSImage(named: "continueInBrowser"))
        

        // ⏱ Auto hide after 10 seconds
        let workItem = DispatchWorkItem { [weak self, weak bubbleContinueInBrowserView] in
            guard let view = bubbleContinueInBrowserView else { return }
            if self?.bubbleContinueInBrowserView == nil{
                return;
            }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                view.animator().alphaValue = 0
            }, completionHandler: {
                view.removeFromSuperview()
                self?.bubbleContinueInBrowserView = nil
            })
        }

        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
    }

    func trySignInWithGoogle(){
        Auth0
            .webAuth()
            .connection("google-oauth2") // The connection name for Google
            .audience("https://auth.focusbear.io/api/v2/")
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    addLog(text: "Logged in with Google")
                    // Handle successful login, save credentials, or transition to the next screen
                    DispatchQueue.main.async {
                        askLogInWcObj?.window?.close()
                        appdelegate!.statusbutton?.action = nil
                        appdelegate!.user = AuthUser(from: credentials.accessToken)
                        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
                        let _ = appdelegate!.credentialsManager.store(credentials: credentials)
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                        appdelegate!.loadCredentialsAndDeviceId()
                        UserDefaults.standard.set(true, forKey: kUserDefaultsLastUserLoginWithGoogle)
                        if currentState != ._ONBOARDING_{
                            leftMenuVcObj?.enableAllItems()
                            mainViewControllerObj?.expandLeftPanel()
                            mainViewControllerObj?.removeSubViews()
                            mainWindowControllerObj?.window?.close()
                            currentState = ._NOTHING_ // if not onboarding then make it nothing
                        }
                    }
                case .failure(let error):
                    print("Google login failed: \(error)")
                    // Handle login failure, show an error message
                }
            }
    }
    
     func trySignInWithApple() {
        // added on 2.27.425
        Auth0
            .webAuth()
            .connection("apple") // Apple connection in Auth0
            .audience("https://auth.focusbear.io/api/v2/") // same audience
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    addLog(text: "Logged in with Apple")

                    DispatchQueue.main.async {
                        askLogInWcObj?.window?.close()
                        appdelegate?.statusbutton?.action = nil
                        
                        appdelegate?.user = AuthUser(from: credentials.accessToken)
                        
                        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
                        _ = appdelegate?.credentialsManager.store(credentials: credentials)
                        
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                        appdelegate?.loadCredentialsAndDeviceId()
                        if currentState != ._ONBOARDING_{
                            leftMenuVcObj?.enableAllItems()
                            mainViewControllerObj?.expandLeftPanel()
                            mainViewControllerObj?.removeSubViews()
                            mainWindowControllerObj?.window?.close()
                            currentState = ._NOTHING_ // if not onboarding then make it nothing
                        }
                    }
                    
                case .failure(let error):
                    print("Apple login failed: \(error)")
                }
            }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple login failed: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
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
    
    @objc func signUpWithGoogle(){
        allApiObject.capturePosthog(event: "button-signin-with-google-clicked", metadata: [:])
        addLog(text:"[user-action] btnSignInWithGoogleClicked")
        trySignInWithGoogle()
        showMessageBoxFor(sender: boxButtonSignUpWithGoogle)
    }
    
    @objc func signUpWithApple(){
        allApiObject.capturePosthog(event: "button-signin-with-apple-clicked", metadata: [:])
        addLog(text:"[user-action] btnSignInWithAppleClicked")
        trySignInWithApple()
        showMessageBoxFor(sender: boxButtonSignUpWithApple)
    }
    
    @objc func signUpWithEmail(){
        addLog(text:"[user-action] btnSignUpClicked")
        allApiObject.capturePosthog(event: "button-signup-with-email-clicked", metadata: [:])
        showCustomLoginWindow(isLogin: false)
    }
    
    @IBAction func btnSignInClicked(_ sender: Any) {
        addLog(text:"[user-action] btnSignInClicked")
        allApiObject.capturePosthog(event: "button-signin-with-email-clicked", metadata: [:])
        showCustomLoginWindow(isLogin: true)
    }
}





