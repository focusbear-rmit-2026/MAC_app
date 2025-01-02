//
//  selectHabitPacksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class selectHabitPacksVc: NSViewController {// not in use

    @IBOutlet weak var lblHabitPackInfo: NSTextField!
    @IBOutlet weak var lblChooseOptions: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    
    @IBOutlet weak var webView: WKWebView!
    var morningRoutineText = "Morning routine duration:"
    var eveningRoutineText = "Evening routine duration:"
    var morningRoutineDuration: Int = 0
    var eveningRoutineDuration: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "Choose a habit pack to get started"
        btnContinue.title = "Continue"
        lblChooseOptions.stringValue = "Choose one of the following options:"
        lblHabitPackInfo.stringValue = "A habit pack is a collection of habits to do in the morning, the evening and during breaks"
        lblTitle.isHidden = true
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "titleSelectHabitPack") as? String ?? lblQuestion.stringValue
            morningRoutineText = askAppWorkVcInfo.value(forKey: "morningRoutineText") as? String ?? morningRoutineText
            eveningRoutineText = askAppWorkVcInfo.value(forKey: "eveningRoutineText") as? String ?? eveningRoutineText
            lblChooseOptions.stringValue = askAppWorkVcInfo.value(forKey: "chooseOptionsText") as? String ?? lblChooseOptions.stringValue
            lblHabitPackInfo.stringValue = askAppWorkVcInfo.value(forKey: "habitPackInfoText") as? String ?? lblHabitPackInfo.stringValue
        }
        allApiObject.capturePosthog(event: "habit-packs-shown", metadata: [:])
    }
    override func viewDidAppear() {
//        showOnboardingProgress(view: self.view, progress: 12)
    }
    override func viewWillDisappear() {
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    override func viewWillAppear() {
        popUpBtn.removeAllItems()
        if habitPacksData != nil{
            if habitPacksData!.count != 0{
                for pack in habitPacksData!{
                    let name = pack["pack_name"] as? String ?? ""
                    popUpBtn.addItem(withTitle: name)
                }
            }
        }
        if popUpBtn.numberOfItems != 0{
            popUpBtn.selectItem(at: 0)
            morningRoutineDuration = habitPacksData![0]["morning_routine_duration_seconds"] as? Int ?? 0
            eveningRoutineDuration = habitPacksData![0]["evening_routine_duration_seconds"] as? Int ?? 0
            loadVideoAt(index: 0)
        }
        lblDescription.isHidden = true
        
        if isHabitsDisabled{
            lblQuestion.stringValue = "Choose your break activities to get started"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "titleSelectBreaks") as? String ?? lblQuestion.stringValue
            }
        }else{
            lblQuestion.stringValue = "Choose a habit pack to get started"
            if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
                lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "titleSelectHabitPack") as? String ?? lblQuestion.stringValue
            }
        }
    }
    @IBAction func popUpBtnClicked(_ sender: Any) {
        if habitPacksData?.count != 0{
            let index = popUpBtn.indexOfSelectedItem
            morningRoutineDuration = habitPacksData![index]["morning_routine_duration_seconds"] as? Int ?? 0
            eveningRoutineDuration = habitPacksData![index]["evening_routine_duration_seconds"] as? Int ?? 0
            loadVideoAt(index: index)
        }
    }
    
    func loadVideoAt(index:Int){
        let id = habitPacksData![index]["id"] as? String ?? ""
        let url = "https://dashboard.focusbear.io/habit-packs/share/\(id)?embedded=true&bust_cache=\(getUuid())"
        let link = URL(string:url)!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        if popUpBtn.numberOfItems != 0{
            let index = popUpBtn.indexOfSelectedItem
            let id = habitPacksData![index]["id"] as? String ?? ""
            if !id.isEmpty{
                UserDefaults.standard.set(id, forKey: kUserdefaultsPackIdSelected)
            }
        }
        mainViewControllerObj!.showAskWorkTimeVc()
    }
}
