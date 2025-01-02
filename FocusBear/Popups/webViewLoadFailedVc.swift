//
//  webViewLoadFailedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 11/10/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class webViewLoadFailedVc: NSViewController {

    @IBOutlet weak var btnReload: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    var webView:WKWebView?
    
    var customDelegate:webViewLoadFailedDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Failed to load. Please check your connection."
        btnReload.title = "Reload"
        if let webViewLoadFailedVcInfo = configjson.value(forKey: "webViewLoadFailedVcInfo") as? NSDictionary{
            lblTitle.stringValue = webViewLoadFailedVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnReload.title = webViewLoadFailedVcInfo.value(forKey: "buttonReloadText") as? String ?? btnReload.title
        }
    }
    
    @IBAction func btnReloadClicked(_ sender: Any) {
        if let webView = webView{
            customDelegate?.reloadClicked(webView: webView)
        }
    }
}
protocol webViewLoadFailedDelegate {
    func reloadClicked(webView:WKWebView)
}
