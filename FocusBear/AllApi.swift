//
//  AllApi.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 30/07/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Foundation
var baseUrl = "https://api.focusbear.io"//https://api.aws.focusbear.io"  //https://api.focusbear.io" // also in helper app. in pusher
class AllApi:NSObject {
    
    func getConfigFile(fileUrl:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading config file")
        if let responsePathUrl = NSURL(string: fileUrl){
            addLog(text: "api call getConfigFile \(responsePathUrl)")
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "GET";
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200{
                        
                        if data != nil{
                            
                            //                    let responseStrInISOLatin = String(data: data!, encoding: String.Encoding.isoLatin1)
                            //                    guard let modifiedDataInUTF8Format = responseStrInISOLatin?.data(using: String.Encoding.utf8) else {
                            //                        print("could not convert data to UTF-8 format")
                            //                        addLog(text: "error config file: could not convert data to UTF-8 format")
                            //                        completionHandler(nil)
                            //                        return
                            //                    }
                            //
                            //
                            //                    do {
                            //                        let jsonResult = try JSONSerialization.jsonObject(with: modifiedDataInUTF8Format) as? NSDictionary
                            //                        print(jsonResult)
                            //                        completionHandler(jsonResult)
                            //                        return
                            //                    } catch {
                            //                        print(error)
                            //                        addLog(text: "error config file: \(error.localizedDescription)")
                            //                        completionHandler(nil)
                            //                        return
                            //                    }
                            
                            do {
                                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                    
                                    print(jsonResult)
                                    addLog(text: "api call getConfigFile return success")
                                    completionHandler(jsonResult)
                                    return
                                }
                                
                            }catch{
                                print(error)
                                addLog(text: "error reading config file: \(error.localizedDescription)")
                                completionHandler(nil)
                                return
                            }
                            
                        }
                        
                        completionHandler(nil)
                        return
                    }else{
                        addLog(text: "api call getConfigFile Api error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        completionHandler(nil)
                        return
                    }
                }
                if error != nil {
                    addLog(text: "error config file: \(error!.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                completionHandler(nil)
                return
            }
            task.resume()
        }else{
            completionHandler(nil)
        }
    }
    
