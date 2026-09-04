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


    @IBOutlet weak var heightTableView: NSLayoutConstraint!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblError: NSTextField!
    //    @IBOutlet weak var textFieldQuantityFormatter: TextFieldNumberFormatter!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: cursorButton!
    //@IBOutlet weak var textFieldCount: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    //@IBOutlet weak var sliderQuantity: NSSlider!
    ///@IBOutlet weak var lblSliderValue: NSTextField!
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
//        textFieldCount.delegate = self
        lblTitle.stringValue = "Log Quantity of activity"
        btnOk.title = "OK"
        btnCancel.title = "Cancel"
        btnCancel.isSecondaryButton = true
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
//        let formatter = TwoDigitFormatter()
////        formatter.maximumFractionDigits = 2
////        formatter.minimumFractionDigits = 0
//        textFieldCount.formatter = formatter
        
//        textFieldQuantityFormatter.maximumFractionDigits = 2
//        textFieldQuantityFormatter.minimumFractionDigits = 0
        
//        tblView.allowsColumnSelection = true
    }
    
    
    var take_notes:String = ""
    var notes:String = ""
    var textFieldStringCount = 0
    var is_skipped = false
    // #2012: this popup is logging a PAST morning habit from the Day Plan (not the live routine). Forces
    // should_not_update_current_activity: true so the running evening routine is untouched, and marks the
    // habit done in the Day Plan on completion. pastHabitId is the habit whose row should strike through.
    var isPastHabit = false
    var pastHabitId: String?
    var pastHabitDayKey: String?      // yyyy-MM-dd of the backdated completion (for per-day strike-through)
    var logQuantityQuestions:[quantityQuestion] = [quantityQuestion]()
