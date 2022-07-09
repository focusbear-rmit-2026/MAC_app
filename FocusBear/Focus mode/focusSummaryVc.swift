//
//  focusSummaryVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/02/22.


import Cocoa

class focusSummaryVc: NSViewController {

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
    @IBOutlet weak var btnClickHere: underLineButton!
    @IBOutlet weak var lblActivitySummary: NSTextField!
    @IBOutlet weak var lblFocusSummary: NSTextField!
   
    
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
        btnClickHere.isHidden = true
        btnNeedMoreTime.title = "I need one more minute"
//        btnClickHere.title = "Click here to see what you achieved."
        btnContinue.title = "Continue"
        lblActivitySummary.stringValue = "Activity Summary:"
        lblFocusSummary.stringValue = "Focus Summary:"
        
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
        readCsv()
        
        scrollViewFocusSummary.isHidden = false
        tblViewFocusSummary.reloadData()
        scrollViewActivitySummaryTotal.isHidden = false
        scrollViewActivitySummaryAverage.isHidden = false
        scrollViewActivitySummaryDuration.isHidden = false
        tblViewActivitySummaryTotal.reloadData()
        tblViewActivitySummaryAverage.reloadData()
        tblViewActivitySummaryDuration.reloadData()
        lblTotalFocusTime.isHidden = false
        lblFocusSummary.isHidden = false
        lblActivitySummary.isHidden = false
        
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<COUNT>", with: "\(arrFocusSummaryDic.count)")//"You completed \(arrFocusSummaryDic.count) focus blocks today."
    }
    override func viewDidAppear() {
        
    }
    var arrFocusSummaryDic = [[String:String]]()
    
    var arrActivitySummaryTotalDic = [[String:String]]()
    var arrActivitySummaryAverageDic = [[String:String]]()
    var arrActivitySummaryDurationDic = [[String:String]]()
    
    func readCsv(){
        var arrActivitySummaryDic = [[String:String]]()
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        
//       startDate = Calendar.current.date(byAdding: .day, value: -10, to: startDate)!// remove this
        
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
                        
                        
                        
                        
                        
                        
                        if logQuantityType == "average"{
                            if total != 0{
                                average = total/Double(arr.count)
                            }
                            summaryDic["average"] = "\(average)"
                            arrActivitySummaryAverageDic.append(summaryDic)
                            continue;
                        }else{//default sum
                            summaryDic["totalQuantity"] = "\(total)"
                            arrActivitySummaryTotalDic.append(summaryDic)
                            continue;
                        }
                        
                        //                    summaryDic["max"] = "\(max)"
                        //                    summaryDic["min"] = "\(min)"
                        
                    }
                }
                
                if let arr = dic["DurationArr"] as? [Int]{
                    let total = arr.reduce(0, +)
                    summaryDic["totalDuration"] = "\(total)"
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
                if activity.isRandomChoice{
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
//    @IBAction func btnClickHereToSeeClicked(_ sender: Any) {
////        btnClickHere.isHidden = true
//        scrollViewFocusSummary.isHidden = false
//        tblViewFocusSummary.reloadData()
//        scrollViewActivitySummaryTotal.isHidden = false
//        scrollViewActivitySummaryAverage.isHidden = false
//        scrollViewActivitySummaryDuration.isHidden = false
//        tblViewActivitySummaryTotal.reloadData()
//        tblViewActivitySummaryAverage.reloadData()
//        tblViewActivitySummaryDuration.reloadData()
//        lblTotalFocusTime.isHidden = false
//        lblFocusSummary.isHidden = false
//        lblActivitySummary.isHidden = false
//    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "button continue Clicked from focus summary")
        currentState = ._NOTHING_
        appdelegate?.shutOffMac()
    }
    @IBAction func btnNeedMoreTimeClicked(_ sender: Any) {
        addLog(text: "button Need one More minute Clicked from focus summary")
        btnNeedMoreTime.isHidden = true
        mainViewControllerObj?.giveOneMoreMinuteBeforeShutOffMac()
    }
}


extension focusSummaryVc: NSTableViewDelegate, NSTableViewDataSource {
    /*
    focus type
    start time
    work achived
    destruction encountered
    */
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
                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["totalQuantity"] ?? ""
                    }
                    
//                    else if tableColumn == tblViewActivitySummaryTotal.tableColumns[2]{
//                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["average"] ?? ""
////                    }else if tableColumn == tblViewActivitySummaryTotal.tableColumns[3]{
////                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["max"] ?? ""
////                    }else if tableColumn == tblViewActivitySummaryTotal.tableColumns[4]{
////                        cell.textField?.stringValue = arrActivitySummaryTotalDic[row]["min"] ?? ""
//                    }
                }
            }else if tableView == tblViewActivitySummaryAverage{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummaryAverage.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryAverageDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummaryAverage.tableColumns[1]{
                        cell.textField?.stringValue = arrActivitySummaryAverageDic[row]["average"] ?? ""
                        
                    }
                }
            }else if tableView == tblViewActivitySummaryDuration{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummaryDuration.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryDurationDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummaryDuration.tableColumns[1]{
                        
                        
                        if let duration = arrActivitySummaryDurationDic[row]["totalDuration"]{
                            if let seconds = Int(duration){
                                let strTime = getStringTimeFromSeconds(seconds:seconds)
                                cell.textField?.stringValue = strTime
                            }
                        }else{
                            cell.textField?.stringValue = arrActivitySummaryDurationDic[row]["totalDuration"] ?? ""
                        }
                        
                    }
                }
            }
            
         return cell
        }
        return NSTableCellView()
    }
}
