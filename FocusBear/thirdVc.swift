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
    
    
    @IBOutlet weak var webViewForVideo: WKWebView!
    @IBOutlet weak var btnReviseQuantity: Button!
    @IBOutlet weak var customViewContainer: NSView!
    @IBOutlet weak var imgViewGifOpenPrefrences: NSImageView!
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
    
    var randomIntToRememberNextHabit: Int = 0
    var lastHabitIndex = -1
    var lastActivityIndex = -1
    
    var preloadFocusModesVcObj:preloadFocusModesVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        webViewForVideo.isHidden = true
        btnReviseQuantity.isHidden = true
        lblTimer.isHidden = true
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Smile _Small")
            imgViewGif.animates = true
        }
        
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
        
    }
    // date formate to pass iso 8601 formate mm-dd-yyyy
    func loadGraph(activityId:String, activityName:String, logQuantity:Bool, logQuantityType:String, activityChoiceId:String?,  activityStartTime:Date?, duration:String, quantity:String){
        // here is logQuantity is only for avtivity
        if logQuantity{
            btnReviseQuantity.isHidden = false
        }else{
            btnReviseQuantity.isHidden = true
        }
        
        
        

        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            var logType = ""
            if currentState == ._MORNING_HABIT_{
                logType = "morning routine"
            }else if currentState == ._EVENING_HABIT_{
                logType = "evening routine"
            }
           // allApiObject.getACtivityStats(activityId: activityId, activityChoiceId: nil, completionHandler: {dic in
                print(graphOneMonthData)
                if let items = graphOneMonthData?.value(forKey: "items") as? [[String:Any]]{
                   
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
                                let finalQuantity = (Double(quantity) ?? 0) + lastQuantity
                                
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
                                newDic["Quantity Logged"] = quantity
                                arrDic.append(newDic)
                            }
                            
                        }
                    }else{//todo append hoga
                        if let dateTime = activityStartTime{
                            var newDic = [String:Any]()
                            newDic["date"] = dateTime
                            newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                            newDic["Duration in seconds"] = duration
                            newDic["Quantity Logged"] = quantity
                            arrDic.append(newDic)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.loadHabitMonthlyGraphFromCsv(activityName: activityName, logQuantity: logQuantity, arrDic: arrDic)
                    }
                    
                }else{
                    // no records
                    DispatchQueue.main.async {
                        let arrDic = self.readCsv(activityName: activityName, logType: logType)
                        self.loadHabitMonthlyGraphFromCsv(activityName: activityName, logQuantity: logQuantity, arrDic: arrDic)
                    }
                    
                }
            ///})
            
            
        }else if currentState == ._ACTIVITY_{
            
           // allApiObject.getACtivityCurrentDayStats(activityId: activityId, activityChoiceId: activityChoiceId, completionHandler: {dic in
                print(graphOneDayData)
                print("*****result****")
                if let items = graphOneDayData as? [[String:Any]]{

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
                    if let dateTime = activityStartTime{
                        var newDic = [String:Any]()
                        newDic["date"] = dateTime
                        newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                        newDic["Duration in seconds"] = duration
                        newDic["Quantity Logged"] = quantity
                        arrDic.append(newDic)//todo check
                    }
                    
                   // arrDic = arrDic.reversed()// no need 
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
                
            //})
            
            
            
            
            
            
            
           // allApiObject.getACtivityStats(activityId: activityId, activityChoiceId: activityChoiceId, completionHandler: {dic in
                print(graphOneMonthData)
                print("*****result****")
               // let stat_type = dic?.value(forKey: "stat_type") as? String ?? ""  //quantity // duration
                if let items = graphOneMonthData?.value(forKey: "items") as? [[String:Any]]{
                   
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
                                let finalQuantity = (Double(quantity) ?? 0) + lastQuantity
                                
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
                                newDic["Quantity Logged"] = quantity
                                arrDic.append(newDic)
                            }
                            
                        }
                    }else{//todo append hoga
                        if let dateTime = activityStartTime{
                            var newDic = [String:Any]()
                            newDic["date"] = dateTime
                            newDic["dateString"] = getStringFromDate(date: dateTime, dateFormat: "MM-dd-yyyy")
                            newDic["Duration in seconds"] = duration
                            newDic["Quantity Logged"] = quantity
                            arrDic.append(newDic)
                        }
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.loadBreakSecondGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                    }
                    
                }else{
                    // no records
                    DispatchQueue.main.async {
                        let arrDic = self.readCsv(activityName: activityName, logType: "break")
                        self.loadBreakSecondGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType, arrDic: arrDic)
                    }
                    
                }
            //})
            
            
            
            
            
//            loadBreakGraphFromCsv(activityName: activityName, logQuantity: logQuantity, logQuantityType: logQuantityType)
        }
