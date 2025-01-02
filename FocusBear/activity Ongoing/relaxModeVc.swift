//
//  relaxModeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class relaxModeVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnIAmDone: Button!
    @IBOutlet weak var btnRemove: NSButton!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    var arrWebsitesInfo = [WebsiteInfo]()
    struct WebsiteInfo{
        var state:Bool = false
        var info:NSDictionary?
    }
    var titleTimeRemainingText = "Time remaining:"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Sites you saved for relax mode:"
        btnRemove.toolTip = "Remove Selected URLs"
        btnIAmDone.title = "I'm done relaxing. Start winding down!"
        
        
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
        }
        
        if let relaxModeVcInfo = configjson.value(forKey: "relaxModeVcInfo") as? NSDictionary{
            lblTitle.stringValue = relaxModeVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnRemove.toolTip = relaxModeVcInfo.value(forKey: "toolTipRemoveUrls") as? String ?? btnRemove.toolTip
            btnIAmDone.title = relaxModeVcInfo.value(forKey: "buttonActivityDoneText") as? String ?? btnIAmDone.title
        }
        
    }
    func startTimerHabit(durationSeconds:Int, currentTimerValue:Int) {
        arrWebsitesInfo.removeAll()
        loader.startAnimation(self)
        loader.isHidden = false
        tblView.reloadData()
        
        allApiObject.getSavedWebsite(completionHandler: {arrJson in
            
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                self.loader.isHidden = true
                if arrJson != nil{
                    for info in arrJson!{
                        let websiteInfo = WebsiteInfo(state: false, info: info)
                        self.arrWebsitesInfo.append(websiteInfo)
                    }
                    self.tblView.reloadData()
                }
            }
        })
        
        
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

        currentTimer = currentTimerValue
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"
        
        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        if h == 0{
            self.lblTimer.stringValue = "\(titleTimeRemainingText) \(minute):\(second)"
        }else{
            self.lblTimer.stringValue = "\(titleTimeRemainingText) \(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func performTimerCount() {
        currentTimer += 1
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
        var hour = "\(h)"
        var minute = "\(m)"
        var second = "\(s)"

        if hour.count == 1 {
            hour = "0\(h)"
        }
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            if h == 0{
                self.lblTimer.stringValue = "\(self.titleTimeRemainingText) \(minute):\(second)"
            }else{
                self.lblTimer.stringValue = "\(self.titleTimeRemainingText) \(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.view.window?.close()
            }
        }
        
    }
    @IBAction func btnRemoveClicked(_ sender: Any) {
        var i = 0
        var totalArrayCount = arrWebsitesInfo.count
        while i < totalArrayCount{
            if arrWebsitesInfo[i].state {
                if let info = arrWebsitesInfo[i].info{
                    let id = info.value(forKey: "id") as? String ?? ""
                    allApiObject.deleteSavedWebsite(UUID: id, completionHandler: {result in
                        
                    })
                }
                arrWebsitesInfo.remove(at: i)
                totalArrayCount -= 1
            }else{
                i += 1
            }
        }
        tblView.reloadData()
    }
    @IBAction func btnIAmDoneClicked(_ sender: Any) {
        self.timer?.invalidate()
        self.view.window?.close()
        if timerViewcontrollerObj != nil{
            timerViewcontrollerObj!.currentTimer = timerViewcontrollerObj!.totalDuration
        }
    }
    func closeTimerBox(){
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        self.view.window?.close()
    }
}


extension relaxModeVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrWebsitesInfo.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellUrlRelaxMode"), owner: nil) as? tblCellUrlRelaxMode {

            cell.lblTitle.stringValue = arrWebsitesInfo[row].info!.value(forKey: "url") as? String ?? ""
            cell.checkBox.target = self
            cell.checkBox.tag = row
            cell.checkBox.action = #selector(btnCheckBoxXlixked(sender:))
            
            if arrWebsitesInfo[row].state {
                cell.checkBox.state = .on
            }else{
                cell.checkBox.state = .off
            }
            return cell
        }

        return NSTableCellView()
    }
    
    @objc func btnCheckBoxXlixked(sender:NSButton){
        if arrWebsitesInfo[sender.tag].state {
            arrWebsitesInfo[sender.tag].state = false
        }else{
            arrWebsitesInfo[sender.tag].state = true
        }
        tblView.reloadData()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblView.selectedRow == -1{
            return
        }
        var url = arrWebsitesInfo[tblView.selectedRow].info!.value(forKey: "url") as? String ?? ""
        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
            url = "http://"+url
        }
        NSWorkspace.shared.open(URL(string: url)!)
        tblView.reloadData()
        addLog(text: "[user-action] relaxModeVc:- OpenUrlClicked")
        allApiObject.capturePosthog(event: "relaxMode-open-url-clicked", metadata: [:])
    }
}
