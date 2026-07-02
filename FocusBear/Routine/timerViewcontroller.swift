//
//  timerViewcontroller.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
import WebKit
class timerViewcontroller: NSViewController, WKNavigationDelegate{
    
    
  
    @IBOutlet weak var btnBackToHabits: Button!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var btnTutorial: cursorButton!
    @IBOutlet weak var webViewTutorial: WKWebView!
    @IBOutlet weak var boxTutorial: NSBox!
    @IBOutlet weak var lblCompletionRequirements: NSTextField!
    @IBOutlet weak var boxCompletionRequirements: NSBox!
    @IBOutlet weak var btnIAmDone: Button!
    @IBOutlet weak var stackViewCustomTab: NSStackView!
    @IBOutlet weak var boxHabitImagesWidth: NSLayoutConstraint!
    @IBOutlet weak var collectionViewImges: NSCollectionView!
    @IBOutlet var textViewInstructions: NSTextView!
    @IBOutlet weak var boxInstructions: NSBox!
    @IBOutlet weak var btnTabInstructions: cursorButton!
    @IBOutlet weak var btnTabNotes: NSButton!
    @IBOutlet weak var btnTabVideo: NSButton!
    @IBOutlet weak var boxTakeNotes: NSBox!
    @IBOutlet weak var boxButtonTabViews: NSBox!
    @IBOutlet weak var lblTitleTakeNotes: NSTextField!
    @IBOutlet var textViewNotes: NSTextView!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var boxPlay: NSBox!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var boxTimerCenterY: NSLayoutConstraint!
    @IBOutlet weak var titleTopSpace: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!

    @IBOutlet weak var lblTitleCheckList: NSTextField!
    @IBOutlet weak var btnTabCheckList: cursorButton!
    // @IBOutlet weak var videoView: AVPlayerView!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var boxCheckList: NSBox!
    @IBOutlet weak var tblViewCheckList: NSTableView!
    
    var currentActicityTitle = ""
    var currentDurationInSeconds = 0
    var currentUrl:String?
    var currentActivityUseTimer = true
    var logQuantityQuestions:[quantityQuestion] = []
    var logQuantityType:String?
    var logActivityQuantity = false
    
    var timerHideBearAnimation:Timer?
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var startTimerValue = 0// we starts timer after video lodded completely and if user has postponed habit at 10 second then we start again habit after postpone time finished from 10 seconds directly  and to hold that value till video  load we are using this variable.

    var textCompletionRequirements = "Complete After: <REQUIREMENTS>"
    let pauseIcon = NSImage(named: NSImage.touchBarPauseTemplateName)
    let playIcon = NSImage(named: NSImage.touchBarPlayTemplateName)
    
    var moreActionsMenu = NSMenu()
    var startAnotherHabitVcObj:startAnotherHabitVc?
    var menuItemSkipHabit: NSMenuItem!
    var menuItemChooseHabit: NSMenuItem!
    var menuItemChooseVideo: NSMenuItem!
    var arrStartCustomRoutineMenu = [NSMenuItem]()
    var isActivityPaused = false
    
