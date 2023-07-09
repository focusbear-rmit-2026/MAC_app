//
//  thirdVc.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 04/01/22.
//  .
//

import Cocoa
import WebKit

class thirdVc: NSViewController {
    
    
    @IBOutlet weak var btnNextGraph: cursorButton!
    @IBOutlet weak var btnPreviousGraph: cursorButton!
    @IBOutlet weak var webViewForVideo: WKWebView!
    @IBOutlet weak var btnReviseQuantity: Button!
    @IBOutlet weak var customViewContainer: NSView!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var stackViewGraph: NSStackView!
    @IBOutlet weak var btnMainCenterY: NSLayoutConstraint!
    @IBOutlet weak var webViewGraph1: WKWebView!
    @IBOutlet weak var webViewGraph2: WKWebView!
    @IBOutlet weak var boxBg: NSBox!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var boxBreathingFinished: NSBox!
    @IBOutlet weak var btnMain: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    
    var randomIntToRememberNextHabit: Int = 0
    var lastHabitIndex = -1
    var lastActivityIndex = -1// 
    
    //    var preloadFocusModesVcObj:preloadFocusModesVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSkipHabit.isHidden = true
        webViewForVideo.isHidden = true
        btnReviseQuantity.isHidden = true
        lblTimer.isHidden = true
        
        
        boxBreathingFinished.isHidden = true
        //        var string = "Hope you feel calmer. You can now personalise your morning routine by clicking on the icon <icon> on the top bar and choosing settings."
        //        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
        //            if let subTitle = dic.value(forKey: "welcomeEndMessage") as? String{
        //                string = subTitle
        //            }
        //        }
        var string = "I've set up a focus mode for you that has some common apps and URLs you might want to use when you're working. Open the settings from the Focus Bear menu to change what apps and URLs are allowed."
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if let subTitle = dic.value(forKey: "preloadFocusModesDoneText") as? String{
                string = subTitle
            }
        }
        lblSubTitle.attributedStringValue = attechIconWithString(text: string)
        
        btnReviseQuantity.title = "Revise Quantity"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnReviseQuantity.title = activityInfo.value(forKey: "buttonReviseQuantityText") as? String ?? btnReviseQuantity.title
        }
        
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Smile _Small")
            imgViewGif.animates = true
        }
    }
    @IBAction func btnNextGraphClicked(_ sender: Any) {
        currentGraphIndex += 1
        loadGraph(activityId: lastActivityIdForGraph, activityName: lastActivityNameForGraph, logQuantity: lastLogQuantityForGraph, logQuantityType: lastLogQuantityTypeForGraph, activityChoiceId: lastActivityChoiceIdForGraph, activityStartTime: lastActivityStartTimeForGraph, duration: lastActivityDurationForGraph, quantity: lastActivityQuantityForGraph)
    }
    
    @IBAction func btnPreviousGraphClicked(_ sender: Any) {
        currentGraphIndex -= 1
        loadGraph(activityId: lastActivityIdForGraph, activityName: lastActivityNameForGraph, logQuantity: lastLogQuantityForGraph, logQuantityType: lastLogQuantityTypeForGraph, activityChoiceId: lastActivityChoiceIdForGraph, activityStartTime: lastActivityStartTimeForGraph, duration: lastActivityDurationForGraph, quantity: lastActivityQuantityForGraph)
    }
    var currentGraphIndex = 0
    // date formate to pass iso 8601 formate mm-dd-yyyy
    var lastActivityIdForGraph = ""
    var lastActivityNameForGraph = ""
    var lastLogQuantityForGraph = false
    var lastLogQuantityTypeForGraph = ""
    var lastActivityChoiceIdForGraph:String?
    var lastActivityStartTimeForGraph:Date?
    var lastActivityDurationForGraph = ""
    var lastActivityQuantityForGraph = ""
    var logQuantityQuestionsForGraph:[quantityQuestion] = [quantityQuestion]()
    
    func loadGraph(activityId:String, activityName:String, logQuantity:Bool, logQuantityType:String, activityChoiceId:String?,  activityStartTime:Date?, duration:String, quantity:String){
        // here is logQuantity is only for avtivity
        
        lastActivityIdForGraph = activityId
        lastActivityNameForGraph = activityName
        lastLogQuantityForGraph = logQuantity
        lastLogQuantityTypeForGraph = logQuantityType
        lastActivityChoiceIdForGraph = activityChoiceId
        lastActivityStartTimeForGraph = activityStartTime
        lastActivityDurationForGraph = duration
        lastActivityQuantityForGraph = quantity
        
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        if logQuantity && lastActivityPerformedTime != nil{ // lastActivityPerformedTime qki jb direct incomplete habit start hoti h to pahle ka graph load hota h tb lastActivityPerformedTime ye var nil milta h
            btnReviseQuantity.isHidden = false
        }else{
            btnReviseQuantity.isHidden = true
        }
        var isSpecialHabitGoing = false
        var isSpecialActivityGoing = false
        if currentState == ._SPECIAL_ACTIVITY_{
            if timerViewcontrollerObj?.lastCurrentSpecialHabit != nil{
                isSpecialHabitGoing = true
            }else{
                isSpecialActivityGoing = true
            }
        }
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || isSpecialHabitGoing{
            var logType = ""
            if currentState == ._MORNING_HABIT_{
                logType = "morning routine"
            }else if currentState == ._EVENING_HABIT_{
                logType = "evening routine"
            }else if isSpecialHabitGoing{
                var isActivityFound = false
                for habit in arrAllDaysMorningHabits{
                    if habit.id == activityId{
                        isActivityFound = true
                        logType = "morning routine"
                        break;
                    }
                }
                
                if !isActivityFound{
                    for habit in arrAllDaysEveningHabits{
                        if habit.id == activityId{
                            isActivityFound = true
                            logType = "evening routine"
                            break;
                        }
                    }
                }
                
            }
            if graphOneMonthData != nil{
                var items = [[String : Any]]()
                let log_quantity_answers_stats = graphOneMonthData?.value(forKey: "log_quantity_answers_stats") as? [[String:Any]] ?? []
                
                
                var question = ""
                if logQuantity{
                    if log_quantity_answers_stats.count > currentGraphIndex{
                        items = log_quantity_answers_stats[currentGraphIndex]["items"] as? [[String:Any]] ?? []
                        if let questionDic = log_quantity_answers_stats[currentGraphIndex]["question"] as? NSDictionary{
                            question = questionDic.value(forKey: "question") as? String ?? ""
                        }
                    }
                }else{
                    items = graphOneMonthData?.value(forKey: "items") as? [[String:Any]] ?? []
                }
                
                
                
                if log_quantity_answers_stats.count-1 > currentGraphIndex{
                    btnNextGraph.isHidden = false
                }
                if currentGraphIndex != 0{
                    btnPreviousGraph.isHidden = false
                }
                var arrDic = [[String:Any]]()
                for item in items{
                    guard let date = item["date"] as? String else{
                        continue;
                    }
                    if let dateTime = getDateFromStringInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = item["summary"] ?? ""
                        newDic["Quantity Logged"] = item["summary"] ?? ""
                        arrDic.append(newDic)
                    }
                    
                }
                var currentQuantity:Double = 0
                
                if logQuantityQuestionsForGraph.count > currentGraphIndex{
                    currentQuantity = logQuantityQuestionsForGraph[currentGraphIndex].quantity
                }
                
                
                arrDic = arrDic.reversed()// bacuse we want to make struct just like csv, adn in csv entries are old to new
                
                if arrDic.count != 0{
                    let lastItem = arrDic.last!
                    
                    if let dateTime = activityStartTime{
                        
                        
                        let dateString = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        
                        if lastItem["dateString"] as? String ?? "" ==  dateString{
                            //                                arrDic[arrDic.count - 1] =
                            let lastDurationString = lastItem["Duration in seconds"] as? String ?? ""
                            let lastquantityString = lastItem["Quantity Logged"] as? String ?? ""
                            
                            
                            let lastDuration = Double(lastDurationString) ?? 0
                            
                            let lastQuantity = Double(lastquantityString) ?? 0
                            
                            
                            let finalDuration = (Double(duration) ?? 0) + lastDuration
                            let finalQuantity = currentQuantity + lastQuantity
                            
                            var newDic = [String:Any]()
                            newDic["date"] = dateTime
                            newDic["dateString"] = dateString
                            newDic["Duration in seconds"] = "\(finalDuration)"
                            newDic["Quantity Logged"] = "\(finalQuantity)"
                            arrDic[arrDic.count - 1] = newDic
                            
                            
                        }else{
                            var newDic = [String:Any]()
                            newDic["date"] = dateTime
                            newDic["dateString"] = dateString
                            newDic["Duration in seconds"] = duration
                            newDic["Quantity Logged"] = "\(currentQuantity)"
                            arrDic.append(newDic)
                        }
                        
                    }
                }else{
                    if let dateTime = activityStartTime{
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = duration
                        newDic["Quantity Logged"] = "\(currentQuantity)"
                        arrDic.append(newDic)
                    }
                }
                if question.isEmpty{
                    question = activityName
                }
                DispatchQueue.main.async {
                    self.loadHabitMonthlyGraphFromCsv(activityName: question, logQuantity: logQuantity, arrDic: arrDic)
                }
                
            }else{
                // no records
                DispatchQueue.main.async {
                    let arrDic = self.readCsv(activityName: activityName, logType: logType)
                    self.loadHabitMonthlyGraphFromCsv(activityName: activityName, logQuantity: logQuantity, arrDic: arrDic)
                }
                
            }
            
        }else if currentState == ._ACTIVITY_ || isSpecialActivityGoing{
            
            //print(graphOneDayData)
           // print("*****result****")
            if graphOneDayData != nil{
                let items = graphOneDayData as? [[String:Any]] ?? []
                var arrDic = [[String:Any]]()
                for item in items{
                    guard let date = item["start_time"] as? String else{
                        continue;
                    }
                    if let dateTime = getDateFromStringInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = item["duration_logged"]
                        newDic["Quantity Logged"] = item["quantity_logged"]
                        arrDic.append(newDic)
                    }
                    
                }
                
                
                arrDic = arrDic.reversed()//
                if let dateTime = activityStartTime{
                    var newDic = [String:Any]()
                    newDic["date"] = dateTime
                    newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                    newDic["Duration in seconds"] = duration
                    newDic["Quantity Logged"] = quantity
                    arrDic.append(newDic)
                }
                DispatchQueue.main.async {
                    self.loadBreakFirstGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                }
                
            }else if graphOneDayDataForQuantity != nil{
                
                
                var currentKey = ""
                
                if graphOneMonthData != nil{
                    let log_quantity_answers_stats = graphOneMonthData?.value(forKey: "log_quantity_answers_stats") as? [[String:Any]] ?? []
                    if currentGraphIndex < log_quantity_answers_stats.count{
                        currentKey = log_quantity_answers_stats[currentGraphIndex]["question_id"] as? String ?? ""
                    }
                }
              
                var currentQuantity:Double = 0
                
                if logQuantityQuestionsForGraph.count > currentGraphIndex{
                    currentQuantity = logQuantityQuestionsForGraph[currentGraphIndex].quantity
                }
                
                let items = graphOneDayDataForQuantity![currentKey] as? [[String:Any]] ?? []
                var arrDic = [[String:Any]]()
                for item in items{
                    guard let date = item["date_logged"] as? String else{
                        continue;
                    }
                    if let dateTime = getDateFromStringInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = item["duration_logged"]
                        newDic["Quantity Logged"] = "\(item["logged_value"] as? Double ?? 0)"
                        arrDic.append(newDic)
                    }
                    
                }
                
                
