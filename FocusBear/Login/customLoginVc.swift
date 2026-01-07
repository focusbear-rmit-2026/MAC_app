//
//  customLoginVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0

class customLoginVc: NSViewController {

    
    @IBOutlet weak var btnSignInBottom: underLineButton!
    @IBOutlet weak var lblSignInBottom: NSTextField!
    @IBOutlet weak var boxAskSignIn: NSBox!
    
    @IBOutlet weak var btnSignUp: underLineButton!
    @IBOutlet weak var lblSignUpBottom: NSTextField!
    @IBOutlet weak var boxAskCreateAccount: NSBox!
    @IBOutlet weak var boxButtonSignUpWithApple: boxButton!
    @IBOutlet weak var boxButtonSignUpWithGoogle: boxButton!
    
    @IBOutlet weak var lblOr: NSTextField!
    @IBOutlet weak var boxSignInOptions: NSBox!
    @IBOutlet weak var lblRuleSixth: NSTextField!
    @IBOutlet weak var lblRuleFifth: NSTextField!
    @IBOutlet weak var lblRuleFourth: NSTextField!
    @IBOutlet weak var lblRuleThird: NSTextField!
    @IBOutlet weak var lblRuleSecond: NSTextField!
    @IBOutlet weak var lblRuleFirst: NSTextField!
    
    @IBOutlet weak var imgViewRuleFirst: NSImageView!
    @IBOutlet weak var imgViewRuleSecond: NSImageView!
    @IBOutlet weak var imgViewRuleThird: NSImageView!
    @IBOutlet weak var imgViewRuleFourth: NSImageView!
    @IBOutlet weak var imgViewRuleFifth: NSImageView!
    @IBOutlet weak var imgViewRuleSixth: NSImageView!
    
    @IBOutlet weak var stackViewPasswordRules: NSStackView!
    @IBOutlet weak var imgViewValidConfirmPassword: NSImageView!
    @IBOutlet weak var imgViewValidPassword: NSImageView!
    @IBOutlet weak var btnForgotPassword: underLineButton!
    @IBOutlet weak var btnShowConfirmPassword: cursorButton!
    @IBOutlet weak var btnShowPassword: cursorButton!
    @IBOutlet weak var textFieldConfirmPasword: NSTextField!
    @IBOutlet weak var textFieldPassword: NSTextField!
    @IBOutlet weak var topSpaceLblTitle: NSLayoutConstraint!
    @IBOutlet weak var lblTitlePasswordRules: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var secureTextFieldConfirmPassword: NSSecureTextField!
    @IBOutlet weak var secureTextFieldPassword: NSSecureTextField!
    @IBOutlet weak var textFieldEmail: NSTextField!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var btnCreateAccount: Button!
    @IBOutlet weak var btnSignIn: Button!
    @IBOutlet weak var boxConfirmPassword: NSBox!
    @IBOutlet weak var boxPassword: NSBox!
    @IBOutlet weak var boxEmailAddress: NSBox!
    @IBOutlet weak var lblConfirmPassword: NSTextField!
    @IBOutlet weak var lblPassword: NSTextField!
    @IBOutlet weak var lblSubtitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblEmailAddress: NSTextField!
    @IBOutlet weak var btnCopyPassword: Button!
    @IBOutlet weak var btnRefreshPassword: cursorButton!
    
    
    var btnShowPasswordTrackingArea: NSTrackingArea?
    
    var isLogin = true
    
    var titleEmailIsBlank = "Email cannot be blank."
    var emailInvalidText = "Please enter a valid Email."
    var titlePasswordIsBlank = "Password cannot be blank."
    var passwordInvalidText = "Please enter a valid password."
    var titleInvalidEmail = "Invalid Email"
    var titleConfirmPasswordBlank = "Confirm password cannot be blank."
    var confirmPasswordInvalidText = "Please enter a valid \"Confirm password\"."
    var titlePasswordNotMatch = "Passwords do not match."
    var confirmPasswordNotMatchText = "Confirm Password does not match with the main password. Please re enter."
    var titleSignupFailed = "Signup failed."
    var titleLoginFailed = "Login failed."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblOr.stringValue = "OR"
        
       // segmentControlPassword.selectedSegmentBezelColor = NSColor.systemBlue
        
        btnRefreshPassword.toolTip = "Refresh password"
        btnCopyPassword.toolTip = "Copy password"
        //checkBoxPasswordSave.title = "I saved the password somewhere safe"
        btnCopyPassword.title = "Copy"
        
        lblRuleFirst.stringValue = "At least 8 characters in length"
        lblRuleSecond.stringValue = "Contain at least 3 of the following 4 types of characters:"
        lblRuleThird.stringValue = "lower case letters (a-z)"
        lblRuleFourth.stringValue = "upper case letters (A-Z)"
        lblRuleFifth.stringValue = "numbers (i.e. 0-9)"
        lblRuleSixth.stringValue = "special characters (e.g. !@#$%^&*)"
        