    var isVideoLodded = false
    var arrImgUrls = [String]()
    var arrCheckList = [[String:Any]]()
    var images: [NSImage?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let orangeColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        btnBackToHabits.borderColor = orangeColor.withAlphaComponent(0.5).cgColor
        btnBackToHabits.buttonColor = orangeColor.withAlphaComponent(0.1).cgColor
        btnBackToHabits.isHidden = true
        
        btnTutorial.title = "Tutorial"
        menuItemSkipHabit = NSMenuItem(title: "Skip this habit for today", action: #selector(menuItemSkipHabitClicked), keyEquivalent: "")
        menuItemSkipHabit.target = self
        moreActionsMenu.addItem(menuItemSkipHabit)
                
        menuItemChooseHabit = NSMenuItem(title: "Choose another habit", action: #selector(menuItemChooseAnotherHabitClicked), keyEquivalent: "")
        menuItemChooseHabit.target = self
        moreActionsMenu.addItem(menuItemChooseHabit)

        menuItemChooseVideo = NSMenuItem(title: "Choose a different video", action: #selector(menuItemChooseAnotherVideoClicked), keyEquivalent: "")
        menuItemChooseVideo.target = self
        moreActionsMenu.addItem(menuItemChooseVideo)
        
        
        tblViewCheckList.delegate = self
        tblViewCheckList.dataSource = self
       
        lblTitleCheckList.stringValue = "Check List"
        btnTabCheckList.title = "Check List"
        
        btnIAmDone.title = "I'm done"
       
        btnTabVideo.title = "Video"
        btnTabNotes.title = "Notes"
        btnTabInstructions.title = "Instructions"
        lblTitleTakeNotes.stringValue = "Take Notes"
        
        
        textViewNotes.delegate = self
        btnSkipHabit.isHidden = true

        self.webView.navigationDelegate = self
        self.webViewTutorial.navigationDelegate = self
        boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
        
        boxTimer.wantsLayer = true
        boxTimer.shadow = NSShadow()
        boxTimer.layer?.shadowOpacity = 0.3
        boxTimer.layer?.shadowColor = NSColor.black.cgColor
        boxTimer.layer?.shadowOffset = NSMakeSize(0, -2)
        boxTimer.layer?.shadowRadius = 5
        
        boxPlay.wantsLayer = true
        boxPlay.shadow = NSShadow()
        boxPlay.layer?.shadowOpacity = 0.3
        boxPlay.layer?.shadowColor = NSColor.black.cgColor
        boxPlay.layer?.shadowOffset = NSMakeSize(0, -2)
        boxPlay.layer?.shadowRadius = 5
        
        
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnTabVideo.title = activityInfo.value(forKey: "buttonVideoText") as? String ?? btnTabVideo.title
            btnTabNotes.title = activityInfo.value(forKey: "buttonNotesText") as? String ?? btnTabNotes.title
            lblTitleTakeNotes.stringValue = activityInfo.value(forKey: "titleTakeNotes") as? String ?? lblTitleTakeNotes.stringValue
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
            btnTabInstructions.title = activityInfo.value(forKey: "buttonInstructionsText") as? String ?? btnTabInstructions.title
            menuItemChooseVideo.title = activityInfo.value(forKey: "buttonChooseVideoText") as? String ?? menuItemChooseVideo.title
            btnIAmDone.title = activityInfo.value(forKey: "buttonActivityDoneText") as? String ?? btnIAmDone.title
            textCompletionRequirements = activityInfo.value(forKey: "completionRequirementsText") as? String ?? textCompletionRequirements
            lblTitleCheckList.stringValue = activityInfo.value(forKey: "titleCheckList") as? String ?? lblTitleCheckList.stringValue
            btnTabCheckList.title = activityInfo.value(forKey: "titleCheckList") as? String ?? btnTabCheckList.title
            menuItemChooseHabit.title = activityInfo.value(forKey: "buttonChooseHabitText") as? String ?? menuItemChooseHabit.title
            menuItemSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? menuItemSkipHabit.title
            btnTutorial.title = activityInfo.value(forKey: "buttonTutorialText") as? String ?? btnTutorial.title
        }
        boxInstructions.isHidden = true
        btnTabInstructions.isHidden = true
        
        boxCheckList.isHidden = true
        btnTabCheckList.isHidden = true
        boxTutorial.isHidden = true
    }

    
    override func viewWillAppear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
        if !isActivityPaused{
            btnSkipHabit.isHidden = true
        }
    }
    
    override func viewWillDisappear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
        boxBg.isHidden = false
        if askIntentionAllowedFocusModeActivityObj != nil{
            if askIntentionAllowedFocusModeActivityObj?.presentingViewController == self{
                askIntentionAllowedFocusModeActivityObj?.dismiss(askIntentionAllowedFocusModeActivityObj)
            }
        }
    }
    @IBAction func btnTabInstructionsClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxCheckList.isHidden = true
        boxTutorial.isHidden = true
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .on
        boxInstructions.isHidden = false
        btnTabCheckList.state = .off
        btnTutorial.state = .off
        if  collectionViewImges.enclosingScrollView?.isHidden == false{
            let containerWidth = stackViewCustomTab.frame.width
            let itemsWidth:CGFloat = CGFloat((arrImgUrls.count * 140) + ((arrImgUrls.count - 1)*10) + 5)
            if itemsWidth < (containerWidth - 20){
                boxHabitImagesWidth.constant = itemsWidth
            }else{
                boxHabitImagesWidth.constant = containerWidth - 2
            }
        }
    }
    
    @IBAction func btnTabNotesClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = false
        boxCheckList.isHidden = true
        boxTutorial.isHidden = true
        btnTabVideo.state = .off
        btnTabNotes.state = .on
        btnTabInstructions.state = .off
        boxInstructions.isHidden = true
        btnTabCheckList.state = .off
        btnTutorial.state = .off
        self.view.window?.makeFirstResponder(textViewNotes)
    }
    
    @IBAction func btnTabVideoClicked(_ sender: Any) {
        webView.isHidden = false
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = true
        boxTutorial.isHidden = true
        btnTabVideo.state = .on
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .off
        btnTutorial.state = .off
    }
    @IBAction func btnTabCheckListClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = false
        boxTutorial.isHidden = true
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .on
        btnTutorial.state = .off
    }
    
    @IBAction func btnTabTutorialClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = true
        boxTutorial.isHidden = false
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .off
        btnTutorial.state = .on
    }
    
    @IBAction func btnBackToHabitsClicked(_ sender: Any) {
        if currentHabitIndex >= 0{
            currentHabitIndex -= 1
        }
        getHabitsVcObject().showAllMorningEveningHabitsFromHabitCompleted()
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        if webView == self.webView{
            if isVideoLoding{
                isVideoLoding = false
            }
            if currentState == ._MICRO_BREAK_ && appdelegate!.isUserOnMeeting{//Mute video volume during in meeting breaks #796
                if #available(macOS 12.0, *) {
                    self.webView.pauseAllMediaPlayback()
                } else {
                    // Fallback on earlier versions
                }
            }
            if isActivityPaused{
                DispatchQueue.global().async {
                    sleep(2)// for vimeo it needs 2 seconds for youtube it need 1 second
                    DispatchQueue.main.async {
                        if self.isActivityPaused{
                            if #available(macOS 12.0, *) {
                                webView.setAllMediaPlaybackSuspended(true)
                                print("setAllMediaPlaybackSuspended")
                            } else {
                                // Fallback on earlier versions
                            }
                        }
                    }
                }
            }
        }else if webView == self.webViewTutorial{
            setAccessTokenToTutorialWebView()
        }
    }
    
    func setAccessTokenToTutorialWebView(){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        let stringJson = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\",\"font\":\"\(selectedFont)\",\"lang\":\"\(currentLanguageCode)\",\"theme\":\"\(theme)\",\"platform\":\"mac\",\"type\":\"mac\"}"
    
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForCourse) { loadAccessTokenForCourse(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
    
        webViewTutorial.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
    
    var isVideoLoding = false{
        didSet{
            if isVideoLoding{
                getHabitsVcObject().btnAbort.isEnabled = false
                btnPause.isEnabled = false
            }else{
                getHabitsVcObject().btnAbort.isEnabled = true
                btnPause.isEnabled = true
                currentTimer = startTimerValue
                startTimerValue = 0
            }
        }
    }
    
    
    func changeVideoUrl(url:String){
        var videoUrl = url
        addLog(text:"video url is :- \(videoUrl)")
        var isVimeoUrl = false
        var videoID: String?
        if let host = URL(string: videoUrl)?.host {
            isVimeoUrl = host.contains("vimeo.com")
            print(isVimeoUrl) // true if it's a Vimeo link
        }

        if isVimeoUrl{
            if let (url,id) = vimeoEmbedURL(from: videoUrl){
                videoID = id
                videoUrl = url
            }
        }else{
            if videoUrl.lowercased().contains("watch?v="){
                if videoUrl.contains("&"){// removing additional param
                    if let firstItem =  videoUrl.components(separatedBy: "&").first{
                        videoUrl = firstItem
                    }
                }
                videoID = videoUrl.components(separatedBy: "watch?v=").last
                videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
            }else{
                // doing this beacuse if video is embedded than it will not play
                if videoUrl.lowercased().contains("https://youtu.be/"){
                    if let lastItem =  videoUrl.components(separatedBy: "/").last{
                        videoID = lastItem.components(separatedBy: "?").first//lastItem
                        if let videoID = videoID {
                            videoUrl = "https://www.youtube.com/embed/" + videoID
                        }
                    }
                    
                }else if videoUrl.lowercased().contains("embed/") {
                    if let lastItem = videoUrl.components(separatedBy: "/").last {
                        // Remove query params if present
                        videoID = lastItem.components(separatedBy: "?").first
                    }
                }
            }
        }
        if videoUrl.contains("?"){
            videoUrl = videoUrl + "&autoplay=1"
        }else{
            videoUrl = videoUrl + "?autoplay=1"
        }
        
        let videoIDUnwrapped = videoID ?? ""
        
        if !SettingsManagerObject.isOfficeModeEnabled || currentState == ._BREATHING_{
            //If a video finishes before the end of a habit, automatically restart it #1476 28/7/25 v 1.26.395
            if videoUrl.contains("?"){
                videoUrl = videoUrl + "&loop=1&playlist=\(videoIDUnwrapped)"
            }else{
                videoUrl = videoUrl + "?loop=1&playlist=\(videoIDUnwrapped)"
            }
        }
       
        
        if !isVimeoUrl{
            if videoUrl.contains("?"){
                videoUrl = videoUrl + "&rel=0"
            }else{
                videoUrl = videoUrl + "?rel=0"
            }
            //videoUrl = videoUrl.replacingOccurrences(of: "youtube.com", with: "youtube-nocookie.com")// not working
        }
        
        addLog(text:"Final video url is :- \(videoUrl)")// Added in v 2.27.419
        print("Final video url is :- \(videoUrl)")
        let link = URL(string:videoUrl)!
        var request = URLRequest(url: link)
        request.setValue("com.App.EarnYourScreentime", forHTTPHeaderField: "Referer")/// v 2.27.336 for Fix Youtube embed #1554(still some urls having problem)
        ///
        if #available(macOS 12.0, *) {
            self.webView.setAllMediaPlaybackSuspended(false)
        } else {
            // Fallback on earlier versions
        }
        self.webView.load(request)
        allApiObject.capturePosthog(event: "play-youtube-video-in-activity", metadata: [:])
    }
    
    
    func vimeoEmbedURL(from urlString: String) -> (String,String)? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        // Case 1: Already an embed URL (player.vimeo.com)
        if host.contains("player.vimeo.com"),
           pathComponents.contains("video"),
           let videoID = pathComponents.last {
            return ("https://player.vimeo.com/video/\(videoID)", videoID)
        }
        
        // Case 2: Normal Vimeo link (vimeo.com/VIDEO_ID or with query params)
        if host.contains("vimeo.com"),
           let videoID = pathComponents.last,
           Int(videoID) != nil {
            return ("https://player.vimeo.com/video/\(videoID)", videoID)
        }
        
        // Not a valid Vimeo link
        return nil
    }
    
    func loadWebViewTo(url:String?){
        btnTabVideo.isHidden = true
        isVideoLodded = false
        if var videoUrl = url{
            addLog(text:"video url is :- \(videoUrl)")
            self.webView.isHidden = false
            isVideoLodded = true
            tabCount += 1
            btnTabVideo.isHidden = false
            var videoID: String?
            var isVimeoUrl = false
            
            if let host = URL(string: videoUrl)?.host {
                isVimeoUrl = host.contains("vimeo.com")
                print(isVimeoUrl) // true if it's a Vimeo link
            }
            if isVimeoUrl{
                if let (url,id) = vimeoEmbedURL(from: videoUrl){
                    videoID = id
                    videoUrl = url
                }
            }else{
                if videoUrl.lowercased().contains("watch?v="){
                    if videoUrl.contains("&"){// removing additional param
                        if let firstItem =  videoUrl.components(separatedBy: "&").first{
                            videoUrl = firstItem
                        }
                    }
                    videoID = videoUrl.components(separatedBy: "watch?v=").last
                    videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
                }else{
                    // doing this beacuse if video is embedded than it will not play
                    if videoUrl.lowercased().contains("https://youtu.be/"){
                        if let lastItem =  videoUrl.components(separatedBy: "/").last{
                            
                            videoID = lastItem.components(separatedBy: "?").first//lastItem
                            if let videoID = videoID {
                                videoUrl = "https://www.youtube.com/embed/" + videoID
                            }
                        }
                        
                    }else if videoUrl.lowercased().contains("embed/") {
                        if let lastItem = videoUrl.components(separatedBy: "/").last {
                            // Remove query params if present
                            videoID = lastItem.components(separatedBy: "?").first
                        }
                    }
                }
            }
            
            let videoIDUnwrapped = videoID ?? ""
            
            if !SettingsManagerObject.isOfficeModeEnabled || currentState == ._BREATHING_{
                if videoUrl.contains("?"){
                    videoUrl = videoUrl + "&autoplay=1"
                }else{
                    videoUrl = videoUrl + "?autoplay=1"
                }
                
                //If a video finishes before the end of a habit, automatically restart it #1476 28/7/25 v 1.26.395
                if videoUrl.contains("?"){
                    videoUrl = videoUrl + "&loop=1&playlist=\(videoIDUnwrapped)"
                }else{
                    videoUrl = videoUrl + "?loop=1&playlist=\(videoIDUnwrapped)"
                }
            }
            
            
            
            if !isVimeoUrl{
                if videoUrl.contains("?"){
                    videoUrl = videoUrl + "&rel=0"
                }else{
                    videoUrl = videoUrl + "?rel=0"
                }
                //videoUrl = videoUrl.replacingOccurrences(of: "youtube.com", with: "youtube-nocookie.com")// // not working //
            }
            addLog(text:"Final video url is :- \(videoUrl)")// Added in v 2.27.419
            print("Final video url is :- \(videoUrl)")
            let link = URL(string:videoUrl)!
            var request = URLRequest(url: link)
            
            request.setValue("com.App.EarnYourScreentime", forHTTPHeaderField: "Referer")// v 2.27.336 for Fix Youtube embed #1554(still some urls having problem)
            
            if #available(macOS 12.0, *) {
                self.webView.setAllMediaPlaybackSuspended(false)
            } else {
                // Fallback on earlier versions
            }
            
            self.webView.load(request)
            allApiObject.capturePosthog(event: "play-youtube-video-in-activity", metadata: [:])
            
            if Reachability.isConnectedToNetwork() == false {
                allApiObject.isInternetOn(completionHandler: {isInternetOn in
                    DispatchQueue.main.async {
                        if !isInternetOn{//
                            if self.isVideoLoding{
                                self.isVideoLoding = false
                            }
                        }
                    }
                    
                })
            }
            isVideoLoding = true
        }else{
            isVideoLoding = false
            self.webView.isHidden = true
        }
    }
    
    func checkInstructionsState(text_instructions:String, imgUrls:[String]){
        arrImgUrls.removeAll()
        images.removeAll()
        if !text_instructions.isEmpty || imgUrls.count != 0{
            if !text_instructions.isEmpty{
                textViewInstructions.enclosingScrollView?.isHidden = false
                textViewInstructions.string = text_instructions
            }else{
                textViewInstructions.enclosingScrollView?.isHidden = true
            }
            if imgUrls.count != 0{
                arrImgUrls = imgUrls
                
                if !imgUrls.isEmpty {
                    loadImages(urls: imgUrls)
                }
            }else{
                collectionViewImges.enclosingScrollView?.isHidden = true
            }
            
            btnTabInstructions.isHidden = false
            boxInstructions.isHidden = false
            if collectionViewImges.enclosingScrollView?.isHidden == false{
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        let containerWidth = self.stackViewCustomTab.frame.width
                        let itemCount: CGFloat = CGFloat(self.arrImgUrls.count)
                        let itemWidth: CGFloat = 140
                        let spacing: CGFloat = 10
                        let padding: CGFloat = 5
                        
                        let totalItemWidth = itemCount * itemWidth
                        let totalSpacing = max(itemCount - 1, 0) * spacing
                        
                        let itemsWidth:CGFloat = totalItemWidth + totalSpacing + padding
                        let availableWidth = containerWidth - 20
                        
                        self.boxHabitImagesWidth.constant = itemsWidth < availableWidth ? itemsWidth : containerWidth
                    }
                }

            }
            
            tabCount += 1
        }else{
            btnTabInstructions.isHidden = true
            boxInstructions.isHidden = true
        }
    }
    
    

    func loadImages(urls: [String]) {
        images = Array(repeating: nil, count: urls.count)

        let group = DispatchGroup()

        for (index, urlString) in urls.enumerated() {
            guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
                continue
            }

            group.enter()

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }

                guard let data,
                      let image = NSImage(data: data) else {
                    return
                }

                self?.images[index] = image
            }.resume()
        }

        group.notify(queue: .main) { [weak self] in
            self?.collectionViewImges.enclosingScrollView?.isHidden = false
            self?.collectionViewImges.reloadData()
        }
    }
    
    func checkListState(list:[String]){
        arrCheckList.removeAll()
        if list.count != 0{
            for item in list{
                arrCheckList.append(["title": item, "state": false])
            }
            tblViewCheckList.reloadData()
            btnTabCheckList.isHidden = false
            boxCheckList.isHidden = false
            tabCount += 1
        }else{
            btnTabCheckList.isHidden = true
            boxCheckList.isHidden = true
        }
    }
    
    func checkTutorialState(id:String){
        if !id.isEmpty{
            let url = "http://dashboard.focusbear.io/webview/course?course_id=\(id)&bust_cache=\(getUuid())"
            let link = URL(string:url)!
            let request = URLRequest(url: link)
            self.webViewTutorial.load(request)
            btnTutorial.isHidden = false
            boxTutorial.isHidden = false
            tabCount += 1
        }else{
            btnTutorial.isHidden = true
            boxTutorial.isHidden = true
        }
    }
    
    func checkActivityExtraAllowedAppsAndUrls(allowedFocusMode:String, duration:Int, habitId:String){
        isAnyAllowedFocusModeActivityRunning = false
        isAnyAllowedFocusModeActivityWasRunningInLastActivity = false
        if habitPlayingBeforeMacSleepId != habitId{////Focus alignment score drops to 0% after resuming from sleep #1321
            refreshFocusModeData()
        }
        habitPlayingBeforeMacSleepId = ""
        
        if !allowedFocusMode.isEmpty{
            let filterArr = arrFocusType.filter { $0["id"] as? String == allowedFocusMode}
            if filterArr.count != 0{ //if activity has focus mode and and any focus mode is running then silently terminate focus mode
                isAnyAllowedFocusModeActivityRunning = true
                isAnyAllowedFocusModeActivityWasRunningInLastActivity = true
                if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                    customBlockingScheduleManagerObj.customBlockingScheduleFinished()
                }
                currentRunningAppNameForAi = ""
                currentBrowserUrlForAi = ""
                dictionaryAllowedUrlsWithIntentionInCuddlyModeCurrentFocus.removeAll()
                arrConvinceAiUrlsInCurrentFocus.removeAll()
                arrConvinceAiAppsInCurrentFocus.removeAll()
                lastEntryInProductivityStatsTime = Date()
                tabMatricsObject.last30SecondsDurationRecordedStartTime = Date()
                tabMatricsObject.resetAll()
                getTotalFocuedTime()
                startFocusModeTime = Date()
                stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
                if let dic = filterArr.first{
                    currentRunningFocusType = dic
                    let lastIntentionUsed = dic["lastIntentionUsed"] as? String ?? ""
                    addLog(text:"Task For Focus Mode :- \(lastIntentionUsed)")
                    whatToAchieveInFocusBlock = lastIntentionUsed
                    appdelegate!.statusbutton?.imagePosition = .imageLeft
                    appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString: dic["color"] as? String ?? "")
                    appdelegate!.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    
                    if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                        focusModeTaskString = dic["lastTaskUsed"] as? String ?? ""
                        taskCreatedByBlockPopup = ""
                        var minutes = 1
                        if duration > 60{
                            minutes = duration / 60
                        }
                        shouldReloadTaskPlayer = true
                        showTaskPlayerWindow(totalDuration: minutes, intention: whatToAchieveInFocusBlock, automatically:true)
                        if leftMenuVcObj != nil{
                            leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
                        }
                    }else{
                        focusModeTaskString = ""
                        taskCreatedByBlockPopup = ""
                    }
                }
                
                if SettingsManagerObject.isCuddlyModeEnabled{
                    addLog(text: "focus mode is strict mode")
                    currentFocusModeStrictness = ._STRICT_
                }else{
                    addLog(text: "focus mode is super strict mode")
                    currentFocusModeStrictness = ._SUPER_STRICT_
                }
                
                endFocusModeTime = nil
            }
        }
       
    }
    
    var videoUrlsArray = [String]()
    var currentActivityIdForVideo = ""
    func getRandomVideoUrl(activityId:String, urlsArray: [String])->String?{
        currentActivityIdForVideo = activityId
        self.videoUrlsArray = urlsArray
        if urlsArray.count == 0{
            return nil
        }else{
            var lastVideoIndex = -1
            var  lastSavedVideosDic = [String : Int]()
            if let savedVideosDic = UserDefaults.standard.object(forKey: "lastSavedVideosDic") as? [String:Int]{
                lastSavedVideosDic = savedVideosDic
                if let val = lastSavedVideosDic[activityId]{
                    lastVideoIndex = val
                }
            }

            if lastVideoIndex == -1 || urlsArray.count == 1{
                lastVideoIndex = 0
                lastSavedVideosDic[activityId] = lastVideoIndex
                UserDefaults.standard.set(lastSavedVideosDic, forKey: "lastSavedVideosDic")
                return urlsArray[lastVideoIndex]
            }
            
            lastVideoIndex += 1
            
            if urlsArray.count <= lastVideoIndex{
                lastVideoIndex = 0
            }
            
            let newVideoUrl = urlsArray[lastVideoIndex]
            
            lastSavedVideosDic[activityId] = lastVideoIndex
            UserDefaults.standard.set(lastSavedVideosDic, forKey: "lastSavedVideosDic")
            
            return newVideoUrl;
        }
    }
    
    var tabCount = 0
    func tryStartTimerHabit(durationSeconds:Int, name:String,currentHabit: habit, currentTimerValue:Int, shouldUpdateDeviceButton:Bool = true) {
        if askIntentionAllowedFocusModeActivityObj != nil{
            if askIntentionAllowedFocusModeActivityObj?.presentingViewController == self{
                askIntentionAllowedFocusModeActivityObj?.dismiss(lateMorningHabitPopupVcObj)
            }
        }
        var isFocusModeActivity = false
        if let focusModeId = currentHabit.allowedFocusMode{
            if !focusModeId.isEmpty && currentTimerValue == 0{
                let filterArr = arrFocusType.filter { $0["id"] as? String == focusModeId}
                if filterArr.count != 0{
                    if let dic = filterArr.first{
                        isFocusModeActivity = true
                        let lastIntentionUsed = dic["lastIntentionUsed"] as? String ?? ""
                        let name = dic["name"] as? String ?? ""
                        boxBg.isHidden = true
                        if self.view.window != nil{
                            allApiObject.capturePosthog(event: "ask-intention-allowed-focus-mode-activity-shown", metadata: [:])
                            self.presentAsSheet(getAskIntentionAllowedFocusModeActivityObject())
                            askIntentionAllowedFocusModeActivityObj?.resetData(focusMode: name, intention: lastIntentionUsed, durationSeconds:durationSeconds, name:name,currentHabit: currentHabit, currentTimerValue:currentTimerValue, shouldUpdateDeviceButton: shouldUpdateDeviceButton)
                        }
                        getTaskPlayerVcObject().loadView()
                        getTaskPlayerVcObject().loadRequest()
                    }
                }
            }else if !focusModeId.isEmpty{
                getTaskPlayerVcObject().loadView()
                getTaskPlayerVcObject().loadRequest()
            }
        }
        if !isFocusModeActivity{
            startTimerHabit(durationSeconds: durationSeconds, name: name, currentHabit: currentHabit, currentTimerValue: currentTimerValue, shouldUpdateDeviceButton: shouldUpdateDeviceButton)
        }
    }
    
    
    func startTimerHabit(durationSeconds:Int, name:String,currentHabit: habit, currentTimerValue:Int, shouldUpdateDeviceButton:Bool) {
        boxBg.isHidden = false
        let url = getRandomVideoUrl(activityId:currentHabit.id, urlsArray: currentHabit.urlsArray)
        addLog(text:"Current Activity id is :- \(currentHabit.id ?? "")")
        btnBackToHabits.isHidden = true
        if currentState != ._CUSTOM_ROUTINE_{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        }
        
        //focusButtonService---//
        if shouldUpdateDeviceButton{
            focusButtonServiceObject.startHabit(habitId: currentHabit.fakeIdForDevice)
        }
        //--------------//
        
        
        isAnyAllowedFocusModeActivityRunning = false
        isAllowedActivityHabitPlaying = false
        if !(getHabitsVcObject().isBreakActivityPostponeInsideAllowedHabit){
            getHabitsVcObject().stopActivityTimer()
        }
        if isFocusModeOnOrPaused(){
            addLog(text: "Activity start:- Focus Mode Finished")
            appdelegate?.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
        }
        isLastActivityStoppedInRunningState = false
        lastActivityRunningId = ""
        lastActivityStoppedTimerCount = 0
        lastActivityRunningId = currentHabit.id
        
        isActivityPaused = false
        self.btnPause.image = pauseIcon
        btnSkipHabit.isHidden = true
        graphOneMonthData = nil
        graphOneDayData = nil
        graphOneDayDataForQuantity = nil
        allApiObject.getACtivityStats(activityId: currentHabit.id, activityChoiceId: nil, completionHandler: {dic in
            
        })
        
        
        if !(activityCompletionVcObj?.isViewLoaded ?? false){
            activityCompletionVcObj?.loadView()
        }
        disableSystemSleep()
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit.allowedFocusMode, duration: durationSeconds, habitId:currentHabit.id)
        
        var currentTimerValue = currentTimerValue
        
        if currentTimerValue == 0{
            if let val = getCurrentHabitCurrentDurationDone(id: currentHabit.id){
                currentTimerValue = val
                if currentTimerValue > durationSeconds{
                    currentTimerValue = 0
                }
            }
        }
        
        var shouldLaunchAppAndUrl = true
        if currentTimerValue == 0{
            shouldLaunchAppAndUrl = true
        }else{
            shouldLaunchAppAndUrl = false
        }
        
        currentRelaxHabitPlaying = nil
        if currentHabit.showSavedDistractingWebsites{
            currentRelaxHabitPlaying = currentHabit
            showRelaxModeWindow(durationSeconds: durationSeconds, currentTimerValue: currentTimerValue)

            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
        }else if currentHabit.openSpecificApps{
            currentHabitPlaying = currentHabit
            if currentHabit.useTimer{
                showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
            }else{
                showcompletionRequirementsWindow(title: currentHabit.completion_requirements)
            }

            mainWindowControllerObj?.window?.close()
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
            hideBlankWindowInSecondaryMonitor()
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                currentHabitPlaying = currentHabit
                if currentHabit.useTimer{
                    showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
                }else{
                    showcompletionRequirementsWindow(title: currentHabit.completion_requirements)
                }
               //
                if !SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                    mainWindowControllerObj?.window?.close()
                }

                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
                hideBlankWindowInSecondaryMonitor()
                
                if shouldLaunchAppAndUrl{
                    let endTime = Calendar.current.date(bySetting: .second, value: durationSeconds, of: Date())
                    focusModeTaskString = ""
                    taskCreatedByBlockPopup = ""
                    allApiObject.startFocusMode(id: currentRunningFocusType["id"] as? String ?? "", intention: whatToAchieveInFocusBlock, start_time: Date(), finish_time: endTime ?? Date(), completionHandler: {newDic in
                        DispatchQueue.main.async {
                            
                        }
                    })
                }
            }else{
                 currentHabitPlaying = nil
            }
        }
        // Allowed-activity habits get the Habit Player | Day Plan tabs; normal habits hide them.
        // The flag drives the postpone-free minimise (covers allow-URLs habits, where the
        // currentHabitPlaying / focus-mode signals aren't set).
        isAllowedActivityHabitPlaying = currentHabit.isAllowedActivityHabit
        updateAllowedActivityScheduleTab(for: currentHabit)
        // Seed the to-do player with any Day Plan tasks assigned to this habit. Deferred so the player
        // has begun loading; the injection JS itself waits for the player to be ready. No-op if none.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            prepopulateDayPlanTasks(for: currentHabit)
        }
        boxButtonTabViews.isHidden = true
        tabCount = 0
        if currentHabitPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }else{
            isVideoLodded = false
            btnTabVideo.isHidden = true
            self.webView.isHidden = true
        }
        if currentHabit.take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            boxTakeNotes.isHidden = false
            tabCount += 1
            if shouldLaunchAppAndUrl{
                textViewNotes.string = ""
                if currentState == ._CUSTOM_ROUTINE_{
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
                }else{
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
                }
            }else{
                if currentState == ._CUSTOM_ROUTINE_{
                    textViewNotes.string = UserDefaults.standard.object(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes) as? String ?? ""
                }else{
                    textViewNotes.string = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
                }
            }
            btnTabNotes.isHidden = false
            self.view.window?.makeFirstResponder(textViewNotes)
        }else{
            if currentState == ._CUSTOM_ROUTINE_{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
            }else{
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            }
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
            btnTabNotes.isHidden = true
        }
        
      
        checkInstructionsState(text_instructions: currentHabit.text_instructions, imgUrls: currentHabit.imgUrls)
        
        checkListState(list: currentHabit.checkList)
        
        checkTutorialState(id: currentHabit.tutorial)
        
        if tabCount > 1{
            boxButtonTabViews.isHidden = false
            if btnTabVideo.isHidden == false{
                btnTabVideoClicked(self)
            }else if btnTabInstructions.isHidden == false{
                btnTabInstructionsClicked(self)
            }else if btnTabNotes.isHidden == false{
                btnTabNotesClicked(self)
            }else if btnTabCheckList.isHidden == false{
                btnTabCheckListClicked(self)
            }else if btnTutorial.isHidden == false{
                btnTabTutorialClicked(self)
            }
        }

        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        lastActivityPerformedTime = Date()
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//arrFilteredMorningHabits[currentHabitIndex].name!)
      
        startTimerValue = currentTimerValue
        currentTimer = currentTimerValue
        totalDuration = durationSeconds//durationInMinutes*60
        
        //focusButtonService---//
        if currentTimerValue != 0{
            focusButtonServiceObject.updateHabitDuration(seconds: self.totalDuration-currentTimer)
        }
        //--------------//
        
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }

        setCountDownTimer()
        
        if currentHabit.useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: currentHabit.completion_requirements)
        }
        writeStringToHabitInfo(isFinishTime: false, activityName: name)
        
    }
    
    var lastCurrentSpecialHabit:habit?
    var lastCurrentSpecialActivity:breakActivity?
    var lastCurrentSpecialActivityChoice:activityChoice?
    var lastCurrentSpecialActivityDuration = 0
    func startSpecialActivity(durationSeconds:Int,currentHabit: habit?, currentActivity: breakActivity?, currentChoice:activityChoice?) {
        
        btnBackToHabits.isHidden = true
        lastCurrentSpecialHabit = currentHabit
        lastCurrentSpecialActivity = currentActivity
        lastCurrentSpecialActivityChoice = currentChoice
        lastCurrentSpecialActivityDuration = durationSeconds
        var activityId = ""
        var urlsArray:[String] = []
        var openSpecificApps = false
        var take_notes = ""
        var name = ""
        if currentHabit != nil{
            activityId = currentHabit?.id ?? ""
            urlsArray = currentHabit?.urlsArray ?? []
            openSpecificApps = currentHabit!.openSpecificApps
            take_notes = currentHabit!.take_notes
            name = currentHabit!.name
        }else{
            activityId = currentActivity?.id ?? ""
            
            openSpecificApps = currentActivity!.openSpecificApps
            take_notes = currentActivity!.take_notes
            
            
            if currentChoice != nil{
                urlsArray = currentChoice?.urlsArray ?? []
                name = currentChoice!.name
            }else{
                urlsArray = currentActivity?.urlsArray ?? []
                name = currentActivity!.name
            }
        }

        addLog(text:"Special Activity id is :- \(activityId)")
        let url = getRandomVideoUrl(activityId:activityId, urlsArray: urlsArray)
        

        isAnyAllowedFocusModeActivityRunning = false

        isActivityPaused = false
        self.btnPause.image = pauseIcon
        btnSkipHabit.isHidden = true
        graphOneMonthData = nil
        graphOneDayData = nil
        graphOneDayDataForQuantity = nil
        if currentActivity != nil{
            allApiObject.getACtivityCurrentDayStats(activityId: activityId, activityChoiceId: currentChoice?.id, completionHandler: {dic in
                
            })
        }
        allApiObject.getACtivityStats(activityId: activityId, activityChoiceId: currentChoice?.id, completionHandler: {dic in
            
        })
        
        if !(activityCompletionVcObj?.isViewLoaded ?? false){
            activityCompletionVcObj?.loadView()
        }
        disableSystemSleep()
        
        
        let useTimer = true//
        //let completion_requirements = ""
        if currentHabit != nil{
//            useTimer = currentHabit!.useTimer
//            completion_requirements = currentHabit!.completion_requirements
            checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit!.allowedFocusMode, duration: durationSeconds, habitId:currentHabit?.id ?? "")
        }else if currentActivity != nil{
//            useTimer = currentActivity!.useTimer
//            completion_requirements = currentActivity!.completion_requirements
//            checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity!.allowedFocusMode, duration: durationSeconds)
        }

        
        
        currentHabitPlaying = nil
        currentActivityPlaying = nil
        if openSpecificApps{
            if currentHabit != nil{
                currentHabitPlaying = currentHabit
            }else{
                currentActivityPlaying = currentActivity
            }
            if useTimer{
                showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
            }
            mainWindowControllerObj?.window?.close()
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
            hideBlankWindowInSecondaryMonitor()
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                if currentHabit != nil{
                    currentHabitPlaying = currentHabit
                }else{
                    currentActivityPlaying = currentActivity
                }
                if useTimer{
                    showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
                }
                mainWindowControllerObj?.window?.close()
                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
                hideBlankWindowInSecondaryMonitor()
            }else{
                currentHabitPlaying = nil
                currentActivityPlaying = nil
            }
        }
        
        boxButtonTabViews.isHidden = true
        tabCount = 0
        
        if currentHabitPlaying == nil && currentActivityPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }else{
            isVideoLodded = false
            btnTabVideo.isHidden = true
        }
        if take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            textViewNotes.string = ""
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSpecaialActivitySavedNotes)
            btnTabNotes.isHidden = false
            boxTakeNotes.isHidden = false
            tabCount += 1
        }else{
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSpecaialActivitySavedNotes)
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
            btnTabNotes.isHidden = true
        }
        
        
        if currentHabit != nil{
            checkInstructionsState(text_instructions: currentHabit!.text_instructions, imgUrls: currentHabit!.imgUrls)
            checkListState(list: currentHabit!.checkList)
            checkTutorialState(id: currentHabit!.tutorial)
        }else if currentActivity != nil{
            checkInstructionsState(text_instructions: currentActivity!.text_instructions, imgUrls: currentActivity!.imgUrls)
            checkListState(list: currentActivity!.checkList)
        }
        if tabCount > 1{
            boxButtonTabViews.isHidden = false
            if btnTabVideo.isHidden == false{
                btnTabVideoClicked(self)
            }else if btnTabInstructions.isHidden == false{
                btnTabInstructionsClicked(self)
            }else if btnTabNotes.isHidden == false{
                btnTabNotesClicked(self)
            }else if btnTabCheckList.isHidden == false{
                btnTabCheckListClicked(self)
            }else if btnTutorial.isHidden == false{
                btnTabTutorialClicked(self)
            }
        }
        
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        lastActivityPerformedTime = Date()
        
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//arrFilteredMorningHabits[currentHabitIndex].name!)
        
        
        startTimerValue = 0
        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }

        setCountDownTimer()
        
        if useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