//                arrDic = arrDic.reversed()//
                if let dateTime = activityStartTime{
                    var newDic = [String:Any]()
                    newDic["date"] = dateTime
                    newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                    newDic["Duration in seconds"] = duration
                    newDic["Quantity Logged"] = "\(currentQuantity)"
                    arrDic.append(newDic)
                }
                DispatchQueue.main.async {
                    self.loadBreakFirstGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                }
                
            }else{
                // no records
                DispatchQueue.main.async {
                    let arrDic = self.readCsvForTodayOnly(activityName: activityName, logType: "break")
                    self.loadBreakFirstGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                }
                
            }
            
            
            print(graphOneMonthData)
            print("*****result****")
            // let stat_type = dic?.value(forKey: "stat_type") as? String ?? ""  //quantity // duration
            if graphOneMonthData != nil{
                
                var items = [[String : Any]]()
                
                let log_quantity_answers_stats = graphOneMonthData?.value(forKey: "log_quantity_answers_stats") as? [[String:Any]] ?? []
                
//                let items = log_quantity_answers_stats[currentGraphIndex]["items"] as? [[String:Any]] ?? []
                var question = ""
                if logQuantity{
                    if log_quantity_answers_stats.count > currentGraphIndex{
                        items = log_quantity_answers_stats[currentGraphIndex]["items"] as? [[String:Any]] ?? []
                        if let questionDic = log_quantity_answers_stats[currentGraphIndex]["question"] as? NSDictionary{
                            question = questionDic.value(forKey: "question") as? String ?? ""
                        }
                    }
                }else{
                    items = graphOneMonthData?.value(forKey: "items") as? [[String:Any]] ?? []
                }
                
                
                
                if log_quantity_answers_stats.count-1 > currentGraphIndex{
                    btnNextGraph.isHidden = false
                }
                if currentGraphIndex != 0{
                    btnPreviousGraph.isHidden = false
                }
                var arrDic = [[String:Any]]()
                for item in items{
                    guard let date = item["date"] as? String else{
                        continue;
                    }
                    if let dateTime = getDateFromStringInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"){
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = item["summary"] ?? ""
                        newDic["Quantity Logged"] = item["summary"] ?? ""
                        arrDic.append(newDic)
                    }
                    
                }
                var currentQuantity:Double = 0
                
                if logQuantityQuestionsForGraph.count > currentGraphIndex{
                    currentQuantity = logQuantityQuestionsForGraph[currentGraphIndex].quantity
                }
                
                arrDic = arrDic.reversed()// bacuse we want to make struct just like csv, adn in csv entries are old to new
                
                if arrDic.count != 0{
                    let lastItem = arrDic.last!
                    
                    if let dateTime = activityStartTime{
                        
                        
                        let dateString = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        
                        if lastItem["dateString"] as? String ?? "" ==  dateString{
                            //                                arrDic[arrDic.count - 1] =
                            let lastDurationString = lastItem["Duration in seconds"] as? String ?? ""
                            let lastquantityString = lastItem["Quantity Logged"] as? String ?? ""
                            
                            
                            let lastDuration = Double(lastDurationString) ?? 0
                            
                            let lastQuantity = Double(lastquantityString) ?? 0
                            
                            
                            let finalDuration = (Double(duration) ?? 0) + lastDuration
                            let finalQuantity = currentQuantity + lastQuantity//(Double(quantity) ?? 0) + lastQuantity
                            var newDic = [String:Any]()
                            
                            if logQuantityType == "AVG"{
                                
                                
                                
                                var arrDuration = [Double]()
                                var arrQuantity = [Double]()
                                if let items = graphOneDayData as? [[String:Any]]{
                                    for item in items{
                                        arrDuration.append(Double(item["duration_logged"] as? String ?? "") ?? 0)
                                        arrQuantity.append(Double(item["quantity_logged"] as? String ?? "") ?? 0)
                                    }
                                    arrDuration.append(Double(duration) ?? 0)
                                    arrQuantity.append(currentQuantity)//Double(quantity) ?? 0)
                                    
                                    
                                    let sumDuration = arrDuration.reduce(0, +)
                                    let sumQuantity = arrQuantity.reduce(0, +)
                                    
                                    let avgQuantity = sumQuantity / Double(arrQuantity.count)
                                    
                                    newDic["date"] = dateTime
                                    newDic["dateString"] = dateString
                                    newDic["Duration in seconds"] = "\(sumDuration)"
                                    newDic["Quantity Logged"] = "\(avgQuantity)"
                                    
                                }else if graphOneDayDataForQuantity != nil{
                                    var currentKey = ""
                                    if graphOneMonthData != nil{
                                        let log_quantity_answers_stats = graphOneMonthData?.value(forKey: "log_quantity_answers_stats") as? [[String:Any]] ?? []
                                        if currentGraphIndex < log_quantity_answers_stats.count{
                                            currentKey = log_quantity_answers_stats[currentGraphIndex]["question_id"] as? String ?? ""
                                        }
                                    }
                                    let items = graphOneDayDataForQuantity![currentKey] as? [[String:Any]] ?? []
                                    
                                    for item in items{
                                        arrDuration.append(Double(item["duration_logged"] as? String ?? "") ?? 0)
                                        arrQuantity.append(item["logged_value"] as? Double ?? 0)
                                    }
                                    arrDuration.append(Double(duration) ?? 0)
                                    arrQuantity.append(currentQuantity)//Double(quantity) ?? 0)
                                    
                                    
                                    let sumDuration = arrDuration.reduce(0, +)
                                    let sumQuantity = arrQuantity.reduce(0, +)
                                    
                                    let avgQuantity = sumQuantity / Double(arrQuantity.count)
                                    
                                    newDic["date"] = dateTime
                                    newDic["dateString"] = dateString
                                    newDic["Duration in seconds"] = "\(sumDuration)"
                                    newDic["Quantity Logged"] = "\(avgQuantity)"
                                    
                                }else{
                                    newDic["date"] = dateTime
                                    newDic["dateString"] = dateString
                                    newDic["Duration in seconds"] = "\(finalDuration)"
                                    newDic["Quantity Logged"] = "\(finalQuantity)"
                                }
                            }else{
                                newDic["date"] = dateTime
                                newDic["dateString"] = dateString
                                newDic["Duration in seconds"] = "\(finalDuration)"
                                newDic["Quantity Logged"] = "\(finalQuantity)"
                            }
                            
                            
                            arrDic[arrDic.count - 1] = newDic
                            
                            
                        }else{
                            var newDic = [String:Any]()
                            newDic["date"] = dateTime
                            newDic["dateString"] = dateString
                            newDic["Duration in seconds"] = duration
                            newDic["Quantity Logged"] = "\(currentQuantity)"//quantity
                            arrDic.append(newDic)
                        }
                        
                    }
                }else{
                    if let dateTime = activityStartTime{
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = duration
                        newDic["Quantity Logged"] = "\(currentQuantity)"//quantity
                        arrDic.append(newDic)
                    }
                }
                
                if question.isEmpty{
                    question = activityName
                }
                DispatchQueue.main.async {
                    self.loadBreakSecondGraphFromCsv(activityName: question, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                }
                
            }else{
                // no records
                DispatchQueue.main.async {
                    let arrDic = self.readCsv(activityName: activityName, logType: "break")
                    self.loadBreakSecondGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                }
                
            }
            
        }
        
    }
    
    func loadHabitMonthlyGraphFromCsv(activityName:String, logQuantity:Bool, arrDic: [[String : Any]]){
        stackViewGraph.isHidden = false
        webViewGraph1.isHidden = false
        webViewGraph2.isHidden = true
        btnMainCenterY.constant = 100
        webViewForVideo.isHidden = true
        if let graphDayspath = Bundle.main.path(forResource: "GraphDays", ofType: "html"), let graphDaysDurationpath = Bundle.main.path(forResource: "GraphDaysDuration", ofType: "html"){
            
            
            let graphDaysUrl = "file://\(graphDayspath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            let graphDaysDurationUrl = "file://\(graphDaysDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_{
                
                //                let  fileURL = URL(string: graphDaysUrl)
                
                
                var fileURL: URL?
                
                if logQuantity{
                    fileURL = URL(string: graphDaysUrl)
                }else{
                    fileURL = URL(string: graphDaysDurationUrl)
                }
                
                
                webViewGraph1.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
                
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                
                let previousMonth = Calendar.current.date(byAdding: .day, value: -31, to: startDate) ?? startDate
                
                
                
                print(arrDic)
                var arrDuration = [String]()
                var arrDateString = [String]()
                var arrDate = [Date]()
                var isDataWeekly = false
                var arrForMaxValue = [Double]()
                
                if let dic = arrDic.first{
                    let date = dic["date"] as! Date
                    let sevenDaysBeforeDate = Calendar.current.date(byAdding: .day, value: -6, to: startDate) ?? startDate
                    if date.compare(sevenDaysBeforeDate) == .orderedDescending {
                        isDataWeekly = true
                    }
                }
                
                
                
                var lastDateAdded = previousMonth // qki pure 1 month ka data chahiye isiliye aaj ki date se -32  se kiya h taki 31 din ka data nilana bhake hi 15 din ka data ho to usse phle ka data fake cretae krenge
                for dic in arrDic{
                    let date = dic["date"] as! Date
                    let stringDate = dic["dateString"] as? String ?? ""
                    let duration = dic["Duration in seconds"] as? String ?? ""// duration minut mai chahiye lekin string mI convert krke
                    let quantity = dic["Quantity Logged"] as? String ?? ""
                    //  if arrDate.isEmpty{
                    //      arrDate.append(date)
                    //      arrDateString.append(stringDate)
                    //      arrDuration.append("\(Int((Int(duration) ?? 0)/60))")
                    //  }else{
                    
                    if date.compare(lastDateAdded) == .orderedDescending {
                        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
                        let calendarLastDate = Calendar.current.dateComponents([.day, .year, .month], from: lastDateAdded)
                        if calendarDate.day != nil && calendarLastDate.day != nil{
                            let diffInDays = date.interval(ofComponent: .day, fromDate: lastDateAdded)//Calendar.current.dateComponents([.day], from: lastDateAdded, to: date).day ?? 1
                            
                            if diffInDays == 1{
                                arrDate.append(date)
                                arrDateString.append(stringDate)
                                var quantityOrDuration:Double = 0
                                
                                if logQuantity{
                                    quantityOrDuration = Double(quantity) ?? 0
                                }else{
                                    quantityOrDuration = Double(duration) ?? 0
                                }
                                arrForMaxValue.append(quantityOrDuration)
                                arrDuration.append("\(quantityOrDuration)")
                                lastDateAdded = arrDate.last!
                            }else{
                                let missinDayCount = diffInDays - 1
                                
                                if missinDayCount > 0 {
                                    for _ in 1...missinDayCount{
                                        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDateAdded){
                                            let newStringDate = getStringFromDate(date: newDate, dateFormat: "MM-dd-yyyy")
                                            if newStringDate != stringDate{
                                                arrDate.append(newDate)
                                                arrDateString.append(newStringDate)
                                                arrDuration.append("")
                                                arrForMaxValue.append(0)
                                                lastDateAdded = arrDate.last!
                                            }
                                        }
                                    }
                                    
                                    
                                    arrDate.append(date)
                                    arrDateString.append(stringDate)
                                    
                                    var quantityOrDuration:Double = 0
                                    
                                    if logQuantity{
                                        quantityOrDuration = Double(quantity) ?? 0
                                    }else{
                                        quantityOrDuration = Double(duration) ?? 0
                                    }
                                    arrForMaxValue.append(quantityOrDuration)
                                    arrDuration.append("\(quantityOrDuration)")
                                    lastDateAdded = arrDate.last!
                                }
                                
                                
                            }
                        }
                        
                    }else{// else mai kabhi aayga nahi qki morning routine ak bar hiu aata hai fir bhi likh rhe hai
                        //                                arrDate.append(date)
                        //                                arrDateString.append(dic["dateString"] as! String)
                        //                                arrDuration.append(dic["Duration in seconds"] as! String)
                    }
                    // }
                }
                print(arrDateString)
                if arrDateString.count == 30{/// adding fake date
                    let firstDate = arrDate.first!
                    let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
                    let newStringDate = getStringFromDate(date: previousDate, dateFormat: "MM-dd-yyyy")
                    arrDate.insert(previousDate, at: 0)
                    arrDateString.insert(newStringDate, at: 0)
                    arrDuration.insert("", at: 0)
                }
                
                //                var arrData = []
                var maxInHabitsGraph = arrForMaxValue.max() ?? 0
                var minInSecondGraph = arrForMaxValue.min() ?? 0
                
                if maxInHabitsGraph < 50{
                    maxInHabitsGraph = maxInHabitsGraph + 5
                }else if maxInHabitsGraph < 99{
                    maxInHabitsGraph = maxInHabitsGraph + 10
                }else if maxInHabitsGraph < 999{
                    maxInHabitsGraph = maxInHabitsGraph + 20
                }else if maxInHabitsGraph < 9999{
                    maxInHabitsGraph = maxInHabitsGraph + 50
                }else {
                    maxInHabitsGraph = maxInHabitsGraph + 200
                }
                
                if minInSecondGraph < 50{
                    minInSecondGraph = minInSecondGraph - 5
                }else if minInSecondGraph < 99{
                    minInSecondGraph = minInSecondGraph - 10
                }else if minInSecondGraph < 999{
                    minInSecondGraph = minInSecondGraph - 20
                }else if minInSecondGraph < 9999{
                    minInSecondGraph = minInSecondGraph - 50
                }else {
                    minInSecondGraph = minInSecondGraph - 200
                }
                
                if minInSecondGraph < 0{
                    minInSecondGraph = 0
                }
                
                //                maxInHabitsGraph = roundOffValue(number:maxInHabitsGraph)//
                var labelYVal = ""
                if logQuantity{
                    labelYVal = graphQuantityText
                }else{
                    labelYVal = graphMinutesText
                }
                var type = ""
                if isDataWeekly{
                    type = "weekly"
                }else{
                    type = "monthly"
                }
                let json = [ "label":"\(activityName)" , "labelX":graphDateText, "labelY":labelYVal, "data": arrDuration, "type":type, "max":maxInHabitsGraph, "min":minInSecondGraph] as [String : Any]
                addGraphsLog(text: "\(json)")
                do {
                    let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
                    if let str = String(data: data, encoding: String.Encoding.utf8){
                        print(str)
                        print("morning habit graph str")
                        
                        let script = "getData(\(str));"
                        
                        
                        DispatchQueue.global().async {
                            if lastActivityPerformedTime == nil{ //iska mtlb app start hotehi koi morning habit hui thi iska mtlb morning habit k bich mai hi app band ho gai thi ya fir dusre system per app start kreke baki habit yha start ki hai to old habit ka start time ni mika to usleep jyada dala qki graph load ni ho rha tha
                                usleep(630000)
                                isHabitGraphLoadedFirstTime = true
                            }else{
                                if isHabitGraphLoadedFirstTime{
                                    usleep(500000)
                                }else{
                                    usleep(720000)
                                    isHabitGraphLoadedFirstTime = true
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                    print(html)
                                    if error != nil{
                                        print("morning habit str error is *************** \(error)")
                                    }else{
                                        print("morning habit str success ***************")
                                    }
                                })
                            }
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
                return;
                
                
            }
        }
    }
    
    //    func loadBreakGraphFromCsv(activityName:String, logQuantity:Bool, logQuantityType:String){
    //
    //        stackViewGraph.isHidden = false
    //
    //        btnMainCenterY.constant = 100
    //        if let graphDayspath = Bundle.main.path(forResource: "GraphDays", ofType: "html"), let graphTimepath = Bundle.main.path(forResource: "GraphTime", ofType: "html"), let graphGraphTimeDurationpath = Bundle.main.path(forResource: "GraphTimeDuration", ofType: "html"), let graphDaysDurationpath = Bundle.main.path(forResource: "GraphDaysDuration", ofType: "html"){
    //            print(graphDayspath)
    //            let graphDaysUrl = "file://\(graphDayspath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    //            let graphDaysDurationUrl = "file://\(graphDaysDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    //            let graphTimeUrl = "file://\(graphTimepath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    //            let graphTimeDurationUrl = "file://\(graphGraphTimeDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    //            webViewGraph1.isHidden = false
    //            webViewGraph2.isHidden = false
    //
    //            //                var  fileURL = URL(string: graphDaysUrl)
    //
    //            var fileURL: URL?
    //
    //            if logQuantity{
    //                fileURL = URL(string: graphDaysUrl)
    //            }else{
    //                fileURL = URL(string: graphDaysDurationUrl)
    //            }
    //
    //
    //            webViewGraph2.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
    //
    //
    //
    //            let arrDic = readCsv(activityName: activityName, logType: "break")
    //            print(arrDic)// 1 month data
    //
    //            // **********for graph second // monthly*******
    //            var arrGraph1DurationOrQuantity = [String]()
    //
    //            var arrGraph1DateString = [String]()
    //            var arrGraph1Date = [Date]()
    //            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    //            let shutoffTime = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: startTime!.second, of: Date())!
    //            let previousMonth = Calendar.current.date(byAdding: .day, value: -31, to: startDate) ?? startDate
    //            var isDataWeekly = false
    //            var lastDateAdded = previousMonth// qki pure 1 month ka data chahiye isiliye aaj ki date se -31  se kiya h taki 31 din ka data nilana bhake hi 15 din ka data ho to usse phle ka data fake cretae krenge
    //
    //            if let dic = arrDic.first{
    //                let date = dic["date"] as! Date
    //                let sevenDaysBeforeDate = Calendar.current.date(byAdding: .day, value: -6, to: startDate) ?? startDate
    //                if date.compare(sevenDaysBeforeDate) == .orderedDescending {
    //                    isDataWeekly = true
    //                }
    //            }
    //            //  *************** creating 30 days data *****************    //
    //            let arrDataForGraph = NSMutableDictionary()
    //            for dic in arrDic{
    //                if let date = dic["date"] as? Date{
    //                    // if date.compare(lastDateAdded) == .orderedDescending {// start ate k baad ka ho to
    //                    // let date = dic["date"] as! Date
    //                    let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
    //                    let calendarLastDate = Calendar.current.dateComponents([.day, .year, .month], from: lastDateAdded)
    //
    //
    //                    if calendarDate.day != nil && calendarLastDate.day != nil{
    //                        let stringDate = dic["dateString"] as! String
    //
    //                        let diffInDays = date.interval(ofComponent: .day, fromDate: lastDateAdded)
    //
    //                        //  stringDate = getStringFromDate(date: date, dateFormat: "HH:mm:ss")
    //                        let duration = dic["Duration in seconds"] as! String
    //                        let quantity = dic["Quantity Logged"] as! String
    //
    //
    //
    //                        if diffInDays == 1{
    //                            var quantityOrDuration:Double = 0
    //                            if logQuantity{
    //                                quantityOrDuration = Double(quantity) ?? 0
    //                            }else{
    //                                quantityOrDuration = Double(duration) ?? 0
    //                            }
    //                            if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
    //                                var arr = [Double]()
    //                                if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
    //                                    arr = nval
    //                                }
    //                                arr.append(quantityOrDuration)
    //                                data["arrQuantityOrDuration"] = arr
    //                                arrDataForGraph[stringDate] = data
    //                                lastDateAdded = date
    //
    //                            }else{
    //                                let arr = [quantityOrDuration]
    //                                let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
    //                                arrDataForGraph[stringDate] = ndic
    //                                lastDateAdded = date
    //                            }
    //                        }else{
    //                            let missinDayCount = diffInDays - 1
    //                            if missinDayCount > 0 {
    //                                for _ in 1...missinDayCount{
    //                                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDateAdded){
    //                                        let newStringDate = getStringFromDate(date: newDate, dateFormat: "MM-dd-yyyy")
    //                                        if newStringDate != stringDate{
    //                                            let arr = [0]
    //                                            let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":newDate]
    //                                            arrDataForGraph[newStringDate] = ndic
    //                                            lastDateAdded = newDate
    //                                        }
    //                                    }
    //                                }
    //
    //                                var quantityOrDuration:Double = 0
    //                                if logQuantity{
    //                                    quantityOrDuration = Double(quantity) ?? 0
    //                                }else{
    //                                    quantityOrDuration = Double(duration) ?? 0
    //                                }
    //                                if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
    //                                    var arr = [Double]()
    //                                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
    //                                        arr = nval
    //                                    }
    //                                    arr.append(quantityOrDuration)
    //                                    data["arrQuantityOrDuration"] = arr
    //                                    arrDataForGraph[stringDate] = data
    //                                    lastDateAdded = date
    //
    //                                }else{
    //                                    let arr = [quantityOrDuration]
    //                                    let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
    //                                    arrDataForGraph[stringDate] = ndic
    //                                    lastDateAdded = date
    //                                }
    //
    //                            }
    //
    //                            if diffInDays == 0{
    //                                var quantityOrDuration:Double = 0
    //                                if logQuantity{
    //                                    quantityOrDuration = Double(quantity) ?? 0
    //                                }else{
    //                                    quantityOrDuration = Double(duration) ?? 0
    //                                }
    //                                if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
    //                                    var arr = [Double]()
    //                                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
    //                                        arr = nval
    //                                    }
    //                                    arr.append(quantityOrDuration)
    //                                    data["arrQuantityOrDuration"] = arr
    //                                    arrDataForGraph[stringDate] = data
    //                                    lastDateAdded = date
    //
    //                                }else{
    //                                    let arr = [quantityOrDuration]
    //                                    let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
    //                                    arrDataForGraph[stringDate] = ndic
    //                                    lastDateAdded = date
    //                                }
    //                            }
    //                        }
    //                    }
    //                    //}
    //                }
    //
    //            }
    //            //  **********************************************  //
    //
    //            var arrForMaxValueInSecondGraph = [Double]()
    //            var arrGraphDictionary = [[String:Any]]()
    //            for key in arrDataForGraph.allKeys as? [String] ?? []{
    //
    //                var arrQuantity = [Double]()
    //                if let data = arrDataForGraph.value(forKey: key) as? NSMutableDictionary{
    //                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
    //                        arrQuantity = nval
    //                    }
    //                    let sum = arrQuantity.reduce(0, +)
    //                    var finalVal:Double = sum //default sum
    //                    if logQuantity{
    //                        if logQuantityType == "SUM"{
    //                            finalVal = sum
    //                        }else if logQuantityType == "AVG"{
    //                            finalVal = sum/Double(arrQuantity.count)
    //                        }
    //                    }else{
    //                        finalVal = sum
    //                    }
    //                    arrForMaxValueInSecondGraph.append(finalVal)
    //                    let newStringDate = getStringFromDate(date: data.value(forKey: "date") as? Date ?? Date(), dateFormat: "yyyy-MM-dd")
    //                    let date = data.value(forKey: "date") as? Date ?? Date()
    //                    let dic = ["date":date, "stringDate":newStringDate, "value":"\(finalVal)"] as [String : Any]
    //                    arrGraphDictionary.append(dic)
    //                }
    //            }
    //
    //            arrGraphDictionary.sort { ($0["date"] as! Date).compare($1["date"] as! Date) == .orderedAscending }
    //            if arrGraphDictionary.count == 30{/// adding fake date for making 31 days
    //                let firstDic = arrGraphDictionary.first!
    //                let firstDate = firstDic["date"] as? Date ?? Date()
    //                let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
    //                let newStringDate = getStringFromDate(date: previousDate, dateFormat: "yyyy-MM-dd")
    //
    //                let dic = ["date":previousDate, "stringDate":newStringDate, "value":"0"] as [String : Any]
    //                arrGraphDictionary.insert(dic, at: 0)
    //            }
    //            for graphData in arrGraphDictionary{
    //                arrGraph1Date.append(graphData["date"] as? Date ?? Date())
    //                arrGraph1DateString.append(graphData["stringDate"] as? String ?? "")
    //                arrGraph1DurationOrQuantity.append(graphData["value"] as? String ?? "")
    //            }
    //
    //
    //            print(arrGraphDictionary)
    //
    //            var maxInSecondGraph = arrForMaxValueInSecondGraph.max() ?? 0
    //
    //
    //
    //
    //
    //            var labelYVal = ""
    //            if logQuantity{
    //                labelYVal = "Quantity"
    //            }else{
    //                labelYVal = "Minutes"
    //            }
    //
    //            if maxInSecondGraph < 99{
    //                maxInSecondGraph = maxInSecondGraph + 10
    //            }else if maxInSecondGraph < 9999{
    //                maxInSecondGraph = maxInSecondGraph + 100
    //            }else {
    //                maxInSecondGraph = maxInSecondGraph + 1000
    //            }
    //
    //            maxInSecondGraph = roundOffValue(number:maxInSecondGraph)
    //            var type = ""
    //            if isDataWeekly{
    //                type = "weekly"
    //            }else{
    //                type = "monthly"
    //            }
    //            let json = [ "label":"\(activityName)" , "labelX":"Date", "labelY":labelYVal, "data": arrGraph1DurationOrQuantity, "type":type, "max":maxInSecondGraph] as [String : Any]
    //            do {
    //                let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
    //                if let str = String(data: data, encoding: String.Encoding.utf8){
    //                    print(str)
    //
    //
    //                    let script = "getData(\(str));"
    //
    //
    //                    DispatchQueue.global().async {
    //                        usleep(500000)//0.5
    //                        DispatchQueue.main.async {
    //                            self.webViewGraph2?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
    //                                print(html)
    //                            })
    //                        }
    //                    }
    //                }
    //            } catch let error as NSError {
    //                print(error)
    //            }
    //
    //
    //            // *****************************graph first****************************************
    //            var graphUrlForDay: URL?
    //
    //            if logQuantity{
    //                graphUrlForDay = URL(string: graphTimeUrl)
    //            }else{
    //                graphUrlForDay = URL(string: graphTimeDurationUrl)
    //            }
    //
    //            webViewGraph1.loadFileURL(graphUrlForDay!, allowingReadAccessTo: graphUrlForDay!)
    //
    //            var arrGraph2Duration = [String]()
    //
    //            var arrGraph2DateString = [String]()
    //            var arrGraph2Date = [Date]()
    //
    //            var arrForMaxValue = [Double]()
    //
    //
    //            for dic in arrDic{
    //                // if let date = dic["date"] as? Date{
    //
    //                let date = dic["date"] as! Date
    //                if date.compare(startDate) == .orderedDescending {
    //                    let stringDate = dic["dateString"] as! String
    //
    //                    let duration = dic["Duration in seconds"] as! String
    //                    let quantity = dic["Quantity Logged"] as! String
    //                    if logQuantity{
    //                        arrGraph2Date.append(date)
    //                        let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
    //                        arrGraph2DateString.append(newStringDate)
    //                        arrGraph2Duration.append(quantity)
    //                        let doubleQuantithy = Double(quantity) ?? 0
    //                        arrForMaxValue.append(doubleQuantithy)
    //                    }else{
    //                        arrGraph2Date.append(date)
    //                        let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
    //                        arrGraph2DateString.append(newStringDate)
    //                        let doubleDuration = Double(duration) ?? 0
    //                        arrGraph2Duration.append("\(doubleDuration)")
    //                        arrForMaxValue.append(doubleDuration)
    //                    }
    //                }
    //                //}
    //            }
    //
    //            var max = arrForMaxValue.max() ?? 0
    //            //              adding start and end time in arrGraph2Duration
    //            arrGraph2DateString.insert(getStringFromDate(date: startDate, dateFormat: "yyyy-MM-dd HH:mm:ss"), at: 0)
    //            arrGraph2DateString.append(getStringFromDate(date: shutoffTime, dateFormat: "yyyy-MM-dd HH:mm:ss"))
    //
    //            //              adding Blank values for start and end time in arrGraph2Duration
    //            arrGraph2Duration.insert(" ", at: 0)
    //            arrGraph2Duration.append(" ")
    //
    //            //"yyyy-MM-dd HH:mm:ss"
    //            //                var labelVal = 0
    //            //                var labelYVal = ""
    //            if logQuantity{
    //                labelYVal = "Quantity"
    //            }else{
    //                labelYVal = "Minutes"
    //            }
    //
    //            if max < 99{
    //                max = max + 10
    //            }else if max < 9999{
    //                max = max + 100
    //            }else {
    //                max = max + 1000
    //            }
    //            let jsonForDay = ["label":activityName , "labelX":"Time", "labelY":labelYVal, "TimeValues":arrGraph2DateString, "data": arrGraph2Duration, "max":max] as [String : Any]
    //
    //
    //
    //            do {
    //                let data = try (JSONSerialization.data(withJSONObject: jsonForDay, options: .prettyPrinted))
    //                if let str = String(data: data, encoding: String.Encoding.utf8){
    //                    print(str)
    //
    //
    //                    let script = "getData(\(str));"
    //
    //
    //                    DispatchQueue.global().async {
    //                        usleep(500000)//0.5
    //                        DispatchQueue.main.async {
    //                            self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
    //                                print(html)
    //                            })
    //                        }
    //                    }
    //                }
    //            } catch let error as NSError {
    //                print(error)
    //            }
    //        }
    //
    //    }
    func loadBreakFirstGraphFromCsv(activityName:String, logQuantity:Bool, logQuantityType:String, arrDic: [[String : Any]]){
        
        stackViewGraph.isHidden = false
        
        btnMainCenterY.constant = 100
        webViewForVideo.isHidden = true
        if let graphTimepath = Bundle.main.path(forResource: "GraphTime", ofType: "html"), let graphGraphTimeDurationpath = Bundle.main.path(forResource: "GraphTimeDuration", ofType: "html"){
            
            
            let graphTimeUrl = "file://\(graphTimepath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            let graphTimeDurationUrl = "file://\(graphGraphTimeDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            webViewGraph1.isHidden = false
            
            
            
            
            
            
            
            
            //            let arrDic = readCsv(activityName: activityName, logType: "break")
            print(arrDic)// 1 month data
            
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            var shutoffTime = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: startTime!.second, of: Date())!
            
            let currentDate = Date()
            if currentDate.compare(shutoffTime) == .orderedDescending{//>
                shutoffTime = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate
            }
            
            
            
            
            // *****************************graph first****************************************
            var graphUrlForDay: URL?
            
            if logQuantity{
                graphUrlForDay = URL(string: graphTimeUrl)
            }else{
                graphUrlForDay = URL(string: graphTimeDurationUrl)
            }
            
            webViewGraph1.loadFileURL(graphUrlForDay!, allowingReadAccessTo: graphUrlForDay!)
            
            var arrGraph2Duration = [String]()
            
            var arrGraph2DateString = [String]()
            var arrGraph2Date = [Date]()
            
            var arrForMaxValue = [Double]()
            
            
            for dic in arrDic{
                // if let date = dic["date"] as? Date{
                
                let date = dic["date"] as! Date
                if date.compare(startDate) == .orderedDescending {
                    // let stringDate = dic["dateString"] as! String
                    
                    let duration = dic["Duration in seconds"] as? String ?? ""
                    let quantity = dic["Quantity Logged"] as? String ?? ""
                    if logQuantity{
                        arrGraph2Date.append(date)
                        let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
                        arrGraph2DateString.append(newStringDate)
                        arrGraph2Duration.append(quantity)
                        let doubleQuantithy = Double(quantity) ?? 0
                        arrForMaxValue.append(doubleQuantithy)
                    }else{
                        arrGraph2Date.append(date)
                        let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
                        arrGraph2DateString.append(newStringDate)
                        let doubleDuration = Double(duration) ?? 0
                        arrGraph2Duration.append("\(doubleDuration)")
                        arrForMaxValue.append(doubleDuration)
                    }
                }
                //}
            }
            
            var max = arrForMaxValue.max() ?? 0
            //              adding start and end time in arrGraph2Duration
            arrGraph2DateString.insert(getStringFromDate(date: startDate, dateFormat: "yyyy-MM-dd HH:mm:ss"), at: 0)
            arrGraph2DateString.append(getStringFromDate(date: shutoffTime, dateFormat: "yyyy-MM-dd HH:mm:ss"))
            
            //              adding Blank values for start and end time in arrGraph2Duration
            arrGraph2Duration.insert(" ", at: 0)
            arrGraph2Duration.append(" ")
            
            
            var labelYVal = ""
            if logQuantity{
                labelYVal = graphQuantityText
            }else{
                labelYVal = graphMinutesText
            }
            
            if max < 50{
                max = max + 2
            }else if max < 99{
                max = max + 5
            }else if max < 999{
                max = max + 20
            }else if max < 9999{
                max = max + 50
            }else {
                max = max + 200
            }
            let min:Double = 0
            let jsonForDay = ["label":activityName , "labelX":graphTimeText, "labelY":labelYVal, "TimeValues":arrGraph2DateString, "data": arrGraph2Duration, "max":max, "min":min] as [String : Any]
            
            addGraphsLog(text: "\(jsonForDay)")
            
            do {
                let data = try (JSONSerialization.data(withJSONObject: jsonForDay, options: .prettyPrinted))
                if let str = String(data: data, encoding: String.Encoding.utf8){
                    print(str)
                    print("str1 is *************** str1")
                    
                    let script = "getData(\(str));"
                    
                    
                    DispatchQueue.global().async {
                        //                        usleep(500000)//0.5//
                        
                        if isBreakDayGraphLoadedFirstTime{
                            usleep(500000)
                        }else{
                            usleep(720000)
                            isBreakDayGraphLoadedFirstTime = true
                        }
                        DispatchQueue.main.async {
                            self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                print(html)
                                if error != nil{
                                    print("str1 error is *************** \(error)")
                                }else{
                                    print("str1 success ***************")
                                }
                            })
                        }
                    }
                }
            } catch let error as NSError {
                print(error)
            }
        }
        
    }
    func loadBreakSecondGraphFromCsv(activityName:String, logQuantity:Bool, logQuantityType:String, arrDic: [[String : Any]]){
        
        stackViewGraph.isHidden = false
        
        btnMainCenterY.constant = 100
        webViewForVideo.isHidden = true
        if let graphDayspath = Bundle.main.path(forResource: "GraphDays", ofType: "html"), let graphTimepath = Bundle.main.path(forResource: "GraphTime", ofType: "html"), let graphGraphTimeDurationpath = Bundle.main.path(forResource: "GraphTimeDuration", ofType: "html"), let graphDaysDurationpath = Bundle.main.path(forResource: "GraphDaysDuration", ofType: "html"){
            print(graphDayspath)
            let graphDaysUrl = "file://\(graphDayspath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            let graphDaysDurationUrl = "file://\(graphDaysDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            webViewGraph2.isHidden = false
            
            //                var  fileURL = URL(string: graphDaysUrl)
            
            var fileURL: URL?
            
            if logQuantity{
                fileURL = URL(string: graphDaysUrl)
            }else{
                fileURL = URL(string: graphDaysDurationUrl)
            }
            
            
            webViewGraph2.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
            
            
            
            //            let arrDic = readCsv(activityName: activityName, logType: "break")
            print(arrDic)// 1 month data
            
            // **********for graph second // monthly*******
            var arrGraph1DurationOrQuantity = [String]()
            
            var arrGraph1DateString = [String]()
            var arrGraph1Date = [Date]()
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutoffTime = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: startTime!.second, of: Date())!
            let previousMonth = Calendar.current.date(byAdding: .day, value: -31, to: startDate) ?? startDate
            var isDataWeekly = false
            var lastDateAdded = previousMonth// qki pure 1 month ka data chahiye isiliye aaj ki date se -31  se kiya h taki 31 din ka data nilana bhake hi 15 din ka data ho to usse phle ka data fake cretae krenge
            
            if let dic = arrDic.first{
                let date = dic["date"] as! Date
                let sevenDaysBeforeDate = Calendar.current.date(byAdding: .day, value: -6, to: startDate) ?? startDate
                if date.compare(sevenDaysBeforeDate) == .orderedDescending {
                    isDataWeekly = true
                }
            }
            //  *************** creating 30 days data *****************    //
            let arrDataForGraph = NSMutableDictionary()
            for dic in arrDic{
                if let date = dic["date"] as? Date{
                    // if date.compare(lastDateAdded) == .orderedDescending {// start ate k baad ka ho to
                    // let date = dic["date"] as! Date
                    let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
                    let calendarLastDate = Calendar.current.dateComponents([.day, .year, .month], from: lastDateAdded)
                    
                    
                    if calendarDate.day != nil && calendarLastDate.day != nil{
                        let stringDate = dic["dateString"] as? String ?? ""
                        
                        let diffInDays = date.interval(ofComponent: .day, fromDate: lastDateAdded)
                        
                        //  stringDate = getStringFromDate(date: date, dateFormat: "HH:mm:ss")
                        let duration = dic["Duration in seconds"] as? String ?? ""
                        let quantity = dic["Quantity Logged"] as? String ?? ""
                        
                        
                        
                        if diffInDays == 1{
                            var quantityOrDuration:Double = 0
                            if logQuantity{
                                quantityOrDuration = Double(quantity) ?? 0
                            }else{
                                quantityOrDuration = Double(duration) ?? 0
                            }
                            if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
                                var arr = [Double]()
                                if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
                                    arr = nval
                                }
                                arr.append(quantityOrDuration)
                                data["arrQuantityOrDuration"] = arr
                                arrDataForGraph[stringDate] = data
                                lastDateAdded = date
                                
                            }else{
                                let arr = [quantityOrDuration]
                                let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
                                arrDataForGraph[stringDate] = ndic
                                lastDateAdded = date
                            }
                        }else{
                            let missinDayCount = diffInDays - 1
                            if missinDayCount > 0 {
                                for _ in 1...missinDayCount{
                                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDateAdded){
                                        let newStringDate = getStringFromDate(date: newDate, dateFormat: "MM-dd-yyyy")
                                        if newStringDate != stringDate{
                                            let arr = [0]
                                            let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":newDate]
                                            arrDataForGraph[newStringDate] = ndic
                                            lastDateAdded = newDate
                                        }
                                    }
                                }
                                
                                var quantityOrDuration:Double = 0
                                if logQuantity{
                                    quantityOrDuration = Double(quantity) ?? 0
                                }else{
                                    quantityOrDuration = Double(duration) ?? 0
                                }
                                if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
                                    var arr = [Double]()
                                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
                                        arr = nval
                                    }
                                    arr.append(quantityOrDuration)
                                    data["arrQuantityOrDuration"] = arr
                                    arrDataForGraph[stringDate] = data
                                    lastDateAdded = date
                                    
                                }else{
                                    let arr = [quantityOrDuration]
                                    let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
                                    arrDataForGraph[stringDate] = ndic
                                    lastDateAdded = date
                                }
                                
                            }
                            
                            if diffInDays == 0{
                                var quantityOrDuration:Double = 0
                                if logQuantity{
                                    quantityOrDuration = Double(quantity) ?? 0
                                }else{
                                    quantityOrDuration = Double(duration) ?? 0
                                }
                                if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
                                    var arr = [Double]()
                                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
                                        arr = nval
                                    }
                                    arr.append(quantityOrDuration)
                                    data["arrQuantityOrDuration"] = arr
                                    arrDataForGraph[stringDate] = data
                                    lastDateAdded = date
                                    
                                }else{
                                    let arr = [quantityOrDuration]
                                    let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
                                    arrDataForGraph[stringDate] = ndic
                                    lastDateAdded = date
                                }
                            }
                        }
                    }
                    //}
                }
                
            }
            //  **********************************************  //
            
            var arrForMaxValueInSecondGraph = [Double]()
            var arrGraphDictionary = [[String:Any]]()
            for key in arrDataForGraph.allKeys as? [String] ?? []{
                
                var arrQuantity = [Double]()
                if let data = arrDataForGraph.value(forKey: key) as? NSMutableDictionary{
                    if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
                        arrQuantity = nval
                    }
                    let sum = arrQuantity.reduce(0, +)
                    var finalVal:Double = sum //default sum
                    if logQuantity{
                        if logQuantityType == "SUM"{
                            finalVal = sum
                        }else if logQuantityType == "AVG"{
                            finalVal = sum/Double(arrQuantity.count)
                        }
                    }else{
                        finalVal = sum
                    }
                    arrForMaxValueInSecondGraph.append(finalVal)
                    let newStringDate = getStringFromDate(date: data.value(forKey: "date") as? Date ?? Date(), dateFormat: "yyyy-MM-dd")
                    let date = data.value(forKey: "date") as? Date ?? Date()
                    let dic = ["date":date, "stringDate":newStringDate, "value":"\(finalVal)"] as [String : Any]
                    arrGraphDictionary.append(dic)
                }
            }
            
            arrGraphDictionary.sort { ($0["date"] as! Date).compare($1["date"] as! Date) == .orderedAscending }
            if arrGraphDictionary.count == 30{/// adding fake date for making 31 days
                let firstDic = arrGraphDictionary.first!
                let firstDate = firstDic["date"] as? Date ?? Date()
                let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
                let newStringDate = getStringFromDate(date: previousDate, dateFormat: "yyyy-MM-dd")
                
                let dic = ["date":previousDate, "stringDate":newStringDate, "value":"0"] as [String : Any]
                arrGraphDictionary.insert(dic, at: 0)
            }
            for graphData in arrGraphDictionary{
                arrGraph1Date.append(graphData["date"] as? Date ?? Date())
                arrGraph1DateString.append(graphData["stringDate"] as? String ?? "")
                arrGraph1DurationOrQuantity.append(graphData["value"] as? String ?? "")
            }
            
            
            print(arrGraphDictionary)
            
            var maxInSecondGraph = arrForMaxValueInSecondGraph.max() ?? 0
            var minInSecondGraph = arrForMaxValueInSecondGraph.min() ?? 0
            
            
            
            
            var labelYVal = ""
            if logQuantity{
                labelYVal = graphQuantityText
            }else{
                labelYVal = graphMinutesText
            }
            
            
            if maxInSecondGraph < 50{
                maxInSecondGraph = maxInSecondGraph + 5
            }else if maxInSecondGraph < 99{
                maxInSecondGraph = maxInSecondGraph + 10
            }else if maxInSecondGraph < 999{
                maxInSecondGraph = maxInSecondGraph + 20
            }else if maxInSecondGraph < 9999{
                maxInSecondGraph = maxInSecondGraph + 50
            }else {
                maxInSecondGraph = maxInSecondGraph + 200
            }
            
            
            if minInSecondGraph < 50{
                minInSecondGraph = minInSecondGraph - 5
            }else if minInSecondGraph < 99{
                minInSecondGraph = minInSecondGraph - 10
            }else if minInSecondGraph < 999{
                minInSecondGraph = minInSecondGraph - 20
            }else if minInSecondGraph < 9999{
                minInSecondGraph = minInSecondGraph - 50
            }else {
                minInSecondGraph = minInSecondGraph - 200
            }
            
            if minInSecondGraph < 0{
                minInSecondGraph = 0
            }
            //            maxInSecondGraph = roundOffValue(number:maxInSecondGraph)//
            var type = ""
            if isDataWeekly{
                type = "weekly"
            }else{
                type = "monthly"
            }
            let json = [ "label":"\(activityName)" , "labelX":graphDateText, "labelY":labelYVal, "data": arrGraph1DurationOrQuantity, "type":type, "max":maxInSecondGraph, "min":minInSecondGraph] as [String : Any]
            addGraphsLog(text: "\(json)")
            do {
                let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
                if let str = String(data: data, encoding: String.Encoding.utf8){
                    print(str)
                    print("str is ***************")
                    
                    let script = "getData(\(str));"
                    
                    
                    DispatchQueue.global().async {
                        //                        usleep(500000)//0.5
                        if isBreakMonthGraphLoadedFirstTime{
                            usleep(500000)
                        }else{
                            usleep(720000)
                            isBreakMonthGraphLoadedFirstTime = true
                        }
                        DispatchQueue.main.async {
                            self.webViewGraph2?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                print(html)
                                if error != nil{
                                    print("str error is *************** \(error)")
                                }else{
                                    print("str success ***************")
                                }
                            })
                        }
                    }
                }
            } catch let error as NSError {
                print(error)
            }
            
        }
        
    }
    //    @objc func loadData(){
    //
    //        //        let script = "getData1();"
    //        //
    //        //        webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
    //        //            print(html)
    //        //        })
    //        //        return;
    //        var json = [ "label":"Pushups Over Time1" , "labelX":"Date1", "labelY":"Number of Pushups1", "data": [100,15,200,10,30,40,50,30, 66, 22 , 31 , 42 , 43 , 21 , 19 , 33 , 42 , 66 , 21 , 15 , 24 , 41 , 36 , 51 , 18 , 89 , 40 , 213, 149 , 128 ,10,15,20,10,30,40,50,30, 66, 22 , 31 , 42 , 43 , 21 , 19 , 33 , 42 , 66 , 21 , 15 , 24 , 41 , 36 , 51 , 18 , 89 , 40 , 213, 149 , 128,  36 , 51 , 18 , 89 , 40 , 213, 149 , 128, 43 , 21 , 19 , 33 , 42 , 66 , 21 , 0, 18 , 89 , 40 , 213, 149 , 128 , ]] as [String : Any]
    //        do {
    //            let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
    //            if let str = String(data: data, encoding: String.Encoding.utf8){
    //                print(str)
    //
    //
    //                let script = "getData(\(str));"
    //
    //                webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
    //                    print(html)
    //                })
    //
    //            }
    //        } catch let error as NSError {
    //            print(error)
    //        }
    //        //        let script = "getData(\(json));"
    //
    //
    //    }
    func readCsv(activityName:String, logType:String)->[[String:Any]]{
        var arrDic = [[String:Any]]()
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        let previousMonth = Calendar.current.date(byAdding: .day, value: -30, to: startDate) ?? startDate
        var arr = readDataFromCSV(url: quantityCsvURL!)
        print(arr)
        
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
                        
                        
                        if (dic["Log type"] ?? "") == logType && (dic["Activity"] ?? "") == activityName{
                            if let time = dic["Start Time"]{
                                if let dateTime = getDateFromString(date: time, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                                    if dateTime.compare(previousMonth) == .orderedDescending {
                                        var newDic = [String:Any]()
                                        newDic["date"] = dateTime
                                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                                        newDic["Duration in seconds"] = dic["Duration in seconds"]
                                        newDic["Quantity Logged"] = dic["Quantity Logged"]
                                        arrDic.append(newDic)
                                    }
                                }
                            }
                        }
                        
                    }
                }
                
                
                return arrDic
                
            }
            
        }
        return []
    }
    func readCsvForTodayOnly(activityName:String, logType:String)->[[String:Any]]{
        var arrDic = [[String:Any]]()
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
        
        var arr = readDataFromCSV(url: quantityCsvURL!)
        print(arr)
        
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
                        
                        
                        if (dic["Log type"] ?? "") == logType && (dic["Activity"] ?? "") == activityName{
                            if let time = dic["Start Time"]{
                                if let dateTime = getDateFromString(date: time, dateFormat: "yyyy-MM-dd HH:mm:ss"){
                                    if dateTime.compare(startDate) == .orderedDescending {
                                        var newDic = [String:Any]()
                                        newDic["date"] = dateTime
                                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                                        newDic["Duration in seconds"] = dic["Duration in seconds"]
                                        newDic["Quantity Logged"] = dic["Quantity Logged"]
                                        arrDic.append(newDic)
                                    }
                                }
                            }
                        }
                        
                    }
                }
                
                
                return arrDic
                
            }
            
        }
        return []
    }
    
    func breathingFinished(isSKipped:Bool) {
        btnSkipHabit.isHidden = true
        btnReviseQuantity.isHidden = true
        lblTimer.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 170
        lblProgress.isHidden = true
        imgViewGif.isHidden = true
        btnMain.title = "Sign Up"
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            btnMain.title = askLogInVcInfo.value(forKey: "buttonSignUpText") as? String ?? btnMain.title
        }
        mainViewControllerObj?.hideCloseButtons()
        webViewForVideo.isHidden = true
        boxBreathingFinished.isHidden = true
        customViewContainer.isHidden = false
        btnMain.isHidden = false
        let name = introActivity!.name!
        //        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
        //            if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
        //                name = arr.first?.value(forKey: "name") as? String ?? ""
        //            }
        //        }
        
        
        if isSKipped{
            allApiObject.capturePosthog(event: "onboarding-activity-skipped", metadata: [:])
            let activityFinishedText = getActivitySkippedText(isLast: false, activityName: name)
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                lblTitle.stringValue = activityFinishedText + "\n\n\n\n" + (common.value(forKey: "letsCreatAccountText") as? String ?? "")
            }
        }else{
            allApiObject.capturePosthog(event: "onboarding-activity-finished", metadata: [:])
            let activityFinishedText = getActivityFinishedText(isLast: false, activityName: name)//"Breathing finished!✅ You’ve earned your screen time. 💪"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                lblTitle.stringValue = activityFinishedText + "\n\n\n\n" + (common.value(forKey: "letsCreatAccountText") as? String ?? "")
            }
        }
    }
    
    func startOnboardingVideo(){
        addLog(text:"start onboarding video")
        btnSkipHabit.isHidden = true
        btnReviseQuantity.isHidden = true
        lblTimer.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 170
        lblProgress.isHidden = true
        imgViewGif.isHidden = true
        
        
        btnMain.title = "Continue"
        if let preloadFocusModesViewInfo = configjson.value(forKey: "preloadFocusModesViewInfo") as? NSDictionary{
            btnMain.title = preloadFocusModesViewInfo.value(forKey: "buttonContinueText") as? String ?? btnMain.title
        }
        
        boxBreathingFinished.isHidden = false
        customViewContainer.isHidden = true
        btnMain.isHidden = false
        lblTitle.stringValue = ""
        webViewForVideo.isHidden = false
        var videoUrl = "https://www.youtube.com/watch?v=TvfNJ1AaT9M"
        
        if let welcomeInfo = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            videoUrl = welcomeInfo.value(forKey: "welcomeVideoUrl") as? String ?? videoUrl
        }
        if videoUrl.lowercased().contains("watch?v="){
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
        }else{
            
            if videoUrl.lowercased().contains("https://youtu.be/"){
                //https://www.youtube.com/watch?v=lExuhKRS8vo
                if let lastItem =  videoUrl.components(separatedBy: "/").last{
                    videoUrl = "https://www.youtube.com/embed/" + lastItem
                }
                
            }
        }
        //        if videoUrl.contains("?"){
        //            videoUrl = videoUrl + "&autoplay=1"
        //        }else{
        //            videoUrl = videoUrl + "?autoplay=1"
        //        }
        let link = URL(string:videoUrl)!
        let request = URLRequest(url: link)
        self.webViewForVideo.load(request)
    }
    
    func btnFocesModesLodded(){
        btnSkipHabit.isHidden = true
        boxBreathingFinished.isHidden = false
        customViewContainer.isHidden = true
        btnMain.isHidden = false
        btnMainClicked(self)//new work 26/9/22
        
        return;//old work
        lblTitle.stringValue = ""
        webViewForVideo.isHidden = false
        
        var videoUrl = "https://www.youtube.com/watch?v=GAeP2pKxako"
        if videoUrl.lowercased().contains("watch?v="){
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
        }else{
            
            if videoUrl.lowercased().contains("https://youtu.be/"){
                //https://www.youtube.com/watch?v=lExuhKRS8vo
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
        self.webViewForVideo.load(request)
        
    }
    
    func morningHabitFinished(index:Int) {
        currentGraphIndex = 0
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        if quittingWcObj != nil{
            if quittingWcObj?.window?.isVisible ?? false{
                quittingWcObj?.window?.close()
            }
        }
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        randomIntToRememberNextHabit = 0
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        stackViewGraph.isHidden = true
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredMorningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        if arrFilteredMorningHabits[lastHabitIndex].useTimer{
            habitTotalCompletedSeconds += arrFilteredMorningHabits[lastHabitIndex].durationSeconds!
        }
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredMorningHabits[lastHabitIndex])
        
        if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
            isAnyAllowedFocusModeActivityFinishTime = Date()
        }
        if arrFilteredMorningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            var notes = ""
            
            if arrFilteredMorningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
            }
            
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(duration)", logQuantityQuestion: arrFilteredMorningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._MORNING_HABIT_, logQuantityType: "", activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, take_notes: arrFilteredMorningHabits[lastHabitIndex].take_notes, notes: notes, logQuantityQuestions: arrFilteredMorningHabits[lastHabitIndex].logQuantityQuestions)
        }else{
            
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "morning routine", activity: lastHabit!, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrFilteredMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(duration)", quantity: "")
            
            if arrFilteredMorningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
                let currentFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                let currentFocusModeId = currentRunningFocusType["id"] as? String ?? ""
                var notes = ""
                
                if arrFilteredMorningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
                }
                mainViewControllerObj!.showFocusCompletedView()
                focusCompletedForActivityVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: isAnyAllowedFocusModeActivityFinishTime, durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [], notes: notes)
            }else{
                var notes = ""
                
                if arrFilteredMorningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
                }
                
                
                allApiObject.activityCompletedApi(activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: false, notes: notes, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
            
            
        }
        
        
        
        setProgress()
        
        addLog(text:"\(lastHabit!) finished")
        var nextActivityName = ""
        if index < arrFilteredMorningHabits.count-1 {
            isSequenceFinished = false
            imgViewGif.isHidden = true
            playEveryActivitySound()
            nextActivityName = arrFilteredMorningHabits[lastHabitIndex+1].name!
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            allApiObject.capturePosthog(event: "complete-morning-routine-activity", metadata: ["routine-type":"morning_routine"])
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        addLog(text:"Remember Next Habit view will show")
                        btnSkipHabit.isHidden = true
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        btnSkipHabit.isHidden = false
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    btnSkipHabit.isHidden = false
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                btnSkipHabit.isHidden = false
                let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
            
            
        }else {
            isSequenceFinished = true
            allApiObject.capturePosthog(event: "complete-morning-routine", metadata: ["routine-type":"morning_routine"])
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:true)
            isHabitAlreadyShowed = true
            btnSkipHabit.isHidden = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
        
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: false, isAskNext:(self.randomIntToRememberNextHabit == 5))
            }
        }
    }
    
    
    func morningHabitSkippedAndDoneAlready() {
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        lastActivityPerformedTime = Date()
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        randomIntToRememberNextHabit = 0
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentHabitIndex += 1
        }
        
        currentAction = ._END_
        
        lastHabitIndex = currentHabitIndex
        stackViewGraph.isHidden = true
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredMorningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        if arrFilteredMorningHabits[lastHabitIndex].useTimer{
            habitTotalCompletedSeconds += arrFilteredMorningHabits[lastHabitIndex].durationSeconds!
        }
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredMorningHabits[lastHabitIndex])
        if arrFilteredMorningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(duration)", logQuantityQuestion: arrFilteredMorningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._MORNING_HABIT_, logQuantityType: "", activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, take_notes: arrFilteredMorningHabits[lastHabitIndex].take_notes, notes: "", logQuantityQuestions: arrFilteredMorningHabits[lastHabitIndex].logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "morning routine", activity: lastHabit!, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrFilteredMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(duration)", quantity: "")
            
            if arrFilteredMorningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
                
            }else{
                
                
                allApiObject.activityCompletedApi(activity_id: arrFilteredMorningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
        }
        
        
        
        setProgress()
        
        addLog(text:"\(lastHabit!) skipped")
        var nextActivityName = ""
        if lastHabitIndex < arrFilteredMorningHabits.count-1 {
            isSequenceFinished = false
            imgViewGif.isHidden = true
            playEveryActivitySound()
            nextActivityName = arrFilteredMorningHabits[lastHabitIndex+1].name!
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            allApiObject.capturePosthog(event: "complete-morning-routine-activity", metadata: ["routine-type":"morning_routine"])
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        addLog(text:"Remember Next Habit view will show")
                        btnSkipHabit.isHidden = true
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        btnSkipHabit.isHidden = false
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    btnSkipHabit.isHidden = false
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                btnSkipHabit.isHidden = false
                let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else {
            isSequenceFinished = true
            allApiObject.capturePosthog(event: "complete-morning-routine", metadata: ["routine-type":"morning_routine"])
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:true)
            isHabitAlreadyShowed = true
            btnSkipHabit.isHidden = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
        
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: false, isAskNext:(self.randomIntToRememberNextHabit == 5))
            }
        }
    }
    func setProgress(){
        var totalSecondsAllHabits = 0
        let habitCompletedSeconds = habitTotalCompletedSeconds
        
        if currentState == ._MORNING_HABIT_{
            for i in lastHabitIndex+1..<arrFilteredMorningHabits.count{
                if arrFilteredMorningHabits[i].useTimer{
                    totalSecondsAllHabits += arrFilteredMorningHabits[i].durationSeconds
                }
            }
        }else if currentState == ._EVENING_HABIT_{
            for i in lastHabitIndex+1..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].useTimer{
                    if isHighPrioritySequenceGoing{
                        if arrFilteredEveningHabits[i].isPriorityHigh{
                            totalSecondsAllHabits += arrFilteredEveningHabits[i].durationSeconds
                        }
                    }else{
                        totalSecondsAllHabits += arrFilteredEveningHabits[i].durationSeconds
                    }
                }
            }
        }
  
        let habitMinutesString: String = getStringTime(seconds: habitCompletedSeconds)
        
        
        let totalMinutesString: String = getStringTime(seconds: totalSecondsAllHabits)
        

        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            addLog(text:"func setProgress:- \(finalSring)")
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            addLog(text:"func setProgress:- \(finalSring)")
            lblProgress.stringValue = finalSring
        }
        
    }
    func morningHabitFinishedAndStartIncompleteNew(index:Int, isLastActivitySkipped:Bool) {
        currentGraphIndex = 0
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        randomIntToRememberNextHabit = 0
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex].name
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true
        
        allApiObject.getACtivityStats(activityId: arrFilteredMorningHabits[lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
            DispatchQueue.main.async {
                self.loadGraph(activityId: arrFilteredMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: arrFilteredMorningHabits[self.lastHabitIndex].logQuantity, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
            }
        })
        
        setProgress()
        
        if index < arrFilteredMorningHabits.count-1 {
            isSequenceFinished = false
            imgViewGif.isHidden = true
            if !isLastActivitySkipped{
                addLog(text:"\(lastHabit!) Finished")
                lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"//
            }else{
                addLog(text:"\(lastHabit!) Skipped")
                lblTitle.stringValue = getActivitySkippedText(isLast: false, activityName: lastHabit!)
            }
            isPromptToRememberHabitShowedInLastHabit = false
            let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
            btnMain.toolTip = btnMain.title
            btnSkipHabit.isHidden = false
        }else {
            imgViewGif.isHidden = false
            isSequenceFinished = true
            if !isLastActivitySkipped{
                addLog(text:"\(lastHabit!) Finished")
                lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            }else{
                addLog(text:"\(lastHabit!) Skipped")
                lblTitle.stringValue = getActivitySkippedText(isLast: true, activityName: lastHabit!)
            }
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            isHabitAlreadyShowed = true
            btnSkipHabit.isHidden = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
        
    }
    func morningHabitSkipped() {
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentHabitIndex += 1
        }
        
        currentAction = ._END_
        allApiObject.activitySkippedApi(activity_id: arrFilteredMorningHabits[currentHabitIndex].id, activity_sequence_id: arrFilteredMorningHabits[currentHabitIndex].activity_sequence_id, completionHandler: {dic in
            
        })
        let index = currentHabitIndex
        randomIntToRememberNextHabit = 0
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrFilteredMorningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredMorningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true
        
        //  allApiObject.getACtivityStats(activityId: arrFilteredMorningHabits[lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
        DispatchQueue.main.async {
            self.loadGraph(activityId: arrFilteredMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: arrFilteredMorningHabits[self.lastHabitIndex].logQuantity, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
        }
        // })
        
        setProgress()
        
        
        addLog(text:"\(lastHabit!) Skipped")
        var nextActivityName = ""
        if index < arrFilteredMorningHabits.count-1 {
            isSequenceFinished = false
            imgViewGif.isHidden = true
            lblTitle.stringValue = getActivitySkippedText(isLast: false, activityName: lastHabit!)
            isPromptToRememberHabitShowedInLastHabit = false
            let time = arrFilteredMorningHabits[lastHabitIndex+1].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredMorningHabits[lastHabitIndex+1].name!)
            btnMain.toolTip = btnMain.title
            btnSkipHabit.isHidden = false
            nextActivityName = arrFilteredMorningHabits[lastHabitIndex+1].name!
        }else {
            imgViewGif.isHidden = false
            isSequenceFinished = true
            lblTitle.stringValue = getActivitySkippedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            isHabitAlreadyShowed = true
            btnSkipHabit.isHidden = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
        
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: true, isAskNext:false)
            }
        }
    }
    var isSequenceFinished = false
    
    func eveningHabitFinished(index:Int) {
        currentGraphIndex = 0
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        if quittingWcObj != nil{// closing this window because we do not want to do some thing from quit window when activity is finishing because from quit window user can skip or postpone
            if quittingWcObj?.window?.isVisible ?? false{
                quittingWcObj?.window?.close()
            }
        }
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        randomIntToRememberNextHabit = 0
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredEveningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        stackViewGraph.isHidden = true
        if arrFilteredEveningHabits[lastHabitIndex].useTimer{
            habitTotalCompletedSeconds += arrFilteredEveningHabits[lastHabitIndex].durationSeconds!
        }
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredEveningHabits[lastHabitIndex])
        
        if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
            isAnyAllowedFocusModeActivityFinishTime = Date()
        }
        
        if arrFilteredEveningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            var notes = ""
            
            if arrFilteredEveningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
            }
            
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(duration)", logQuantityQuestion: arrFilteredEveningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._EVENING_HABIT_, logQuantityType: "", activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, take_notes: arrFilteredEveningHabits[lastHabitIndex].take_notes, notes: notes, logQuantityQuestions: arrFilteredEveningHabits[lastHabitIndex].logQuantityQuestions)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "evening routine", activity: lastHabit!, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(duration)", quantity: "")
            
            if arrFilteredEveningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
            }else if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
                let currentFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                let currentFocusModeId = currentRunningFocusType["id"] as? String ?? ""
                var notes = ""
                
                if arrFilteredEveningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
                }
                mainViewControllerObj!.showFocusCompletedView()
                focusCompletedForActivityVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: isAnyAllowedFocusModeActivityFinishTime, durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [], notes: notes)
            }else{
                
                var notes = ""
                
                if arrFilteredEveningHabits[lastHabitIndex].take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitSavedNotes) as? String ?? ""
                }
                
                
                allApiObject.activityCompletedApi(activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: false, notes: notes, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
            
        }
        
        
        addLog(text:"\(lastHabit!) Finished")
        
        
        isSequenceFinished = false
        var newHabitIndex = lastHabitIndex+1
        if index < arrFilteredEveningHabits.count-1 {
            if isHighPrioritySequenceGoing{
                while !arrFilteredEveningHabits[newHabitIndex].isPriorityHigh{
                    newHabitIndex = newHabitIndex + 1
                    if newHabitIndex > arrFilteredEveningHabits.count - 1{
                        isSequenceFinished = true
                        break;
                    }
                }
                
                
            }
        }else{
            isSequenceFinished = true
        }
        currentHabitIndex = newHabitIndex - 1
        setProgress()
        var nextActivityName = ""
        if !isSequenceFinished {
            nextActivityName = arrFilteredEveningHabits[newHabitIndex].name!
            allApiObject.capturePosthog(event: "complete-evening-routine-activity", metadata: ["routine-type":"evening_routine"])
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            playEveryActivitySound()
            imgViewGif.isHidden = true
            
            if SettingsManagerObject.isPromptToRememberHabit && !isHighPrioritySequenceGoing{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        addLog(text:"Remember Next Habit view will show")
                        btnSkipHabit.isHidden = true
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        btnSkipHabit.isHidden = false
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    btnSkipHabit.isHidden = false
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                btnSkipHabit.isHidden = false
                let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                btnMain.toolTip = btnMain.title
            }
        }else{
            allApiObject.capturePosthog(event: "complete-evening-routine", metadata: ["routine-type":"evening_routine"])
            if arrFilteredEveningHabits[lastHabitIndex].logQuantity || arrFilteredEveningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                
            }else{
                startTimer(duration: 30)
            }
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:false)
            if startTime == nil || shutOffTime == nil{
                return;
            }
            
            
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            btnSkipHabit.isHidden = true
        }
        
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: false, isAskNext:(self.randomIntToRememberNextHabit == 5))
            }
        }
        
    }
    func eveningHabitSkippedAndDoneAlready() {
        currentGraphIndex = 0
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        lastActivityPerformedTime = Date()
        randomIntToRememberNextHabit = 0
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentHabitIndex += 1
        }
        currentAction = ._END_
        
        lastHabitIndex = currentHabitIndex
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredEveningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        stackViewGraph.isHidden = true
        if arrFilteredEveningHabits[lastHabitIndex].useTimer{
            habitTotalCompletedSeconds += arrFilteredEveningHabits[lastHabitIndex].durationSeconds!
        }
        let duration = getLastHabitDoneDuration(lastHabit: arrFilteredEveningHabits[lastHabitIndex])
        if arrFilteredEveningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(duration)", logQuantityQuestion: arrFilteredEveningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._EVENING_HABIT_, logQuantityType: "", activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, take_notes: arrFilteredEveningHabits[lastHabitIndex].take_notes, notes: "", logQuantityQuestions: arrFilteredEveningHabits[lastHabitIndex].logQuantityQuestions)
            logQuantityVcObj?.is_skipped = true
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "evening routine", activity: lastHabit!, durationInSeconds: "\(duration)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(duration)", quantity: "")
            
            
            if arrFilteredEveningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: duration, quantity_logged:nil, activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil, log_quantity_answers: [])
            }else{
                
                
                allApiObject.activityCompletedApi(activity_id: arrFilteredEveningHabits[lastHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:duration, choice_id: nil, is_skipped: true, notes: "", should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
            
        }
        
        
        addLog(text:"\(lastHabit!) skipped")
        
        isSequenceFinished = false
        var newHabitIndex = lastHabitIndex+1
        if lastHabitIndex < arrFilteredEveningHabits.count-1 {
            if isHighPrioritySequenceGoing{
                while !arrFilteredEveningHabits[newHabitIndex].isPriorityHigh{
                    newHabitIndex = newHabitIndex + 1
                    if newHabitIndex > arrFilteredEveningHabits.count - 1{
                        isSequenceFinished = true
                        break;
                    }
                }
                
                
            }
        }else{
            isSequenceFinished = true
        }
        currentHabitIndex = newHabitIndex - 1
        setProgress()
        var nextActivityName = ""
        
        if !isSequenceFinished {
            allApiObject.capturePosthog(event: "complete-evening-routine-activity", metadata: ["routine-type":"evening_routine"])
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            playEveryActivitySound()
            imgViewGif.isHidden = true
            nextActivityName = arrFilteredEveningHabits[newHabitIndex].name!
            if SettingsManagerObject.isPromptToRememberHabit && !isHighPrioritySequenceGoing{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        addLog(text:"Remember Next Habit view will show")
                        btnSkipHabit.isHidden = true
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        btnSkipHabit.isHidden = false
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    btnSkipHabit.isHidden = false
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                btnSkipHabit.isHidden = false
                let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
                btnMain.toolTip = btnMain.title
            }
        }else{
            allApiObject.capturePosthog(event: "complete-evening-routine", metadata: ["routine-type":"evening_routine"])
            if arrFilteredEveningHabits[lastHabitIndex].logQuantity || arrFilteredEveningHabits[lastHabitIndex].take_notes == END_OF_ACTIVITY{
                
            }else{
                startTimer(duration: 30)
            }
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:false)
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            btnSkipHabit.isHidden = true
        }
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: false, isAskNext:(self.randomIntToRememberNextHabit == 5))
            }
        }
    }
    func eveningHabitFinishedAndStartIncompleteNew(index:Int, isLastActivitySkipped:Bool) {
        currentGraphIndex = 0
        btnNextGraph.isHidden = true
        btnPreviousGraph.isHidden = true
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        randomIntToRememberNextHabit = 0
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex].name
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true
        
        
        allApiObject.getACtivityStats(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
            DispatchQueue.main.async {
                self.loadGraph(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: arrFilteredEveningHabits[self.lastHabitIndex].logQuantity, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
            }
        })
        
        
        
        
        
        isSequenceFinished = false
        var newHabitIndex = lastHabitIndex+1
        if lastHabitIndex < arrFilteredEveningHabits.count-1 {
            if isHighPrioritySequenceGoing{
                while !arrFilteredEveningHabits[newHabitIndex].isPriorityHigh{
                    newHabitIndex = newHabitIndex + 1
                    if newHabitIndex > arrFilteredEveningHabits.count - 1{
                        isSequenceFinished = true
                        break;
                    }
                }
                
                
            }
        }else{
            isSequenceFinished = true
        }
        setProgress()
        currentHabitIndex = newHabitIndex - 1
        if !isSequenceFinished {
            
            if !isLastActivitySkipped{
                addLog(text:"\(lastHabit!) Finished")
                lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            }else{
                addLog(text:"\(lastHabit!) Skipped")
                lblTitle.stringValue = getActivitySkippedText(isLast: false, activityName: lastHabit!)
            }
            imgViewGif.isHidden = true
            isPromptToRememberHabitShowedInLastHabit = false
            let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
            btnMain.toolTip = btnMain.title
            btnSkipHabit.isHidden = false
        }else{
            if arrFilteredEveningHabits[lastHabitIndex].logQuantity{
                
            }else{
                startTimer(duration: 30)
            }
            
            imgViewGif.isHidden = false
            if !isLastActivitySkipped{
                addLog(text:"\(lastHabit!) Finished")
                lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            }else{
                addLog(text:"\(lastHabit!) Skipped")
                lblTitle.stringValue = getActivitySkippedText(isLast: true, activityName: lastHabit!)
            }
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            btnSkipHabit.isHidden = true
        }
        
    }
    func eveningHabitSkipped() {
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitRunningInfo)
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentHabitIndex += 1
        }
        currentAction = ._END_
        
        allApiObject.activitySkippedApi(activity_id: arrFilteredEveningHabits[currentHabitIndex].id, activity_sequence_id: arrFilteredEveningHabits[currentHabitIndex].activity_sequence_id, completionHandler: {dic in
            
        })
        let index = currentHabitIndex
        randomIntToRememberNextHabit = 0
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = false
        boxBreathingFinished.isHidden = true
        lastHabitIndex = index
        let lastHabit = arrFilteredEveningHabits[lastHabitIndex].name
        UserDefaults.standard.set(arrFilteredEveningHabits[lastHabitIndex].id, forKey: kUserdefaultsLastHabitID)
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true
        
        
        //   allApiObject.getACtivityStats(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
        DispatchQueue.main.async {
            self.loadGraph(activityId: arrFilteredEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
        }
        // })
        
        
        
        isSequenceFinished = false
        var newHabitIndex = lastHabitIndex+1
        if index < arrFilteredEveningHabits.count-1 {
            if isHighPrioritySequenceGoing{
                while !arrFilteredEveningHabits[newHabitIndex].isPriorityHigh{
                    newHabitIndex = newHabitIndex + 1
                    if newHabitIndex > arrFilteredEveningHabits.count - 1{
                        isSequenceFinished = true
                        break;
                    }
                }
                
                
            }
        }else{
            isSequenceFinished = true
        }
        setProgress()
        currentHabitIndex = newHabitIndex - 1
        addLog(text:"\(lastHabit!) Skipped")
        var nextActivityName = ""
        if !isSequenceFinished {
            lblTitle.stringValue = getActivitySkippedText(isLast: false, activityName: lastHabit!)
            imgViewGif.isHidden = true
            isPromptToRememberHabitShowedInLastHabit = false
            let time = arrFilteredEveningHabits[newHabitIndex].durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: arrFilteredEveningHabits[newHabitIndex].name!)
            btnMain.toolTip = btnMain.title
            btnSkipHabit.isHidden = false
            nextActivityName = arrFilteredEveningHabits[newHabitIndex].name!
        }else{
            if arrFilteredEveningHabits[lastHabitIndex].logQuantity{
                
            }else{
                startTimer(duration: 30)
            }
            
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivitySkippedText(isLast: true, activityName: lastHabit!)
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            btnSkipHabit.isHidden = true
        }
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastHabit ?? "", nextActivity: nextActivityName, isSkipped: true, isAskNext:false)
            }
        }
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0
    
    func startTimer(duration:Int) {
        if isTimerGoingOn{
            lblTimer.isHidden = false
            return
        }
        btnSkipHabit.isHidden = true
        lblTimer.isHidden = false
        isTimerGoingOn = true
        currentTimer = 0
        totalDuration = duration
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimer.isHidden = false
            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.main.async {
                self.lblTimer.isHidden = true
                self.isTimerGoingOn = false
                self.btnMainClicked(self)
            }
        }
    }
    
    func activityFinished(index:Int) {
        currentGraphIndex = 0
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = true
        let lastActivityChoice = currentActivityChoice
        currentActivityChoice = nil
        var currentActivity:breakActivity?
        boxBreathingFinished.isHidden = true
        imgViewGif.isHidden = true
        lastActivityIndex = index
        var lastActivity = ""//arrAllbreakActivities[lastActivityIndex].name
        var logQuantity:Bool = false
        var durationInSeconds = 0
        var logQuantityType:String?
        var activity_id:String = ""
        var activity_sequence_id = ""
        let activityChoiceId:String? = lastActivityChoice?.id
        var take_notes = ""
        var logQuantityQuestions = [quantityQuestion]()

        lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrAllbreakActivities[lastActivityIndex].name
        logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
        durationInSeconds = getLastActivityDoneDuration(lastActivity: arrFinalBreakActivities[lastActivityIndex].activity)
        activity_id = arrFinalBreakActivities[lastActivityIndex].activity.id
        activity_sequence_id = arrFinalBreakActivities[lastActivityIndex].activity.activity_sequence_id
        logQuantityType = timerViewcontrollerObj?.logQuantityType ?? arrFinalBreakActivities[lastActivityIndex].activity.logQuantityType
        take_notes = arrFinalBreakActivities[lastActivityIndex].activity.take_notes
        logQuantityQuestions = timerViewcontrollerObj?.logQuantityQuestions ?? []
        
        
        if logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            var notes = ""
            
            if take_notes == DURING_ACTIVITY{
                notes = UserDefaults.standard.object(forKey: kUserdefaultsLastActivitySavedNotes) as? String ?? ""
            }
            
            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: nil, currentState: ._ACTIVITY_, logQuantityType: logQuantityType ?? "", activity_id: activity_id, activity_sequence_id: activity_sequence_id,activityChoiceId:activityChoiceId, take_notes:take_notes, notes:notes, logQuantityQuestions: logQuantityQuestions)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "break", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: activity_id, activityName: lastActivity, logQuantity: logQuantity, logQuantityType: "", activityChoiceId: activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: "\(durationInSeconds)", quantity: "")
            
            if take_notes == END_OF_ACTIVITY{
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: durationInSeconds, quantity_logged:nil, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: [])
            }else{
                
                var notes = ""
                
                if take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastActivitySavedNotes) as? String ?? ""
                }
                
                allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: false, notes: notes, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
            
        }
        
        
        if index < arrFinalBreakActivities.count-1 {
            isSequenceFinished = false
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
            currentActivity = arrFinalBreakActivities[lastActivityIndex+1].activity
            allApiObject.capturePosthog(event: "complete-break-activity", metadata: ["routine-type":"break_activity"])
            btnSkipHabit.isHidden = false
        }else {
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
            isSequenceFinished = true
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            imgViewGif.isHidden = false
            allApiObject.capturePosthog(event: "complete-all-break-activity", metadata: ["routine-type":"break_activity"])
            btnSkipHabit.isHidden = true
        }
        
        var nextActivityName: String = ""
        if currentActivity != nil{
            if currentActivity!.choiceType != ._RANDOM_{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = nil
                currentActivityChoice = arrFinalBreakActivities[lastActivityIndex+1].randomChoice
                nextActivityName = currentActivityChoice?.name ?? ""
            }
            
            
            let time = currentActivity!.durationSeconds
            activityName = nextActivityName
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
            btnMain.toolTip = btnMain.title

        }
        
        playEveryActivitySound()
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastActivity, nextActivity: nextActivityName, isSkipped: false, isAskNext:false)
            }
        }
    }
    
    func activitySkippedAndDoneAlready(){
        currentGraphIndex = 0
        lastActivityPerformedTime = Date()
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = true
        boxBreathingFinished.isHidden = true
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentActivityIndex += 1
        }

        let lastActivityChoice = currentActivityChoice
        currentActivityChoice = nil
        var currentActivity:breakActivity?

        imgViewGif.isHidden = true
        lastActivityIndex = currentActivityIndex


        var lastActivity = ""
        var logQuantity:Bool = false
        var durationInSeconds = 0
        var logQuantityType:String?
        var activity_id:String = ""
        var activity_sequence_id = ""
        let activityChoiceId:String? = lastActivityChoice?.id
        var take_notes = ""
        var logQuantityQuestions = [quantityQuestion]()

        lastActivity = arrFinalBreakActivities[lastActivityIndex].randomChoice?.name ?? arrFinalBreakActivities[lastActivityIndex].activity.name
        logQuantity = arrFinalBreakActivities[lastActivityIndex].activity.logQuantity ?? false
        durationInSeconds = getLastActivityDoneDuration(lastActivity: arrFinalBreakActivities[lastActivityIndex].activity)
        activity_id = arrFinalBreakActivities[lastActivityIndex].activity.id
        activity_sequence_id = arrFinalBreakActivities[lastActivityIndex].activity.activity_sequence_id
        logQuantityType = arrFinalBreakActivities[lastActivityIndex].activity.logQuantityType
        take_notes = arrFinalBreakActivities[lastActivityIndex].activity.take_notes
        logQuantityQuestions = arrFinalBreakActivities[lastActivityIndex].activity.logQuantityQuestions
        
        if logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false

            var notes = ""

            if take_notes == DURING_ACTIVITY{
                notes = UserDefaults.standard.object(forKey: kUserdefaultsLastActivitySavedNotes) as? String ?? ""
            }

            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: nil, currentState: ._ACTIVITY_, logQuantityType: logQuantityType ?? "", activity_id: activity_id, activity_sequence_id: activity_sequence_id,activityChoiceId:activityChoiceId, take_notes:take_notes, notes:notes, logQuantityQuestions: logQuantityQuestions)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "break", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")

            self.loadGraph(activityId: activity_id, activityName: lastActivity, logQuantity: logQuantity, logQuantityType: "", activityChoiceId: activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: "\(durationInSeconds)", quantity: "")

            if take_notes == END_OF_ACTIVITY{
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: durationInSeconds, quantity_logged:nil, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: [])
            }else{

                var notes = ""

                if take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastActivitySavedNotes) as? String ?? ""
                }

                allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: false, notes: notes, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in

                    DispatchQueue.main.async {

                    }
                    print(dic)
                })
            }
        }


        if currentActivityIndex < arrFinalBreakActivities.count-1 {
            isSequenceFinished = false
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
            currentActivity = arrFinalBreakActivities[lastActivityIndex+1].activity
            allApiObject.capturePosthog(event: "complete-break-activity", metadata: ["routine-type":"break_activity"])
            btnSkipHabit.isHidden = false
        }else {
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
            isSequenceFinished = true
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            imgViewGif.isHidden = false
            allApiObject.capturePosthog(event: "complete-all-break-activity", metadata: ["routine-type":"break_activity"])
            btnSkipHabit.isHidden = true
        }

        var nextActivityName: String = ""
        if currentActivity != nil{
            if currentActivity!.choiceType != ._RANDOM_{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = nil
                currentActivityChoice = arrFinalBreakActivities[lastActivityIndex].randomChoice
                nextActivityName = currentActivityChoice?.name ?? ""
            }


            let time = currentActivity!.durationSeconds
            activityName = nextActivityName
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
            btnMain.toolTip = btnMain.title
        }

        playEveryActivitySound()
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastActivity, nextActivity: nextActivityName, isSkipped: false, isAskNext:false)
            }
        }
    }
    
    func activitySkipped(){
        logQuantityQuestionsForGraph = []
        currentGraphIndex = 0
        lastActivityPerformedTime = Date()
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }

        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = true
        boxBreathingFinished.isHidden = true
        if currentAction != ._INPROGRESS_{// if inprogess it means already updated cutrrenthabitindex
            currentActivityIndex += 1
        }

        currentActivityChoice = nil
        var currentActivity:breakActivity?

        imgViewGif.isHidden = true
        lastActivityIndex = currentActivityIndex
        
        var lastActivity = ""
        var logQuantity:Bool = false
        var activity_id:String = ""
        let activityChoiceId:String? = arrFinalBreakActivities[lastActivityIndex].randomChoice?.id

        lastActivity = arrFinalBreakActivities[lastActivityIndex].randomChoice?.name ?? arrFinalBreakActivities[lastActivityIndex].activity.name
        logQuantity = arrFinalBreakActivities[lastActivityIndex].activity.logQuantity ?? false
        activity_id = arrFinalBreakActivities[lastActivityIndex].activity.id
        
        self.loadGraph(activityId: activity_id, activityName: lastActivity, logQuantity: logQuantity, logQuantityType: "", activityChoiceId: activityChoiceId,activityStartTime: nil, duration: "", quantity: "")
        btnReviseQuantity.isHidden = true//do not remove this beacuse in skipping user cant enter quantity
        
        if currentActivityIndex < arrFinalBreakActivities.count-1 {
            isSequenceFinished = false
            lblTitle.stringValue = getActivitySkippedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
            currentActivity = arrFinalBreakActivities[lastActivityIndex+1].activity
            btnSkipHabit.isHidden = false
        }else {
            lblTitle.stringValue = getActivitySkippedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
            isSequenceFinished = true
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.hideCloseButtons()
            btnMain.toolTip = btnMain.title
            imgViewGif.isHidden = false
            btnSkipHabit.isHidden = true
        }

        var nextActivityName: String = ""
        if currentActivity != nil{
            if currentActivity!.choiceType != ._RANDOM_{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = nil
                currentActivityChoice = arrFinalBreakActivities[lastActivityIndex+1].randomChoice
                nextActivityName = currentActivityChoice?.name ?? ""
            }


            let time = currentActivity!.durationSeconds
            activityName = nextActivityName
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
            btnMain.toolTip = btnMain.title


        }


        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                playActivityFinishedSound(lastActivity: lastActivity, nextActivity: nextActivityName, isSkipped: true, isAskNext:false)
            }
        }
    }
    
    func specialActivityFinished() {
        currentGraphIndex = 0
        btnSkipHabit.isHidden = true
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        webViewForVideo.isHidden = true
        lblTimer.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = true
        boxBreathingFinished.isHidden = true
        imgViewGif.isHidden = true
        
        var lastActivity = ""
        var logQuantity:Bool = false
        var durationInSeconds = 0
        var logQuantityQuestion:String?
        var logQuantityType:String?
        var activity_id:String = ""
        var activity_sequence_id = ""
        var take_notes = ""
        var activityChoiceId:String?
        var logQuantityQuestions:[quantityQuestion] = [quantityQuestion]()
        if timerViewcontrollerObj?.lastCurrentSpecialHabit != nil{
            logQuantity = timerViewcontrollerObj?.lastCurrentSpecialHabit?.logQuantity ?? false
            take_notes = timerViewcontrollerObj?.lastCurrentSpecialHabit?.take_notes ?? ""
            lastActivity = timerViewcontrollerObj?.lastCurrentSpecialHabit?.name ?? ""
            logQuantityQuestion = timerViewcontrollerObj?.lastCurrentSpecialHabit?.logQuantityQuestion
            activity_id = timerViewcontrollerObj?.lastCurrentSpecialHabit?.id ?? ""
            activity_sequence_id = timerViewcontrollerObj?.lastCurrentSpecialHabit?.activity_sequence_id ?? ""
            logQuantityQuestions = timerViewcontrollerObj?.lastCurrentSpecialHabit?.logQuantityQuestions ?? []
        }else if timerViewcontrollerObj?.lastCurrentSpecialActivity != nil{
            if timerViewcontrollerObj?.lastCurrentSpecialActivityChoice != nil{
                logQuantity = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.logQuantity ?? false
                lastActivity = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.name ?? ""
                logQuantityQuestion = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.logQuantityQuestion
                logQuantityType = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.logQuantityType ?? ""
                activityChoiceId = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.id ?? ""
                logQuantityQuestions = timerViewcontrollerObj?.lastCurrentSpecialActivityChoice?.logQuantityQuestions ?? []
            }else{
                logQuantity = timerViewcontrollerObj?.lastCurrentSpecialActivity?.logQuantity ?? false
                lastActivity = timerViewcontrollerObj?.lastCurrentSpecialActivity?.name ?? ""
                logQuantityQuestion = timerViewcontrollerObj?.lastCurrentSpecialActivity?.logQuantityQuestion
                logQuantityType = timerViewcontrollerObj?.lastCurrentSpecialActivity?.logQuantityType ?? ""
                logQuantityQuestions = timerViewcontrollerObj?.lastCurrentSpecialActivity?.logQuantityQuestions ?? []
            }
            take_notes = timerViewcontrollerObj?.lastCurrentSpecialActivity?.take_notes ?? ""
            activity_id = timerViewcontrollerObj?.lastCurrentSpecialActivity?.id ?? ""
            activity_sequence_id = timerViewcontrollerObj?.lastCurrentSpecialActivity?.activity_sequence_id ?? ""
        }
        durationInSeconds = timerViewcontrollerObj?.lastCurrentSpecialActivityDuration ?? 0
        if logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            
            var notes = ""
            
            if take_notes == DURING_ACTIVITY{
                notes = UserDefaults.standard.object(forKey: kUserdefaultsLastSpecaialActivitySavedNotes) as? String ?? ""
            }
            
            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: logQuantityQuestion, currentState: ._SPECIAL_ACTIVITY_, logQuantityType: logQuantityType ?? "", activity_id: activity_id, activity_sequence_id: activity_sequence_id,activityChoiceId:activityChoiceId, take_notes:take_notes, notes:notes, logQuantityQuestions:logQuantityQuestions)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "special activity", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: activity_id, activityName: lastActivity, logQuantity: logQuantity, logQuantityType: "", activityChoiceId: activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: "\(durationInSeconds)", quantity: "")
            
            if take_notes == END_OF_ACTIVITY{
                mainViewControllerObj!.showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: durationInSeconds, quantity_logged:nil, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: [])
            }else{
                
                var notes = ""
                
                if take_notes == DURING_ACTIVITY{
                    notes = UserDefaults.standard.object(forKey: kUserdefaultsLastSpecaialActivitySavedNotes) as? String ?? ""
                }
                
                allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: false, notes: notes, should_not_update_current_activity: true, log_quantity_answers: [], completionHandler: {dic  in
                    
                    DispatchQueue.main.async {
                        
                    }
                    print(dic)
                })
            }
            
            
        }
        
        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
        btnMain.title = unlockMachineButtonText
        imgViewGif.isHidden = false
        mainViewControllerObj?.hideCloseButtons()
        allApiObject.capturePosthog(event: "complete-late-no-more-activity", metadata: [:])
        
        playEveryActivitySound()
    }
    
    
    var currentActivityChoice:activityChoice?
    var activityName: String = ""
    
    func startBreakActivity() {
        activityName = ""
        btnSkipHabit.isHidden = false
        btnSkipHabit.title = "Postpone break for five minutes"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnSkipHabit.title
        }
        
        lblProgress.isHidden = false
        var totalDuration = 0
        for activity in arrFinalBreakActivities{
            if activity.activity.useTimer{
                totalDuration += activity.activity.durationSeconds
            }
        }
        
        var breakDurationText = "Break Activites Duration: <DURATION>"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            breakDurationText = activityInfo.value(forKey: "breakDurationText") as? String ?? breakDurationText
        }
        lblProgress.stringValue = breakDurationText.replacingOccurrences(of: "<DURATION>", with: "\(getStringTime(seconds: totalDuration))")//"Break Activites Duration: \(getStringTime(seconds: totalDuration))"//
        
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 0
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        
        currentActivityChoice = nil
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastActivityIndex = -1
        
        var seconds: Int = 0
        let currentActivity = arrFinalBreakActivities[0].activity

        if currentActivity!.choiceType != ._RANDOM_{
            activityName = currentActivity!.name
        }else{//random choice
            currentActivityChoice = nil
            currentActivityChoice = arrFinalBreakActivities[0].randomChoice
            activityName = currentActivityChoice?.name ?? ""
        }
        
        seconds = currentActivity!.durationSeconds
        
        lblTitle.stringValue = getStartBreakActivityTitleText(seconds: seconds, activityName: activityName)//"It’s time for a break. Do \(seconds) seconds of \(activityName) to earn more screentime."
        btnMain.title = getstartActivityButtonText(seconds: seconds, name: activityName)//"Start \(seconds) seconds \(activityName)"
        btnMain.toolTip = btnMain.title
        
        addLog(text:"start-break-activity")//complete break activity//
    }
    @IBAction func btnReviseQuantityClicked(_ sender: Any) {
        addLog(text:"thirdvc-btnReviseQuantityClicked")
        btnReviseQuantity.isHidden = true
        mainViewControllerObj!.showLogQuantityView()
        logQuantityVcObj?.isReviseQuantity = true
        // logQuantityVcObj?.textFieldCount.stringValue = ""
        //   logQuantityVcObj?.textFieldCount.selectText(self)
        //   logQuantityVcObj?.textFieldCount.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        if self.timer != nil{
            isTimerGoingOn = false
            lblTimer.isHidden = true
            self.timer?.invalidate()
        }
    }
    
    func loadBlankUrl(){
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webViewForVideo.load(request)
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        if webViewForVideo.isHidden == false{ // onboarding view is lodded
            addLog(text:"onboarding video - btn Continue clicked")
            loadBlankUrl()
            self.view.window?.close()
            appdelegate!.loadCredentialsAndDeviceId()
            let secondsBetween = Date().timeIntervalSince(onboardingVideoStartTime ?? Date())
            allApiObject.capturePosthog(event: "onboarding-video-watched", metadata: ["watched_duration_seconds":Int(secondsBetween)])
            showMenuTourWindow()
            return;
        }
        
        
        addLog(text:"thirdvc-btnMainClicked :- \(btnMain.title)")
        btnReviseQuantity.isHidden = true
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    addLog(text:"thirdvc-return:- password view is visible")
                    return;
                }
            }
        }
        customViewContainer.isHidden = true
        lblProgress.isHidden = true
        imgViewGif.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 0
        webViewForVideo.isHidden = true
        boxBreathingFinished.isHidden = true
        
        
        if currentState == ._BREATHING_{
            boxBreathingFinished.isHidden = true
            mainViewControllerObj?.breathingFinishedUnlockMachine()
        }else if currentState == ._ACTIVITY_ {
            if lastActivityIndex == -1 {
                mainViewControllerObj?.startCurrentActivity()
            }else{
                if lastActivityIndex < arrFinalBreakActivities.count-1 {
                    mainViewControllerObj?.changeActivity()
                }else {
                    mainViewControllerObj?.activityFinishedUnlockMachine()
                }
            }
        }else if currentState == ._MORNING_HABIT_{
            if !isSequenceFinished{
                if randomIntToRememberNextHabit == 5{
                    addLog(text:"Remember Next Habit view showing")
                    boxBg.isHidden = true
                    getRememberNextHabitVcObj().nextHabitIndex = lastHabitIndex+1
                    self.view.addSubview(getRememberNextHabitVcObj().view)
                    self.view.addConstraints(subView: getRememberNextHabitVcObj().view)
                    getRememberNextHabitVcObj().resetData()
                    randomIntToRememberNextHabit = 0
                }else{
                    mainViewControllerObj?.changeMorningHabit()
                }
            }else {
                mainViewControllerObj?.habitsFinishedUnlockMachine()
            }
        }else if currentState == ._EVENING_HABIT_{
            if !isSequenceFinished{
                if randomIntToRememberNextHabit == 5{
                    addLog(text:"Remember Next Habit view showing")
                    boxBg.isHidden = true
                    getRememberNextHabitVcObj().nextHabitIndex = lastHabitIndex+1
                    self.view.addSubview(getRememberNextHabitVcObj().view)
                    self.view.addConstraints(subView: getRememberNextHabitVcObj().view)
                    getRememberNextHabitVcObj().resetData()
                    randomIntToRememberNextHabit = 0
                }else{
                    mainViewControllerObj?.changeEveningHabit()
                }
            }else {
                self.timer?.invalidate()
                self.timer = nil
                mainViewControllerObj?.eveningHabitFinishShowShutOff()
            }
        }else if currentState == ._SPECIAL_ACTIVITY_{
            self.timer?.invalidate()
            self.timer = nil
            mainViewControllerObj?.specialActivityFinish()
        }
    }
    
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        if currentState == ._MORNING_HABIT_{
            let currentHabitId = arrFilteredMorningHabits[currentHabitIndex + 1].id ?? ""
            
            allApiObject.getACtivityStats(activityId: currentHabitId, activityChoiceId: nil, completionHandler: {dic in
                
            })
        }else if currentState == ._EVENING_HABIT_{
            let currentHabitId = arrFilteredEveningHabits[currentHabitIndex + 1].id ?? ""
            
            allApiObject.getACtivityStats(activityId: currentHabitId, activityChoiceId: nil, completionHandler: {dic in
                
            })
        }else if currentState == ._ACTIVITY_{
            let currentActivity = arrFinalBreakActivities[currentActivityIndex + 1].activity
            let currentActivityId = currentActivity?.id ?? ""
            let randomChoice = arrFinalBreakActivities[currentActivityIndex + 1].randomChoice
            

            allApiObject.getACtivityStats(activityId: currentActivityId, activityChoiceId: randomChoice?.id, completionHandler: {dic in
                
            })
            
            if arrFinalBreakActivities[currentHabitIndex + 1].activity.logQuantity{
                var questions_ids = [String]()
                for question in arrFinalBreakActivities[currentHabitIndex + 1].activity.logQuantityQuestions{
                    questions_ids.append(question.id)
                }
                allApiObject.getActivityCurrentDayQuestionsStats(activityId: currentActivityId, activityChoiceId: randomChoice?.id, questions_ids: questions_ids, completionHandler: {dic in
                    
                })
            }else{
                allApiObject.getACtivityCurrentDayStats(activityId: currentActivityId, activityChoiceId: randomChoice?.id, completionHandler: {dic in
                    
                })
            }
            
        }else{
            return
        }
        
        
        
        mainViewControllerObj?.showWhySkipHabitView()
        return;
        
        
    }
}
