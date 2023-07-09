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
    
    
  
    @IBOutlet weak var lblCompletionRequirements: NSTextField!
    @IBOutlet weak var boxCompletionRequirements: NSBox!
    @IBOutlet weak var btnIAmDone: Button!
    @IBOutlet weak var btnChooseDifferentVideo: underLineButton!
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
//    var btnPauseTitle = "Pause Activity"
//    var btnResumeTitle = "Resume Activity"
    let pauseIcon = NSImage(named: NSImage.touchBarPauseTemplateName)
    let playIcon = NSImage(named: NSImage.touchBarPlayTemplateName)
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tblViewCheckList.delegate = self
        tblViewCheckList.dataSource = self
        
        lblTitleCheckList.stringValue = "Check List"
        btnTabCheckList.title = "Check List"
        
        btnIAmDone.title = "I'm done"
        btnChooseDifferentVideo.title = "Choose a different video"
        btnTabVideo.title = "Video"
        btnTabNotes.title = "Notes"
        btnTabInstructions.title = "Instructions"
        lblTitleTakeNotes.stringValue = "Take Notes"
        
        
        textViewNotes.delegate = self
        btnSkipHabit.isHidden = true
        btnChooseDifferentVideo.isHidden = true
        self.webView.navigationDelegate = self
        boxTimerCenterY = boxTimerCenterY.setMultiplier(multiplier: 1.6)
        
        boxTimer.wantsLayer = true
        boxTimer.shadow = NSShadow()
        boxTimer.layer?.shadowOpacity = 0.3
        boxTimer.layer?.shadowColor = NSColor.black.cgColor
        boxTimer.layer?.shadowOffset = NSMakeSize(0, -2)
        boxTimer.layer?.shadowRadius = 5
        
