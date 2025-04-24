//
//  unusedCode.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

//*** UNUSED CODE WHICH MAY BE USED LATER***//

// **TRYING MAGIC LINK**//

//    func sendLink(completionHandler: @escaping(_ result: NSDictionary?) -> ()){
//
//        let responsePath = "https://dev-2hidr8ad.us.auth0.com/passwordless/start"
//        if let responsePathUrl = NSURL(string: responsePath){
//
//            let request = NSMutableURLRequest(url:responsePathUrl as URL);
//            request.httpMethod = "POST";
//
//
//            let parameters = [
//              "client_id": "dgMrlNC5mM634Sxi9SLqIqi0WvgVpwX7",
//              "connection": "email",
//              "email": "prashant.wtl@gmail.com",// email
//              "send": "link"
//            ] as [String : Any]
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//            let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
//            request.httpBody = jsonData
//            let task = URLSession.shared.dataTask(with: request as URLRequest) {
//                data, response, error in
//
//                if let httpResponse = response as? HTTPURLResponse{
//                    if httpResponse.statusCode == 200{ //it means it is right //
//                        if data != nil{
//                            do {
//                                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//                                    addLog(text: "api call getKeyWords return success")
//                                    completionHandler(jsonResult)
//                                    return
//                                }
//
//                            }catch{
//                                addLog(text: "api call getKeyWords return error:- \(error.localizedDescription)")
//                                completionHandler(nil)
//                                print(error)
//                                return;
//                            }
//                        }
//                    }else{
//
//                        completionHandler(nil)
//                        return
//                    }
//                }
//
//                if error != nil {
//                    addLog(text: "api call getKeyWords return error:- \(error!.localizedDescription)")
//                    completionHandler(nil)
//                    return
//                }
//                completionHandler(nil)
//                return
//            }
//
//            task.resume()
//        }else{
//            completionHandler(nil)
//        }
//
//
//    }



//** AUTH0 LOGIN**//

//    var sessionStart = false
//    func login(isLogin:Bool) {
//        addLog(text: "show Login window")
//        print("*****login call")
//
////        sessionStart = true
//
//        var parameters = [String:String]()
//        if isLogin{
//            parameters = ["prompt": "login"]
//        }else{
//            parameters = ["screen_hint":"signup"]
//        }
//
//        Auth0
//            .webAuth()
//            .useEphemeralSession()
//            .parameters(parameters)// Ignore the cookie (if present) and show the login page
//            .scope("offline_access")
//            .audience("https://auth.focusbear.io/api/v2/")
//            .start { [self] result in
////                if !sessionStart{
////                    addLog(text: "session already closed")
////                    return;
////                }
////                sessionStart = false
//                DispatchQueue.main.async {
//                    if loginHelpWcObj != nil{
//                        if loginHelpWcObj?.window?.isVisible ?? false{
//                            loginHelpWcObj?.window?.close()
//                        }
//                    }
//                }
//                switch result {
//                case .success(let credentials):// baad mai check krna iske ander main thred hota h kya automatically hi
//                    addLog(text: "Login success")
//                    DispatchQueue.main.async {
//                        self.statusbutton?.action = nil
//                        self.user = User(from: credentials.accessToken)
//                        let _ = self.credentialsManager.store(credentials: credentials)
//                        self.loadCredentialsAndDeviceId()
//                        if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) == nil{
////                            showOnboardingCardWindow()
//                        }
//                    }
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                    print("Failed with: \(error)")
//                    DispatchQueue.main.async {
//                        showAskLoginWindow()
//                    }
//
////                    addLog(text: "login failed - app quit")
////                    DispatchQueue.main.async {
////                        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
////                        self.terminateFromSelf = true
////                        NSApp.terminate(self)
////                    }
//                }
//            }
//    }

//**AUTH0 LOGOUT//**

