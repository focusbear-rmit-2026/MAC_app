//
//  helpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
import SwiftUI
import UniformTypeIdentifiers

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

        // The Report Problem submit area is now a SwiftUI form (feedback + screenshots + Send, plus a
        // destination radio for one user), hosted over the AppKit controls above.
        setupReportProblemSwiftUI()
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


// MARK: - SwiftUI Report-a-Problem form
//
// The Report Problem tab's submit form (feedback + screenshots + Send) rebuilt in SwiftUI, hosted over
// the AppKit controls. For one user it also shows a destination radio to send to Focus Bear support
// (R2 + Cliq, the existing path) or to write a local Claude task instead.

enum ReportProblemSubmission {
    static func hasContent(note: String, screenshots: [URL]) -> Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !screenshots.isEmpty
    }
}

/// Bundle the current logs + this feedback (+ screenshots) into ~/FocusBear-Claude-Tasks/<timestamp>/
/// with a TASK.md, ready to hand to Claude. Returns the folder.
@discardableResult
func writeFocusBearClaudeTask(note: String, screenshots: [URL],
                             root: URL = LocalReportStatusReader.defaultRoot,
                             accountID: () -> String = { LocalReportCapability.currentAccount }) -> URL? {
    // Reject stray/default-button submissions before looking up identity or touching the filesystem.
    guard ReportProblemSubmission.hasContent(note: note, screenshots: screenshots) else { return nil }
    let account = accountID()
    guard LocalReportCapability.isEnabled(for: account) else { return nil }
    let fm = FileManager.default
    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let stamp = f.string(from: Date())
    let folder = root.appendingPathComponent(stamp, isDirectory: true)
    try? fm.createDirectory(at: folder, withIntermediateDirectories: true)

    var copied: [String] = []
    if let logsURL = DebugLogsFolderURL, let items = try? fm.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: nil) {
        let dst = folder.appendingPathComponent("logs"); try? fm.createDirectory(at: dst, withIntermediateDirectories: true)
        for src in items where src.pathExtension == "txt" {
            try? fm.copyItem(at: src, to: dst.appendingPathComponent(src.lastPathComponent)); copied.append("logs/\(src.lastPathComponent)")
        }
    }
    var shots: [String] = []
    if !screenshots.isEmpty {
        let dst = folder.appendingPathComponent("screenshots"); try? fm.createDirectory(at: dst, withIntermediateDirectories: true)
        for src in screenshots {
            try? fm.copyItem(at: src, to: dst.appendingPathComponent(src.lastPathComponent)); shots.append("screenshots/\(src.lastPathComponent)")
        }
    }
    let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    let body = """
    # Focus Bear — Claude debug task

    - Created: \(stamp)
    - App version: \(version)
    - User: \(account)

    ## What to investigate
    \(note.isEmpty ? "_(no description provided)_" : note)

    ## Logs
    \(copied.isEmpty ? "_(none found)_" : copied.map { "- \($0)" }.joined(separator: "\n"))

    ## Screenshots
    \(shots.isEmpty ? "_(none)_" : shots.map { "- \($0)" }.joined(separator: "\n"))

    ---
    Hand this to Claude with: "work on the task in \(folder.path)"
    """
    try? body.write(to: folder.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
    return folder
}

@available(macOS 11.0, *)
enum ReportDestination: String, CaseIterable, Identifiable {
    case support = "Focus Bear support (R2 + Cliq)"
    case localClaude = "Local Claude task"
    var id: String { rawValue }
}

@available(macOS 11.0, *)
struct ReportProblemForm: View {
    @SwiftUI.State private var feedback = ""
    @SwiftUI.State private var screenshots: [URL] = []
    @SwiftUI.State private var destination: ReportDestination = .support
    @SwiftUI.State private var isSending = false
    @SwiftUI.State private var status: String?
    @SwiftUI.State private var dropTargeted = false
    @SwiftUI.State private var isPicking = false
    @SwiftUI.State private var localReportRefreshToken = 0
    @SwiftUI.State private var isCleanShotPickerVisible = false
    let showDestination: Bool
    /// Both resolved once per launch, not per body pass — this struct is rebuilt on every keystroke in
    /// the feedback field. Nil simply hides the button for anyone who does not have CleanShot.
    private let cleanShotRoot = CleanShotLibrary.defaultRoot
    private let cleanShotStrings = CleanShotPickerStrings.shared
    let onSend: (String, [URL], ReportDestination, @escaping (Bool) -> Void) -> Void
    /// Opens a window-attached file picker (handled by helpVc, which has the window). Done there rather
    /// than with NSOpenPanel.runModal() in SwiftUI — runModal stacked a nested modal loop per click and
    /// the panels opened behind the kiosk window, freezing the app.
    let onPickScreenshots: (@escaping ([URL]) -> Void) -> Void

