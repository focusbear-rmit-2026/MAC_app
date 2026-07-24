//
//  teacherUnlockRequestVc.swift
//  Focus Bear
//
//  Created by Focus Bear on 02/07/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Teacher Mode unlock request:- modelled on AccountabilityBuddy/createUnlockRequestVc but built
//  programmatically (no storyboard scene) and targeting POST /class-session/:id/unlock-requests.
//  Approval arrives back as class-allowlist-changed, denial as class-unlock-resolved.
//

import Cocoa

class teacherUnlockRequestVc: NSViewController {

    var sessionId = ""

    var lblTitle: NSTextField!
    var lblAppOrUrl: NSTextField!
    var textFieldAppOrUrl: NSTextField!
    var lblReason: NSTextField!
    var textFieldReason: NSTextField!
    var btnCreateRequest: NSButton!
    var btnCancel: NSButton!
    var loader: NSProgressIndicator!

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 250))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        var titleString = "Ask your teacher to unlock an app or website"
        var appOrUrlString = "App name or website"
        var reasonString = "Reason (optional)"
        var placeHolderAppOrUrlString = "e.g. Desmos or desmos.com"
        var placeHolderReasonString = "Explain why you need this unlock...."
        var buttonCreateRequestString = "Send Request"

        if let teacherSessionInfo = configjson.value(forKey: "teacherSessionInfo") as? NSDictionary{
            titleString = teacherSessionInfo.value(forKey: "titleCreateUnlockRequest") as? String ?? titleString
            appOrUrlString = teacherSessionInfo.value(forKey: "appOrUrlTitle") as? String ?? appOrUrlString
            reasonString = teacherSessionInfo.value(forKey: "reasonTitle") as? String ?? reasonString
            placeHolderAppOrUrlString = teacherSessionInfo.value(forKey: "placeHolderAppOrUrl") as? String ?? placeHolderAppOrUrlString
            placeHolderReasonString = teacherSessionInfo.value(forKey: "placeHolderReason") as? String ?? placeHolderReasonString
            buttonCreateRequestString = teacherSessionInfo.value(forKey: "buttonCreateRequest") as? String ?? buttonCreateRequestString
        }

        lblTitle = NSTextField(labelWithString: titleString)
        lblTitle.font = NSFont.boldSystemFont(ofSize: 15)
        lblTitle.frame = NSRect(x: 20, y: 205, width: 420, height: 25)
        self.view.addSubview(lblTitle)

        lblAppOrUrl = NSTextField(labelWithString: appOrUrlString)
        lblAppOrUrl.frame = NSRect(x: 20, y: 172, width: 420, height: 20)
        self.view.addSubview(lblAppOrUrl)

        textFieldAppOrUrl = NSTextField(frame: NSRect(x: 20, y: 142, width: 420, height: 26))
        textFieldAppOrUrl.placeholderString = placeHolderAppOrUrlString
        self.view.addSubview(textFieldAppOrUrl)

        lblReason = NSTextField(labelWithString: reasonString)
        lblReason.frame = NSRect(x: 20, y: 110, width: 420, height: 20)
        self.view.addSubview(lblReason)

        textFieldReason = NSTextField(frame: NSRect(x: 20, y: 80, width: 420, height: 26))
        textFieldReason.placeholderString = placeHolderReasonString
        self.view.addSubview(textFieldReason)

        btnCreateRequest = NSButton(title: buttonCreateRequestString, target: self, action: #selector(btnCreateRequestClicked(_:)))
        btnCreateRequest.bezelStyle = .rounded
        btnCreateRequest.keyEquivalent = "\r"
        btnCreateRequest.frame = NSRect(x: 320, y: 20, width: 120, height: 32)
        self.view.addSubview(btnCreateRequest)

        btnCancel = NSButton(title: buttonCancelText, target: self, action: #selector(btnCancelClicked(_:)))
        btnCancel.bezelStyle = .rounded
        btnCancel.frame = NSRect(x: 200, y: 20, width: 110, height: 32)
        self.view.addSubview(btnCancel)

        loader = NSProgressIndicator(frame: NSRect(x: 170, y: 26, width: 20, height: 20))
        loader.style = .spinning
        loader.isHidden = true
        self.view.addSubview(loader)
    }

    override func viewWillAppear() {
        textFieldAppOrUrl.stringValue = ""
        textFieldReason.stringValue = ""
        btnCreateRequest.isEnabled = true
    }

    @objc func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }

    @objc func btnCreateRequestClicked(_ sender: Any) {
        let appOrUrl = textFieldAppOrUrl.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if appOrUrl.isEmpty{
            return;
        }
        addLog(text: "[user-action] teacherUnlockRequestVc:- btnCreateRequestClicked")

        var requestedApp:String?
        var requestedDomain:String?
        if appOrUrl.contains(".") && !appOrUrl.contains(" "){// looks like a domain/url, otherwise treat as an app name
            requestedDomain = appOrUrl
        }else{
            requestedApp = appOrUrl
        }

        btnCreateRequest.isEnabled = false
        loader.isHidden = false
        loader.startAnimation(self)

        allApiObject.requestClassUnlock(sessionId: sessionId, requestedApp: requestedApp, requestedDomain: requestedDomain, reason: textFieldReason.stringValue, completionHandler: {result in
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.loader.isHidden = true
                self.btnCreateRequest.isEnabled = true
                if result{
                    self.view.window?.close()
                    showCustomAlert(title: "Unlock request sent", body: "Your teacher has been notified. If it's approved, the app or website will unlock automatically.", buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

                    })
                }else{
                    showCustomAlert(title: "Could not send unlock request", body: "Something went wrong while sending your unlock request. Please try again.", buttonOkText: "OK", buttonCancelText: nil, checkBoxText: nil, autoClose: true, buttonLinkUrl: nil, buttonLinkText: nil, completionHandler: {isOkClicked in

                    })
                }
            }
        })
    }
}