//        login()// agar loin ko call krna hi h to alag se code likho or app close krna jyada sahi rhega automatially lgin view aayga
//        Auth0.webAuth()
//            .useEphemeralSession()
//            .parameters(["prompt": "login"]) // Ignore the cookie (if present) and show the login page
//            .start { result in
//                switch result {
//                case .success:
//                    self.user = nil
//                    //            let _ = self.credentialsManager.clear()
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                }
//
//            }
//        return;
//        Auth0
//            .webAuth()
//            .clearSession { result in
//                switch result {
//                case .success:
//                    self.user = nil
//                    let _ = self.credentialsManager.clear()
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                }
//            }





//        ***************** needed in testing only *********************
//
//
//                                shutoff window
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.shutOffMac()
//
//                                show evening habits
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.showAllEveningHabits()
//                                showBlankWindowInSecondaryMonitor()
//                                self.perform(#selector(showMorningHabitAfterTimer), with: nil, afterDelay: 80)
//
//
//
//
//                                show brain dump window
//                                showBrainDumpWindow()
//                                showAskLoginWindow()//
//
//
//                                use this to show abort done view
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj!.showAbortConfirmationView()
//                                showBlankWindowInSecondaryMonitor()
//                                showWelcomeOnboardingWindow()//
//                                showOnboardingVideoWindow()
//                                showOnboardingCardWindow(isLogin: true)
//                                showBreakWarningWindow()
//                                showEasyPostponeWindow()
//                                showPreloadFocusModesWindow()
//                                preloadFocusModesWindowControllerObj!.contentViewController = getHowHeardVcObj()
//                                showPopUpOfflineWindow()
//                                showExtraNagsAfterInactivity()
//                                showTrialExpiredWindow()
//
//                                mainWindowControllerObj?.loadWindow()
//                                isHabitAlreadyShowed = true

//                                UserDefaults.standard.set(Date().dayBefore, forKey: kUserdefaultsEveningHabitsShowedTillDate)
//                                arrKeywordsToAllowInFocus = ["111", "222", "333"]//
//                                lastFocusModeTempInfo = lastFocusTempInfo(id: "currentFocusModeId", arrAllowedAppsInCuddlyModeCurrentFocus: [], arrAllowedUrlsInCuddlyModeCurrentFocus: ["google.com", "facebook.com"])
//                                showaddFocusTempUrlsOrAppsWindow()//
//
//                                showFocusEndWarningWindow()
//
//                                getPreloadFocusModesWindowControllerObj()
//                                preloadFocusModesWindowControllerObj!.contentViewController = getFocusTipsVcObjObj()
//                                preloadFocusModesWindowControllerObj!.showWindow(self)
//
//                                showWelcomeWindow()
//                                showHowHeardWindow()
//                                showAskLoginWindow()
//                                showChooseFrictionLevelWindow()
//
//                                showNaturalBreakDetectionWindow()
//                                showChooseFrictionLevelWindow()
//                                showCustomLoginWindow(isLogin: false)
//                                return;//
//        ®
//        *******************************************************************