        lblTitlePasswordRules.stringValue = "Password rules:"

        lblTitle.stringValue = "Sign In"
        lblSubtitle.stringValue = "Create an account"//"Welcome back"
        lblEmailAddress.stringValue = "Email Address"
        lblPassword.stringValue = "Password"
        lblConfirmPassword.stringValue = "Confirm your password"
        btnSignIn.title = "Sign In"
        btnCreateAccount.title = "Create an account"
        btnForgotPassword.title = "Forgot Password"
        
        var generatePasswordText = "Generate password"
        var useOwnPasswordText = "Use own password"
        
        lblSignInBottom.stringValue = "Already have an account?"
        btnSignInBottom.title = "Sign In"
        lblSignUpBottom.stringValue = "Don't have an account?"
        btnSignUp.title = "Sign Up"
        
        var buttonContinueWithGoogle = "Continue with Google"
        var buttonContinueWithApple = "Continue with Apple"
        
        if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
            lblEmailAddress.stringValue = customLoginVcInfo.value(forKey: "titleEmailAddress") as? String ?? lblEmailAddress.stringValue
            lblPassword.stringValue = customLoginVcInfo.value(forKey: "titlePassword") as? String ?? lblPassword.stringValue
            lblConfirmPassword.stringValue = customLoginVcInfo.value(forKey: "titleConfirmPassword") as? String ?? lblConfirmPassword.stringValue
            btnSignIn.title = customLoginVcInfo.value(forKey: "buttonSignInText") as? String ?? btnSignIn.title
            btnCreateAccount.title = customLoginVcInfo.value(forKey: "buttonCreateAccountText") as? String ?? btnCreateAccount.title
            
            
            titleEmailIsBlank = customLoginVcInfo.value(forKey: "titleEmailIsBlank") as? String ?? titleEmailIsBlank
            emailInvalidText = customLoginVcInfo.value(forKey: "emailInvalidText") as? String ?? emailInvalidText
            titlePasswordIsBlank = customLoginVcInfo.value(forKey: "titlePasswordIsBlank") as? String ?? titlePasswordIsBlank
            passwordInvalidText = customLoginVcInfo.value(forKey: "passwordInvalidText") as? String ?? passwordInvalidText
            titleInvalidEmail = customLoginVcInfo.value(forKey: "titleInvalidEmail") as? String ?? titleInvalidEmail
            titleConfirmPasswordBlank = customLoginVcInfo.value(forKey: "titleConfirmPasswordBlank") as? String ?? titleConfirmPasswordBlank
            confirmPasswordInvalidText = customLoginVcInfo.value(forKey: "confirmPasswordInvalidText") as? String ?? confirmPasswordInvalidText
            titlePasswordNotMatch = customLoginVcInfo.value(forKey: "titlePasswordNotMatch") as? String ?? titlePasswordNotMatch
            confirmPasswordNotMatchText = customLoginVcInfo.value(forKey: "confirmPasswordNotMatchText") as? String ?? confirmPasswordNotMatchText
            titleSignupFailed = customLoginVcInfo.value(forKey: "titleSignupFailed") as? String ?? titleSignupFailed
            titleLoginFailed = customLoginVcInfo.value(forKey: "titleLoginFailed") as? String ?? titleLoginFailed
            
            lblTitlePasswordRules.stringValue = customLoginVcInfo.value(forKey: "titlePasswordRules") as? String ?? lblTitlePasswordRules.stringValue
//            lblPasswordRules.stringValue = customLoginVcInfo.value(forKey: "passwordRulesText") as? String ?? lblPasswordRules.stringValue
            lblRuleFirst.stringValue = customLoginVcInfo.value(forKey: "passwordRuleFirstText") as? String ?? lblRuleFirst.stringValue
            lblRuleSecond.stringValue = customLoginVcInfo.value(forKey: "passwordRuleSecondText") as? String ?? lblRuleSecond.stringValue
            lblRuleThird.stringValue = customLoginVcInfo.value(forKey: "passwordRuleThirdText") as? String ?? lblRuleThird.stringValue
            lblRuleFourth.stringValue = customLoginVcInfo.value(forKey: "passwordRuleFourthText") as? String ?? lblRuleFourth.stringValue
            lblRuleFifth.stringValue = customLoginVcInfo.value(forKey: "passwordRuleFifthText") as? String ?? lblRuleFifth.stringValue
            lblRuleSixth.stringValue = customLoginVcInfo.value(forKey: "passwordRuleSixthText") as? String ?? lblRuleSixth.stringValue
            
            
            btnForgotPassword.title = customLoginVcInfo.value(forKey: "buttonForgotPasswordText") as? String ?? btnForgotPassword.title
            