    init(showDestination: Bool,
         onPickScreenshots: @escaping (@escaping ([URL]) -> Void) -> Void,
         onSend: @escaping (String, [URL], ReportDestination, @escaping (Bool) -> Void) -> Void) {
        self.showDestination = showDestination
        self.onPickScreenshots = onPickScreenshots
        self.onSend = onSend
    }

    private static let imageExts = ["png", "jpg", "jpeg", "heic", "gif", "tiff", "bmp"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Report a problem or share an idea").font(.headline)
                Text("Screenshots and your logs help us understand what happened.")
                    .font(.subheadline).foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $feedback)
                        .font(.system(size: 13)).frame(minHeight: 90)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3)))
                    if feedback.isEmpty {
                        Text("What happened?").foregroundColor(.secondary).padding(10).allowsHitTesting(false)
                    }
                }

                screenshotsZone

                if showDestination {
                    Picker("Send to:", selection: $destination) {
                        ForEach(ReportDestination.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(RadioGroupPickerStyle())
                }

                HStack(spacing: 10) {
                    SwiftUI.Button(isSending ? "Sending…" : "Send") { send() }
                        .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 40))
                        // This form stays hosted while other Help controls/sheets handle Return.
                        // Sending a report must not become the window-wide default action.
                        .disabled(isSending || isPicking || !ReportProblemSubmission.hasContent(note: feedback, screenshots: screenshots))
                    if let s = status { Text(s).foregroundColor(.secondary) }
                    Spacer()
                }
                if showDestination {
                    LocalReportStatusView(refreshToken: localReportRefreshToken)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var screenshotsZone: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !screenshots.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(screenshots, id: \.self) { url in
                            ZStack(alignment: .topTrailing) {
                                if let img = NSImage(contentsOf: url) {
                                    Image(nsImage: img).resizable().scaledToFill()
                                        .frame(width: 60, height: 60).clipped().cornerRadius(4)
                                } else {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.2)).frame(width: 60, height: 60)
                                }
                                SwiftUI.Button { screenshots.removeAll { $0 == url } } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }.buttonStyle(.plain).padding(2)
                            }
                        }
                    }.padding(.vertical, 2)
                }
            }
            HStack {
                Text(isPicking ? "Opening…" : "➕ Drag, paste, or click to choose")
                    .foregroundColor(.secondary)
                if isPicking { ProgressView().scaleEffect(0.5).frame(width: 14, height: 14) }
            }
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(dropTargeted ? 0.18 : 0.06)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(.secondary.opacity(0.4)))
                .contentShape(Rectangle())
                .onTapGesture { chooseScreenshots() }
                .onDrop(of: [UTType.fileURL.identifier, UTType.image.identifier], isTargeted: $dropTargeted) { providers in
                    handleDrop(providers)
                }
                .onPasteCommand(of: [UTType.fileURL.identifier, UTType.image.identifier]) { providers in
                    _ = handleDrop(providers)
                }
            HStack(spacing: 12) {
                SwiftUI.Button { pasteScreenshots() } label: {
                    Label(cleanShotStrings["pasteFromClipboard"], systemImage: "doc.on.clipboard")
                }.buttonStyle(.link).font(.caption)
                // Only when CleanShot has actually saved something — offering a folder that does not
                // exist is worse than not offering it at all.
                if let root = cleanShotRoot {
                    SwiftUI.Button { isCleanShotPickerVisible = true } label: {
                        Label(cleanShotStrings["chooseFromCleanShot"], systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(.link).font(.caption)
                    .sheet(isPresented: $isCleanShotPickerVisible) {
                        CleanShotPickerSheet(
                            root: root,
                            strings: cleanShotStrings,
                            // The very same `screenshots` array the file picker, the drop zone and the
                            // paste button fill, so Send treats a CleanShot pick identically.
                            onChoose: { url in if !screenshots.contains(url) { screenshots.append(url) } },
                            onClose: { isCleanShotPickerVisible = false })
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// Opens the picker exactly once (guarded by isPicking) via helpVc, which presents it as a
    /// window-attached sheet — so repeated clicks can't stack modal loops or hide it behind the app.
    private func chooseScreenshots() {
        guard !isPicking else { return }
        isPicking = true
        onPickScreenshots { urls in
            isPicking = false
            for u in urls where !screenshots.contains(u) { screenshots.append(u) }
        }
    }

    /// Pastes images or image-file URLs from the clipboard. Prefers file URLs and only falls back to
    /// raw images — a screenshot on the clipboard carries BOTH, so handling both would add it twice.
    private func pasteScreenshots() {
        let pb = NSPasteboard.general
        let fileURLs = (pb.readObjects(forClasses: [NSURL.self],
                                       options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? [])
            .filter { ReportProblemForm.imageExts.contains($0.pathExtension.lowercased()) }
        if !fileURLs.isEmpty {
            for u in fileURLs where !screenshots.contains(u) { screenshots.append(u) }
            return
        }
        if let imgs = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage] {
            for img in imgs {
                guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else { continue }
                let tmp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("pasted-screenshot-\(UUID().uuidString).png")
                if (try? png.write(to: tmp)) != nil { screenshots.append(tmp) }
            }
        }
    }

    /// Accepts both dragged files and raw image data (e.g. from CleanShot/Preview, which provide
    /// image bytes rather than a file URL). Raw data is written to a temp PNG so it can be uploaded.
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for p in providers {
            if p.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                handled = true
                _ = p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    var url: URL?
                    if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                    else if let u = item as? URL { url = u }
                    if let url = url, ReportProblemForm.imageExts.contains(url.pathExtension.lowercased()) {
                        DispatchQueue.main.async { if !screenshots.contains(url) { screenshots.append(url) } }
                    }
                }
            } else if p.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                handled = true
                p.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data = data else { return }
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent("dropped-screenshot-\(UUID().uuidString).png")
                    guard (try? data.write(to: tmp)) != nil else { return }
                    DispatchQueue.main.async { screenshots.append(tmp) }
                }
            }
        }
        return handled
    }

    private func send() {
        guard !isSending, !isPicking,
              ReportProblemSubmission.hasContent(note: feedback, screenshots: screenshots) else { return }
        isSending = true; status = nil
        onSend(feedback, screenshots, showDestination ? destination : .support) { ok in
            isSending = false
            status = ok ? "Sent ✓" : "Failed — please try again"
            if ok { feedback = ""; screenshots = []; localReportRefreshToken += 1 }
        }
    }
}

