//
//  reportBadAIResponseVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/02/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class reportBadAIResponseVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var lblUrl: NSTextField!
    @IBOutlet weak var lblTitleUrl: NSTextField!
    @IBOutlet weak var btnReportIssue: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblCheckBoxShareLogs: NSTextField!
    @IBOutlet weak var checkBoxShareLogs: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblTitleAddInfo: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var payload:[String:Any]?
    /// Called when the user actually submits the report. popUpBlockConfirmVc supplies this to allow the
    /// current app/site (the AI was wrong to block it); nil when reporting a historical entry from the
    /// debug logs, where there's no current site to allow.
    var onReported:(() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Report bad AI blocking decision"
        lblTitleAddInfo.stringValue = "What was wrong?"
        lblCheckBoxShareLogs.stringValue = "Share URL and focus intention with Focus Bear team"
        lblTitleUrl.stringValue = "URL:"
        btnReportIssue.title = "Report issue"
        
        if let reportBadAIResponseVcInfo = configjson.value(forKey: "reportBadAIResponseVcInfo") as? NSDictionary{
            lblTitle.stringValue = reportBadAIResponseVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleAddInfo.stringValue = reportBadAIResponseVcInfo.value(forKey: "titleIssue") as? String ?? lblTitleAddInfo.stringValue
            lblCheckBoxShareLogs.stringValue = reportBadAIResponseVcInfo.value(forKey: "checkBoxShareData") as? String ?? lblCheckBoxShareLogs.stringValue
            lblTitleUrl.stringValue = reportBadAIResponseVcInfo.value(forKey: "titleUrl") as? String ?? lblTitleUrl.stringValue
            btnReportIssue.title = reportBadAIResponseVcInfo.value(forKey: "buttonReportText") as? String ?? btnReportIssue.title
        }
        
        lblUrl.stringValue = ""
        btnCancel.title = buttonCancelText
        btnCancel.isSecondaryButton = true
    }
    
    func resetData(url:String?, app:String?, payload:[String:Any]?, onReported:(() -> Void)? = nil){
        self.payload = payload
        self.onReported = onReported
        checkBoxShareLogs.state = .off
        btnReportIssue.isEnabled = false
        if let url = url{
            lblUrl.stringValue = url
            
            lblCheckBoxShareLogs.stringValue = "Share URL and focus intention with Focus Bear team"
            lblTitleUrl.stringValue = "URL:"
            
            if let reportBadAIResponseVcInfo = configjson.value(forKey: "reportBadAIResponseVcInfo") as? NSDictionary{
                lblCheckBoxShareLogs.stringValue = reportBadAIResponseVcInfo.value(forKey: "checkBoxShareData") as? String ?? lblCheckBoxShareLogs.stringValue
                lblTitleUrl.stringValue = reportBadAIResponseVcInfo.value(forKey: "titleUrl") as? String ?? lblTitleUrl.stringValue
            }
        }else if let app = app{
            lblUrl.stringValue = app
            lblCheckBoxShareLogs.stringValue = "Share App name and focus intention with Focus Bear team"
            lblTitleUrl.stringValue = "App:"
            
            if let reportBadAIResponseVcInfo = configjson.value(forKey: "reportBadAIResponseVcInfo") as? NSDictionary{
                lblCheckBoxShareLogs.stringValue = reportBadAIResponseVcInfo.value(forKey: "checkBoxShareAppData") as? String ?? lblCheckBoxShareLogs.stringValue
                lblTitleUrl.stringValue = reportBadAIResponseVcInfo.value(forKey: "titleApp") as? String ?? lblTitleUrl.stringValue
            }
        }
        textView.string = ""
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    @IBAction func checkBoxShareLogsClicked(_ sender: Any) {
        btnReportIssue.isEnabled = checkBoxShareLogs.state == .on ? true : false
    }
    
    @IBAction func btnReportIssueClicked(_ sender: Any) {
        let payload = self.payload ?? [:]
        
        if checkBoxShareLogs.state == .on{
            allApiObject.capturePosthog(event: "bad-ai-blocking-decision", metadata: ["userFeedbackOnDecision": textView.string, "payloadSentToAIEndpoint": "\(payload)"])
        }
        // Reporting a bad AI block means the AI was wrong to block this app/site — allow it for the rest
        // of this focus session so it isn't immediately re-blocked (closure supplied by popUpBlockConfirmVc).
        onReported?()
        self.view.window?.close()
    }
}