//    var currentQuestionIndex = 0
    func resetData(name:String, durationInSeconds:String, logQuantityQuestion:String?, currentState:CURRENTSTATE, logQuantityType:String, activity_id:String, activity_sequence_id:String, activityChoiceId:String?, take_notes:String, notes:String, logQuantityQuestions:[quantityQuestion]){
        self.is_skipped = false
        self.isPastHabit = false          // cleared each open; the past-habit caller re-sets it after resetData
        self.pastHabitId = nil
        self.pastHabitDayKey = nil
        self.activityChoiceId = nil
        self.activityChoiceId = activityChoiceId
        self.activity_id = activity_id
        self.activity_sequence_id = activity_sequence_id
        lblError.isHidden = true
        self.lCurrentState = currentState
        self.name = name
        self.durationInSeconds = durationInSeconds
        self.logQuantityType = logQuantityType
        //textFieldCount.stringValue = ""
        var subTitle = logQuantityQuestion ?? logQuantityQuestionText
        if subTitle.isEmpty{// if logQuantityQuestion is ""
            subTitle = logQuantityQuestionText
        }
        subTitle = subTitle.replacingOccurrences(of: "<activity>", with: name)
        self.logQuantityQuestion = subTitle
        lblSubTitle.stringValue = subTitle
        btnOk.isEnabled = true
        self.take_notes = take_notes
        self.notes = notes
        self.logQuantityQuestions = logQuantityQuestions
        if self.logQuantityQuestions.isEmpty {
            // A log-quantity habit with no questions list (older settings only carried the single
            // `logQuantityQuestion` string): show one free-entry field for it rather than an empty
            // sheet whose OK had nothing to read.
            addLog(text: "logQuantityVc.resetData: no questions for \(name) — using the single legacy question")
            self.logQuantityQuestions = [quantityQuestion(id: "", minValue: 0, maxValue: 0, question: subTitle,
                                                          logQuantityType: logQuantityType, minValueDescription: "", maxValueDescription: "")]
        }
        var height = self.logQuantityQuestions.count * 74
        if height > 296{
            height = 296
        }
        
        
        
        for i in 0..<logQuantityQuestions.count{
            if logQuantityQuestions[i].maxValue == 0 && logQuantityQuestions[i].minValue == 0{
                self.logQuantityQuestions[i].quantity = 0
            }else{
                self.logQuantityQuestions[i].quantity = (Double(logQuantityQuestions[i].minValue) + Double(logQuantityQuestions[i].maxValue)) / 2
            }
        }
        heightTableView.constant = CGFloat(height)
        tblView.reloadData()
        
        for i in 0..<tblView.numberOfRows{
            if let item = tblView.view(atColumn: 0, row: i, makeIfNecessary: true) as? tblCellLogQuantity{
                if item.textFieldCount.isHidden == false{
                    tblView.scrollRowToVisible(i)
                    item.textFieldCount.setFocus()
                    break;
                }else if item.lblSliderValue.isHidden == false{
                    tblView.scrollRowToVisible(i)
                    item.lblSliderValue.setFocusAndSelectText()
                    break;
                }
            }
        }
    }

    func tabClickedSelectNextTextField()->Bool{
        if logQuantityQuestions.count > 1{
            for row in 0..<logQuantityQuestions.count{
                if let cell = tblView.view(atColumn: 0, row: row, makeIfNecessary: true) as? tblCellLogQuantity{
                    if cell.textFieldCount.isFirstResponder || cell.lblSliderValue.isFirstResponder{
                        var newRow = row
                        if row == logQuantityQuestions.count - 1{
                            newRow = 0
                        }else{
                            newRow = row + 1
                        }
                        tblView.scrollRowToVisible(newRow)
                        if let cell = tblView.view(atColumn: 0, row: newRow, makeIfNecessary: true) as? tblCellLogQuantity{
                            if !cell.lblSliderValue.isHidden{
                                cell.lblSliderValue.setFocus()
                            }else{
                                cell.textFieldCount.setFocus()
                            }
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        addLog(text:"[user-action] Log quantity-btnCancelClicked")
        if lastActivityPerformedTime == nil{// nil is not possible but we are doing this
            lastActivityPerformedTime = Date()
        }

        self.view.removeFromSuperview()
        if isReviseQuantity{
            addLog(text:"Log quantity-btnCancelClicked return - isReviseQuantity")
            if lCurrentState! == ._EVENING_HABIT_{
                if activityCompletionVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                    activityCompletionVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                }
            }
            activityCompletionVcObj?.btnReviseQuantity.isHidden = false
           return
        }
        
        var isUsingActionBar = false
        if getHabitsVcObject().habitsView.subviews.contains(firstViewControllerObj!.view){
            isUsingActionBar = true
        }else if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_ && (leftMenuVcObj?.boxHabits.isSelected ?? false){
            if let habitsStateVcObj = habitsStateVcObj{
                if getHabitsVcObject().habitsView.subviews.contains(habitsStateVcObj.view){
                    isUsingActionBar = true
                }
            }
        }
        
        if !isUsingActionBar{ // it means user has not used quick action bar
            activityCompletionVcObj?.logQuantityQuestionsForGraph.removeAll()
            activityCompletionVcObj?.loadGraph(activityId: self.activity_id, activityName: self.name, logQuantity: true, logQuantityType: self.logQuantityType, activityChoiceId: self.activityChoiceId,activityStartTime: lastActivityPerformedTime!, duration: durationInSeconds, quantity: "0")
               
        }


        let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")

        var logType = ""
        if lCurrentState == nil{
            logType = "break"
        }else if lCurrentState! == ._MORNING_HABIT_{
            logType = "morning routine"
        }else if lCurrentState! == ._EVENING_HABIT_{
            logType = "evening routine"
        }else if lCurrentState! == ._MICRO_BREAK_{
            logType = "break"
        }else if lCurrentState! == ._SPECIAL_ACTIVITY_{
            logType = "special activity"
        }else if lCurrentState! == ._CUSTOM_ROUTINE_{
            logType = "custom routine"
        }

        addEntryInStatsCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: "0.0", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")

        if take_notes == END_OF_ACTIVITY{
            getHabitsVcObject().showTakeNotesView()
            takeActivityNotesVcObj?.resetData(durationInSeconds: Int(durationInSeconds) ?? 0, quantity_logged:0.0, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: [])
            takeActivityNotesVcObj?.isPastHabit = isPastHabit   // #2012: carry the past-habit flag through
            takeActivityNotesVcObj?.pastHabitId = pastHabitId
                takeActivityNotesVcObj?.pastHabitDayKey = pastHabitDayKey

        }else if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
            let currentFocusModeName = currentRunningFocusType["name"] as? String ?? ""
            let currentFocusModeId = currentRunningFocusType["id"] as? String ?? ""

            getHabitsVcObject().showFocusCompletedView()
            focusModeActualDurationPerformed = Int(durationInSeconds) ?? 0
            focusCompletedForActivityVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: isAnyAllowedFocusModeActivityFinishTime, durationInSeconds: Int(durationInSeconds) ?? 0, quantity_logged:0.0, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: [], notes: notes)
        }else if isPastHabit{
            // #2012: a PAST habit → offline-sync (/completed-activity/sync) so it lands on the right
            // date's sequence log (with that day's stats) and never disturbs the live routine.
            recordPastHabitCompletionViaOfflineSync(activity_id: activity_id, activity_sequence_id: activity_sequence_id, performedAt: lastActivityPerformedTime!, duration: Int(durationInSeconds) ?? 0, quantity: 0.0, notes: notes, dayKey: pastHabitDayKey ?? "")
        }else{
            if lCurrentState! == ._EVENING_HABIT_{
                if activityCompletionVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                    activityCompletionVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                }
            }

            var should_not_update_current_activity = false
            if lCurrentState == ._SPECIAL_ACTIVITY_{
                should_not_update_current_activity = true
            }

            allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:0.0, duration_logged:Int(durationInSeconds) ?? 0, choice_id: activityChoiceId, is_skipped: is_skipped, notes: notes, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: [], completionHandler: {dic  in
                DispatchQueue.main.async {

                }

                print(dic)
            })

        }

    }

    
    /// The first question's answer — the value the stats CSV and the completed-activity API record as
    /// "quantity logged". Never index the array directly: a prompt can open with NO questions (a habit
    /// flagged log-quantity whose questions list is empty), and `[0]` on that crashed the app
    /// (Sentry FOCUS-BEAR-MACOS-1C6).
    private var loggedQuantity: Double { logQuantityQuestions.first?.quantity ?? 0 }

    @IBAction func btnOkClicked(_ sender: Any) {
        addLog(text:"[user-action] Log quantity-btnOkClicked")
        
        if lastActivityPerformedTime == nil{// nil is not possible but we are doing this
            lastActivityPerformedTime = Date()
        }

        let startTime = getStringFromDate(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")

        var logType = ""
        if lCurrentState == nil{
            logType = "break"
        }else if lCurrentState! == ._MORNING_HABIT_{
            logType = "morning routine"
        }else if lCurrentState! == ._EVENING_HABIT_{
            logType = "evening routine"
        }else if lCurrentState! == ._MICRO_BREAK_{
            logType = "break"
        }else if lCurrentState! == ._SPECIAL_ACTIVITY_{
            logType = "special activity"
        }else if lCurrentState! == ._CUSTOM_ROUTINE_{
            logType = "custom routine"
        }

        if !isReviseQuantity{
            addEntryInStatsCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: "\(loggedQuantity)", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
        }else{
            replaceLastEntryInStatsCsv(logType: logType, activity: name, durationInSeconds: durationInSeconds, quantityQuestion: logQuantityQuestion, quantityLogged: "\(loggedQuantity)", startTime: startTime, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
        }



        self.view.removeFromSuperview()
        
        var isUsingActionBar = false
        if getHabitsVcObject().habitsView.subviews.contains(firstViewControllerObj!.view){
            isUsingActionBar = true
        }else if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_ && (leftMenuVcObj?.boxHabits.isSelected ?? false){
            if let habitsStateVcObj = habitsStateVcObj{
                if getHabitsVcObject().habitsView.subviews.contains(habitsStateVcObj.view){
                    isUsingActionBar = true
                }
            }
        }
        
        if !isUsingActionBar{ // it means user has not used quick action bar
            activityCompletionVcObj?.currentGraphIndex = 0
            activityCompletionVcObj?.logQuantityQuestionsForGraph = logQuantityQuestions
            activityCompletionVcObj?.loadGraph(activityId: self.activity_id, activityName: self.name, logQuantity: true, logQuantityType: self.logQuantityType, activityChoiceId: self.activityChoiceId, activityStartTime: lastActivityPerformedTime!, duration: durationInSeconds, quantity: "\(loggedQuantity)")
        }
        
        var log_quantity_answers = [[String : Any]]()
        for question in logQuantityQuestions{
            let val = Double(round(100 * question.quantity) / 100)
            log_quantity_answers.append(["question_id": question.id ?? "", "logged_value": val])
        }
        if !isReviseQuantity{
            
            if take_notes == END_OF_ACTIVITY{
                getHabitsVcObject().showTakeNotesView()
                takeActivityNotesVcObj?.resetData(durationInSeconds: Int(durationInSeconds) ?? 0, quantity_logged:loggedQuantity, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: log_quantity_answers)
                takeActivityNotesVcObj?.isPastHabit = isPastHabit   // #2012: carry the past-habit flag through
                takeActivityNotesVcObj?.pastHabitId = pastHabitId
                takeActivityNotesVcObj?.pastHabitDayKey = pastHabitDayKey
            }else if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
                let currentFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                let currentFocusModeId = currentRunningFocusType["id"] as? String ?? ""

                getHabitsVcObject().showFocusCompletedView()
                focusModeActualDurationPerformed = Int(durationInSeconds) ?? 0
                focusCompletedForActivityVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: isAnyAllowedFocusModeActivityFinishTime, durationInSeconds: Int(durationInSeconds) ?? 0, quantity_logged:loggedQuantity, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: log_quantity_answers, notes: notes)
            }else if isPastHabit{
                // #2012: a PAST habit → offline-sync (/completed-activity/sync) so it lands on the right
                // date's sequence log (with that day's stats) and never disturbs the live routine.
                recordPastHabitCompletionViaOfflineSync(activity_id: activity_id, activity_sequence_id: activity_sequence_id, performedAt: lastActivityPerformedTime!, duration: Int(durationInSeconds) ?? 0, quantity: loggedQuantity, notes: notes, dayKey: pastHabitDayKey ?? "")
            }else{
                if lCurrentState! == ._EVENING_HABIT_{
                    if activityCompletionVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                        activityCompletionVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                    }
                }
                var should_not_update_current_activity = false
                if lCurrentState == ._SPECIAL_ACTIVITY_{
                    should_not_update_current_activity = true
                }

                allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:loggedQuantity, duration_logged:Int(durationInSeconds) ?? 0, choice_id: activityChoiceId, is_skipped:is_skipped, notes: notes, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
                    DispatchQueue.main.async {

                    }

                })
            }

        }else{
            if allApiObject.completedActivityLogId == nil{// it mean activity completed api error found or was offline when activity completed api executed so replace in offline activity data


                let calendar = Calendar.current
                let finish_time = calendar.date(byAdding: .second, value: Int(durationInSeconds) ?? 0, to: lastActivityPerformedTime!) ?? Date()

                let start_time_string = getStringFromDateInUtc(date: lastActivityPerformedTime!, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")

                let finish_time_string = getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")

                replaceLastEntryInActivitiesCsv(activity_id: activity_id, duration_logged: durationInSeconds, device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: "", choice_id: activityChoiceId ?? "", quantity_logged: "\(loggedQuantity)", skipped_did_not_complete: "")

            }else{
                allApiObject.activityCompletedReviseApi(activity_id: allApiObject.completedActivityLogId ?? "", quantity_logged:loggedQuantity, choice_id: allApiObject.completedChoiceLogId, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
                    DispatchQueue.main.async {
                        print(dic)
                    }

                })
            }
            if lCurrentState! == ._EVENING_HABIT_{
                if activityCompletionVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                    activityCompletionVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                }
            }
        }
        
    }

    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            lblError.isHidden = true
            
            if textfield.tag < 0{
                return;
            }
            
            if let item = tblView.view(atColumn: 0, row: textfield.tag, makeIfNecessary: false) as? tblCellLogQuantity{
                if item.lblSliderValue == textfield{
                    let value = textfield.stringValue
                    let result = value.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
                    let doubleValue = Double(result) ?? item.sliderQuantity.doubleValue
                    if doubleValue < item.sliderQuantity.minValue{
                        //value = item.sliderQuantity.minValue
                    }else if doubleValue > item.sliderQuantity.maxValue{
                        //value = item.sliderQuantity.maxValue
                    }else{
                        item.sliderQuantity.doubleValue = doubleValue
                        logQuantityQuestions[textfield.tag].quantity = doubleValue
                        item.lblSliderValue.stringValue = result
                    }
                    
                }
            }
        }
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            lblError.isHidden = true
            if textfield.tag < 0{
                return;
            }
            
            if let item = tblView.view(atColumn: 0, row: textfield.tag, makeIfNecessary: false) as? tblCellLogQuantity{
                if item.textFieldCount == textfield{
                    logQuantityQuestions[textfield.tag].quantity = textfield.doubleValue
                }
            }
            
        }
    }
    
    
}


