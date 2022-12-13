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
//    @IBOutlet weak var lblPasswordRules: NSTextField!
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
        
        
        lblRuleFirst.stringValue = "At least 8 characters in length"
        lblRuleSecond.stringValue = "Contain at least 3 of the following 4 types of characters:"
        lblRuleThird.stringValue = "lower case letters (a-z)"
        lblRuleFourth.stringValue = "upper case letters (A-Z)"
        lblRuleFifth.stringValue = "numbers (i.e. 0-9)"
        lblRuleSixth.stringValue = "special characters (e.g. !@#$%^&*)"
        
        lblTitlePasswordRules.stringValue = "Password rules:"
//        lblPasswordRules.stringValue = "* At least 8 characters in length\n* Contain at least 3 of the following 4 types of characters:\n* lower case letters (a-z)\n* upper case letters (A-Z)\n* numbers (i.e. 0-9)\n* special characters (e.g. !@#$%^&*)"
        
        
        
        lblTitle.stringValue = "Sign In"
        lblSubtitle.stringValue = "Create an account"//"Welcome back"
        
        
        lblEmailAddress.stringValue = "Email Address"
        lblPassword.stringValue = "Password"
        lblConfirmPassword.stringValue = "Confirm your password"
        
        btnSignIn.title = "Sign In"
        btnCreateAccount.title = "Create an account"
        
        btnForgotPassword.title = "Forgot Password"
        
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
        }
        
        textFieldPassword.delegate = self
        textFieldConfirmPasword.delegate = self
        secureTextFieldPassword.delegate = self
        secureTextFieldConfirmPassword.delegate = self
        
    }
    
    override func viewWillAppear() {
        reloadView()
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
        secureTextFieldConfirmPassword.isHidden = false
        btnShowPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
        btnShowConfirmPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
        
        imgViewRuleFirst.isHidden = true
        imgViewRuleSecond.isHidden = true
        imgViewRuleThird.isHidden = true
        imgViewRuleFourth.isHidden = true
        imgViewRuleFifth.isHidden = true
        imgViewRuleSixth.isHidden = true
        
        if isLogin{
            addLog(text: "login view ")
            btnCreateAccount.isEnabled = true
            btnForgotPassword.isHidden = false
            topSpaceLblTitle.constant = 130
            lblTitle.stringValue = "Sign In"
            lblSubtitle.stringValue = "Welcome back"
            boxConfirmPassword.isHidden = true
            btnSignIn.isHidden = false
            btnCreateAccount.buttonColor = NSColor.white.cgColor
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                lblTitle.stringValue = customLoginVcInfo.value(forKey: "titleSignIn") as? String ?? lblTitle.stringValue
                lblSubtitle.stringValue = customLoginVcInfo.value(forKey: "subTitleWelcomeback") as? String ?? lblSubtitle.stringValue
            }
            lblTitlePasswordRules.isHidden = true
//            lblPasswordRules.isHidden = true
            stackViewPasswordRules.isHidden = true
            textFieldEmail.nextKeyView = secureTextFieldPassword
            secureTextFieldPassword.nextKeyView = textFieldEmail
            
        }else{
            addLog(text: "signup view ")
            btnCreateAccount.isEnabled = false
            btnForgotPassword.isHidden = true
            topSpaceLblTitle.constant = 80
            lblTitle.stringValue = "Sign Up"
            lblSubtitle.stringValue = "Create an account"
            boxConfirmPassword.isHidden = false
            btnSignIn.isHidden = true
            btnCreateAccount.buttonColor = buttonBgColor.cgColor
            if let customLoginVcInfo = configjson.value(forKey: "customLoginVcInfo") as? NSDictionary{
                lblTitle.stringValue = customLoginVcInfo.value(forKey: "titleSignUp") as? String ?? lblTitle.stringValue
                lblSubtitle.stringValue = customLoginVcInfo.value(forKey: "subTitleCreateAccount") as? String ?? lblSubtitle.stringValue
            }
            lblTitlePasswordRules.isHidden = false
//            lblPasswordRules.isHidden = false
            stackViewPasswordRules.isHidden = false
            textFieldEmail.nextKeyView = secureTextFieldPassword
            secureTextFieldPassword.nextKeyView = secureTextFieldConfirmPassword
            secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        addLog(text: "btnBackClicked")
        showAskLoginWindow()
    }
    
    @IBAction func btnSignInClicked(_ sender: Any) {
        addLog(text: "btnSignInClicked")
        var password = secureTextFieldPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        
        if Reachability.isConnectedToNetwork() == false {
            if self.view.window != nil{
                askLogInVcObj?.showAlertNoInternet(window: self.view.window!)
            }
            return
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
        appdelegate!.statusbutton?.action = nil
        appdelegate!.user = User(from: credentials.accessToken)
        allApiObject.capturePosthog(event: "login-homemade", metadata: [:])
        let _ = appdelegate!.credentialsManager.store(credentials: credentials)
        if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) == nil{
            showOnboardingCardWindow(isLogin: isLogin)
        }else{
            appdelegate!.loadCredentialsAndDeviceId()
        }
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
                textFieldPassword.nextKeyView = secureTextFieldConfirmPassword
                secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
            }else{
                textFieldPassword.nextKeyView = textFieldConfirmPasword
                textFieldConfirmPasword.nextKeyView = textFieldEmail
            }
            
        }else{
            secureTextFieldPassword.stringValue = textFieldPassword.stringValue
            textFieldPassword.isHidden = true
            secureTextFieldPassword.isHidden = false
            btnShowPassword.image = #imageLiteral(resourceName: "eyeGray Icon")
            secureTextFieldPassword.setFocus()
           
            textFieldEmail.nextKeyView = secureTextFieldPassword
            if textFieldConfirmPasword.isHidden{
                secureTextFieldPassword.nextKeyView = secureTextFieldConfirmPassword
                secureTextFieldConfirmPassword.nextKeyView = textFieldEmail
            }else{
                secureTextFieldPassword.nextKeyView = textFieldConfirmPasword
                textFieldConfirmPasword.nextKeyView = textFieldEmail
            }
        }
    }
    @IBAction func btnForgotPasswordClicked(_ sender: Any) {
     
        addLog(text: "btnForgotPasswordClicked")
        
        
        

        if textFieldEmail.stringValue.isEmpty == true
        {
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
        addLog(text: "CreateAccountClicked")
        var password = secureTextFieldPassword.stringValue
        var confirmPassword = secureTextFieldConfirmPassword.stringValue
        
        if secureTextFieldPassword.isHidden == false{
            password = secureTextFieldPassword.stringValue
        }else{
            password = textFieldPassword.stringValue
        }
        
        if secureTextFieldConfirmPassword.isHidden == false{
            confirmPassword = secureTextFieldConfirmPassword.stringValue
        }else{
            confirmPassword = textFieldConfirmPasword.stringValue
        }
        if Reachability.isConnectedToNetwork() == false {
            if self.view.window != nil{
                askLogInVcObj?.showAlertNoInternet(window: self.view.window!)
            }
            return
        }
        
        if isLogin{
            isLogin = false
            reloadView()
        }else{
            if textFieldEmail.stringValue.isEmpty == true
            {
                alertforvalidation(question: titleEmailIsBlank, text: emailInvalidText)
                return
            }else if password.isEmpty == true
            {
                alertforvalidation(question: titlePasswordIsBlank, text: passwordInvalidText)//
                return
            }else if confirmPassword.isEmpty == true
            {
                alertforvalidation(question: titleConfirmPasswordBlank, text: confirmPasswordInvalidText)
                return
            }
            
            let value = isValidEmail(email: textFieldEmail.stringValue)
            if value == false
            {
                alertforvalidation(question: titleInvalidEmail, text: emailInvalidText)
                return
            }
            if password != confirmPassword{
                alertforvalidation(question: titlePasswordNotMatch, text: confirmPasswordNotMatchText)
                return
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
        let specialCharacterRegEx  = ".*[!&^%$#@()/]+.*"
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
                    
                    var confirmPassword = secureTextFieldConfirmPassword.stringValue
                    if secureTextFieldConfirmPassword.isHidden == false{
                        confirmPassword = secureTextFieldConfirmPassword.stringValue
                    }else{
                        confirmPassword = textFieldConfirmPasword.stringValue
                    }
                    
                    if confirmPassword == textfield.stringValue{
                        imgViewValidConfirmPassword.isHidden = false
                    }else{
                        imgViewValidConfirmPassword.isHidden = true
                    }
                }else{
                    imgViewValidConfirmPassword.isHidden = true
                    imgViewValidPassword.isHidden = true
                }
            }else if textfield == textFieldConfirmPasword || textfield == secureTextFieldConfirmPassword{
                
                var password = secureTextFieldPassword.stringValue
                
                if secureTextFieldPassword.isHidden == false{
                    password = secureTextFieldPassword.stringValue
                }else{
                    password = textFieldPassword.stringValue
                }
                if !password.isEmpty{
                    if imgViewValidPassword.isHidden == false{
                        if password == textfield.stringValue{
                            imgViewValidConfirmPassword.isHidden = false
                        }else{
                            imgViewValidConfirmPassword.isHidden = true
                        }
                    }else{
                        imgViewValidConfirmPassword.isHidden = true
                    }
                }else{
                    imgViewValidConfirmPassword.isHidden = true
                }
            }
            
            if imgViewValidPassword.isHidden == false && imgViewValidConfirmPassword.isHidden == false{
                btnCreateAccount.isEnabled = true
            }else{
                btnCreateAccount.isEnabled = false
            }
        }
    }
}