//        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
//            btnPauseTitle = activityInfo.value(forKey: "buttonPauseText") as? String ?? btnPauseTitle
//            btnResumeTitle = activityInfo.value(forKey: "buttonResumeText") as? String ?? btnResumeTitle
//        }
        
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
            btnChooseDifferentVideo.title = activityInfo.value(forKey: "buttonChooseVideoText") as? String ?? btnChooseDifferentVideo.title
            btnIAmDone.title = activityInfo.value(forKey: "buttonActivityDoneText") as? String ?? btnIAmDone.title
            textCompletionRequirements = activityInfo.value(forKey: "completionRequirementsText") as? String ?? textCompletionRequirements
            lblTitleCheckList.stringValue = activityInfo.value(forKey: "titleCheckList") as? String ?? lblTitleCheckList.stringValue
            btnTabCheckList.title = activityInfo.value(forKey: "titleCheckList") as? String ?? btnTabCheckList.title
        }
        boxInstructions.isHidden = true
        btnTabInstructions.isHidden = true
        
        boxCheckList.isHidden = true
        btnTabCheckList.isHidden = true
    }
    override func viewWillAppear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
        btnSkipHabit.isHidden = true
        btnChooseDifferentVideo.isHidden = true
    }
    override func viewWillDisappear() {
        self.timerHideBearAnimation?.invalidate()
        self.timerHideBearAnimation = nil
    }
    @IBAction func btnTabInstructionsClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxCheckList.isHidden = true
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .on
        boxInstructions.isHidden = false
        btnTabCheckList.state = .off
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
        btnTabVideo.state = .off
        btnTabNotes.state = .on
        btnTabInstructions.state = .off
        boxInstructions.isHidden = true
        btnTabCheckList.state = .off
    }
    @IBAction func btnTabVideoClicked(_ sender: Any) {
        webView.isHidden = false
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = true
        btnTabVideo.state = .on
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .off
    }
    @IBAction func btnTabCheckListClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = false
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .on
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        if isVideoLoding{
            isVideoLoding = false
        }
        
        if isActivityPaused{
            DispatchQueue.global().async {
                sleep(1)
                DispatchQueue.main.async {
                    if self.isActivityPaused{
                        if #available(macOS 12.0, *) {
                            webView.setAllMediaPlaybackSuspended(true)
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }
        }
    }
    var isVideoLoding = false{
        didSet{
            if isVideoLoding{
                mainViewControllerObj?.btnAbort.isEnabled = false
                btnPause.isEnabled = false
            }else{
                mainViewControllerObj?.btnAbort.isEnabled = true
                btnPause.isEnabled = true
                currentTimer = startTimerValue
                startTimerValue = 0
            }
        }
    }
    var isVideoLodded = false
    var arrImgUrls = [String]()
    var arrCheckList = [[String:Any]]()
    func changeVideoUrl(url:String){
        var videoUrl = url
        if videoUrl.lowercased().contains("watch?v="){
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
        }else{
            // doing this beacuse if video is embedded than it will not play
            if videoUrl.lowercased().contains("https://youtu.be/"){
                if let lastItem =  videoUrl.components(separatedBy: "/").last{
                    videoUrl = "https://www.youtube.com/embed/" + lastItem
                }
                
            }
        }
        if videoUrl.contains("?"){
            videoUrl = videoUrl + "&autoplay=1"
        }else{
            videoUrl = videoUrl + "?autoplay=1"
        }
        let link = URL(string:videoUrl)!
        let request = URLRequest(url: link)
        if #available(macOS 12.0, *) {
            self.webView.setAllMediaPlaybackSuspended(false)
        } else {
            // Fallback on earlier versions
        }
        self.webView.load(request)
        allApiObject.capturePosthog(event: "play-youtube-video-in-activity", metadata: [:])
    }
    func loadWebViewTo(url:String?){
        btnTabVideo.isHidden = true
        isVideoLodded = false
        if var videoUrl = url{
            self.webView.isHidden = false
            isVideoLodded = true
            tabCount += 1
            btnTabVideo.isHidden = false
            if videoUrl.lowercased().contains("watch?v="){
                videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
            }else{
                // doing this beacuse if video is embedded than it will not play
                if videoUrl.lowercased().contains("https://youtu.be/"){
                    if let lastItem =  videoUrl.components(separatedBy: "/").last{
                       videoUrl = "https://www.youtube.com/embed/" + lastItem
                    }
                    
                }
            }
            if videoUrl.contains("?"){
                videoUrl = videoUrl + "&autoplay=1"
            }else{
                videoUrl = videoUrl + "?autoplay=1"
            }
            let link = URL(string:videoUrl)!
            let request = URLRequest(url: link)
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
        if !text_instructions.isEmpty || imgUrls.count != 0{
            if !text_instructions.isEmpty{
                textViewInstructions.enclosingScrollView?.isHidden = false
                textViewInstructions.string = text_instructions
            }else{
                textViewInstructions.enclosingScrollView?.isHidden = true
            }
            if imgUrls.count != 0{
                arrImgUrls = imgUrls
                collectionViewImges.enclosingScrollView?.isHidden = false
                collectionViewImges.reloadData()
            }else{
                collectionViewImges.enclosingScrollView?.isHidden = true
            }
            
            btnTabInstructions.isHidden = false
            boxInstructions.isHidden = false
            if collectionViewImges.enclosingScrollView?.isHidden == false{
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        let containerWidth = self.stackViewCustomTab.frame.width
                        let itemsWidth:CGFloat = CGFloat((self.arrImgUrls.count * 140) + ((self.arrImgUrls.count - 1)*10) + 5)
                        if itemsWidth < (containerWidth - 20){
                            self.boxHabitImagesWidth.constant = itemsWidth
                        }else{
                            self.boxHabitImagesWidth.constant = containerWidth
                        }
                    }
                }

            }
            
            tabCount += 1
        }else{
            btnTabInstructions.isHidden = true
            boxInstructions.isHidden = true
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
    
    
    func  checkActivityExtraAllowedAppsAndUrls(allowedFocusMode:String){
        isAnyAllowedFocusModeActivityRunning = false
        isAnyAllowedFocusModeActivityWasRunningInLastActivity = false
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        if !allowedFocusMode.isEmpty{
            let filterArr = arrFocusType.filter { $0["id"] as? String == allowedFocusMode}
            if filterArr.count != 0{ //if activity has focus mode and and any focus mode is running then silently terminate focus mode
                isAnyAllowedFocusModeActivityRunning = true
                isAnyAllowedFocusModeActivityWasRunningInLastActivity = true
                whatToAchieveInFocusBlock = ""
                if let dic = filterArr.first{
                    currentRunningFocusType = dic

                }
                
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
    func startTimerHabit(durationSeconds:Int, name:String,currentHabit: habit, currentTimerValue:Int) {
        
        let url = getRandomVideoUrl(activityId:currentHabit.id, urlsArray: currentHabit.urlsArray)
        addLog(text:"Current Activity id is :- \(currentHabit.id ?? "")")
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitsStartedDate)
        isAnyAllowedFocusModeActivityRunning = false
        if !(mainViewControllerObj?.isBreakActivityPostponeInsideAllowedHabit ?? false){
            mainViewControllerObj?.stopActivityTimer()
        }
        if isFocusModeOnOrPaused(){
            addLog(text: "Activity start:- Focus Mode Finished")
            appdelegate?.focusModeFinished(isSilent: true, isShutOffTime: false)
        }
        isLastActivityStoppedInRunningState = false
        lastActivityRunningId = ""
        lastActivityStoppedTimerCount = 0
        lastActivityRunningId = currentHabit.id
        
        isActivityPaused = false
        self.btnPause.image = pauseIcon
        btnSkipHabit.isHidden = true
        btnChooseDifferentVideo.isHidden = true
        graphOneMonthData = nil
        graphOneDayData = nil
        graphOneDayDataForQuantity = nil
        allApiObject.getACtivityStats(activityId: currentHabit.id, activityChoiceId: nil, completionHandler: {dic in
            
        })
        
        
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        disableSystemSleep()
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit.allowedFocusMode)
        
        
        
        var shouldLaunchAppAndUrl = true
        if currentTimerValue == 0{
            shouldLaunchAppAndUrl = true
        }else{
            shouldLaunchAppAndUrl = false
        }
        
        
        
        if currentHabit.openSpecificApps{
            currentHabitPlaying = currentHabit
            if currentHabit.useTimer{
                showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
            }
            mainWindowControllerObj?.window?.close()
            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
            hideBlankWindowInSecondaryMonitor()
        }else{
            if isAnyAllowedFocusModeActivityRunning{//if activityAllowedFocusApps.count != 0{
                currentHabitPlaying = currentHabit
                if currentHabit.useTimer{
                    showSmallTimerWindow(durationSeconds: durationSeconds, msg: getDoSomeActivityText(activityName: name), isFocusBreak: false, currentTimerValue:currentTimerValue)
                }
                mainWindowControllerObj?.window?.close()
                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: shouldLaunchAppAndUrl)
                hideBlankWindowInSecondaryMonitor()
                
                if shouldLaunchAppAndUrl{
                    let endTime = Calendar.current.date(bySetting: .second, value: durationSeconds, of: Date())
                    
                    allApiObject.startFocusMode(id: currentRunningFocusType["id"] as? String ?? "", intention: whatToAchieveInFocusBlock, start_time: Date(), finish_time: endTime ?? Date(), completionHandler: {newDic in
                        DispatchQueue.main.async {
                            
                        }
                    })
                }
            }else{
                 currentHabitPlaying = nil
            }
        }
        boxButtonTabViews.isHidden = true
        tabCount = 0
        if currentHabitPlaying == nil{// do not allow  video  if activity is allow app type
            loadWebViewTo(url: url)
        }else{
            isVideoLodded = false
            btnTabVideo.isHidden = true
        }
        if currentHabit.take_notes == DURING_ACTIVITY{//  har jgh ye block load video k niche rakho
            textViewNotes.enclosingScrollView?.isHidden = false
            boxTakeNotes.isHidden = false
            tabCount += 1
            if shouldLaunchAppAndUrl{
                textViewNotes.string = ""
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            }else{
                textViewNotes.string = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
            }
            btnTabNotes.isHidden = false
        }else{
            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
            textViewNotes.string = ""
            textViewNotes.enclosingScrollView?.isHidden = true
            boxTakeNotes.isHidden = true
            btnTabNotes.isHidden = true
        }
        
      
        checkInstructionsState(text_instructions: currentHabit.text_instructions, imgUrls: currentHabit.imgUrls)
        
        checkListState(list: currentHabit.checkList)
        
        
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
        
        lastActivityPerformedTime = Date()
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//arrFilteredMorningHabits[currentHabitIndex].name!)
      
        startTimerValue = currentTimerValue
        currentTimer = currentTimerValue
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        
        if currentHabit.useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: currentHabit.completion_requirements)
        }
        
        
        
    }
    
    
    var lastCurrentSpecialHabit:habit?
    var lastCurrentSpecialActivity:breakActivity?
    var lastCurrentSpecialActivityChoice:activityChoice?
    var lastCurrentSpecialActivityDuration = 0
    func startSpecialActivity(durationSeconds:Int,currentHabit: habit?, currentActivity: breakActivity?, currentChoice:activityChoice?) {
        
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
        btnChooseDifferentVideo.isHidden = true
        graphOneMonthData = nil
        graphOneDayData = nil
        graphOneDayDataForQuantity = nil
        if currentActivity != nil{
            allApiObject.getACtivityCurrentDayStats(activityId: activityId, activityChoiceId: currentChoice?.id, completionHandler: {dic in
                
            })
        }
        allApiObject.getACtivityStats(activityId: activityId, activityChoiceId: currentChoice?.id, completionHandler: {dic in
            
        })
        
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        disableSystemSleep()
        
        
        let useTimer = true//
        let completion_requirements = ""
        if currentHabit != nil{
//            useTimer = currentHabit!.useTimer
//            completion_requirements = currentHabit!.completion_requirements
            checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentHabit!.allowedFocusMode)
        }else if currentActivity != nil{
//            useTimer = currentActivity!.useTimer
//            completion_requirements = currentActivity!.completion_requirements
            checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity!.allowedFocusMode)
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        
        if useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
