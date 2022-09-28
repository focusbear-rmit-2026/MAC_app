//
//  preloadFocusModesVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class preloadFocusModesVc: NSViewController, NSTextFieldDelegate {


    @IBOutlet weak var textFieldSomethingElse: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var popUpBtnWork: NSPopUpButton!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    var titleProgramming = "Programming"
    var titleGraphicDesign = "Graphic Design"
    var titleDataAnalysis = "Data Analysis"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
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
        }
        
        popUpBtnWork.addItem(withTitle: titleSelectWorkType)
        popUpBtnWork.addItem(withTitle: titleProgramming)
        popUpBtnWork.addItem(withTitle: titleGraphicDesign)
        popUpBtnWork.addItem(withTitle: titleDataAnalysis)
        popUpBtnWork.addItem(withTitle: titleSomethingElse)
        
        
    }
    
    
    @IBAction func popUpBtnSelectWorkClicked(_ sender: Any) {
        textFieldSomethingElse.stringValue = ""
        let selectedIndex = popUpBtnWork.indexOfSelectedItem
        switch selectedIndex {
        case 0:
            btnContinue.isEnabled = false
            textFieldSomethingElse.isHidden = true
        case 1:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
        case 2:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
        case 3:
            textFieldSomethingElse.isHidden = true
            btnContinue.isEnabled = true
        case 4:
            btnContinue.isEnabled = false
            textFieldSomethingElse.isHidden = false
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
            dic = ["name":"\(titleProgramming) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Visual Studio Code.app", "/Applications/XCode.app", "/Applications/Utilities/Terminal.app"], "allowed_urls": ["https://stackoverflow.com","localhost"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeProgramming]

        case 2://Graphic Design
            dic = ["name":"\(titleGraphicDesign) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Figma.app", "/Applications/Adobe Illustrator.app", "/Applications/Adobe Photoshop.app"], "allowed_urls": ["https://www.figma.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeGraphicDesign]
            
        case 3://Data Analysis
            dic = ["name":"\(titleDataAnalysis) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Excel.app"], "allowed_urls": ["https://www.office.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "jobType":jobTypeDataAnalysis]
        
        case 4:
            dic = ["name":"\(textFieldSomethingElse.stringValue) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":true, "isAllowedAllUrls":true, "jobType":jobTypeSomethingElse]

            
        default:
            break
        }
        
        if dic != nil{
            let id = getUuid()
            dic!["id"] = id
            UserDefaults.standard.set(dic, forKey: kUserdefaultsFocusAddedFromFirstHabit)



//            allApiObject.addFocusMode(focusType: dic!, completionHandler: {newDic in //  yha ad nahi krenge jga focus mode ki list get krte h vh a pahle hi userdefaults  se get krke fie vapas add or upload krenege
////                if newDic != nil{
////                    dic!["id"] = newDic!.value(forKey: "id") as? String ?? ""//["id"] as? String ?? ""
////
////                }
//
//            })
        }
        
        thirdVcObj?.btnFocesModesLodded()
    }
    

    func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else{
            return;
        }
        if textfield == textFieldSomethingElse{
            if textFieldSomethingElse.stringValue.isEmpty{
                btnContinue.isEnabled = false
            }else{
                btnContinue.isEnabled = true
            }
        }
    }
    
}
