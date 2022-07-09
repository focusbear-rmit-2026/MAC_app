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
        switch selectedIndex {
        case 0:
            return // not possible because button is not enabled if option 0 is selected
        case 1://Programming
                let dic:[String:Any] = ["name":"\(titleProgramming) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": ["/Applications/Visual Studio Code.app", "/Applications/XCode.app", "/Applications/Utilities/Terminal.app"], "urlsArray": ["https://stackoverflow.com","localhost"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false]
                arrFocusType.insert(dic, at: arrFocusType.count - 1)
            
            
        case 2://Graphic Design
            let dic:[String:Any] = ["name":"\(titleGraphicDesign) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": ["/Applications/Figma.app", "/Applications/Adobe Illustrator.app", "/Applications/Adobe Photoshop.app"], "urlsArray": ["https://www.figma.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false]
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
            
        case 3://Data Analysis
            let dic:[String:Any] = ["name":"\(titleDataAnalysis) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": ["/Applications/Microsoft Excel.app"], "urlsArray": ["https://www.office.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false]
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        case 4:
            let dic:[String:Any] = ["name":"\(textFieldSomethingElse.stringValue) \(workText)", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": [], "urlsArray": [], "isOn": false, "isAllowedAllApps":true, "isAllowedAllUrls":true]
            
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
            
        default:
            break
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
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
