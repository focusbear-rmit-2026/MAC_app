//
//  helpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class helpVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var btnSelectScreenshots: Button!
    @IBOutlet weak var lblAddScreenshots: NSTextField!
    @IBOutlet weak var dropView: dropView!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var webViewGetSupport: WKWebView!
    @IBOutlet weak var tabViewGetSupport: NSTabViewItem!
    @IBOutlet weak var lblTitleWhatsApp: NSTextField!
    @IBOutlet weak var webViewCourses: WKWebView!
    @IBOutlet weak var btnDontUseDiscord: underLineButton!
    @IBOutlet weak var btnJoinDiscordServer: Button!
    @IBOutlet var textView: placeHolderTextView!
    @IBOutlet weak var tabViewReportProblem: NSTabViewItem!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnExportLogs: Button!
    @IBOutlet weak var tabViewCommunity: NSTabViewItem!
    @IBOutlet weak var lblTitleCommunity: NSTextField!
    @IBOutlet weak var tabViewCourses: NSTabViewItem!
    
    @IBOutlet weak var btnJoinWhatsAppGroup: Button!
    var arrScrrenshots = [URL]()
    var tabViewDebugLogs: NSTabViewItem?
    var debugLogsVcObj: DebugLogsVc?
    var tabDebugLogsTitle = "Debug Logs"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSelectScreenshots.title = "Select Screenshots"
        lblAddScreenshots.stringValue = "➕ Drag and drop screenshots here that you want to share"
        
        tabViewGetSupport.label = "Get Support"
        lblTitleWhatsApp.stringValue = "Join the Focus Bear WhatsApp group to exchange ideas, organize co-working/body doubling sessions, and get support with the app!"
        btnJoinWhatsAppGroup.title = "Join WhatsApp Group"
        
        
        tabViewCourses.label = "Tutorials"
        lblTitleCommunity.stringValue = "Join the Focus Bear discord server to share ideas, set up co-working/body doubling sessions and get help with the app."
        btnJoinDiscordServer.title = "Join Discord Server"
        btnDontUseDiscord.title = "I don't use Discord"
        
        tabViewReportProblem.label = "Report Problem"
        tabViewCommunity.label = "Community"
        
        lblTitle.stringValue = "Focus Bear is still a new app and you might encounter issues (or have great ideas on how to make it better). We'd really appreciate your feedback. You can email us at support@focusbear.io. Screenshots are really helpful to let us understand the problem. Also if you had a problem, please share your logs with Focus Bear Support Team (use the link below)"
        
        btnExportLogs.title = "Share logs with Focus Bear Support Team"
        var placeHolderLogsFeedback = "What happened?"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            tabViewReportProblem.label = preferencesInfo.value(forKey: "tabReportProblemText") as? String ?? tabViewReportProblem.label
        }
        
        if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
            btnExportLogs.title = helpVcInfo.value(forKey: "buttonShareLogsText") as? String ?? btnExportLogs.title
            lblTitle.stringValue = helpVcInfo.value(forKey: "shareLogsText") as? String ?? lblTitle.stringValue
            placeHolderLogsFeedback = helpVcInfo.value(forKey: "placeHolderLogsFeedback") as? String ?? placeHolderLogsFeedback
            tabViewCommunity.label = helpVcInfo.value(forKey: "tabCommunity") as? String ?? tabViewCommunity.label
            lblTitleCommunity.stringValue = helpVcInfo.value(forKey: "titleCommunity") as? String ?? lblTitleCommunity.stringValue
            btnJoinDiscordServer.title = helpVcInfo.value(forKey: "buttonJoinDiscordText") as? String ?? btnJoinDiscordServer.title
            btnDontUseDiscord.title = helpVcInfo.value(forKey: "buttonDontUseDiscordText") as? String ?? btnDontUseDiscord.title
            tabViewCourses.label = helpVcInfo.value(forKey: "tabCourses") as? String ?? tabViewCourses.label
            lblTitleWhatsApp.stringValue = helpVcInfo.value(forKey: "titleWhatsAppGroup") as? String ?? lblTitleWhatsApp.stringValue
            btnJoinWhatsAppGroup.title = helpVcInfo.value(forKey: "buttonJoinWhatsAppGroupText") as? String ?? btnJoinWhatsAppGroup.title
            tabViewGetSupport.label = helpVcInfo.value(forKey: "tabGetSupport") as? String ?? tabViewGetSupport.label
            if let title = helpVcInfo.value(forKey: "titleAddScreenshots") as? String{
                lblAddScreenshots.stringValue = "➕ \(title)"
            }
            btnSelectScreenshots.title = helpVcInfo.value(forKey: "buttonSelectScreenshots") as? String ?? btnSelectScreenshots.title
            tabDebugLogsTitle = helpVcInfo.value(forKey: "tabDebugLogs") as? String ?? tabDebugLogsTitle
        }
        
        
        self.webViewGetSupport.navigationDelegate = self
        loadGetSupportWebView()
        
        
        self.webViewCourses.navigationDelegate = self
        loadCoursesWebView()
        
        tabView.delegate = self
        textView.placeHolderTitleString = NSAttributedString(string: placeHolderLogsFeedback, attributes: [NSAttributedString.Key.foregroundColor : NSColor.secondaryLabelColor, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 13)])
        addDebugLogsTabIfNeeded()
        tabView.selectTabViewItem(at: 0)
        
        dropView.delegate = self
        
        btnSelectScreenshots.isSecondaryButton = true
    }
    
    func loadGetSupportWebView(){
        let urlGetSupportString = "https://dashboard.focusbear.io/webview/get-support?bust_cache=\(getUuid())"
        let  urlGetSupport = URL(string: urlGetSupportString)
        let requestGetSupport = NSMutableURLRequest(url: urlGetSupport!)
        webViewGetSupport.load(requestGetSupport as URLRequest)
    }
    
    func loadCoursesWebView(){
        let urlCoursesString = "https://dashboard.focusbear.io/webview/enrolled-courses?bust_cache=\(getUuid())"
        let  urlCourses = URL(string: urlCoursesString)
        let requestCourses = NSMutableURLRequest(url: urlCourses!)
        webViewCourses.load(requestCourses as URLRequest)
    }
    
    override func viewWillAppear() {
        arrScrrenshots.removeAll()
        collectionView.reloadData()
        addDebugLogsTabIfNeeded()
    }
    
    func addDebugLogsTabIfNeeded() {
        let shouldShow = SettingsManagerObject.isAIBlockingEnabled()
        if shouldShow && tabViewDebugLogs == nil {
            tabViewDebugLogs = NSTabViewItem(identifier: "debugLogs")
            tabViewDebugLogs!.label = tabDebugLogsTitle
            debugLogsVcObj = DebugLogsVc()
            tabViewDebugLogs!.viewController = debugLogsVcObj
            tabView.addTabViewItem(tabViewDebugLogs!)
        } else if !shouldShow && tabViewDebugLogs != nil {
            tabView.removeTabViewItem(tabViewDebugLogs!)
            tabViewDebugLogs = nil
            debugLogsVcObj = nil
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                if webView == self.webViewCourses{
                    self.setAccessTokenToWebViewCourses()
                }else if webView == self.webViewGetSupport{
                    self.setAccessTokenToWebViewGetSupport()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
  

    var webViewLoadFailedGetSupportVcObj:webViewLoadFailedVc?
    var webViewLoadFailedCoursesVcObj:webViewLoadFailedVc?
    func removeWebViewLoadFailedView(webView: WKWebView) {
        if webViewLoadFailedGetSupportVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedGetSupportVcObj!.view){
                webViewLoadFailedGetSupportVcObj?.view.removeFromSuperview()
            }
        }
        if webViewLoadFailedCoursesVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedCoursesVcObj!.view){
                webViewLoadFailedCoursesVcObj?.view.removeFromSuperview()
            }
        }
    }
   
    func handleLoadError(webView: WKWebView) {
        if webView == webViewGetSupport{
            if webViewLoadFailedGetSupportVcObj != nil{
                if webView.subviews.contains(webViewLoadFailedGetSupportVcObj!.view){
                    return;
                }
            }
            webViewLoadFailedGetSupportVcObj = getWebViewLoadFailedVcObject()
            webViewLoadFailedGetSupportVcObj!.customDelegate = self
            webViewLoadFailedGetSupportVcObj?.webView = webView
            webView.addSubview(webViewLoadFailedGetSupportVcObj!.view)
            webView.addConstraints(subView: webViewLoadFailedGetSupportVcObj!.view)
        }else if webView == webViewCourses{
            if webViewLoadFailedCoursesVcObj != nil{
                if webView.subviews.contains(webViewLoadFailedCoursesVcObj!.view){
                    return;
                }
            }
            webViewLoadFailedCoursesVcObj = getWebViewLoadFailedVcObject()
            webViewLoadFailedCoursesVcObj!.customDelegate = self
            webViewLoadFailedCoursesVcObj?.webView = webView
            webView.addSubview(webViewLoadFailedCoursesVcObj!.view)
            webView.addConstraints(subView: webViewLoadFailedCoursesVcObj!.view)
        }
    }
    
    func reloadClicked(webView:WKWebView){
        if webView == webViewGetSupport{
            loadGetSupportWebView()
        }else if webView == webViewCourses{
            loadCoursesWebView()
        }
    }
    
    func setAccessTokenToWebViewGetSupport(){
        let theme = getWindowTheme()
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"lang\":\"\(currentLanguageCode)\"}"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadMetaDataFoGetSupport) { loadMetaDataFoGetSupport(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webViewGetSupport.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }

    
    func setAccessTokenToWebViewCourses(){
        let theme = getWindowTheme()
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"lang\":\"\(currentLanguageCode)\"}"
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadMetaDataForEnrolledCourses) { loadMetaDataForEnrolledCourses(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webViewCourses.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
    @IBAction func btnExportLogsClicked(_ sender: Any) {
        
        self.view.addSubview(getLogsUploadingVcObjObj().view)
        self.view.addConstraints(subView: getLogsUploadingVcObjObj().view)
        let message = self.textView.string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self.textView.string
        allApiObject.uploadAppLogs(feedback: message, screenShots: arrScrrenshots, completionHandler: {uploaded in
            DispatchQueue.main.async {
                getLogsUploadingVcObjObj().view.removeFromSuperview()
                if uploaded ?? false{
                    var logsUploadDoneText = "Logs successfully shared."
                    if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
                        logsUploadDoneText = helpVcInfo.value(forKey: "logsUploadDoneText") as? String ?? logsUploadDoneText
                    }
                    self.textView.string = ""
                    self.arrScrrenshots.removeAll()
                    self.collectionView.reloadData()
                    self.showAlert(msg: logsUploadDoneText, completionHandler: {bool in
                        
                    })
                }else{
                    var logsUploadErrorText = "There was some problem in uploading the logs. Please try again."
                    if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
                        logsUploadErrorText = helpVcInfo.value(forKey: "logsUploadErrorText") as? String ?? logsUploadErrorText
                    }
                    self.showAlert(msg: logsUploadErrorText, completionHandler: {bool in
                        
                    })
                }
                
            }
        })

    }
    @IBAction func btnJoinDiscordServerClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-join-discord-server-clicked", metadata: [:])
        let discordUrl = configjson.value(forKey: "discordUrl") as? String ?? "https://discord.gg/VZdv3ZjhSq"
        NSWorkspace.shared.open(URL(string: discordUrl)!)
    }
    @IBAction func btnDontUseDiscordClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-i-dont-use-discord-clicked", metadata: [:])
        self.presentAsSheet(getChooseCommunityVcObject())
    }
    
    var chooseCommunityVcObj:chooseCommunityVc?
    func getChooseCommunityVcObject()->chooseCommunityVc{
        chooseCommunityVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("chooseCommunityVc")) as? chooseCommunityVc
        return chooseCommunityVcObj!
    }
    
    @IBAction func btnJoinWhatsAppGroupClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-join-whatsapp-group-clicked", metadata: [:])
        let discordUrl = configjson.value(forKey: "whatsAppUrl") as? String ?? "https://chat.whatsapp.com/FV0oTbCUWpILBYif7CP6UD"
        NSWorkspace.shared.open(URL(string: discordUrl)!)
    }
    
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in

            completionHandler(true)
            return
        })
    }
    
    @IBAction func btnSelectScreenshotsClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Choose one or more screenshots you want to share."
        openPanel.prompt = "Select"
        
        if let helpVcInfo = configjson.value(forKey: "helpVcInfo") as? NSDictionary{
            openPanel.message = helpVcInfo.value(forKey: "titleSelectScreenshots") as? String ?? openPanel.message
            openPanel.prompt = helpVcInfo.value(forKey: "buttonSelect") as? String ?? openPanel.prompt
        }
        
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = ["png", "jpg", "jpeg", "heic"]
        if let window = self.view.window{
            openPanel.beginSheetModal(for: window,completionHandler: { [self] result in
                if result == .OK{
                    let selectedURLs = openPanel.urls
                    // Handle selected screenshots
                    arrScrrenshots = arrScrrenshots + selectedURLs
                    collectionView.reloadData()
                }
            })
        }
    }
}

