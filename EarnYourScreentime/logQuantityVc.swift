//
//  logQuantityVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 12/02/22.

//

import Cocoa

class logQuantityVc: NSViewController, NSTextFieldDelegate {


    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var btnOk: cursorButton!
    @IBOutlet weak var textFieldCount: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    var name = ""
    var durationInSeconds = ""
    var logQuantityQuestion = ""
    var lCurrentState:CURRENTSTATE?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textFieldCount.delegate = self
        lblTitle.stringValue = "Log Quantity of activity"
        btnOk.title = "OK"
        btnCancel.title = "Cancel"
        
        if let logQuantityInfo = configjson.value(forKey: "logQuantityInfo") as? NSDictionary{
            if let buttonCancelText = logQuantityInfo.value(forKey: "buttonCancelText") as? String{
                btnCancel.title = buttonCancelText
            }
            if let buttonOkText = logQuantityInfo.value(forKey: "buttonOkText") as? String{
                btnOk.title = buttonOkText
            }
            if let title = logQuantityInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            
        }
        
        
    }
    func resetData(name:String, durationInSeconds:String, logQuantityQuestion:String?, currentState:CURRENTSTATE){
//        getStringFromDate"yyyy-MM-dd HH:mm:ss"
        //lastActivityPerformedTime
        self.lCurrentState = currentState
        self.name = name
        self.durationInSeconds = durationInSeconds
        textFieldCount.stringValue = ""
//        print(timestamp)
        var subTitle = logQuantityQuestion ?? "How many <activity> did you do?"
        if subTitle.isEmpty{// if logQuantityQuestion is ""
            subTitle = "How many <activity> did you do?"
        }
        self.logQuantityQuestion = subTitle
        lblSubTitle.stringValue = subTitle.replacingOccurrences(of: "<activity>", with: name)
        textFieldCount.selectText(self)
        textFieldCount.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        btnOk.isEnabled = false
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.removeFromSuperview()
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
//        do {
//            var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
//
//            let timestamp = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
//            let quantityPerformed = textFieldCount.stringValue
//            let csvString = "\(timestamp),\(name),\(durationInSeconds),\(quantityPerformed)\n"
//            csv = csv.appending(csvString)
//            do {
//                try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
//            } catch {
//                print("error creating file")
//            }
//        }catch{
//            print(error)
//        }
        var logType = ""
        if lCurrentState == nil{
            logType = "break"
        }else if lCurrentState! == ._MORNING_HABIT_{
            logType = "morning routine"
        }else if lCurrentState! == ._EVENING_HABIT_{
            logType = "evening routine"
        }else if lCurrentState! == ._ACTIVITY_{
            logType = "break"
        }
        addEntryInCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: textFieldCount.stringValue, startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        self.view.removeFromSuperview()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldCount{
                let count = textfield.integerValue
                textfield.stringValue = "\(count)"
                if textfield.stringValue.count > 4{
                    textfield.stringValue = "9999"
                }
                if textfield.stringValue.isEmpty{
                    btnOk.isEnabled = false
                }else{
                    btnOk.isEnabled = true
                }
            }
        }
    }
}