            btnRefreshPassword.toolTip = customLoginVcInfo.value(forKey: "tooltipRefreshPassword") as? String ?? btnRefreshPassword.toolTip
            btnCopyPassword.toolTip = customLoginVcInfo.value(forKey: "tooltipCopyPassword") as? String ?? btnCopyPassword.toolTip
            //checkBoxPasswordSave.title = customLoginVcInfo.value(forKey: "checkBoxPasswordSavedText") as? String ?? checkBoxPasswordSave.title
            btnCopyPassword.title = customLoginVcInfo.value(forKey: "buttonCopyPasswordText") as? String ?? btnCopyPassword.title
            generatePasswordText = customLoginVcInfo.value(forKey: "generatePasswordText") as? String ?? generatePasswordText
            useOwnPasswordText = customLoginVcInfo.value(forKey: "useOwnPasswordText") as? String ?? useOwnPasswordText
            
            lblOr.stringValue = customLoginVcInfo.value(forKey: "orText") as? String ?? lblOr.stringValue
            lblSignInBottom.stringValue = customLoginVcInfo.value(forKey: "titleSignInAccount") as? String ?? lblSignInBottom.stringValue
            btnSignInBottom.title = customLoginVcInfo.value(forKey: "buttonSignInText") as? String ?? btnSignInBottom.title
            lblSignUpBottom.stringValue = customLoginVcInfo.value(forKey: "titleDontHaveAccount") as? String ?? lblSignUpBottom.stringValue
            btnSignUp.title = customLoginVcInfo.value(forKey: "titleSignUp") as? String ?? btnSignUp.title
            buttonContinueWithGoogle = customLoginVcInfo.value(forKey: "buttonContinueWithGoogle") as? String ?? buttonContinueWithGoogle
            buttonContinueWithApple = customLoginVcInfo.value(forKey: "buttonContinueWithApple") as? String ?? buttonContinueWithApple
        }
        
        //segmentControlPassword.setLabel(generatePasswordText, forSegment: 0)
        //segmentControlPassword.setLabel(useOwnPasswordText, forSegment: 1)
        
        textFieldPassword.delegate = self
        textFieldConfirmPasword.delegate = self
        secureTextFieldPassword.delegate = self
        secureTextFieldConfirmPassword.delegate = self
        
        
        btnShowPasswordTrackingArea = NSTrackingArea.init(rect: btnShowPassword.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        btnShowPassword.addTrackingArea(btnShowPasswordTrackingArea!)
        
        boxButtonSignUpWithGoogle.setTitle(buttonContinueWithGoogle)
        boxButtonSignUpWithGoogle.setImage(NSImage(named: "google_logo"))
        boxButtonSignUpWithGoogle.target = self
        boxButtonSignUpWithGoogle.action = #selector(signUpWithGoogle)
        
        boxButtonSignUpWithApple.setTitle(buttonContinueWithApple)
        boxButtonSignUpWithApple.setImage(NSImage(named: "apple_logo"))
        boxButtonSignUpWithApple.target = self
        boxButtonSignUpWithApple.action = #selector(signUpWithApple)
        
        
        
    }
    
    @objc func signUpWithGoogle(){
        askLogInVcObj?.btnSignInWithGoogleClicked(self)
    }
    
    @objc func signUpWithApple(){
        askLogInVcObj?.btnSignInWithAppleClicked(self)
    }
    
    override func viewWillAppear() {
        reloadView()
    }
    override func viewWillDisappear() {
        appdelegate!.menuItemUninstall.isHidden = true
    }
    
