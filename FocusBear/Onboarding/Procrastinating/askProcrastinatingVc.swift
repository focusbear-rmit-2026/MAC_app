//
//  askProcrastinatingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askProcrastinatingVc: NSViewController, NSTextViewDelegate {// not in use 

    @IBOutlet weak var lblTitleIntention: NSTextField!
    
    @IBOutlet weak var lblStartFocus: NSTextField!
    @IBOutlet weak var lblIntention: NSTextField!
    @IBOutlet weak var btnStart: Button!
//    @IBOutlet weak var btnFourth: Button!
//    @IBOutlet weak var btnShortThird: Button!
//    @IBOutlet weak var btnShortSecond: Button!
//    @IBOutlet weak var btnShortFirst: Button!
    
    @IBOutlet weak var boxFirst: procrastinatingTabBox!
    @IBOutlet weak var boxSecond: procrastinatingTabBox!
    @IBOutlet weak var boxThird: procrastinatingTabBox!
    @IBOutlet weak var boxFourth: procrastinatingTabBox!
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblSubTitle: NSTextField!
   // @IBOutlet weak var lblTitle: NSTextField!
    
    var arrTextIntenion:[(String, String)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        btnShortFirst.buttonColor = NSColor.white.cgColor
//        btnShortSecond.buttonColor = NSColor.white.cgColor
//        btnShortThird.buttonColor = NSColor.white.cgColor
//        btnFourth.buttonColor = NSColor.white.cgColor
        lblStartFocus.stringValue = "Let's focus all out for 25 minutes." // text not added
       // lblTitle.stringValue = "Time to do something difficult"
        lblSubTitle.stringValue = "What's something you've been procrastinating on? Focus Bear will help you get it done right after this."
        btnStart.title = "Let's do this!"
        boxFourth.title = "Something else"
        lblTitleIntention.stringValue = "Intention:"
        if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
            //lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnStart.title = dic.value(forKey: "buttonStartText") as? String ?? btnStart.title
            boxFourth.title = dic.value(forKey: "buttonSomethingElseText") as? String ?? "Something else"
            lblTitleIntention.stringValue = dic.value(forKey: "titleIntention") as? String ?? lblTitleIntention.stringValue
        }
        textView.delegate = self
        btnStart.isEnabled = false
        textView.enclosingScrollView?.isHidden = true
        lblIntention.isHidden = true
        lblIntention.stringValue = ""
        textView.string = ""
        lblTitleIntention.isHidden = true
        
        boxFirst.delegate = self
        boxSecond.delegate = self
        boxThird.delegate = self
        boxFourth.delegate = self
    }
    
    override func viewWillAppear() {
        resetData()
    }
    
    func resetData() {
        let selectedIndex = UserDefaults.standard.object(forKey: kUserDefaultsSelectedOccupationIndex) as? Int ?? 0
        if selectedIndex == occupationStudentIndex{
            
            var studentLongTextFirst = "Finally start that essay that’s been staring at you with judgmental eyes."
            var studentShortTextFirst = "Start that essay (finally)."

            var studentLongTextSecond = "Wrestle with your lecture notes to see if you can remember anything from last month."
            var studentShortTextSecond = "Review lecture notes."

            var studentLongTextThird = "Pretend you know what’s going on in your group project and get cracking on research."
            var studentShortTextThird = "Take lead in group project."

            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                studentLongTextFirst = dic.value(forKey: "studentLongTextFirst") as? String ?? studentLongTextFirst
                studentShortTextFirst = dic.value(forKey: "studentShortTextFirst") as? String ?? studentShortTextFirst
                studentLongTextSecond = dic.value(forKey: "studentLongTextSecond") as? String ?? studentLongTextSecond
                studentShortTextSecond = dic.value(forKey: "studentShortTextSecond") as? String ?? studentShortTextSecond
                studentLongTextThird = dic.value(forKey: "studentLongTextThird") as? String ?? studentLongTextThird
                studentShortTextThird = dic.value(forKey: "studentShortTextThird") as? String ?? studentShortTextThird
            }

            arrTextIntenion = [(studentLongTextFirst, studentShortTextFirst), (studentLongTextSecond, studentShortTextSecond), (studentLongTextThird, studentShortTextThird)]
        }else if selectedIndex == occupationBusinessOwnerIndex{
            var businessOwnerLongTextFirst = "Start that tax return you’ve been avoiding like it’s a monster under the bed."
            var businessOwnerShortTextFirst = "Start your tax return."

            var businessOwnerLongTextSecond = "Finally sort through those old receipts you’ve been pretending don’t exist."
            var businessOwnerShortTextSecond = "Sort through receipts."

            var businessOwnerLongTextThird = "Knock out that dreaded 15-minute chore that’s been sitting on your list for days."
            var businessOwnerShortTextThird = "Do a dreaded chore."
            
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                businessOwnerLongTextFirst = dic.value(forKey: "businessOwnerLongTextFirst") as? String ?? businessOwnerLongTextFirst
                businessOwnerShortTextFirst = dic.value(forKey: "businessOwnerShortTextFirst") as? String ?? businessOwnerShortTextFirst
                
                businessOwnerLongTextSecond = dic.value(forKey: "businessOwnerLongTextSecond") as? String ?? businessOwnerLongTextSecond
                businessOwnerShortTextSecond = dic.value(forKey: "businessOwnerShortTextSecond") as? String ?? businessOwnerShortTextSecond
                
                businessOwnerLongTextThird = dic.value(forKey: "businessOwnerLongTextThird") as? String ?? businessOwnerLongTextThird
                businessOwnerShortTextThird = dic.value(forKey: "businessOwnerShortTextThird") as? String ?? businessOwnerShortTextThird
            }
            
            arrTextIntenion = [(businessOwnerLongTextFirst, businessOwnerShortTextFirst), (businessOwnerLongTextSecond, businessOwnerShortTextSecond), (businessOwnerLongTextThird, businessOwnerShortTextThird)]
        }else if selectedIndex == occupationEmployeeIndex{
            var employeeLongTextFirst = "Update your portfolio before you forget how awesome your old work is."
            var employeeShortTextFirst = "Update portfolio."

            var employeeLongTextSecond = "Attack your inbox like a boss—your future unread emails are watching."
            var employeeShortTextSecond = "Clear out inbox."
            
            
            var employeeLongTextThird = "Brainstorm that \"brilliant\" new concept that’ll either be genius or a creative dumpster fire."
            var employeeShortTextThird = "Start new concept."
            
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                employeeLongTextFirst = dic.value(forKey: "employeeLongTextFirst") as? String ?? employeeLongTextFirst
                employeeShortTextFirst = dic.value(forKey: "employeeShortTextFirst") as? String ?? employeeShortTextFirst
                
                employeeLongTextSecond = dic.value(forKey: "employeeLongTextSecond") as? String ?? employeeLongTextSecond
                employeeShortTextSecond = dic.value(forKey: "employeeShortTextSecond") as? String ?? employeeShortTextSecond
                
                employeeLongTextThird = dic.value(forKey: "employeeLongTextThird") as? String ?? employeeLongTextThird
                employeeShortTextThird = dic.value(forKey: "employeeShortTextThird") as? String ?? employeeShortTextThird
            }
            
            
            arrTextIntenion = [(employeeLongTextFirst, employeeShortTextFirst), (employeeLongTextSecond, employeeShortTextSecond), (employeeLongTextThird, employeeShortTextThird)]
        }else if selectedIndex == occupationFreelancerIndex{
            var freelancerLongTextFirst = "Finish the design project that’s been lurking on your desktop like a bad habit."
            var freelancerShortTextFirst = "Finish design."

            var freelancerLongTextSecond = "Update your portfolio before you forget how awesome your old work is."
            var freelancerShortTextSecond = "Update portfolio."

            var freelancerLongTextThird = "Brainstorm that \"brilliant\" new concept that’ll either be genius or a creative dumpster fire."
            var freelancerShortTextThird = "Start new concept."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                freelancerLongTextFirst = dic.value(forKey: "freelancerLongTextFirst") as? String ?? freelancerLongTextFirst
                freelancerShortTextFirst = dic.value(forKey: "freelancerShortTextFirst") as? String ?? freelancerShortTextFirst
                
                freelancerLongTextSecond = dic.value(forKey: "freelancerLongTextSecond") as? String ?? freelancerLongTextSecond
                freelancerShortTextSecond = dic.value(forKey: "freelancerShortTextSecond") as? String ?? freelancerShortTextSecond
                
                freelancerLongTextThird = dic.value(forKey: "freelancerLongTextThird") as? String ?? freelancerLongTextThird
                freelancerShortTextThird = dic.value(forKey: "freelancerShortTextThird") as? String ?? freelancerShortTextThird
            }
            
            arrTextIntenion = [(freelancerLongTextFirst, freelancerShortTextFirst), (freelancerLongTextSecond, freelancerShortTextSecond), (freelancerLongTextThird, freelancerShortTextThird)]
        }else if selectedIndex == occupationOtherIndex{
            var genericSuggestionsLongTextFirst = "Start that tax return you’ve been avoiding like it’s a monster under the bed."
            var genericSuggestionsShortTextFirst = "Start your tax return."

            var genericSuggestionsLongTextSecond = "Finally sort through those old receipts you’ve been pretending don’t exist."
            var genericSuggestionsShortTextSecond = "Sort through receipts."

            var genericSuggestionsLongTextThird = "Knock out that dreaded 15-minute chore that’s been sitting on your list for days."
            var genericSuggestionsShortTextThird = "Do a dreaded chore."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                genericSuggestionsLongTextFirst = dic.value(forKey: "genericSuggestionsLongTextFirst") as? String ?? genericSuggestionsLongTextFirst
                genericSuggestionsShortTextFirst = dic.value(forKey: "genericSuggestionsShortTextFirst") as? String ?? genericSuggestionsShortTextFirst
                
                genericSuggestionsLongTextSecond = dic.value(forKey: "genericSuggestionsLongTextSecond") as? String ?? genericSuggestionsLongTextSecond
                genericSuggestionsShortTextSecond = dic.value(forKey: "genericSuggestionsShortTextSecond") as? String ?? genericSuggestionsShortTextSecond
                
                genericSuggestionsLongTextThird = dic.value(forKey: "genericSuggestionsLongTextThird") as? String ?? genericSuggestionsLongTextThird
                genericSuggestionsShortTextThird = dic.value(forKey: "genericSuggestionsShortTextThird") as? String ?? genericSuggestionsShortTextThird
            }
            
            arrTextIntenion = [(genericSuggestionsLongTextFirst, genericSuggestionsShortTextFirst), (genericSuggestionsLongTextSecond, genericSuggestionsShortTextSecond), (genericSuggestionsLongTextThird, genericSuggestionsShortTextThird)]
        }else if selectedIndex == occupationProgrammerIndex{
            var programmerLongTextFirst = "Hunt down that bug that’s been hiding from you like it’s in witness protection."
            var programmerShortTextFirst = "Fix the sneaky bug."

            var programmerLongTextSecond = "Face the spaghetti code you created and somehow didn’t regret until now."
            var programmerShortTextSecond = "Refactor that mess."

            var programmerLongTextThird = "Write those unit tests your future self will thank you for (but probably never run)."
            var programmerShortTextThird = "Write unit tests (ugh)."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                programmerLongTextFirst = dic.value(forKey: "programmerLongTextFirst") as? String ?? programmerLongTextFirst
                programmerShortTextFirst = dic.value(forKey: "programmerShortTextFirst") as? String ?? programmerShortTextFirst
                
                programmerLongTextSecond = dic.value(forKey: "programmerLongTextSecond") as? String ?? programmerLongTextSecond
                programmerShortTextSecond = dic.value(forKey: "programmerShortTextSecond") as? String ?? programmerShortTextSecond
                
                programmerLongTextThird = dic.value(forKey: "programmerLongTextThird") as? String ?? programmerLongTextThird
                programmerShortTextThird = dic.value(forKey: "programmerShortTextThird") as? String ?? programmerShortTextThird
            }
            
            arrTextIntenion = [(programmerLongTextFirst, programmerShortTextFirst), (programmerLongTextSecond, programmerShortTextSecond), (programmerLongTextThird, programmerShortTextThird)]
        }else if selectedIndex == occupationGraphicDesignerIndex{
            var graphicDesignerLongTextFirst = "Finish the design project that’s been lurking on your desktop like a bad habit."
            var graphicDesignerShortTextFirst = "Finish design."

            var graphicDesignerLongTextSecond = "Update your portfolio before you forget how awesome your old work is."
            var graphicDesignerShortTextSecond = "Update portfolio."

            var graphicDesignerLongTextThird = "Brainstorm that \"brilliant\" new concept that’ll either be genius or a creative dumpster fire."
            var graphicDesignerShortTextThird = "Start new concept."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                graphicDesignerLongTextFirst = dic.value(forKey: "graphicDesignerLongTextFirst") as? String ?? graphicDesignerLongTextFirst
                graphicDesignerShortTextFirst = dic.value(forKey: "graphicDesignerShortTextFirst") as? String ?? graphicDesignerShortTextFirst
                
                graphicDesignerLongTextSecond = dic.value(forKey: "graphicDesignerLongTextSecond") as? String ?? graphicDesignerLongTextSecond
                graphicDesignerShortTextSecond = dic.value(forKey: "graphicDesignerShortTextSecond") as? String ?? graphicDesignerShortTextSecond
                
                graphicDesignerLongTextThird = dic.value(forKey: "graphicDesignerLongTextThird") as? String ?? graphicDesignerLongTextThird
                graphicDesignerShortTextThird = dic.value(forKey: "graphicDesignerShortTextThird") as? String ?? graphicDesignerShortTextThird
            }
            
            arrTextIntenion = [(graphicDesignerLongTextFirst, graphicDesignerShortTextFirst), (graphicDesignerLongTextSecond, graphicDesignerShortTextSecond), (graphicDesignerLongTextThird, graphicDesignerShortTextThird)]
        }else if selectedIndex == occupationOtherOfficeWorkIndex{
            var officeWorkLongTextFirst = "Attack your inbox like a boss—your future unread emails are watching."
            var officeWorkShortTextFirst = "Clear out inbox."

            var officeWorkLongTextSecond = "Write that report before your boss reminds you (again... and again)."
            var officeWorkShortTextSecond = "Finish the report."

            var officeWorkLongTextThird = "Declutter your desk like you’re about to star in an episode of Office Hoarders."
            var officeWorkShortTextThird = "Declutter your desk."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                officeWorkLongTextFirst = dic.value(forKey: "officeWorkLongTextFirst") as? String ?? officeWorkLongTextFirst
                officeWorkShortTextFirst = dic.value(forKey: "officeWorkShortTextFirst") as? String ?? officeWorkShortTextFirst
                
                officeWorkLongTextSecond = dic.value(forKey: "officeWorkLongTextSecond") as? String ?? officeWorkLongTextSecond
                officeWorkShortTextSecond = dic.value(forKey: "officeWorkShortTextSecond") as? String ?? officeWorkShortTextSecond
                
                officeWorkLongTextThird = dic.value(forKey: "officeWorkLongTextThird") as? String ?? officeWorkLongTextThird
                officeWorkShortTextThird = dic.value(forKey: "officeWorkShortTextThird") as? String ?? officeWorkShortTextThird
            }
            arrTextIntenion = [(officeWorkLongTextFirst, officeWorkShortTextFirst), (officeWorkLongTextSecond, officeWorkShortTextSecond), (officeWorkLongTextThird, officeWorkShortTextThird)]
        }else if selectedIndex == occupationFieldWorkIndex{
            
            var fieldWorkLongTextFirst = "Finish the design project that’s been lurking on your desktop like a bad habit."
            var fieldWorkShortTextFirst = "Finish design."

            var fieldWorkLongTextSecond = "Update your portfolio before you forget how awesome your old work is."
            var fieldWorkShortTextSecond = "Update portfolio."

            var fieldWorkLongTextThird = "Brainstorm that \"brilliant\" new concept that’ll either be genius or a creative dumpster fire."
            var fieldWorkShortTextThird = "Start new concept."
            
            if let dic = configjson.value(forKey: "askProcrastinatingVcInfo") as? NSDictionary{
                fieldWorkLongTextFirst = dic.value(forKey: "fieldWorkLongTextFirst") as? String ?? fieldWorkLongTextFirst
                fieldWorkShortTextFirst = dic.value(forKey: "fieldWorkShortTextFirst") as? String ?? fieldWorkShortTextFirst
                
                fieldWorkLongTextSecond = dic.value(forKey: "fieldWorkLongTextSecond") as? String ?? fieldWorkLongTextSecond
                fieldWorkShortTextSecond = dic.value(forKey: "fieldWorkShortTextSecond") as? String ?? fieldWorkShortTextSecond
                
                fieldWorkLongTextThird = dic.value(forKey: "fieldWorkLongTextThird") as? String ?? fieldWorkLongTextThird
                fieldWorkShortTextThird = dic.value(forKey: "fieldWorkShortTextThird") as? String ?? fieldWorkShortTextThird
            }
            
            arrTextIntenion = [(fieldWorkLongTextFirst, fieldWorkShortTextFirst), (fieldWorkLongTextSecond, fieldWorkShortTextSecond), (fieldWorkLongTextThird, fieldWorkShortTextThird)]
        }
        
        for i in 0..<arrTextIntenion.count{
            let (_, shortText) = arrTextIntenion[i]
            if i == 0{
                boxFirst.title = shortText
            }else if i == 1{
                boxSecond.title = shortText
            }else if  i == 2{
                boxThird.title = shortText
            }
        }
    }
    
    @IBAction func btnShortThirdClicked(_ sender: Any) {
        let (longText, _) = arrTextIntenion[2]
        textView.string = longText
        lblIntention.stringValue = longText
        btnStart.isEnabled = true
        textView.enclosingScrollView?.isHidden = true
        lblIntention.isHidden = false
        lblTitleIntention.isHidden = false
        allApiObject.capturePosthog(event: "button_choice3_clicked", metadata: [:])
    }
    
    @IBAction func btnShortSecondClicked(_ sender: Any) {
        let (longText, _) = arrTextIntenion[1]
        textView.string = longText
        lblIntention.stringValue = longText
        btnStart.isEnabled = true
        textView.enclosingScrollView?.isHidden = true
        lblIntention.isHidden = false
        lblTitleIntention.isHidden = false
        allApiObject.capturePosthog(event: "button_choice2_clicked", metadata: [:])
    }
    
    @IBAction func btnShortFirstClicked(_ sender: Any) {
        let (longText, _) = arrTextIntenion[0]
        textView.string = longText
        lblIntention.stringValue = longText
        btnStart.isEnabled = true
        textView.enclosingScrollView?.isHidden = true
        lblIntention.isHidden = false
        lblTitleIntention.isHidden = false
        allApiObject.capturePosthog(event: "button_choice1_clicked", metadata: [:])
    }
    
    @IBAction func btnFourthClicked(_ sender: Any) {
        textView.string = ""
        btnStart.isEnabled = false
        textView.enclosingScrollView?.isHidden = false
        lblIntention.isHidden = true
        textView.window?.makeFirstResponder(textView)
        lblTitleIntention.isHidden = false
        allApiObject.capturePosthog(event: "button_choice4_clicked", metadata: [:])
    }
    
    @IBAction func btnStartClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button_lets_do_this_clicked", metadata: [:])
        //self.view.window?.close()
        appdelegate?.menuShowSimplePomodoroModeView()
        simplePomodoroVcObj?.textViewAchieve.string = self.textView.string
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                simplePomodoroVcObj?.textViewAchieve.string = self.textView.string
            }
        }
        
        //The app should automatically restart the focus session after the app restarts during permissions   #1559  v2.27.435
        for i in 0..<arrFocusType.count{
            if let isDeepWorkFocus = arrFocusType[i]["isDeepWorkFocus"] as? Bool{//this key will only be awailable in default focus type
                if  isDeepWorkFocus{
                    arrFocusType[i]["lastIntentionUsed"] = textView.string
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    updateAllFocusModes()
                    break;
                }
            }
            
        }
        
        UserDefaults.standard.set(true, forKey: kUserdefaultsUserShouldDoFirstFocusSesion)
        
        //--------------//
    }
    
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            if textView == self.textView{
                if textView.string.isEmpty{
                    btnStart.isEnabled = false
                }else{
                    btnStart.isEnabled = true
                }
            }
        }
    }
}

extension askProcrastinatingVc: procrastinatingTabBoxDelegate{
    func selectableListBoxSelectionDidChange(_ box: procrastinatingTabBox) {
        if box == boxFirst{
            btnShortFirstClicked(self)
        }else if box == boxSecond{
            btnShortSecondClicked(self)
        }else if box == boxThird{
            btnShortThirdClicked(self)
        }else if box == boxFourth{
            btnFourthClicked(self)
        }
    }
}