//            lblCompletionRequirements.stringValue = completion_requirements
//            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: completion_requirements)
        }
        
        writeStringToHabitInfo(isFinishTime: false, activityName: name)
    }
    
    @objc func hideBearAnimation(){
        resetConstraintsForVideoAndGif(kIsReducedMotion: true)
    }
    
    func resumeTimerHabit(durationSeconds:Int, url:String?, name:String, useTimer:Bool){
   // allowing postpone from timer window issue #213  date- 5/9/22
        if isSmallCountDownTimerViewVisible(){
            if !(smallCountDownVcObj?.isFocusBreak ?? false){
                if currentHabitPlaying != nil{
                    if currentHabitPlaying!.openSpecificApps{
                        currentHabitPlaying = currentHabitPlaying!
                        mainWindowControllerObj?.window?.close()
                        appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                        hideBlankWindowInSecondaryMonitor()
                        if currentHabitPlaying!.useTimer{
                            smallCountDownVcObj?.resumeTimerHabit(durationSeconds: durationSeconds)
                        }
                    }else{
                        if isAnyAllowedFocusModeActivityRunning{//activityAllowedFocusApps.count != 0{
                            currentHabitPlaying = currentHabitPlaying!
                            mainWindowControllerObj?.window?.close()
                            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                            hideBlankWindowInSecondaryMonitor()
                            if currentHabitPlaying!.useTimer{
                                smallCountDownVcObj?.resumeTimerHabit(durationSeconds: durationSeconds)
                            }
                        }else{
                            currentHabitPlaying = nil
                        }
                    }
                }
                
            }
        }
        disableSystemSleep()
        btnSkipHabit.isHidden = true
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(arrFilteredMorningHabits[currentHabitIndex].name!)."
        btnBackToHabits.isHidden = true
        if useTimer{
            totalDuration = durationSeconds//durationInMinutes*60
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
            
            var hour = "\(h)"
            var minute = "\(m)"
            var second = "\(s)"
            
            if hour.count == 1{
                hour = "0\(h)"
            }
            
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
        }
        if !isActivityPaused{
            if url != nil{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            
            setCountDownTimer()
            
            //focusButtonService---//
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                focusButtonServiceObject.resumeHabit()
            }
            //--------------//
        }else{
            if url != nil{
                if #available(macOS 12.0, *) {
                    
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            menuItemChooseHabit.isHidden = true
            menuItemChooseVideo.isHidden = true
            btnSkipHabit.isHidden = false
            
            if currentState == ._MORNING_HABIT_{
                if currentHabitIndex == arrFilteredMorningHabits.count - 1{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit")
                }else{
                    menuItemChooseHabit.isHidden = false
                    addLog(text:"Show menu Item Select Another Habit")
                }
                if !SettingsManagerObject.isOutOfOrderHabitsAllowed{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit:- Reason: Out Of Order Habits are not Allowed")
                }
            }else if currentState == ._EVENING_HABIT_{
                if currentHabitIndex == arrFilteredEveningHabits.count - 1{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit:- Reason: last habit")
                }else{
                    if isHighPrioritySequenceGoing{
                        var isAnyHighPriorityHabitRemaining = false
                        for i in currentHabitIndex + 1..<arrFilteredEveningHabits.count{
                            if arrFilteredEveningHabits[i].isPriorityHigh{
                                
                                if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                    let currentDate = Date()
                                    if currentDate > cutOffDate{
                                        continue;
                                    }
                                }
                                
                                
                                isAnyHighPriorityHabitRemaining = true
                                break;
                            }
                        }
                        if isAnyHighPriorityHabitRemaining{
                            menuItemChooseHabit.isHidden = false
                            addLog(text:"Show menu Item Select Another Habit:- Reason: High Priority Habit Remaining")
                        }else{
                            menuItemChooseHabit.isHidden = true
                            addLog(text:"Hide menu Item Select Another Habit:- Reason: No High Priority Habit Remaining")
                        }
                    }else{
                        menuItemChooseHabit.isHidden = false
                        addLog(text:"Show menu Item Select Another Habit")
                    }
                }
                if !SettingsManagerObject.isOutOfOrderHabitsAllowed{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit:- Reason: Out Of Order Habits are not Allowed")
                }
            }else if currentState == ._CUSTOM_ROUTINE_{
                let arrHabits = arrAllCustomRoutine[currentRoutineIndex].arrAllFilteredHabits
                if currentHabitIndex == arrHabits.count - 1{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit")
                }else{
                    menuItemChooseHabit.isHidden = false
                    addLog(text:"Show menu Item Select Another Habit")
                }
                if !SettingsManagerObject.isOutOfOrderHabitsAllowed{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit:- Reason: Out Of Order Habits are not Allowed")
                }
            }
            if currentState != ._BREATHING_{
                if videoUrlsArray.count > 1{
                    menuItemChooseVideo.isHidden = false
                }
            }
        }
        
    }
    
    
    
    func startTimerActivity(durationInSeconds:Int,name:String, urlsArray:[String], logQuantityQuestion:[quantityQuestion],currentActivity: breakActivity, currentChoice:activityChoice?,logQuantity:Bool, logQuantityType:String) {
//        isLastActivityStoppedInRunningState = false
        //lastActivityRunningId = ""
        //lastActivityStoppedTimerCount = 0
        btnBackToHabits.isHidden = true
        var url: String?
        addLog(text:"Current Activity id is :- \(currentActivity.id ?? "")")
        if currentChoice == nil{
            url = getRandomVideoUrl(activityId:currentActivity.id, urlsArray: urlsArray)
        }else{
            addLog(text:"Current Activity id is :- \(currentChoice!.id ?? "")")
            url = getRandomVideoUrl(activityId:currentChoice!.id, urlsArray: urlsArray)
        }
        
        
        isAnyAllowedFocusModeActivityRunning = false
        btnSkipHabit.isHidden = true
        isActivityPaused = false
        self.btnPause.image = pauseIcon
        graphOneMonthData = nil
        graphOneDayData = nil
        graphOneDayDataForQuantity = nil
        
        allApiObject.getACtivityStats(activityId: currentActivity.id, activityChoiceId: currentChoice?.id, completionHandler: {dic in
        
        })
        
        if currentActivity.logQuantity{
            var questions_ids = [String]()
            for question in currentActivity.logQuantityQuestions{
                questions_ids.append(question.id)
            }
            allApiObject.getActivityCurrentDayQuestionsStats(activityId: currentActivity.id, activityChoiceId: nil, questions_ids: questions_ids, completionHandler: {dic in
                
            })
        }else{
            allApiObject.getACtivityCurrentDayStats(activityId: currentActivity.id, activityChoiceId: currentChoice?.id, completionHandler: {dic in
                
            })
        }
        
        
        if !(activityCompletionVcObj?.isViewLoaded ?? false){
            activityCompletionVcObj?.loadView()
        }
        

        
        disableSystemSleep()
        logActivityQuantity = logQuantity
//        activityPostponeCount = 0
        isAnyAllowedFocusModeActivityRunning = false
        isAnyAllowedFocusModeActivityWasRunningInLastActivity = false
//        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity.allowedFocusMode, duration: durationInSeconds)
        
        if currentActivity.openSpecificApps{
            currentActivityPlaying = currentActivity
            mainWindowControllerObj?.window?.close()
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
            hideBlankWindowInSecondaryMonitor()
            if currentActivity.useTimer{
                showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
            }
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                currentActivityPlaying = currentActivity
                mainWindowControllerObj?.window?.close()
                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: true)
                hideBlankWindowInSecondaryMonitor()
                if currentActivity.useTimer{
                    showSmallTimerWindow(durationSeconds: durationInSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:0)
                }
            }else{
                 currentActivityPlaying = nil
            }
        }
        boxButtonTabViews.isHidden = true
        tabCount = 0
        if currentActivityPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }else{
            isVideoLodded = false
            btnTabVideo.isHidden = true
        }
        if currentActivity.take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            textViewNotes.string = ""
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastActivitySavedNotes)
            boxTakeNotes.isHidden = false
            btnTabNotes.isHidden = false
            tabCount += 1
        }else{
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastActivitySavedNotes)
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
            btnTabNotes.isHidden = true
        }

            
        checkInstructionsState(text_instructions: currentActivity.text_instructions, imgUrls: currentActivity.imgUrls)
        checkListState(list: currentActivity.checkList)
        
        if tabCount > 1{
            boxButtonTabViews.isHidden = false
            if btnTabVideo.isHidden == false{
                btnTabVideoClicked(self)
            }else if btnTabInstructions.isHidden == false{
                btnTabInstructionsClicked(self)
            }else if btnTabNotes.isHidden == false{
                btnTabNotesClicked(self)
            }else if btnTabCheckList.isHidden == false{
                btnTabCheckListClicked(self)
            }
        }
        
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        self.logQuantityQuestions = logQuantityQuestion
        self.logQuantityType = logQuantityType
        currentActicityTitle = name
        currentDurationInSeconds = durationInSeconds
        currentUrl = url
        lastActivityPerformedTime = Date()
        currentActivityUseTimer = currentActivity.useTimer
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        
        
        
        
        currentTimer = 0
        startTimerValue = 0
        totalDuration = durationInSeconds
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }
        
        setCountDownTimer()
        
        if currentActivity.useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
