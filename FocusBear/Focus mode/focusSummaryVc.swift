//
//  focusSummaryVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/02/22.


import Cocoa

class focusSummaryVc: NSViewController {
    
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var widthScrollViewFocusSummary: NSLayoutConstraint!
    @IBOutlet weak var lblTotalBreaksTimeGeekMode: NSTextField!
    @IBOutlet weak var lblTitleTimeSpentOnBreaks: NSTextField!
    @IBOutlet weak var lblTimeSpentOnBreaks: NSTextField!
    @IBOutlet weak var lblTimeSpentDisabledApp: NSTextField!
    @IBOutlet weak var lblTimeSpentEnableApp: NSTextField!
    @IBOutlet weak var lblTotalTimeOnBlockedSItes: NSTextField!
    @IBOutlet weak var lblTotalDistractingSites: NSTextField!
    @IBOutlet weak var lblTitleTimeSpentDisabledApp: NSTextField!
    @IBOutlet weak var lblTitleTimeSpentEnableApp: NSTextField!
    @IBOutlet weak var lblTitleTotalTimeOnBlockedSItes: NSTextField!
    @IBOutlet weak var lblTitleTotalDistractingSites: NSTextField!
    
    @IBOutlet weak var btnNeedMoreTime: Button!
    @IBOutlet weak var lblTotalFocusTime: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var scrollViewFocusSummary: NSScrollView!
    @IBOutlet weak var scrollViewActivitySummaryTotal: NSScrollView!
    @IBOutlet weak var scrollViewActivitySummaryAverage: NSScrollView!
    @IBOutlet weak var scrollViewActivitySummaryDuration: NSScrollView!
    //    @IBOutlet weak var heightConstraints: NSLayoutConstraint!
    @IBOutlet weak var tblViewActivitySummaryTotal: NSTableView!
    @IBOutlet weak var tblViewActivitySummaryAverage: NSTableView!
    @IBOutlet weak var tblViewActivitySummaryDuration: NSTableView!
    @IBOutlet weak var tblViewFocusSummary: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblActivitySummary: NSTextField!
    @IBOutlet weak var lblFocusSummary: NSTextField!
  
    
    @IBOutlet weak var boxSimpleMode: NSBox!
    var viewVisibleCount = 0
    
    var titleText = "You completed <COUNT> focus blocks today."
    var focusTableColumnFirstText = "Focus type"
    var focusTableColumnSecondText = "Start Time"
    var focusTableColumnThirdText = "Duration"
    var focusTableColumnFourthText = "Work Achieved"
    var focusTableColumnFifthText = "Distractions encountered"
    
    
    var activityTableColumnFirstText = "Activity"
    var activityTableColumnSecondText = "Total Quantity"
    var activityTableColumnThirdText = "Average"
    
    var activityTableColumnSixthText = "Total Duration"
    var totalFocusTimeText = "Total focus time: <TIME>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleTimeSpentOnBreaks.stringValue = "Time spent on breaks"
        lblTitleTimeSpentDisabledApp.stringValue = "Time spent with blocking deactivated:"
        lblTitleTimeSpentEnableApp.stringValue = "Time spent with blocking activated:"
        lblTitleTotalTimeOnBlockedSItes.stringValue = "Time spent on super distracting sites:"
        lblTitleTotalDistractingSites.stringValue = "Total distracting sites blocked:"
        btnNeedMoreTime.isSecondaryButton = true
        btnContinue.title = "Continue"
        lblActivitySummary.stringValue = "Activity Summary:"
        lblFocusSummary.stringValue = "Focus Summary:"
        
//        boxSimpleMode.fillColor = NSColor.clear
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                if let title = focusSummaryInfo.value(forKey: "title") as? String{
                    titleText = title
                }
                if let buttonContinueText = focusSummaryInfo.value(forKey: "buttonContinueText") as? String{
                    btnContinue.title = buttonContinueText
                }
                if let buttonNeedMoreTimeText = focusSummaryInfo.value(forKey: "buttonNeedMoreTimeText") as? String{
                    btnNeedMoreTime.title = buttonNeedMoreTimeText
                }
                