//    func showAnimation(){
//        DispatchQueue.global().async {
//            usleep(50000)
//            for i in 0..<6{
//                if i % 2 == 0{
//                    DispatchQueue.main.async {
//                        if self.boxPasswordGenerated.isHidden{
//                            return;
//                        }
//                        self.boxPasswordGenerated.fillColor = self.lblTitle.textColor ?? NSColor.red
//                    }
//                }else{
//                    DispatchQueue.main.async {
//                        self.boxPasswordGenerated.fillColor = NSColor.clear
//                        if self.boxPasswordGenerated.isHidden{
//                            return;
//                        }
//                    }
//                }
//                usleep(500000)
//            }
//        }
//    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == btnShowPasswordTrackingArea{
            var msg = "Show Password"
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                msg = customLoginVcInfo.value(forKey: "tooltipShowPassword") as? String ?? msg
            }
            showTooltip(sender: btnShowPassword, msg: msg , preferredEdge: NSRectEdge.minY, maxWidthVal:230)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == btnShowPasswordTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
    }
    
    func reloadView(){
        textFieldEmail.stringValue = ""
        secureTextFieldPassword.stringValue = ""
        secureTextFieldConfirmPassword.stringValue = ""
        textFieldPassword.stringValue = ""
        textFieldConfirmPasword.stringValue = ""
        
        textFieldPassword.isHidden = true
        textFieldConfirmPasword.isHidden = true
        
        imgViewValidPassword.isHidden = true
        imgViewValidConfirmPassword.isHidden = true
        secureTextFieldPassword.isHidden = false
        secureTextFieldConfirmPassword.isHidden = true
        btnShowPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
        btnShowConfirmPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
        btnShowConfirmPassword.isHidden = true
        
        imgViewRuleFirst.isHidden = true
        imgViewRuleSecond.isHidden = true
        imgViewRuleThird.isHidden = true
        imgViewRuleFourth.isHidden = true
        imgViewRuleFifth.isHidden = true
        imgViewRuleSixth.isHidden = true
        
        if isLogin{
            addLog(text: "login view ")
            allApiObject.capturePosthog(event: "view-signin-shown", metadata: [:])
            boxAskSignIn.isHidden = true
            secureTextFieldPassword.isEditable = true
            //checkBoxPasswordSave.isHidden = true
            btnCreateAccount.keyEquivalent = ""
            btnSignIn.keyEquivalent = "\r"
            btnCreateAccount.isEnabled = true
            btnForgotPassword.isHidden = false
            //topSpaceLblTitle.constant = 80
            lblTitle.stringValue = "Sign In"
            lblSubtitle.stringValue = "Sign In with a Focus Bear account"
            boxConfirmPassword.isHidden = true
            btnSignIn.isHidden = false
            btnCreateAccount.buttonColor = NSColor.white.cgColor
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                lblTitle.stringValue = customLoginVcInfo.value(forKey: "titleSignIn") as? String ?? lblTitle.stringValue
                lblSubtitle.stringValue = customLoginVcInfo.value(forKey: "subTitleSignIn") as? String ?? lblSubtitle.stringValue
            }
            lblTitlePasswordRules.isHidden = true
//            lblPasswordRules.isHidden = true
            stackViewPasswordRules.isHidden = true
            textFieldEmail.nextKeyView = secureTextFieldPassword
            secureTextFieldPassword.nextKeyView = textFieldEmail
            //segmentControlPassword.isHidden = true
            btnCopyPassword.isHidden = true
            btnRefreshPassword.isHidden = true
            boxSignInOptions.isHidden = false
            boxAskCreateAccount.isHidden = false
            btnCreateAccount.isHidden = true
        }else{
            addLog(text: "signup view ")
            allApiObject.capturePosthog(event: "view-signup-shown", metadata: [:])
            boxAskCreateAccount.isHidden = true
            btnCreateAccount.isHidden = false
            boxAskSignIn.isHidden = false
           // segmentControlPassword.isHidden = true
        //    segmentControlPassword.selectedSegment = 1
            segmentControlPasswordClicked(self)
            btnCreateAccount.keyEquivalent = "\r"
            btnSignIn.keyEquivalent = ""
            btnCreateAccount.isEnabled = false
            btnForgotPassword.isHidden = true
           // topSpaceLblTitle.constant = 80
            lblTitle.stringValue = "Sign Up"
            lblSubtitle.stringValue = "Create an account to sync your habit + block settings across all your devices."
            boxConfirmPassword.isHidden = true
            btnSignIn.isHidden = true
            btnCreateAccount.buttonColor = buttonBgColor.cgColor
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                lblTitle.stringValue = customLoginVcInfo.value(forKey: "titleSignUp") as? String ?? lblTitle.stringValue
                lblSubtitle.stringValue = customLoginVcInfo.value(forKey: "explainCreateAccountText") as? String ?? lblSubtitle.stringValue
            }
            textFieldEmail.nextKeyView = secureTextFieldPassword
            secureTextFieldPassword.nextKeyView = textFieldEmail
            boxSignInOptions.isHidden = true
            return;
            
            
            secureTextFieldPassword.isEditable = false
            secureTextFieldPassword.isSelectable = false
         //   segmentControlPassword.isHidden = false
          //  segmentControlPassword.selectedSegment = 0
            btnCreateAccount.keyEquivalent = "\r"
            btnSignIn.keyEquivalent = ""
            btnCreateAccount.isEnabled = false
            btnForgotPassword.isHidden = true
           // topSpaceLblTitle.constant = 80
            lblTitle.stringValue = "Sign Up"
            lblSubtitle.stringValue = "Create an account to sync your habit + block settings across all your devices."
            boxConfirmPassword.isHidden = true
            btnSignIn.isHidden = true
            btnCreateAccount.buttonColor = buttonBgColor.cgColor
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                lblTitle.stringValue = customLoginVcInfo.value(forKey: "titleSignUp") as? String ?? lblTitle.stringValue
                lblSubtitle.stringValue = customLoginVcInfo.value(forKey: "explainCreateAccountText") as? String ?? lblSubtitle.stringValue
            }
            lblTitlePasswordRules.isHidden = true
