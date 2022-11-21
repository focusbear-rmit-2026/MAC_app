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
    @IBOutlet weak var comboBoxHabits: NSComboBox!
    @IBOutlet weak var textFieldNextHabit: PopoverAwareTextField!
    
    //    @IBOutlet weak var tblViewHabits: NSTableView!
    //    @IBOutlet weak var textFieldNextHabit: NSTextField!
    @IBOutlet weak var btnStartNextHabit: Button!
    //    @IBOutlet weak var popupBtnHabits: NSPopUpButton!
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
        
        //        textFieldNextHabit.delegate = self
        //        tblViewHabits.delegate = self
        //        tblViewHabits.dataSource = self
        
        //        let searchBar = NSSearchField()
        //        searchBar.menu
        
        //        popupBtnHabits.sear
        comboBoxHabits.delegate = self
        comboBoxHabits.dataSource = self
        
        let popoverViewControllerObj = PopoverViewController()
        textFieldNextHabit.popoverViewControllerObj = popoverViewControllerObj
        self.customViewForList.addSubview(popoverViewControllerObj.view)
        self.customViewForList.addConstraints(subView: popoverViewControllerObj.view)
        textFieldNextHabit.popoverViewControllerObj?.view.isHidden = true
        comboBoxHabits.isHidden = true// not in use // hide hi rhta h
        //
        
        textFieldNextHabit.delegate = self
        textFieldNextHabit.parentVcObj = self
        btnSkipHabit.title = "Skip this habit for today"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnSkipHabit.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnSkipHabit.title
        }
    }
    
    func resetData(){
        addLog(text:"rememberNextHabitVc:- func resetData")
        textFieldNextHabit.stringValue = ""
        
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
            for habit in arrAllMorningHabits{
                arrHabitNames.append(habit.name)
            }
            
            arrHabitNames.shuffle()
            
            lastHabitName = arrAllMorningHabits[nextHabitIndex-1].name
            nextHabitName = arrAllMorningHabits[nextHabitIndex].name
            nextHabitTime = arrAllMorningHabits[nextHabitIndex].durationSeconds
        }else if currentState == ._EVENING_HABIT_{
            arrHabitNames.removeAll()
            for habit in arrAllEveningHabits{
                arrHabitNames.append(habit.name)
            }
            
            arrHabitNames.shuffle()
            //            for habit in arrHabitNames{
            //                 popupBtnHabits.addItem(withTitle: habit)
            //            }
            lastHabitName = arrAllEveningHabits[nextHabitIndex-1].name
            nextHabitName = arrAllEveningHabits[nextHabitIndex].name
            nextHabitTime = arrAllEveningHabits[nextHabitIndex].durationSeconds
        }
        
        lblQuestion.stringValue = questionText.replacingOccurrences(of: "<LAST_HABIT_NAME>", with: lastHabitName)//"You just completed \(lastHabitName). What habit will you do next?"
        btnStartNextHabit.title = getstartActivityButtonText(seconds: nextHabitTime, name: nextHabitName)
        //        textFieldNextHabit.stringValue = ""
        
        //        for habit in arrHabitNames{
        //            //            if habit.localizedStandardContains(textfield.stringValue){
        //            let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
        //            item.target=self
        //            arrSearchedHabitNames.append(habit)
        //            //}
        //            menuHabits.addItem(item)
        //        }
        
        //        comboBoxHabits.ite
        comboBoxHabits.reloadData()
        comboBoxHabits.placeholderString = selectHabitText
        comboBoxHabits.stringValue = ""
        
        
        textFieldNextHabit.itemsArr.removeAll()
        for habit in arrHabitNames{
            textFieldNextHabit.itemsArr.append(habit)
        }
        btnSkipHabit.isHidden = true
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else{
            return
        }
        if textfield == textFieldNextHabit{
            print("final string is \(textfield.stringValue)")
        }
    }
    
    @IBAction func popupBtnHabitsClicked(_ sender: Any) {
        //        if popupBtnHabits.indexOfSelectedItem == 0{
        //            return
        //        }
        //        let index = popupBtnHabits.indexOfSelectedItem - 1
        //
        //        var nextHabit:habit?
        ////        var selectedHabit:habit?
        //        if currentState == ._MORNING_HABIT_{
        //            nextHabit = arrAllMorningHabits[nextHabitIndex]
        //        }else if currentState == ._EVENING_HABIT_{
        //            nextHabit = arrAllEveningHabits[nextHabitIndex]
        //        }
        //        if arrHabitNames[index] == nextHabit?.name{
        //            lblSelectionResult.stringValue = arrRandomPhraseRightChoice.randomElement() ?? ""
        //        }else{
        //            lblSelectionResult.stringValue = (arrRandomPhraseWrongChoice.randomElement() ?? "").replacingOccurrences(of: "<CORRECT_HABIT_NAME>", with: nextHabit?.name ?? "")
        //        }
        //
        //        lblSelectionResult.isHidden = false
        //        btnStartNextHabit.isHidden = false
    }
    
    @IBAction func btnStartNextHabitClicked(_ sender: Any) {
        addLog(text:"rememberNextHabitVc:- button Start Next Habit Clicked")
        self.view.removeFromSuperview()
        thirdVcObj?.boxBg.isHidden = false
        thirdVcObj?.btnMainClicked(self)
    }
    func optionSelectedByUser(){
        addLog(text:"rememberNextHabitVc:- optionSelectedByUser")
        var nextHabit:habit?
        //        var selectedHabit:habit?
        if currentState == ._MORNING_HABIT_{
            nextHabit = arrAllMorningHabits[nextHabitIndex]
        }else if currentState == ._EVENING_HABIT_{
            nextHabit = arrAllEveningHabits[nextHabitIndex]
        }
        if textFieldNextHabit.stringValue == nextHabit?.name{
            lblSelectionResult.stringValue = arrRandomPhraseRightChoice.randomElement() ?? ""
        }else{
            lblSelectionResult.stringValue = (arrRandomPhraseWrongChoice.randomElement() ?? "").replacingOccurrences(of: "<CORRECT_HABIT_NAME>", with: nextHabit?.name ?? "")
        }
        
        lblSelectionResult.isHidden = false
        btnStartNextHabit.isHidden = false
        btnSkipHabit.isHidden = false
    }
    @IBAction func comboBoxHabitAction(_ sender: Any) {
        print("workDone")
        
    }
    @IBAction func btnSkipHabitClicked(_ sender: Any) {
        thirdVcObj?.btnSkipHabitClicked(self)
    }
}