    func isSettingsValid(settings:NSDictionary, isOnboarding:Bool, completionHandler: @escaping(_ result: NSDictionary?, _ statusCode:Int) -> ()){
        addLog(text: "func call:- api isSettingsValid user-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                var responsePath = "\(baseUrl)/user-settings?device_id=\(currentDeviceId)"
                if isOnboarding{
                    responsePath = "\(baseUrl)/user-settings?device_id=\(currentDeviceId)&is_onboarding=true"
                }
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call isSettingsValid \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: settings)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 200{ //it means it is right //
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            applastSettingsGetTime = Date()
                                            addLog(text: "api call isSettingsValid return success")
                                            completionHandler(jsonResult, httpResponse.statusCode)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call isSettingsValid return error:- \(error.localizedDescription)")
                                        completionHandler(nil, httpResponse.statusCode)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call isSettingsValid Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil, httpResponse.statusCode)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call isSettingsValid return error:- \(error!.localizedDescription)")
                            completionHandler(nil, 0)
                            return
                        }
                        completionHandler(nil, 0)
                        return
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil, 0)
                }
                
            }else{
                completionHandler(nil, 0)
                return
            }
        }
    }
    func writeJsonInLog(data: Data?){
        if data != nil{
            do {
                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                    addLog(text: "json is:- \(jsonResult)")
                }
            }catch{
                
            }
        }
    }
    
    /// Converts the current guest/anonymous account into a registered one (#1850) by
    /// calling the cross-platform backend endpoint. The backend sets the new email +
    /// password on the SAME account, so data is preserved, and sends a verification
    /// email. `completionHandler` is called on the main thread with nil on success or
    /// a user-facing error message on failure.
    func convertGuestAccount(email: String, newPassword: String, completionHandler: @escaping(_ errorMessage: String?) -> ()){
        addLog(text: "func call:- convertGuestAccount")
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            func finish(_ message: String?) {
                DispatchQueue.main.async { completionHandler(message) }
            }

            guard appdelegate!.credential != nil else {
                finish("You need to be signed in to create an account.")
                return
            }
            guard let responsePathUrl = NSURL(string: "\(baseUrl)/auth/convert-guest") else {
                finish("Something went wrong. Please try again.")
                return
            }

            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let json: [String: Any] = ["email": email, "newPassword": newPassword]
            request.httpBody = try? JSONSerialization.data(withJSONObject: json)

            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    addLog(text: "api call convert-guest error:- \(error.localizedDescription)")
                    finish("Network error. Please check your connection and try again.")
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    finish("Something went wrong. Please try again.")
                    return
                }
                if (200...299).contains(httpResponse.statusCode) {
                    addLog(text: "api call convert-guest success")
                    finish(nil)
                    return
                }
                var message = "Couldn't create your account (\(httpResponse.statusCode)). Please try again."
                if let data = data,
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let m = obj["message"] as? String {
                        message = m
                    } else if let arr = obj["message"] as? [String], let first = arr.first {
                        message = first
                    }
                }
                addLog(text: "api call convert-guest Api error:- statusCode is \(httpResponse.statusCode)")
                self.writeJsonInLog(data: data)
                finish(message)
            }
            task.resume()
        }
    }

    func getDeviceId(completionHandler: @escaping(_ deviceId:String?) -> ()){
        addLog(text: "func call:- getDeviceId")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/device"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getDeviceId \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "operating_system":"MacOS",//userId.removingPercentEncoding ?? "",
                        "metadata": [:]
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetDeviceIdErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            
                                            if let id = jsonResult.value(forKey: "id") as? String{
                                                
                                                addLog(text: "api call getDeviceId success")
                                                completionHandler(id)
                                                return
                                                
                                            }
                                            addLog(text: "api call getDeviceId error")
                                            completionHandler(nil)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getDeviceId error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call getDeviceId Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call getDeviceId error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetDeviceIdErrorFound{
                                    self.isApiGetDeviceIdErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetDeviceIdErrorFound = true
                                    addLog(text: "error getDeviceId:- try second time")
                                    self.getDeviceId(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    
    
    func captureEventEndpoint (event:String, metadata:[String:Any]){
        addLog(text: "captureEventEndpoint event: \(event)")
        
        
        guard (appdelegate!.credential?.accessToken) != nil else{
            addLog(text: "func call:- captureEventEndpoint return:- no accessToken found")
            return
        }
        
        
        var distinct_id = ""
        if appdelegate!.user != nil{
            if let userId = appdelegate!.user?.userId{
                distinct_id = userId
            }
        }else{
            distinct_id = globalUUID
        }
        
        var properties = [String:Any]()
        
        
        
        for key in metadata.keys{
            properties[key] = metadata[key]
        }
        var event_data = [String : Any]()
        event_data = ["data":properties]
        
        var json: [String: Any] = [
            "event_type": event,
            "user_properties": [
                "USERNAME": currentUserName,
                "id": distinct_id,
                "USES_MAC_APP": true
            ],
            "event_data": event_data
        ]
        
        json["operating_system"] = "macos"// for new events endpoint #1536 v 2.28.436
        json["app_version"] = getAppVersionInString()// #1255// 
        EventBuffer.shared.addEvent(json)

        
        
        
        /* old work
        let responsePath = "\(baseUrl)/events"
        if let responsePathUrl = NSURL(string: responsePath){
            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST";
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 204{ //it means it is right
                        print("api call captureEventEndpoint success")
                        // addLog(text: "api call captureEventEndpoint success")
                        return;
                    }else{
                        addLog(text: "api call captureEventEndpoint error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        return
                    }
                }
                if error != nil {
                    addLog(text: "api call captureEventEndpoint error: \(error!.localizedDescription)")
                    return
                }
                
                return
            }
            
            task.resume()
        }else{
            
            return
        }
         */
    }
    
    func capturePosthog(event:String, metadata:[String:Any]){
        if currentUserEmail.lowercased().contains("internaltest") || isTestUser{
            return;
        }
        captureEventEndpoint(event: event, metadata: metadata)

        addLog(text: "capturePosthog event: \(event)")
        
        let responsePath = "https://app.posthog.com/capture/"
        if let responsePathUrl = NSURL(string: responsePath){
            
            //addLog(text: "api call capture \(responsePathUrl)")
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "POST";
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            
            var distinct_id = ""
            if appdelegate!.user != nil{
                if let userId = appdelegate!.user?.userId{
                    distinct_id = userId
                }
            }else{
                distinct_id = globalUUID
            }
            let isGeekModeEnabled = SettingsManagerObject.isGeekModeEnabled
            var mode = "simple-mode"
            if isGeekModeEnabled{
                mode = "geek-mode"
            }
            let lastQuitReason = UserDefaults.standard.object(forKey: kUserDefaultsLastQuitReason) as? String ?? ""
            var properties = [String:Any]()
            
            properties["distinct_id"] = distinct_id
            properties["appVersion"] = appVersion
            properties["macOSVersion"] = macOSVersion
            properties["USES_MAC_APP"] = true
            properties["day_of_usage"] = getDaysSinceAppInstalled()
            properties["$set"] = [//person properties
                "mode": mode,
                "display_size" : "\(screenFrame.width) * \(screenFrame.height)",
                "day_of_usage" : getDaysSinceAppInstalled(),
                "last-quit-reason": lastQuitReason,
                "STAGE_MANAGER_ENABLED": stageManagerObject.isStageManagerEnabled,
                "USES_FULL_SCREEN_MODE": SettingsManagerObject.isFullScreenEnabled
            ]
            for key in metadata.keys{
                properties[key] = metadata[key]
            }
            
            let goals = UserDefaults.standard.object(forKey: kUserDefaultsCustomGoals) as? String ?? ""
            let howHeardAboutApp = UserDefaults.standard.object(forKey: kUserDefaultsHowHeardAboutApp) as? String ?? ""
            var json: [String: Any] = [
                "api_key": "phc_Y6hD2dvO1zylm7CLij5CuNt6S5gTxe7EVXoxZcb2xUm",
                "event": event,
                "context": [
                    "os": "MacOS",
                    "osVersion": macOSVersion,
                    "appVersion": appVersion
                ],
                "properties": properties,
                "reason-for-using-focus-bear": goals,
                "how-heard-about-focus-bear": howHeardAboutApp,
                "app-version": appVersion
            ]
            
            if isPurchased{
                json["isPayingUser"] = true
            }else{
                json["isPayingUser"] = false
            }
            
            
            if let lastQuitReason = UserDefaults.standard.object(forKey: kUserDefaultsLastQuitReason) as? String{
                json["last-quit-reason"] = lastQuitReason
            }
            
            
            if let occupation = UserDefaults.standard.object(forKey: kUserDefaultsSelectedOccupationForPosthog) as? String{
                json["occupation"] = occupation
            }

            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 200{ //success
                        //   addLog(text: "api call capturePosthog success")
                        print("api call capturePosthog success")
                        return;
                    }else{
                        addLog(text: "api call capturePosthog error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        return
                    }
                }
                if error != nil {
                    addLog(text: "api call capturePosthog error: \(error!.localizedDescription)")
                    return
                }
                
                return
            }
            
            task.resume()
        }else{
            
            return
        }
    }
    
    
    func getSettings(isFirstTime:Bool, packId:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading Settings file user-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                var responsePath = "\(baseUrl)/user-settings?language=\(currentLanguageCode)"
                if isFirstTime{
                    if let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool{
                        if isHabitsDisabled{
                            let focusOnlyPackId = "4a5872f5-a8e5-48c2-a2e3-83c3830fce58"
                            responsePath = "\(baseUrl)/habit-packs/default?pack_id=\(focusOnlyPackId)"
                        }
                    }
                    if !packId.isEmpty{
                        responsePath = "\(baseUrl)/habit-packs/default?pack_id=\(packId)"
                    }
                }
                
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getSettings \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    
                    request.httpMethod = "GET";
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            applastSettingsGetTime = Date()
                                            addLog(text: "api call getSettings success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get Settings file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call get Settings Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error Settings file: \(error!.localizedDescription)")
                            completionHandler(nil)
                            return
                        }
                        completionHandler(nil)
                        return
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getUserLocalDeviceSettings(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading user-local-device-settings file")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user-local-device-settings"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getSettings \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApigetUserLocalDeviceSettingsErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call user-local-device-settings success")
                                            print(jsonResult)
                                            addLog(text: "User Local Device Settings:- \(jsonResult)")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get user-local-device-settings file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call user-local-device-settings Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "error user-local-device-settings file: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApigetUserLocalDeviceSettingsErrorFound{
                                    self.isApigetUserLocalDeviceSettingsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApigetUserLocalDeviceSettingsErrorFound = true
                                    addLog(text: "error ser-local-device-settings file:- try second time")
                                    self.getUserLocalDeviceSettings(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    var isApiGetLastActivityInfoErrorFound = false
    var isApigetUserLocalDeviceSettingsErrorFound = false
    var isApiGetuserDetailsInfoErrorFound = false
    var isApiPutUserLocalDeviceSettingsErrorFound = false
    var isApiActivityCompletedErrorFound = false
    var isApiActivityCompletedReviseErrorFound = false
    var isApiForceCompleteCurrentSequenceErrorFound = false
    var isApiGetActivityStatsErrorFound = false
    var isApiGetActivityCurrentDayStatsErrorFound = false
    var isApiGetAllActivityDaySummaryErrorFound = false
    var isApiGetProjectsErrorFound = false
    var isApiAddFocusModeErrorFound = false
    var isApiUpdateAllFocusModeErrorFound = false
    var isApiDeleteFocusModeErrorFound = false
    var isApiEditFocusModeErrorFound = false
    var isApiStartFocusModeErrorFound = false
    var isApiExtendFocusModeErrorFound = false
    var isApiFinishFocusModeErrorFound = false
    var isApiGetDeviceIdErrorFound = false
    var isApiActivitySkippedErrorFound = false
    var isApiGetFocusTemplateErrorFound = false
    var isApiGetUserSubscriptionErrorFound = false
    var isApiGetHabitPacksErrorFound = false
    var isApiPostTermsServiceErrorFound = false
    var isApigetuserLongTermGoalsErrorFound = false
    var isApiGetFocusModeTagsErrorFound = false
    var isApiGetAllTasksErrorFound = false
    var isApiGetAllBuddiesErrorFound = false
    var isApiGetUnlockRequestStatusErrorFound = false
    var isApiGetAllBlockingSchedulesErrorFound = false
    var isApiAddBlockingScheduleErrorFound = false
    var isApiUnlockRequestErrorFound = false
    var isApiGenerateOccupationRelevantSitesErrorFound = false
    var isApiGetAllFocusModesErrorFound = false
    var isApiGetUserDetailsSummaryErrorFound = false
    
    var isApiUpdateBlockingScheduleErrorFound = false
    var isApiDeleteBlockingScheduleErrorFound = false
    
    var isApiUploadLogsErrorFound = false
    var isApiPostSavedWebsiteErrorFound = false
    var isApiGetSavedWebsiteErrorFound = false
    var isApiDeleteSavedWebsiteErrorFound = false
    
    var isApiAddAdditionalGoalsErrorFound = false
    
    var isApiUnCompleteCurrentSequenceErrorFound = false

    var isApiJoinClassSessionErrorFound = false
    var isApiDeclineClassSessionErrorFound = false
    var isApiGetCurrentClassSessionErrorFound = false
    var isApiRequestClassUnlockErrorFound = false

    var errorCodeRequestTimeout = -1001
    var errorCodeNoInternet = -1009

    /// #2150: the habits the user actually COMPLETED on a past day, so the Day Plan can strike them
    /// through when navigating back. `GET /completed-activity-sequence/routine-progress?date=&timezone=`
    /// returns the same shape as `today_routine_progress` (per-routine `completed_habit_ids` /
    /// `skipped_habit_ids`). Note `completed_habit_ids` includes skipped ones, so we subtract
    /// `skipped_habit_ids` to get strictly-completed. Best-effort — nil on any failure (Day Plan then
    /// falls back to the local per-day cache).
    func fetchDayRoutineProgress(dayKey: String, completion: @escaping (_ completedIds: Set<String>?) -> Void) {
        appdelegate?.credentialsManager.credentials { credentialsInfo in
            appdelegate?.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate?.credential != nil else { DispatchQueue.main.async { completion(nil) }; return }
            let tz = TimeZone.current.identifier
            let path = "\(baseUrl)/completed-activity-sequence/routine-progress?date=\(dayKey)&timezone=\(tz)"
            guard let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = NSURL(string: encoded) else { DispatchQueue.main.async { completion(nil) }; return }
            let request = makeRequest(responsePathUrl: url)
            request.httpMethod = "GET"
            URLSession.shared.dataTask(with: request as URLRequest) { data, response, _ in
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data,
                      let json = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary else {
                    DispatchQueue.main.async { completion(nil) }; return
                }
                // Union strictly-completed ids across every routine in the payload (morning / evening /
                // any custom or standalone), robust to which routine keys are present for the day.
                var completed = Set<String>()
                for value in json.allValues {
                    guard let routine = value as? NSDictionary else { continue }
                    let done = (routine["completed_habit_ids"] as? [String]).map(Set.init) ?? []
                    let skipped = (routine["skipped_habit_ids"] as? [String]).map(Set.init) ?? []
                    completed.formUnion(done.subtracting(skipped))
                }
                DispatchQueue.main.async { completion(completed) }
            }.resume()
        }
    }

    func getLastActivityInfo(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading getLastActivityInfo file")
        
        
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/details/current-activity-props"//
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getLastActivityInfo \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetLastActivityInfoErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call getLastActivityInfo success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getLastActivityInfo file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getLastActivityInfo Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getLastActivityInfo: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetLastActivityInfoErrorFound{
                                    self.isApiGetLastActivityInfoErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetLastActivityInfoErrorFound = true
                                    addLog(text: "error getLastActivityInfo:- try second time")
                                    self.getLastActivityInfo(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getuserDetailsInfo(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading getuserDetailsInfo file")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/details"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getuserDetailsInfo \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetuserDetailsInfoErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call getuserDetailsInfo success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getuserDetailsInfo file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getuserDetailsInfo Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getuserDetailsInfo: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetuserDetailsInfoErrorFound{
                                    self.isApiGetuserDetailsInfoErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetuserDetailsInfoErrorFound = true
                                    addLog(text: "error getuserDetailsInfo:- try second time")
                                    self.getuserDetailsInfo(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getuserDetailsSummary(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- getuserDetailsSummary")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated getuserDetailsSummary from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/details/summary"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getuserDetailsSummary \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetUserDetailsSummaryErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call getuserDetailsSummary success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getuserDetailsSummary file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getuserDetailsSummary Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getuserDetailsSummary: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetUserDetailsSummaryErrorFound{
                                    self.isApiGetUserDetailsSummaryErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetUserDetailsSummaryErrorFound = true
                                    addLog(text: "error getuserDetailsSummary:- try second time")
                                    self.getuserDetailsInfo(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getuserLongTermGoals(completionHandler: @escaping(_ result: [String]?) -> ()) {
        addLog(text: "func call:- getuserLongTermGoals")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/long-term-goals"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getuserLongTermGoals \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApigetuserLongTermGoalsErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: [String] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [String]{
                                            
                                            addLog(text: "api call getuserLongTermGoals success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getuserLongTermGoals: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getuserLongTermGoals Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getuserLongTermGoals: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApigetuserLongTermGoalsErrorFound{
                                    self.isApigetuserLongTermGoalsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApigetuserLongTermGoalsErrorFound = true
                                    addLog(text: "error getuserLongTermGoals:- try second time")
                                    self.getuserLongTermGoals(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getFocusTemplateInfo(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getFocusTemplateInfo")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/focus-mode-template?featured_for_onboarding=true&language=\(currentLanguageCode)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getFocusTemplateInfo \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetFocusTemplateErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            addLog(text: "api call getFocusTemplateInfo success")
                                            print(jsonResult)
                                            focusModeTemplateData = jsonResult
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getFocusTemplateInfo file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getFocusTemplateInfo Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getFocusTemplateInfo: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetFocusTemplateErrorFound{
                                    self.isApiGetFocusTemplateErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetFocusTemplateErrorFound = true
                                    addLog(text: "error getFocusTemplateInfo:- try second time")
                                    self.getFocusTemplateInfo(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getAllFocusModes(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getAllFocusModes")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/focus-modes"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllFocusModes \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetAllFocusModesErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    
                                    
                                    do {
                                        if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            addLog(text: "api call getAllFocusModes success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getAllFocusModes file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getAllFocusModes Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getAllFocusModes: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetAllFocusModesErrorFound{
                                    self.isApiGetAllFocusModesErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetAllFocusModesErrorFound = true
                                    addLog(text: "error getAllFocusModes:- try second time")
                                    self.getAllFocusModes(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getUserSubscriptionInfo(completionHandler: @escaping(_ result: NSDictionary?, _ statusCode:Int?) -> ()) {
        addLog(text: "func call:- getUserSubscriptionInfo")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/user/subscription"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getUserSubscriptionInfo \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetUserSubscriptionErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call getUserSubscriptionInfo success")
                                            print(jsonResult)
                                            
                                            completionHandler(jsonResult, nil)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getUserSubscriptionInfo file: \(error.localizedDescription)")
                                        completionHandler(nil, nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil, nil)
                                return
                            }else{
                                addLog(text: "api call getUserSubscriptionInfo Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil, httpResponse.statusCode)
                                return
                            }
                        }
                        if error != nil {
                            
                            addLog(text: "error getUserSubscriptionInfo: \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetUserSubscriptionErrorFound{
                                    self.isApiGetUserSubscriptionErrorFound = false
                                    completionHandler(nil, nil)
                                    return
                                }else{
                                    self.isApiGetUserSubscriptionErrorFound = true
                                    addLog(text: "error getUserSubscriptionInfo:- try second time")
                                    self.getUserSubscriptionInfo(completionHandler: { json,statusCode  in
                                        completionHandler(nil, nil)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil, nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil, nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil, nil)
                }
            }else{
                completionHandler(nil, nil)
            }
        }
    }
    
    func getHabitPacksInfo(breaks_only:Bool, completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getHabitPacksInfo")
        
        let responsePath = "\(baseUrl)/habit-packs?featured_for_onboarding=true&breaks_only=\(breaks_only)"//&language=\(currentLanguageCode)//
        if let responsePathUrl = NSURL(string: responsePath){
            addLog(text: "api call getHabitPacksInfo \(responsePathUrl)")
            
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "GET";
            request.addValue("mac-os", forHTTPHeaderField: "platform")
            request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.isApiGetHabitPacksErrorFound = false
                    if httpResponse.statusCode == 200{
                        
                        if data != nil{
                            do {
                                if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                    
                                    addLog(text: "api call getHabitPacksInfo success")
                                    print(jsonResult)
                                    //"pack_name"
                                    habitPacksData = jsonResult.sorted{
                                        return $0["pack_name"] as? String ?? "" < $1["pack_name"] as? String ?? ""
                                    }
                                    completionHandler(jsonResult)
                                    return
                                }
                                
                            }catch{
                                print(error)
                                addLog(text: "error get getHabitPacksInfo file: \(error.localizedDescription)")
                                completionHandler(nil)
                                return
                            }
                            
                        }
                        
                        completionHandler(nil)
                        return
                    }else{
                        addLog(text: "api call getHabitPacksInfo Api error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        completionHandler(nil)
                        return
                    }
                }
                if error != nil {
                    
                    addLog(text: "error getHabitPacksInfo: \(error!.localizedDescription)")
                    
                    if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                        if self.isApiGetHabitPacksErrorFound{
                            self.isApiGetHabitPacksErrorFound = false
                            completionHandler(nil)
                            return
                        }else{
                            self.isApiGetHabitPacksErrorFound = true
                            addLog(text: "error getHabitPacksInfo:- try second time")
                            self.getHabitPacksInfo(breaks_only:breaks_only, completionHandler: { json in
                                completionHandler(json)
                                return
                            })
                        }
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }else{
                    completionHandler(nil)
                    return
                }
            }
            task.resume()
        }else{
            completionHandler(nil)
        }
    }
    
    func putUserLocalDeviceSettings(settings:[String: [String:Any]], completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:-  putUserLocalDeviceSettings:- user-local-device-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user-local-device-settings"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call putUserLocalDeviceSettings \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: settings)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiPutUserLocalDeviceSettingsErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            addLog(text: "api call putUserLocalDeviceSettings return success")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call putUserLocalDeviceSettings return error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call putUserLocalDeviceSettings Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "api call putUserLocalDeviceSettings return error:- \(error!.localizedDescription)")
                            
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiPutUserLocalDeviceSettingsErrorFound{
                                    self.isApiPutUserLocalDeviceSettingsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiPutUserLocalDeviceSettingsErrorFound = true
                                    addLog(text: "error putUserLocalDeviceSettings:- try second time")
                                    self.putUserLocalDeviceSettings(settings: settings, completionHandler: {dic  in
                                        completionHandler(dic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            completionHandler(nil)
                            return
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    var completedActivityLogId:String?
    var completedChoiceLogId:String?
    //    var isAnyErrorFoundInActivityCompletedApi = false
    func activityCompletedApi(activity_id:String, activity_sequence_id:String, start_time:Date, quantity_logged:Double?, duration_logged:Int, choice_id:String?, is_skipped:Bool, notes:String, should_not_update_current_activity:Bool, log_quantity_answers:[[String:Any]], completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        if activity_id.isEmpty && activity_sequence_id.isEmpty{// custom special activity which is not in morning , evening or breaks
            completionHandler(nil);
            return;
        }
        addLog(text: "func call:- activityCompletedApi completed-activity")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            self.completedActivityLogId = nil
            self.completedChoiceLogId = nil
            
            let calendar = Calendar.current
            var finish_time = calendar.date(byAdding: .second, value: duration_logged, to: start_time) ?? Date()
            
            if is_skipped{
                finish_time = calendar.date(byAdding: .second, value: 1, to: start_time) ?? Date()
            }
            
            let start_time_string = getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            
            let finish_time_string = getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            
            let responsePath = "\(baseUrl)/completed-activity"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call activityCompletedApi \(responsePathUrl) for activityId: \(activity_id), choice_id: \(choice_id ?? "")")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                var json: [String: Any] = [
                    "activity_id":activity_id,
                    "duration_logged":duration_logged,
                    "device_id":currentDeviceId,
                    "activity_sequence_id":activity_sequence_id,
                    "start_time": start_time_string,
                    "finish_time": finish_time_string,
                    "metadata": [:]
                ]
                
                if is_skipped{
                    let dic:[String:Any] = ["skipped_did_complete": true]
                    json["metadata"] = dic
                }
                
                if !notes.isEmpty{
                    json["note_logged"] = notes
                }
                
                if choice_id != nil{
                    json["choice_id"] = choice_id!
                }
                
                //                if quantity_logged != nil{
                //                    json["quantity_logged"] = quantity_logged!//
                //                }
                
                if log_quantity_answers.count != 0{
                    json["log_quantity_answers"] = log_quantity_answers
                }
                
                if should_not_update_current_activity{
                    json["should_not_update_current_activity"] = should_not_update_current_activity
                }
                
                print("*****************json for activity************")
                print(json)
                print("**********************************************")
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiActivityCompletedErrorFound = false
                        if httpResponse.statusCode == 201{
                            
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        addLog(text: "api call activityCompletedApi success")
                                        print("*************** Activity completed response****************")
                                        print(jsonResult)
                                        print("***********************************************************")
                                        if let completedActivityLog = jsonResult.value(forKey: "completed_activity_log") as? NSDictionary{
                                            if let id = completedActivityLog.value(forKey: "id") as? String{
                                                self.completedActivityLogId = id
                                            }
                                        }
                                        if let completedChoiceLog = jsonResult.value(forKey: "completed_choice_log") as? NSDictionary{
                                            if let id = completedChoiceLog.value(forKey: "id") as? String{
                                                self.completedChoiceLogId = id
                                            }
                                        }
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call activityCompletedApi error:- \(error.localizedDescription)")
                                    print(error)
                                    completionHandler(nil)
                                    return
                                }
                            }
                        }else{
                            addLog(text: "api call activityCompletedApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            
                            
                            if httpResponse.statusCode == 500{
                                var quantity_logged_string = ""
                                if quantity_logged != nil{
                                    quantity_logged_string = "\(quantity_logged!)"
                                }
                                var skipped_did_complete = ""
                                if is_skipped{
                                    skipped_did_complete = "true"
                                }
                                
                                addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "\(duration_logged)", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: skipped_did_complete, choice_id: choice_id ?? "", quantity_logged: quantity_logged_string, skipped_did_not_complete: "", note_logged: notes)
                            }
                            
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        
                        var quantity_logged_string = ""
                        if quantity_logged != nil{
                            quantity_logged_string = "\(quantity_logged!)"
                        }
                        var skipped_did_complete = ""
                        if is_skipped{
                            skipped_did_complete = "true"
                        }
                        
                        addLog(text: "api call activityCompletedApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiActivityCompletedErrorFound{
                                self.isApiActivityCompletedErrorFound = false
                                
                                DispatchQueue.main.async {
                                    var activitiesSyncErrorText = "Focus Bear was not able to sync the activities' statistics due to bad internet."
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        activitiesSyncErrorText = common.value(forKey: "activitiesSyncErrorText") as? String ?? activitiesSyncErrorText
                                    }
                                    showCustomNotificationView(msg: activitiesSyncErrorText)
                                }
                                
                                
                                addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "\(duration_logged)", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: skipped_did_complete, choice_id: choice_id ?? "", quantity_logged: quantity_logged_string, skipped_did_not_complete: "", note_logged: notes)
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiActivityCompletedErrorFound = true
                                addLog(text: "error activityCompletedApi:- try second time")
                                
                                self.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, is_skipped: is_skipped, notes: notes, should_not_update_current_activity: should_not_update_current_activity, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
                                    
                                    completionHandler(dic)
                                    return
                                })
                            }
                        }else if (error as? NSError)?.code == self.errorCodeNoInternet{
                            //                            self.isAnyErrorFoundInActivityCompletedApi = true
                            
                            DispatchQueue.main.async {
                                var activitiesSyncErrorText = "Focus Bear was not able to sync the activities' statistics due to bad internet."
                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                    activitiesSyncErrorText = common.value(forKey: "activitiesSyncErrorText") as? String ?? activitiesSyncErrorText
                                }
                                showCustomNotificationView(msg: activitiesSyncErrorText)
                            }
                            addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "\(duration_logged)", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: skipped_did_complete, choice_id: choice_id ?? "", quantity_logged: quantity_logged_string, skipped_did_not_complete: "", note_logged: notes)
                            completionHandler(nil)//The Internet connection appears to be offline.
                            return
                        }else{//1009
                            
                            addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "\(duration_logged)", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: skipped_did_complete, choice_id: choice_id ?? "", quantity_logged: quantity_logged_string, skipped_did_not_complete: "", note_logged: notes)
                            completionHandler(nil)
                            return
                        }
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func activityCompletedReviseApi(activity_id:String, quantity_logged:Double , choice_id:String?, log_quantity_answers:[[String:Any]], completionHandler: @escaping(_ result: NSDictionary?) -> ()){//
        addLog(text: "func call:- activityCompletedReviseApi:- completed-activity/revise/id")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            let id = choice_id ?? activity_id
            
            let responsePath = "\(baseUrl)/completed-activity/revise/\(id)"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call activity Completed Revise Api \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "PATCH";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let json: [String: Any] = [
                    "quantity_logged":0,// need to send  quantity_logged 0
                    "log_quantity_answers":log_quantity_answers
                ]
                
                
                
                print("*****************json for activity************")
                print(json)
                print("**********************************************")
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiActivityCompletedReviseErrorFound = false
                        if httpResponse.statusCode == 200{
                            addLog(text: "api call activity Completed Revise Api success")
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        print("*************** Activity completed response****************")
                                        print(jsonResult)
                                        print("***********************************************************")
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call activity Completed Revise Api error:- \(error.localizedDescription)")
                                    completionHandler(nil)
                                    return
                                }
                            }
                        }else{
                            addLog(text: "api call activity Completed Revise Api error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    if error != nil {
                        addLog(text: "api call activity Completed Revise Api error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiActivityCompletedReviseErrorFound{
                                self.isApiActivityCompletedReviseErrorFound = false
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiActivityCompletedReviseErrorFound = true
                                addLog(text: "error activity Completed Revise Api:- try second time")
                                
                                allApiObject.activityCompletedReviseApi(activity_id: activity_id, quantity_logged:quantity_logged, choice_id: choice_id, log_quantity_answers: log_quantity_answers, completionHandler: {dic  in
                                    completionHandler(dic)
                                    return
                                    
                                })
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func activitySkippedApi(activity_id:String, activity_sequence_id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- activitySkippedApi completed-activity")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            let responsePath = "\(baseUrl)/completed-activity/skip"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call activitySkippedApi \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let json: [String: Any] = [
                    "activity_id":activity_id,//userId.removingPercentEncoding ?? "",
                    "device_id":currentDeviceId,
                    "activity_sequence_id":activity_sequence_id,
                ]
                
                print("*****************json for activity************")
                print(json)
                print("**********************************************")
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiActivitySkippedErrorFound = false
                        if httpResponse.statusCode == 201{
                            addLog(text: "api call activitySkippedApi success")
                            completionHandler(nil)
                            return
                            
                        }else{
                            addLog(text: "api call activitySkippedApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            
                            if httpResponse.statusCode == 500{
                                let calendar = Calendar.current
                                let start_time = Date()
                                let finish_time = calendar.date(byAdding: .second, value: 1, to: start_time) ?? Date()
                                
                                let start_time_string = getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                
                                let finish_time_string = getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                
                                addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: "", choice_id: "", quantity_logged: "", skipped_did_not_complete: "true", note_logged: "")
                            }
                            
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        addLog(text: "api call activitySkippedApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiActivitySkippedErrorFound{
                                self.isApiActivitySkippedErrorFound = false
                                
                                let calendar = Calendar.current
                                let start_time = Date()
                                let finish_time = calendar.date(byAdding: .second, value: 1, to: start_time) ?? Date()
                                
                                let start_time_string = getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                
                                let finish_time_string = getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                                
                                addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: "", choice_id: "", quantity_logged: "", skipped_did_not_complete: "true", note_logged: "")
                                
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiActivitySkippedErrorFound = true
                                addLog(text: "error activitySkippedApi:- try second time")
                                
                                self.activitySkippedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, completionHandler: {dic  in
                                    
                                    completionHandler(dic)
                                    return
                                })
                            }
                        }else{
                            let calendar = Calendar.current
                            let start_time = Date()
                            let finish_time = calendar.date(byAdding: .second, value: 1, to: start_time) ?? Date()
                            
                            let start_time_string = getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                            
                            let finish_time_string = getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                            
                            addEntryInofflineActivitiesCsv(activity_id: activity_id, duration_logged: "", device_id: currentDeviceId, activity_sequence_id: activity_sequence_id, start_time: start_time_string, finish_time: finish_time_string, skipped_did_complete: "", choice_id: "", quantity_logged: "", skipped_did_not_complete: "true", note_logged: "")
                            completionHandler(nil)
                            return
                        }
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func syncOfflineDataApi(offineData: [[String : Any]], completionHandler: @escaping(_ result: [NSDictionary]?) -> ()){
        addLog(text: "func call:- activity sync Api completed-activity")
        
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            let responsePath = "\(baseUrl)/completed-activity/sync"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call activitysyncApi \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let json: [String: Any] = [
                    "completed_activites":offineData//userId.removingPercentEncoding ?? "",
                ]
                
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 201{
                            addLog(text: "api call activitysyncApi success")
                            
                            if data != nil{
                                do {
                                    if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                        addLog(text: "api call activitysyncApi success")
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call activitysyncApi error:- \(error.localizedDescription)")
                                    print(error)
                                    completionHandler(nil)
                                    return
                                }
                            }else{
                                addLog(text: "api call activitysyncApi error:- data is nil")
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            addLog(text: "api call activitysyncApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            //Deon asked that if the request fails with a 400 error, we should not try again
                             //So we will return json here so that the entries are removed from the offline csv file
                            if (httpResponse.statusCode != 408 && (httpResponse.statusCode >= 400 && httpResponse.statusCode <= 426 )){
                                let jsonResult: [NSDictionary]  = []
                                completionHandler(jsonResult)
                            }else{
                                completionHandler(nil)
                            }
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        addLog(text: "api call activitySyncApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            completionHandler(nil)
                            return
                        }else{
                            
                            completionHandler(nil)
                            return
                        }
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func forceCompleteCurrentSequence(activity_sequence_id:String, isForToday:Bool, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- forceCompleteCurrentSequence:- completed-activity-sequence/activity_sequence_id/force-complete-current-sequence")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            var responsePath = "\(baseUrl)/completed-activity-sequence/\(activity_sequence_id)/force-complete-current-sequence"
            if isForToday == true{
                responsePath += "?cancel_habits_for_today=true"
            }
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call forceCompleteCurrentSequence \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let json: [String: Any] = [:]
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiForceCompleteCurrentSequenceErrorFound = false
                        if httpResponse.statusCode == 201{
                            addLog(text: "api call forceCompleteCurrentSequence success")
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        addLog(text: "api call forceCompleteCurrentSequence success")
                                        print("*************** Activity forceCompleteCurrentSequence response****************")
                                        print(jsonResult)
                                        print("***********************************************************")
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call forceCompleteCurrentSequence error:- \(error.localizedDescription)")
                                    print(error)
                                    completionHandler(nil)
                                    return
                                }
                            }
                        }else{
                            addLog(text: "api call forceCompleteCurrentSequence error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    
                    
                    if error != nil {
                        addLog(text: "api call forceCompleteCurrentSequence error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiForceCompleteCurrentSequenceErrorFound{
                                self.isApiForceCompleteCurrentSequenceErrorFound = false
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiForceCompleteCurrentSequenceErrorFound = true
                                addLog(text: "error forceCompleteCurrentSequence:- try second time")
                                self.getLastActivityInfo(completionHandler: { json in
                                    completionHandler(json)
                                    return
                                })
                                
                                self.forceCompleteCurrentSequence(activity_sequence_id: activity_sequence_id, isForToday: isForToday, completionHandler: {json in
                                    
                                    completionHandler(json)
                                    return
                                })
                                
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func uncompleteCurrentSequence(activity_sequence_id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- uncompleteCurrentSequence:- completed-activity-sequence/activity_sequence_id/force-complete-current-sequence")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            let responsePath = "\(baseUrl)/completed-activity-sequence/\(activity_sequence_id)/uncomplete"

            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call uncompleteCurrentSequence \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let json: [String: Any] = [:]
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiUnCompleteCurrentSequenceErrorFound = false
                        if httpResponse.statusCode == 201{
                            addLog(text: "api call uncompleteCurrentSequence success")
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        addLog(text: "api call uncompleteCurrentSequence success")
                                        print(jsonResult)
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call uncompleteCurrentSequence error:- \(error.localizedDescription)")
                                    print(error)
                                    completionHandler(nil)
                                    return
                                }
                            }
                        }else{
                            addLog(text: "api call uncompleteCurrentSequence error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    
                    
                    if error != nil {
                        addLog(text: "api call uncompleteCurrentSequence error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiUnCompleteCurrentSequenceErrorFound{
                                self.isApiUnCompleteCurrentSequenceErrorFound = false
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiUnCompleteCurrentSequenceErrorFound = true
                                addLog(text: "error uncompleteCurrentSequence:- try second time")
                                self.getLastActivityInfo(completionHandler: { json in
                                    completionHandler(json)
                                    return
                                })
                                
                                self.uncompleteCurrentSequence(activity_sequence_id: activity_sequence_id, completionHandler: {json in
                                    
                                    completionHandler(json)
                                    return
                                })
                                
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getAllTracks(completionHandler: @escaping(_ stats:[NSDictionary]?) -> ()){
        addLog(text: "func call:- getAllTracks")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/tracks"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllTracks \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 200{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            print(jsonResult)
                                            addLog(text: "api call getAllTracks success")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getAllTracks error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getAllTracks error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call getAllTracks error:- \(error!.localizedDescription)")
                            completionHandler(nil)
                            return
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getAllTracks error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
        
    }
    
    func getACtivityStats(activityId:String, activityChoiceId:String?, completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getACtivityStats:- completed-activity/id/stats")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let id = activityChoiceId ?? activityId
                
                let zone = TimeZone.current
                let responsePath = "\(baseUrl)/completed-activity/\(id)/stats?days_number=30&timezone=\(zone.identifier)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getActivityStats \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetActivityStatsErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            print(jsonResult)
                                            addLog(text: "api call getActivityStats success")
                                            graphOneMonthData = jsonResult//.mutableCopy() as? NSMutableDictionary
                                            
                                            //                                            addGraphsLog(text: "Monthly Stats:-\(jsonResult)")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getActivityStats error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getActivityStats error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        
                        
                        
                        if error != nil {
                            addLog(text: "api call getActivityStats error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetActivityStatsErrorFound{
                                    self.isApiGetActivityStatsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetActivityStatsErrorFound = true
                                    addLog(text: "error getActivityStats:- try second time")
                                    
                                    allApiObject.getACtivityStats(activityId: activityId, activityChoiceId: activityChoiceId, completionHandler: {dic in
                                        completionHandler(dic)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getActivityStats error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getACtivityCurrentDayStats(activityId:String, activityChoiceId:String?, completionHandler: @escaping(_ stats:[NSDictionary]?) -> ()){
        addLog(text: "func call:- getActivityCurrentDayStats:- Completed-activity")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let id = activityChoiceId ?? activityId
                
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                var shutOffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                if shutOffDate < startDate{
                    shutOffDate = Calendar.current.date(byAdding: .hour, value: 24, to: shutOffDate) ?? shutOffDate
                }
                let currentDate = Date()
                if currentDate.compare(shutOffDate) == .orderedDescending{//>
                    shutOffDate = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate
                }
                
                
                let fromTime = getStringFromDateInUtc(date: startDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                let toTime = getStringFromDateInUtc(date: shutOffDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                
                
                let responsePath = "\(baseUrl)/completed-activity/\(id)?from_time=\(fromTime)&to_time=\(toTime)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getACtivityCurrentDayStats \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetActivityCurrentDayStatsErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            print(jsonResult)
                                            addLog(text: "api call getACtivityCurrentDayStats success")
                                            graphOneDayData = jsonResult//
                                            //                                            addGraphsLog(text: "Current Day Stats:-\(jsonResult)")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getACtivityCurrentDayStats error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getACtivityCurrentDayStats error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call getACtivityCurrentDayStats error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetActivityCurrentDayStatsErrorFound{
                                    self.isApiGetActivityCurrentDayStatsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetActivityCurrentDayStatsErrorFound = true
                                    addLog(text: "error getACtivityCurrentDayStats:- try second time")
                                    self.getACtivityCurrentDayStats(activityId: activityId, activityChoiceId: activityChoiceId, completionHandler: {dic in
                                        completionHandler(dic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getACtivityCurrentDayStats error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getActivityCurrentDayQuestionsStats(activityId:String, activityChoiceId:String?, questions_ids:[String], completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getActivityCurrentDayQuestionsStats:- Completed-activity")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                //let id = activityChoiceId ?? activityId
                
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                var shutOffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                let currentDate = Date()
                if currentDate.compare(shutOffDate) == .orderedDescending{//>
                    shutOffDate = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate
                }
                
                
                let fromTime = getStringFromDateInUtc(date: startDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                let toTime = getStringFromDateInUtc(date: shutOffDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                
                
                let responsePath = "\(baseUrl)/completed-activity/answer-logs?from_time=\(fromTime)&to_time=\(toTime)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getActivityCurrentDayQuestionsStats \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "question_ids": questions_ids
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetActivityCurrentDayStatsErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            print(jsonResult)
                                            addLog(text: "api call getACtivityCurrentDayStats success")
                                            graphOneDayDataForQuantity = jsonResult//
                                            //                                            addGraphsLog(text: "Current Day Stats:-\(jsonResult)")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getActivityCurrentDayQuestionsStats error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getActivityCurrentDayQuestionsStats error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call getActivityCurrentDayQuestionsStats error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetActivityCurrentDayStatsErrorFound{
                                    self.isApiGetActivityCurrentDayStatsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetActivityCurrentDayStatsErrorFound = true
                                    addLog(text: "error getActivityCurrentDayQuestionsStats:- try second time")
                                    self.getActivityCurrentDayQuestionsStats(activityId: activityId, activityChoiceId: activityChoiceId, questions_ids: questions_ids, completionHandler: {dic in
                                        completionHandler(dic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getActivityCurrentDayQuestionsStats error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getAllActivityDaySummary(completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getAllActivityDaySummary:- completed-activity/day-summary")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let zone = TimeZone.current
                let responsePath = "\(baseUrl)/completed-activity/day-summary?timezone=\(zone.identifier)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllActivityDaySummary \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetAllActivityDaySummaryErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            print(jsonResult)
                                            addLog(text: "api call getAllActivityDaySummary success")
                                            allActivityTodaySummaryData = jsonResult
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getAllActivityDaySummary error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getAllActivityDaySummary error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        
                        
                        //isApiGetAllActivityDaySummaryErrorFound
                        
                        
                        if error != nil {
                            addLog(text: "api call getAllActivityDaySummary error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetAllActivityDaySummaryErrorFound{
                                    self.isApiGetAllActivityDaySummaryErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetAllActivityDaySummaryErrorFound = true
                                    addLog(text: "error getAllActivityDaySummary:- try second time")
                                    self.getAllActivityDaySummary(completionHandler: {dic in
                                        completionHandler(dic)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getAllActivityDaySummary error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }

    
    func addFocusMode(focusType:[String:Any],completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- addFocusMode:- focus-mode")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/focus-mode"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call addFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    var json: [String: Any] = [
                        "id":focusType["id"] as? String ?? "",
                        "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
                        "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
                        "name":focusType["name"] as? String ?? "",
                        "tags":focusType["tags"] as? [String] ?? [],
                        "metadata": [:]
                    ]
                    
                    var dic = focusType
                    dic.removeValue(forKey: "doNotSuggestAnyMore")// no need to sync Auto suggest focus mode key
                    
                    dic.removeValue(forKey: "name")
                    dic.removeValue(forKey: "id")
                    dic.removeValue(forKey: "allowed_urls")
                    dic.removeValue(forKey: "allowed_apps")
                    dic.removeValue(forKey: "tags")
                    json["metadata"] = dic
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiAddFocusModeErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            addLog(text: "api call addFocusMode success")
                                            completionHandler(true)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call addFocusMode error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(false)
                                        return
                                    }
                                }
                            }else{
                                addLog(text: "api call addFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call addFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiAddFocusModeErrorFound{
                                    self.isApiAddFocusModeErrorFound = false
                                    completionHandler(false)
                                    return
                                }else{
                                    self.isApiAddFocusModeErrorFound = true
                                    addLog(text: "error addFocusMode:- try second time")
                                    self.addFocusMode(focusType: focusType, completionHandler: {result in
                                        completionHandler(result)
                                        return;
                                    })
                                    return;
                                }
                            }else{
                                completionHandler(false)
                                return
                            }
                            
                        }else{
                            completionHandler(false)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                }
                
            }
        }
    }
    func deleteFocusMode(id:String, completionHandler: @escaping(_ isDeleted:Bool) -> ()){
        addLog(text: "func call:- deleteFocusMode :- focus-mode")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/focus-mode?id=\(id)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call deleteFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "DELETE";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiDeleteFocusModeErrorFound = false
                            if httpResponse.statusCode == 204{ //it means it is right
                                addLog(text: "api call deleteFocusMode success")
                                completionHandler(true)
                                return
                                
                            }else{
                                addLog(text: "api call deleteFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call deleteFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiDeleteFocusModeErrorFound{
                                    self.isApiDeleteFocusModeErrorFound = false
                                    completionHandler(false)
                                    return
                                }else{
                                    self.isApiDeleteFocusModeErrorFound = true
                                    addLog(text: "error deleteFocusMode:- try second time")
                                    self.deleteFocusMode(id: id, completionHandler: {isDeleted in
                                        completionHandler(isDeleted)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(false)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(false)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                    return
                }
            }else{
                completionHandler(false)
            }
        }
    }
    
    func editFocusMode(focusType:[String:Any], completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        if focusType["isLockedFocus"] as? Bool == true{
            completionHandler(nil)
            return
        }
        addLog(text: "func call:-  editFocusMode:- focus-mode")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/focus-mode/\(focusType["id"] as? String ?? "")"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call editFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PATCH";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var json: [String: Any] = [
                        "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
                        "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
                        "name":focusType["name"] as? String ?? "",
                        "metadata": [:]
                    ]
                    var tagsDic = [[String:Any]]()
                    if let tags = focusType["tags"] as? [String]{
                        for tag in tags{
                            tagsDic.append(["id": getIdForTag(tag: tag), "text": tag])
                        }
                    }
                    json["tags"] = tagsDic
                    var dic = focusType
                    
                    dic.removeValue(forKey: "doNotSuggestAnyMore")// no need to sync Auto suggest focus mode key
                    
                    dic.removeValue(forKey: "name")
                    dic.removeValue(forKey: "id")
                    dic.removeValue(forKey: "allowed_urls")
                    dic.removeValue(forKey: "allowed_apps")
                    dic.removeValue(forKey: "tags")
                    json["metadata"] = dic
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiEditFocusModeErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            addLog(text: "api call editFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call editFocusMode error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call editFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call editFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiEditFocusModeErrorFound{
                                    self.isApiEditFocusModeErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiEditFocusModeErrorFound = true
                                    addLog(text: "error editFocusMode:- try second time")
                                    self.editFocusMode(focusType: focusType, completionHandler: {newDic in
                                        completionHandler(newDic)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    
    func updateAllFocusMode(focusModes:[[String:Any]], completionHandler: @escaping(_ newDic:[NSDictionary]?) -> ()){
        addLog(text: "func call:- updateAllFocusMode:- focus-mode")
        
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/focus-mode"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call updateAllFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: focusModes)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiUpdateAllFocusModeErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            addLog(text: "api call updateAllFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call updateAllFocusMode error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call updateAllFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call updateAllFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiUpdateAllFocusModeErrorFound{
                                    self.isApiUpdateAllFocusModeErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiUpdateAllFocusModeErrorFound = true
                                    addLog(text: "error updateAllFocusMode:- try second time")
                                    
                                    self.updateAllFocusMode(focusModes:focusModes, completionHandler: {newDic in
                                        completionHandler(newDic)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func startFocusMode(id:String,intention:String, start_time:Date, finish_time:Date, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:- startFocusMode:- focus-mode/id/start")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/focus-mode/\(id)/start"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call startFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var to_dos:[[String: Any]] = []
                    if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
                        do {
                            let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                            print(jsonResult)
                            to_dos = jsonResult
                        }catch{
                            print(error)
                        }
                    }
                    
                    let json: [String: Any] = [
                        "intention":intention,
                        "finish_time":getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                        "start_time":getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                        "to_dos":to_dos
                    ]
                    
                    
                    
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            //it means it is right
                            self.isApiStartFocusModeErrorFound = false
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                        // if let id = jsonResult.value(forKey: "id") as? String{
                                        
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call startFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }else{
                                            addLog(text: "api call startFocusMode Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            if httpResponse.statusCode == 400{//it means may be a focus mode is already running so complete it
                                                finishOldFocusModeIfRunning(startNewFocusId: id, intention: intention, start_time: start_time, finish_time: finish_time)
                                            }
                                            completionHandler(nil)
                                            return
                                        }
                                        
                                        
                                        //  }
                                        
                                    }
                                    
                                }catch{
                                    addLog(text: "api call startFocusMode error:- \(error.localizedDescription)")
                                    completionHandler(nil)
                                    print(error)
                                    return;
                                }
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call startFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiStartFocusModeErrorFound{
                                    self.isApiStartFocusModeErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiStartFocusModeErrorFound = true
                                    addLog(text: "error startFocusMode:- try second time")
                                    
                                    self.startFocusMode(id: id, intention: intention, start_time: start_time, finish_time: finish_time, completionHandler: {newDic in
                                        completionHandler(newDic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    
    func finishFocusMode(id:String,achievements:String, distractions:String, finish_time:Date, rating:Int?, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:-  finishFocusMode:- focus-mode/id/finish")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/focus-mode/\(id)/finish"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call finishFocusMode \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var to_dos:[[String: Any]] = []
                    if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
                        do {
                            let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                            print(jsonResult)
                            to_dos = jsonResult
                        }catch{
                            print(error)
                        }
                    }
                    var achievements = achievements.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? achievements
                    if achievements.count > 250{// api was not accepting more than 255 charcters so i truncate to 254 characters
                        let index = achievements.index(achievements.startIndex, offsetBy: 250)
                        achievements = String(achievements.prefix(upTo: index))
                    }
                    
                    
                    var json: [String: Any] = [
                        "achievements": achievements,
                        "distractions": distractions,
                        "finish_time": getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                        "focus_duration_seconds": focusModeActualDurationPerformed,
                        "to_dos":to_dos
                    ]
                    
                    var metadata = [String : Any]()
                    if let rating = rating{
                        metadata["focus_stars"] = rating
                    }
                    if SettingsManagerObject.isAiCheckUrlEnabled{
                        metadata["focus_alignment_score"] = "\(currentFocusAlignmentScore)"
                    }
                    json["metadata"] = metadata
                    
                    focusModeTaskString = ""
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            //it means it is right
                            self.isApiFinishFocusModeErrorFound = false
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                        // if let id = jsonResult.value(forKey: "id") as? String{
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call finishFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }else{
                                            addLog(text: "api call finishFocusMode Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            completionHandler(nil)
                                            return
                                        }
                                        
                                        
                                        //  }
                                        
                                    }
                                    
                                }catch{
                                    completionHandler(nil)
                                    addLog(text: "api call finishFocusMode error:- \(error.localizedDescription)")
                                    print(error)
                                    return;
                                }
                            }
                            //                        }else{
                            //                            completionHandler(nil)
                            //                            return
                            //                        }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call finishFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiFinishFocusModeErrorFound{
                                    self.isApiFinishFocusModeErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiFinishFocusModeErrorFound = true
                                    addLog(text: "error finishFocusMode:- try second time")
                                    
                                    allApiObject.finishFocusMode(id: id, achievements: achievements, distractions: distractions, finish_time: finish_time, rating:rating, completionHandler: {newDic in
                                        completionHandler(newDic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    
    func extendFocusMode(id:String, finish_time:Date, completionHandler: @escaping(_ result: NSDictionary?) -> ()){//v 2.28.439
        addLog(text: "func call:- extendFocusMode:- update_scheduled_finish")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            let responsePath = "\(baseUrl)/focus-mode/\(id)/update_scheduled_finish"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call extendFocusMode Api \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "PATCH";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let json: [String: Any] = [
                    "scheduled_finish_time":getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                ]
                
                
                
                print("*****************json for activity************")
                print(json)
                print("**********************************************")
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiExtendFocusModeErrorFound = false
                        if httpResponse.statusCode == 200{
                            addLog(text: "api call extendFocusMode Api success")
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        print("*************** Activity completed response****************")
                                        print(jsonResult)
                                        print("***********************************************************")
                                        completionHandler(jsonResult)
                                        return
                                    }
                                    
                                }catch{
                                    addLog(text: "api call extendFocusMode error:- \(error.localizedDescription)")
                                    completionHandler(nil)
                                    return
                                }
                            }
                        }else{
                            addLog(text: "api call extendFocusMode Api error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    if error != nil {
                        addLog(text: "api call extendFocusMode Api error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiExtendFocusModeErrorFound{
                                self.isApiExtendFocusModeErrorFound = false
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiExtendFocusModeErrorFound = true
                                addLog(text: "error activity extendFocusMode Api:- try second time")
                                
                                allApiObject.extendFocusMode(id: id, finish_time:finish_time, completionHandler: {dic  in
                                    completionHandler(dic)
                                    return
                                    
                                })
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }

    /// POST focus-mode/{id}/pause — tells the backend the session was paused here, so it broadcasts
    /// `focus-mode-paused` to the user's other devices (FOCUS_SESSION_SYNC.md §6). Until this existed a
    /// desktop pause was a purely local flag, so nothing else could ever learn about it.
    func pauseFocusMode(id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        postFocusModeLifecycleAction(id: id, action: "pause", completionHandler: completionHandler)
    }

    /// POST focus-mode/{id}/resume — the resume counterpart of pauseFocusMode.
    func resumeFocusMode(id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        postFocusModeLifecycleAction(id: id, action: "resume", completionHandler: completionHandler)
    }

    /// Shared body for the pause/resume endpoints — they differ only by path segment. The `device_id`
    /// header that makeRequest already attaches is what lets this Mac ignore the echo of its own change
    /// when the backend broadcasts it back over Pusher.
    private func postFocusModeLifecycleAction(id:String, action:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- focus mode \(action):- focus-mode/id/\(action)")
        guard !id.isEmpty else {
            addLog(text: "focus mode \(action):- no focus mode id, skipping")
            completionHandler(nil)
            return
        }

        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            let responsePath = "\(baseUrl)/focus-mode/\(id)/\(action)"
            guard let responsePathUrl = NSURL(string: responsePath) else {
                completionHandler(nil)
                return
            }
            addLog(text: "api call focus mode \(action) Api \(responsePathUrl)")

            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // These endpoints take no parameters, but the API rejects an absent body when the
            // content-type says JSON ("Body cannot be empty when content-type is set to
            // 'application/json'"), so send an empty object rather than nothing.
            request.httpBody = try? JSONSerialization.data(withJSONObject: [String: Any]())

            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if let error = error {
                    // Deliberately no retry: pause/resume is time-sensitive, and a late retry could
                    // land after the user already toggled back. The local state stays applied and the
                    // next current-activity-props reconcile corrects the server view.
                    addLog(text: "api call focus mode \(action) Api error:- \(error.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    completionHandler(nil)
                    return
                }
                guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    addLog(text: "api call focus mode \(action) Api error:- statusCode is \(httpResponse.statusCode)")
                    self.writeJsonInLog(data: data)
                    completionHandler(nil)
                    return
                }
                addLog(text: "api call focus mode \(action) Api success")
                if let data = data,
                   let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary {
                    completionHandler(jsonResult)
                } else {
                    completionHandler(nil)
                }
            }
            task.resume()
        }
    }

    func getForgotPassword(emailAddress:String,completionHandler: @escaping(_ result: String?) -> ()) {
        addLog(text: "func call:- getForgotPassword")//
        let jsonResult:NSMutableDictionary = ["client_id":"dgMrlNC5mM634Sxi9SLqIqi0WvgVpwX7", "email":emailAddress, "connection":"Username-Password-Authentication"]
        
        let responsePath = "https://dev-2hidr8ad.us.auth0.com/dbconnections/change_password"
        if let responsePathUrl = NSURL(string: responsePath){
            
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "POST";
            
            let json = jsonResult//[[String: String]]()
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                // print(response)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200{
                        
                        if data != nil{
                            addLog(text: "getForgotPassword - success")
                            let status = String(data: data!, encoding: .utf8)!
                            completionHandler(status)
                        }
                    }else{
                        addLog(text: "error in getForgotPassword response - data nil:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                    }
                    
                }
                
                if error != nil {
                    addLog(text: "getForgotPassword response - error - \(error!.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                completionHandler(nil)
                return;
            }
            task.resume()
        }else{
            //        isUploadingPopupResponse = false
            completionHandler(nil)
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func downloadFileAsync(url: URL?,destinationUrl: URL, completion: @escaping (String?, Error?) -> Void)
    {
        
        
        //let documentsUrl =  FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        
        if FileManager().fileExists(atPath: destinationUrl.path) || url == nil
        {
            completion(destinationUrl.path, nil)
        }
        else
        {
            //            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url!)
            
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) {//let task = session.dataTask(with: request, completionHandler:{
                data, response, error in
                if error == nil
                {
                    if let response = response as? HTTPURLResponse
                    {
                        //                        if response.statusCode == 200
                        //                        {
                        if let data = data
                        {
                            if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                            {
                                completion(destinationUrl.path, error)
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                        else
                        {
                            completion(destinationUrl.path, error)
                        }
                        //                        }else{
                        //                            completion(destinationUrl.path, "error")
                        //                        }
                    }
                }
                else
                {
                    completion(destinationUrl.path, error)
                }
            }//)
            task.resume()
        }
    }
    
    func downloadBlockPageAsync(url: URL?,destinationUrl: URL, completion: @escaping (String?, Error?) -> Void){
        
        //            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        
        if url == nil
        {
            completion(destinationUrl.path, nil)
        }
        
        var request = URLRequest(url: url!)
        
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) {//let task = session.dataTask(with: request, completionHandler:{
            data, response, error in
            if error == nil
            {
                if let response = response as? HTTPURLResponse
                {
                    if response.statusCode == 200
                    {
                        if let data = data
                        {
                            
                            if FileManager.default.fileExists(atPath: destinationUrl.path){
                                do{
                                    try FileManager.default.removeItem(atPath: destinationUrl.path)
                                }catch{
                                    print(error)
                                }
                            }//
                            
                            if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                            {
                                completion(destinationUrl.path, error)
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                        else
                        {
                            completion(destinationUrl.path, error)
                        }
                    }else{
                        completion(destinationUrl.path, nil)
                    }
                }
            }
            else
            {
                completion(destinationUrl.path, error)
            }
        }//)
        task.resume()
        
    }
    
    func isInternetOn(completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- api isInternetOn")
        
        
        let responsePath = "\(baseUrl)/api"
        if let responsePathUrl = NSURL(string: responsePath){
            addLog(text: "api call isInternetOn \(responsePathUrl)")
            
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "GET";
            
            request.addValue("mac-os", forHTTPHeaderField: "platform")
            request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 200{ //it means it is right //
                        addLog(text: "api call isInternetOn Api :- return true")
                        completionHandler(true)
                        return
                    }else{
                        addLog(text: "api call isInternetOn Api error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        
                        completionHandler(false)
                        return
                    }
                }
                
                if error != nil {
                    addLog(text: "api call isInternetOn return error:- \(error!.localizedDescription)")
                    completionHandler(false)
                    return
                }
                completionHandler(false)
                return
            }
            
            task.resume()
        }else{
            completionHandler(false)
        }
        
    }
    func getKeyWords(completionHandler: @escaping(_ result: [String]?) -> ()){
        addLog(text: "func call:- api getKeyWords")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/tab-keywords"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getKeyWords \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let arr = arrAllowedTabTitlesInCuddlyModeCurrentFocus
                    let parameters = [
                        "titles": arr
                    ] as [String : Any]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right //
                                if data != nil{
                                    do {
                                        if let jsonResult: [String] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [String]{
                                            addLog(text: "api call getKeyWords return success")
                                            
                                            arrKeywordsToAllowInFocus = jsonResult
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getKeyWords return error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call getKeyWords Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call getKeyWords return error:- \(error!.localizedDescription)")
                            completionHandler(nil)
                            return
                        }
                        completionHandler(nil)
                        return
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    
    
    
    func chatGPTIsURLSafe(url: String, tab_title: String, focus_mode: String, intention:String, currentTaskInToDoPlayer:String?, currentHabitName:String?, other_explanations_including_domains:[String], completionHandler: @escaping(_ newDic:NSDictionary?, _ url:String?, _ payload: [String: Any]?) -> ()){
        addLog(text: "func call:- chatGPTIsURLSafe")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/is-url-safe-to-use"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call chatGPTIsURLSafe \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var language = "english"
                    if currentLanguageCode == "es"{
                        language = "spanish"
                    }
                    
                    var json: [String: Any] = [
                        "url": url,
                        "tab_title": tab_title,
                        "meta_description": "",
                        "focus_mode": focus_mode,
                        "language": language,
                        "intention": intention,
                        "lastFiveJustificationsInThisFocusSession": other_explanations_including_domains,
                        "current_tasks": arrCurrentFocusTasks 
                    ]
                    if let currentTask = currentTaskInToDoPlayer{
                        json["currentTaskInToDoPlayer"] = currentTask
                    }
                    if let currentHabitName = currentHabitName{
                        json["habit_name"] = currentHabitName
                    }
                    
                    if currentFocusModeStrictness == ._SUPER_STRICT_ {
                        json["task_must_align_to_focus_intention"] = true
                    }
                    addLog(text: "chatGPTIsURLSafe: json data for api is:- \(json)")// will remove it after some time // from all chatgpt functions // 2.27.427
                    request.timeoutInterval = 15
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        if let httpResponse = response as? HTTPURLResponse{
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call chatGPTIsURLSafe success")
                                            completionHandler(jsonResult, url, json)
                                            return
                                        }else{
                                            addLog(text: "api call chatGPTIsURLSafe Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            completionHandler(nil, url, json)
                                            return
                                        }
                                    }
                                    
                                }catch{
                                    addLog(text: "api call chatGPTIsURLSafe error:- \(error.localizedDescription)")
                                    completionHandler(nil, url, json)
                                    print(error)
                                    return;
                                }
                            }
                            
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call chatGPTIsURLSafe error:- \(error!.localizedDescription)")
                            print(error?.localizedDescription)
                            completionHandler(nil, url, json)
                            return;
                        }else{
                            completionHandler(nil, url, json)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil, url, nil)
                    return
                }
                
            }else{
                completionHandler(nil, nil, nil)
                return
            }
        }
    }
    
    func chatGPTIsURLSafeWithNewIntention(url: String, tab_title: String, focus_mode: String, intention:String, intentionForThisSite:String, other_explanations_including_domains:[String], currentTaskInToDoPlayer:String?, currentHabitName:String?, completionHandler: @escaping(_ newDic:NSDictionary?, _ url:String?, _ payload: [String: Any]?) -> ()){
        addLog(text: "func call:- chatGPTIsURLSafeWithNewIntention")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/is-url-safe-to-use"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call chatGPTIsURLSafeWithNewIntention \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var language = "english"
                    if currentLanguageCode == "es"{
                        language = "spanish"
                    }
                    var json: [String: Any] = [
                        "url": url,
                        "tab_title": tab_title,
                        "meta_description": "",
                        "focus_mode": focus_mode,
                        "language": language,
                        "intention": intention,
                        "extraJustificationForThisSite": intentionForThisSite,
                        "lastFiveJustificationsInThisFocusSession": other_explanations_including_domains
                    ]//
                    
                    if let currentTask = currentTaskInToDoPlayer{
                        json["currentTaskInToDoPlayer"] = currentTask
                    }
                    if let currentHabitName = currentHabitName{
                        json["habit_name"] = currentHabitName
                    }
                    if currentFocusModeStrictness == ._SUPER_STRICT_ {
                        json["task_must_align_to_focus_intention"] = true
                    }
                    addLog(text: "chatGPTIsURLSafeWithNewIntention: json data for api is:- \(json)")// will remove it after some time
                    request.timeoutInterval = 22
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    print(json)
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        if let httpResponse = response as? HTTPURLResponse{
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call chatGPTIsURLSafeWithNewIntention success")
                                            completionHandler(jsonResult, url, json)
                                            return
                                        }else{
                                            addLog(text: "api call chatGPTIsURLSafeWithNewIntention Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            completionHandler(nil, url, json)
                                            return
                                        }
                                    }
                                    
                                }catch{
                                    addLog(text: "api call chatGPTIsURLSafeWithNewIntention error:- \(error.localizedDescription)")
                                    completionHandler(nil, url, json)
                                    print(error)
                                    return;
                                }
                            }
                            
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call chatGPTIsURLSafeWithNewIntention error:- \(error!.localizedDescription)")
                            print(error?.localizedDescription)
                            completionHandler(nil, url, json)
                            return;
                        }else{
                            completionHandler(nil, url, json)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil, url, nil)
                    return
                }
                
            }else{
                completionHandler(nil, nil, nil)
                return
            }
        }
    }
    
    
    func chatGPTIsAppSafe(appName: String, focus_mode: String, intention:String, other_explanations_including_apps:[String], currentTaskInToDoPlayer:String?, currentHabitName:String?, completionHandler: @escaping(_ newDic:NSDictionary?, _ appName:String?, _ payload: [String: Any]?) -> ()){
        addLog(text: "func call:- chatGPTIsAppSafe")
        var appName = appName
        //var tabTitle:String?
        if appName == "Claude"{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let title = claudeTitleReader.shared.chatTitle(for: runningApp){
                    print(title)
                    //tabTitle = title
                    appName = appName + " - " + title
                }
            }
        }
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/is-app-safe-to-use"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call chatGPTIsAppSafe \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var language = "english"
                    if currentLanguageCode == "es"{
                        language = "spanish"
                    }
                    var json: [String: Any] = [
                        "focusMode": focus_mode,
                        "intention": intention,
                        "appName": appName,
                        "language": language,
                        "lastFiveJustificationsInThisFocusSession": other_explanations_including_apps,
                        "current_tasks": arrCurrentFocusTasks
                    ]
                    if let currentTask = currentTaskInToDoPlayer{
                        json["currentTaskInToDoPlayer"] = currentTask
                    }
                    if let currentHabitName = currentHabitName{
                        json["habit_name"] = currentHabitName
                    }
                    if currentFocusModeStrictness == ._SUPER_STRICT_ {
                        json["task_must_align_to_focus_intention"] = true
                    }
                    
//                    if let tabTitle = tabTitle{
//                        json["tab_title"] = tabTitle
//                    }
                    addLog(text: "chatGPTIsAppSafe: json data for api is:- \(json)")// will remove it after some time
                    request.timeoutInterval = 15
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        if let httpResponse = response as? HTTPURLResponse{
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call chatGPTIsAppSafe success")
                                            completionHandler(jsonResult, appName, json)
                                            return
                                        }else{
                                            addLog(text: "api call chatGPTIsAppSafe Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            completionHandler(nil, appName, json)
                                            return
                                        }
                                    }
                                    
                                }catch{
                                    addLog(text: "api call chatGPTIsAppSafe error:- \(error.localizedDescription)")
                                    completionHandler(nil, appName, json)
                                    print(error)
                                    return;
                                }
                            }
                            
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call chatGPTIsAppSafe error:- \(error!.localizedDescription)")
                            print(error?.localizedDescription)
                            completionHandler(nil, appName, json)
                            return;
                        }else{
                            completionHandler(nil, appName, json)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil, appName, nil)
                    return
                }
                
            }else{
                completionHandler(nil, nil, nil)
                return
            }
        }
    }
    
    func chatGPTIsAppSafeWithNewIntention(appName: String, focus_mode: String, intention:String, intentionForThisApp:String, other_explanations_including_apps:[String], currentTaskInToDoPlayer:String?, currentHabitName:String?, completionHandler: @escaping(_ newDic:NSDictionary?, _ appName:String?, _ payload: [String: Any]?) -> ()){
        addLog(text: "func call:- chatGPTIsAppSafeWithNewIntention")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/is-app-safe-to-use"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call chatGPTIsAppSafeWithNewIntention \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    var language = "english"
                    if currentLanguageCode == "es"{
                        language = "spanish"
                    }
                    var json: [String: Any] = [
                        "focusMode": focus_mode,
                        "intention": intention,
                        "appName": appName,
                        "language": language,
                        "justificationForThisSpecificApp": intentionForThisApp,
                        "lastFiveJustificationsInThisFocusSession": other_explanations_including_apps
                    ]
                    if let currentTask = currentTaskInToDoPlayer{
                        json["currentTaskInToDoPlayer"] = currentTask
                    }
                    if let currentHabitName = currentHabitName{
                        json["habit_name"] = currentHabitName
                    }
                    if currentFocusModeStrictness == ._SUPER_STRICT_ {
                        json["task_must_align_to_focus_intention"] = true
                    }
                    addLog(text: "chatGPTIsAppSafeWithNewIntention: json data for api is:- \(json)")// will remove it after some time
                    request.timeoutInterval = 15
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        if let httpResponse = response as? HTTPURLResponse{
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call chatGPTIsAppSafeWithNewIntention success")
                                            completionHandler(jsonResult, appName, json)
                                            return
                                        }else{
                                            addLog(text: "api call chatGPTIsAppSafeWithNewIntention Api error:- statusCode is \(httpResponse.statusCode)")
                                            self.writeJsonInLog(data: data)
                                            completionHandler(nil, appName, json)
                                            return
                                        }
                                    }
                                    
                                }catch{
                                    addLog(text: "api call chatGPTIsAppSafeWithNewIntention error:- \(error.localizedDescription)")
                                    completionHandler(nil, appName, json)
                                    print(error)
                                    return;
                                }
                            }
                            
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call chatGPTIsAppSafeWithNewIntention error:- \(error!.localizedDescription)")
                            print(error?.localizedDescription)
                            completionHandler(nil, appName, json)
                            return;
                        }else{
                            completionHandler(nil, appName, json)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil, appName, nil)
                    return
                }
                
            }else{
                completionHandler(nil, nil, nil)
                return
            }
        }
    }
    
    
    func postTermsService(consentType:String){
        addLog(text: "func call:- postTermsService")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/consent"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call postTermsService \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "consent_type": consentType,
                        "consent_status": true,
                        "metadata":["policy_version": "1.0.0", "operating_system": "macos"]
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiPostTermsServiceErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                //success//
                                addLog(text: "api call postTermsService success")
                            }else{
                                addLog(text: "api call postTermsService error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call postTermsService error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiPostTermsServiceErrorFound{
                                    self.isApiPostTermsServiceErrorFound = false
                                }else{
                                    self.isApiPostTermsServiceErrorFound = true
                                    addLog(text: "error postTermsService:- try second time")
                                    self.postTermsService(consentType: consentType)
                                }
                            }
                        }
                    }
                    task.resume()
                }else{
                    addLog(text: "api call postTermsService error:- can't create url")
                }
                
            }
        }
    }
    
    func uploadAppLogs(feedback:String, screenShots:[URL]? = nil, completionHandler: @escaping(_ val:Bool?) -> ()){
        addLog(text: "func call:-  uploadAppLogs")
        var feedback = feedback
        if feedback.isEmpty{
            feedback = "no_feedback"
        }
        allApiObject.getUploadLogUrl(screenShots:screenShots, completionHandler: { bool, url in
            if bool{
                if let url = url{
                    allApiObject.notifyUploadLogsSuccess(feedback: feedback, uploadUrl: url, completionHandler: {bool in
                        print("Done")
                        completionHandler(bool)
                        return
                    })
                }else{
                    completionHandler(false)
                    return;
                }
            }else{
                completionHandler(false)
                return;
            }
            
        })
    }
    
    func getFocusModeTags(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getFocusModeTags")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/focus-mode/tags"//
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getFocusModeTags \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetFocusModeTagsErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let arrJsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            addLog(text: "api call getFocusModeTags success")
                                            print(arrJsonResult)
                                            completionHandler(arrJsonResult)
                                            arrAllFocusModeTags.removeAll()
                                            for json in arrJsonResult{
                                                var stringAny = [String:String]()
                                                for (key, value) in json {
                                                    stringAny[key as? String ?? ""] = value as? String ?? ""
                                                }
                                                arrAllFocusModeTags.append(stringAny)
                                            }
                                            
                                            UserDefaults.standard.set(arrAllFocusModeTags, forKey: kUserdefaultsAllFocusModesTags)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getFocusModeTags file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getFocusModeTags Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getFocusModeTags: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetFocusModeTagsErrorFound{
                                    self.isApiGetFocusModeTagsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetFocusModeTagsErrorFound = true
                                    addLog(text: "error getFocusModeTags:- try second time")
                                    self.getFocusModeTags(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func postSavedWebsite(url:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- postSavedWebsiteApi completed-activity")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            let responsePath = "\(baseUrl)/saved-website"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call postSavedWebsiteApi \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "POST";
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let json: [String: Any] = [
                    "url":url,//userId.removingPercentEncoding ?? "",
                    "title":"",
                    "metadata":[:],
                ]
                
                let jsonData = try? JSONSerialization.data(withJSONObject: [json])
                
                
                request.httpBody = jsonData
                
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiPostSavedWebsiteErrorFound = false
                        if httpResponse.statusCode == 201{
                            addLog(text: "api call postSavedWebsiteApi success")
                            completionHandler(nil)
                            return
                            
                        }else{
                            addLog(text: "api call postSavedWebsiteApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        addLog(text: "api call postSavedWebsiteApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiPostSavedWebsiteErrorFound{
                                self.isApiPostSavedWebsiteErrorFound = false
                                
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiPostSavedWebsiteErrorFound = true
                                addLog(text: "error postSavedWebsiteApi:- try second time")
                                
                                self.postSavedWebsite(url: url, completionHandler: {dic  in
                                    
                                    completionHandler(dic)
                                    return
                                })
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getSavedWebsite(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()){
        addLog(text: "func call:- getSavedWebsiteApi completed-activity")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            let responsePath = "\(baseUrl)/saved-website"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call getSavedWebsiteApi \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "GET";
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiGetSavedWebsiteErrorFound = false
                        if httpResponse.statusCode == 200{
                            if data != nil{
                                do {
                                    if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                        addLog(text: "api call getSavedWebsiteApi success")
                                        print(jsonResult)
                                        completionHandler(jsonResult)
                                        return
                                    }
                                }catch{
                                    print(error)
                                    addLog(text: "error get getSavedWebsiteApi file: \(error.localizedDescription)")
                                    completionHandler(nil)
                                    return
                                }
                            }
                            completionHandler(nil)
                            return
                        }else{
                            addLog(text: "api call getSavedWebsiteApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        addLog(text: "api call getSavedWebsiteApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiGetSavedWebsiteErrorFound{
                                self.isApiGetSavedWebsiteErrorFound = false
                                
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiGetSavedWebsiteErrorFound = true
                                addLog(text: "error getSavedWebsiteApi:- try second time")
                                
                                self.getSavedWebsite(completionHandler: {dic  in
                                    
                                    completionHandler(dic)
                                    return
                                })
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }else{
                        completionHandler(nil)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func deleteSavedWebsite(UUID:String, completionHandler: @escaping(_ isDeleted: Bool) -> ()){
        addLog(text: "func call:- deleteSavedWebsiteApi completed-activity")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            let responsePath = "\(baseUrl)/saved-website?website_id=\(UUID)"
            if let responsePathUrl = NSURL(string: responsePath){
                addLog(text: "api call deleteSavedWebsiteApi \(responsePathUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = makeRequest(responsePathUrl: responsePathUrl)
                request.httpMethod = "DELETE";
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiDeleteSavedWebsiteErrorFound = false
                        if httpResponse.statusCode == 200{
                            addLog(text: "api call deleteSavedWebsiteApi success")
                            completionHandler(true)
                            return
                            
                        }else{
                            addLog(text: "api call deleteSavedWebsiteApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            completionHandler(false)
                            return
                        }
                    }
                    
                    
                    if error != nil {
                        addLog(text: "api call deleteSavedWebsiteApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiDeleteSavedWebsiteErrorFound{
                                self.isApiDeleteSavedWebsiteErrorFound = false
                                
                                completionHandler(false)
                                return
                            }else{
                                self.isApiDeleteSavedWebsiteErrorFound = true
                                addLog(text: "error deleteSavedWebsiteApi:- try second time")
                                
                                self.deleteSavedWebsite(UUID: UUID, completionHandler: {isDeleted  in
                                    
                                    completionHandler(isDeleted)
                                    return
                                })
                            }
                        }else{
                            completionHandler(false)
                            return
                        }
                        
                    }else{
                        completionHandler(false)
                        return
                    }
                    
                }
                
                task.resume()
            }else{
                completionHandler(false)
            }
        }
    }
    
    ///
    func addAdditionalGoals(goals:[String], completionHandler: @escaping(_ result:Bool?) -> ()){
        addLog(text: "func call:- addAdditionalGoals")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/long-term-goals"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call addAdditionalGoals \(responsePathUrl)")
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "goals":goals
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            //it means it is right
                            self.isApiAddAdditionalGoalsErrorFound = false
                            if httpResponse.statusCode == 200{
                                completionHandler(true)
                                return
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call addAdditionalGoals error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiAddAdditionalGoalsErrorFound{
                                    self.isApiAddAdditionalGoalsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiAddAdditionalGoalsErrorFound = true
                                    addLog(text: "error addAdditionalGoals:- try second time")
                                    
                                    self.addAdditionalGoals(goals:goals, completionHandler: {newDic in
                                        completionHandler(newDic)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
                return
            }
        }
    }
    

    func postCourse(){
        addLog(text: "func call:- postCourse")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/course/sync-platform-courses"
                if let responsePathUrl = NSURL(string: responsePath){
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    let json: [String: Any] = [
                        "platform": "mac"
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right
                                //success//
                                print("success")
                                addLog(text: "api call postCourse success")
                            }else{
                                addLog(text: "api call postCourse error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                            }
                        }
                        if data != nil{
                            do {
                                let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary ?? [:]
                                
                                print(jsonResult)
                            }catch{
                                
                            }
                        }
                        if error != nil{
                            addLog(text: "api call postCourse error: \(error!.localizedDescription)")
                        }
                    }
                    task.resume()
                }
                
            }
        }
    }
    
    func autoEenrolledCourse(){
        addLog(text: "func call:- autoEenrolledCourse")
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/course/enrolled"
                if let responsePathUrl = NSURL(string: responsePath){
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    let json: [String: Any] = [
                        "course_id": "58baa0a7-a451-4198-a245-a5f86a61ebf3"
                    ]
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right
                                //success//
                                print("success")
                                addLog(text: "api call autoEenrolledCourse success")
                            }else{
                                addLog(text: "api call autoEenrolledCourse error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                            }
                        }
                        do {
                            let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary ?? [:]
                            
                            print(jsonResult)
                        }catch{
                            
                        }
                        
                        if error != nil{
                            addLog(text: "api call autoEenrolledCourse error: \(error!.localizedDescription)")
                        }
                    }
                    task.resume()
                }
                
            }
        }
    }
    
    
    func capturePosthogIdentify(sAliasID:String, completionHandler: @escaping(_ result:Bool) -> ()){
        addLog(text: "capturePosthogIdentify")
        
        let responsePath = "https://app.posthog.com/capture/"
        if let responsePathUrl = NSURL(string: responsePath){
            
            //addLog(text: "api call capture \(responsePathUrl)")
            let request = NSMutableURLRequest(url:responsePathUrl as URL);
            request.httpMethod = "POST";
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            
            var distinct_id = ""
            if appdelegate!.user != nil{
                if let userId = appdelegate!.user?.userId{
                    distinct_id = userId
                }
            }else{
                distinct_id = macAddress
            }
            let isGeekModeEnabled = SettingsManagerObject.isGeekModeEnabled
            var mode = "simple-mode"
            if isGeekModeEnabled{
                mode = "geek-mode"
            }
            
            
            let occupation = UserDefaults.standard.object(forKey: kUserDefaultsSelectedOccupationForPosthog) as? String ?? ""
            let goals = UserDefaults.standard.object(forKey: kUserDefaultsCustomGoals) as? String ?? ""
            let lastQuitReason = UserDefaults.standard.object(forKey: kUserDefaultsLastQuitReason) as? String ?? ""
        
            var properties = [String:Any]()
            
            properties["distinct_id"] = distinct_id
            properties["appVersion"] = appVersion
            properties["macOSVersion"] = macOSVersion
            properties["USES_MAC_APP"] = true
            properties["alias"] = sAliasID
            properties["$set"] = [//person properties
                "USES_MAC_APP": true,
                "isPayingUser": isPurchased,
                "mode": mode,
                "occupation": occupation,
                "reason-for-using-focus-bear": goals,
                "last-quit-reason": lastQuitReason,
                "app-version": appVersion,
                "USES_FULL_SCREEN_MODE": SettingsManagerObject.isFullScreenEnabled
            ]
            
            
            let json: [String: Any] = [
                "api_key": "phc_Y6hD2dvO1zylm7CLij5CuNt6S5gTxe7EVXoxZcb2xUm",
                "event": "$create_alias",
                "context": [
                    "os": "MacOS",
                    "osVersion": macOSVersion,
                    "appVersion": appVersion
                ],
                "properties": properties
            ]
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 200{ //success
                        print("api call capturePosthogIdentify success")
                        completionHandler(true)
                        return;
                    }else{
                        addLog(text: "api call capturePosthogIdentify error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                        completionHandler(false)
                        return;
                    }
                }
                if error != nil {
                    addLog(text: "api call capturePosthogIdentify error: \(error!.localizedDescription)")
                    completionHandler(false)
                    return;
                }
                
                completionHandler(false)
                return;
            }
            
            task.resume()
        }else{
            completionHandler(false)
            return;
        }
    }
    
    
    func addTask(title: String, details: String, eisenhowerQuadrant:Int, dueDate:String, objective:String, tags:[[String:String]], completionHandler: @escaping(_ result:Bool, _ jsonResult: NSDictionary?) -> ()){
        addLog(text: "func call:- addTask")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/to-do"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call addTask \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "title": title,
                        "details": details,// description
                        "objective":objective,
                        "eisenhower_quadrant": eisenhowerQuadrant,
                        "tags": tags,
                        "due_date": dueDate
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiPostTermsServiceErrorFound = false
                            if httpResponse.statusCode == 200{
                                addLog(text: "api call addTask success")
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            addLog(text: "json is:- \(jsonResult)")
                                            completionHandler(true, jsonResult)
                                            return;
                                        }
                                    }catch{
                                        
                                    }
                                }
                                
                                completionHandler(true, nil)
                                return;
                            }else{
                                addLog(text: "api call addTask error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false, nil)
                                return;
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call addTask error: \(error!.localizedDescription)")
                            completionHandler(false, nil)
                            return;
                        }
                        
                        completionHandler(false, nil)
                        return;
                    }
                    task.resume()
                }else{
                    addLog(text: "api call addTask error:- can't create url")
                    completionHandler(false, nil)
                    return;
                }
                
            }
        }
    }
    
    
    func getProjects(completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getProjects")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let zone = TimeZone.current
                let responsePath = "\(baseUrl)/completed-activity/day-summary?timezone=\(zone.identifier)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getProjects \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetProjectsErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            print(jsonResult)
                                            addLog(text: "api call getProjects success")
                                            //                                            allActivityTodaySummaryData = jsonResult
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call getProjects error:- \(error.localizedDescription)")
                                        print(error)
                                        completionHandler(nil)
                                        return
                                    }
                                }
                                
                            }else{
                                addLog(text: "api call getProjects error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        
                        
                        
                        //isApiGetAllActivityDaySummaryErrorFound
                        
                        
                        if error != nil {
                            addLog(text: "api call getProjects error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetProjectsErrorFound{
                                    self.isApiGetProjectsErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetProjectsErrorFound = true
                                    addLog(text: "error getProjects:- try second time")
                                    self.getProjects(completionHandler: {dic in
                                        completionHandler(dic)
                                        return
                                    })
                                    
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    addLog(text: "api call getProjects error:- can't create url")
                    completionHandler(nil)
                    return
                }
                
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func getUploadLogUrl(screenShots:[URL]? = nil, completionHandler: @escaping(_ val:Bool, _ url:String?) -> ()) {
        addLog(text: "func call:- getUploadLogUrl")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/app-logs/upload-logs-url?filename=Debug_Logs.txt.zip&mimetype=application/zip"
                
                
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getUploadLogUrl \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    
                    request.httpMethod = "GET";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200 && data != nil{
                                let url = String(data: data!, encoding: .utf8)!
                                
                                if data != nil{
                                    allApiObject.uploadAppLogsNew(url:url, screenShots:screenShots, completionHandler: {uploaded in
                                        completionHandler(uploaded, url)
                                        return;
                                    })
                                }else{
                                    completionHandler(false, nil)
                                    return
                                }
                            }else{
                                addLog(text: "api call get getUploadLogUrl Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false, nil)
                                return
                            }
                        }else{
                            completionHandler(false, nil)
                            return;
                        }
                        if error != nil {
                            addLog(text: "error getUploadLogUrl file: \(error!.localizedDescription)")
                            completionHandler(false, nil)
                            return;
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(false, nil)
                }
            }else{
                completionHandler(false, nil)
            }
        }
    }
    
    func uploadAppLogsNew(url:String, screenShots:[URL]? = nil, completionHandler: @escaping(_ val:Bool) -> ()){
        addLog(text: "func call:-  uploadAppLogs")
        
        guard let url = URL(string: url) else {
            print("Invalid URL")
            completionHandler(false)
            return;
        }
        let zipUrl = DebugLogsFolderURL.deletingLastPathComponent().appendingPathComponent("FocusBearMacLogs.zip")
        var zipFilePath = ""
        if #available(macOS 13.0, *) {
            zipFilePath = zipUrl.path()
        } else {
            zipFilePath = zipUrl.path
        }
        zipFilePath = zipFilePath.removingPercentEncoding ?? zipFilePath
        
        do {
            try createZipArchive(zipPath: zipFilePath, logFolder: DebugLogsFolderURL.path, screenshots: screenShots ?? [])
            print("Zip created at \(zipFilePath)")
            addLog(text: "Zipped file saved at: \(zipFilePath)")
        } catch {
            print("Error: \(error.localizedDescription)")
            addLog(text: "Error: \(error.localizedDescription)")
            completionHandler(false)
            return;
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, fromFile: zipUrl) { data, response, error in
            do{
                try FileManager.default.removeItem(at: zipUrl)
            }catch{
                print(error.localizedDescription)
            }
            if let error = error {
                print("Upload error: \(error)")
                completionHandler(false)
                return;
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Upload response: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 200{
                    completionHandler(true)
                    return;
                }
            }
            completionHandler(false)
            return;
        }
        task.resume()
        
    }
    
    func notifyUploadLogsSuccess(feedback:String, uploadUrl:String, completionHandler: @escaping(_ val:Bool) -> ()){
        addLog(text: "func call:- notifyUploadLogsSuccess")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/app-logs/notify-upload-success"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call notifyUploadLogsSuccess \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "feedback_message": feedback,
                        "app_platform": "mac-os",
                        "app_version": getAppVersionInString(),
                        "uploaded_file_url": uploadUrl
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right
                                completionHandler(true)
                                return
                            }else{
                                addLog(text: "api call notifyUploadLogsSuccess Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call notifyUploadLogsSuccess error:- \(error!.localizedDescription)")
                            completionHandler(false)
                            return
                            
                        }else{
                            completionHandler(false)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                    return
                }
                
            }else{
                completionHandler(false)
                return
            }
        }
    }
    
    func emailConfirmation(completionHandler: @escaping(_ val:Bool) -> ()){
        addLog(text: "func call:- emailConfirmation")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/auth/email-confirmation"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call emailConfirmation \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right
                                completionHandler(true)
                                return
                            }else{
                                addLog(text: "api call emailConfirmation Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call emailConfirmation error:- \(error!.localizedDescription)")
                            completionHandler(false)
                            return
                            
                        }else{
                            completionHandler(false)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                    return
                }
                
            }else{
                completionHandler(false)
                return
            }
        }
    }
    
    
    func resetPassword( completionHandler: @escaping(_ val:Bool, _ errorMessage:String?) -> ()){
        addLog(text: "func call:- resetPassword")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/auth/reset-password"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call resetPassword \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "email": currentUserEmail
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 201{ //it means it is right
                                completionHandler(true, nil)
                                return
                            }else{
                                addLog(text: "api call resetPassword Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            addLog(text: "json is:- \(jsonResult)")
                                            if let message = jsonResult.value(forKey: "message") as? String{
                                                completionHandler(false, message)
                                                return;
                                            }
                                        }
                                    }catch{
                                        
                                    }
                                    if let message = String(data: data!, encoding: .utf8){
                                        completionHandler(false, message)
                                        return;
                                    }
                                }
                                completionHandler(false, nil)
                                return
                            }
                        }
                        
                        if error != nil {
                            addLog(text: "api call resetPassword error:- \(error!.localizedDescription)")
                            completionHandler(false, nil)
                            return
                            
                        }else{
                            completionHandler(false, nil)
                            return
                        }
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false, nil)
                    return
                }
                
            }else{
                completionHandler(false, nil)
                return
            }
        }
    }
    
    // Use /to-do/recent to fetch up to 50 most recently updated tasks.
    func getAllTasks(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getAllTasks")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                // more than 10 task work recent?take=50 added 3.33.493
                // This endpoint returns a plain array (not a paginated wrapper), so
                // more than the default 10 tasks are returned.
                let responsePath = "\(baseUrl)/to-do/recent?take=50"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllTasks \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetAllTasksErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        // /to-do/recent returns a plain array, not a paginated wrapper
                                        if let arrJsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            addLog(text: "api call getAllTasks success")
                                            print(arrJsonResult)
                                            completionHandler(arrJsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getAllTasks file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getAllTasks Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getAllTasks: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetAllTasksErrorFound{
                                    self.isApiGetAllTasksErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetAllTasksErrorFound = true
                                    addLog(text: "error getAllTasks:- try second time")
                                    self.getAllTasks(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    /// Fetches the to-do list in the backend's SMART (TOP-score) priority order. Unlike
    /// /to-do/recent (recency, plain array), this endpoint is paginated and already prioritised,
    /// so the Day Plan picker shows the same order as the web to-do list. Handles both a plain
    /// array and a `{ data: [...] }` wrapper response.
    func getSmartTasks(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getSmartTasks")
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil else { completionHandler(nil); return }
            let responsePath = "\(baseUrl)/to-do?page=1&take=50&status=NOT_STARTED&order=DESC&sort_mode=SMART"
            guard let responsePathUrl = NSURL(string: responsePath) else { completionHandler(nil); return }
            addLog(text: "api call getSmartTasks \(responsePathUrl)")
            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else { completionHandler(nil); return }
                guard httpResponse.statusCode == 200, let data = data else {
                    addLog(text: "getSmartTasks statusCode \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completionHandler(nil); return
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    if let arr = json as? [NSDictionary] { completionHandler(arr); return }
                    if let obj = json as? NSDictionary, let arr = obj.value(forKey: "data") as? [NSDictionary] {
                        completionHandler(arr); return
                    }
                    addLog(text: "getSmartTasks: unexpected response shape")
                } catch {
                    addLog(text: "error getSmartTasks parse: \(error.localizedDescription)")
                }
                completionHandler(nil)
            }
            task.resume()
        }
    }

    /// Fetch ALL of the user's projects (used by the Day Plan `#project` autocomplete). The
    /// `/projects` response is `{ data: [page], projects: [...], total_count, meta }`; we take the
    /// larger of `data`/`projects` and, if that's still short of `total_count`, page with `?page=N`
    /// (no `take` — a large `take` makes the endpoint return empty) until we've collected them all.
    func getProjectsList(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getProjectsList")
        fetchProjectsPage(page: 1, accumulated: [], completionHandler: completionHandler)
    }

    private func fetchProjectsPage(page: Int, accumulated: [NSDictionary],
                                   completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil else {
                completionHandler(accumulated.isEmpty ? nil : accumulated); return
            }
            let responsePath = page == 1 ? "\(baseUrl)/projects" : "\(baseUrl)/projects?page=\(page)"
            guard let responsePathUrl = NSURL(string: responsePath) else {
                completionHandler(accumulated.isEmpty ? nil : accumulated); return
            }
            addLog(text: "api call getProjectsList \(responsePathUrl)")
            let request = makeRequest(responsePathUrl: responsePathUrl)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    addLog(text: "getProjectsList statusCode \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completionHandler(accumulated.isEmpty ? nil : accumulated); return
                }
                var pageItems: [NSDictionary] = []
                var totalCount = 0
                if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) {
                    if let arr = json as? [NSDictionary] {
                        pageItems = arr
                    } else if let obj = json as? NSDictionary {
                        let dataArr = obj.value(forKey: "data") as? [NSDictionary] ?? []
                        let projArr = obj.value(forKey: "projects") as? [NSDictionary] ?? []
                        pageItems = projArr.count > dataArr.count ? projArr : dataArr
                        totalCount = (obj.value(forKey: "total_count") as? Int)
                            ?? ((obj.value(forKey: "meta") as? NSDictionary)?.value(forKey: "total") as? Int) ?? 0
                    }
                }
                // Dedupe by id so we stop cleanly even if `?page=` is ignored and the same set repeats.
                let existingIds = Set(accumulated.compactMap { $0.value(forKey: "id") as? String })
                let newItems = pageItems.filter {
                    guard let id = $0.value(forKey: "id") as? String else { return true }
                    return !existingIds.contains(id)
                }
                let all = accumulated + newItems
                let more = !newItems.isEmpty && (totalCount == 0 || all.count < totalCount)
                if more, page < 50 {
                    self.fetchProjectsPage(page: page + 1, accumulated: all, completionHandler: completionHandler)
                } else {
                    completionHandler(all)
                }
            }
            task.resume()
        }
    }

    func getAllBlockingSchedules(completionHandler: @escaping(_ result: Data?) -> ()) {
        addLog(text: "func call:- getAllBlockingSchedules")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/blocking-schedules"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllBlockingSchedules \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetAllBlockingSchedulesErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    completionHandler(data!)
                                    return
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getAllBlockingSchedules Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getAllBlockingSchedules: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetAllBlockingSchedulesErrorFound{
                                    self.isApiGetAllBlockingSchedulesErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetAllBlockingSchedulesErrorFound = true
                                    addLog(text: "error getAllBlockingSchedules:- try second time")
                                    self.getAllBlockingSchedules(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func addBlockingSchedule(jsonData:Data, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- addBlockingSchedule")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/blocking-schedules"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call addBlockingSchedule \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiAddBlockingScheduleErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                
                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call addBlockingSchedule error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call addBlockingSchedule error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiAddBlockingScheduleErrorFound{
                                    self.isApiAddBlockingScheduleErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiAddBlockingScheduleErrorFound = true
                                    addLog(text: "error addBlockingSchedule:- try second time")
                                    self.addBlockingSchedule(jsonData: jsonData, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }
                            
                        }else{
                            completionHandler(false)
                            return;
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }
    
    
    func updateBlockingSchedule(id: String, jsonData:Data, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- updateBlockingSchedule")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/blocking-schedules/\(id)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call updateBlockingSchedule \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "PUT";
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiUpdateBlockingScheduleErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call updateBlockingSchedule error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call updateBlockingSchedule error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiUpdateBlockingScheduleErrorFound{
                                    self.isApiUpdateBlockingScheduleErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiUpdateBlockingScheduleErrorFound = true
                                    addLog(text: "error updateBlockingSchedule:- try second time")
                                    self.updateBlockingSchedule(id: id, jsonData: jsonData, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }
                            
                        }else{
                            completionHandler(false)
                            return;
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }
    
    func deleteBlockingSchedule(id: String, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- deleteBlockingSchedule")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/blocking-schedules/\(id)"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call deleteBlockingSchedule \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "DELETE";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiDeleteBlockingScheduleErrorFound = false
                            if httpResponse.statusCode == 204{
                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call deleteBlockingSchedule error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call deleteBlockingSchedule error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiDeleteBlockingScheduleErrorFound{
                                    self.isApiDeleteBlockingScheduleErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiDeleteBlockingScheduleErrorFound = true
                                    addLog(text: "error deleteBlockingSchedule:- try second time")
                                    self.deleteBlockingSchedule(id: id, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }
                            
                        }else{
                            completionHandler(false)
                            return;
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }
    
    
    func getAllBuddies(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getAllBuddies")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/accountability-buddy"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllBuddies \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetAllBuddiesErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let arrJsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                            
                                            print(arrJsonResult)
                                            completionHandler(arrJsonResult)
                                            return;
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getAllBuddies file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getAllBuddies Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getAllBuddies: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetAllBuddiesErrorFound{
                                    self.isApiGetAllBuddiesErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetAllBuddiesErrorFound = true
                                    addLog(text: "error getAllBuddies:- try second time")
                                    self.getAllBuddies(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    func unlockRequest(withBuddyUserId:String, reason:String, durationMinutes: Int, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- unlockRequest")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/accountability-buddy/unlock-request"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call unlockRequest \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "accountability_buddy_user_id":withBuddyUserId,
                        "reason": reason,
                        "unlock_duration_minutes": durationMinutes
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiUnlockRequestErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                
                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call unlockRequest error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(false)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call unlockRequest error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiUnlockRequestErrorFound{
                                    self.isApiUnlockRequestErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiUnlockRequestErrorFound = true
                                    addLog(text: "error unlockRequest:- try second time")
                                    self.unlockRequest(withBuddyUserId:withBuddyUserId, reason:reason, durationMinutes: durationMinutes, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }
                            
                        }else{
                            completionHandler(false)
                            return;
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }
    


    func generateOccupationRelevantSites(userOccupation:String, completionHandler: @escaping(_ result: [String:Any]?) -> ()){
        addLog(text: "func call:- generateOccupationRelevantSites")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "\(baseUrl)/user/generate-occupation-specific-relevant-sites"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call generateOccupationRelevantSites \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";
                    
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let json: [String: Any] = [
                        "user_occupation":userOccupation
                    ]
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGenerateOccupationRelevantSitesErrorFound = false
                            if httpResponse.statusCode == 201{ //it means it is right
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: [String:Any] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]{
                                            
                                            addLog(text: "api call generateOccupationRelevantSites success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get generateOccupationRelevantSites: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call generateOccupationRelevantSites error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return;
                            }
                        }
                        
                        
                        if error != nil {
                            addLog(text: "api call generateOccupationRelevantSites error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGenerateOccupationRelevantSitesErrorFound{
                                    self.isApiGenerateOccupationRelevantSitesErrorFound = false
                                    completionHandler(nil)
                                    return;
                                }else{
                                    self.isApiGenerateOccupationRelevantSitesErrorFound = true
                                    addLog(text: "error generateOccupationRelevantSites:- try second time")
                                    self.generateOccupationRelevantSites(userOccupation: userOccupation, completionHandler: { result in
                                        completionHandler(result)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return;
                            }
                            
                        }else{
                            completionHandler(nil)
                            return;
                        }
                        
                    }
                    
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    
    func getUnlockRequestStatus(completionHandler: @escaping(_ result: [NSDictionary]?) -> ()) {
        addLog(text: "func call:- getUnlockRequestStatus")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "\(baseUrl)/accountability-buddy/unlock-requests"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getUnlockRequestStatus \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            self.isApiGetUnlockRequestStatusErrorFound = false
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let json: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
                                            print(json)
                                            
                                            if let data = json.value(forKey: "data") as? [NSDictionary]{
                                                completionHandler(data)
                                                return;
                                            }
                                            completionHandler(nil)
                                            return;
                                        }
                                        
                                    }catch{
                                        print(error)
                                        addLog(text: "error get getUnlockRequestStatus file: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }
                                    
                                }
                                
                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getUnlockRequestStatus Api error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                completionHandler(nil)
                                return
                            }
                        }
                        if error != nil {
                            addLog(text: "error getUnlockRequestStatus: \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetUnlockRequestStatusErrorFound{
                                    self.isApiGetUnlockRequestStatusErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiGetUnlockRequestStatusErrorFound = true
                                    addLog(text: "error getUnlockRequestStatus:- try second time")
                                    self.getUnlockRequestStatus(completionHandler: { json in
                                        completionHandler(json)
                                        return
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return
                            }
                            
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }
    
    //***********Teacher Mode class session apis***************//

    func joinClassSession(sessionId:String, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:- joinClassSession")

        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")

            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            if appdelegate!.credential != nil{

                let responsePath = "\(baseUrl)/class-session/\(sessionId)/join"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call joinClassSession \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken

                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";

                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    // The server rejects an empty body when Content-Type is application/json
                    // ("Body cannot be empty…"), so send an empty JSON object.
                    request.httpBody = "{}".data(using: .utf8)

                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiJoinClassSessionErrorFound = false
                            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201{ //it means it is right

                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{

                                            addLog(text: "api call joinClassSession success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }

                                    }catch{
                                        print(error)
                                        addLog(text: "error joinClassSession: \(error.localizedDescription)")
                                        completionHandler(nil)
                                        return
                                    }

                                }

                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call joinClassSession error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
                                completionHandler(nil)
                                return;
                            }
                        }


                        if error != nil {
                            addLog(text: "api call joinClassSession error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiJoinClassSessionErrorFound{
                                    self.isApiJoinClassSessionErrorFound = false
                                    completionHandler(nil)
                                    return;
                                }else{
                                    self.isApiJoinClassSessionErrorFound = true
                                    addLog(text: "error joinClassSession:- try second time")
                                    self.joinClassSession(sessionId: sessionId, completionHandler: { newDic in
                                        completionHandler(newDic)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return;
                            }

                        }else{
                            completionHandler(nil)
                            return;
                        }

                    }

                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }

    func declineClassSession(sessionId:String, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- declineClassSession")

        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")

            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            if appdelegate!.credential != nil{

                let responsePath = "\(baseUrl)/class-session/\(sessionId)/decline"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call declineClassSession \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken

                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";

                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    // The server rejects an empty body when Content-Type is application/json
                    // ("Body cannot be empty…"), so send an empty JSON object.
                    request.httpBody = "{}".data(using: .utf8)
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiDeclineClassSessionErrorFound = false
                            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204{ //it means it is right

                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call declineClassSession error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
                                completionHandler(false)
                                return;
                            }
                        }


                        if error != nil {
                            addLog(text: "api call declineClassSession error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiDeclineClassSessionErrorFound{
                                    self.isApiDeclineClassSessionErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiDeclineClassSessionErrorFound = true
                                    addLog(text: "error declineClassSession:- try second time")
                                    self.declineClassSession(sessionId: sessionId, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }

                        }else{
                            completionHandler(false)
                            return;
                        }

                    }

                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }

    func getCurrentClassSession(completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:- getCurrentClassSession")

        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")

            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            if appdelegate!.credential != nil{

                let responsePath = "\(baseUrl)/class-session/current"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call getCurrentClassSession \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken

                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "GET";

                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiGetCurrentClassSessionErrorFound = false
                            if httpResponse.statusCode == 200{

                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{

                                            addLog(text: "api call getCurrentClassSession success")
                                            print(jsonResult)
                                            completionHandler(jsonResult)
                                            return
                                        }

                                    }catch{
                                        // the endpoint returns null when there is no live session for the caller
                                        completionHandler(nil)
                                        return
                                    }

                                }

                                completionHandler(nil)
                                return
                            }else{
                                addLog(text: "api call getCurrentClassSession error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
                                completionHandler(nil)
                                return;
                            }
                        }


                        if error != nil {
                            addLog(text: "api call getCurrentClassSession error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiGetCurrentClassSessionErrorFound{
                                    self.isApiGetCurrentClassSessionErrorFound = false
                                    completionHandler(nil)
                                    return;
                                }else{
                                    self.isApiGetCurrentClassSessionErrorFound = true
                                    addLog(text: "error getCurrentClassSession:- try second time")
                                    self.getCurrentClassSession(completionHandler: { newDic in
                                        completionHandler(newDic)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(nil)
                                return;
                            }

                        }else{
                            completionHandler(nil)
                            return;
                        }

                    }

                    task.resume()
                }else{
                    completionHandler(nil)
                }
            }else{
                completionHandler(nil)
            }
        }
    }

    // canonical heartbeat body {in_focus, device_id} - best effort, no retry (next beat is 25s away)
    func classSessionHeartbeat(sessionId:String, inFocus:Bool, completionHandler: @escaping(_ result: Bool) -> ()){

        appdelegate!.credentialsManager.credentials {credentialsInfo in

            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            if appdelegate!.credential != nil{

                let responsePath = "\(baseUrl)/class-session/\(sessionId)/heartbeat"
                if let responsePathUrl = NSURL(string: responsePath){

                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";

                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let json: [String: Any] = [
                        "in_focus": inFocus,
                        "device_id": currentDeviceId
                    ]

                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData

                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if let httpResponse = response as? HTTPURLResponse{
                            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 204{ //it means it is right

                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call classSessionHeartbeat error:- statusCode is \(httpResponse.statusCode)")
                                completionHandler(false)
                                return;
                            }
                        }

                        if error != nil {
                            addLog(text: "api call classSessionHeartbeat error:- \(error!.localizedDescription)")
                        }
                        completionHandler(false)
                        return;

                    }

                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }

    func requestClassUnlock(sessionId:String, requestedApp:String?, requestedDomain:String?, reason:String, completionHandler: @escaping(_ result: Bool) -> ()){
        addLog(text: "func call:- requestClassUnlock")

        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")

            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)

            if appdelegate!.credential != nil{

                let responsePath = "\(baseUrl)/class-session/\(sessionId)/unlock-requests"
                if let responsePathUrl = NSURL(string: responsePath){
                    addLog(text: "api call requestClassUnlock \(responsePathUrl)")
                    let token = appdelegate!.credential!.accessToken

                    let request = makeRequest(responsePathUrl: responsePathUrl)
                    request.httpMethod = "POST";

                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    var json: [String: Any] = [:]
                    if let requestedApp = requestedApp{
                        json["requested_app"] = requestedApp
                    }
                    if let requestedDomain = requestedDomain{
                        json["requested_domain"] = requestedDomain
                    }
                    if !reason.isEmpty{
                        json["reason"] = reason
                    }

                    let jsonData = try? JSONSerialization.data(withJSONObject: json)
                    request.httpBody = jsonData

                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in

                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiRequestClassUnlockErrorFound = false
                            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201{ //it means it is right

                                completionHandler(true)
                                return;
                            }else{
                                addLog(text: "api call requestClassUnlock error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
                                completionHandler(false)
                                return;
                            }
                        }


                        if error != nil {
                            addLog(text: "api call requestClassUnlock error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiRequestClassUnlockErrorFound{
                                    self.isApiRequestClassUnlockErrorFound = false
                                    completionHandler(false)
                                    return;
                                }else{
                                    self.isApiRequestClassUnlockErrorFound = true
                                    addLog(text: "error requestClassUnlock:- try second time")
                                    self.requestClassUnlock(sessionId: sessionId, requestedApp: requestedApp, requestedDomain: requestedDomain, reason: reason, completionHandler: { bool in
                                        completionHandler(bool)
                                        return;
                                    })
                                }
                            }else{
                                completionHandler(false)
                                return;
                            }

                        }else{
                            completionHandler(false)
                            return;
                        }

                    }

                    task.resume()
                }else{
                    completionHandler(false)
                }
            }else{
                completionHandler(false)
            }
        }
    }

    func transcribeAudio(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let apiKey = "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"
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "model": "whisper-1",
            "language": "en"
        ]//gpt5.4
        
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        if let fileData = try? Data(contentsOf: fileURL) {
            let filename = fileURL.lastPathComponent
            let mimetype = "audio/wav"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                completion(.failure(error))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let transcription = json["text"] as? String {
                    completion(.success(transcription))
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response data"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func getIntentFromOpenAI(userMessage: String, habits:String, completion: @escaping (Result<IntentResponse, Error>) -> Void) {
        let apiKey = "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"
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let dateString = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // System prompt to classify intent
        let systemPrompt = """
        You are a voice command classifier for a productivity app called Focus Bear.  
        Your job is to parse the user's spoken command and output a structured JSON object that my app can execute.

        Possible actions:
        - create_task
        - start_focus
        - pause_focus
        - resume_focus
        - stop_focus
        - start_habit
        - pause_habit
        - resume_habit
        - get_focus_stats

        **Create task**
        Fields: task (string), datetime OPTIONAL (local system datetime or relative like "tomorrow 9am", "tomorrow", "in 2 hours", "next thursday"), optional repeat.
        A reminder or task WITHOUT any time is still a valid create_task — "remind me to X", "add a task to X", "note to self: X" all map to create_task with high confidence and datetime null. Do NOT lower confidence just because no time was given.

        **Start focus session**  
        Fields: duration_minutes (int), goal (string, optional).

        **Pause focus session**  
        Fields: none.

        **Stop focus session**  
        Fields: none.

        **Start a habit**  
        Fields: habit_name (string), optional duration or repeat.
        
        **Pause habit**  
        Fields: none.

        **Resume habit**
        Fields: none.

        **Get focus stats**
        Fields: none. Use when the user asks how they're doing, how much they've focused, or how many hours of deep work they've done today (e.g. "how's my focus today?", "how much deep work have I done?").

        Rules:
        - Infer missing details sensibly. If no duration for focus, default to 25 min.
        - Assume current datetime is \(dateString) and format is "yyyy-MM-dd HH:mm:ss".
        - If input contains datetime which may be relative (e.g., "tomorrow", "in 2 hours", "next thursday"), calculate the resulting datetime as local datetime using current datetime as reference.
        - If the command is unclear, set "confidence" to "low" and explain in "clarification_needed".
        - If multiple actions, pick the primary one but note secondary in "additional_actions".

        Respond with ONLY valid JSON. No markdown formatting, no explanation text before or after the JSON.
        Output format (JSON only, no extra text):

        {
          "action": "create_task | start_focus | pause_focus | stop_focus | start_habit | get_focus_stats",
          "parameters": {
            // action-specific fields
          },
          "confidence": "high | medium | low",
          "clarification_needed": "string or null",
          "additional_actions": [] // optional
        }

        Examples of input and output:

        1. "Remind me to call mom tomorrow at 9am"
        {
          "action": "create_task",
          "parameters": {
            "task": "call mom",
            "time": "yyyy-MM-dd HH:mm:ss",
            "repeat": null
          },
          "confidence": "high",
          "clarification_needed": null
        }

        1b. "Remind me to go to the movies"  (a reminder with no time — still high confidence)
        {
          "action": "create_task",
          "parameters": {
            "task": "go to the movies",
            "time": null,
            "repeat": null
          },
          "confidence": "high",
          "clarification_needed": null
        }

        2. "Start a focus session for 45 mins with goal test windows app"
        {
          "action": "start_focus",
          "parameters": {
            "duration_minutes": 45,
            "goal": "test windows app"
          },
          "confidence": "high",
          "clarification_needed": null
        }

        3. "Pause focus session"
        {
          "action": "pause_focus",
          "parameters": {},
          "confidence": "high",
          "clarification_needed": null
        }

        4. "Stop focus session"
        {
          "action": "stop_focus",
          "parameters": {},
          "confidence": "high",
          "clarification_needed": null
        }

        5. "Start a habit named drink water"
        {
          "action": "start_habit",
          "parameters": {
            "habit_name": "drink water"
          },
          "confidence": "high",
          "clarification_needed": null
        }

        For habits, please note that I have a defined list of habits and you should closely match the input and return one name from this habit list: " 
                   
        "\(habits)"
        
        Now classify this user command:
        "\(userMessage)"
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.1,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                completion(.failure(error))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let intentData = content.data(using: .utf8){
                    let intentResponse = try JSONDecoder().decode(IntentResponse.self, from: intentData)
                    completion(.success(intentResponse))
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    
}

func generateBoundaryString() -> String{
    return "Boundary-\(NSUUID().uuidString)"
}

func makeRequest(responsePathUrl: NSURL)->NSMutableURLRequest{
    let userId = appdelegate!.user?.userId ?? ""
    let token = appdelegate!.credential?.accessToken ?? ""
    let request = NSMutableURLRequest(url:responsePathUrl as URL);
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.addValue("mac-os", forHTTPHeaderField: "platform")
    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
    request.addValue(userId, forHTTPHeaderField: "x-focus-bear-user-id")
    request.addValue(currentDeviceId, forHTTPHeaderField: "device-id")
    request.addValue(currentDeviceId, forHTTPHeaderField: "device_id")
    return request
}





//------Event Buffer Singleton--------//new events endpoint #1536 v 2.28.436
final class EventBuffer {
    static let shared = EventBuffer()
    
    private var events: [[String: Any]] = []
    private var timer: Timer?
    private var batchMinCount = 0
    
    private init() {
        startBatchTimer()
    }
    
    func addEvent(_ event: [String: Any]) {
        DispatchQueue.main.async {
            self.events.append(event)
        }
    }
    
    private func startBatchTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.flushEvents()
        }
    }
}

extension EventBuffer {

    func flushEvents() {
        addLog(text: "func flushEvents events: \(events.count)")
        guard events.count > batchMinCount else { return }

        let batch = events
        events.removeAll()

        sendBatchToServer(batch)
    }
    
    private func sendBatchToServer(_ batch: [[String: Any]]) {
        guard let url = URL(string: "https://events.aws.focusbear.io/batch-ingest-events/events")
        else { return }

//        var request = URLRequest(url: url)
        let request = makeRequest(responsePathUrl: url as NSURL)
        request.httpMethod = "POST"

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: batch, options: [])
        } catch {
            print("JSON error:", error)
            return
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            if let error = error {
                print("Upload error:", error)
                addLog(text: "api call batch-ingest-events error: \(error.localizedDescription)")
                return
            }

            if let http = response as? HTTPURLResponse {
                print("Batch Uploaded. Status:", http.statusCode)
                if http.statusCode == 204{ //success
                    return;
                }else{
                    addLog(text: "api call captureEventEndpoint error:- statusCode is \(http.statusCode)")
                    allApiObject.writeJsonInLog(data: data)
                }
            }
        }.resume()
    }
}

// Intent Response Model - Fixed Decodable conformance
struct IntentResponse: Codable {
    let action: String
    let parameters: Parameters
    let confidence: String
    let clarification_needed: String?
    let additional_actions: [AdditionalAction]?
    
    struct Parameters: Codable {
        let task: String?
        let time: String?
        let `repeat`: String?
        let duration_minutes: Int?
        let goal: String?
        let habit_name: String?
        
        enum CodingKeys: String, CodingKey {
            case task
            case time
            case `repeat` = "repeat"  // Handle reserved keyword
            case duration_minutes
            case goal
            case habit_name
        }
        
        // Custom initializer to handle missing values
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            task = try container.decodeIfPresent(String.self, forKey: .task)
            time = try container.decodeIfPresent(String.self, forKey: .time)
            `repeat` = try container.decodeIfPresent(String.self, forKey: .repeat)
            duration_minutes = try container.decodeIfPresent(Int.self, forKey: .duration_minutes)
            goal = try container.decodeIfPresent(String.self, forKey: .goal)
            habit_name = try container.decodeIfPresent(String.self, forKey: .habit_name)
        }
        
        // Custom encoder (optional but good to have)
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(task, forKey: .task)
            try container.encodeIfPresent(time, forKey: .time)
            try container.encodeIfPresent(`repeat`, forKey: .repeat)
            try container.encodeIfPresent(duration_minutes, forKey: .duration_minutes)
            try container.encodeIfPresent(goal, forKey: .goal)
            try container.encodeIfPresent(habit_name, forKey: .habit_name)
        }
    }
    
    struct AdditionalAction: Codable {
        let action: String
        let parameters: [String: String]?
    }
}


/*
 let systemPrompt = """
 You are a task classifier for a focus app. Analyze the user's speech and return a JSON response.
 
 Possible intents:
 1. "start_focus" - User wants to start a focus session
 2. "stop_focus" - User wants to stop focus session
 3. "pause_focus" - User wants to pause focus session
 4. "resume_focus" - User wants to resume focus session
 5. "create_task" - User wants to create a reminder/task
 
 For start_focus, extract:
 - duration_in_minutes: number (default 25 if not specified)
 - goal: what they want to accomplish (optional)
 
 For create_task, extract:
 - task_name: what needs to be done (clean, without filler words)
 - due_date: "today", "tomorrow", "next week", "next monday", or "none" if not specified
 
 Return ONLY valid JSON in this format:
 {
     "intent": "start_focus",
     "duration_in_minutes": 45,
     "goal": "complete ethics application"
 }
 
 OR
 {
     "intent": "create_task",
     "task_name": "call jeremy",
     "due_date": "tomorrow"
 }
 
 OR
 {
     "intent": "stop_focus"
 }
 """*/