//            lblPasswordRules.isHidden = false
            stackViewPasswordRules.isHidden = true
            textFieldEmail.nextKeyView = secureTextFieldPassword
            secureTextFieldPassword.nextKeyView = textFieldEmail
            let passWord = generateSecurePassword()
            secureTextFieldPassword.stringValue = generateSecurePassword()
            btnCopyPassword.isHidden = false
            btnRefreshPassword.isHidden = true
          //  checkBoxPasswordSave.isHidden = false
          //  checkBoxPasswordSave.state = .off
            if isValidPassword(password: passWord){
                imgViewValidPassword.isHidden = true//will be hiiden default
                btnCreateAccount.isEnabled = false
            }else{
                imgViewValidPassword.isHidden = true
                btnCreateAccount.isEnabled = false
            }
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        addLog(text: "[user-action] btnBackClicked")
        showAskLoginWindow()
    }
    
    @IBAction func btnSignInClicked(_ sender: Any) {
        addLog(text: "[user-action] btnSignInClicked")
        allApiObject.capturePosthog(event: "button-signin-clicked", metadata: [:])
        var password = secureTextFieldPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }

        if textFieldEmail.stringValue.isEmpty == true
        {
            alertforvalidation(question: titleEmailIsBlank, text: emailInvalidText)
            return
        }else if password.isEmpty == true
        {
            alertforvalidation(question: titlePasswordIsBlank, text: passwordInvalidText)
            return
        }
        
        let value = isValidEmail(email: textFieldEmail.stringValue)
        if value == false
        {
            alertforvalidation(question: titleInvalidEmail, text: emailInvalidText)
            return
        }
        
        if Reachability.isConnectedToNetwork() == false {
            startLoader()
            allApiObject.isInternetOn(completionHandler: {isInternetOn in
                DispatchQueue.main.async {
                    self.stopLoader()
                    if !isInternetOn{
                        
                        if self.view.window != nil{
                            askLogInVcObj?.showAlertNoInternet(window: self.view.window!)
                        }
                    }else{
                        self.performSignIn()
                    }
                }
            })

            return;
        }
        performSignIn()
    }
    func startLoader(){
        loader.startAnimation(self)
        btnSignIn.isEnabled = false
        btnCreateAccount.isEnabled = false
        textFieldEmail.isEnabled = false
        secureTextFieldPassword.isEnabled = false
        textFieldPassword.isEnabled = false
        self.btnBack.isEnabled = false
        self.btnForgotPassword.isEnabled = false
        self.secureTextFieldConfirmPassword.isEnabled = false
        self.textFieldConfirmPasword.isEnabled = false
    }
    func stopLoader(){
        self.loader.stopAnimation(self)
        self.btnSignIn.isEnabled = true
        self.btnCreateAccount.isEnabled = true
        self.textFieldEmail.isEnabled = true
        self.secureTextFieldPassword.isEnabled = true
        self.textFieldPassword.isEnabled = true
        self.btnBack.isEnabled = true
        self.btnForgotPassword.isEnabled = true
        self.secureTextFieldConfirmPassword.isEnabled = true
        self.textFieldConfirmPasword.isEnabled = true
    }
    func performSignIn(){
        var password = secureTextFieldPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        let email = textFieldEmail.stringValue
        
        loader.startAnimation(self)
        btnSignIn.isEnabled = false
        btnCreateAccount.isEnabled = false
        textFieldEmail.isEnabled = false
        secureTextFieldPassword.isEnabled = false
        textFieldPassword.isEnabled = false
        self.btnBack.isEnabled = false
        self.btnForgotPassword.isEnabled = false
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
                    self.btnSignIn.isEnabled = true
                    self.btnCreateAccount.isEnabled = true
                    self.textFieldEmail.isEnabled = true
                    self.secureTextFieldPassword.isEnabled = true
                    self.textFieldPassword.isEnabled = true
                    self.btnBack.isEnabled = true
                    self.btnForgotPassword.isEnabled = true
                }
                switch result {
                case .success(let credentials):
                    print("Obtained credentials: \(credentials)")
                    DispatchQueue.main.async {
                        self.loginDone(credentials: credentials, isLogin: true)
                    }
                case .failure(let error):
                    print("Failed with: \(error)")
                    addLog(text: "login failed")
                    DispatchQueue.main.async {
                        self.alertforvalidation(question: self.titleLoginFailed, text: error.localizedDescription)
                    }
                }
            }
    }
    func loginDone(credentials: (Credentials), isLogin:Bool){
        addLog(text: "Custom Login success")
        self.view.window?.close()
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastBreaksStartTime)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastBreakEndTime)
        appdelegate!.statusbutton?.action = nil
        appdelegate!.user = AuthUser(from: credentials.accessToken)
        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
        let _ = appdelegate!.credentialsManager.store(credentials: credentials)
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
        appdelegate!.needToCheckEmailVerification = true
        appdelegate!.loadCredentialsAndDeviceId()
    }
    
    @IBAction func btnShowConfirmPasswordClicked(_ sender: Any) {
        if textFieldConfirmPasword.isHidden{
            textFieldConfirmPasword.stringValue = secureTextFieldConfirmPassword.stringValue
            textFieldConfirmPasword.isHidden = false
            secureTextFieldConfirmPassword.isHidden = true
            btnShowConfirmPassword.image = #imageLiteral(resourceName: "eye Icon")
            textFieldConfirmPasword.setFocus()
            
            
            if textFieldPassword.isHidden{
                textFieldEmail.nextKeyView = secureTextFieldPassword
                secureTextFieldPassword.nextKeyView = textFieldConfirmPasword
            }else{
                textFieldEmail.nextKeyView = textFieldPassword
                textFieldPassword.nextKeyView = textFieldConfirmPasword
            }
            textFieldConfirmPasword.nextKeyView = textFieldEmail
            
        }else{
            secureTextFieldConfirmPassword.stringValue = textFieldConfirmPasword.stringValue
            textFieldConfirmPasword.isHidden = true
            secureTextFieldConfirmPassword.isHidden = false
            btnShowConfirmPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
            secureTextFieldConfirmPassword.setFocus()
            
            if textFieldPassword.isHidden{
                textFieldEmail.nextKeyView = secureTextFieldPassword
                secureTextFieldPassword.nextKeyView = secureTextFieldConfirmPassword
            }else{
                textFieldEmail.nextKeyView = textFieldPassword
                textFieldPassword.nextKeyView = secureTextFieldConfirmPassword
            }
            secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
        }
    }
    @IBAction func btnShowPasswordClicked(_ sender: Any) {
        if textFieldPassword.isHidden{
            textFieldPassword.stringValue = secureTextFieldPassword.stringValue
            textFieldPassword.isHidden = false
            secureTextFieldPassword.isHidden = true
            btnShowPassword.image = #imageLiteral(resourceName: "eye Icon")
            textFieldPassword.setFocus()
            
            textFieldEmail.nextKeyView = textFieldPassword
            if textFieldConfirmPasword.isHidden{
                textFieldPassword.nextKeyView = textFieldEmail
//                secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
            }else{
                textFieldPassword.nextKeyView = textFieldEmail
//                textFieldConfirmPasword.nextKeyView = textFieldEmail
            }
            
        }else{
            secureTextFieldPassword.stringValue = textFieldPassword.stringValue
            textFieldPassword.isHidden = true
            secureTextFieldPassword.isHidden = false
            btnShowPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
            secureTextFieldPassword.setFocus()
           
            textFieldEmail.nextKeyView = secureTextFieldPassword
            if textFieldConfirmPasword.isHidden{
                secureTextFieldPassword.nextKeyView = textFieldEmail
//                secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
            }else{
                secureTextFieldPassword.nextKeyView = textFieldEmail
//                textFieldConfirmPasword.nextKeyView = textFieldEmail
            }
        }
    }
    @IBAction func btnForgotPasswordClicked(_ sender: Any) {
        addLog(text: "[user-action] btnForgotPasswordClicked")
        allApiObject.capturePosthog(event: "button-forgot-password-clicked", metadata: [:])
        if textFieldEmail.stringValue.isEmpty{
            alertforvalidation(question: titleEmailIsBlank, text: emailInvalidText)
            return
        }
        loader.startAnimation(self)
        btnSignIn.isEnabled = false
        btnCreateAccount.isEnabled = false
        textFieldEmail.isEnabled = false
        secureTextFieldPassword.isEnabled = false
        textFieldPassword.isEnabled = false
        self.btnBack.isEnabled = false
        self.btnForgotPassword.isEnabled = false
        allApiObject.getForgotPassword(emailAddress: textFieldEmail.stringValue, completionHandler: {result in
            if result != nil{
                DispatchQueue.main.async {
                    addLog(text: "Forgot Password success")
                    self.loader.stopAnimation(self)
                    self.btnSignIn.isEnabled = true
                    self.btnCreateAccount.isEnabled = true
                    self.textFieldEmail.isEnabled = true
                    self.secureTextFieldPassword.isEnabled = true
                    self.textFieldPassword.isEnabled = true
                    self.btnBack.isEnabled = true
                    self.btnForgotPassword.isEnabled = true
                    
                    self.alertforvalidation(question: result!, text: "")
                }
                
                return
            }
        })
        
    }
    
    @IBAction func btnCreateAccountClicked(_ sender: Any) {
        addLog(text: "[user-action] CreateAccountClicked")
        var password = secureTextFieldPassword.stringValue
//        var confirmPassword = secureTextFieldConfirmPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        
//        if secureTextFieldConfirmPassword.isHidden == false{
//            confirmPassword = secureTextFieldConfirmPassword.stringValue
//        }else{
//            confirmPassword = textFieldConfirmPasword.stringValue
//        }
        
        
        if isLogin{
            isLogin = false
            reloadView()
        }else{
            allApiObject.capturePosthog(event: "button-create-account-clicked", metadata: [:])
            if textFieldEmail.stringValue.isEmpty == true
            {
                alertforvalidation(question: titleEmailIsBlank, text: emailInvalidText)
                return
            }else if password.isEmpty == true
            {
                alertforvalidation(question: titlePasswordIsBlank, text: passwordInvalidText)//
                return
            }
            
//            else if confirmPassword.isEmpty == true
//            {
//                alertforvalidation(question: titleConfirmPasswordBlank, text: confirmPasswordInvalidText)
//                return
//            }
            
            let value = isValidEmail(email: textFieldEmail.stringValue)
            if value == false
            {
                alertforvalidation(question: titleInvalidEmail, text: emailInvalidText)
                return
            }
//            if password != confirmPassword{
//                alertforvalidation(question: titlePasswordNotMatch, text: confirmPasswordNotMatchText)
//                return
//            }
            
            if Reachability.isConnectedToNetwork() == false {
                startLoader()
                allApiObject.isInternetOn(completionHandler: {isInternetOn in
                    DispatchQueue.main.async {
                        self.stopLoader()
                        if !isInternetOn{
                            
                            if self.view.window != nil{
                                askLogInVcObj?.showAlertNoInternet(window: self.view.window!)
                            }
                        }else{
                            self.perfromCreateAccount()
                        }
                    }
                })

                return;
            }
            
            perfromCreateAccount()
            
            
        }
    }
    
    func perfromCreateAccount(){
        var password = secureTextFieldPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        
        
        loader.startAnimation(self)
        btnCreateAccount.isEnabled = false
        self.textFieldEmail.isEnabled = false
        self.secureTextFieldPassword.isEnabled = false
        self.textFieldPassword.isEnabled = false
        self.secureTextFieldConfirmPassword.isEnabled = false
        self.textFieldConfirmPasword.isEnabled = false
        self.btnBack.isEnabled = false
        let email = textFieldEmail.stringValue
        
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
                                self.btnCreateAccount.isEnabled = true
                                self.textFieldEmail.isEnabled = true
                                self.secureTextFieldPassword.isEnabled = true
                                self.textFieldPassword.isEnabled = true
                                self.secureTextFieldConfirmPassword.isEnabled = true
                                self.textFieldConfirmPasword.isEnabled = true
                                self.btnBack.isEnabled = true
                            }
                            switch result {
                            case .success(let credentials):
                                print("Obtained credentials: \(credentials)")
                                DispatchQueue.main.async {
                                    self.loginDone(credentials: credentials, isLogin: false)
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
                        self.btnCreateAccount.isEnabled = true
                        self.textFieldEmail.isEnabled = true
                        self.secureTextFieldPassword.isEnabled = true
                        self.textFieldPassword.isEnabled = true
                        self.secureTextFieldConfirmPassword.isEnabled = true
                        self.textFieldConfirmPasword.isEnabled = true
                        self.btnBack.isEnabled = true
                        
                        
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
    
    func isValidEmail(email:String?) -> Bool {
        
        guard email != nil else { return false }
        
        let regEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
        return pred.evaluate(with: email)
    }
    func isValidPassword(password:String) -> Bool {
        var isPasswordFirstRuleValid = false
        if password.count >= 8{
            imgViewRuleFirst.isHidden = false
            isPasswordFirstRuleValid = true
        }else{
            imgViewRuleFirst.isHidden = true
        }
        var passwordRuleAppliedCount = 0
        if isContainAnyCaptalLetter(password: password){
            passwordRuleAppliedCount += 1
            imgViewRuleFourth.isHidden = false
        }else{
            imgViewRuleFourth.isHidden = true
        }
        
        if isContainAnySmallLetter(password: password){
            passwordRuleAppliedCount += 1
            imgViewRuleThird.isHidden = false
        }else{
            imgViewRuleThird.isHidden = true
        }
        
        if isContainAnyNumber(password: password){
            passwordRuleAppliedCount += 1
            imgViewRuleFifth.isHidden = false
        }else{
            imgViewRuleFifth.isHidden = true
        }
        
        if isContainAnySpecialCharacter(password: password){
            passwordRuleAppliedCount += 1
            imgViewRuleSixth.isHidden = false
        }else{
            imgViewRuleSixth.isHidden = true
        }
        
        if passwordRuleAppliedCount >= 3{
            imgViewRuleSecond.isHidden = false
            if isPasswordFirstRuleValid{
                return true
            }else{
                return false
            }
        }else{
            imgViewRuleSecond.isHidden = true
            return false
        }
        
        // old work
//        let regEx = "(?=.{8,})((?=.*\\d)(?=.*[a-z])(?=.*[A-Z])|(?=.*\\d)(?=.*[a-zA-Z])(?=.*[\\W_])|(?=.*[a-z])(?=.*[A-Z])(?=.*[\\W_])).*"
//
//        let pred = NSPredicate(format:"SELF MATCHES %@", regEx)
//        return pred.evaluate(with: password)
    }
    
    
    func isContainAnyCaptalLetter(password:String)->Bool{
        let capitalLetterRegEx  = ".*[A-Z]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
        let capitalresult = texttest.evaluate(with: password)
        return capitalresult
    }
    func isContainAnySmallLetter(password:String)->Bool{
        let capitalLetterRegEx  = ".*[a-z]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", capitalLetterRegEx)
        let capitalresult = texttest.evaluate(with: password)
        return capitalresult
    }
    
    func isContainAnyNumber(password:String)->Bool{
        let numberRegEx  = ".*[0-9]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", numberRegEx)
        let numberresult = texttest.evaluate(with: password)
        return numberresult
    }
    
    func isContainAnySpecialCharacter(password:String)->Bool{
        let specialCharacterRegEx  = ".*[=.!&^%$#@()/]+.*"
        let texttest = NSPredicate(format:"SELF MATCHES %@", specialCharacterRegEx)
        let specialresult = texttest.evaluate(with: password)
        return specialresult
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
    func generateSecurePassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialCharacters = "!@#$%^&*()_-+={}[]\\|:;\"'<>,.?/~`"
        let passwordLength = 8 // change this to set the length of the password

        var password = ""

        // add one upper case letter
        password += String(uppercaseLetters.randomElement()!)

        // add one lower case letter
        password += String(letters.randomElement()!)

        // add one special character
        password += String(specialCharacters.randomElement()!)

        // add one number
        password += String(numbers.randomElement()!)

        // add remaining characters randomly
        for _ in 0..<(passwordLength - 4) {
            let allChars = letters + uppercaseLetters + numbers //+ specialCharacters
            password += String(allChars.randomElement()!)
        }

        // shuffle the password to make it more secure
        password = String(password.shuffled())

        return password
    }
    
    @IBAction func segmentControlPasswordClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-use-own-password-clicked", metadata: [:])
        secureTextFieldPassword.isEditable = true
        secureTextFieldPassword.isSelectable = true
        stackViewPasswordRules.isHidden = false
        lblTitlePasswordRules.isHidden = false
        textFieldPassword.stringValue = ""
        secureTextFieldPassword.stringValue = ""
        if isValidPassword(password: ""){
            imgViewValidPassword.isHidden = false
        }else{
            imgViewValidPassword.isHidden = true
        }
        btnCopyPassword.isHidden = true
        btnRefreshPassword.isHidden = true
        btnCreateAccount.isEnabled = false
    }
    
    @IBAction func btnCopyPasswordClicked(_ sender: Any) {
        var password = secureTextFieldPassword.stringValue
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password, forType: .string)
        

        
        var msg = "Copied"
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            msg = upgradeNowVcInfo.value(forKey: "toolTipCopied") as? String ?? msg
        }
        showTooltip(sender: btnCopyPassword, msg: msg, preferredEdge: NSRectEdge.minY, maxWidthVal:230)
        DispatchQueue.global().async {
            sleep(2)
            DispatchQueue.main.async {
                popoverTooltip?.close()
            }
        }
        
    }
    @IBAction func btnRefreshPasswordClicked(_ sender: Any) {
        let passWord = generateSecurePassword()
        if secureTextFieldPassword.isHidden == false{
            secureTextFieldPassword.stringValue = passWord
        }else{
            textFieldPassword.stringValue = passWord
        }
        
        if isValidPassword(password: passWord){
            btnCreateAccount.isEnabled = true
        }else{
            btnCreateAccount.isEnabled = false
        }
        imgViewValidPassword.isHidden = true
        btnRefreshPassword.isHidden = true
    }
