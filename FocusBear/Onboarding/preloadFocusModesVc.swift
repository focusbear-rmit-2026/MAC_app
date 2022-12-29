//
//  preloadFocusModesVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class preloadFocusModesVc: NSViewController, NSTextFieldDelegate {


    @IBOutlet weak var lblGotIt: NSTextField!
    @IBOutlet weak var textFieldSomethingElse: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var popUpBtnWork: NSPopUpButton!
    @IBOutlet weak var lblTitle: NSTextField!
    //71
    
    var titleProgramming = "Programming"
    var titleGraphicDesign = "Graphic Design"
    var titleDataAnalysis = "Data Analysis"
    
    var gotItText = "Got it. Let's set up a Focus Mode to help you be super productive while you're doing <WORK_TYPE> work."
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        textFieldSomethingElse.placeholderString = "Rocket Surgery"
        textFieldSomethingElse.isHidden = true
        btnContinue.isEnabled = false
        
        var titleSelectWorkType = "Select work type"
        
       
        lblTitle.stringValue = "What type of work do you mainly do?"
        popUpBtnWork.removeAllItems()

        textFieldSomethingElse.delegate = self
        btnContinue.title = "Continue"
        
        
        var titleSomethingElse = "Something else"
        
        
        if let preloadFocusModesViewInfo = configjson.value(forKey: "preloadFocusModesViewInfo") as? NSDictionary{
            lblTitle.stringValue = preloadFocusModesViewInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = preloadFocusModesViewInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            titleSelectWorkType = preloadFocusModesViewInfo.value(forKey: "titleSelectWorkType") as? String ?? titleSelectWorkType
            titleProgramming = preloadFocusModesViewInfo.value(forKey: "titleProgramming") as? String ?? titleProgramming
            titleGraphicDesign = preloadFocusModesViewInfo.value(forKey: "titleGraphicDesign") as? String ?? titleGraphicDesign
            titleDataAnalysis = preloadFocusModesViewInfo.value(forKey: "titleDataAnalysis") as? String ?? titleDataAnalysis
            titleSomethingElse = preloadFocusModesViewInfo.value(forKey: "titleSomethingElse") as? String ?? titleSomethingElse
            
            textFieldSomethingElse.placeholderString = preloadFocusModesViewInfo.value(forKey: "placeholderWorkText") as? String ?? textFieldSomethingElse.placeholderString
            gotItText = preloadFocusModesViewInfo.value(forKey: "gotItText") as? String ?? gotItText
        }
        
        popUpBtnWork.addItem(withTitle: titleSelectWorkType)
        popUpBtnWork.addItem(withTitle: titleProgramming)
        popUpBtnWork.addItem(withTitle: titleGraphicDesign)
        popUpBtnWork.addItem(withTitle: titleDataAnalysis)
        popUpBtnWork.addItem(withTitle: titleSomethingElse)
        
        lblGotIt.stringValue = ""
        
    }
    
    
    @IBAction func popUpBtnSelectWorkClicked(_ sender: Any) {
        textFieldSomethingElse.stringValue = ""
        let selectedIndex = popUpBtnWork.indexOfSelectedItem
        switch selectedIndex {
        case 0:
            btnContinue.isEnabled = false
            textFieldSomethingElse.isHidden = true
            lblGotIt.stringValue = ""
        case 1:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
            lblGotIt.stringValue = gotItText.replacingOccurrences(of: "<WORK_TYPE>", with: titleProgramming)
        case 2:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
            lblGotIt.stringValue = gotItText.replacingOccurrences(of: "<WORK_TYPE>", with: titleGraphicDesign)
        case 3:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
            lblGotIt.stringValue = gotItText.replacingOccurrences(of: "<WORK_TYPE>", with: titleDataAnalysis)
        case 4:
            btnContinue.isEnabled = false
            textFieldSomethingElse.isHidden = false
            lblGotIt.stringValue = ""
        default:
            break
        }
    }
    
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        var workText = "Work"
        if let preloadFocusModesViewInfo = configjson.value(forKey: "preloadFocusModesViewInfo") as? NSDictionary{
            workText = preloadFocusModesViewInfo.value(forKey: "workText") as? String ?? workText
        }
        
        let selectedIndex = popUpBtnWork.indexOfSelectedItem

        var dic: [String : Any]?
        switch selectedIndex {
        case 0:
            return // not possible because button is not enabled if option 0 is selected
        case 1://Programming
            dic = ["name":"\(titleProgramming) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Visual Studio Code.app", "/Applications/Xcode.app", "/Applications/Utilities/Terminal.app", "/Applications/Google Chrome.app", "/Applications/iTerm2.app", "/Applications/Docker.app", "/Applications/Firefox.app", "/Applications/Insomnia.app", "/Applications/VirtualBox.app", "/Applications/DBeaver.app"], "allowed_urls": ["https://stackoverflow.com","localhost"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeProgramming, "isAllowedListApproach":true, "isBlockedAllUrls":false]

        case 2://Graphic Design
            dic = ["name":"\(titleGraphicDesign) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Figma.app", "/Applications/Adobe Illustrator.app", "/Applications/Adobe Photoshop.app", "/Applications/Google Chrome.app"], "allowed_urls": ["https://www.figma.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeGraphicDesign, "isAllowedListApproach":true, "isBlockedAllUrls":false]
            
        case 3://Data Analysis
            dic = ["name":"\(titleDataAnalysis) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Excel.app", "/Applications/Google Chrome.app"], "allowed_urls": ["https://www.office.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeDataAnalysis, "isAllowedListApproach":true, "isBlockedAllUrls":false]
        
        case 4:
            dic = ["name":"\(textFieldSomethingElse.stringValue) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Excel.app", "/Applications/Microsoft Word.app", "/Applications/Google Chrome.app", "/System/Applications/Calendar.app"], "allowed_urls": ["https://www.google.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeSomethingElse, "isAllowedListApproach":true, "isBlockedAllUrls":false]

            
        default:
            break
        }
        
        if dic != nil{
            let id = getUuid()
            dic!["id"] = id
//            UserDefaults.standard.set(dic, forKey: kUserdefaultsFocusAddedFromFirstHabit)
            addLog(text: "preload Focus modeVC:-  button Continue clicked")
            preloadFocusModesWindowControllerObj!.contentViewController = getPreloadFocusModeAppsVcObj()
            preloadFocusModeAppsVcObj?.resetView(dic: dic!)


        }
        
//        thirdVcObj?.btnFocesModesLodded()
        
        
    }
   

    func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else{
            return;
        }
        if textfield == textFieldSomethingElse{
            if textFieldSomethingElse.stringValue.isEmpty{
                btnContinue.isEnabled = false
                lblGotIt.stringValue = ""
            }else{
                if textfield.stringValue.count > 250{
                    textfield.currentEditor()?.deleteBackward(nil)
                    return;
                }
                
                btnContinue.isEnabled = true
                lblGotIt.stringValue = gotItText.replacingOccurrences(of: "<WORK_TYPE>", with: textfield.stringValue)
            }
        }
    }
    
}
