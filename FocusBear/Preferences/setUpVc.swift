//
//  setUpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class setUpVc: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imgViewCustomiseFocusMode: NSImageView!
    @IBOutlet weak var imgViewCustomiseHabit: NSImageView!
    @IBOutlet weak var imgViewSetBlockedUrls: NSImageView!
    @IBOutlet weak var imgViewCompleteMorningRoutine: NSImageView!
    @IBOutlet weak var imgViewCompleteEveningRoutine: NSImageView!
    @IBOutlet weak var imgViewFocusSession: NSImageView!
    
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTotalProgress: NSTextField!
    @IBOutlet weak var boxProgressFull: NSBox!
    @IBOutlet weak var boxProgressWidth: NSLayoutConstraint!
    @IBOutlet weak var boxProgress: NSBox!
   
    @IBOutlet weak var lblCustomiseFocusMode: NSTextField!
    @IBOutlet weak var lblCustomiseHabit: NSTextField!
    @IBOutlet weak var lblSetBlockedUrls: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutine: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutine: NSTextField!
    @IBOutlet weak var lblFocusSession: NSTextField!
    
    @IBOutlet weak var lblCustomiseFocusModeProgress: NSTextField!
    @IBOutlet weak var lblCustomiseHabitProgress: NSTextField!
    @IBOutlet weak var lblSetBlockedUrlsProgress: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutineProgress: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutineProgress: NSTextField!
    @IBOutlet weak var lblFocusSessionProgress: NSTextField!
    
    
    
    let viewWidthDefault = 1040
    let viewHeightDefault = 682
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self
        let url = "https://dashboard.focusbear.io/webview/stats"
        let  fileURL = URL(string: url)
        let request = NSMutableURLRequest(url: fileURL!)
        webView.load(request as URLRequest)
        
        let handler = MessageHandler()
        webView.configuration.userContentController.add(handler, name: "open_android_app")
        webView.configuration.userContentController.add(handler, name: "open_ios_app")
        
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.setAccessTokenToWebView()
            }
        }
    }
    
    
    
    override func viewWillAppear() {
        preferencesWindowControllerObj?.window?.setContentSize(NSSize(width: viewWidthDefault, height: viewHeightDefault))
    }
    override func viewDidAppear() {
        setAccessTokenToWebView()
    }

    func setAccessTokenToWebView(){
        let stringJson1 = "{\"access_token\":\"\(appdelegate!.credential?.accessToken ?? "")\",\"type\":\"mac\",\"lang\":\"\(currentLanguageCode)\"}"
        
        let javascript = "loadAccessTokenForStats(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
 
    override func viewWillDisappear() {

    }
}