//            lblCompletionRequirements.stringValue = currentActivity.completion_requirements
            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: currentActivity.completion_requirements)
        }
        

        writeStringToHabitInfo(isFinishTime: false, activityName: name)
    }
  
    func setCountDownTimer(){
        DispatchQueue.main.async {
            self.lblTimer.font = NSFont.monospacedDigitSystemFont(ofSize: self.lblTimer.font?.pointSize ?? 41, weight: .regular)
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    func resetConstraintsForVideoAndGif(kIsReducedMotion:Bool){
        if kIsReducedMotion{
            imgViewGif.image = nil
            self.timerHideBearAnimation?.invalidate()//need to do this
            self.timerHideBearAnimation = nil
        }else{
            imgViewGif.image = NSImage(named: newGifsNamesArray.randomElement() ?? "")
            imgViewGif.animates = true
            self.timerHideBearAnimation?.invalidate()
            self.timerHideBearAnimation = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.hideBearAnimation), userInfo: nil, repeats: false)
        }
        if kIsReducedMotion && tabCount > 0{
            titleTopSpace.constant = 50
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.75)
            if boxInstructions.isHidden == false{
                if  collectionViewImges.enclosingScrollView?.isHidden == false{
                    DispatchQueue.global().async {
                        sleep(1)
                        DispatchQueue.main.async {
                            let containerWidth = self.stackViewCustomTab.frame.width
                            let itemCount: CGFloat = CGFloat(self.arrImgUrls.count)
                            let itemWidth: CGFloat = 140
                            let spacing: CGFloat = 10
                            let padding: CGFloat = 5
                            let totalItemWidth = itemCount * itemWidth
                            let totalSpacing = max(itemCount - 1, 0) * spacing
                            
                            let itemsWidth = totalItemWidth + totalSpacing + padding
                            if itemsWidth < (containerWidth - 20){
                                self.boxHabitImagesWidth.constant = itemsWidth
                            }else{
                                self.boxHabitImagesWidth.constant = containerWidth
                            }
                        }
                    }
                }
            }
        }else{
            titleTopSpace.constant = 210
            boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
        }
    }
    
    func resumeTimerActivity(durationInSeconds:Int,name:String, url:String?, useTimer:Bool) {
        disableSystemSleep()
        btnSkipHabit.isHidden = true
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(name)."
        
        if useTimer{
            totalDuration = durationInSeconds
            let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
            
            var hour = "\(h)"
            var minute = "\(m)"
            var second = "\(s)"
            
            if hour.count == 1{
                hour = "0\(h)"
            }
            
            if minute.count == 1 {
                minute = "0\(m)"
            }
            if second.count == 1 {
                second = "0\(s)"
            }
            if h == 0{
                self.lblTimer.stringValue = "\(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
            }
        }
        btnBackToHabits.isHidden = true

        
        if !isActivityPaused{
            if url != nil{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            
            setCountDownTimer()
        }else{
            if url != nil{
                if #available(macOS 12.0, *) {
                    
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
        }
    }
    
    func startBreathing() {
        allApiObject.capturePosthog(event: "ongoing-onboarding-activity-shown", metadata: [:])
        btnSkipHabit.title = "Skip"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkipHabit.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkipHabit.title
        }
        btnBackToHabits.isHidden = true
        isActivityPaused = false
        btnSkipHabit.isHidden = false
        self.btnPause.image = pauseIcon
        loadWebViewTo(url: introActivity!.urlsArray.randomElement())
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        boxButtonTabViews.isHidden = true
        textViewNotes.string = ""
        textViewNotes.enclosingScrollView?.isHidden = true
        boxTakeNotes.isHidden = true
        btnTabNotes.isHidden = true
        
        boxInstructions.isHidden = true
        btnTabInstructions.isHidden = true
        
        boxCheckList.isHidden = true
        btnTabCheckList.isHidden = true
        boxTutorial.isHidden = true
        btnTutorial.isHidden = true
        lblTitle.stringValue = getDoSomeActivityText(activityName: introActivity!.name!)//"Do some \(introActivity!.name!)."
        currentTimer = 0
        totalDuration = introActivity!.durationSeconds!
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
        }

        setCountDownTimer()
        
        boxTimer.isHidden = false
        boxCompletionRequirements.isHidden = true
    }
    func loadBlankUrl(){
        if boxButtonTabViews.isHidden == false && isVideoLodded{
            btnTabVideoClicked(self)
        }
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    @objc func performTimerCount() {
        currentTimer += 1
        if isAnyAllowedFocusModeActivityRunning{
            addEntryInProductivityStatsCsv()
        }
        // Re-sync the Focus Button to the Mac's authoritative remaining time every 15s. The device
        // runs its own countdown and can drift; until now it was only told the duration once at
        // habit start, so any device drift accumulated over the whole habit (reported ~33s slow on a
        // 15-min habit). This keeps it aligned to within the re-sync window. No-op if not connected.
        // Only while a morning/evening habit is actually running — this timer also drives breaks,
        // focus mode and custom routines, where the habit-duration signal doesn't apply.
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentTimer % 15 == 0 {
            focusButtonServiceObject.updateHabitDuration(seconds: self.totalDuration - currentTimer)
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1{
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            if self.isVideoLoding{
                if self.currentTimer >= 5{
                    self.isVideoLoding = false
                }
            }else{
                if h == 0{
                    self.lblTimer.stringValue = "\(minute):\(second)"
                }else{
                    self.lblTimer.stringValue = "\(hour):\(minute):\(second)"
                }
            }
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            enableSystemSleep()
            if popUpCheckListWcObj != nil{
                if popUpCheckListWcObj?.window?.isVisible ?? false{
                    popUpCheckListWcObj?.window?.close()
                }
            }

            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.loadBlankUrl()
                    if currentState == ._BREATHING_{
                        getHabitsVcObject().breathingOver(isSKipped: false)
                    }else if currentState == ._MORNING_HABIT_ {
                        getHabitsVcObject().morningHabitOver()
                    }else if currentState == ._EVENING_HABIT_ {
                        getHabitsVcObject().eveningHabitOver()
                    }else if currentState == ._MICRO_BREAK_{
                        getHabitsVcObject().activityOver()
                    }else if currentState == ._SPECIAL_ACTIVITY_{
                        getHabitsVcObject().specialActivityOver()
                    }else if currentState == ._CUSTOM_ROUTINE_{
                        getHabitsVcObject().customRoutineHabitOver()
                    }
                }
            }
        }
    }
    
    
    @IBAction func btnPauseClicked(_ sender: Any) {
        if boxButtonTabViews.isHidden == false && isVideoLodded{
            btnTabVideoClicked(self)
        }

        for menu in arrStartCustomRoutineMenu{// remove all custom routine menu items
            moreActionsMenu.removeItem(menu)
        }
        arrStartCustomRoutineMenu.removeAll()
        
        if isActivityPaused{
            addLog(text:"[user-action]Ongoing activity:-btn Resume Clicked")
            isActivityPaused = false
            allApiObject.capturePosthog(event: "resume-activity", metadata: [:])
            
            //focusButtonService---//
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                focusButtonServiceObject.resumeHabit()
            }
            //--------------//
            btnBackToHabits.isHidden = true
            
            DispatchQueue.main.async {
                self.btnPause.image = self.pauseIcon
            }
            setCountDownTimer()
            if isVideoLodded{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                }
            }
            if currentState != ._BREATHING_{
                btnSkipHabit.isHidden = true
            }
            if currentHabitPlaying != nil{
                if boxTimer.isHidden == false{
                    showSmallTimerWindow(durationSeconds: totalDuration, msg: lblTitle.stringValue, isFocusBreak: false, currentTimerValue:currentTimer)
                }
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
            }else if currentRelaxHabitPlaying != nil{
                showRelaxModeWindow(durationSeconds: totalDuration, currentTimerValue: currentTimer)
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
            }
            
        }else{
            addLog(text:"[user-action]Ongoing activity:-btn Pause Clicked")
            self.btnPause.image = playIcon
            isActivityPaused = true
            allApiObject.capturePosthog(event: "pause-activity", metadata: [:])
            timer?.invalidate()
            
            //focusButtonService---//
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                focusButtonServiceObject.pauseHabit()
            }
            //--------------//
            
            
            if isVideoLodded{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(true)
                } else {
                    // Fallback on earlier versions
                }
            }
            btnSkipHabit.title = "Skip this habit for today"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
            }

            btnSkipHabit.isHidden = true
            menuItemChooseHabit.isHidden = true
            menuItemChooseVideo.isHidden = true
            
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
                btnSkipHabit.isHidden = false
                
                if currentState == ._MORNING_HABIT_{
                    if currentHabitIndex == arrFilteredMorningHabits.count - 1{
                        menuItemChooseHabit.isHidden = true
                        btnBackToHabits.isHidden = true
                        addLog(text:"Hide menu Item Select Another Habit")
                    }else{
                        menuItemChooseHabit.isHidden = false
                        btnBackToHabits.isHidden = false
                        addLog(text:"Show menu Item Select Another Habit")
                    }
                    saveCurrentHabitCurrentDurationDone(id: arrFilteredMorningHabits[currentHabitIndex].id, duration: currentTimer)
                    
                    enableMenuForStartCustomRoutine()
                    
                }else if currentState == ._EVENING_HABIT_{
                    if currentHabitIndex == arrFilteredEveningHabits.count - 1{
                        menuItemChooseHabit.isHidden = true
                        btnBackToHabits.isHidden = true
                        addLog(text:"Hide menu Item Select Another Habit:- Reason: last habit")
                    }else{
                        if isHighPrioritySequenceGoing{
                            var isAnyHighPriorityHabitRemaining = false
                            for i in currentHabitIndex + 1..<arrFilteredEveningHabits.count{
                                if arrFilteredEveningHabits[i].isPriorityHigh{
                                    if let cutOffTime = arrFilteredEveningHabits[i].cutOffTime{
                                        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                        let currentDate = Date()
                                        if currentDate > cutOffDate{
                                            continue;
                                        }
                                    }
                                    
                                    isAnyHighPriorityHabitRemaining = true
                                    break;
                                }
                            }
                            if isAnyHighPriorityHabitRemaining{
                                menuItemChooseHabit.isHidden = false
                                btnBackToHabits.isHidden = false
                                addLog(text:"Show menu Item Select Another Habit:- Reason: High Priority Habit Remaining")
                            }else{
                                menuItemChooseHabit.isHidden = true
                                btnBackToHabits.isHidden = true
                                addLog(text:"Hide menu Item Select Another Habit:- Reason: No High Priority Habit Remaining")
                            }
                        }else{
                            menuItemChooseHabit.isHidden = false
                            btnBackToHabits.isHidden = false
                            addLog(text:"Show menu Item Select Another Habit")
                        }
                        
                    }
                    saveCurrentHabitCurrentDurationDone(id: arrFilteredEveningHabits[currentHabitIndex].id, duration: currentTimer)
                    enableMenuForStartCustomRoutine()
                }else if currentState == ._CUSTOM_ROUTINE_{
                    if currentHabitIndex == arrAllCustomRoutine[currentHabitIndex].arrAllFilteredHabits.count - 1{
                        menuItemChooseHabit.isHidden = true
                        addLog(text:"Hide menu Item Select Another Habit")
                    }else{
                        menuItemChooseHabit.isHidden = false
                        addLog(text:"Show menu Item Select Another Habit")
                    }
                    btnBackToHabits.isHidden = true
                }
                
                if isVideoLodded{
                    if videoUrlsArray.count > 1{
                        menuItemChooseVideo.isHidden = false
                    }
                }
                btnSkipHabit.title = buttonMoreActionsText
                if !SettingsManagerObject.isOutOfOrderHabitsAllowed{
                    menuItemChooseHabit.isHidden = true
                    addLog(text:"Hide menu Item Select Another Habit:- Reason: Out Of Order Habits are not Allowed")
                }
            }else if currentState == ._BREATHING_{
                btnSkipHabit.isHidden = false
                menuItemChooseHabit.isHidden = true
                menuItemChooseVideo.isHidden = true
                btnSkipHabit.title = "Skip"
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    btnSkipHabit.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkipHabit.title
                }
                btnBackToHabits.isHidden = true
            }else if currentState == ._MICRO_BREAK_{
                btnSkipHabit.isHidden = false
                menuItemChooseHabit.isHidden = true
                menuItemChooseVideo.isHidden = true
                btnSkipHabit.title = buttonMoreActionsText
                btnBackToHabits.isHidden = true
            }
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                if currentHabitPlaying != nil{
                    closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                }
            }
        }
    }
    
    func enableMenuForStartCustomRoutine(){
        arrStartCustomRoutineMenu.removeAll()
        let arrCustomRoutine = getListCustomRoutineTime()
        if arrCustomRoutine.count != 0{
            var menuItemCustomRoutineText = "Change to another routine - <ROUTINE>"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                menuItemCustomRoutineText = activityInfo.value(forKey: "menuItemCustomRoutineText") as? String ?? menuItemCustomRoutineText
            }
            
            for routine in arrCustomRoutine{
                let menuItemCustomRoutineTitle = menuItemCustomRoutineText.replacingOccurrences(of: "<ROUTINE>", with: routine.title)
                let menuItemCustomRoutine = NSMenuItem(title: menuItemCustomRoutineTitle, action: #selector(menuItemStartCustomRoutineClicked), keyEquivalent: "")
                menuItemCustomRoutine.target = self
                menuItemCustomRoutine.identifier = NSUserInterfaceItemIdentifier(routine.sequenceId)
                moreActionsMenu.addItem(menuItemCustomRoutine)
                arrStartCustomRoutineMenu.append(menuItemCustomRoutine)
            }
        }
    }
    
    @IBAction func btnIAmDoneClicked(_ sender: Any) {
        addLog(text:"[user-action]ongoing activity:-btnIAmDoneClicked")
        self.timer?.invalidate()
        enableSystemSleep()
        if popUpCheckListWcObj != nil{
            if popUpCheckListWcObj?.window?.isVisible ?? false{
                popUpCheckListWcObj?.window?.close()
            }
        }
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.loadBlankUrl()
                if currentState == ._BREATHING_{
                    getHabitsVcObject().breathingOver(isSKipped: false)
                }else if currentState == ._MORNING_HABIT_ {
                    getHabitsVcObject().morningHabitOver()
                }else if currentState == ._EVENING_HABIT_ {
                    getHabitsVcObject().eveningHabitOver()
                }else if currentState == ._MICRO_BREAK_{
                    getHabitsVcObject().activityOver()
                }else if currentState == ._SPECIAL_ACTIVITY_{
                    getHabitsVcObject().specialActivityOver()
                }else if currentState == ._CUSTOM_ROUTINE_{
                    getHabitsVcObject().customRoutineHabitOver()
                }
            }
        }
    }
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        if currentState == ._BREATHING_{
            if !isActivityPaused{
                btnPauseClicked(self)
            }
            getHabitsVcObject().breathingOver(isSKipped: true)
        }else{
            addLog(text:"Show more Actions menu")
            let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y - 8 )
            moreActionsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
        }
    }
    
    @objc func menuItemSkipHabitClicked(){
        getHabitsVcObject().showWhySkipHabitView()
    }
    
    @objc func menuItemChooseAnotherHabitClicked(){
        btnStartAnotherHabitClicked(self)
    }
    
    @objc func menuItemChooseAnotherVideoClicked(){
        btnChooseDifferentVideoClicked(self)
    }
    
    @objc func menuItemStartCustomRoutineClicked(menuItem:NSMenuItem){
        addLog(text:"[user-action]ongoing activity:-menuItemStartCustomRoutineClicked")
        if let id = menuItem.identifier?.rawValue{
            print(id)
            getHabitsVcObject().showLoaderView()
            isCustomRoutineTime(id: id) { isCustom,currentRoutineIndex,duration   in
                print(isCustom)
                getHabitsVcObject().hideLoaderView()
                if !isCustom{ // show alert
                    addLog(text:"Can't perform this routine right now")
                    let alert = NSAlert()
                    alert.setSharingType()
                    var canNotDoRoutine = "You can't perform this routine right now because either it's not the scheduled time or you've already completed it."
                    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                        canNotDoRoutine = activityInfo.value(forKey: "canNotDoCustomRoutineText") as? String ?? canNotDoRoutine
                    }
                    alert.messageText = canNotDoRoutine
                    alert.addButton(withTitle: buttonOkText)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
                    
        
                    self.moreActionsMenu.removeItem(menuItem)
                    for i in 0..<self.arrStartCustomRoutineMenu.count{
                        let menuItemStartCustomRoutine = self.arrStartCustomRoutineMenu[i]
                        if menuItemStartCustomRoutine == menuItem{
                            self.arrStartCustomRoutineMenu.remove(at: i)
                            break;
                        }
                    }
                    
                    
                }else{
                    isCustomRoutineWasRunningInPostponeMorningHabit = false
                    isCustomRoutineWasRunningInPostponeEveningHabit = false
                    let lastCurrentState = currentState
                    if currentState == ._MORNING_HABIT_{
                        addLog(text:"Perform custom routine- \(id) from morning routine")
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        getHabitsVcObject().postponeMorningHabitFor(minutes: 0, secondsToPostpone: duration, showAskFocusModeView: false, showAskIntention: false)
                        isCustomRoutineWasRunningInPostponeMorningHabit = true
                    }else if currentState == ._EVENING_HABIT_{
                        addLog(text:"Perform custom routine- \(id) from evening routine")
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        getHabitsVcObject().postponeEveningHabitFor(minutes: 0, secondsToPostpone: duration, showAskFocusModeView: false, showAskIntention: false)
                        isCustomRoutineWasRunningInPostponeEveningHabit = true
                    }
                    currentState = ._CUSTOM_ROUTINE_
                    startCustomRoutine(index: currentRoutineIndex, isOnDemand:false)
                    
                    if lastCurrentState == ._MORNING_HABIT_{
                        isCustomRoutineWasRunningBetweenMorningHabit = true
                    }else if lastCurrentState == ._EVENING_HABIT_{
                        isCustomRoutineWasRunningBetweenEveningHabit = true
                    }
                }
            }
        }
    }
    
    
    @IBAction func btnChooseDifferentVideoClicked(_ sender: Any) {
        addLog(text:"btnChooseDifferentVideoClicked")
        if boxButtonTabViews.isHidden == false && isVideoLodded{
            btnTabVideoClicked(self)
        }
        
        if let url = getRandomVideoUrl(activityId:currentActivityIdForVideo, urlsArray: videoUrlsArray){
            changeVideoUrl(url: url)
        }
    }
    

    @IBAction func btnStartAnotherHabitClicked(_ sender: Any) {
        if self.view.window != nil{
            if startAnotherHabitVcObj == nil{
                startAnotherHabitVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startAnotherHabitVc")) as? startAnotherHabitVc
            }
            startAnotherHabitVcObj!.currentHabitIndex = currentHabitIndex
            self.presentAsSheet(startAnotherHabitVcObj!)
        }
    }
}

