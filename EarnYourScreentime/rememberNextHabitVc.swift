//
//  rememberNextHabitVc.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 19/05/22.
//  Copyright © 2022 Earn Your Screen Time. All rights reserved.
//

import Cocoa

class rememberNextHabitVc: NSViewController {

    @IBOutlet weak var btnStartNextHabit: Button!
    @IBOutlet weak var popupBtnHabits: NSPopUpButton!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSelectionResult: NSTextField!
    var arrRandomPhraseRightChoice = [String]()
    var arrRandomPhraseWrongChoice = [String]()
    var questionText = "You just completed <LAST_HABIT_NAME>. What habit will you do next?"

    var nextHabitIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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
        }
        
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice1)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice2)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice3)
        arrRandomPhraseRightChoice.append(randomPhraseRightChoice4)
        
        arrRandomPhraseWrongChoice.append(randomPhraseWrongChoice1)
        arrRandomPhraseWrongChoice.append(randomPhraseWrongChoice2)
    }
    var arrHabitNames = [String]()
    func resetData(){
        lblSelectionResult.isHidden = true
        btnStartNextHabit.isHidden = true
        
        var lastHabitName = ""
        var nextHabitName = ""
        var nextHabitTime = 0
        
        popupBtnHabits.removeAllItems()
        
        var selectHabitText = "Select Habit"
        if let rememberNextHabitViewInfo = configjson.value(forKey: "rememberNextHabitViewInfo") as? NSDictionary{
            if let text = rememberNextHabitViewInfo.value(forKey: "selectHabitText") as? String{
                selectHabitText = text
            }
        }
        popupBtnHabits.addItem(withTitle: selectHabitText)
        if currentState == ._MORNING_HABIT_{
            arrHabitNames.removeAll()
            for habit in arrAllMorningHabits{
                arrHabitNames.append(habit.name)
            }
            
            arrHabitNames.shuffle()
            for habit in arrHabitNames{
                 popupBtnHabits.addItem(withTitle: habit)
            }

            lastHabitName = arrAllMorningHabits[nextHabitIndex-1].name
            nextHabitName = arrAllMorningHabits[nextHabitIndex].name
            nextHabitTime = arrAllMorningHabits[nextHabitIndex].durationSeconds
        }else if currentState == ._EVENING_HABIT_{
            arrHabitNames.removeAll()
            for habit in arrAllEveningHabits{
                arrHabitNames.append(habit.name)
            }
            
            arrHabitNames.shuffle()
            for habit in arrHabitNames{
                 popupBtnHabits.addItem(withTitle: habit)
            }
            lastHabitName = arrAllEveningHabits[nextHabitIndex-1].name
            nextHabitName = arrAllEveningHabits[nextHabitIndex].name
            nextHabitTime = arrAllEveningHabits[nextHabitIndex].durationSeconds
        }
        
        lblQuestion.stringValue = questionText.replacingOccurrences(of: "<LAST_HABIT_NAME>", with: lastHabitName)//"You just completed \(lastHabitName). What habit will you do next?"
        btnStartNextHabit.title = getstartActivityButtonText(seconds: nextHabitTime, name: nextHabitName)
    }
    
    @IBAction func popupBtnHabitsClicked(_ sender: Any) {
        if popupBtnHabits.indexOfSelectedItem == 0{
            return
        }
        let index = popupBtnHabits.indexOfSelectedItem - 1
        
        var nextHabit:habit?
        var selectedHabit:habit?
        if currentState == ._MORNING_HABIT_{
            nextHabit = arrAllMorningHabits[nextHabitIndex]
        }else if currentState == ._EVENING_HABIT_{
            nextHabit = arrAllEveningHabits[nextHabitIndex]
        }
        if arrHabitNames[index] == nextHabit?.name{
            lblSelectionResult.stringValue = arrRandomPhraseRightChoice.randomElement() ?? ""
        }else{
            lblSelectionResult.stringValue = (arrRandomPhraseWrongChoice.randomElement() ?? "").replacingOccurrences(of: "<CORRECT_HABIT_NAME>", with: nextHabit?.name ?? "")
        }
        
        lblSelectionResult.isHidden = false
        btnStartNextHabit.isHidden = false
        
    }
    
    @IBAction func btnStartNextHabitClicked(_ sender: Any) {
        self.view.removeFromSuperview()
        thirdVcObj?.boxBg.isHidden = false
        thirdVcObj?.btnMainClicked(self)
    }
    
}
