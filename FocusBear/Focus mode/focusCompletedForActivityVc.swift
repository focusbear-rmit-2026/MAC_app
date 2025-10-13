//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedForActivityVc: NSViewController {
    
    @IBOutlet weak var heightScrollView: NSLayoutConstraint!
    @IBOutlet weak var stackviewAchieve: NSStackView!
    @IBOutlet weak var stackViewStarRating: NSStackView!
    @IBOutlet weak var boxAverageTabCount: NSBox!
    @IBOutlet weak var boxAverageTimeSpent: NSBox!
    @IBOutlet weak var btnMoreOptions: cursorButton!
    @IBOutlet weak var imgViewAccordinMoreOptions: NSImageView!
    @IBOutlet weak var lblAccordinMoreOptions: NSTextField!
    @IBOutlet weak var boxAccordinMoreOptions: NSBox!
    @IBOutlet weak var stackViewTags: NSStackView!
    @IBOutlet weak var boxFocusAlignmentScore: NSBox!
    
    @IBOutlet weak var lblEnableAdvancedAnalyticsSetting: NSTextField!
    @IBOutlet weak var lblDeepWorkTimeToday: NSTextField!
    @IBOutlet weak var lblTitleTime: NSTextField!
    @IBOutlet weak var lblTitleAppOrSite: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblDeepFocusTime: NSTextField!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTime: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTimeToday: NSTextField!
    
    @IBOutlet weak var btnStarFirst: cursorButton!
    @IBOutlet weak var btnStarSecond: cursorButton!
    @IBOutlet weak var btnStarThird: cursorButton!
    @IBOutlet weak var btnStarFourth: cursorButton!
    @IBOutlet weak var btnStarFifth: cursorButton!
    
    @IBOutlet weak var lblTabCount: NSTextField!
    @IBOutlet weak var lblTitleTabCount: NSTextField!
    
    @IBOutlet weak var lblTitleFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleStats: NSTextField!
    
    @IBOutlet weak var boxTempForShowToolTip: NSBox!
    @IBOutlet weak var lblTitleTags: NSTextField!
    @IBOutlet weak var tokenFieldTags: NSTokenField!
    @IBOutlet weak var btnContinue: Button!
