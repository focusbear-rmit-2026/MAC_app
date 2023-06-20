//
//  takeActivityNotesVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class takeActivityNotesVc: NSViewController {

    @IBOutlet var textViewNotes: NSTextView!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Take Notes"
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            lblTitle.stringValue = activityInfo.value(forKey: "titleTakeNotes") as? String ?? lblTitle.stringValue
        }
        
        btnOk.title = buttonOkText
    }
    
    override func viewWillAppear() {
        textViewNotes.string = ""
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
    
    func resetData(durationInSeconds:Int, quantity_logged:Double?, activity_id:String, activity_sequence_id:String, activityChoiceId:String?, log_quantity_answers: [[String : Any]]){
        self.is_skipped = false
        self.activityChoiceId = nil
        self.activityChoiceId = activityChoiceId
        self.activity_id = activity_id
        self.activity_sequence_id = activity_sequence_id
        self.durationInSeconds = durationInSeconds
        self.quantity_logged = nil
        self.quantity_logged = quantity_logged
        self.log_quantity_answers = log_quantity_answers
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.removeFromSuperview()
        
        if isAnyAllowedFocusModeActivityWasRunningInLastActivity{
            let currentFocusModeName = currentRunningFocusType["name"] as? String ?? ""
            let currentFocusModeId = currentRunningFocusType["id"] as? String ?? ""
            
            mainViewControllerObj!.showFocusCompletedView()
            focusCompletedForActivityVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: isAnyAllowedFocusModeActivityFinishTime, durationInSeconds: durationInSeconds, quantity_logged:quantity_logged, activity_id: activity_id, activity_sequence_id: activity_sequence_id, activityChoiceId: activityChoiceId, log_quantity_answers: log_quantity_answers, notes: textViewNotes.string)
        }else{
            if currentState == ._EVENING_HABIT_{
                if thirdVcObj!.lastHabitIndex >= arrFilteredEveningHabits.count-1 {
                    thirdVcObj?.startTimer(duration: 30)// evening habit k baad 30 second k baad shutof ho jay isiliye ye timer lagaya
                }
            }
            var should_not_update_current_activity = false
            if currentState == ._SPECIAL_ACTIVITY_{
                should_not_update_current_activity = true
            }
            
            allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:lastActivityPerformedTime!, quantity_logged:quantity_logged, duration_logged:durationInSeconds, choice_id: activityChoiceId, is_skipped: is_skipped, notes: textViewNotes.string, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
                DispatchQueue.main.async {
                    
                }
                
                print(dic)
            })
        }
        
        
    }
}
