//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedForActivityVc: NSViewController {
    
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var textFieldDistractions: NSTextField!
    @IBOutlet weak var textFieldAchieve: NSTextField!
    //@IBOutlet weak var btnStartAnotherFocusBlock: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    //@IBOutlet weak var btnTakeBreak: Button!
    //@IBOutlet weak var lblIntentionWas: NSTextField!
    //@IBOutlet var textViewIntention: NSTextView!
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Take a 5 minute break"
    var currentFocusModeId = ""
    var finish_time:Date?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        btnContinue.title = "Continue"
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        lblTitle.stringValue = "You did it!"
        lblQuestionFirst.stringValue = "What did you achieve during this time?"
        lblQuestionSecond.stringValue = "Any distractions?"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                if let title = focusCompletedInfo.value(forKey: "title") as? String{
                    lblTitle.stringValue = title
                }
                if let subTitle = focusCompletedInfo.value(forKey: "subTitle") as? String{
                    subTitleText = subTitle
                }
                if let questionFirstText = focusCompletedInfo.value(forKey: "questionFirstText") as? String{
                    lblQuestionFirst.stringValue = questionFirstText
                }
                if let questionSecondText = focusCompletedInfo.value(forKey: "questionSecondText") as? String{
                    lblQuestionSecond.stringValue = questionSecondText
                }
                if let buttonTakeBreakText = focusCompletedInfo.value(forKey: "buttonTakeBreakText") as? String{
                    self.buttonTakeBreakText = buttonTakeBreakText
                }
            }
        }
    }
    

    var is_skipped = false
    var durationInSeconds = 0
    var logQuantityQuestion = ""
    var isReviseQuantity = false
    var activity_id:String = ""
    var activity_sequence_id:String = ""
    var activityChoiceId:String?
    var quantity_logged:Double?
    var log_quantity_answers: [[String : Any]] = []
    var notes = ""

    
    func resetData(focusModeName:String, currentFocusModeId:String, finish_time:Date, durationInSeconds:Int, quantity_logged:Double?, activity_id:String, activity_sequence_id:String, activityChoiceId:String?, log_quantity_answers: [[String : Any]], notes:String){
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textFieldAchieve.stringValue = ""
        textFieldDistractions.stringValue = ""
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)

        self.is_skipped = false
        self.activityChoiceId = nil
        self.activityChoiceId = activityChoiceId
        self.activity_id = activity_id
        self.activity_sequence_id = activity_sequence_id
        self.durationInSeconds = durationInSeconds
        self.quantity_logged = nil
        self.quantity_logged = quantity_logged
        self.log_quantity_answers = log_quantity_answers
        self.notes = notes
    }

    @IBAction func btnContinueClicked(_ sender: Any) {
        
        self.view.removeFromSuperview()
        if currentState == ._EVENING_HABIT_{
            if thirdVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
            }
        }
        var should_not_update_current_activity = false
        if currentState == ._SPECIAL_ACTIVITY_{
            should_not_update_current_activity = true
        }
        
        allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:quantity_logged, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: is_skipped, notes: notes, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
            DispatchQueue.main.async {
                
            }
            
            print(dic)
        })
        
        
        
        
        
        whatToAchieveInFocusBlock = ""
        appdelegate!.setIntentionInBrainDumpWindow()

        
        
        let timestamp = getStringFromDate(date: lastActivityPerformedTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let achievements = textFieldAchieve.stringValue.components(separatedBy: .newlines).joined()
        let distractionsEncountered = textFieldDistractions.stringValue.components(separatedBy: .newlines).joined()
        focusModeActualDurationPerformed = durationInSeconds
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "")

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })

    }
}