//    @IBOutlet weak var textFieldDistractions: NSTextField!
    @IBOutlet weak var textFieldAchieve: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    let kUserdefaultsShowTextForTokenFieldFirstTime = "kUserdefaultsShowTextForTokenFieldFirstTime"
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Take a 5 minute break"
    var currentFocusModeId = ""
    var finish_time:Date?
    var arrAllTags = [String]()
    var defaultTokenMenu = NSMenu()
    var currentFocusModeIndex = 0
    
    var arrAllAppsTabsData = [[String:Any]]()
    var allowExtend = false
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnMoreOptions.title = "More Stats"
        lblAccordinMoreOptions.stringValue = "Reflect on the session"
        lblTitleStats.stringValue = "Stats"
        lblTitleFocusAlignmentScore.stringValue = "Focus Alignment Score"
        lblTitleDeepWorkTime.stringValue = "Deep work time this session"
        lblTitleDeepWorkTimeToday.stringValue = "Total deep work time today"
        lblTitleAverageTimeSpentPerTab.stringValue = "Average Time Spent per Tab/App"
        lblTitleTabCount.stringValue = "Average tab count"
        lblTitleAppOrSite.stringValue = "App or site"
        lblTitleTime.stringValue = "Time"
        lblEnableAdvancedAnalyticsSetting.stringValue = "Enable the Advanced analytics setting to view detailed data about app and browser tab usage during focus mode. You can turn this on in Preferences > Settings > Advanced > Privacy (Geek mode required)."
        
        
        tokenFieldTags.delegate = self
        lblTitleTags.stringValue = "Reporting Tags" 
        btnContinue.title = "Continue"
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this time?"
        lblQuestionSecond.stringValue = "How focused were you?"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let title = focusCompletedInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = focusCompletedInfo.value(forKey: "subTitle") as? String{
                    subTitleText = subTitle
                }
                if let questionFirstText = focusCompletedInfo.value(forKey: "questionFirstText") as? String{
                    lblQuestionFirst.stringValue = questionFirstText
                }
                if let titleStarRatingText = focusCompletedInfo.value(forKey: "titleStarRatingText") as? String{
                    lblQuestionSecond.stringValue = titleStarRatingText
                }
                if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonTakeBreakText") as? String{
                    self.buttonTakeBreakText = buttonTakeBreakText
                }
                lblTitleTags.stringValue = focusCompletedInfo.value(forKey: "titleTags") as? String ?? lblTitleTags.stringValue
                
                lblTitleStats.stringValue = focusCompletedInfo.value(forKey: "titleStats") as? String ?? lblTitleStats.stringValue
                lblTitleFocusAlignmentScore.stringValue = focusCompletedInfo.value(forKey: "titleFocusAlignmentScore") as? String ?? lblTitleFocusAlignmentScore.stringValue
                lblTitleDeepWorkTime.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTime") as? String ?? lblTitleDeepWorkTime.stringValue
                lblTitleDeepWorkTimeToday.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTimeToday") as? String ?? lblTitleDeepWorkTimeToday.stringValue
                lblTitleAverageTimeSpentPerTab.stringValue = focusCompletedInfo.value(forKey: "titleTimeSpentPerTab") as? String ?? lblTitleAverageTimeSpentPerTab.stringValue
                lblTitleTabCount.stringValue = focusCompletedInfo.value(forKey: "titleTabCount") as? String ?? lblTitleTabCount.stringValue
                lblTitleAppOrSite.stringValue = focusCompletedInfo.value(forKey: "titleAppOrSite") as? String ?? lblTitleAppOrSite.stringValue
                lblTitleTime.stringValue = focusCompletedInfo.value(forKey: "titleTime") as? String ?? lblTitleTime.stringValue
                lblEnableAdvancedAnalyticsSetting.stringValue = focusCompletedInfo.value(forKey: "enableAdvancedAnalyticsSettingText") as? String ?? lblEnableAdvancedAnalyticsSetting.stringValue
                btnMoreOptions.title = focusCompletedInfo.value(forKey: "buttonMoreOptionsText") as? String ?? btnMoreOptions.title
                lblAccordinMoreOptions.stringValue = focusCompletedInfo.value(forKey: "buttonAccordionMoreOptionsText") as? String ?? lblAccordinMoreOptions.stringValue
            }
        }
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
        if addTaskVcObj != nil{
            if addTaskVcObj!.presentingViewController == self{
                addTaskVcObj!.dismiss(addTaskVcObj!)
                allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-closed", metadata: [:])
            }
        }
    }
    
    override func viewDidAppear() {
        isViewVisible = true
        tabMatricsObject.closeLastDomainIfStarted()
        tabMatricsObject.closeLastAppIfStarted()
        arrAllAppsTabsData.removeAll()
        
        var arrAllUrlsRecodDuringFocusMode = tabMatricsObject.arrAllUrlsRecodDuringFocusMode
        var arrAllAppsRecodDuringFocusMode = tabMatricsObject.arrAllAppsRecodDuringFocusMode
        

        arrAllAppsRecodDuringFocusMode = tabMatricsObject.clubAllSameAppEntries(appData: arrAllAppsRecodDuringFocusMode)
        arrAllUrlsRecodDuringFocusMode = tabMatricsObject.clubAllSameDomainEntries(appData: arrAllUrlsRecodDuringFocusMode)
        arrAllAppsTabsData = arrAllAppsRecodDuringFocusMode
        arrAllAppsTabsData += arrAllUrlsRecodDuringFocusMode
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            arrAllAppsTabsData = arrAllAppsTabsData.sorted { dict1, dict2 in
                guard let duration1 = dict1[tabMatricsObject.keyFocusDuration] as? Int,
                      let duration2 = dict2[tabMatricsObject.keyFocusDuration] as? Int else {
                    return false
                }
                return duration1 > duration2
            }
            
            lblEnableAdvancedAnalyticsSetting.isHidden = true
        }else{
            lblEnableAdvancedAnalyticsSetting.isHidden = false
        }
        
        tblView.reloadData()// need to reload always
    
        lblFocusAlignmentScore.stringValue = "\(currentFocusAlignmentScore)%"
        let arrAllTabsCount = tabMatricsObject.arrAllTabsCount
        let sumOfCount =  arrAllTabsCount.reduce(0, +)
        if arrAllTabsCount.count > 0{
            let average = sumOfCount / arrAllTabsCount.count
            lblTabCount.stringValue = "\(average)"
        }else{
            lblTabCount.stringValue = "0"
        }
        
        let duration = Double(focusModeActualDurationPerformed)
        var finalDuration = duration
        if SettingsManagerObject.isAiCheckUrlEnabled{
            boxFocusAlignmentScore.isHidden = false
            let score = currentFocusAlignmentScore
            let deepWorkDurationForAlignmentScore = (duration * score) / 100
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(deepWorkDurationForAlignmentScore))
            finalDuration = deepWorkDurationForAlignmentScore
        }else{
            boxFocusAlignmentScore.isHidden = true
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(duration))
        }
        
        boxFocusAlignmentScore.isHidden = true// accordion
        let totalDeepFocusedTimeToday = totalDeepFocusedTime + finalDuration
        lblDeepWorkTimeToday.stringValue = getStringTimeFromSeconds(seconds: Int(totalDeepFocusedTimeToday))
        
        
        // Calculate the average duration per tab
        var allAppsWithoutBrowsers = [[String : Any]]()//
        //  ignore browser in average tab count
        for item in arrAllAppsTabsData{
            let isBrowser = item[tabMatricsObject.keyIsBrowser] as? Bool ?? false
            if !isBrowser{
                allAppsWithoutBrowsers.append(item)
            }
        }
        
        let totalDuration = allAppsWithoutBrowsers.reduce(0) { total, entry in
            if let duration = entry["duration"] as? Int {
                return total + duration
            }
            return total
        }

        let averageDuration = allAppsWithoutBrowsers.isEmpty ? 0 : totalDuration / allAppsWithoutBrowsers.count
        lblAverageTimeSpentPerTab.stringValue = getStringTimeFromSeconds(seconds: averageDuration)
        
        if !focusModeTaskStringIsEmpty() || allowExtend{
            let obj = getAddTaskVcObject()
            obj.loadView()
            if self.view.window != nil{
                obj.reloadData(isAddingTask: false, allowExtend: false, isHabitGoing: true)
                self.presentAsSheet(obj)
            }
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-shown", metadata: [:])
        }
        setViewHeight()
        reloadMoreOptionsState()
    }
    
    override func viewDidLayout() {
        if isViewVisible{
            setViewHeight()
        }
    }

    func setViewHeight(){
        if self.view.frame.height < 700{
            heightScrollView.constant = 500
        }else if self.view.frame.height < 800{
            heightScrollView.constant = 700
        }else {
            heightScrollView.constant = 750
        }
    }
    
    var is_skipped = false
    var durationInSeconds = 0
    var logQuantityQuestion = ""
    var isReviseQuantity = false
    var activity_id:String = ""
    var activity_sequence_id:String = ""
    var activityChoiceId:String?
    var quantity_logged:Double?
    var log_quantity_answers: [[String : Any]] = []
    var notes = ""

    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date, durationInSeconds:Int, quantity_logged:Double?, activity_id:String, activity_sequence_id:String, activityChoiceId:String?, log_quantity_answers: [[String : Any]], notes:String){
        nextFocusSessionIntention = ""
        currentRatingCount = 0
        updateStarRatingView()
        arrAllTags.removeAll()
        for tagInfo in arrAllFocusModeTags{
            arrAllTags.append(tagInfo["text"] ?? "")
        }
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textFieldAchieve.stringValue = ""
        
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)

        
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String ?? "" == currentFocusModeId{
                currentFocusModeIndex = i
                break;
            }
        }
        
        if let tags = arrFocusType[currentFocusModeIndex]["tags"] as? [String]{
            tokenFieldTags.objectValue = tags
        }
        
        self.is_skipped = false
        self.activityChoiceId = nil
        self.activityChoiceId = activityChoiceId
        self.activity_id = activity_id
        self.activity_sequence_id = activity_sequence_id
        self.durationInSeconds = durationInSeconds
        self.quantity_logged = nil
        self.quantity_logged = quantity_logged
        self.log_quantity_answers = log_quantity_answers
        self.notes = notes
        
        
        
        reloadMoreOptionsState()
        reloadMoreQuestionsState()
    }

    @objc private func menuItemClicked(_ menuItem: NSMenuItem) {
        if let fieldEditor = tokenFieldTags?.currentEditor() {
            let textRange = fieldEditor.selectedRange
            let replaceString = menuItem.title
            fieldEditor.replaceCharacters(in: textRange, with: replaceString)
            fieldEditor.selectedRange = NSMakeRange(textRange.location, replaceString.count)
        }
    }