extension logQuantityVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return logQuantityQuestions.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellLogQuantity"), owner: nil) as? tblCellLogQuantity {
            
            if row < logQuantityQuestions.count{
                if logQuantityQuestions[row].maxValue == 0 && logQuantityQuestions[row].minValue == 0{
                    cell.textFieldCount.isHidden = false
                    cell.sliderQuantity.isHidden = true
                    cell.lblSliderValue.isHidden = true
                    cell.textFieldCount.delegate = self
                    cell.textFieldCount.tag = row
                    let formatter = TwoDigitFormatter()
                    cell.textFieldCount.formatter = formatter
                    cell.topSpaceStackView.constant = 10
                    cell.lblMinimumDescription.isHidden = true
                    cell.lblMaximumDescription.isHidden = true
                    cell.lblMinimum.isHidden = true
                    cell.lblMaximum.isHidden = true
                    cell.textFieldCount.stringValue = ""
                }else{
                    cell.textFieldCount.isHidden = true
                    cell.sliderQuantity.isHidden = false
                    cell.sliderQuantity.minValue = Double(logQuantityQuestions[row].minValue)
                    cell.sliderQuantity.maxValue = Double(logQuantityQuestions[row].maxValue)
                    cell.lblSliderValue.isHidden = false
                    cell.sliderQuantity.doubleValue = logQuantityQuestions[row].quantity
                    cell.topSpaceStackView.constant = 24
                    cell.lblMinimum.isHidden = false
                    cell.lblMaximum.isHidden = false
                    cell.lblSliderValue.delegate = self
                    cell.lblSliderValue.tag = row
                    let val = Double(round(100 * cell.sliderQuantity.doubleValue) / 100)
                    cell.lblSliderValue.stringValue = "\(val)"
                    if logQuantityQuestions[row].minValueDescription.isEmpty{
                        cell.lblMinimumDescription.isHidden = true
                    }else{
                        cell.lblMinimumDescription.isHidden = false
                        cell.lblMinimumDescription.stringValue = logQuantityQuestions[row].minValueDescription
                    }
                    
                    if logQuantityQuestions[row].maxValueDescription.isEmpty{
                        cell.lblMaximumDescription.isHidden = true
                    }else{
                        cell.lblMaximumDescription.isHidden = false
                        cell.lblMaximumDescription.stringValue = logQuantityQuestions[row].maxValueDescription
                    }
                    
                    cell.lblMinimum.stringValue = "(\(logQuantityQuestions[row].minValue ?? 0))"
                    cell.lblMaximum.stringValue =  "(\(logQuantityQuestions[row].maxValue ?? 0))"
                    
                    cell.sliderQuantity.target = self
                    cell.sliderQuantity.tag = row
                    cell.sliderQuantity.action = #selector(sliderClicked(sender:))
                    
                }
                
                
                
                cell.lblQuestion.stringValue = logQuantityQuestions[row].question
            }
            return cell
        }
        return NSTableCellView()
    }
    
    @objc func sliderClicked(sender:NSSlider){
        if let item = tblView.view(atColumn: 0, row: sender.tag, makeIfNecessary: false) as? tblCellLogQuantity{
            if item.sliderQuantity == sender{
                logQuantityQuestions[sender.tag].quantity = sender.doubleValue
                
                let val = Double(round(100 * sender.doubleValue) / 100)
                item.lblSliderValue.stringValue = "\(val)"
            }
        }
        
    }
}