                if let focusTableColumnFirstText = focusSummaryInfo.value(forKey: "focusTableColumnFirstText") as? String{
                    self.focusTableColumnFirstText = focusTableColumnFirstText
                }
                if let focusTableColumnSecondText = focusSummaryInfo.value(forKey: "focusTableColumnSecondText") as? String{
                    self.focusTableColumnSecondText = focusTableColumnSecondText
                }
                if let focusTableColumnThirdText = focusSummaryInfo.value(forKey: "focusTableColumnThirdText") as? String{
                    self.focusTableColumnThirdText = focusTableColumnThirdText
                }
                if let focusTableColumnFourthText = focusSummaryInfo.value(forKey: "focusTableColumnFourthText") as? String{
                    self.focusTableColumnFourthText = focusTableColumnFourthText
                }
                if let focusTableColumnFifthText = focusSummaryInfo.value(forKey: "focusTableColumnFifthText") as? String{
                    self.focusTableColumnFifthText = focusTableColumnFifthText
                }
                if let activityTableColumnFirstText = focusSummaryInfo.value(forKey: "activityTableColumnFirstText") as? String{
                    self.activityTableColumnFirstText = activityTableColumnFirstText
                }
                if let activityTableColumnSecondText = focusSummaryInfo.value(forKey: "activityTableColumnSecondText") as? String{
                    self.activityTableColumnSecondText = activityTableColumnSecondText
                }
                if let activityTableColumnThirdText = focusSummaryInfo.value(forKey: "activityTableColumnThirdText") as? String{
                    self.activityTableColumnThirdText = activityTableColumnThirdText
                }
                if let activityTableColumnSixthText = focusSummaryInfo.value(forKey: "activityTableColumnSixthText") as? String{
                    self.activityTableColumnSixthText = activityTableColumnSixthText
                }
                
