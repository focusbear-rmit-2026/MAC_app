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
//                    //logout()
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



// remove this block below
//                UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
//                UserDefaults.standard.removeObject(forKey: kUserdefaultsFirstRun)
//                UserDefaults.standard.removeObject(forKey: kUserdefaultsVideoShown)
//                UserDefaults.standard.removeObject(forKey: kUserdefaultsSelectedJson)
//                self.user = nil
//                let _ = self.credentialsManager.clear()
//                self.credential = nil
//                UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
///////  remove this code above

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
