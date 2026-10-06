//
//  accountVc.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 03/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import Auth0
import SwiftUI

class accountVc: NSViewController {

    @IBOutlet weak var btnCancelEditing: cursorButton!
    @IBOutlet weak var btnUpdate: Button!
    @IBOutlet weak var btnEditUserName: cursorButton!
    @IBOutlet weak var textFieldEditUserName: NSTextField!
    @IBOutlet weak var topSpaceUserId: NSLayoutConstraint!
    @IBOutlet weak var btnResendConfirmation: underLineButton!
    @IBOutlet weak var lblEmailNotVerified: NSTextField!
    @IBOutlet weak var boxEmailNotVerified: NSBox!
    @IBOutlet weak var lblStatus: NSTextField!
    
    @IBOutlet weak var lblSubscriptionDetails: NSTextField!
    @IBOutlet weak var loaderResetPassword: NSProgressIndicator!
    @IBOutlet weak var btnResetPassword: Button!
    @IBOutlet weak var lblTitleMain: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnRestorePurchase: Button!
    @IBOutlet weak var lblRestore: NSTextField!
    @IBOutlet weak var lblUserId: NSTextField!
    @IBOutlet weak var lblTitleUserId: NSTextField!
    @IBOutlet weak var btnLogout: NSButton!
    @IBOutlet weak var lblEmaiId: NSTextField!
    @IBOutlet weak var lblTitleEmailId: NSTextField!
    @IBOutlet weak var lblName: NSTextField!
    @IBOutlet weak var lblTitleName: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblVersionState: NSTextField!
    
    var restoreText = "If you've already purchased Focus Bear subscription, you can restore that purchase."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblEmaiId.setAccessibilityIdentifier(UITestContract.Identifier.SettingsRegression.accountEmail)
        // Do view setup here.
        lblSubscriptionDetails.stringValue = "Subscription Details"
        lblStatus.stringValue = "Status:"
        lblEmailNotVerified.stringValue = "Email not Verified"
        btnResendConfirmation.title = "Resend Confirmation Email"
        
        
        btnRestorePurchase.title = "Sync Payment Status"
        
