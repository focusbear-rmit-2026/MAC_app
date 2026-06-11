//
//  rememberNextHabitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/05/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class rememberNextHabitVc: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var lblPleaseEnterToChoose: NSTextField!
    @IBOutlet weak var btnSkipHabit: underLineButton!
    @IBOutlet weak var customViewForList: NSView!
    @IBOutlet weak var comboBoxHabits: searchableComboBox!
    @IBOutlet weak var textFieldNextHabit: PopoverAwareTextField!
    @IBOutlet weak var btnStartNextHabit: Button!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSelectionResult: NSTextField!
    var arrRandomPhraseRightChoice = [String]()
    var arrRandomPhraseWrongChoice = [String]()
    var questionText = "You just completed <LAST_HABIT_NAME>. What habit will you do next?"
    
    var nextHabitIndex = 0
    var menuHabits = NSMenu()
    var arrHabitNames = [String]()
    var arrSearchedHabitNames = [String]()
    var moreActionsMenu = NSMenu()
    var startAnotherHabitVcObj:startAnotherHabitVc?
    var chooseHabitsVCObj: chooseHabitsVC?
    var menuItemSkipHabit: NSMenuItem!
    var menuItemSelectAnotherHabit: NSMenuItem!
    var menuItemChooseHabits: NSMenuItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblPleaseEnterToChoose.stringValue = "Press enter to choose an option"
        lblTitle.stringValue = "What comes next?"
        lblDescription.stringValue = "I want to make sure you don't become too dependent on me. There will be days where you don't have access to your computer but that doesn't mean you won't do your habits. Think of me as training wheels - I'm here to help you deepen the habits until they become automatic. Let's do a quick exercise to make sure you remember how to stack your habits even when I'm not there."
        
        
        var randomPhraseRightChoice1 = "Right on!"
        var randomPhraseRightChoice2 = "Yeah!"
        var randomPhraseRightChoice3 = "You got it!"
        var randomPhraseRightChoice4 = "I can just retire now because you know exactly what you're doing 🙂"
        
        var randomPhraseWrongChoice1 = "Oops not quite - it's <CORRECT_HABIT_NAME>"
        var randomPhraseWrongChoice2 = "Almost - it's <CORRECT_HABIT_NAME>"
        
        
        if let rememberNextHabitViewInfo = configjson.value(forKey: "rememberNextHabitViewInfo") as? NSDictionary{
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseRightChoice1") as? String{
                randomPhraseRightChoice1 = choice
            }
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseRightChoice2") as? String{
                randomPhraseRightChoice2 = choice
            }
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseRightChoice3") as? String{
                randomPhraseRightChoice3 = choice
            }
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseRightChoice4") as? String{
                randomPhraseRightChoice4 = choice
            }
            
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseWrongChoice1") as? String{
                randomPhraseWrongChoice1 = choice
            }
            if let choice = rememberNextHabitViewInfo.value(forKey: "randomPhraseWrongChoice2") as? String{
                randomPhraseWrongChoice2 = choice
            }
            
            
            if let title = rememberNextHabitViewInfo.value(forKey: "title") as? String{
                lblTitle.stringValue = title
            }
            if let description = rememberNextHabitViewInfo.value(forKey: "description") as? String{
                lblDescription.stringValue = description
            }
            if let questionText = rememberNextHabitViewInfo.value(forKey: "questionText") as? String{
                self.questionText = questionText
            }
            
            lblPleaseEnterToChoose.stringValue = rememberNextHabitViewInfo.value(forKey: "enterToChooseText") as? String ?? lblPleaseEnterToChoose.stringValue
        }
        
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice1)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice2)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice3)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice4)
        
        arrRandomPhraseWrongChoice.append(randomPhraseWrongChoice1)
        arrRandomPhraseWrongChoice.append(randomPhraseWrongChoice2)

        comboBoxHabits.customDelegate = self

        btnSkipHabit.title = buttonMoreActionsText
        textFieldNextHabit.isHidden = true
        customViewForList.isHidden = true
        
        menuItemSkipHabit = NSMenuItem(title: "Skip this habit for today", action: #selector(menuItemSkipHabitClicked), keyEquivalent: "")
        menuItemSkipHabit.target = self
        moreActionsMenu.addItem(menuItemSkipHabit)
        
        
        menuItemSelectAnotherHabit = NSMenuItem(title: "Choose another habit", action: #selector(menuItemSelectAnotherHabitClicked), keyEquivalent: "")
        menuItemSelectAnotherHabit.target = self
        moreActionsMenu.addItem(menuItemSelectAnotherHabit)
        

        menuItemChooseHabits = NSMenuItem(title: "Select the habits to do from the list of all habits", action: #selector(menuItemChooseHabitsClicked), keyEquivalent: "")
        menuItemChooseHabits.target = self
        moreActionsMenu.addItem(menuItemChooseHabits)
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            menuItemSelectAnotherHabit.title = activityInfo.value(forKey: "buttonChooseHabitText") as? String ?? menuItemSelectAnotherHabit.title
            menuItemChooseHabits.title = activityInfo.value(forKey: "menuItemSelectHabitsText") as? String ?? menuItemChooseHabits.title
        }
        
    }
    
    func resetData(){
        addLog(text:"rememberNextHabitVc:- func resetData")
//        textFieldNextHabit.stringValue = ""
        
        lblSelectionResult.isHidden = true
        btnStartNextHabit.isHidden = true
        
        var lastHabitName = ""
        var nextHabitName = ""
        var nextHabitTime = 0

        var selectHabitText = "Select Habit"
        if let rememberNextHabitViewInfo = configjson.value(forKey: "rememberNextHabitViewInfo") as? NSDictionary{
            if let text = rememberNextHabitViewInfo.value(forKey: "selectHabitText") as? String{
                selectHabitText = text
            }
        }
        
        if currentState == ._MORNING_HABIT_{
            arrHabitNames.removeAll()
            for habit in arrFilteredMorningHabits{
                arrHabitNames.append(habit.name)
            }
            
            arrHabitNames.shuffle()
            
            lastHabitName = arrFilteredMorningHabits[nextHabitIndex-1].name
            nextHabitName = arrFilteredMorningHabits[nextHabitIndex].name
            nextHabitTime = arrFilteredMorningHabits[nextHabitIndex].durationSeconds
        }else if currentState == ._EVENING_HABIT_{
            arrHabitNames.removeAll()
            for habit in arrFilteredEveningHabits{
                arrHabitNames.append(habit.name)
            }
            arrHabitNames.shuffle()
            lastHabitName = arrFilteredEveningHabits[nextHabitIndex-1].name
            nextHabitName = arrFilteredEveningHabits[nextHabitIndex].name
            nextHabitTime = arrFilteredEveningHabits[nextHabitIndex].durationSeconds
        }
        
        lblQuestion.stringValue = questionText.replacingOccurrences(of: "<LAST_HABIT_NAME>", with: lastHabitName)
        btnStartNextHabit.title = getstartActivityButtonText(seconds: nextHabitTime, name: nextHabitName)
        comboBoxHabits.reloadData()
        comboBoxHabits.placeholderString = selectHabitText
        comboBoxHabits.stringValue = ""
        
        comboBoxHabits.items.removeAll()
        comboBoxHabits.stringValue = ""
        
        textFieldNextHabit.itemsArr.removeAll()
        for habit in arrHabitNames{
            textFieldNextHabit.itemsArr.append(habit)
            comboBoxHabits.items.append(habit)
        }

        btnSkipHabit.isHidden = true
        textFieldNextHabit.setFocus()
        comboBoxHabits.setFocus()
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else{
            return
        }
        if textfield == textFieldNextHabit{
            print("final string is \(textfield.stringValue)")
        }
    }
    
    @IBAction func btnStartNextHabitClicked(_ sender: Any) {
        addLog(text:"[user-action] rememberNextHabitVc:- button Start Next Habit Clicked")
        self.view.removeFromSuperview()
        activityCompletionVcObj?.boxBg.isHidden = false
        activityCompletionVcObj?.btnMainClicked(self)
    }

    @IBAction func comboBoxHabitAction(_ sender: Any) {
        itemSelectedByUser(comboBox: comboBoxHabits)
    }
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        if currentState == ._MORNING_HABIT_{
            if currentHabitIndex == arrFilteredMorningHabits.count - 2{
                menuItemSelectAnotherHabit.isHidden = true
            }else{
                menuItemSelectAnotherHabit.isHidden = false
            }
            var remaingHabitsCount = 0
            for i in 0..<arrPreFilteredMorningHabits.count{
                let id = arrPreFilteredMorningHabits[i].id ?? ""
                let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredMorningHabits)
                if !isActivityCompleted{
                    remaingHabitsCount += 1
                }
            }
            if remaingHabitsCount > 1{
                menuItemChooseHabits.isHidden = false
            }else{
                menuItemChooseHabits.isHidden = true
            }
            
        }else if currentState == ._EVENING_HABIT_{
            if currentHabitIndex == arrFilteredEveningHabits.count - 2{
                menuItemSelectAnotherHabit.isHidden = true
            }else{
                if isHighPrioritySequenceGoing{
                    var isAnyHighPriorityHabitRemaining = false
                    for i in currentHabitIndex + 2..<arrFilteredEveningHabits.count{
                        if arrFilteredEveningHabits[i].isPriorityHigh{
                            isAnyHighPriorityHabitRemaining = true
                            break;
                        }
                    }
                    if isAnyHighPriorityHabitRemaining{
                        menuItemSelectAnotherHabit.isHidden = false
                    }else{
                        menuItemSelectAnotherHabit.isHidden = true
                    }
                }else{
                    menuItemSelectAnotherHabit.isHidden = false
                }
            }
            
            var remaingHabitsCount = 0
            for i in 0..<arrPreFilteredEveningHabits.count{
                let id = arrPreFilteredEveningHabits[i].id ?? ""
                let isActivityCompleted = isActivityCompleted(id: id, habits: arrFilteredEveningHabits)
                if !isActivityCompleted{
                    if isHighPrioritySequenceGoing{
                        if arrPreFilteredEveningHabits[i].isPriorityHigh{
                            remaingHabitsCount += 1
                        }
                    }else{
                        remaingHabitsCount += 1
                    }
                }
            }
            if remaingHabitsCount > 1{
                menuItemChooseHabits.isHidden = false
            }else{
                menuItemChooseHabits.isHidden = true
            }
        }
        func isActivityCompleted(id:String, habits:[habit])->Bool{
            for i in 0..<currentHabitIndex + 1{
                let habit = habits[i]
                if habit.id == id{
                    return true
                }
            }
            return false
        }
        if !SettingsManagerObject.isOutOfOrderHabitsAllowed{
            menuItemSelectAnotherHabit.isHidden = true
        }
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y - 8 )
        moreActionsMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @objc func menuItemSkipHabitClicked(){
        activityCompletionVcObj?.menuItemSkipHabitClicked()
    }

    @objc func menuItemSelectAnotherHabitClicked(){
        if self.view.window != nil{
            if startAnotherHabitVcObj == nil{
                startAnotherHabitVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startAnotherHabitVc")) as? startAnotherHabitVc
            }
            startAnotherHabitVcObj!.currentHabitIndex = currentHabitIndex + 1
            self.presentAsSheet(startAnotherHabitVcObj!)
        }
    }
    
    @objc func menuItemChooseHabitsClicked(){
        if self.view.window != nil{
            if chooseHabitsVCObj == nil{
                chooseHabitsVCObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("chooseHabitsVC")) as? chooseHabitsVC
            }
            chooseHabitsVCObj!.currentHabitIndex = currentHabitIndex
            self.presentAsSheet(chooseHabitsVCObj!)
        }
    }

}


extension rememberNextHabitVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }
        addLog(text:"rememberNextHabitVc:- optionSelectedByUser")
        var nextHabit:habit?
        if currentState == ._MORNING_HABIT_{
            nextHabit = arrFilteredMorningHabits[nextHabitIndex]
        }else if currentState == ._EVENING_HABIT_{
            nextHabit = arrFilteredEveningHabits[nextHabitIndex]
        }
        if comboBox.stringValue == nextHabit?.name{
            lblSelectionResult.stringValue = arrRandomPhraseRightChoice.randomElement() ?? ""
        }else{
            lblSelectionResult.stringValue = (arrRandomPhraseWrongChoice.randomElement() ?? "").replacingOccurrences(of: "<CORRECT_HABIT_NAME>", with: nextHabit?.name ?? "")
        }
        
        lblSelectionResult.isHidden = false
        btnStartNextHabit.isHidden = false
        btnSkipHabit.isHidden = false
    }
}