//    func updateAllFocusModeTags(){
//        arrAllTags.removeAll()
//        var arrJson = [[String: Any]]()
//        for focusType in arrFocusType{
//            var json: [String: Any] = [
//                "id":focusType["id"] as? String ?? "",
//                "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
//                "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
//                "name":focusType["name"] as? String ?? "",
//                "metadata": [:]
//            ]
//            var tagsDic = [[String:Any]]()
//            if let tags = focusType["tags"] as? [String]{
//                for tag in tags{
//                    tagsDic.append(["id": getIdForTag(tag: tag), "text": tag])
//                }
//            }
//            json["tags"] = tagsDic
//            
//            var dic = focusType
//            dic.removeValue(forKey: "name")
//            dic.removeValue(forKey: "id")
//            dic.removeValue(forKey: "allowed_urls")
//            dic.removeValue(forKey: "allowed_apps")
//            dic.removeValue(forKey: "tags")
//            json["metadata"] = dic
//            arrJson.append(json)
//        }
//        allApiObject.updateAllFocusMode(focusModes: arrJson, completionHandler: {json in
//            
//        })
//    }
    
    func getTagsString()->String{
        let tags = self.tokenFieldTags.objectValue as? [String] ?? []
        var tagsString = ""
        for i in 0..<tags.count{
            let tag = tags[i]
            if i == 0{
                tagsString += tag
            }else{
                tagsString += ";" + tag
            }
            
        }
        return tagsString
    }
    
    var currentRatingCount = 0
    func updateStarRatingView(){
        btnStarFirst.image = NSImage(named: "star_Gray")
        btnStarSecond.image = NSImage(named: "star_Gray")
        btnStarThird.image = NSImage(named: "star_Gray")
        btnStarFourth.image = NSImage(named: "star_Gray")
        btnStarFifth.image = NSImage(named: "star_Gray")
        
        if currentRatingCount == 1{
            btnStarFirst.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 2{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 3{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 4{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
        }else if currentRatingCount == 5{
            btnStarFirst.image = NSImage(named: "star_Golden")
            btnStarSecond.image = NSImage(named: "star_Golden")
            btnStarThird.image = NSImage(named: "star_Golden")
            btnStarFourth.image = NSImage(named: "star_Golden")
            btnStarFifth.image = NSImage(named: "star_Golden")
        }
    }
    
    
    
    @IBAction func btnStarFirstClicked(_ sender: Any) {
        currentRatingCount = 1
        updateStarRatingView()
    }
    
    @IBAction func btnStarSecondClicked(_ sender: Any) {
        currentRatingCount = 2
        updateStarRatingView()
    }
    
    @IBAction func btnStarThirdClicked(_ sender: Any) {
        currentRatingCount = 3
        updateStarRatingView()
    }
    
    @IBAction func btnStarFourthClicked(_ sender: Any) {
        currentRatingCount = 4
        updateStarRatingView()
    }
    
    @IBAction func btnStarFifthClicked(_ sender: Any) {
        currentRatingCount = 5
        updateStarRatingView()
    }
    
   
    
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        
        self.view.removeFromSuperview()
        if currentState == ._EVENING_HABIT_{
            if thirdVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
            }
        }
        var should_not_update_current_activity = false
        if currentState == ._SPECIAL_ACTIVITY_{
            should_not_update_current_activity = true
        }
        
        allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:quantity_logged, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: is_skipped, notes: notes, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
            DispatchQueue.main.async {
                
            }
            
            print(dic)
        })

        whatToAchieveInFocusBlock = ""

        
        
        let timestamp = getStringFromDate(date: lastActivityPerformedTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
//        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        focusModeActualDurationPerformed = durationInSeconds
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: "", abortReason: "", feedback: "", tags:getTagsString())

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: "", finish_time: self.finish_time ?? Date(), rating:currentRatingCount, completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })

    }
    func getStringTimeFromSeconds(seconds : Int)->String{
        if seconds == 0{
            return "0" + secondsSText
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
        var stringTime: String = ""
        if h != 0{
            stringTime = "\(h)" + hoursHText
        }
        if m != 0{
            if stringTime.isEmpty{
                stringTime = "\(m)" + minutesMText
            }else{
                stringTime += " \(m)" + minutesMText
            }
        }
        if s != 0{
            if stringTime.isEmpty{
                stringTime = "\(s)" + secondsSText
            }else{
                stringTime += " \(s)" + secondsSText
            }
        }
        return stringTime
    }
    
    @IBAction func btnInfoFocusAlignmentClicked(_ sender: NSButton) {
        var msg = ""
        if SettingsManagerObject.isAiCheckUrlEnabled{
            msg = "The % of the focus session that you spent on productive sites/apps based on Focus Bear's AI."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScoreAi") as? String ?? msg
                }
            }
        }else{
            msg = "The % of the focus session that you spent on productive sites/apps based on your list of blocked/allowed sites."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScore") as? String ?? msg
                }
            }
        }

        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoDeepWotkTimeThisSessionClicked(_ sender: NSButton) {
        var msg = "We multiply the focus session duration by the focus alignment score to get your deep work time"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipDeepWotkTimeThisSession") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoTotalWotkTimeTodayClicked(_ sender: NSButton) {
        var msg = "Total deep work time accumulated from all focus sessions today, calculated using session duration and focus alignment score."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipTotalWotkTimeToday") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTimePerTabClicked(_ sender: NSButton) {
        var msg = "Focus Bear keeps track of how much time you spend in each browser tab. If you are constantly changing tabs, it indicates that you're probably multi tasking rather than sticking to one task."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTimePerTab") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTabCountClicked(_ sender: NSButton) {
        var msg = "If you have a lot of tabs open, you're likely to get distracted by half finished work. Put the tasks in your to do list instead. Use Focus Bear's tab limiter feature to help avoid tab overwhelm."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTabCount") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAppOrSiteClicked(_ sender: NSButton) {
        var msg = "This shows your top 5 apps/sites during this focus session. Data is only stored locally on your computer."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAppOrSite") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnMoreOptionsClicked(_ sender: Any) {
        if boxAverageTimeSpent.isHidden{
            expandMoreOptions()
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusStatsExpanded)
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func reloadMoreOptionsState(){
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFocusStatsExpanded) as? Bool{
            if val{
                expandMoreOptions()
            }else{
                collapseMoreOptions()
            }
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func expandMoreOptions(){
        boxAverageTimeSpent.isHidden = false
        boxAverageTabCount.isHidden = false
        if SettingsManagerObject.isAiCheckUrlEnabled{
            boxFocusAlignmentScore.isHidden = false
        }else{
            boxFocusAlignmentScore.isHidden = true
        }
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
    }
    
    func collapseMoreOptions(){
        boxFocusAlignmentScore.isHidden = true
        boxAverageTimeSpent.isHidden = true
        boxAverageTabCount.isHidden = true
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoForwardTemplateName)
    }
    
    @IBAction func btnViewAccordinMoreOptionsClicked(_ sender: Any) {
        if stackviewAchieve.isHidden{
            expandMoreQuestions()
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusAllThingsExpanded)
        }else{
            collapseMoreQuestions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusAllThingsExpanded)
        }
    }
    func collapseMoreQuestions(){
        stackviewAchieve.isHidden = true
        stackViewStarRating.isHidden = true
        stackViewTags.isHidden = true
        imgViewAccordinMoreOptions.image = NSImage(named: NSImage.goForwardTemplateName)
    }
    
    func expandMoreQuestions(){
        stackviewAchieve.isHidden = false
        stackViewStarRating.isHidden = false
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app") && UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool == true{// show tags box if time tracker is enabled
            stackViewTags.isHidden = false
        }else{
            stackViewTags.isHidden = true
        }
        imgViewAccordinMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
    }
    
    func reloadMoreQuestionsState(){
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFocusAllThingsExpanded) as? Bool{
            if val{
                expandMoreQuestions()
            }else{
                collapseMoreQuestions()
            }
        }else{
            collapseMoreQuestions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusAllThingsExpanded)
        }
    }
}