//        if let graphDayspath = Bundle.main.path(forResource: "GraphDays", ofType: "html"), let graphTimepath = Bundle.main.path(forResource: "GraphTime", ofType: "html"), let graphGraphTimeDurationpath = Bundle.main.path(forResource: "GraphTimeDuration", ofType: "html"), let graphDaysDurationpath = Bundle.main.path(forResource: "GraphDaysDuration", ofType: "html"){
//            print(graphDayspath)
//            let graphDaysUrl = "file://\(graphDayspath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//            let graphDaysDurationUrl = "file://\(graphDaysDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//            let graphTimeUrl = "file://\(graphTimepath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//            let graphTimeDurationUrl = "file://\(graphGraphTimeDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
//
//            stackViewGraph.isHidden = false
//
//            btnMainCenterY.constant = 100
//            imgViewGifOpenPrefrences.isHidden = true
//
//
//            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
//                webViewGraph1.isHidden = false
//                webViewGraph2.isHidden = true
////                let  fileURL = URL(string: graphDaysUrl)
//
//
//                var fileURL: URL?
//
//                if logQuantity{
//                    fileURL = URL(string: graphDaysUrl)
//                }else{
//                    fileURL = URL(string: graphDaysDurationUrl)
//                }
//
//
//                webViewGraph1.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
//
//                var logType = ""
//                if currentState == ._MORNING_HABIT_{
//                    logType = "morning routine"
//                }else if currentState == ._EVENING_HABIT_{
//                    logType = "evening routine"
//                }
//                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
//
//                let previousMonth = Calendar.current.date(byAdding: .day, value: -31, to: startDate) ?? startDate
//
//
//                let arrDic = readCsv(activityName: activityName, logType: logType)
//                print(arrDic)
//                var arrDuration = [String]()
//                var arrDateString = [String]()
//                var arrDate = [Date]()
//                var isDataWeekly = false
//                var arrForMaxValue = [Double]()
//
//                if let dic = arrDic.first{
//                    let date = dic["date"] as! Date
//                    let sevenDaysBeforeDate = Calendar.current.date(byAdding: .day, value: -6, to: startDate) ?? startDate
//                    if date.compare(sevenDaysBeforeDate) == .orderedDescending {
//                        isDataWeekly = true
//                    }
//                }
//
//
//
//                var lastDateAdded = previousMonth // qki pure 1 month ka data chahiye isiliye aaj ki date se -32  se kiya h taki 31 din ka data nilana bhake hi 15 din ka data ho to usse phle ka data fake cretae krenge
//                for dic in arrDic{
//                    let date = dic["date"] as! Date
//                    let stringDate = dic["dateString"] as! String
//                    let duration = dic["Duration in seconds"] as! String// duration minut mai chahiye lekin string mI convert krke
//                    let quantity = dic["Quantity Logged"] as! String
//                    //  if arrDate.isEmpty{
//                    //      arrDate.append(date)
//                    //      arrDateString.append(stringDate)
//                    //      arrDuration.append("\(Int((Int(duration) ?? 0)/60))")
//                    //  }else{
//
//                    if date.compare(lastDateAdded) == .orderedDescending {
//                        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
//                        let calendarLastDate = Calendar.current.dateComponents([.day, .year, .month], from: lastDateAdded)
//                        if calendarDate.day != nil && calendarLastDate.day != nil{
//                            let diffInDays = date.interval(ofComponent: .day, fromDate: lastDateAdded)//Calendar.current.dateComponents([.day], from: lastDateAdded, to: date).day ?? 1
//
//                            if diffInDays == 1{
//                                arrDate.append(date)
//                                arrDateString.append(stringDate)
//                                var quantityOrDuration:Double = 0
//
//                                if logQuantity{
//                                    quantityOrDuration = Double(quantity) ?? 0
//                                }else{
//                                    quantityOrDuration = Double(duration) ?? 0
//                                }
//                                arrForMaxValue.append(quantityOrDuration)
//                                arrDuration.append("\(quantityOrDuration)")
//                                lastDateAdded = arrDate.last!
//                            }else{
//                                let missinDayCount = diffInDays - 1
//
//                                if missinDayCount > 0 {
//                                    for _ in 1...missinDayCount{
//                                        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDateAdded){
//                                            let newStringDate = getStringFromDate(date: newDate, dateFormat: "MM-dd-yyyy")
//                                            if newStringDate != stringDate{
//                                                arrDate.append(newDate)
//                                                arrDateString.append(newStringDate)
//                                                arrDuration.append("")
//                                                arrForMaxValue.append(0)
//                                                lastDateAdded = arrDate.last!
//                                            }
//                                        }
//                                    }
//
//
//                                    arrDate.append(date)
//                                    arrDateString.append(stringDate)
//
//                                    var quantityOrDuration:Double = 0
//
//                                    if logQuantity{
//                                        quantityOrDuration = Double(quantity) ?? 0
//                                    }else{
//                                        quantityOrDuration = Double(duration) ?? 0
//                                    }
//                                    arrForMaxValue.append(quantityOrDuration)
//                                    arrDuration.append("\(quantityOrDuration)")
//                                    lastDateAdded = arrDate.last!
//                                }
//
//
//                            }
//                        }
//
//                    }else{// else mai kabhi aayga nahi qki morning routine ak bar hiu aata hai fir bhi likh rhe hai
//                        //                                arrDate.append(date)
//                        //                                arrDateString.append(dic["dateString"] as! String)
//                        //                                arrDuration.append(dic["Duration in seconds"] as! String)
//                    }
//                    // }
//                }
//                print(arrDateString)
//                if arrDateString.count == 30{/// adding fake date
//                    let firstDate = arrDate.first!
//                    let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
//                    let newStringDate = getStringFromDate(date: previousDate, dateFormat: "MM-dd-yyyy")
//                    arrDate.insert(previousDate, at: 0)
//                    arrDateString.insert(newStringDate, at: 0)
//                    arrDuration.insert("", at: 0)
//                }
//
//                //                var arrData = []
//                var maxInHabitsGraph = arrForMaxValue.max() ?? 0
//                if maxInHabitsGraph < 99{
//                    maxInHabitsGraph = maxInHabitsGraph + 10
//                }else if maxInHabitsGraph < 9999{
//                    maxInHabitsGraph = maxInHabitsGraph + 100
//                }else {
//                    maxInHabitsGraph = maxInHabitsGraph + 1000
//                }
//                maxInHabitsGraph = roundOffValue(number:maxInHabitsGraph)
//                var labelYVal = ""
//                if logQuantity{
//                    labelYVal = "Quantity"
//                }else{
//                    labelYVal = "Minutes"
//                }
//                var type = ""
//                if isDataWeekly{
//                    type = "weekly"
//                }else{
//                    type = "monthly"
//                }
//                let json = [ "label":"\(activityName)" , "labelX":"Date", "labelY":labelYVal, "data": arrDuration, "type":type, "max":maxInHabitsGraph] as [String : Any]
//                do {
//                    let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
//                    if let str = String(data: data, encoding: String.Encoding.utf8){
//                        print(str)
//
//
//                        let script = "getData(\(str));"
//
//
//                        DispatchQueue.global().async {
//                            usleep(500000)//0.5
//                            DispatchQueue.main.async {
//                                self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
//                                    print(html)
//                                })
//                            }
//                        }
//                    }
//                } catch let error as NSError {
//                    print(error)
//                }
//                return;
//
//
//            }else if currentState == ._ACTIVITY_{
//                webViewGraph1.isHidden = false
//                webViewGraph2.isHidden = false
//
////                var  fileURL = URL(string: graphDaysUrl)
//
//                var fileURL: URL?
//
//                if logQuantity{
//                    fileURL = URL(string: graphDaysUrl)
//                }else{
//                    fileURL = URL(string: graphDaysDurationUrl)
//                }
//
//
//                webViewGraph2.loadFileURL(fileURL!, allowingReadAccessTo: fileURL!)
//
//
//
//                let arrDic = readCsv(activityName: activityName, logType: "break")
//                print(arrDic)// 1 month data
//
//                // **********for graph second // monthly*******
//                var arrGraph1DurationOrQuantity = [String]()
//
//                var arrGraph1DateString = [String]()
//                var arrGraph1Date = [Date]()
//                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
//                let shutoffTime = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: startTime!.second, of: Date())!
//                let previousMonth = Calendar.current.date(byAdding: .day, value: -31, to: startDate) ?? startDate
//                var isDataWeekly = false
//                var lastDateAdded = previousMonth// qki pure 1 month ka data chahiye isiliye aaj ki date se -31  se kiya h taki 31 din ka data nilana bhake hi 15 din ka data ho to usse phle ka data fake cretae krenge
//
//                if let dic = arrDic.first{
//                    let date = dic["date"] as! Date
//                    let sevenDaysBeforeDate = Calendar.current.date(byAdding: .day, value: -6, to: startDate) ?? startDate
//                    if date.compare(sevenDaysBeforeDate) == .orderedDescending {
//                        isDataWeekly = true
//                    }
//                }
//                //  *************** creating 30 days data *****************    //
//                let arrDataForGraph = NSMutableDictionary()
//                for dic in arrDic{
//                    if let date = dic["date"] as? Date{
//                        // if date.compare(lastDateAdded) == .orderedDescending {// start ate k baad ka ho to
//                        // let date = dic["date"] as! Date
//                        let calendarDate = Calendar.current.dateComponents([.day, .year, .month], from: date)
//                        let calendarLastDate = Calendar.current.dateComponents([.day, .year, .month], from: lastDateAdded)
//
//
//                        if calendarDate.day != nil && calendarLastDate.day != nil{
//                            let stringDate = dic["dateString"] as! String
//
//                            let diffInDays = date.interval(ofComponent: .day, fromDate: lastDateAdded)
//
//                            //  stringDate = getStringFromDate(date: date, dateFormat: "HH:mm:ss")
//                            let duration = dic["Duration in seconds"] as! String
//                            let quantity = dic["Quantity Logged"] as! String
//
//
//
//                            if diffInDays == 1{
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
//                            }else{
//                                let missinDayCount = diffInDays - 1
//                                if missinDayCount > 0 {
//                                    for _ in 1...missinDayCount{
//                                        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDateAdded){
//                                            let newStringDate = getStringFromDate(date: newDate, dateFormat: "MM-dd-yyyy")
//                                            if newStringDate != stringDate{
//                                                let arr = [0]
//                                                let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":newDate]
//                                                arrDataForGraph[newStringDate] = ndic
//                                                lastDateAdded = newDate
//                                            }
//                                        }
//                                    }
//
//                                    var quantityOrDuration:Double = 0
//                                    if logQuantity{
//                                        quantityOrDuration = Double(quantity) ?? 0
//                                    }else{
//                                        quantityOrDuration = Double(duration) ?? 0
//                                    }
//                                    if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
//                                        var arr = [Double]()
//                                        if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
//                                            arr = nval
//                                        }
//                                        arr.append(quantityOrDuration)
//                                        data["arrQuantityOrDuration"] = arr
//                                        arrDataForGraph[stringDate] = data
//                                        lastDateAdded = date
//
//                                    }else{
//                                        let arr = [quantityOrDuration]
//                                        let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
//                                        arrDataForGraph[stringDate] = ndic
//                                        lastDateAdded = date
//                                    }
//
//                                }
//
//                                if diffInDays == 0{
//                                    var quantityOrDuration:Double = 0
//                                    if logQuantity{
//                                        quantityOrDuration = Double(quantity) ?? 0
//                                    }else{
//                                        quantityOrDuration = Double(duration) ?? 0
//                                    }
//                                    if let data = arrDataForGraph.value(forKey: stringDate) as? NSMutableDictionary{
//                                        var arr = [Double]()
//                                        if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
//                                            arr = nval
//                                        }
//                                        arr.append(quantityOrDuration)
//                                        data["arrQuantityOrDuration"] = arr
//                                        arrDataForGraph[stringDate] = data
//                                        lastDateAdded = date
//
//                                    }else{
//                                        let arr = [quantityOrDuration]
//                                        let ndic:NSMutableDictionary = ["arrQuantityOrDuration":arr, "date":date]
//                                        arrDataForGraph[stringDate] = ndic
//                                        lastDateAdded = date
//                                    }
//                                }
//                            }
//                        }
//                        //}
//                    }
//
//                }
//                //  **********************************************  //
//
//                var arrForMaxValueInSecondGraph = [Double]()
//                var arrGraphDictionary = [[String:Any]]()
//                for key in arrDataForGraph.allKeys as? [String] ?? []{
//
//                    var arrQuantity = [Double]()
//                    if let data = arrDataForGraph.value(forKey: key) as? NSMutableDictionary{
//                        if let nval = data.value(forKey: "arrQuantityOrDuration") as? [Double]{
//                            arrQuantity = nval
//                        }
//                        let sum = arrQuantity.reduce(0, +)
//                        var finalVal:Double = sum //default sum
//                        if logQuantity{
//                            if logQuantityType == "SUM"{
//                                finalVal = sum
//                            }else if logQuantityType == "AVG"{
//                                finalVal = sum/Double(arrQuantity.count)
//                            }
//                        }else{
//                            finalVal = sum
//                        }
//                        arrForMaxValueInSecondGraph.append(finalVal)
//                        let newStringDate = getStringFromDate(date: data.value(forKey: "date") as? Date ?? Date(), dateFormat: "yyyy-MM-dd")
//                        let date = data.value(forKey: "date") as? Date ?? Date()
//                        let dic = ["date":date, "stringDate":newStringDate, "value":"\(finalVal)"] as [String : Any]
//                        arrGraphDictionary.append(dic)
//                    }
//                }
//
//                arrGraphDictionary.sort { ($0["date"] as! Date).compare($1["date"] as! Date) == .orderedAscending }
//                if arrGraphDictionary.count == 30{/// adding fake date for making 31 days
//                    let firstDic = arrGraphDictionary.first!
//                    let firstDate = firstDic["date"] as? Date ?? Date()
//                    let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: firstDate) ?? firstDate
//                    let newStringDate = getStringFromDate(date: previousDate, dateFormat: "yyyy-MM-dd")
//
//                    let dic = ["date":previousDate, "stringDate":newStringDate, "value":"0"] as [String : Any]
//                    arrGraphDictionary.insert(dic, at: 0)
//                }
//                for graphData in arrGraphDictionary{
//                    arrGraph1Date.append(graphData["date"] as? Date ?? Date())
//                    arrGraph1DateString.append(graphData["stringDate"] as? String ?? "")
//                    arrGraph1DurationOrQuantity.append(graphData["value"] as? String ?? "")
//                }
//
//
//                print(arrGraphDictionary)
//
//                var maxInSecondGraph = arrForMaxValueInSecondGraph.max() ?? 0
//
//
//
//
//
//                var labelYVal = ""
//                if logQuantity{
//                    labelYVal = "Quantity"
//                }else{
//                    labelYVal = "Minutes"
//                }
//
//                if maxInSecondGraph < 99{
//                    maxInSecondGraph = maxInSecondGraph + 10
//                }else if maxInSecondGraph < 9999{
//                    maxInSecondGraph = maxInSecondGraph + 100
//                }else {
//                    maxInSecondGraph = maxInSecondGraph + 1000
//                }
//
//                maxInSecondGraph = roundOffValue(number:maxInSecondGraph)
//                var type = ""
//                if isDataWeekly{
//                    type = "weekly"
//                }else{
//                    type = "monthly"
//                }
//                let json = [ "label":"\(activityName)" , "labelX":"Date", "labelY":labelYVal, "data": arrGraph1DurationOrQuantity, "type":type, "max":maxInSecondGraph] as [String : Any]
//                do {
//                    let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
//                    if let str = String(data: data, encoding: String.Encoding.utf8){
//                        print(str)
//
//
//                        let script = "getData(\(str));"
//
//
//                        DispatchQueue.global().async {
//                            usleep(500000)//0.5
//                            DispatchQueue.main.async {
//                                self.webViewGraph2?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
//                                    print(html)
//                                })
//                            }
//                        }
//                    }
//                } catch let error as NSError {
//                    print(error)
//                }
//
//
//                // *****************************graph first****************************************
//                var graphUrlForDay: URL?
//
//                if logQuantity{
//                    graphUrlForDay = URL(string: graphTimeUrl)
//                }else{
//                    graphUrlForDay = URL(string: graphTimeDurationUrl)
//                }
//
//                webViewGraph1.loadFileURL(graphUrlForDay!, allowingReadAccessTo: graphUrlForDay!)
//
//                var arrGraph2Duration = [String]()
//
//                var arrGraph2DateString = [String]()
//                var arrGraph2Date = [Date]()
//
//                var arrForMaxValue = [Double]()
//
//
//                for dic in arrDic{
//                    // if let date = dic["date"] as? Date{
//
//                    let date = dic["date"] as! Date
//                    if date.compare(startDate) == .orderedDescending {
//                        let stringDate = dic["dateString"] as! String
//
//                        let duration = dic["Duration in seconds"] as! String
//                        let quantity = dic["Quantity Logged"] as! String
//                        if logQuantity{
//                            arrGraph2Date.append(date)
//                            let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
//                            arrGraph2DateString.append(newStringDate)
//                            arrGraph2Duration.append(quantity)
//                            let doubleQuantithy = Double(quantity) ?? 0
//                            arrForMaxValue.append(doubleQuantithy)
//                        }else{
//                            arrGraph2Date.append(date)
//                            let newStringDate = getStringFromDate(date: date, dateFormat: "yyyy-MM-dd HH:mm:ss")
//                            arrGraph2DateString.append(newStringDate)
//                            let doubleDuration = Double(duration) ?? 0
//                            arrGraph2Duration.append("\(doubleDuration)")
//                            arrForMaxValue.append(doubleDuration)
//                        }
//                    }
//                    //}
//                }
//
//                var max = arrForMaxValue.max() ?? 0
//                //              adding start and end time in arrGraph2Duration
//                arrGraph2DateString.insert(getStringFromDate(date: startDate, dateFormat: "yyyy-MM-dd HH:mm:ss"), at: 0)
//                arrGraph2DateString.append(getStringFromDate(date: shutoffTime, dateFormat: "yyyy-MM-dd HH:mm:ss"))
//
//                //              adding Blank values for start and end time in arrGraph2Duration
//                arrGraph2Duration.insert(" ", at: 0)
//                arrGraph2Duration.append(" ")
//
//                //"yyyy-MM-dd HH:mm:ss"
//                //                var labelVal = 0
//                //                var labelYVal = ""
//                if logQuantity{
//                    labelYVal = "Quantity"
//                }else{
//                    labelYVal = "Minutes"
//                }
//
//                if max < 99{
//                    max = max + 10
//                }else if max < 9999{
//                    max = max + 100
//                }else {
//                    max = max + 1000
//                }
//                let jsonForDay = ["label":activityName , "labelX":"Time", "labelY":labelYVal, "TimeValues":arrGraph2DateString, "data": arrGraph2Duration, "max":max] as [String : Any]
//
//
//
//                do {
//                    let data = try (JSONSerialization.data(withJSONObject: jsonForDay, options: .prettyPrinted))
//                    if let str = String(data: data, encoding: String.Encoding.utf8){
//                        print(str)
//
//
//                        let script = "getData(\(str));"
//
//
//                        DispatchQueue.global().async {
//                            usleep(500000)//0.5
//                            DispatchQueue.main.async {
//                                self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
//                                    print(html)
//                                })
//                            }
//                        }
//                    }
//                } catch let error as NSError {
//                    print(error)
//                }
//
//
//            }
//
//
//        }
        //file://
    }
    
    func loadHabitMonthlyGraphFromCsv(activityName:String, logQuantity:Bool, arrDic: [[String : Any]]){
        stackViewGraph.isHidden = false
        webViewGraph1.isHidden = false
        webViewGraph2.isHidden = true
        btnMainCenterY.constant = 100
        imgViewGifOpenPrefrences.isHidden = true
        webViewForVideo.isHidden = true
        if let graphDayspath = Bundle.main.path(forResource: "GraphDays", ofType: "html"), let graphDaysDurationpath = Bundle.main.path(forResource: "GraphDaysDuration", ofType: "html"){
            
            
            let graphDaysUrl = "file://\(graphDayspath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            let graphDaysDurationUrl = "file://\(graphDaysDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                
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
                if maxInHabitsGraph < 99{
                    maxInHabitsGraph = maxInHabitsGraph + 10
                }else if maxInHabitsGraph < 9999{
                    maxInHabitsGraph = maxInHabitsGraph + 100
                }else {
                    maxInHabitsGraph = maxInHabitsGraph + 1000
                }
                maxInHabitsGraph = roundOffValue(number:maxInHabitsGraph)
                var labelYVal = ""
                if logQuantity{
                    labelYVal = "Quantity"
                }else{
                    labelYVal = "Minutes"
                }
                var type = ""
                if isDataWeekly{
                    type = "weekly"
                }else{
                    type = "monthly"
                }
                let json = [ "label":"\(activityName)" , "labelX":"Date", "labelY":labelYVal, "data": arrDuration, "type":type, "max":maxInHabitsGraph] as [String : Any]
                do {
                    let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
                    if let str = String(data: data, encoding: String.Encoding.utf8){
                        print(str)
                        
                        
                        let script = "getData(\(str));"
                        
                        
                        DispatchQueue.global().async {
                            if lastActivityPerformedTime == nil{ //iska mtlb app start hotehi koi morning habit hui thi iska mtlb morning habit k bich mai hi app band ho gai thi ya fir dusre system per app start kreke baki habit yha start ki hai to old habit ka start time ni mika to usleep jyada dala qki graph load ni ho rha tha 
                                usleep(600000)
                            }else{
                                usleep(500000)
                            }
                        
                            DispatchQueue.main.async {
                                self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                    print(html)
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
//        imgViewGifOpenPrefrences.isHidden = true
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
        imgViewGifOpenPrefrences.isHidden = true
        webViewForVideo.isHidden = true
        if let graphTimepath = Bundle.main.path(forResource: "GraphTime", ofType: "html"), let graphGraphTimeDurationpath = Bundle.main.path(forResource: "GraphTimeDuration", ofType: "html"){
   

            let graphTimeUrl = "file://\(graphTimepath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            let graphTimeDurationUrl = "file://\(graphGraphTimeDurationpath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            webViewGraph1.isHidden = false

            
          
            
            
            
            
            
//            let arrDic = readCsv(activityName: activityName, logType: "break")
            print(arrDic)// 1 month data
            
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutoffTime = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: startTime!.second, of: Date())!
            
  
      

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
                labelYVal = "Quantity"
            }else{
                labelYVal = "Minutes"
            }
            
            if max < 99{
                max = max + 10
            }else if max < 9999{
                max = max + 100
            }else {
                max = max + 1000
            }
            let jsonForDay = ["label":activityName , "labelX":"Time", "labelY":labelYVal, "TimeValues":arrGraph2DateString, "data": arrGraph2Duration, "max":max] as [String : Any]
            
            
            
            do {
                let data = try (JSONSerialization.data(withJSONObject: jsonForDay, options: .prettyPrinted))
                if let str = String(data: data, encoding: String.Encoding.utf8){
                    print(str)
                    print("str1 is *************** str1")
                    
                    let script = "getData(\(str));"
                    
                    
                    DispatchQueue.global().async {
                        usleep(500000)//0.5//todo graph load ni ho rha kabhi kabhi
                        DispatchQueue.main.async {
                            self.webViewGraph1?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                print(html)
                                if error != nil{
                                    print("str1 error is *************** \(error)")
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
        imgViewGifOpenPrefrences.isHidden = true
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
            
            
            
            
            
            var labelYVal = ""
            if logQuantity{
                labelYVal = "Quantity"
            }else{
                labelYVal = "Minutes"
            }
            
            if maxInSecondGraph < 99{
                maxInSecondGraph = maxInSecondGraph + 10
            }else if maxInSecondGraph < 9999{
                maxInSecondGraph = maxInSecondGraph + 100
            }else {
                maxInSecondGraph = maxInSecondGraph + 1000
            }
            
            maxInSecondGraph = roundOffValue(number:maxInSecondGraph)
            var type = ""
            if isDataWeekly{
                type = "weekly"
            }else{
                type = "monthly"
            }
            let json = [ "label":"\(activityName)" , "labelX":"Date", "labelY":labelYVal, "data": arrGraph1DurationOrQuantity, "type":type, "max":maxInSecondGraph] as [String : Any]
            do {
                let data = try (JSONSerialization.data(withJSONObject: json, options: .prettyPrinted))
                if let str = String(data: data, encoding: String.Encoding.utf8){
                    print(str)
                    print("str is ***************")
                    
                    let script = "getData(\(str));"
                    
                    
                    DispatchQueue.global().async {
                        usleep(500000)//0.5
                        DispatchQueue.main.async {
                            self.webViewGraph2?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
                                print(html)
                                if error != nil{
                                    print("str error is *************** \(error)")
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
    func breathingFinished() {
        btnReviseQuantity.isHidden = true
        lblTimer.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 170
        lblProgress.isHidden = true
        imgViewGif.isHidden = true
        btnMain.title = unlockMachineButtonText
        mainViewControllerObj?.btnAbort.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
        webViewForVideo.isHidden = true
        boxBreathingFinished.isHidden = true
        customViewContainer.isHidden = false
        btnMain.isHidden = true
        var name = "Breathing"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                name = arr.first?.value(forKey: "name") as? String ?? ""
            }else{
                
            }
        }
        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: name)//"Breathing finished!✅ You’ve earned your screen time. 💪"
        
        if preloadFocusModesVcObj == nil{
            preloadFocusModesVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preloadFocusModesVc")) as? preloadFocusModesVc
        }
        customViewContainer.addSubview(preloadFocusModesVcObj!.view)
        customViewContainer.addConstraints(subView: preloadFocusModesVcObj!.view)

 
    }
    
    func btnFocesModesLodded(){
        imgViewGifOpenPrefrences.isHidden = true
        boxBreathingFinished.isHidden = false
        customViewContainer.isHidden = true
        btnMain.isHidden = false
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
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
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
        let lastHabit = arrAllMorningHabits[lastHabitIndex].name
        if arrAllMorningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(arrAllMorningHabits[lastHabitIndex].durationSeconds!)", logQuantityQuestion: arrAllMorningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._MORNING_HABIT_, logQuantityType: "", activity_id: arrAllMorningHabits[lastHabitIndex].id, activity_sequence_id: arrAllMorningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil)
        }else{
            
            

            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "morning routine", activity: lastHabit!, durationInSeconds: "\(arrAllMorningHabits[lastHabitIndex].durationSeconds!)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrAllMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(arrAllMorningHabits[lastHabitIndex].durationSeconds!)", quantity: "")
            allApiObject.activityCompletedApi(activity_id: arrAllMorningHabits[lastHabitIndex].id, activity_sequence_id: arrAllMorningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:arrAllMorningHabits[lastHabitIndex].durationSeconds!, choice_id: nil, completionHandler: {dic  in
                
                DispatchQueue.main.async {
                    
                }
                print(dic)
            })
        }
        
        
        
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllMorningHabits.count{
            totalSecondsAllHabits += arrAllMorningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllMorningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        
        var habitMinutesString: String = ""
        
        
        var totalMinutesString: String = ""
        
        
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        
        
        
        
        if index < arrAllMorningHabits.count-1 {
            
            imgViewGif.isHidden = true
            playEveryActivitySound()
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            
            
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else {
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.btnAbort.isHidden = true
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:true)
            isHabitAlreadyShowed = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
    }
    
    func morningHabitFinishedAndStartIncompleteNew(index:Int) {
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
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
        let lastHabit = arrAllMorningHabits[lastHabitIndex].name
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true

        allApiObject.getACtivityStats(activityId: arrAllMorningHabits[lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
            DispatchQueue.main.async {
                self.loadGraph(activityId: arrAllMorningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: arrAllMorningHabits[self.lastHabitIndex].logQuantity, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
            }
        })
        
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllMorningHabits.count{
            totalSecondsAllHabits += arrAllMorningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllMorningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        
        var habitMinutesString: String = ""
        
        
        var totalMinutesString: String = ""
        
        
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        
        
        
        
        if index < arrAllMorningHabits.count-1 {
            
            imgViewGif.isHidden = true
            playEveryActivitySound()
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            
            
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                let time = arrAllMorningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllMorningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else {
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = unlockMachineButtonText
            mainViewControllerObj?.btnAbort.isHidden = true
            btnMain.toolTip = btnMain.title
            playAfterMorningEveningRoutineSound(isMorning:true)
            isHabitAlreadyShowed = true
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
    }
    
    func eveningHabitFinished(index:Int) {
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
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
        let lastHabit = arrAllEveningHabits[lastHabitIndex].name
        stackViewGraph.isHidden = true
        if arrAllEveningHabits[lastHabitIndex].logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            logQuantityVcObj?.resetData(name: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[lastHabitIndex].durationSeconds!)", logQuantityQuestion: arrAllEveningHabits[lastHabitIndex].logQuantityQuestion, currentState: ._EVENING_HABIT_, logQuantityType: "", activity_id: arrAllEveningHabits[lastHabitIndex].id, activity_sequence_id: arrAllEveningHabits[lastHabitIndex].activity_sequence_id, activityChoiceId: nil)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "evening routine", activity: lastHabit!, durationInSeconds: "\(arrAllEveningHabits[lastHabitIndex].durationSeconds!)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: arrAllEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: lastActivityPerformedTime!, duration: "\(arrAllEveningHabits[lastHabitIndex].durationSeconds!)", quantity: "")
            allApiObject.activityCompletedApi(activity_id: arrAllEveningHabits[lastHabitIndex].id, activity_sequence_id: arrAllEveningHabits[lastHabitIndex].activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:arrAllEveningHabits[lastHabitIndex].durationSeconds!, choice_id: nil, completionHandler: {dic  in
                
                DispatchQueue.main.async {
                    
                }
                print(dic)
            })
        }
        
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllEveningHabits.count{
            totalSecondsAllHabits += arrAllEveningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllEveningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        
        var habitMinutesString: String = ""
        var totalMinutesString: String = ""
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        
        
        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        if index < arrAllEveningHabits.count-1 {
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            playEveryActivitySound()
            imgViewGif.isHidden = true
            
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else{
            if arrAllEveningHabits[lastHabitIndex].logQuantity{
                
            }else{
                startTimer(duration: 30)
            }
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.btnAbort.isHidden = true
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
        }
        
    }
    func eveningHabitFinishedAndStartIncompleteNew(index:Int) {
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
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
        let lastHabit = arrAllEveningHabits[lastHabitIndex].name
        stackViewGraph.isHidden = false
        self.webViewGraph1.isHidden = true
        self.webViewGraph2.isHidden = true

        
        allApiObject.getACtivityStats(activityId: arrAllEveningHabits[self.lastHabitIndex].id, activityChoiceId: nil, completionHandler: {dic in
            DispatchQueue.main.async {
                self.loadGraph(activityId: arrAllEveningHabits[self.lastHabitIndex].id, activityName: lastHabit ?? "", logQuantity: false, logQuantityType: "", activityChoiceId: nil,activityStartTime: nil, duration: "", quantity: "")
            }
        })
        
        var totalSecondsAllHabits = 0
        var habitCompletedSeconds = 0
        
        
        for i in 0..<arrAllEveningHabits.count{
            totalSecondsAllHabits += arrAllEveningHabits[i].durationSeconds
            if i<=index{
                habitCompletedSeconds += arrAllEveningHabits[i].durationSeconds
            }
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: habitCompletedSeconds)
        var habitHour = "\(h)"
        var habitMinute = "\(m)"
        var habitSecond = "\(s)"
        
        if habitHour.count == 1 {
            habitHour = "0\(h)"
        }
        
        if habitMinute.count == 1 {
            habitMinute = "0\(m)"
        }
        if habitSecond.count == 1 {
            habitSecond = "0\(s)"
        }
        
        let (hour,minute,second) = secondsToHoursMinutesSeconds(seconds: totalSecondsAllHabits - habitCompletedSeconds)
        var totalHour = "\(hour)"
        var totalMinute = "\(minute)"
        var totalSecond = "\(second)"
        
        if totalHour.count == 1 {
            totalHour = "0\(hour)"
        }
        
        if totalMinute.count == 1 {
            totalMinute = "0\(minute)"
        }
        if totalSecond.count == 1 {
            totalSecond = "0\(second)"
        }
        
        var habitMinutesString: String = ""
        var totalMinutesString: String = ""
        if h != 0{
            habitMinutesString = "\(h)h"
        }
        if m != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(m)m"
            }else{
                habitMinutesString += " \(m)m"
            }
        }
        if s != 0{
            if habitMinutesString.isEmpty{
                habitMinutesString = "\(s)s"
            }else{
                habitMinutesString += " \(s)s"
            }
        }
        
        if hour != 0{
            totalMinutesString = "\(hour)h"
        }
        if minute != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(minute)m"
            }else{
                totalMinutesString += " \(minute)m"
            }
        }
        if second != 0{
            if totalMinutesString.isEmpty{
                totalMinutesString = "\(second)s"
            }else{
                totalMinutesString += " \(second)s"
            }
        }
        
        
        
        
        if totalMinutesString.isEmpty{
            var finalSring = "You have completed <duration> of habits."
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsCompleteText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            lblProgress.stringValue = finalSring
        }else{
            var finalSring = "You have completed <duration> of habits - <totalduration> to go. You can do it!"
            if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                finalSring = activityInfo.value(forKey: "habitsProgressText") as? String ?? finalSring
            }
            finalSring = finalSring.replacingOccurrences(of: "<duration>", with: habitMinutesString)
            finalSring = finalSring.replacingOccurrences(of: "<totalduration>", with: totalMinutesString)
            lblProgress.stringValue = finalSring
        }
        
        if index < arrAllEveningHabits.count-1 {
            lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastHabit!)//"\(lastHabit!) finished!✅"
            playEveryActivitySound()
            imgViewGif.isHidden = true
            
            if SettingsManagerObject.isPromptToRememberHabit{
                if !isPromptToRememberHabitShowedInLastHabit{
                    randomIntToRememberNextHabit = Int.random(in: 0..<6)
                    if randomIntToRememberNextHabit == 5{
                        isPromptToRememberHabitShowedInLastHabit = true
                        btnMain.title = "What comes next?"
                        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                            btnMain.title = activityInfo.value(forKey: "whatComesNextButtonText") as? String ?? "What comes next?"
                        }
                        btnMain.toolTip = btnMain.title
                    }else{
                        isPromptToRememberHabitShowedInLastHabit = false
                        let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                        btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                        btnMain.toolTip = btnMain.title
                    }
                }else{
                    isPromptToRememberHabitShowedInLastHabit = false
                    let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                    btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                    btnMain.toolTip = btnMain.title
                }
            }else{
                let time = arrAllEveningHabits[lastHabitIndex+1].durationSeconds
                btnMain.title = getstartActivityButtonText(seconds: time!, name: arrAllEveningHabits[lastHabitIndex+1].name!)
                btnMain.toolTip = btnMain.title
            }
        }else{
            if arrAllEveningHabits[lastHabitIndex].logQuantity{
                
            }else{
                startTimer(duration: 30)
            }
            imgViewGif.isHidden = false
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastHabit!)
            btnMain.title = "Let's wrap up for the day"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                btnMain.title = common.value(forKey: "wrapupButtonText") as? String ?? btnMain.title
            }
            
            mainViewControllerObj?.btnAbort.isHidden = true
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
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        imgViewGifOpenPrefrences.isHidden = true
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
        var logQuantityQuestion:String?
        var logQuantityType:String?
        var activity_id:String = ""
        var activity_sequence_id = ""
        let activityChoiceId:String? = lastActivityChoice?.id
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].name//because name mai activitychoice ka name bhi ho skta h
                logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
                durationInSeconds = arrActivitiesIncludeInEveryBreak[lastActivityIndex].durationSeconds
                activity_id = arrActivitiesIncludeInEveryBreak[lastActivityIndex].id
                activity_sequence_id = arrActivitiesIncludeInEveryBreak[lastActivityIndex].activity_sequence_id
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].logQuantityQuestion
                logQuantityType = timerViewcontrollerObj?.logQuantityType ?? arrActivitiesIncludeInEveryBreak[lastActivityIndex].logQuantityType
//                activity_id =
            }else{
                lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].name
                logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
                durationInSeconds = arrActivitiesExcludeInEveryBreak[lastActivityIndex].durationSeconds
                activity_id = arrActivitiesExcludeInEveryBreak[lastActivityIndex].id
                activity_sequence_id = arrActivitiesExcludeInEveryBreak[lastActivityIndex].activity_sequence_id
                logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].logQuantityQuestion
                logQuantityType = timerViewcontrollerObj?.logQuantityType ?? arrActivitiesExcludeInEveryBreak[lastActivityIndex].logQuantityType
            }
        }else{
            lastActivity = timerViewcontrollerObj?.currentActicityTitle ?? arrAllbreakActivities[lastActivityIndex].name
            logQuantity = timerViewcontrollerObj?.logActivityQuantity ?? false
            durationInSeconds = arrActivitiesExcludeInEveryBreak[lastActivityIndex].durationSeconds
            activity_id = arrActivitiesExcludeInEveryBreak[lastActivityIndex].id
            activity_sequence_id = arrActivitiesExcludeInEveryBreak[lastActivityIndex].activity_sequence_id
            logQuantityQuestion = timerViewcontrollerObj?.logQuantityQuestion ?? arrAllbreakActivities[lastActivityIndex].logQuantityQuestion
            logQuantityType = timerViewcontrollerObj?.logQuantityType ?? arrAllbreakActivities[lastActivityIndex].logQuantityType
        }
        
        if logQuantity{
            webViewGraph1.isHidden = true
            webViewGraph2.isHidden = true
            mainViewControllerObj!.showLogQuantityView()
            logQuantityVcObj?.isReviseQuantity = false
            logQuantityVcObj?.resetData(name: lastActivity, durationInSeconds: "\(durationInSeconds)", logQuantityQuestion: logQuantityQuestion, currentState: ._ACTIVITY_, logQuantityType: logQuantityType ?? "", activity_id: activity_id, activity_sequence_id: activity_sequence_id,activityChoiceId:activityChoiceId)
        }else{
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "break", activity: lastActivity, durationInSeconds: "\(durationInSeconds)", quantityQuestion: "", quantityLogged: "", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            
            self.loadGraph(activityId: activity_id, activityName: lastActivity, logQuantity: logQuantity, logQuantityType: "", activityChoiceId: activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: "\(durationInSeconds)", quantity: "")
            allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:nil, duration_logged:durationInSeconds, choice_id: activityChoiceId, completionHandler: {dic  in
                
                DispatchQueue.main.async {
                    
                }
                print(dic)
            })
            
        }
        
        
        if isAnyMandatoryActivityIncluded{
            if isMandatoryActivityGoing{
                
                if index < arrActivitiesIncludeInEveryBreak.count-1 {
                    lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                    currentActivity = arrActivitiesIncludeInEveryBreak[lastActivityIndex+1]
                }else {
                    if arrActivitiesExcludeInEveryBreak.count == 0{
                        lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                        btnMain.title = unlockMachineButtonText
                        mainViewControllerObj?.btnAbort.isHidden = true
                        btnMain.toolTip = btnMain.title
                        imgViewGif.isHidden = false
                    }else{
                        lblTitle.stringValue = getActivityFinishedText(isLast: false, activityName: lastActivity)//"\(lastActivity) finished!✅"
                        currentActivityIndex = Int(arc4random_uniform(UInt32(arrActivitiesExcludeInEveryBreak.count)))
                        currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
                    }
                }
            }else{
                lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
                btnMain.title = unlockMachineButtonText
                mainViewControllerObj?.btnAbort.isHidden = true
                btnMain.toolTip = btnMain.title
                imgViewGif.isHidden = false
            }
        }else{
            lblTitle.stringValue = getActivityFinishedText(isLast: true, activityName: lastActivity)//"\(lastActivity) finished!✅ You’ve earned your screen time. 💪"
            btnMain.title = unlockMachineButtonText
            btnMain.toolTip = btnMain.title
            imgViewGif.isHidden = false
            mainViewControllerObj?.btnAbort.isHidden = true
        }
        
        
        if currentActivity != nil{
            
            var nextActivityName: String = ""
            
            
            if !currentActivity!.isRandomChoice{
                nextActivityName = currentActivity!.name
            }else{//random choice
                currentActivityChoice = currentActivity?.choices.randomElement()
                
                if currentActivity?.choices.count != 1{
                    if let lastChoice = lastShownRandomChoiceDic[currentActivity!.name]{
                        while lastChoice.name == currentActivityChoice!.name && lastChoice.logQuantityQuestion == currentActivityChoice!.logQuantityQuestion{
                            currentActivityChoice = currentActivity?.choices.randomElement()
                        }
                    }
                }
                
                
                lastShownRandomChoiceDic[currentActivity!.name ?? ""] = currentActivityChoice
                nextActivityName = currentActivityChoice?.name ?? ""
            }
            
            
            let time = currentActivity!.durationSeconds
            btnMain.title = getstartActivityButtonText(seconds: time!, name: nextActivityName)
            btnMain.toolTip = btnMain.title
        }
        playEveryActivitySound()
    }
    
    var currentActivityChoice:activityChoice?
    func startBreakActivity() {
        btnReviseQuantity.isHidden = true
        customViewContainer.isHidden = true
        lblTimer.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 0
        imgViewGifOpenPrefrences.isHidden = true
        webViewForVideo.isHidden = true
        boxBg.isHidden = false
        if rememberNextHabitVcObj != nil{
            if self.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj?.view.removeFromSuperview()
            }
        }
        lblProgress.isHidden = true
        currentActivityChoice = nil
        imgViewGif.isHidden = true
        boxBreathingFinished.isHidden = true
        lastActivityIndex = -1
        var activityName: String = ""
        var seconds: Int = 0
        var currentActivity:breakActivity?
        if isMandatoryActivityGoing{
            currentActivity = arrActivitiesIncludeInEveryBreak[currentActivityIndex]
        }else{
            currentActivity = arrActivitiesExcludeInEveryBreak[currentActivityIndex]
        }
        
        
        if !currentActivity!.isRandomChoice{
            activityName = currentActivity!.name
        }else{//random choice
            currentActivityChoice = currentActivity?.choices.randomElement()
            
            if currentActivity?.choices.count != 1{
                if let lastChoice = lastShownRandomChoiceDic[currentActivity!.name]{
                    while lastChoice.name == currentActivityChoice!.name && lastChoice.logQuantityQuestion == currentActivityChoice!.logQuantityQuestion{
                        currentActivityChoice = currentActivity?.choices.randomElement()
                    }
                }
            }
            
            
            lastShownRandomChoiceDic[currentActivity!.name ?? ""] = currentActivityChoice
            
            activityName = currentActivityChoice?.name ?? ""
        }
        
        seconds = currentActivity!.durationSeconds
        
        lblTitle.stringValue = getStartBreakActivityTitleText(seconds: seconds, activityName: activityName)//"It’s time for a break. Do \(seconds) seconds of \(activityName) to earn more screentime."
        btnMain.title = getstartActivityButtonText(seconds: seconds, name: activityName)//"Start \(seconds) seconds \(activityName)"
        btnMain.toolTip = btnMain.title
    }
    @IBAction func btnReviseQuantityClicked(_ sender: Any) {
        addLog(text:"thirdvc-btnReviseQuantityClicked")
        btnReviseQuantity.isHidden = true
        mainViewControllerObj!.showLogQuantityView()
        logQuantityVcObj?.isReviseQuantity = true
        logQuantityVcObj?.textFieldCount.stringValue = ""
        logQuantityVcObj?.textFieldCount.selectText(self)
        logQuantityVcObj?.textFieldCount.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
    }
    func loadBlankUrl(){
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webViewForVideo.load(request)
    }
    @IBAction func btnMainClicked(_ sender: Any) {
        addLog(text:"thirdvc-btnMainClicked")
        btnReviseQuantity.isHidden = true
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    return;
                }
            }
        }
        customViewContainer.isHidden = true
        lblProgress.isHidden = true
        imgViewGif.isHidden = true
        stackViewGraph.isHidden = true
        btnMainCenterY.constant = 0
        imgViewGifOpenPrefrences.isHidden = true
        webViewForVideo.isHidden = true
        boxBreathingFinished.isHidden = true
        if currentState == ._BREATHING_{
            loadBlankUrl()
            boxBreathingFinished.isHidden = true
            mainViewControllerObj?.breathingFinishedUnlockMachine()
        }else if currentState == ._ACTIVITY_ {
            if lastActivityIndex == -1 {
                mainViewControllerObj?.startCurrentActivity()
            }else{
                if isAnyMandatoryActivityIncluded{
                    if isMandatoryActivityGoing{
                        
                        if lastActivityIndex < arrActivitiesIncludeInEveryBreak.count-1 {
                            mainViewControllerObj?.changeActivity()
                        }else {
                            if arrActivitiesExcludeInEveryBreak.count == 0{
                                mainViewControllerObj?.activityFinishedUnlockMachine()
                            }else{
                                isMandatoryActivityGoing = false
                                mainViewControllerObj?.changeActivity()
                            }
                        }
                    }else{
                        mainViewControllerObj?.activityFinishedUnlockMachine()
                    }
                }else{
                    mainViewControllerObj?.activityFinishedUnlockMachine()
                }
            }
            
        }else if currentState == ._MORNING_HABIT_{
            if lastHabitIndex < arrAllMorningHabits.count-1 {
                if randomIntToRememberNextHabit == 5{
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
            if lastHabitIndex < arrAllEveningHabits.count-1 {
                if randomIntToRememberNextHabit == 5{
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
        }
    }
}