extension helpVc: NSTabViewDelegate{
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        let id = tabViewItem?.identifier as? String ?? ""
        if id == "courses"{
            allApiObject.capturePosthog(event: "help-tab-tutorials-clicked", metadata: [:])
        }else if id == "community"{
            allApiObject.capturePosthog(event: "help-tab-community-clicked", metadata: [:])
        }else if id == "report"{
            allApiObject.capturePosthog(event: "help-tab-report-problem-clicked", metadata: [:])
        }else if id == "chat"{
            allApiObject.capturePosthog(event: "help-tab-chat-with-focus-bear-clicked", metadata: [:])
        }else if id == "support"{
            allApiObject.capturePosthog(event: "help-tab-get-support-clicked", metadata: [:])
        }else if id == "debugLogs"{
            allApiObject.capturePosthog(event: "help-tab-debug-logs-clicked", metadata: [:])
            debugLogsVcObj?.tblView.reloadData()
            debugLogsVcObj?.updateNoLogsVisibility()
        }
    }
}

extension helpVc:NSCollectionViewDelegate, NSCollectionViewDataSource, dropViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if arrScrrenshots.count == 0{
            lblAddScreenshots.isHidden = false
        }else{
            lblAddScreenshots.isHidden = true
        }
        return arrScrrenshots.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionCellScreenshots"), for: indexPath) as! collectionCellScreenshots
        
        item.imgView.image = NSImage(contentsOf: arrScrrenshots[indexPath.item])
        item.btnRemove.tag = indexPath.item
        item.btnRemove.target = self
        item.btnRemove.action = #selector(btnRemoveClicked)
        return item
    }
    
    @objc func btnRemoveClicked(sender:NSButton){
        let index = sender.tag
        arrScrrenshots.remove(at: index)
        collectionView.reloadData()
    }
    
    func filesAddedInDropView(filesAdded: [URL]) {
        arrScrrenshots = arrScrrenshots + filesAdded
        collectionView.reloadData()
    }
}