//extension rememberNextHabitVc:NSTextFieldDelegate{
//    func controlTextDidBeginEditing(_ obj: Notification) {
//        guard let textfield = obj.object as? NSTextField else{
//                return
//        }
//        print("begin")
////        menuHabits.removeAllItems()
////        let p = NSPoint(x: textfield.frame.origin.x, y: textfield.frame.origin.y - 5 )
////        menuHabits.popUp(positioning: nil, at: p, in: textfield.superview)
//
//
//    }
//
//    func controlTextDidEndEditing(_ obj: Notification) {
//        guard let textfield = obj.object as? NSTextField else{
//                return
//        }
//        print("End")
////        menuHabits.removeAllItems()
//
////        tblViewHabits.enclosingScrollView!.isHidden = true
//    }
//    @objc func menuItemClicked(sender:NSMenuItem){
//
//    }
//    func controlTextDidChange(_ obj: Notification) {
//        guard let textfield = obj.object as? NSTextField else{
//                return
//        }
//        print("Change")
////        arrSearchedHabitNames.removeAll()
////        for habit in arrHabitNames{
////            if habit.localizedStandardContains(textfield.stringValue){
//////                let item = NSMenuItem(title: habit, action: #selector(menuItemClicked), keyEquivalent: "")
//////                item.target=self
////                arrSearchedHabitNames.append(habit)
////            }
////        }
////        tblViewHabits.enclosingScrollView!.isHidden = false
////        tblViewHabits.reloadData()
//
////        let p = NSPoint(x: textfield.frame.origin.x, y: textfield.frame.origin.y - 5 )
////        menuHabits.popUp(positioning: nil, at: p, in: textfield.superview)
//    }
//}

//extension rememberNextHabitVc: NSTableViewDelegate, NSTableViewDataSource{
//
//    func numberOfRows(in tableView: NSTableView) -> Int {
//        if textFieldNextHabit.stringValue.isEmpty{
//            return arrHabitNames.count
//        }else{
//            return arrSearchedHabitNames.count
//        }
//
//    }
//    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
//
//            if textFieldNextHabit.stringValue.isEmpty{
//                cell.lblTitle.stringValue = arrHabitNames[row]
//            }else{
//                cell.lblTitle.stringValue = arrSearchedHabitNames[row]
//            }
//            return cell
//        }
//
//        return NSTableCellView()
//    }
//}

extension rememberNextHabitVc: NSComboBoxDelegate, NSComboBoxDataSource{
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return arrHabitNames[index]
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return arrHabitNames.count
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var i = 0
        for str in arrHabitNames {
            if str == string{
                return i
            }
            i += 1
        }
        return -1
    }
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        
        print("SubString = \(string)")
        
        for state in arrHabitNames {
            // substring must have less characters then stings to search
            if string.count < state.count{
                // only use first part of the strings in the list with length of the search string
                let statePartialStr = state.lowercased()[state.lowercased().startIndex..<state.lowercased().index(state.lowercased().startIndex, offsetBy: string.count)]
                if statePartialStr.range(of: string.lowercased()) != nil {
                    print("SubString Match = \(state)")
                    return state
                }
                //                else{
                //                    if state.lowercased().contains(string.lowercased()){
                //                        return state
                //                    }
                //                }
            }
        }
        return ""
    }
}