                if let titleActivitySummaryText = focusSummaryInfo.value(forKey: "titleActivitySummaryText") as? String{
                    lblActivitySummary.stringValue = titleActivitySummaryText
                }
                if let titleFocusSummaryText = focusSummaryInfo.value(forKey: "titleFocusSummaryText") as? String{
                    lblFocusSummary.stringValue = titleFocusSummaryText
                }
                if let totalFocusTimeText = focusSummaryInfo.value(forKey: "totalFocusTimeText") as? String{
                    self.totalFocusTimeText = totalFocusTimeText
                }
            }
        }
        
        
        
        
        
    }
    
    override func viewWillAppear() {
        setScrollViewFocusSummaryWidth()
    }
    
    var timerStopAnimation:Timer?
    func setTimerStopAnimation(){
        timerStopAnimation?.invalidate()
        timerStopAnimation = nil
        imgViewGif.animates = true
        
        timerStopAnimation = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(stopAnimatingImageview), userInfo: nil, repeats: false)
    }
    
    @objc func stopAnimatingImageview(){
        imgViewGif.animates = false
    }
    
    func reloadData(){
        arrActivitySummaryAverageDic.removeAll()
        arrActivitySummaryTotalDic.removeAll()
        arrActivitySummaryDurationDic.removeAll()
        arrFocusSummaryDic.removeAll()
        setTimerStopAnimation()
        if SettingsManagerObject.isGeekModeEnabled{
            scrollViewFocusSummary.isHidden = false
            scrollViewActivitySummaryTotal.isHidden = false
            scrollViewActivitySummaryAverage.isHidden = false
            scrollViewActivitySummaryDuration.isHidden = false
            lblTotalFocusTime.isHidden = false
            lblFocusSummary.isHidden = false
            lblActivitySummary.isHidden = false
            boxSimpleMode.isHidden = true
            
            if allActivityTodaySummaryData != nil{
                
                if let arr = allActivityTodaySummaryData!.value(forKey: "focusSummary") as? [[String:Any]]{
                    for item in arr{
                        let name = item["name"] as? String ?? ""
                        let duration = item["duration"] as? Double ?? 0
                        var start_time = item["start_time"] as? String ?? ""
                        var achievements = item["achievements"] as? String ?? ""
                        let distractions = item["distractions"] as? String ?? ""
                        if let date = getDateFromStringInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                            start_time = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
                        }
                        achievements = achievements.removingPercentEncoding ?? achievements
                        let dic = ["Activity":name, "Duration in seconds":"\(Int(duration))", "Start Time": start_time, "Work achieved": achievements, "Distractions encountered": distractions]
                        arrFocusSummaryDic.append(dic)
                    }
                }
                
                if let arr = allActivityTodaySummaryData!.value(forKey: "daySummaryAVG") as? [[String:Any]]{
                    for item in arr{
                        let name = item["name"] as? String ?? ""
                        let quantity = item["quantity"] as? Double ?? 0
                        let dic = ["Activity":name, "quantity":"\(roundDoubleValue(val: quantity))"]
                        arrActivitySummaryAverageDic.append(dic)
                    }
                }
                if let arr = allActivityTodaySummaryData!.value(forKey: "daySummarySUM") as? [[String:Any]]{
                    for item in arr{
                        let name = item["name"] as? String ?? ""
                        let quantity = item["quantity"] as? Double ?? 0
                        let dic = ["Activity":name, "quantity":"\(roundDoubleValue(val: quantity))"]
                        arrActivitySummaryTotalDic.append(dic)
                    }
                }
                if let arr = allActivityTodaySummaryData!.value(forKey: "daySummaryDuration") as? [[String:Any]]{
                    for item in arr{
                        let name = item["name"] as? String ?? ""
                        let duration = item["duration"] as? Int ?? 0//will be in integer
                        let dic = ["Activity":name, "duration":"\(duration)"]
                        arrActivitySummaryDurationDic.append(dic)
                    }
                }
                var totalSeconds = 0
                for i in 0..<arrFocusSummaryDic.count{
                    let stirngCount = arrFocusSummaryDic[i]["Duration in seconds"] ?? ""
                    let seconds = Int(stirngCount) ?? 0
                    totalSeconds += seconds
                }
                
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: totalSeconds)
                
                let time = "\(h)h \(m)m \(s)s"
                lblTotalFocusTime .stringValue = totalFocusTimeText.replacingOccurrences(of: "<TIME>", with: time)
            }else{
                readCsv()
            }
            
            
            tblViewFocusSummary.reloadData()
            tblViewActivitySummaryTotal.reloadData()
            tblViewActivitySummaryAverage.reloadData()
            tblViewActivitySummaryDuration.reloadData()
            
            lblTitle.stringValue = titleText.replacingOccurrences(of: "<COUNT>", with: "\(arrFocusSummaryDic.count)")//"You completed \(arrFocusSummaryDic.count) focus blocks today."
            
            let arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
            let totalDuration = arrDuration.reduce(0, +)
            
            var timeSpentText = "Total time spent on breaks: <TIME>"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                    timeSpentText = focusSummaryInfo.value(forKey: "totalBreaksTimeText") as? String ?? timeSpentText
                }
            }
            lblTotalBreaksTimeGeekMode.stringValue = timeSpentText.replacingOccurrences(of: "<TIME>", with: getStringTimeFromSeconds(seconds: totalDuration))
            
        }else{
            scrollViewFocusSummary.isHidden = true
            scrollViewActivitySummaryTotal.isHidden = true
            scrollViewActivitySummaryAverage.isHidden = true
            scrollViewActivitySummaryDuration.isHidden = true
            lblTotalFocusTime.isHidden = true
            lblFocusSummary.isHidden = true
            lblActivitySummary.isHidden = true
            boxSimpleMode.isHidden = false
            lblTitle.stringValue = "Your day summary"
            lblTitleTimeSpentDisabledApp.stringValue = "Time spent with blocking deactivated:"
            lblTitleTimeSpentEnableApp.stringValue = "Time spent with blocking activated:"
            lblTitleTotalTimeOnBlockedSItes.stringValue = "Time spent on super distracting sites:"
            lblTitleTotalDistractingSites.stringValue = "Total distracting sites blocked:"
            lblTitleTimeSpentOnBreaks.stringValue = "Total time spent on breaks:"
            
            
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                    lblTitle.stringValue = focusSummaryInfo.value(forKey: "titleDaySummary") as? String ?? lblTitle.stringValue
                    lblTitleTimeSpentDisabledApp.stringValue = focusSummaryInfo.value(forKey: "titleTimeSpentDisabledApp") as? String ?? lblTitleTimeSpentDisabledApp.stringValue
                    lblTitleTimeSpentEnableApp.stringValue = focusSummaryInfo.value(forKey: "titleTimeSpentEnableApp") as? String ?? lblTitleTimeSpentEnableApp.stringValue
                    lblTitleTotalTimeOnBlockedSItes.stringValue = focusSummaryInfo.value(forKey: "titleTotalTimeOnBlockedSItes") as? String ?? lblTitleTotalTimeOnBlockedSItes.stringValue
                    lblTitleTotalDistractingSites.stringValue = focusSummaryInfo.value(forKey: "titleTotalDistractingSites") as? String ?? lblTitleTotalDistractingSites.stringValue
                    lblTitleTimeSpentOnBreaks.stringValue = focusSummaryInfo.value(forKey: "titleTimeSpentOnBreaks") as? String ?? lblTitleTimeSpentOnBreaks.stringValue
                }
            }
            
            var totalDurationaSaved = 0
            if let timeSpentInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalTimeSpentOnDistractingSites) as? [String:Any]{
                if let date = timeSpentInfo["date"] as? Date, let duration = timeSpentInfo["duration"] as? Int{
                    if Calendar.current.isDateInToday(date){
                        totalDurationaSaved = duration
                    }
                }
            }
            
            var totalBlockedSites = 0
            if let blockInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalDistractingSitesBlocked) as? [String:Any]{
                if let date = blockInfo["date"] as? Date, let count = blockInfo["count"] as? Int{
                    if Calendar.current.isDateInToday(date){
                        totalBlockedSites = count
                    }
                }
            }
            
            
            var totalAppEnableTime = SettingsManagerObject.totalAppEnableTime
            var totalAppDisableTime = SettingsManagerObject.totalAppDisableTime
                
            if isAppEnable{
                let diffSeconds = Calendar.current.dateComponents([.second], from: SettingsManagerObject.appEnableDate ?? Date(), to: Date()).second ?? 0
                totalAppEnableTime = totalAppEnableTime + diffSeconds

            }else{
                let diffSeconds = Calendar.current.dateComponents([.second], from: SettingsManagerObject.appDisableDate ?? Date(), to: Date()).second ?? 0
                totalAppDisableTime = totalAppDisableTime + diffSeconds
                
            }
            
            lblTimeSpentEnableApp.stringValue = getStringTimeFromSeconds(seconds: totalAppEnableTime)
            lblTimeSpentDisabledApp.stringValue = getStringTimeFromSeconds(seconds: totalAppDisableTime)
            lblTotalTimeOnBlockedSItes.stringValue = getStringTimeFromSeconds(seconds: totalDurationaSaved)
            lblTotalDistractingSites.integerValue = totalBlockedSites
            
            let arrDuration = UserDefaults.standard.object(forKey: kUserdefaultsArrayBreaksDurations) as? [Int] ?? []
            let totalDuration = arrDuration.reduce(0, +)
            
            lblTimeSpentOnBreaks.stringValue = getStringTimeFromSeconds(seconds: totalDuration)
        }
        
        
        
        if viewVisibleCount == 0{
            btnNeedMoreTime.title = "I need to work for one more minute"
            
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                    if let buttonNeedMoreTimeText = focusSummaryInfo.value(forKey: "buttonNeedMoreTimeText") as? String{
                        btnNeedMoreTime.title = buttonNeedMoreTimeText
                    }
                }
            }
        }else{
            btnNeedMoreTime.title = "I still need to work more"
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusSummaryInfo = focusInfo.value(forKey: "focusSummaryInfo") as? NSDictionary{
                    if let buttonNeedMoreTimeText = focusSummaryInfo.value(forKey: "buttonStillNeedMoreTimeText") as? String{
                        btnNeedMoreTime.title = buttonNeedMoreTimeText
                    }
                }
            }
        }
        
    }
    
    override func viewDidAppear() {
        
    }
    
    override func viewDidLayout() {
        setScrollViewFocusSummaryWidth()
    }
    
    func setScrollViewFocusSummaryWidth(){
        let windowWidth = self.view.frame.width
        if windowWidth < 1100 {
            // Very narrow window: use smallest scroll view width
            widthScrollViewFocusSummary.constant = 800
        } else if windowWidth < 1300 {
            // 13-inch MacBook range (~1280px): reduce width to prevent label overlap
            widthScrollViewFocusSummary.constant = 900
        } else {
            widthScrollViewFocusSummary.constant = 1000
        }
        // Ensure the title label truncates gracefully rather than overlapping
        lblTitle.lineBreakMode = .byTruncatingTail
        lblTitle.maximumNumberOfLines = 1
    }
    
    
    func getStringTimeFromSeconds(seconds : Int)->String{
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
        if stringTime.isEmpty{
            stringTime += "\(m)" + minutesMText
        }
        return stringTime
    }
    
    
    
    var arrFocusSummaryDic = [[String:String]]()
    
    var arrActivitySummaryTotalDic = [[String:String]]()
    var arrActivitySummaryAverageDic = [[String:String]]()
    var arrActivitySummaryDurationDic = [[String:String]]()
    
    func readCsv(){
        var arrActivitySummaryDic = [[String:String]]()
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        var arr = readDataFromCSV(url: quantityCsvURL!)
        print(arr)
        arrFocusSummaryDic.removeAll()
        arrActivitySummaryDic.removeAll()
        if let headers = arr.first{
            arr.remove(at: 0)
            if arr.count != 0{
                //all rows
                for j in 0..<arr.count{
                    let subarray = arr[j]
                    if subarray.count != headers.count{// column numbers are fixed so verifying content while reading
                        
                    }else{
                        var dic = [String:String]()
                        for i in 0..<subarray.count{
                            dic[headers[i]] = subarray[i]
                        }
                        if (dic["Log type"] ?? "") == "focus block"{
                            if let time = dic["Timestamp"]{
                                if let dateTime = getDateFromString(date: time, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                                    if dateTime.compare(startDate) == .orderedDescending {
                                        arrFocusSummaryDic.append(dic)
                                    }
                                }
                            }
                        }else if (dic["Log type"] ?? "") == "break"{
                            if let time = dic["Timestamp"]{
                                if let dateTime = getDateFromString(date: time, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                                    if dateTime.compare(startDate) == .orderedDescending {
                                        arrActivitySummaryDic.append(dic)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            
        }
        //        tblViewSummary.reloadData()
        print(arrActivitySummaryDic)
        var newDic = [String:Any]()
        
        for dic in arrActivitySummaryDic{
            print(dic)
            var oldDic = [String:Any]()
            if let dic = newDic[dic["Activity"] ?? ""] as? [String:Any]{
                oldDic = dic
            }
            var arrQuantity = [Double]()
            var doubleQuantity:Double = -1
            if let quantity = dic["Quantity Logged"] {
                if let doubleVal = Double(quantity){
                    doubleQuantity = doubleVal
                }
            }
            if let arr = oldDic["QuantityLoggedArr"] as? [Double]{
                arrQuantity = arr
            }
            if doubleQuantity != -1{
                arrQuantity.append(doubleQuantity)
            }
            oldDic["QuantityLoggedArr"] = arrQuantity
            
            
            
            var arrDuration = [Int]()
            var intDuration = -1
            if let duration = dic["Duration in seconds"] {
                if let intVal = Int(duration){
                    intDuration = intVal
                }
            }
            if let arr = oldDic["DurationArr"] as? [Int]{
                arrDuration = arr
            }
            if intDuration != -1{
                arrDuration.append(intDuration)
            }
            oldDic["DurationArr"] = arrDuration
            
            
            newDic[dic["Activity"] ?? ""] = oldDic
        }
        print(newDic.count)
        print(newDic)
        arrActivitySummaryDic.removeAll()
        arrActivitySummaryTotalDic.removeAll()
        arrActivitySummaryAverageDic.removeAll()
        arrActivitySummaryDurationDic.removeAll()
        for key in newDic.keys{
            if let dic = newDic[key] as? [String:Any]{
                var summaryDic = [String:String]()
                summaryDic["Activity"] = key
                let logQuantityType = getLogquaqntityTypeFromActivity(activityName: key)
                
                
                if let arr = dic["QuantityLoggedArr"] as? [Double]{
                    if arr.count != 0{
                        var total:Double = 0
                        var min:Double = 0
                        var max:Double = 0
                        var average:Double = 0
                        
                        
                        max = arr.max() ?? max
                        min = arr.min() ?? min
                        total = arr.reduce(0, +)
                        
                        
                        
                        
                        
                        
                        if logQuantityType == "AVG"{
                            if total != 0{
                                average = total/Double(arr.count)
                            }
                            summaryDic["quantity"] = "\(average)"
                            arrActivitySummaryAverageDic.append(summaryDic)
                            continue;
                        }else{//default sum
                            summaryDic["quantity"] = "\(total)"
                            arrActivitySummaryTotalDic.append(summaryDic)
                            continue;
                        }
                        
                        //                    summaryDic["max"] = "\(max)"
                        //                    summaryDic["min"] = "\(min)"
                        
                    }
                }
                
                if let arr = dic["DurationArr"] as? [Int]{
                    let total = arr.reduce(0, +)
                    summaryDic["duration"] = "\(total)"
                    arrActivitySummaryDurationDic.append(summaryDic)
                }
                
                //                arrActivitySummaryDic.append(summaryDic)
            }
        }
        
        
        //        lblTotalFocusTime
        var totalSeconds = 0
        for i in 0..<arrFocusSummaryDic.count{
            let stirngCount = arrFocusSummaryDic[i]["Duration in seconds"] ?? ""
            let seconds = Int(stirngCount) ?? 0
            totalSeconds += seconds
        }
        
        
        
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: totalSeconds)
        
        let time = "\(h)h \(m)m \(s)s"
        lblTotalFocusTime .stringValue = totalFocusTimeText.replacingOccurrences(of: "<TIME>", with: time)
        
    }
    
    func getLogquaqntityTypeFromActivity(activityName:String)->String{
        for activity in arrAllbreakActivities{
            if activity.name.lowercased() == activityName.lowercased(){
                return activity.logQuantityType
            }else{
                if activity.choiceType == ._RANDOM_{
                    for choice in activity.choices{
                        if choice.name.lowercased() == activityName.lowercased(){
                            return choice.logQuantityType
                        }
                    }
                }
            }
        }
        
        return ""
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] button continue Clicked from focus summary")
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else{// not shut off time
            
        }
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)

        // #1942: clear any pending "one more minute" timer and its countdown box before
        // proceeding, so it can't re-show the Focus Summary on top of the evening routine.
        getHabitsVcObject().timerGiveOneMoreMinut?.invalidate()
        getHabitsVcObject().timerGiveOneMoreMinut = nil
        closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()

        // Clear ._FOCUS_SUMMARY_ first: shutOffMac() early-returns when currentState is ._FOCUS_SUMMARY_,
        // so without this the call would do nothing. Then route the Focus Summary "Continue" through the
        // shutdown flow so shutOffMac() can display the completed evening routine before the shutdown prompt.
        currentState = ._NOTHING_
        viewVisibleCount = 0
        appdelegate?.shutOffMac()
    }
    
    @IBAction func btnNeedMoreTimeClicked(_ sender: Any) {        
        if viewVisibleCount == 0{
            addLog(text: "[user-action] button Need one More minute Clicked from focus summary")
            if cutOffTime != nil && SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff && !SettingsManagerObject.isEasySkipEnabled{
                if isCutOffTimeGoing() && shouldAskPassword(){
                    mainViewControllerObj?.showPasswordView()
                }else{
                    postponeFocusSummaryForOneMinute()
                }
            }else{
                postponeFocusSummaryForOneMinute()
            }
        }else{
            addLog(text: "[user-action] button I still need to work more Clicked from focus summary")
            getHabitsVcObject().abortCurrentState()
        }
    }
    
    func postponeFocusSummaryForOneMinute(){
        getHabitsVcObject().giveOneMoreMinuteBeforeShutOffMac()
        viewVisibleCount += 1
    }
    
}


extension focusSummaryVc: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tblViewFocusSummary{
            for i in 0..<tableView.tableColumns.count{
                let tableColumn = tableView.tableColumns[i]
                if i == 0{
                    tableColumn.title = focusTableColumnFirstText
                }else if i == 1{
                    tableColumn.title = focusTableColumnSecondText
                }else if i == 2{
                    tableColumn.title = focusTableColumnThirdText
                }else if i == 3{
                    tableColumn.title = focusTableColumnFourthText
                }else if i == 4{
                    tableColumn.title = focusTableColumnFifthText
                }
            }
            
            return arrFocusSummaryDic.count
        }else if tableView == tblViewActivitySummaryTotal{
            for i in 0..<tableView.tableColumns.count{
                let tableColumn = tableView.tableColumns[i]
                if i == 0{
                    tableColumn.title = activityTableColumnFirstText
                }else if i == 1{
                    tableColumn.title = activityTableColumnSecondText
                }
            }
            
            return arrActivitySummaryTotalDic.count
        }else if tableView == tblViewActivitySummaryAverage{
            for i in 0..<tableView.tableColumns.count{
                let tableColumn = tableView.tableColumns[i]
                if i == 0{
                    tableColumn.title = activityTableColumnFirstText
                }else if i == 1{
                    tableColumn.title = activityTableColumnThirdText
                }
            }
            return arrActivitySummaryAverageDic.count
        }else if tableView == tblViewActivitySummaryDuration{
            for i in 0..<tableView.tableColumns.count{
                let tableColumn = tableView.tableColumns[i]
                if i == 0{
                    tableColumn.title = activityTableColumnFirstText
                }else if i == 1{
                    tableColumn.title = activityTableColumnSixthText
                }
            }
            return arrActivitySummaryDurationDic.count
        }
        return 0
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_list"), owner: nil) as? NSTableCellView {
            
            if tableView == tblViewFocusSummary{
                if tableColumn != nil{
                    if tableColumn == tblViewFocusSummary.tableColumns[0]{
                        cell.textField?.stringValue = arrFocusSummaryDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewFocusSummary.tableColumns[1]{
                        cell.textField?.stringValue = arrFocusSummaryDic[row]["Start Time"] ?? ""
                    }else if tableColumn == tblViewFocusSummary.tableColumns[2]{
                        if let duration = arrFocusSummaryDic[row]["Duration in seconds"]{
                            if let seconds = Int(duration){
                                let strTime = getStringTimeFromSeconds(seconds:seconds)
                                cell.textField?.stringValue = strTime
                            }else{
                                cell.textField?.stringValue = arrFocusSummaryDic[row]["Duration in seconds"] ?? ""
                            }
                        }else{
                            cell.textField?.stringValue = arrFocusSummaryDic[row]["Duration in seconds"] ?? ""
                        }
                    }else if tableColumn == tblViewFocusSummary.tableColumns[3]{
                        cell.textField?.stringValue = arrFocusSummaryDic[row]["Work achieved"] ?? ""
                    }else if tableColumn == tblViewFocusSummary.tableColumns[4]{
                        cell.textField?.stringValue = arrFocusSummaryDic[row]["Distractions encountered"] ?? ""
                    }
                }
            }else if tableView == tblViewActivitySummaryTotal{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummaryTotal.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummaryTotal.tableColumns[1]{
                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["quantity"] ?? ""
                    }
                }
            }else if tableView == tblViewActivitySummaryAverage{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummaryAverage.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryAverageDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummaryAverage.tableColumns[1]{
                        cell.textField?.stringValue = arrActivitySummaryAverageDic[row]["quantity"] ?? ""
                        
                    }
                }
            }else if tableView == tblViewActivitySummaryDuration{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummaryDuration.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryDurationDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummaryDuration.tableColumns[1]{
                        
                        
                        if let duration = arrActivitySummaryDurationDic[row]["duration"]{
                            if let seconds = Int(duration){
                                let strTime = getStringTimeFromSeconds(seconds:seconds)
                                cell.textField?.stringValue = strTime
                            }
                        }else{
                            cell.textField?.stringValue = arrActivitySummaryDurationDic[row]["duration"] ?? ""
                        }
                        
                    }
                }
            }
            
            return cell
        }
        return NSTableCellView()
    }
    
    
}
