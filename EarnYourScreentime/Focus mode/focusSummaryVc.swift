//
//  focusSummaryVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 28/02/22.
//  Copyright © 2022 MugPhotography. All rights reserved.
//

import Cocoa

class focusSummaryVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var heightConstraints: NSLayoutConstraint!
    @IBOutlet weak var tblViewSummary: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnClickHere: underLineButton!
    
    var titleText = "You completed <COUNT> focus blocks today."
    var tableColumnFirstText = "Focus type"
    var tableColumnSecondText = "Start Time"
    var tableColumnThirdText = "Work Achieved"
    var tableColumnFourthText = "Distractions encountered"
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnClickHere.title = "Click here to see what you achieved."
        btnContinue.title = "Continue"
        
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
                if let tableColumnFirstText = focusSummaryInfo.value(forKey: "tableColumnFirstText") as? String{
                    self.tableColumnFirstText = tableColumnFirstText
                }
                if let tableColumnSecondText = focusSummaryInfo.value(forKey: "tableColumnSecondText") as? String{
                    self.tableColumnSecondText = tableColumnSecondText
                }
                if let tableColumnThirdText = focusSummaryInfo.value(forKey: "tableColumnThirdText") as? String{
                    self.tableColumnThirdText = tableColumnThirdText
                }
                if let tableColumnFourthText = focusSummaryInfo.value(forKey: "tableColumnFourthText") as? String{
                    self.tableColumnFourthText = tableColumnFourthText
                }
            }
        }
        
    }
    override func viewWillAppear() {
        btnClickHere.isHidden = false
        scrollView.isHidden = true
        readCsv()
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<COUNT>", with: "\(arrDic.count)")//"You completed \(arrDic.count) focus blocks today."
    }
    override func viewDidAppear() {
        
    }
    var arrDic = [[String:String]]()
    func readCsv(){
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        var arr = readDataFromCSV(url: quantityCsvURL!)
        print(arr)
        arrDic.removeAll()
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
                                        arrDic.append(dic)
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            
        }
//        tblViewSummary.reloadData()
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
        if arrDic.count > 14{
            heightConstraints.constant = ((NSScreen.main?.frame.height ?? 1080) - 500)
        }else{
            heightConstraints.constant = 291
        }
        scrollView.isHidden = false
        tblViewSummary.reloadData()
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
        
        return arrDic.count
    }
//    func tableView(_ tableView: NSTableView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
//        return false
//    }
//    func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
//        return false
//    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell_list"), owner: nil) as? NSTableCellView {
            
            if tableColumn != nil{
                if tableColumn == tblViewSummary.tableColumns[0]{
                    tableColumn?.title = tableColumnFirstText
                    cell.textField?.stringValue = arrDic[row]["Activity"] ?? ""
                    
                }else if tableColumn == tblViewSummary.tableColumns[1]{
                    tableColumn?.title = tableColumnSecondText
                    cell.textField?.stringValue = arrDic[row]["Start Time"] ?? ""
                }else if tableColumn == tblViewSummary.tableColumns[2]{
                    tableColumn?.title = tableColumnThirdText
                    cell.textField?.stringValue = arrDic[row]["Work achieved"] ?? ""
                }else if tableColumn == tblViewSummary.tableColumns[3]{
                    tableColumn?.title = tableColumnFourthText
                    cell.textField?.stringValue = arrDic[row]["Distractions encountered"] ?? ""
                }
            }
            
         return cell
        }
        return NSTableCellView()
    }
}
