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
    
    @IBOutlet weak var lblOr: NSTextField!
    @IBOutlet weak var lblTitleCreateAccount: NSTextField!
    @IBOutlet weak var btnSignIn: underLineButton!
    @IBOutlet weak var boxButtonSignUpWithEmail: boxButton!
    @IBOutlet weak var boxButtonSignUpWithApple: boxButton!
    @IBOutlet weak var boxButtonSignUpWithGoogle: boxButton!
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
        
        lblOr.stringValue = "OR"
        
        var buttonSignUpWithGoogle = "Regístrate con Google"
        var buttonSignUpWithApple = "Regístrate con Apple"
        var buttonSignUpWithEmail = "Regístrate con correo electrónico"
        var buttonSignInOldAccountText = "¿Ya tienes una cuenta de Focus Bear? Inicia sesión"
        var buttonCreateAccount = "Crea tu cuenta"
        
        
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblMessage.stringValue = askLogInVcInfo.value(forKey: "messageText") as? String ?? lblMessage.stringValue
            btnSignInWithEmail.title = askLogInVcInfo.value(forKey: "buttonSignInEmailText") as? String ?? btnSignInWithEmail.title
            btnSignInWithGoogle.title = askLogInVcInfo.value(forKey: "buttonSignInGoogleText") as? String ?? btnSignInWithGoogle.title
            btnSignInWithApple.title = askLogInVcInfo.value(forKey: "buttonSignInAppleText") as? String ?? btnSignInWithApple.title
            buttonSignUpWithGoogle = askLogInVcInfo.value(forKey: "buttonSignUpWithGoogle") as? String ?? buttonSignUpWithGoogle
            buttonSignUpWithApple = askLogInVcInfo.value(forKey: "buttonSignUpWithApple") as? String ?? buttonSignUpWithApple
            buttonSignUpWithEmail = askLogInVcInfo.value(forKey: "buttonSignUpWithEmail") as? String ?? buttonSignUpWithEmail
            buttonSignInOldAccountText = askLogInVcInfo.value(forKey: "buttonSignInOldAccountText") as? String ?? buttonSignInOldAccountText
            buttonCreateAccount = askLogInVcInfo.value(forKey: "buttonCreateAccount") as? String ?? buttonCreateAccount
            lblOr.stringValue = askLogInVcInfo.value(forKey: "orText") as? String ?? lblOr.stringValue
        }
        
        btnSignUp.isBordered = false
        
        if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
            btnSignUp.title = customLoginVcInfo.value(forKey: "buttonCreateAccountText") as? String ?? btnSignUp.title
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
    
    var messageBoxView: NSView?
    var hideWorkItem: DispatchWorkItem?
    
    func showMessageBoxFor(sender: NSBox) {
        guard
            let window = sender.window,
            let contentView = window.contentView
        else { return }

        // Cancel previous timer
        hideWorkItem?.cancel()
        hideWorkItem = nil

        // Remove existing box
        messageBoxView?.removeFromSuperview()

        let vc = getMessageBoxVcObject()
        let boxView = vc.view
        messageBoxView = boxView

        // 🔁 Convert sender bounds → window contentView
        let senderRectInContent =
            sender.convert(sender.bounds, to: contentView)

        let boxSize = boxView.frame.size

        let x = senderRectInContent.maxX + 8
        let y = senderRectInContent.midY - boxSize.height / 2

        boxView.frame = NSRect(
            x: x,
            y: y,
            width: boxSize.width,
            height: boxSize.height
        )

        boxView.alphaValue = 1
        contentView.addSubview(boxView)

        // ⏱ Auto hide after 10 seconds
        let workItem = DispatchWorkItem { [weak self, weak boxView] in
            guard let view = boxView else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.25
                view.animator().alphaValue = 0
            }, completionHandler: {
                view.removeFromSuperview()
                self?.messageBoxView = nil
            })
        }

        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
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
                        askLogInWcObj?.window?.close()
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
//        let request = ASAuthorizationAppleIDProvider().createRequest()
//        request.requestedScopes = [.fullName, .email]
//        
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = self
//        controller.presentationContextProvider = self
//        DispatchQueue.main.async {
//            controller.performRequests()
//        }
        // added on 2.27.425
        Auth0
            .webAuth()
            .connection("apple") // Apple connection in Auth0
            .audience("https://auth.focusbear.io/api/v2/") // same audience
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    print("Logged in with Apple: \(credentials)")
                    
                    DispatchQueue.main.async {
                        askLogInWcObj?.window?.close()
                        appdelegate?.statusbutton?.action = nil
                        
                        appdelegate?.user = AuthUser(from: credentials.accessToken)
                        
                        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
                        _ = appdelegate?.credentialsManager.store(credentials: credentials)
                        
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                        appdelegate?.loadCredentialsAndDeviceId()
                        //                        UserDefaults.standard.set(true, forKey: kUserDefaultsLastUserLoginWithApple)
                    }
                    
                case .failure(let error):
                    print("Apple login failed: \(error)")
                    DispatchQueue.main.async {
                        askLogInWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.modalPanelWindow)))
                    }
                }
            }
        
        
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
        
        
        return;
        addLog(text:"[user-action] btnSignInWithAppleClicked")
        allApiObject.capturePosthog(event: "button-signin-with-apple-clicked", metadata: [:])
        self.presentAsSheet(loginComingSoonMsgVcObject())
    }
    
    
    
    func startAppleLogin() {
        let clientID = "com.focusbear.applesignin"
        let redirectURI = "Focus Bear://auth/callback"
        
        let authURL = URL(string:
            "https://appleid.apple.com/auth/authorize?" +
            "response_type=code%20id_token&" +
            "client_id=\(clientID)&" +
            "redirect_uri=\(redirectURI)&" +
            "scope=email%20name"
        )!
        
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "yourapp"
        ) { callbackURL, error in
            guard error == nil, let callbackURL = callbackURL else {
                print("Login canceled or failed")
                return
            }
            // Extract ?code= and ?id_token= from callbackURL
            print("Apple returned: \(callbackURL)")
        }
        
        session.start()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let authorizationCodeData = credential.authorizationCode,
           let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) {
            
            // Exchange Apple authorizationCode with Auth0
            let url = URL(string: "https://YOUR_DOMAIN.auth0.com/oauth/token")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
                "subject_token_type": "http://auth0.com/oauth/token-type/apple-authz-code",
                "scope": "openid profile email offline_access",
                "audience": "https://auth.focusbear.io/api/v2/",
                "subject_token": authorizationCode,
                "client_id": "com.focusbear.applesignin",
                "user_profile": [
                    "name": [
                        "firstName": credential.fullName?.givenName ?? "",
                        "lastName": credential.fullName?.familyName ?? ""
                    ],
                    "email": credential.email ?? ""
                ]
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data {
                    do {
                        let result = try JSONSerialization.jsonObject(with: data, options: [])
                        print("Auth0 response: \(result)")
                        // store credentials in CredentialsManager like you do for Google
                    } catch {
                        print("Failed to decode: \(error)")
                    }
                }
            }.resume()
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
        btnSignInWithGoogleClicked(self)
        showMessageBoxFor(sender: boxButtonSignUpWithGoogle)
    }
    @objc func signUpWithApple(){
        btnSignInWithAppleClicked(self)
        showMessageBoxFor(sender: boxButtonSignUpWithApple)
    }
    @objc func signUpWithEmail(){
        btnSignUpClicked(self)
    }
    
    @IBAction func btnSignInClicked(_ sender: Any) {
        btnSignInWithEmailClicked(self)
    }
}
// com.focusbear.applesignin




