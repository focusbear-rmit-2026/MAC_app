//
//  setUpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class setUpVc: NSViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var imgViewCustomiseFocusMode: NSImageView!
    @IBOutlet weak var imgViewCustomiseHabit: NSImageView!
    @IBOutlet weak var imgViewSetBlockedUrls: NSImageView!
    @IBOutlet weak var imgViewCompleteMorningRoutine: NSImageView!
    @IBOutlet weak var imgViewCompleteEveningRoutine: NSImageView!
    @IBOutlet weak var imgViewFocusSession: NSImageView!
    
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblTotalProgress: NSTextField!
    @IBOutlet weak var boxProgressFull: NSBox!
    @IBOutlet weak var boxProgressWidth: NSLayoutConstraint!
    @IBOutlet weak var boxProgress: NSBox!
   
    @IBOutlet weak var lblCustomiseFocusMode: NSTextField!
    @IBOutlet weak var lblCustomiseHabit: NSTextField!
    @IBOutlet weak var lblSetBlockedUrls: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutine: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutine: NSTextField!
    @IBOutlet weak var lblFocusSession: NSTextField!
    
    @IBOutlet weak var lblCustomiseFocusModeProgress: NSTextField!
    @IBOutlet weak var lblCustomiseHabitProgress: NSTextField!
    @IBOutlet weak var lblSetBlockedUrlsProgress: NSTextField!
    @IBOutlet weak var lblCompleteMorningRoutineProgress: NSTextField!
    @IBOutlet weak var lblCompleteEveningRoutineProgress: NSTextField!
    @IBOutlet weak var lblFocusSessionProgress: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Setup"
        lblCustomiseFocusMode.stringValue = "Customise a focus mode"
        lblCustomiseHabit.stringValue = "Customise your habits"
        lblSetBlockedUrls.stringValue = "Set always blocked URLs"
        lblCompleteMorningRoutine.stringValue = "Complete your morning routine 10 times"
        lblCompleteEveningRoutine.stringValue = "Complete your evening routine 10 times"
        lblFocusSession.stringValue = "Do 10 focus sessions"
        
        if let setUpVcInfo = configjson.value(forKey: "setUpVcInfo") as? NSDictionary{
            lblTitle.stringValue = setUpVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblCustomiseFocusMode.stringValue = setUpVcInfo.value(forKey: "customiseFocusModeText") as? String ?? lblCustomiseFocusMode.stringValue
            lblCustomiseHabit.stringValue = setUpVcInfo.value(forKey: "customiseHabitText") as? String ?? lblCustomiseHabit.stringValue
            lblSetBlockedUrls.stringValue = setUpVcInfo.value(forKey: "setBlockedUrlsText") as? String ?? lblSetBlockedUrls.stringValue
            lblCompleteMorningRoutine.stringValue = setUpVcInfo.value(forKey: "completeMorningRoutineText") as? String ?? lblCompleteMorningRoutine.stringValue
            lblCompleteEveningRoutine.stringValue = setUpVcInfo.value(forKey: "completeEveningRoutineText") as? String ?? lblCompleteEveningRoutine.stringValue
            lblFocusSession.stringValue = setUpVcInfo.value(forKey: "focusSessionText") as? String ?? lblFocusSession.stringValue
        }
        
        self.webView.navigationDelegate = self
        let url = "https://dashboard.focusbear.io/webview/stats"
        let  fileURL = URL(string: url)
        let request = NSMutableURLRequest(url: fileURL!)
        webView.load(request as URLRequest)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("*************didFinish navigation**************")
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.setAccessTokenToWebView()
            }
        }
    }
    
    override func viewDidAppear() {
        setAccessTokenToWebView()
        self.view.window?.styleMask.insert(.resizable)
    }

    func setAccessTokenToWebView(){
        let stringJson1 = "{access_token: \"\(appdelegate!.credential?.accessToken ?? "")\"}"
        
        let javascript = "loadAccessTokenForStats(\(stringJson1));"
        
        webView.evaluateJavaScript(javascript,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print("****error")
            print(html)
        })
    }
    override func viewWillAppear() {
        let maximumProgressWidth = boxProgressFull.frame.width - (boxProgressFull.borderWidth*2)

        let isEditFocusModeOnce = UserDefaults.standard.object(forKey: kUserdefaultsEditFocusModeOnce) as? Bool ?? false
        
       
        let isEditHabitsOnce = UserDefaults.standard.object(forKey: kUserdefaultsEditHabitsOnce) as? Bool ?? false
        
        let isEditBlockedUrlsOnce = UserDefaults.standard.object(forKey: kUserdefaultsEditBlockedUrlsOnce) as? Bool ?? false
        
        let morningRoutineDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsMorningRoutineDoneCount) as? Int ?? 0
        
        let eveningRoutineDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsEveningRoutineDoneCount) as? Int ?? 0
        
        let focusModeDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeDoneCount) as? Int ?? 0
        
        let checkImg = #imageLiteral(resourceName: "check_circle")
        let unCheckImg = #imageLiteral(resourceName: "uncheck_circle")
        
        var arrProgress = [Int]()
        if isEditFocusModeOnce{
            arrProgress.append(100)
            lblCustomiseFocusModeProgress.stringValue = "(100%)"
            imgViewCustomiseFocusMode.image = checkImg
        }else{
            arrProgress.append(0)
            lblCustomiseFocusModeProgress.stringValue = "(0%)"
            imgViewCustomiseFocusMode.image = unCheckImg
        }
        
        if isEditHabitsOnce{
            arrProgress.append(100)
            lblCustomiseHabitProgress.stringValue = "(100%)"
            imgViewCustomiseHabit.image = checkImg
        }else{
            arrProgress.append(0)
            lblCustomiseHabitProgress.stringValue = "(0%)"
            imgViewCustomiseHabit.image = unCheckImg
        }
        
        if isEditBlockedUrlsOnce{
            arrProgress.append(100)
            lblSetBlockedUrlsProgress.stringValue = "(100%)"
            imgViewSetBlockedUrls.image = checkImg
        }else{
            arrProgress.append(0)
            lblSetBlockedUrlsProgress.stringValue = "(0%)"
            imgViewSetBlockedUrls.image = unCheckImg
        }
        

        
        var morningRoutineProgress = morningRoutineDoneCount * 10
        if morningRoutineProgress > 100 {
            morningRoutineProgress = 100
        }
        if morningRoutineProgress == 100{
            imgViewCompleteMorningRoutine.image = checkImg
        }else{
            imgViewCompleteMorningRoutine.image = unCheckImg
        }
        
        arrProgress.append(morningRoutineProgress)
        lblCompleteMorningRoutineProgress.stringValue = "(\(morningRoutineProgress)%)"
        
        var eveningRoutineProgress = eveningRoutineDoneCount * 10
        if eveningRoutineProgress > 100 {
            eveningRoutineProgress = 100
        }
        
        if eveningRoutineProgress == 100{
            imgViewCompleteEveningRoutine.image = checkImg
        }else{
            imgViewCompleteEveningRoutine.image = unCheckImg
        }
        
        arrProgress.append(eveningRoutineProgress)
        lblCompleteEveningRoutineProgress.stringValue = "(\(eveningRoutineProgress)%)"
        
        var focusModeProgress = focusModeDoneCount * 10
        if focusModeProgress > 100 {
            focusModeProgress = 100
        }
        
        if focusModeProgress == 100{
            imgViewFocusSession.image = checkImg
        }else{
            imgViewFocusSession.image = unCheckImg
        }
        arrProgress.append(focusModeProgress)
        lblFocusSessionProgress.stringValue = "(\(focusModeProgress)%)"
        
        
        
        let sumArray = arrProgress.reduce(0, +)

        var averageProgress:Double = Double(sumArray) / Double(arrProgress.count)
        
        averageProgress = Double(round(100 * averageProgress) / 100)
        
        lblTotalProgress.stringValue = "\(averageProgress)%"
        
        boxProgressWidth.constant = CGFloat((Double(maximumProgressWidth)*averageProgress)/100)
        
        
    }
 
    override func viewWillDisappear() {
        self.view.window?.styleMask.remove(.resizable)
    }
}
