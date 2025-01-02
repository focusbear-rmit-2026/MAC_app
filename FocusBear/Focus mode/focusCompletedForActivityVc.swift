//
//  focusCompletedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class focusCompletedForActivityVc: NSViewController {
    
    @IBOutlet weak var boxTempForShowToolTip: NSBox!
    @IBOutlet weak var lblTitleTags: NSTextField!
    @IBOutlet weak var tokenFieldTags: NSTokenField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var textFieldDistractions: NSTextField!
    @IBOutlet weak var textFieldAchieve: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    let kUserdefaultsShowTextForTokenFieldFirstTime = "kUserdefaultsShowTextForTokenFieldFirstTime"
    
    var currentFocusModeName = ""
    var subTitleText = "You have successfully completed the focus block - <FOCUSTYPE>"
    var buttonTakeBreakText = "Take a 5 minute break"
    var currentFocusModeId = ""
    var finish_time:Date?
    var arrAllTags = [String]()
    var defaultTokenMenu = NSMenu()
    var currentFocusModeIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tokenFieldTags.delegate = self
        lblTitleTags.stringValue = "Reporting Tags" 
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
                lblTitleTags.stringValue = focusCompletedInfo.value(forKey: "titleTags") as? String ?? lblTitleTags.stringValue
            }
        }
    }
    
    override func viewWillDisappear() {
        if addTaskVcObj != nil{
            if addTaskVcObj!.presentingViewController == self{
                addTaskVcObj!.dismiss(addTaskVcObj!)
                allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-closed", metadata: [:])
            }
        }
    }
    override func viewDidAppear() {
        if !focusModeTaskString.isEmpty{
            let obj = getAddTaskVcObject()
            obj.loadView()
            obj.reloadData(isAddingTask: false)
            self.presentAsSheet(obj)
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-shown", metadata: [:])
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
        arrAllTags.removeAll()
        for tagInfo in arrAllFocusModeTags{
            arrAllTags.append(tagInfo["text"] ?? "")
        }
        self.currentFocusModeName = focusModeName
        self.currentFocusModeId = currentFocusModeId
        self.finish_time = finish_time
        textFieldAchieve.stringValue = ""
        textFieldDistractions.stringValue = ""
        lblSubTitle.stringValue = subTitleText.replacingOccurrences(of: "<FOCUSTYPE>", with: currentFocusModeName)

        
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String ?? "" == currentFocusModeId{
                currentFocusModeIndex = i
                break;
            }
        }
        
        if let tags = arrFocusType[currentFocusModeIndex]["tags"] as? [String]{
            tokenFieldTags.objectValue = tags
        }
        
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

    @objc private func menuItemClicked(_ menuItem: NSMenuItem) {
        if let fieldEditor = tokenFieldTags?.currentEditor() {
            let textRange = fieldEditor.selectedRange
            let replaceString = menuItem.title
            fieldEditor.replaceCharacters(in: textRange, with: replaceString)
            fieldEditor.selectedRange = NSMakeRange(textRange.location, replaceString.count)
        }
    }
//    func updateAllFocusModeTags(){
//        arrAllTags.removeAll()
//        var arrJson = [[String: Any]]()
//        for focusType in arrFocusType{
//            var json: [String: Any] = [
//                "id":focusType["id"] as? String ?? "",
//                "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
//                "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
//                "name":focusType["name"] as? String ?? "",
//                "metadata": [:]
//            ]
//            var tagsDic = [[String:Any]]()
//            if let tags = focusType["tags"] as? [String]{
//                for tag in tags{
//                    tagsDic.append(["id": getIdForTag(tag: tag), "text": tag])
//                }
//            }
//            json["tags"] = tagsDic
//            
//            var dic = focusType
//            dic.removeValue(forKey: "name")
//            dic.removeValue(forKey: "id")
//            dic.removeValue(forKey: "allowed_urls")
//            dic.removeValue(forKey: "allowed_apps")
//            dic.removeValue(forKey: "tags")
//            json["metadata"] = dic
//            arrJson.append(json)
//        }
//        allApiObject.updateAllFocusMode(focusModes: arrJson, completionHandler: {json in
//            
//        })
//    }
    
    func getTagsString()->String{
        let tags = self.tokenFieldTags.objectValue as? [String] ?? []
        var tagsString = ""
        for i in 0..<tags.count{
            let tag = tags[i]
            if i == 0{
                tagsString += tag
            }else{
                tagsString += ";" + tag
            }
            
        }
        return tagsString
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
        addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: achievements, distractionsEncountered: distractionsEncountered, abortReason: "", feedback: "", tags:getTagsString())

        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: textFieldAchieve.stringValue, distractions: textFieldDistractions.stringValue, finish_time: self.finish_time ?? Date(), rating:nil, completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })

    }
}



extension focusCompletedForActivityVc:NSTextFieldDelegate, NSTokenFieldDelegate{
    
    func controlTextDidChange(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if tokenFieldTags == self.tokenFieldTags{
                let selectedRow = currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                dic["tags"] = self.tokenFieldTags.objectValue as? [String] ?? []

                arrFocusType[selectedRow] = dic
            }
        }
    }
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let tokenFieldTags = obj.object as? NSTokenField{
            if UserDefaults.standard.object(forKey: kUserdefaultsShowTextForTokenFieldFirstTime) == nil{
                if tokenFieldTags == self.tokenFieldTags{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsShowTextForTokenFieldFirstTime)
                    var addTagsInfoText = "Press enter to add the tag"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                            addTagsInfoText = focusCompletedInfo.value(forKey: "addTagsInfoText") as? String ?? addTagsInfoText
                        }
                    }
                    showTooltip(sender: self.boxTempForShowToolTip, msg: addTagsInfoText, preferredEdge: .maxY, maxWidthVal: 250)
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
                        popoverTooltip?.close()
                    }
                }
            }
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, hasMenuForRepresentedObject representedObject: Any) -> Bool {
        return true
    }
    func tokenField(_ tokenField: NSTokenField,
                    menuForRepresentedObject representedObject: Any) -> NSMenu? {
        defaultTokenMenu.removeAllItems()
        for habit in arrAllTags{//
            let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
            item.target = self
            defaultTokenMenu.addItem(item)
        }
        
        return defaultTokenMenu
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        return arrAllTags.filter { $0.lowercased().hasPrefix(substring.lowercased()) }
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {

        DispatchQueue.global().async {
            DispatchQueue.main.async {
                
                let selectedRow = self.currentFocusModeIndex
                var dic = arrFocusType[selectedRow]
                //dic["tags"] = self.tokenField.objectValue as? [String] ?? []
                let tags = self.tokenFieldTags.objectValue as? [String] ?? []
                
                var finalTags = [String]()
                for i in 0..<tags.count{
                    if !finalTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                        finalTags.append(tags[i])
                        if !self.arrAllTags.contains(where: {$0.caseInsensitiveCompare(tags[i]) == .orderedSame}) {
                            self.arrAllTags.append(tags[i])
                        }
                    }
                }
                dic["tags"] = finalTags
                arrFocusType[selectedRow] = dic
                self.tokenFieldTags.objectValue = finalTags
            }
        }
        return tokens
    }
    
}
