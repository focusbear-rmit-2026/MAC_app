//
//  focusSummaryVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 28/02/22.


import Cocoa

class focusSummaryVc: NSViewController {

    @IBOutlet weak var lblTotalFocusTime: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var scrollViewFocusSummary: NSScrollView!
    @IBOutlet weak var scrollViewActivitySummary: NSScrollView!
    //    @IBOutlet weak var heightConstraints: NSLayoutConstraint!
    @IBOutlet weak var tblViewActivitySummary: NSTableView!
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
    var activityTableColumnFourthText = "Max"
    var activityTableColumnFifthText = "Min"
    var activityTableColumnSixthText = "Total Duration"
    var totalFocusTimeText = "Total focus time: <TIME>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        btnClickHere.title = "Click here to see what you achieved."
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
                if let buttonClickHereText = focusSummaryInfo.value(forKey: "buttonClickHereText") as? String{
                    btnClickHere.title = buttonClickHereText
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
                if let activityTableColumnFourthText = focusSummaryInfo.value(forKey: "activityTableColumnFourthText") as? String{
                    self.activityTableColumnFourthText = activityTableColumnFourthText
                }
                if let activityTableColumnFifthText = focusSummaryInfo.value(forKey: "activityTableColumnFifthText") as? String{
                    self.activityTableColumnFifthText = activityTableColumnFifthText
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
        lblTotalFocusTime.isHidden = true
        btnClickHere.isHidden = false
        scrollViewFocusSummary.isHidden = true
        scrollViewActivitySummary.isHidden = true
        lblFocusSummary.isHidden = true
        lblActivitySummary.isHidden = true
        readCsv()
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<COUNT>", with: "\(arrFocusSummaryDic.count)")//"You completed \(arrFocusSummaryDic.count) focus blocks today."
    }
    override func viewDidAppear() {
        
    }
    var arrFocusSummaryDic = [[String:String]]()
    var arrActivitySummaryDic = [[String:String]]()
    func readCsv(){
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
            var arrQuantity = [Int]()
            var intQuantity = -1
            if let quantity = dic["Quantity Logged"] {
                if let intVal = Int(quantity){
                    intQuantity = intVal
                }
            }
            if let arr = oldDic["QuantityLoggedArr"] as? [Int]{
                arrQuantity = arr
            }
            if intQuantity != -1{
                arrQuantity.append(intQuantity)
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
        for key in newDic.keys{
            if let dic = newDic[key] as? [String:Any]{
                var summaryDic = [String:String]()
                summaryDic["Activity"] = key
                
                if let arr = dic["DurationArr"] as? [Int]{
                    let total = arr.reduce(0, +)
                    summaryDic["totalDuration"] = "\(total)"
                }
                
                if let arr = dic["QuantityLoggedArr"] as? [Int]{
                    
                    var total = 0
                    var min = 0
                    var max = 0
                    var average = 0
                    
                    
                    max = arr.max() ?? max
                    min = arr.min() ?? min
                    total = arr.reduce(0, +)
                    if total != 0{
                        average = total/arr.count
                    }
                    
                    summaryDic["max"] = "\(max)"
                    summaryDic["min"] = "\(min)"
                    summaryDic["totalQuantity"] = "\(total)"
                    summaryDic["average"] = "\(average)"
                }
                arrActivitySummaryDic.append(summaryDic)
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
    func readDataFromCSV(url:URL)-> [[String]]{
        
        
        
        var arrItems = [[String]]()
        if let string = try? String(contentsOf: url){
            print(string)
            let arrCsv = csv(data: string)
            print(arrCsv)
            for item in arrCsv{
                if let row = item.first{
                    print(row)
                    var arrHeaders = [String]()
                    let arrString = getArrItem(data: row)
                    //                    if arrHeaders.count == 0{
                    for header in arrString{
                        if header != "\r"{
                            arrHeaders.append(header)
                        }
                    }
                    arrItems.append(arrHeaders)
                    
                }
                
            }
            
        }
        return arrItems
    }
    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ";")
            result.append(columns)
        }
        return result
    }
    func getArrItem(data: String) -> [String] {
        var result: [String] = []
        result = data.components(separatedBy: ",")
        return result
    }
    @IBAction func btnClickHereToSeeClicked(_ sender: Any) {
        btnClickHere.isHidden = true
        scrollViewFocusSummary.isHidden = false
        tblViewFocusSummary.reloadData()
        scrollViewActivitySummary.isHidden = false
        tblViewActivitySummary.reloadData()
        lblTotalFocusTime.isHidden = false
        lblFocusSummary.isHidden = false
        lblActivitySummary.isHidden = false
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        currentState = ._NOTHING_
        appdelegate?.shutOffMac()
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
        }else if tableView == tblViewActivitySummary{
            for i in 0..<tableView.tableColumns.count{
                let tableColumn = tableView.tableColumns[i]
                if i == 0{
                    tableColumn.title = activityTableColumnFirstText
                }else if i == 1{
                    tableColumn.title = activityTableColumnSecondText
                }else if i == 2{
                    tableColumn.title = activityTableColumnThirdText
                }else if i == 3{
                    tableColumn.title = activityTableColumnFourthText
                }else if i == 4{
                    tableColumn.title = activityTableColumnFifthText
                }else if i == 5{
                    tableColumn.title = activityTableColumnSixthText
                }
            }
            
            return arrActivitySummaryDic.count
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
            }else if tableView == tblViewActivitySummary{
                if tableColumn != nil{
                    if tableColumn == tblViewActivitySummary.tableColumns[0]{
                        cell.textField?.stringValue = arrActivitySummaryDic[row]["Activity"] ?? ""
                    }else if tableColumn == tblViewActivitySummary.tableColumns[1]{
                        cell.textField?.stringValue = arrActivitySummaryDic[row]["totalQuantity"] ?? ""
                    }else if tableColumn == tblViewActivitySummary.tableColumns[2]{
                        cell.textField?.stringValue = arrActivitySummaryDic[row]["average"] ?? ""
                    }else if tableColumn == tblViewActivitySummary.tableColumns[3]{
                        cell.textField?.stringValue = arrActivitySummaryDic[row]["max"] ?? ""
                    }else if tableColumn == tblViewActivitySummary.tableColumns[4]{
                        cell.textField?.stringValue = arrActivitySummaryDic[row]["min"] ?? ""
                    }else if tableColumn == tblViewActivitySummary.tableColumns[5]{
                        
                        
                        if let duration = arrActivitySummaryDic[row]["totalDuration"]{
                            if let seconds = Int(duration){
                                let strTime = getStringTimeFromSeconds(seconds:seconds)
                                cell.textField?.stringValue = strTime
                            }
                        }else{
                            cell.textField?.stringValue = arrActivitySummaryDic[row]["totalDuration"] ?? ""
                        }
                        
                    }
                }
            }
            
         return cell
        }
        return NSTableCellView()
    }
}