        lblTitleUserId.stringValue = "User Id:"
        lblTitle.stringValue = "Your Account Information"
        lblTitleName.stringValue = "Leaderboard Username:"
        lblTitleEmailId.stringValue = "Email Id:"
        btnLogout.title = "Logout"
        btnLogout.setAccessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.logoutButton)
        btnResetPassword.title = "Reset Password"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            lblTitle.stringValue = accountVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleName.stringValue = accountVcInfo.value(forKey: "titleLeaderboardUsernameText") as? String ?? accountVcInfo.value(forKey: "titleNameText") as? String ?? lblTitleName.stringValue
            lblTitleEmailId.stringValue = accountVcInfo.value(forKey: "titleEmailIdText") as? String ?? lblTitleEmailId.stringValue
            btnLogout.title = accountVcInfo.value(forKey: "buttonLogoutText") as? String ?? btnLogout.title
            lblTitleUserId.stringValue = accountVcInfo.value(forKey: "titleUserIdText") as? String ?? lblTitleUserId.stringValue
            restoreText = accountVcInfo.value(forKey: "restoreText") as? String ?? restoreText
            btnRestorePurchase.title = accountVcInfo.value(forKey: "buttonRestoreText") as? String ?? btnRestorePurchase.title
            btnResetPassword.title = accountVcInfo.value(forKey: "buttonResetPasswordText") as? String ?? btnResetPassword.title
            lblSubscriptionDetails.stringValue = accountVcInfo.value(forKey: "subscriptionDetails") as? String ?? lblSubscriptionDetails.stringValue
            lblStatus.stringValue = accountVcInfo.value(forKey: "status") as? String ?? lblStatus.stringValue
            lblEmailNotVerified.stringValue = accountVcInfo.value(forKey: "emailNotVerified") as? String ?? lblEmailNotVerified.stringValue
            btnResendConfirmation.title = accountVcInfo.value(forKey: "buttonResendConfirmation") as? String ?? btnResendConfirmation.title
        }
        
        arrForSearchFromSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": lblTitle.stringValue, "tabId": idAccount, "object": lblTitle as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnRestorePurchase.title, "tabId": idAccount, "object": btnRestorePurchase as Any])
        arrForSearchFromSimpleModeSettings.append(["title": btnLogout.title, "tabId": idAccount, "object": btnLogout as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleEmailId.stringValue, "tabId": idAccount, "object": lblTitleEmailId as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleName.stringValue, "tabId": idAccount, "object": lblTitleName as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleUserId.stringValue, "tabId": idAccount, "object": lblTitleUserId as Any])

        // Leaderboard-username editing (#1133): start in read-only display mode (label + edit icon);
        // the editable field + Update button appear only when the user taps the edit icon.
        btnUpdate.title = "Update"
        btnEditUserName.toolTip = "Edit"
        btnCancelEditing.toolTip = "Undo"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            btnUpdate.title = accountVcInfo.value(forKey: "buttonUpdateUsernameText") as? String ?? btnUpdate.title
            btnEditUserName.toolTip = accountVcInfo.value(forKey: "editUsernameTooltip") as? String ?? btnEditUserName.toolTip
            btnCancelEditing.toolTip = accountVcInfo.value(forKey: "cancelUsernameTooltip") as? String ?? btnCancelEditing.toolTip
        }
        // Icon-only buttons: the tooltip is the only text that says what they do.
        btnEditUserName.setAccessibilityLabel(btnEditUserName.toolTip)
        btnCancelEditing.setAccessibilityLabel(btnCancelEditing.toolTip)
        setUsernameEditMode(false)
    }
    
    override func viewWillAppear(){
        addLog(text: "accountVc:- viewWillAppear")
        // If the user left the screen mid-edit, discard that and return to the read-only display.
        btnUpdate.isEnabled = true
        setUsernameEditMode(false)
        reloadView()
    }

    func reloadView(){
        if let userId = appdelegate!.user?.userId{
            lblUserId.stringValue = userId
        }else{
            lblUserId.stringValue = ""
        }
        if currentLeaderboardUsername.isEmpty {
            // New key for the editable UX. The old `leaderboardUsernamePlaceholder` ("...in the web app")
            // is left untouched so older app versions still read it correctly from the served config.
            var leaderboardUsernameNotSet = "Not set — click Edit to set your leaderboard username"
            if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                leaderboardUsernameNotSet = accountVcInfo.value(forKey: "leaderboardUsernameNotSetText") as? String ?? leaderboardUsernameNotSet
            }
            lblName.stringValue = leaderboardUsernameNotSet
        } else {
            lblName.stringValue = currentLeaderboardUsername
        }
        lblEmaiId.stringValue = currentUserEmail
        
        var daysRemainingText = "Trial version - <DAYS> of 21 trial days remaining"
        var trialExpiredText = "Your subscription has expired"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let text = common.value(forKey: "daysRemainingText") as? String{
                daysRemainingText = text
            }

        }
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            trialExpiredText = menuInfo.value(forKey: "subscriptionExpiredText") as? String ?? trialExpiredText
        }
        if isPurchased == false{
            let daysremaining = daysLeft

            
            if daysremaining <= 0{
                lblVersionState.stringValue = trialExpiredText
            }else{
                lblVersionState.stringValue = daysRemainingText.replacingOccurrences(of: "<DAYS>", with: "\(daysremaining)")//"Trial version - \(daysremaining) of 7 trial days remaining"//
            }
        }else{
            lblVersionState.stringValue = "Registered Version"
            if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                lblVersionState.stringValue = accountVcInfo.value(forKey: "registeredVersionText") as? String ?? lblVersionState.stringValue
            }
        }
        
        if !isPurchased{
            lblRestore.stringValue = restoreText
            lblRestore.isHidden = false
        }else{
            lblRestore.stringValue = ""
            lblRestore.isHidden = true
        }
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitleMain.stringValue = ""
            }else{
                lblTitleMain.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitleMain.stringValue = ""
        }
        
        if !isEmailVerified{//
            boxEmailNotVerified.isHidden = false
            topSpaceUserId.constant = 78
        }else{
            boxEmailNotVerified.isHidden = true
            topSpaceUserId.constant = 20
        }

        configureGuestConversionCard()
    }
    /// Toggle between the read-only username label (+ edit icon) and the editable field (+ Update button).
    private func setUsernameEditMode(_ editing: Bool){
        lblName.isHidden = editing
        btnEditUserName.isHidden = editing
        textFieldEditUserName.isHidden = !editing
        btnUpdate.isHidden = !editing
        btnCancelEditing.isHidden = !editing
    }

    @IBAction func btnCancelEditingClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- cancel editing leaderboard username")
        // Discard any typed changes and return to the read-only display, without calling the API.
        btnUpdate.isEnabled = true   // in case a prior in-flight update had disabled it
        setUsernameEditMode(false)
    }

    @IBAction func btnEditUserNameClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- edit leaderboard username clicked")
        // Prefill with the current username (empty when not set), switch to edit mode, and focus the field.
        textFieldEditUserName.stringValue = currentLeaderboardUsername
        setUsernameEditMode(true)
        self.view.window?.makeFirstResponder(textFieldEditUserName)
    }

    @IBAction func btnUpdateClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- update leaderboard username clicked")
        let newUsername = textFieldEditUserName.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        // The backend needs a non-empty value and caps username at 30 chars.
        if newUsername.isEmpty || newUsername.count > 30 {
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = newUsername.isEmpty
                ? "Please enter a leaderboard username."
                : "Leaderboard username must be 30 characters or fewer."
            if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary {
                let key = newUsername.isEmpty ? "usernameEmptyText" : "usernameTooLongText"
                alert.messageText = accountVcInfo.value(forKey: key) as? String ?? alert.messageText
            }
            alert.runModal()
            return
        }
        // Disable Update while the request is in flight to avoid double-submits; the completion is on main.
        btnUpdate.isEnabled = false
        allApiObject.updateLeaderboardUsername(username: newUsername) { [weak self] _, statusCode in
            guard let self = self else { return }
            self.btnUpdate.isEnabled = true
            if statusCode == 200 {
                currentLeaderboardUsername = newUsername
                self.setUsernameEditMode(false)   // back to label + edit icon
                self.reloadView()
                allApiObject.capturePosthog(event: "leaderboard-username-updated", metadata: [:])
            } else {
                // Keep edit mode so the user can correct and retry (e.g. a taken username).
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "Couldn't update your leaderboard username."
                alert.informativeText = "That username may already be taken. Please try a different one."
                if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary {
                    alert.messageText = accountVcInfo.value(forKey: "usernameUpdateFailedTitle") as? String ?? alert.messageText
                    alert.informativeText = accountVcInfo.value(forKey: "usernameUpdateFailedText") as? String ?? alert.informativeText
                }
                alert.runModal()
            }
        }
    }
    // MARK: - Guest account conversion (#1850)

    private var guestConversionHostingView: NSHostingView<AnonymousAccountConversionView>?
    private weak var guestConversionFormController: NSViewController?
    private let guestCardTopInset: CGFloat = 16
    private let guestCardSideInset: CGFloat = 22
    /// Approx. card height; used only to reserve space below it. Verified visually.
    private let guestCardReservedHeight: CGFloat = 96

    /// For guest/anonymous users, shows a SwiftUI "create an account" card at the top
    /// of the Account tab and reserves space so existing content sits below it.
    /// No-op (and hidden) for registered users.
    private func configureGuestConversionCard() {
        let isGuest = isCurrentUserGuestAccount()
        if isGuest, guestConversionHostingView == nil {
            let card = AnonymousAccountConversionView(onCreateAccount: { [weak self] in
                self?.presentGuestConversionForm()
            })
            let hosting = NSHostingView(rootView: card)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.topAnchor.constraint(equalTo: view.topAnchor, constant: self.view.frame.height - boxEmailNotVerified.frame.minY - 20),
                hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: guestCardSideInset),
                hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -guestCardSideInset),
            ])
            guestConversionHostingView = hosting
        }

        guestConversionHostingView?.isHidden = !isGuest

        // viewWillAppear re-sets topSpaceUserId to its base (20/78) each call, so this
        // is not cumulative. Reserve enough room for the card above the account info.
        if isGuest {
            //topSpaceUserId.constant = max(topSpaceUserId.constant,
                                          //guestCardTopInset + guestCardReservedHeight)
            topSpaceUserId.constant = guestCardTopInset + guestCardReservedHeight + 20
            boxEmailNotVerified.isHidden = true
        }
    }

    /// Presents the email/password form sheet that calls the backend convert-guest
    /// endpoint (mirrors the mobile guest-conversion flow; data is preserved server-side).
    private func presentGuestConversionForm() {
        addLog(text: "[user-action] accountVc:- guest create-account tapped")
        let form = AnonymousAccountConversionFormView(
            submit: { email, password, completion in
                allApiObject.convertGuestAccount(email: email, newPassword: password, completionHandler: completion)
            },
            onSuccess: { [weak self] in
                self?.handleGuestConversionSuccess()
            },
            onCancel: { [weak self] in
                if let controller = self?.guestConversionFormController { self?.dismiss(controller) }
            }
        )
        let controller = NSHostingController(rootView: form)
        guestConversionFormController = controller
        presentAsSheet(controller)
    }

    private func handleGuestConversionSuccess() {
        if let controller = guestConversionFormController { dismiss(controller) }
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Almost there!"
        alert.informativeText = "We've sent a verification email. Please confirm your email address to finish creating your account."
        alert.alertStyle = .informational
        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
        getUserDetailsAgain()
    }

    func getUserDetailsAgain(){
        allApiObject.getuserDetailsInfo(completionHandler: {dic in
            if dic != nil{
                isEmailVerified = dic?.value(forKey: "email_verified") as? Bool ?? false
                
                addLog(text:"isEmailVerified :- \(isEmailVerified)")
                currentUserEmail = dic?.value(forKey: "email") as? String ?? ""
                currentUserName = dic?.value(forKey: "username") as? String ?? ""
                if let sharedDefaults = appdelegate?.sharedDefaults {
                    InternalTestUser.record(email: currentUserEmail, in: sharedDefaults)
                }
                
                if isCurrentUserGuestAccount(){
                    addLog(text: "No need to verify email. Reason: Guest account.")
                    isEmailVerified = true
                }
                DispatchQueue.main.async {
                    self.reloadView()
                }
            }
        })
    }
    
    @IBAction func btnLogoutClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnLogoutClicked")
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to logout?"
        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
            alert.messageText = accountVcInfo.value(forKey: "logoutAlertText") as? String ?? alert.messageText
        }
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                print("okclicked")
                allApiObject.capturePosthog(event: "logout", metadata: [:])
                appdelegate?.logout(isAutomatic: false)
            }
        })
       
    }
    
    @IBAction func btnRestorePurchaseClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- btnRestorePurchaseClicked")
        loader.startAnimation(self)
        btnRestorePurchase.isEnabled = false
        allApiObject.capturePosthog(event: "sync-payment-status", metadata: ["from":"accounts_tab"])
        appdelegate?.renewToken(window: self.view.window!, completionHandler: {
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.btnRestorePurchase.isEnabled = true
                self.reloadView()
            }
            
        })
    }

    
    @IBAction func btnResetPasswordClicked(_ sender: Any) {
        addLog(text: "[user-action] accountVc:- Reset Password Clicked")
        loaderResetPassword.startAnimation(self)
        if !isEmailVerified{
            btnResetPassword.isEnabled = false
            allApiObject.getuserDetailsInfo(completionHandler: {dic in
                DispatchQueue.main.async {
                    self.loaderResetPassword.stopAnimation(self)
                    self.btnResetPassword.isEnabled = true
                    if dic != nil{
                        isEmailVerified = dic?.value(forKey: "email_verified") as? Bool ?? false
                        if isCurrentUserGuestAccount(){
                            addLog(text: "No need to verify email. Reason: Guest account.")
                            isEmailVerified = true
                        }
                        if !isEmailVerified{
                            if unverifiedEmailWcObj != nil{
                                if unverifiedEmailWcObj?.window?.isVisible ?? false{
                                    unverifiedEmailWcObj?.window?.close()
                                }
                            }
                            self.presentAsSheet(getUnverifiedEmailVcObject())
                            getUnverifiedEmailVcObject().isAWindow = false
                        }else{
                            self.resetPassword()
                        }
                    }
                }
            })
        }else{
            resetPassword()
        }
    }

    
    func resetPassword(){
        addLog(text: "func resetPassword called")
        loaderResetPassword.startAnimation(self)
        btnResetPassword.isEnabled = false
        DispatchQueue.global().async{
            sleep(20) // makes it
            DispatchQueue.main.async{
                self.btnResetPassword.isEnabled = true
            }
        }
//        Auth0.authentication().resetPassword(email: currentUserEmail, connection: "Username-Password-Authentication").start{ result in
//            DispatchQueue.main.async {
//                self.loaderResetPassword.stopAnimation(self)
//                switch result {
//                case .success():
//                    if let window = self.view.window {
//                        let alert = NSAlert()
//                        alert.messageText = "Reset Link Sent" text
//                        alert.informativeText = "We've sent a password reset link to your email. Please check your inbox."
//                        alert.alertStyle = .informational
//                        alert.beginSheetModal(for: window, completionHandler: nil)
//                    }
//                case .failure(_):
//                    if let window = self.view.window {
//                        let alert = NSAlert()
//                        alert.messageText = "Unable to Send Reset Email"
//                        alert.informativeText = "Something went wrong while sending the reset link. Please check your internet connection and try again."
//                        alert.alertStyle = .warning
//                        alert.beginSheetModal(for: window, completionHandler: nil)
//                    }
//                }
//            }
//        }
        
        
        
        allApiObject.resetPassword(completionHandler: {(bool, message) in
            DispatchQueue.main.async {
                self.loaderResetPassword.stopAnimation(self)
                switch bool {
                case true:
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Reset Link Sent"
                        alert.informativeText = "We've sent a password reset link to your email. Please check your inbox."
                        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                            alert.messageText = accountVcInfo.value(forKey: "linkSentTitle") as? String ?? alert.messageText
                            alert.informativeText = accountVcInfo.value(forKey: "linkSentDescription") as? String ?? alert.informativeText
                        }
                        
                        alert.alertStyle = .informational
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    }
                case false:
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Unable to Send Reset Email"
                        alert.informativeText = message ?? "Something went wrong while sending the reset link. Please check your internet connection and try again."
                        if let accountVcInfo = configjson.value(forKey: "accountVcInfo") as? NSDictionary{
                            alert.messageText = accountVcInfo.value(forKey: "linkSendFailedTitle") as? String ?? alert.messageText
                            alert.informativeText = accountVcInfo.value(forKey: "linkSendFailedDescription") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .warning
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    }
                }
            }
            
        })
    }
    @IBAction func btnResendConfirmationClicked(_ sender: Any) {
        addLog(text: "[user-action] unverifiedEmailVc:- button Resend Clicked")
        self.loaderResetPassword.startAnimation(self)
        allApiObject.emailConfirmation(completionHandler: { val in
            DispatchQueue.main.async{
                self.loaderResetPassword.stopAnimation(self)
                if val{
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Verification Email Sent"
                        alert.informativeText = "We've sent a verification link to your email. Please check your inbox to verify your account."
                        if let unverifiedEmailVcInfo = configjson.value(forKey: "unverifiedEmailVcInfo") as? NSDictionary{
                            alert.messageText = unverifiedEmailVcInfo.value(forKey: "titleEmailSent") as? String ?? alert.messageText
                            alert.informativeText = unverifiedEmailVcInfo.value(forKey: "descriptionEmailSent") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .informational
                        alert.beginSheetModal(for: window, completionHandler: {_ in
                            
                        })
                    }
                }else{
                    if let window = self.view.window {
                        let alert = NSAlert()
                        alert.messageText = "Failed to Send Verification Email"
                        alert.informativeText = "Something went wrong while sending the verification email. Please try again later."
                        if let unverifiedEmailVcInfo = configjson.value(forKey: "unverifiedEmailVcInfo") as? NSDictionary{
                            alert.messageText = unverifiedEmailVcInfo.value(forKey: "titleEmailFailed") as? String ?? alert.messageText
                            alert.informativeText = unverifiedEmailVcInfo.value(forKey: "descriptionEmailFailed") as? String ?? alert.informativeText
                        }
                        alert.alertStyle = .warning
                        alert.beginSheetModal(for: window, completionHandler: {_ in
                            
                        })
                    }
                }
                
            }
        })
    }
}