//func getSchemsFile(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {//
//    if let myUrl = NSURL(string: "https://focus-bear.github.io/assets/config/settings-schema.json"){
//
//        let request = NSMutableURLRequest(url:myUrl as URL);
//        request.httpMethod = "GET";
//
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if let httpResponse = response as? HTTPURLResponse {
//                if httpResponse.statusCode == 200{
//
//                    if data != nil{
//
//                        do {
//                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//
//                                print(jsonResult)
//                                completionHandler(jsonResult)
//                                return
//                            }
//
//                        }catch{
//                            print(error)
//                        }
//
//                    }
//                    completionHandler(nil)
//                    return
//                }else{
//                    completionHandler(nil)
//                    return
//                }
//            }
//            if error != nil {
//                completionHandler(nil)
//                return
//            }
//            completionHandler(nil)
//        }
//        task.resume()
//    }else{
//        completionHandler(nil)
//    }
//}





// done 28/7/23
// short cut key in search
// hide text box in set intention
// rearrange code
// bug solved focus end screen


//aisettingsvc



//if event.keyCode == 122{//f1
//    char = "f1"
//}else if event.keyCode == 120 {//f2
//    char = "f2"
//}else if event.keyCode == 99 {//f3
//    char = "f3"
//}else if event.keyCode == 118 {//f4
//    char = "f4"
//}else if event.keyCode == 96 {//f5
//    char = "f5"
//}else if event.keyCode == 97 {//f6
//    char = "f6"
//}else if event.keyCode == 98 {//f7
//    char = "f7"
//}else if event.keyCode == 100 {//f8
//    char = "f8"
//}else if event.keyCode == 101 {//f9
//    char = "f9"
//}else if event.keyCode == 109 {//f10
//    char = "f10"
//}else if event.keyCode == 103 {//f11
//    char = "f11"
//}else if event.keyCode == 111 {//f12
//    char = "f12"
//}
//We're going to request permissions to control Chrome / Safari / Other browsers / System Events. This is needed to block distracting websites when you start a focus mode or to hide/unhide the dock.

//extension menuViewController: NSTableViewDelegate, NSTableViewDataSource{
//
//    func numberOfRows(in tableView: NSTableView) -> Int {
//        addLog(text: "menuViewController tableview:- numberOfRows")
//        var isFocusModeOn = false
//        var isFocusModePaused = false
//        for dic in arrFocusType{
//            if dic["isOn"] as? Bool == true{
//                isFocusModeOn = true
//            }else if dic["isPaused"] as? Bool == true{
//                isFocusModePaused = true
//            }
//        }
//        if isFocusModeOn || isFocusModePaused{
//            lblOn.isHidden = false
//            if isFocusModeOn{
//                setRemainingTime()
//            }else {
//                let secondsBetween = appdelegate!.remainingFocusModeSecondsAfterPaused
//
//                var titleTimeRemainingText = "Time remaining:"
//
//                if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                    titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
//                }
//
//                titleTimeRemainingText = titleTimeRemainingText + " " + getStringTimeFromSeconds(seconds: Int(secondsBetween))
//                lblOn.stringValue = titleTimeRemainingText
//            }
//            return 1
//        }else{
//            lblOn.isHidden = true
//        }
//
//        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
//            return 2
//        }
//
//        if isHardCorePomodoroModeOn{
//            lblTitleFocus.stringValue = itemHardcorePomodoroTitle
//            return 1
//        }
//        lblTitleFocus.stringValue = itemFocusTitle
//
//        return arrFocusType.count
//    }
//
//    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
//        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocus"), owner: nil) as? tblCellFocus {
//            cell.rowHeight.constant = CGFloat(rowHeight)
//            cell.boxtitle.isTableView = true
//            addLog(text: "menuViewController tableview:- viewFor tableColumn")
//            var cRow = row
//            if isHardCorePomodoroModeOn{
//                for i in 0..<arrFocusType.count{
//                    if arrFocusType[i]["name"] as? String == hardcodePmodoroFocusModeName{
//                        cRow = i
//                        break;
//                    }
//                }
//            }
//            for i in 0..<arrFocusType.count{
//                let dic = arrFocusType[i]
//                if dic["isOn"] as? Bool == true{
//                    cRow = i
//                    break;
//                }else if dic["isPaused"] as? Bool == true{
//                    cRow = i
//                    break;
//                }
//            }
//            if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{//Don’t ask them to set up focus modes upfront
//                if row == 0{
//                    for i in 0..<arrFocusType.count{
//                        if arrFocusType[i]["isDefault"] as? Bool == true{
//                            cRow = i
//                            break;
//                        }
//                    }
//                }else if row == 1{
//                    for i in 0..<arrFocusType.count{
//                        if arrFocusType[i]["isRelaxFocus"] as? Bool == true{
//                            cRow = i
//                            break;
//                        }
//                    }
//                }
//            }
//
//            cell.boxtitle.tagValue = cRow
//
//
//            if let name = arrFocusType[cRow]["name"] as? String{
//                cell.lblTitle.stringValue = name
//            }else{
//                cell.lblTitle.stringValue = ""
//            }
//            cell.imgViewAppIcon.isHidden = false
//            if arrFocusType[cRow]["isOn"] as? Bool == true{
//                cell.imgViewAppIcon.image = NSImage(named: NSImage.touchBarPauseTemplateName)
//                if SettingsManagerObject.selectedFontIndex == intelOneMonoIndex{
//                    cell.lblTitle.font = getBoldFont(size: 12)
//                    cell.lblIntension.font = getRegularFont(size: 11)
//                }else if SettingsManagerObject.selectedFontIndex == openDyslexicIndex{
//                    cell.lblTitle.font = getBoldFont(size: 10)
//                    cell.lblIntension.font = getRegularFont(size: 10)
//                }else{
//                    cell.lblTitle.font = getBoldFont(size: cell.lblTitle.font?.pointSize ?? 12)
//                    cell.lblIntension.font = getRegularFont(size: 11)
//                }
//
//                cell.lblTitle.textColor = buttonTitleColor
//                if let color = arrFocusType[cRow]["color"] as? String{
//                    cell.boxColor.fillColor = HexToColor(hexString: color)
//                }
//                cell.backgroundcolor = NSColor.black.withAlphaComponent(0.1)
//                if whatToAchieveInFocusBlock.isEmpty{
//                    cell.lblIntension.isHidden = true
//                }else{
//                    cell.lblIntension.isHidden = false
//                    cell.lblIntension.stringValue = whatToAchieveInFocusBlock
//                }
//            }else if arrFocusType[cRow]["isPaused"] as? Bool == true{
//                cell.boxColor.fillColor = .tertiaryLabelColor
//                cell.imgViewAppIcon.image = NSImage(named: NSImage.touchBarPlayPauseTemplateName)
//                cell.lblIntension.isHidden = true
//                cell.lblTitle.font = getRegularFont(size: cell.lblTitle.font?.pointSize ?? 12)
//                cell.lblTitle.textColor = NSColor.black
//                cell.backgroundcolor = NSColor.black.withAlphaComponent(0.1)
//            }else{//on NSTouchBarPlayTemplate
//                cell.boxColor.fillColor = .tertiaryLabelColor
//                cell.imgViewAppIcon.image = NSImage(named: NSImage.Name("NSTouchBarPlayTemplate"))
//                cell.lblIntension.isHidden = true
//                cell.lblTitle.font = getRegularFont(size: cell.lblTitle.font?.pointSize ?? 12)
//                cell.lblTitle.textColor = NSColor.black
//                cell.backgroundcolor = NSColor.clear
//            }
//
//            cell.btnEditFocusMode.isHidden = true
//            cell.btnEditFocusMode.target = self
//            cell.btnEditFocusMode.tag = cRow
//            cell.btnEditFocusMode.action = #selector(btnEditFocusModeClicked(sender:))
//
//            cell.btnInfoIcon.isHidden = true
//            cell.btnInfoIcon.target = self
//            cell.btnInfoIcon.tag = cRow
//            cell.btnInfoIcon.action = #selector(btnEditFocusModeClicked(sender:))
//
//
//            if arrFocusType[cRow]["isLockedFocus"] as? Bool == true{
//                cell.isInfoIconVisible = true
//            }else{
//                cell.isInfoIconVisible = false
//            }
//
//            cell.boxtitle.fillColor = .clear
//            return cell
//        }
//
//        return NSTableCellView()
//    }
//
//    @objc func btnEditFocusModeClicked(sender:NSButton){
//        addLog(text: "btn Edit FocusMode Clicked from menu")
//
//        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//            if trialExpiredNagWcObj != nil{
//                if trialExpiredNagWcObj?.window?.isVisible ?? false{
//                    return;
//                }
//            }
//            showUpgradeNowWindow()
//            return;
//        }
//
//        if arrFocusType[sender.tag]["isLockedFocus"] as? Bool == true{
//
//            var msg = "Use this if you want to focus on using one app/reading one article. We'll detect the current app + site you have open and block everything else."
//            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                msg = menuInfo.value(forKey: "toolTipLockedFocus") as? String ?? msg
//            }
//
//            showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
//            return;
//        }
//
//        var shouldShowPassword = true
//        if preferencesWindowControllerObj?.window?.isVisible ?? false{
//            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                tabview.selectedTabViewItemIndex = preferencesFocusModesIndex
//                addLog(text: "")
//            }
//            shouldShowPassword = false
//        }else{
//            preferencesWindowControllerObj?.showWindow(self)
//        }
//        addLog(text: "Showing preferences")
//        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//            tabview.selectedTabViewItemIndex = preferencesFocusModesIndex
//            if shouldAskPassword() && shouldShowPassword{
//                tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
//                tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
//                getEnterPasswordVcObjForPreferences().parentVc = nil
//                enterPasswordVcObjForPreferences?.removeConstraints()
//                addLog(text: "Showing enter password view")
//            }
//        }
//
//        DispatchQueue.global().async {
//            DispatchQueue.main.async {
//                focusPreferencesVcObj?.tblViewFocusType.selectRowIndexes(IndexSet(integer: sender.tag), byExtendingSelection: false)
//                focusPreferencesVcObj?.tblViewFocusType.scrollRowToVisible(sender.tag)
//            }
//        }
//    }
//
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return CGFloat(rowHeight)
//    }
//    func tableViewSelectionDidChange(_ notification: Notification) {
//        print("tableViewSelectionDidChange")
//
//    }
//    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
//        return false
//    }
//}


//    var timer:Timer?
//    func startFocusRemainingTimer() {
//        if timer != nil{
//            timer?.invalidate()
//            timer = nil
//        }
//        setRemainingTime()
//        DispatchQueue.main.async {
//            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
//            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
//        }
//    }
    
//    @objc func performTimerCount() {
//        if !isFocusModeOn(){
//            if !isFocusModePaused(){
//                lblOn.isHidden = true
//            }else{
//                let secondsBetween = appdelegate!.remainingFocusModeSecondsAfterPaused
//
//                var titleTimeRemainingText = "Time remaining:"
//
//                if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//                    titleTimeRemainingText = brainDumpVcInfo.value(forKey: "titleTimeRemainingText") as? String ?? titleTimeRemainingText
//                }
//
//                titleTimeRemainingText = titleTimeRemainingText + " " + getStringTimeFromSeconds(seconds: Int(secondsBetween))
//                lblOn.stringValue = titleTimeRemainingText
//            }
//            timer?.invalidate()
//            return;
//        }
//        DispatchQueue.main.async {
//            self.setRemainingTime()
//        }
//    }


//    var rowHeight = 32
//    func resetViewHeight(){
//        addLog(text: "menuViewController resetViewHeight start")
//        var height = 34
//        if SettingsManagerObject.selectedFontIndex == openDyslexicIndex{
//            rowHeight = 40
//        }
//        if SettingsManagerObject.selectedFontIndex == poppinsIndex{
//            rowHeight = 36
//        }
//        let isFocusModeOnOrPaused = isFocusModeOnOrPaused()
//        if isHardCorePomodoroModeOn || isFocusModeOnOrPaused{
//            if SettingsManagerObject.selectedFontIndex == openDyslexicIndex{
//                height = 58
//            }
//            if SettingsManagerObject.selectedFontIndex == poppinsIndex{
//                height = 45
//            }
//            if SettingsManagerObject.selectedFontIndex == intelOneMonoIndex{
//                height = 43
//            }
//            height += rowHeight // only one focus mode will be visible which is on for hardcore pomodoro mode
//        }else if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
//            height += (rowHeight * 2)// only two focus mode will be visible
//        }else{
//            if arrFocusType.count > 6{
//                height += (6*rowHeight)
//            }else{
//                height += (arrFocusType.count * rowHeight)
//            }
//
//        }
//
//        if isFocusModeOnOrPaused{
//            height += 19 //on label space
//        }
//        if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
//            height += 34 //set focus mode button space
//        }
//        if !boxStartPomodoroMode.isHidden{
//            height += 34 //set Pomodoro button space
//        }
//        if !boxStopHardcorePomodoroMode.isHidden{
//            height += 34 //set Stop Hardcore Pomodoro button space
//        }
//        let cgFlotHeight = CGFloat(height)
//        if focusModeBoxHeight.constant != cgFlotHeight{
//            focusModeBoxHeight.constant = cgFlotHeight
//        }
//        addLog(text: "menuViewController resetViewHeight end")
//    }
