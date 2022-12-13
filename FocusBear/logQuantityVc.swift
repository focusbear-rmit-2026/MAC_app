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
    @IBOutlet weak var btnCancel: Button!
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
    var activity_id:String = ""
    var activity_sequence_id:String = ""
    var activityChoiceId:String?
    
    var logQuantityQuestionText = "How many <activity> did you do?"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        textFieldCount.delegate = self
        lblTitle.stringValue = "Log Quantity of activity"
        btnOk.title = "OK"
        btnCancel.title = "Cancel"
        btnCancel.buttonColor = NSColor.white.cgColor
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
            if let title = logQuantityInfo.value(forKey: "logQuantityQuestionText") as? String{
                logQuantityQuestionText = title
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
    var is_skipped = false
    func resetData(name:String, durationInSeconds:String, logQuantityQuestion:String?, currentState:CURRENTSTATE, logQuantityType:String, activity_id:String, activity_sequence_id:String, activityChoiceId:String?){
//        getStringFromDate"yyyy-MM-dd HH:mm:ss"
        //lastActivityPerformedTime
        self.is_skipped = false
        self.activityChoiceId = nil
        self.activityChoiceId = activityChoiceId
        self.activity_id = activity_id
        self.activity_sequence_id = activity_sequence_id
        lblError.isHidden = true
        self.lCurrentState = currentState
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.logQuantityType = logQuantityType
        textFieldCount.stringValue = ""
//        print(timestamp)
        var subTitle = logQuantityQuestion ?? logQuantityQuestionText
        if subTitle.isEmpty{// if logQuantityQuestion is ""
            subTitle = logQuantityQuestionText
        }
        subTitle = subTitle.replacingOccurrences(of: "<activity>", with: name)
        self.logQuantityQuestion = subTitle
        lblSubTitle.stringValue = subTitle
        textFieldCount.selectText(self)
        textFieldCount.currentEditor()?.selectedRange = NSRange(location: 0, length: 0)
        btnOk.isEnabled = true
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text:"Log quantity-btnCancelClicked")
        if lastActivityPerformedTime == nil{// nil is not possible but we are doing this
            lastActivityPerformedTime = Date()
        }
        
        self.view.removeFromSuperview()
        if isReviseQuantity{
            addLog(text:"Log quantity-btnCancelClicked return - isReviseQuantity")
           return
        }
        thirdVcObj?.loadGraph(activityId: self.activity_id, activityName: self.name, logQuantity: true, logQuantityType: self.logQuantityType, activityChoiceId: self.activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: durationInSeconds, quantity: "0")
        
        allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:0.0, duration_logged:Int(durationInSeconds) ?? 0, choice_id: activityChoiceId, is_skipped: is_skipped, completionHandler: {dic  in
            DispatchQueue.main.async {
                
            }
            
            print(dic)
        })
       
        if lCurrentState! == ._EVENING_HABIT_{
            if thirdVcObj!.lastHabitIndex >= arrAllEveningHabits.count-1 {
                thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
            }
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text:"Log quantity-btnOkClicked")
        
        if lastActivityPerformedTime == nil{// nil is not possible but we are doing this
            lastActivityPerformedTime = Date()
        }
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
            
            thirdVcObj?.loadGraph(activityId: self.activity_id, activityName: self.name, logQuantity: true, logQuantityType: self.logQuantityType, activityChoiceId: self.activityChoiceId, activityStartTime: lastActivityPerformedTime!, duration: durationInSeconds, quantity: "\(doubleVal)")
            
            if !isReviseQuantity{
                allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:doubleVal, duration_logged:Int(durationInSeconds) ?? 0, choice_id: activityChoiceId, is_skipped:is_skipped, completionHandler: {dic  in
                    DispatchQueue.main.async {
                        
                    }

                })
            }else{
                allApiObject.activityCompletedReviseApi(activity_id: allApiObject.completedActivityLogId ?? "", quantity_logged:doubleVal, choice_id: allApiObject.completedChoiceLogId, completionHandler: {dic  in
                    DispatchQueue.main.async {
                        print(dic)
                    }

                })
            }
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