//    @IBAction func checkBoxPasswordSaveClicked(_ sender: Any) {
//        if checkBoxPasswordSave.state == .on{
//            allApiObject.capturePosthog(event: "saved-password-safe-checked", metadata: [:])
//            var passWord = secureTextFieldPassword.stringValue
//            if secureTextFieldPassword.isHidden == false{
//                passWord = secureTextFieldPassword.stringValue
//            }else{
//                passWord = textFieldPassword.stringValue
//            }
//            
//            if isValidPassword(password: passWord){
//                btnCreateAccount.isEnabled = true
//            }else{
//                btnCreateAccount.isEnabled = false
//            }
//        }else{
//            btnCreateAccount.isEnabled = false
//        }
//        
//    }
    
    @IBAction func btnSignUpClicked(_ sender: Any) {
        btnCreateAccountClicked(self)
    }
    
    @IBAction func btnSignInBottomClicked(_ sender: Any) {
        isLogin = true
        reloadView()
    }
    
}



extension customLoginVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if isLogin{
            return;
        }
        
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldPassword || textfield == secureTextFieldPassword{
                if isValidPassword(password: textfield.stringValue){
                    imgViewValidPassword.isHidden = false
                }else{
                    imgViewValidPassword.isHidden = true
                }
            }
            if imgViewValidPassword.isHidden == false{//} && imgViewValidConfirmPassword.isHidden == false{
                btnCreateAccount.isEnabled = true
            }else{
                btnCreateAccount.isEnabled = false
            }
        }
    }
}