//            lblCompletionRequirements.stringValue = completion_requirements
//            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: completion_requirements)
        }
        
        
    }
    
    @objc func hideBearAnimation(){
        resetConstraintsForVideoAndGif(kIsReducedMotion: true)
    }
    
    func resumeTimerHabit(durationSeconds:Int, url:String?, name:String, useTimer:Bool){
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                    if currentHabitPlaying != nil{
                        if currentHabitPlaying!.openSpecificApps{
                            currentHabitPlaying = currentHabitPlaying!
                            mainWindowControllerObj?.window?.close()
                            appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                            hideBlankWindowInSecondaryMonitor()
                            if currentHabitPlaying!.useTimer{
                                getsmallCountDownVcObject().resumeTimerHabit(durationSeconds: durationSeconds)
                            }
                        }else{
                            if isAnyAllowedFocusModeActivityRunning{//activityAllowedFocusApps.count != 0{
                                currentHabitPlaying = currentHabitPlaying!
                                mainWindowControllerObj?.window?.close()
                                appdelegate?.startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl: false)
                                hideBlankWindowInSecondaryMonitor()
                                if currentHabitPlaying!.useTimer{
                                    getsmallCountDownVcObject().resumeTimerHabit(durationSeconds: durationSeconds)
                                }
                            }else{
                                 currentHabitPlaying = nil
                            }
                        }
                    }
                    
                }
            }
        }//!getsmallCountDownVcObject().isFocusBreak{
        disableSystemSleep()
        btnSkipHabit.isHidden = true
        btnChooseDifferentVideo.isHidden = true
        lblTitle.stringValue = getDoSomeActivityText(activityName: name)//"Do some \(arrFilteredMorningHabits[currentHabitIndex].name!)."
        
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
            
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
        }else{
            if url != nil{
                if #available(macOS 12.0, *) {
                    
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            btnSkipHabit.isHidden = false
            if currentState != ._BREATHING_{
                btnChooseDifferentVideo.isHidden = false
            }
        }
        
    }
    
    
    
    func startTimerActivity(durationInSeconds:Int,name:String, urlsArray:[String], logQuantityQuestion:[quantityQuestion],currentActivity: breakActivity, currentChoice:activityChoice?,logQuantity:Bool, logQuantityType:String) {
//        isLastActivityStoppedInRunningState = false
        //lastActivityRunningId = ""
        //lastActivityStoppedTimerCount = 0
        
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
        btnChooseDifferentVideo.isHidden = true
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
        
        
        if !(thirdVcObj?.isViewLoaded ?? false){
            thirdVcObj?.loadView()
        }
        

        
        disableSystemSleep()
        logActivityQuantity = logQuantity
//        activityPostponeCount = 0
        
        checkActivityExtraAllowedAppsAndUrls(allowedFocusMode: currentActivity.allowedFocusMode)
        
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
        
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        
        if currentActivity.useTimer{
            boxTimer.isHidden = false
            boxCompletionRequirements.isHidden = true
            
        }else{
            boxTimer.isHidden = true
            boxCompletionRequirements.isHidden = false
//            lblCompletionRequirements.stringValue = currentActivity.completion_requirements
            lblCompletionRequirements.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: currentActivity.completion_requirements)
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
                            let itemsWidth:CGFloat = CGFloat((self.arrImgUrls.count * 140) + ((self.arrImgUrls.count - 1)*10) + 5)
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
        btnChooseDifferentVideo.isHidden = true
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
        

        
        if !isActivityPaused{
            if url != nil{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                    loadWebViewTo(url: url)
                }
            }
            
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
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
        isActivityPaused = false
        btnSkipHabit.isHidden = true
        btnChooseDifferentVideo.isHidden = true
        self.btnPause.image = pauseIcon
        loadWebViewTo(url: introActivity!.urlsArray.randomElement())
        resetConstraintsForVideoAndGif(kIsReducedMotion: SettingsManagerObject.kIsReducedMotion)
        
        boxButtonTabViews.isHidden = true
        textViewNotes.string = ""
        textViewNotes.enclosingScrollView?.isHidden = true
        boxTakeNotes.isHidden = true
        
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

        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        
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
        currentTimer += 1//todo 1
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
                        mainViewControllerObj?.breathingOver(isSKipped: false)
                    }else if currentState == ._MORNING_HABIT_ {
                        mainViewControllerObj?.morningHabitOver()
                    }else if currentState == ._EVENING_HABIT_ {
                        mainViewControllerObj?.eveningHabitOver()
                    }else if currentState == ._ACTIVITY_{
                        mainViewControllerObj?.activityOver()
                    }else if currentState == ._SPECIAL_ACTIVITY_{
                        mainViewControllerObj?.specialActivityOver()
                    }
                }
            }
        }
    }
    var isActivityPaused = false
    @IBAction func btnPauseClicked(_ sender: Any) {
        if boxButtonTabViews.isHidden == false && isVideoLodded{
            btnTabVideoClicked(self)
        }
        
        if isActivityPaused{
            isActivityPaused = false
            allApiObject.capturePosthog(event: "resume-activity", metadata: [:])
            DispatchQueue.main.async {
                self.btnPause.image = self.pauseIcon
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
                RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            }
            if isVideoLodded{
                if #available(macOS 12.0, *) {
                    webView.setAllMediaPlaybackSuspended(false)
                } else {
                    // Fallback on earlier versions
                }
            }
            btnSkipHabit.isHidden = true
            btnChooseDifferentVideo.isHidden = true
            if currentHabitPlaying != nil{
                if boxTimer.isHidden == false{
                    showSmallTimerWindow(durationSeconds: totalDuration, msg: lblTitle.stringValue, isFocusBreak: false, currentTimerValue:currentTimer)
                }
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
            }
        }else{
            self.btnPause.image = playIcon
            isActivityPaused = true
            allApiObject.capturePosthog(event: "pause-activity", metadata: [:])
            timer?.invalidate()
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
            
            
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                btnSkipHabit.isHidden = false
                if isVideoLodded{
                    if videoUrlsArray.count > 1{
                        btnChooseDifferentVideo.isHidden = false
                    }
                }
                btnSkipHabit.title = "Skip this habit for today"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
                }
            }else if currentState == ._BREATHING_{
                btnSkipHabit.isHidden = false
                btnChooseDifferentVideo.isHidden = true
                btnSkipHabit.title = "Skip"
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    btnSkipHabit.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkipHabit.title
                }
            }else if currentState == ._ACTIVITY_{
                btnSkipHabit.isHidden = false
                btnChooseDifferentVideo.isHidden = true
                btnSkipHabit.title = "Skip this habit for today"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
                }
            }else{
                btnSkipHabit.isHidden = true
                btnChooseDifferentVideo.isHidden = true
            }
        }
        
    }
    
    @IBAction func btnIAmDoneClicked(_ sender: Any) {
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
                    mainViewControllerObj?.breathingOver(isSKipped: false)
                }else if currentState == ._MORNING_HABIT_ {
                    mainViewControllerObj?.morningHabitOver()
                }else if currentState == ._EVENING_HABIT_ {
                    mainViewControllerObj?.eveningHabitOver()
                }else if currentState == ._ACTIVITY_{
                    mainViewControllerObj?.activityOver()
                }else if currentState == ._SPECIAL_ACTIVITY_{
                    mainViewControllerObj?.specialActivityOver()
                }
            }
        }
    }
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        if currentState == ._BREATHING_{
            mainViewControllerObj?.breathingOver(isSKipped: true)
        }else{
            mainViewControllerObj?.showWhySkipHabitView()
        }
        
    }
    @IBAction func btnChooseDifferentVideoClicked(_ sender: Any) {
        if boxButtonTabViews.isHidden == false && isVideoLodded{
            btnTabVideoClicked(self)
        }
        
        if let url = getRandomVideoUrl(activityId:currentActivityIdForVideo, urlsArray: videoUrlsArray){
            changeVideoUrl(url: url)
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
            }else if currentState == ._ACTIVITY_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastActivitySavedNotes)
            }else if currentState == ._SPECIAL_ACTIVITY_{
                UserDefaults.standard.set(textViewNotes.string, forKey: kUserdefaultsLastSpecaialActivitySavedNotes)
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
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex]
        let font = NSFont(name: selectedFont.regularFontName, size: newFontSize)!
        
        textViewInstructions.font = font
        textViewNotes.font = font
    }
}
extension timerViewcontroller:NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return arrImgUrls.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionViewItemImage"), for: indexPath) as! collectionViewItemImage
        
        if indexPath.item < arrImgUrls.count{
            if let url = URL(string: arrImgUrls[indexPath.item]){
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        item.imgView.image = NSImage(contentsOf: url)
                    }
                }
                
            }else{
                item.imgView.image = nil
            }
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