extension timerViewcontroller:NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textViewNotes{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastHabitSavedNotes)
            }else if currentState == ._MICRO_BREAK_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastActivitySavedNotes)
            }else if currentState == ._SPECIAL_ACTIVITY_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastSpecaialActivitySavedNotes)
            }else if currentState == ._CUSTOM_ROUTINE_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
            }
        }
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            adjustFontSizeToFit(textView:textView)
        }
    }
    
    func adjustFontSizeToFit(textView:NSTextView) {
        guard let textContainer = textView.textContainer else{
            return;
        }
        guard let layoutManager = textView.layoutManager else{
            return;
        }
        
        let textBounds = layoutManager.usedRect(for: textContainer)
        let availableSize = textView.bounds.size
        
        let scaleFactor = min(availableSize.width / textBounds.size.width, availableSize.height / textBounds.size.height)
        let currentFontSize = textView.font?.pointSize ?? 14
        
        var newFontSize = currentFontSize * scaleFactor
        if newFontSize > 30 {
            newFontSize = 30
        }
        let font = getRegularFont(size: newFontSize)
        
        textViewInstructions.font = font
        textViewNotes.font = font
    }
}
extension timerViewcontroller:NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionViewItemImage"), for: indexPath) as! collectionViewItemImage
        
        if indexPath.item < images.count {
            item.imgView.image = images[indexPath.item]
        }else{
            item.imgView.image = nil
        }
        
        return item
    }
    
    
}

extension timerViewcontroller:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrCheckList.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellOnboardingBlockedUrls"), owner: nil) as? tblCellOnboardingBlockedUrls {
            
            if row < arrCheckList.count{
                cell.btnCheckBox.title = arrCheckList[row]["title"] as? String ?? ""
                
                if let state = arrCheckList[row]["state"] as? Bool{
                    if state{
                        cell.btnCheckBox.state = .on
                    }else{
                        cell.btnCheckBox.state = .off
                    }
                }
                cell.btnCheckBox.target = self
                cell.btnCheckBox.tag = row
                cell.btnCheckBox.action = #selector(btnCheckBoxClicked(sender:))
            }
            return cell
        }
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
    
    @objc func btnCheckBoxClicked(sender:NSButton){
        if let state = arrCheckList[sender.tag]["state"] as? Bool{
            if state{
                arrCheckList[sender.tag]["state"] = false
            }else{
                arrCheckList[sender.tag]["state"] = true
            }
        }
        
        tblViewCheckList.reloadData()
    }
}

//bukN2P7WpwE