extension helpVc {
    /// Host the SwiftUI report form over the AppKit Report Problem controls.
    func setupReportProblemSwiftUI() {
        guard #available(macOS 11.0, *), let container = tabViewReportProblem.view else { return }
        let gated = LocalReportCapability.isEnabled(for: appdelegate?.user?.userId ?? "")
        let form = ReportProblemForm(
            showDestination: gated,
            onPickScreenshots: { [weak self] completion in self?.pickReportScreenshots(completion) },
            onSend: { [weak self] feedback, shots, dest, done in
                self?.sendReport(feedback: feedback, screenshots: shots, destination: dest, completion: done)
            })
        let hosting = NSHostingView(rootView: form)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        // Hide the old AppKit controls — the SwiftUI form replaces them.
        let old: [NSView?] = [lblTitle, textView.enclosingScrollView ?? textView, dropView,
                              collectionView.enclosingScrollView ?? collectionView,
                              lblAddScreenshots, btnSelectScreenshots, btnExportLogs]
        old.forEach { $0?.isHidden = true }
        btnExportLogs.isEnabled = false
        btnExportLogs.keyEquivalent = ""
    }

    /// Presents the screenshot picker as a sheet attached to the Help window. A sheet can't be opened
    /// twice (guarded again by `attachedSheet`) and can't fall behind the kiosk window — both were the
    /// cause of the freeze from the earlier runModal() approach.
    func pickReportScreenshots(_ completion: @escaping ([URL]) -> Void) {
        guard let window = view.window, window.attachedSheet == nil else { completion([]); return }
        // Building NSOpenPanel spins up com.apple.appkit.xpc.openAndSavePanelService and blocks the
        // main thread for ~3s on first use. Done in the caller's run-loop turn, SwiftUI commits the
        // "Opening…" spinner only AFTER that block — so the click looked completely dead for 3s
        // (report 2026-06-24_17-56-32). Hopping to the next turn lets the spinner paint first; the
        // wait is the same length, but it is now visibly acknowledged.
        DispatchQueue.main.async { [weak self] in
            // Re-check: a turn has passed, so the window may have gone or grown a sheet since.
            guard let self = self, let window = self.view.window, window.attachedSheet == nil else {
                completion([]); return
            }
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            if #available(macOS 11.0, *) { panel.allowedContentTypes = [.image] }
            panel.message = "Choose screenshots to attach"
            panel.beginSheetModal(for: window) { resp in
                completion(resp == .OK ? panel.urls : [])
            }
        }
    }

    @available(macOS 11.0, *)
    func sendReport(feedback: String, screenshots: [URL], destination: ReportDestination, completion: @escaping (Bool) -> Void) {
        guard ReportProblemSubmission.hasContent(note: feedback, screenshots: screenshots) else {
            completion(false)
            return
        }
        switch destination {
        case .support:
            let message = feedback.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? feedback
            view.addSubview(getLogsUploadingVcObjObj().view)
            view.addConstraints(subView: getLogsUploadingVcObjObj().view)
            allApiObject.uploadAppLogs(feedback: message, screenShots: screenshots) { uploaded in
                DispatchQueue.main.async {
                    getLogsUploadingVcObjObj().view.removeFromSuperview()
                    completion(uploaded ?? false)
                }
            }
        case .localClaude:
            let folder = writeFocusBearClaudeTask(note: feedback, screenshots: screenshots)
            // Don't reveal the folder in Finder — submitting several reports piled up Finder windows
            // the user had to close one by one. The report still lands in ~/FocusBear-Claude-Tasks.
            completion(folder != nil)
        }
    }
}
