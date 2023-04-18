//
//  selectHabitPacksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/03/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class selectHabitPacksVc: NSViewController {

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
        lblQuestion.stringValue = "Select habits from Featured Habit Packs to get you started using Focus Bear"
        btnContinue.title = "Continue"
        lblTitle.isHidden = true
        
        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            //lblTitle.stringValue = askAppWorkVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblQuestion.stringValue = askAppWorkVcInfo.value(forKey: "titleSelectHabitPack") as? String ?? lblQuestion.stringValue
            morningRoutineText = askAppWorkVcInfo.value(forKey: "morningRoutineText") as? String ?? morningRoutineText
            eveningRoutineText = askAppWorkVcInfo.value(forKey: "eveningRoutineText") as? String ?? eveningRoutineText
        }
        allApiObject.capturePosthog(event: "habit-packs-shown", metadata: [:])
    }
    override func viewWillDisappear() {
        let link = URL(string:"about:blank")!
        let request = URLRequest(url: link)
        self.webView.load(request)
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
//            let description = habitPacksData![0]["welcome_message_plain_text"] as? String ?? ""
            morningRoutineDuration = habitPacksData![0]["morning_routine_duration_seconds"] as? Int ?? 0
            eveningRoutineDuration = habitPacksData![0]["evening_routine_duration_seconds"] as? Int ?? 0
//            let morningroutineDurationText = morningRoutineText + " " + getStringTime(seconds: morningroutineDuration)
//            let eveningroutineDurationText = eveningRoutineText + " " + getStringTime(seconds: eveningroutineDuration)
//            lblDescription.stringValue = description + "\n\n" + morningroutineDurationText + "\n\n" + eveningroutineDurationText
            loadVideoAt(index: 0)
        }
        lblDescription.isHidden = true
    }
    @IBAction func popUpBtnClicked(_ sender: Any) {
        let index = popUpBtn.indexOfSelectedItem
//        let description = habitPacksData![index]["welcome_message_plain_text"] as? String ?? ""
        morningRoutineDuration = habitPacksData![index]["morning_routine_duration_seconds"] as? Int ?? 0
        eveningRoutineDuration = habitPacksData![index]["evening_routine_duration_seconds"] as? Int ?? 0
//        let morningroutineDurationText = morningRoutineText + " " + getStringTime(seconds: morningroutineDuration)
//        let eveningroutineDurationText = eveningRoutineText + " " + getStringTime(seconds: eveningroutineDuration)
//        lblDescription.stringValue = description + "\n\n" + morningroutineDurationText + "\n\n" + eveningroutineDurationText
        loadVideoAt(index: index)
    }
    
    func loadVideoAt(index:Int){
        let id = habitPacksData![index]["id"] as? String ?? ""
        let url = "https://dashboard.focusbear.io/habit-packs/share/\(id)?embedded=true"
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
