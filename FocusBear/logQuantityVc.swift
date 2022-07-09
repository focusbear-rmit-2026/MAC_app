//
//  logQuantityVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/02/22.

//

import Cocoa

class TwoDigitFormatter: NumberFormatter {

    let maxLength = 13

    let wrongCharacterSet = CharacterSet(charactersIn: "0123456789.").inverted
     override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        self.maximumFractionDigits = 2
        self.minimumFractionDigits = 0

        if partialString.count > maxLength {
                return false
        }
        if partialString.rangeOfCharacter(from: wrongCharacterSet) != nil {
                return false


        }

        return true

    }
}
class logQuantityVc: NSViewController, NSTextFieldDelegate {


    @IBOutlet weak var lblError: NSTextField!
    //    @IBOutlet weak var textFieldQuantityFormatter: TextFieldNumberFormatter!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var btnOk: cursorButton!
    @IBOutlet weak var textFieldCount: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var name = ""
    var durationInSeconds = ""
    var logQuantityQuestion = ""
    var logQuantityType = ""
    var lCurrentState:CURRENTSTATE?
    var isReviseQuantity = false
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
        let formatter = TwoDigitFormatter()
//        formatter.maximumFractionDigits = 2
//        formatter.minimumFractionDigits = 0
        textFieldCount.formatter = formatter
        
//        textFieldQuantityFormatter.maximumFractionDigits = 2
//        textFieldQuantityFormatter.minimumFractionDigits = 0
    }
    var textFieldStringCount = 0
    func resetData(name:String, durationInSeconds:String, logQuantityQuestion:String?, currentState:CURRENTSTATE, logQuantityType:String){
//        getStringFromDate"yyyy-MM-dd HH:mm:ss"
        //lastActivityPerformedTime
        lblError.isHidden = true
        self.lCurrentState = currentState
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.logQuantityType = logQuantityType
        textFieldCount.stringValue = ""
//        print(timestamp)
        var subTitle = logQuantityQuestion ?? "How many <activity> did you do?"
        if subTitle.isEmpty{// if logQuantityQuestion is ""
            subTitle = "How many <activity> did you do?"
        }
        subTitle = subTitle.replacingOccurrences(of: "<activity>", with: name)
        self.logQuantityQuestion = subTitle
        lblSubTitle.stringValue = subTitle
        textFieldCount.selectText(self)
        textFieldCount.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        btnOk.isEnabled = true
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.removeFromSuperview()
        thirdVcObj?.loadGraph(activityName: name, logQuantity: true, logQuantityType: logQuantityType)
        if lCurrentState! == ._EVENING_HABIT_{
            if thirdVcObj!.lastHabitIndex >= arrAllEveningHabits.count-1 {
                thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
            }
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        if textFieldCount.stringValue.isEmpty{
            lblError.isHidden = false//
            lblError.stringValue = "Log quantity can not be empty."
            if let logQuantityInfo = configjson.value(forKey: "logQuantityInfo") as? NSDictionary{
                if let quantityIsEmptyText = logQuantityInfo.value(forKey: "quantityIsEmptyText") as? String{
                    lblError.stringValue = quantityIsEmptyText
                }
            }
            return;
        }
        //
        if let doubleVal = Double(textFieldCount.stringValue){
            let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")

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
            
            if !isReviseQuantity{
                addEntryInCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: "\(doubleVal)", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            }else{
               replaceLastEntryInCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: "\(doubleVal)", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            }
            
            self.view.removeFromSuperview()
            thirdVcObj?.loadGraph(activityName: name, logQuantity: true, logQuantityType: logQuantityType)
            
            
            if lCurrentState! == ._EVENING_HABIT_{
                if thirdVcObj!.lastHabitIndex >= arrAllEveningHabits.count-1 {
                    thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                }
            }
        }else{
            lblError.isHidden = false
            lblError.stringValue = "Please enter a valid value."
            if let logQuantityInfo = configjson.value(forKey: "logQuantityInfo") as? NSDictionary{
                if let enterValidValueText = logQuantityInfo.value(forKey: "enterValidValueText") as? String{
                    lblError.stringValue = enterValidValueText
                }
            }
        }
        

        
    }

    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldCount{
                //print(textfield.stringValue)
                lblError.isHidden = true
            }
        }
    }
    
    
}