extension focusCompletedForActivityVc:NSTextFieldDelegate, NSTokenFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if tokenFieldTags == self.tokenFieldTags{
                let selectedRow = currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                dic["tags"] = self.tokenFieldTags.objectValue as? [String] ?? []

                arrFocusType[selectedRow] = dic
            }
        }
    }
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if UserDefaults.standard.object(forKey: kUserdefaultsShowTextForTokenFieldFirstTime) == nil{
                if tokenFieldTags == self.tokenFieldTags{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsShowTextForTokenFieldFirstTime)
                    var addTagsInfoText = "Press enter to add the tag"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                            addTagsInfoText = focusCompletedInfo.value(forKey: "addTagsInfoText") as? String ?? addTagsInfoText
                        }
                    }
                    showTooltip(sender: self.boxTempForShowToolTip, msg: addTagsInfoText, preferredEdge: .maxY, maxWidthVal: 250)
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                        popoverTooltip?.close()
                    }
                }
            }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }
    func tokenField(_ tokenField: NSTokenField,
                    menuForRepresentedObject representedObject: Any) -> NSMenu? {
        defaultTokenMenu.removeAllItems()
        for habit in arrAllTags{//
            let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
            item.target = self
            defaultTokenMenu.addItem(item)
        }
        
        return defaultTokenMenu
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return arrAllTags.filter { $0.lowercased().hasPrefix(substring.lowercased()) }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {

        DispatchQueue.global().async {
            DispatchQueue.main.async {
                
                let selectedRow = self.currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                //dic["tags"] = self.tokenField.objectValue as? [String] ?? []
                let tags = self.tokenFieldTags.objectValue as? [String] ?? []
                
                var finalTags = [String]()
                for i in 0..<tags.count{
                    if !finalTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                        finalTags.append(tags[i])
                        if !self.arrAllTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                            self.arrAllTags.append(tags[i])
                        }
                    }
                }
                dic["tags"] = finalTags
                arrFocusType[selectedRow] = dic
                self.tokenFieldTags.objectValue = finalTags
            }
        }
        return tokens
    }
    
}

extension focusCompletedForActivityVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            return arrAllAppsTabsData.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocsedCompletedItem"), owner: nil) as? tblCellFocsedCompletedItem {

            if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusAppTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }else if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDomainTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }
            if let duration = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDuration] as? Int{
                cell.lblDuration.stringValue = getStringTimeFromSeconds(seconds: duration)
                cell.progress.maxValue = Double(focusModeActualDurationPerformed)
                cell.progress.doubleValue = Double(duration)
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }

}
