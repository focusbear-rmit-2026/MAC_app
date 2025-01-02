//
//  taskPlayerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/05/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class taskPlayerVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var boxForHoverEffect: NSBox!
    @IBOutlet weak var boxBg: NSBox!
    //    @IBOutlet weak var constraintWidthTitleBar: NSLayoutConstraint!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var btnBackToOriginalPosition: mouseDownMoveWindowButton!
    @IBOutlet weak var boxTitleBar: NSBox!
    @IBOutlet weak var boxBackToOriginalPosition: NSBox!
    @IBOutlet weak var stackViewTopButtons: NSStackView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var boxMinimize: NSBox!
    @IBOutlet weak var boxMaximize: NSBox!
    @IBOutlet weak var boxClose: NSBox!
    
    @IBOutlet weak var imgViewMinimize: NSImageView!
    @IBOutlet weak var imgViewMaximize: NSImageView!
    @IBOutlet weak var imgViewClose: NSImageView!
    
    @IBOutlet weak var btnArrowRight: cursorButton!
    @IBOutlet weak var btnArrowLeft: cursorButton!
    var topButtonsTrackingArea: NSTrackingArea?
    let handler = MessageHandler()
    var totalDuration = 0
    var intention = ""
    var trackingAreaWebView: NSTrackingArea?
    var lastWindowFrame:NSRect = NSRect(x: 50, y: 50, width: 500, height: 500)
    var isSnapLeft = true
    var isSnappingGoing = false
    var isMouseEntering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        webView.configuration.userContentController.add(handler, name: "close_focus_player_ui")
        webView.configuration.userContentController.add(handler, name: "send_new_task_added_to_todo_player")
        webView.configuration.userContentController.add(handler, name: "send_brain_dump_content")
        webView.configuration.userContentController.add(handler, name: "send_intention")
        
        topButtonsTrackingArea = NSTrackingArea.init(rect: stackViewTopButtons.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        stackViewTopButtons.addTrackingArea(topButtonsTrackingArea!)
        
        self.view.window?.backgroundColor = NSColor.clear
        
        
        createTrackingArea()
        
        btnArrowLeft.toolTip = "Snap to left"
        btnArrowRight.toolTip = "Snap to right"
        
        if let taskPlayerVcInfo = configjson.value(forKey: "taskPlayerVcInfo") as? NSDictionary{
            btnArrowLeft.toolTip = taskPlayerVcInfo.value(forKey: "toolTipSnapLeft") as? String ?? btnArrowLeft.toolTip
            btnArrowRight.toolTip = taskPlayerVcInfo.value(forKey: "toolTipSnapRight") as? String ?? btnArrowRight.toolTip
        }
        
        btnArrowLeft.isHidden = true
        btnArrowRight.isHidden = true
        boxBackToOriginalPosition.isHidden = true
    }
    
    override func viewWillAppear() {
        
    }
    
    
    override func viewWillDisappear() {
        if stackViewTopButtons.isHidden{
            stackViewTopButtons.isHidden = false
            self.view.window!.setFrame(lastWindowFrame, display: true)
            boxBackToOriginalPosition.isHidden = true
            taskPlayerWcObj?.window?.styleMask.insert(.resizable)
            imgViewAppIcon.isHidden = true
        }
    }
    
    override func viewDidLayout() {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
            }
        }
    }
    
    override func viewDidAppear() {
        updateTrackingAreaIfNeeded()
    }
    func updateTrackingAreaIfNeeded() {
        // Remove the old tracking area if it exists
        if let trackingArea = self.trackingAreaWebView {
            webView.removeTrackingArea(trackingArea)
        }
        
        // Recreate the tracking area with the updated bounds
        createTrackingArea()
    }
    
    func createTrackingArea(){
        trackingAreaWebView = NSTrackingArea.init(rect: self.boxBg.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.boxBg.addTrackingArea(trackingAreaWebView!)
    }
    func windowDragged(){
        if !boxBackToOriginalPosition.isHidden{
            let midXPoint = (self.view.window?.screen?.frame.midX ?? 0) - 10
            if (self.view.window?.frame.midX)! > midXPoint{
                isSnapLeft = false
            }else{
                isSnapLeft = true
            }
            mouseActiveSetSmallWindowFrame()
        }
    }

    
    override func mouseEntered(with event: NSEvent) {
        if isSnappingGoing{
            return;
        }
        if event.trackingArea == topButtonsTrackingArea && !stackViewTopButtons.isHidden{
            imgViewClose.isHidden = false
            imgViewMaximize.isHidden = false
            imgViewMinimize.isHidden = false
        }else if event.trackingArea == trackingAreaWebView || event.trackingArea == topButtonsTrackingArea{
            if btnBackToOriginalPosition.isHidden{
                btnBackToOriginalPosition.isHidden = false
                mouseActiveSetSmallWindowFrame()
                isMouseEntering = true
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.isMouseEntering = false
                    }
                }
            }
        }
    }
    
    func mouseActiveSetSmallWindowFrame(){
        if !boxBackToOriginalPosition.isHidden{
            if isSnapLeft{
                let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 10
                animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 180, height: self.view.window!.frame.height), duration: 0)
                imgViewAppIcon.isHidden = true
            }else{
                let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 10
                let width:CGFloat = 180
                let xPoint = maxXPoint - width
                
                animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 180, height: self.view.window!.frame.height), duration: 0)
                imgViewAppIcon.isHidden = true
                
                
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        if isSnappingGoing{
            return;
        }
        if isMouseEntering{
            return;
        }
        if event.trackingArea == topButtonsTrackingArea && !stackViewTopButtons.isHidden{
            imgViewClose.isHidden = true
            imgViewMaximize.isHidden = true
            imgViewMinimize.isHidden = true
        }else if event.trackingArea == trackingAreaWebView || event.trackingArea == topButtonsTrackingArea{
            btnBackToOriginalPosition.isHidden = true
            if !boxBackToOriginalPosition.isHidden{
                if isSnapLeft{
                    let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 10
                    animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 60, height: self.view.window!.frame.height), duration: 0)
                    imgViewAppIcon.isHidden = false
                }else{
                    let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 10
                    let width:CGFloat = 60
                    let xPoint = maxXPoint - width
                    animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: width, height: self.view.window!.frame.height), duration: 0)
                    imgViewAppIcon.isHidden = false
                }
                
            }
        }
    }
    var isAnimationGoing = false
    func animateWindowFrameChange(window: NSWindow, newFrame: NSRect, duration: TimeInterval) {
        if isAnimationGoing{
            isAnimationGoing = false
            window.setFrame(newFrame, display: true, animate: false)
            return;
        }
        
        if duration == 0{
            window.setFrame(newFrame, display: true, animate: false)
        }else{
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                window.animator().setFrame(newFrame, display: true)
                isAnimationGoing = true
            }, completionHandler: {
                // Completion handler if needed
                print("Animation completed")
                self.isAnimationGoing = false
            })
        }
    }
    
    
    func reloadData(totalDuration:Int, intention:String){
        if !boxBackToOriginalPosition.isHidden{
            btnBackToOriginalPositionClicked(self)
        }
        
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        imgViewAppIcon.isHidden = true
        boxBackToOriginalPosition.isHidden = true
        stackViewTopButtons.isHidden = false
        btnBackToOriginalPosition.isHidden = true
        
        self.totalDuration = totalDuration
        self.intention = intention
        if !self.intention.isEmpty{
            self.intention = self.intention.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self.intention
        }
        setAccessTokenToWebView()
        boxBackToOriginalPosition.isHidden = true
        btnBackToOriginalPosition.isHidden = true
    }
    
    func reloadView(){
        if !boxBackToOriginalPosition.isHidden{
            btnBackToOriginalPositionClicked(self)
        }
        
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        imgViewAppIcon.isHidden = true
        boxBackToOriginalPosition.isHidden = true
        stackViewTopButtons.isHidden = false
        btnBackToOriginalPosition.isHidden = true
    }
    func loadRequest(){
        let webUrl = "https://dashboard.focusbear.io/webview/todo-player?bust_cache=\(getUuid())"
        let link = URL(string:webUrl)!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                if taskPlayerWcObj != nil{
                    if taskPlayerWcObj?.window?.isVisible ?? false{
                        self.setAccessTokenToWebView()
                    }
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
  

    var webViewLoadFailedVcObj:webViewLoadFailedVc?
    func removeWebViewLoadFailedView(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.view.removeFromSuperview()
            }
        }
    }
   
    func handleLoadError(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                return;
            }
        }
        webViewLoadFailedVcObj = getWebViewLoadFailedVcObject()
        webViewLoadFailedVcObj!.customDelegate = self
        webViewLoadFailedVcObj?.webView = webView
        webView.addSubview(webViewLoadFailedVcObj!.view)
        webView.addConstraints(subView: webViewLoadFailedVcObj!.view)
    }
    
    func reloadClicked(webView:WKWebView){
        loadRequest()
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        if taskPlayerVcObj != nil && UserDefaults.standard.object(forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime) == nil && SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            UserDefaults.standard.set(true, forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime)
            let alert = NSAlert()
            alert.setSharingType()
            
            var alertStopLaunchingToDoPlayer = "Do you want to stop the To Do player from launching automatically?"
            var buttonKeepItText = "Keep it"
            var buttonDontShowText = "Don't Show it Again"
            
            if let toDoPlayerVcInfo = configjson.value(forKey: "toDoPlayerVcInfo") as? NSDictionary{
                alertStopLaunchingToDoPlayer = toDoPlayerVcInfo.value(forKey: "alertStopLaunchingToDoPlayer") as? String ?? alertStopLaunchingToDoPlayer
                buttonKeepItText = toDoPlayerVcInfo.value(forKey: "buttonKeepItText") as? String ?? buttonKeepItText
                buttonDontShowText = toDoPlayerVcInfo.value(forKey: "buttonDontShowText") as? String ?? buttonDontShowText
            }
            
            alert.messageText = alertStopLaunchingToDoPlayer
            alert.addButton(withTitle: buttonKeepItText)
            alert.addButton(withTitle: buttonDontShowText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
                if result == .alertSecondButtonReturn{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                self.view.window?.close()
                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
            })
        }else{
            self.view.window?.close()
            allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
        }
    }
    
    @IBAction func btnMinimizeClicked(_ sender: Any) {
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        if isSnapLeft{
            btnArrowLeftClicked(self)
        }else{
            btnArrowRightClicked(self)
        }
        return;
        let windowHeight = self.view.window?.frame.height ?? 1000
        if windowHeight > 280{
            let newWindowHeight:CGFloat = 250
            let changeInY = windowHeight - newWindowHeight
            
            self.view.window!.setFrame(NSRect(x: self.view.window!.frame.minX , y: self.view.window!.frame.minY + changeInY, width: 600, height: newWindowHeight), display: true)
        }
    }
    
    @IBAction func btnMaximizeClicked(_ sender: Any) {
        self.view.window?.zoom(nil)
    }
    func setAccessTokenToWebView(){
        var theme = "LIGHT"
        if preferencesWindowControllerObj != nil{
            if preferencesWindowControllerObj!.window!.hasDarkAppearance{
                theme = "DARK"
            }else {
                theme = "LIGHT"
            }
        }
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var brainDump = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        brainDump = brainDump.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? brainDump
        
        var isFirstTime = false
        if UserDefaults.standard.object(forKey: kUserDefaultsOpenTodoPlayerFirstTime) == nil{
            UserDefaults.standard.set(true, forKey: kUserDefaultsOpenTodoPlayerFirstTime)
            isFirstTime = true
        }

        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"brain_dump\":\"\(brainDump)\",\"isOnboarding\":\(isFirstTime)}"
        
        if !focusModeTaskString.isEmpty{
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":\(focusModeTaskString),\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"brain_dump\":\"\(brainDump)\",\"isOnboarding\":\(isFirstTime)}"
        }
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadMetaDataForToDoPlayer) { loadMetaDataForToDoPlayer(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
    
    func getToDosFromPlayer(){
        let script = "getToDosFromPlayer();"
        webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
            print(html)
        })
    }
    
    
    
    @IBAction func btnArrowLeftClicked(_ sender: Any) {// will be a samll window in left side
        self.isSnappingGoing = true
        lastWindowFrame = self.view.window?.frame ?? lastWindowFrame
        let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 10
        self.view.window!.setFrame(NSRect(x: xPoint , y: self.view.window!.frame.midY, width: 60, height: 180), display: true)
        boxBackToOriginalPosition.isHidden = false
        imgViewAppIcon.isHidden = false
        taskPlayerWcObj?.window?.styleMask.remove(.resizable)
        btnBackToOriginalPosition.isHidden = true
        isSnapLeft = true
        stackViewTopButtons.isHidden = true
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
                self.isSnappingGoing = false
            }
        }
    }
    
    @IBAction func btnArrowRightClicked(_ sender: Any) {// will be a samll window in right side
        isSnappingGoing = true
        lastWindowFrame = self.view.window?.frame ?? lastWindowFrame
        let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 10
        let width:CGFloat = 60
        let xPoint = maxXPoint - width
        self.view.window!.setFrame(NSRect(x: xPoint , y: self.view.window!.frame.midY, width: width, height: 180), display: true)
        boxBackToOriginalPosition.isHidden = false
        imgViewAppIcon.isHidden = false
        taskPlayerWcObj?.window?.styleMask.remove(.resizable)
        btnBackToOriginalPosition.isHidden = true
        isSnapLeft = false
        stackViewTopButtons.isHidden = true
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
                self.isSnappingGoing = false
            }
        }
    }
    @IBAction func btnBackToOriginalPositionClicked(_ sender: Any) {
        stackViewTopButtons.isHidden = false
        self.view.window!.setFrame(lastWindowFrame, display: true)
        boxBackToOriginalPosition.isHidden = true
        taskPlayerWcObj?.window?.styleMask.insert(.resizable)
        btnBackToOriginalPosition.isHidden = true
        imgViewAppIcon.isHidden = true
    }
}
