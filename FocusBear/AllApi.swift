//
//  AllApi.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 30/07/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Foundation

class AllApi:NSObject {
    
    
    
    func getConfigFile(fileUrl:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading config file")
        if let myUrl = NSURL(string: fileUrl){
            addLog(text: "api call getConfigFile \(myUrl)")
            let request = NSMutableURLRequest(url:myUrl as URL);
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
    
    func isSettingsValid(settings:NSDictionary, completionHandler: @escaping(_ result: NSDictionary?, _ statusCode:Int) -> ()){
        addLog(text: "func call:- api isSettingsValid user-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/user-settings"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call isSettingsValid \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "PUT";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                addLog(text: "accessToken is:- \(token)")
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
    
    func getDeviceId(completionHandler: @escaping(_ deviceId:String?) -> ()){
        addLog(text: "func call:- getDeviceId")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/device"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getDeviceId \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "POST";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                        addLog(text: "accessToken is:- \(token)")
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
        addLog(text: "func call:- captureEventEndpoint")
        
        let responsePath = "https://api.focusbear.io/events"
        if let myUrl = NSURL(string: responsePath){
            guard let token = appdelegate!.credential?.accessToken else{
                return
            }
            addLog(text: "api call captureEventEndpoint \(myUrl)")
            let request = NSMutableURLRequest(url:myUrl as URL);
            request.httpMethod = "POST";
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("mac-os", forHTTPHeaderField: "platform")
            request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
            
            var distinct_id = ""
            if appdelegate!.user != nil{
                if let userId = appdelegate!.user?.userId{
                    distinct_id = userId
                }
            }else{
                distinct_id = macAddress
            }
            
            var properties = [String:Any]()
            

            
            for key in metadata.keys{
                properties[key] = metadata[key]
            }
            var event_data = [String : Any]()
            event_data = ["data":properties]
            
            let json: [String: Any] = [
                "event_type": event,
                "user_properties": [
                    "USERNAME": currentUserName,
                    "id": distinct_id,
                    "USES_MAC_APP": true
                ],
                "event_data": event_data
            ]
            //            properties": [
            //                "distinct_id": "testuserid",// user id if logged in else mac machine id
            //                "routine-type": "morning_routine",// morning evening or break activity ni h to jayga hi nahi
            //                "deactivate-reason": "app is broken",//for deactivate
            //                "detailed-reason": "Still shows morning routine after I finished morning routine"
            //            ]
            
            
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 204{ //it means it is right
                    
                        addLog(text: "api call captureEventEndpoint success")
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
    }
    func capturePosthog(event:String, metadata:[String:Any]){
        
        captureEventEndpoint(event: event, metadata: metadata)
        
        
        addLog(text: "func call:- capturePosthog")
        
        let responsePath = "https://app.posthog.com/capture/"
        if let myUrl = NSURL(string: responsePath){
            
            addLog(text: "api call capture \(myUrl)")
            let request = NSMutableURLRequest(url:myUrl as URL);
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
            
            var properties = [String:Any]()
            
            properties["distinct_id"] = distinct_id
            properties["appVersion"] = appVersion
            properties["macOSVersion"] = macOSVersion
            properties["USES_MAC_APP"] = true
            for key in metadata.keys{
                properties[key] = metadata[key]
            }
            
            
            let json: [String: Any] = [
                "api_key": "phc_Y6hD2dvO1zylm7CLij5CuNt6S5gTxe7EVXoxZcb2xUm",
                "event": event,
                "context": [
                    "os": "MacOS",
                    "osVersion": macOSVersion,
                    "appVersion": appVersion
                ],
                "properties": properties
            ]
            //            properties": [
            //                "distinct_id": "testuserid",// user id if logged in else mac machine id
            //                "routine-type": "morning_routine",// morning evening or break activity ni h to jayga hi nahi
            //                "deactivate-reason": "app is broken",//for deactivate
            //                "detailed-reason": "Still shows morning routine after I finished morning routine"
            //            ]
            
            
            
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            request.httpBody = jsonData
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode == 200{ //it means it is right
                    
                        addLog(text: "api call capturePosthog success")
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
    
    
    func getSettings(isFirstTime:Bool, isHabitsDisabled:Bool, completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading Settings file user-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                var responsePath = "https://api.focusbear.io/user-settings"
                if isFirstTime{
                    if isHabitsDisabled{
                        responsePath = "https://api.focusbear.io/habit-packs/default?pack_id=7cff2a97-90ad-4791-98b0-4a79dad32f73&format=break_only"
                    }else{
                        responsePath = "https://api.focusbear.io/habit-packs/default?pack_id=45ede897-9008-494f-b810-8d5495f6baca&format=routine_and_break"
                    }
                }
                
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getSettings \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 200{
                                
                                if data != nil{
                                    do {
                                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                            
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
                                addLog(text: "accessToken is:- \(token)")
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
                let responsePath = "https://api.focusbear.io/user-local-device-settings"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getSettings \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                addLog(text: "accessToken is:- \(token)")
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
    var isApiAddFocusModeErrorFound = false
    var isApiDeleteFocusModeErrorFound = false
    var isApiEditFocusModeErrorFound = false
    var isApiStartFocusModeErrorFound = false
    var isApiFinishFocusModeErrorFound = false
    var isApiGetDeviceIdErrorFound = false
    var isApiActivitySkippedErrorFound = false
    
    
    var errorCodeRequestTimeout = -1001
    var errorCodeNoInternet = -1009
    
    func getLastActivityInfo(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "func call:- downloading getLastActivityInfo file")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            if appdelegate!.credential != nil{
                let responsePath = "https://api.focusbear.io/user/details/current-activity-props"//
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getLastActivityInfo \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                addLog(text: "accessToken is:- \(token)")
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
                let responsePath = "https://api.focusbear.io/user/details"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getuserDetailsInfo \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                addLog(text: "accessToken is:- \(token)")
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
    func putUserLocalDeviceSettings(settings:[String: [String:Any]], completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:-  putUserLocalDeviceSettings:- user-local-device-settings")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/user-local-device-settings"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call putUserLocalDeviceSettings \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "PUT";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
                                addLog(text: "accessToken is:- \(token)")
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
    var isAnyErrorFoundInActivityCompletedApi = false
    
    func activityCompletedApi(activity_id:String, activity_sequence_id:String, start_time:Date, quantity_logged:Double?, duration_logged:Int, choice_id:String?, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- activityCompletedApi completed-activity")

        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            
            self.completedActivityLogId = nil
            self.completedChoiceLogId = nil
            
            let calendar = Calendar.current
            let finish_time = calendar.date(byAdding: .second, value: duration_logged, to: start_time) ?? Date()
            
            let responsePath = "https://api.focusbear.io/completed-activity"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call activityCompletedApi \(myUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("mac-os", forHTTPHeaderField: "platform")
                request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
  
                var json: [String: Any] = [
                    "activity_id":activity_id,//userId.removingPercentEncoding ?? "",
                    // "choice_id":choice_id,//deviceName.removingPercentEncoding ?? "",
                    //                "quantity_logged":quantity_logged,
                    "duration_logged":duration_logged,
                    "device_id":currentDeviceId,
                    "activity_sequence_id":activity_sequence_id,
                    "start_time": getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                    "finish_time": getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")//"2022-07-29T12:53:14.030Z"
                    
                ]
                
                if choice_id != nil{
                    json["choice_id"] = choice_id!
                }
                
                if quantity_logged != nil{
                    json["quantity_logged"] = quantity_logged!
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
                            addLog(text: "accessToken is:- \(token)")
                            completionHandler(nil)
                            return
                        }
                    }
       
                    
                    if error != nil {
                        addLog(text: "api call activityCompletedApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiActivityCompletedErrorFound{
                                self.isApiActivityCompletedErrorFound = false//Focus Bear was not able to sync the activities' statistics due to bad internet.
                                self.isAnyErrorFoundInActivityCompletedApi = true
                                completionHandler(nil)
                                return
                            }else{
                                self.isApiActivityCompletedErrorFound = true
                                addLog(text: "error activityCompletedApi:- try second time")

                                self.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, completionHandler: {dic  in
                                    
                                    completionHandler(dic)
                                    return
                                })
                            }
                        }else if (error as? NSError)?.code == self.errorCodeNoInternet{
                            self.isAnyErrorFoundInActivityCompletedApi = true
                            completionHandler(nil)//The Internet connection appears to be offline.
                            return
                        }else{//1009
                            completionHandler(nil)//The Internet connection appears to be offline.
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
    
    
    func activityCompletedReviseApi(activity_id:String, quantity_logged:Double , choice_id:String?, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- activityCompletedReviseApi:- completed-activity/revise/id")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            let id = choice_id ?? activity_id
            
            let responsePath = "https://api.focusbear.io/completed-activity/revise/\(id)"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call activity Completed Revise Api \(myUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "PATCH";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("mac-os", forHTTPHeaderField: "platform")
                request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                
                let json: [String: Any] = [
                    "quantity_logged":quantity_logged
                ]
                
                //            if choice_id != nil{
                //                json["choice_id"] = choice_id!
                //            }
                
                
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
                            addLog(text: "accessToken is:- \(token)")
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
                          
                                allApiObject.activityCompletedReviseApi(activity_id: activity_id, quantity_logged:quantity_logged, choice_id: choice_id, completionHandler: {dic  in
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

            
            let responsePath = "https://api.focusbear.io/completed-activity/skip"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call activitySkippedApi \(myUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("mac-os", forHTTPHeaderField: "platform")
                request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
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
//                            if data != nil{
//                                do {
//                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//                                        addLog(text: "api call activitySkippedApi success")
//                                        print("*************** activitySkippedApi response****************")
//                                        print(jsonResult)
//                                        print("***********************************************************")
//
//                                        completionHandler(jsonResult)
//                                        return
//                                    }
//
//                                }catch{
//                                    addLog(text: "api call activitySkippedApi succe:- \(error.localizedDescription)")
//                                    print(error)
//                                    completionHandler(nil)
//                                    return
//                                }
//                            }
                        }else{
                            addLog(text: "api call activitySkippedApi error:- statusCode is \(httpResponse.statusCode)")
                            self.writeJsonInLog(data: data)
                            addLog(text: "accessToken is:- \(token)")
                            completionHandler(nil)
                            return
                        }
                    }
       
                    
                    if error != nil {
                        addLog(text: "api call activitySkippedApi error:- \(error!.localizedDescription)")
                        if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                            if self.isApiActivitySkippedErrorFound{
                                self.isApiActivitySkippedErrorFound = false
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
    func forceCompleteCurrentSequence(activity_sequence_id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        addLog(text: "func call:- forceCompleteCurrentSequence:- completed-activity-sequence/activity_sequence_id/force-complete-current-sequence")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            let responsePath = "https://api.focusbear.io/completed-activity-sequence/\(activity_sequence_id)/force-complete-current-sequence"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call forceCompleteCurrentSequence \(myUrl)")
                let token = appdelegate!.credential?.accessToken ?? ""
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.addValue("mac-os", forHTTPHeaderField: "platform")
                request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let json: [String: Any] = [:]
                let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
                request.httpBody = jsonData
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        self.isApiForceCompleteCurrentSequenceErrorFound = false
                        if httpResponse.statusCode == 201{
                            
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
                            addLog(text: "accessToken is:- \(token)")
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
                                
                                self.forceCompleteCurrentSequence(activity_sequence_id: activity_sequence_id, completionHandler: {json in
                                    
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
    
    func getACtivityStats(activityId:String, activityChoiceId:String?, completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getACtivityStats:- completed-activity/id/stats")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let id = activityChoiceId ?? activityId
                
                
                let responsePath = "https://api.focusbear.io/completed-activity/\(id)/stats?days_number=30&timezone=UTC"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getActivityStats \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    //                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
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
                                            graphOneMonthData = jsonResult
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
                                addLog(text: "accessToken is:- \(token)")
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
                let shutOffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                let fromTime = getStringFromDateInUtc(date: startDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                let toTime = getStringFromDateInUtc(date: shutOffDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                
                
                let responsePath = "https://api.focusbear.io/completed-activity/\(id)?from_time=\(fromTime)&to_time=\(toTime)"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getACtivityCurrentDayStats \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    
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
                                addLog(text: "accessToken is:- \(token)")
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
    func getAllActivityDaySummary(completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        addLog(text: "func call:- getAllActivityDaySummary:- completed-activity/day-summary")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let zone = TimeZone.current
                let responsePath = "https://api.focusbear.io/completed-activity/day-summary?timezone=\(zone.identifier)"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call getAllActivityDaySummary \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "GET";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    
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
                                addLog(text: "accessToken is:- \(token)")
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
    func getAbortJsonToUpload(emailAddress:String?, feedback:String, abortReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
        addLog(text: "func call:- get Abort Json To Upload response")
        var settingsJson = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            if let data = stringDic.data(using: String.Encoding.utf8) {
                do {
                    settingsJson = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            settingsJson = dicResult
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        

        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["abortReason":abortReason, "settingsJSON":settingsJson, "macOSVersion":macOSVersion, "appVersion":appVersion, "feedback":feedback, "usageStartDate":myDateString]
        
        if emailAddress != nil{
            jsonResult["emailAddress"] = emailAddress!
        }
        
        
        
        let responsePath = webhookUrl
        if let myUrl = NSURL(string: responsePath){
            
            let request = NSMutableURLRequest(url:myUrl as URL);
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
                            addLog(text: "get Abort Json To Upload response - data is not nil")
                            let status = String(data: data!, encoding: .utf8)!
                            if status == "1"{
                                print("success")
                                addLog(text: "get Abort Json To Upload response - success")
                            }else{
                                addLog(text: "get Abort Json To Upload response - status is not 1")
                            }
                        }
                    }else{
                        addLog(text: "error get Abort Json To Upload response - error:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                    }
                    
                }
                
                if error != nil {
                    addLog(text: "get Abort Json To Upload response - error - \(error!.localizedDescription)")
                    completionHandler(jsonResult)
                    return
                }
                completionHandler(jsonResult)
                return;
            }
            task.resume()
        }else{
            //        isUploadingPopupResponse = false
            completionHandler(jsonResult)
        }
        
        
    }
    func getQuitJsonToUpload(emailAddress:String?, feedback:String, quitReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
        addLog(text: "func call:- get Quit Json To Upload")//
        var settingsJson = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            if let data = stringDic.data(using: String.Encoding.utf8) {
                do {
                    settingsJson = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            settingsJson = dicResult
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        
        
        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["quitReason":quitReason, "settingsJSON":settingsJson, "macOSVersion":macOSVersion, "appVersion":appVersion, "feedback":feedback, "usageStartDate":myDateString]
        
        if emailAddress != nil{
            jsonResult["emailAddress"] = emailAddress!
        }
        
        
        
        let responsePath = webhookUrl
        if let myUrl = NSURL(string: responsePath){
            
            let request = NSMutableURLRequest(url:myUrl as URL);
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
                            addLog(text: "get Quit Json To Upload response - success")
                            let status = String(data: data!, encoding: .utf8)!
                            if status == "1"{
                                print("success")
                                
                            }else{
                                addLog(text: "get Quit Json To Upload response - nil data")
                            }
                        }
                    }else{
                        addLog(text: "error in get Quit Json To Upload response - data nil:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                    }
                    
                }
                
                if error != nil {
                    addLog(text: "get Quit Json To Upload response - error - \(error!.localizedDescription)")
                    completionHandler(jsonResult)
                    return
                }
                completionHandler(jsonResult)
                return;
            }
            task.resume()
        }else{
            //        isUploadingPopupResponse = false
            completionHandler(jsonResult)
        }
        
        
    }
    
    
    func getUninstallJsonToUpload(emailAddress:String?, uninstallReason:String, uninstallDescription:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
        
        addLog(text: "func call:- get Uninstall Json To Upload")
        var settingsJson = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            if let data = stringDic.data(using: String.Encoding.utf8) {
                do {
                    settingsJson = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            settingsJson = dicResult
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        
   
        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["uninstallReason":uninstallReason, "uninstallDescription":uninstallDescription, "settingsJSON":settingsJson, "macOSVersion":macOSVersion, "appVersion":appVersion, "usageStartDate":myDateString]//, "feedback":feedback//

        if emailAddress != nil{
            jsonResult["emailAddress"] = emailAddress!
        }
        
        
        
        let responsePath = webhookUrl
        if let myUrl = NSURL(string: responsePath){
            
            let request = NSMutableURLRequest(url:myUrl as URL);
            request.httpMethod = "POST";
            
            let json = jsonResult//[[String: String]]()

            let jsonData = try? JSONSerialization.data(withJSONObject: json)
            //         let boundary = generateBoundaryString()
            //         let contentData = createBodyWithParameters(imageDataKey: folderData as? NSData ?? NSData(), boundary: boundary, jsonData: jsonData) as Data
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                // print(response)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200{

                        if data != nil{
                            addLog(text: "get Uninstall Json To Upload response - success")
                            let status = String(data: data!, encoding: .utf8)!
                            if status == "1"{
                                print("success")
                                
                            }else{
                                
                            }
                        }
                    }else{
                        addLog(text: "error in get Uninstall Json To Upload response - data nil:- statusCode is \(httpResponse.statusCode)")
                        self.writeJsonInLog(data: data)
                    }
                    
                }
                
                if error != nil {
                    addLog(text: "get Uninstall Json To Upload response - error - \(error!.localizedDescription)")
                    completionHandler(jsonResult)
                    return
                }
                completionHandler(jsonResult)
                return;
            }
            task.resume()
        }else{
            //        isUploadingPopupResponse = false
            completionHandler(jsonResult)
        }
        
        
    }
    func activateKey(license_key:String,completionHandler: @escaping(_ result: NSDictionary?) -> ()){// not in use
        //80F7CCF5-7FE54D41-B5A2DD9F-4A84B894
        //    isUploadingPopupResponse = true
        let responsePath = "https://api.gumroad.com/v2/licenses/verify?product_permalink=xdkkds&license_key=\(license_key)"
        if let myUrl = NSURL(string: responsePath){
            addLog(text: "api call getConfigFile \(myUrl)")
            let request = NSMutableURLRequest(url:myUrl as URL);
            request.httpMethod = "POST";
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            //        request.httpBody = jsonData
            
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200{
                        
                        if data != nil{
                            do {
                                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                    
                                    completionHandler(jsonResult)
                                    return
                                }
                                
                            }catch{
                                print(error)
                            }
                        }
                    }else{
                        completionHandler(nil)
                        return
                    }
                }
                
                if error != nil {
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
    
    func addFocusMode(focusType:[String:Any], completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:- addFocusMode:- focus-mode")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/focus-mode"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call addFocusMode \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "POST";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    var json: [String: Any] = [
                        "id":focusType["id"] as? String ?? "",
                        "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
                        "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
                        "name":focusType["name"] as? String ?? "",
                        "metadata": [:]
                    ]
                    
                    var dic = focusType
                    dic.removeValue(forKey: "name")
                    dic.removeValue(forKey: "id")
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
                                            completionHandler(jsonResult)
                                            return
                                        }
                                        
                                    }catch{
                                        addLog(text: "api call addFocusMode error:- \(error.localizedDescription)")
                                        completionHandler(nil)
                                        print(error)
                                        return;
                                    }
                                }
                            }else{
                                addLog(text: "api call addFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
                                completionHandler(nil)
                                return
                            }
                        }

                        
                        if error != nil {
                            addLog(text: "api call addFocusMode error:- \(error!.localizedDescription)")
                            if (error as? NSError)?.code == self.errorCodeRequestTimeout{
                                if self.isApiAddFocusModeErrorFound{
                                    self.isApiAddFocusModeErrorFound = false
                                    completionHandler(nil)
                                    return
                                }else{
                                    self.isApiAddFocusModeErrorFound = true
                                    addLog(text: "error addFocusMode:- try second time")
                                    
                                    self.addFocusMode(focusType: focusType, completionHandler: {newDic in
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
    func deleteFocusMode(id:String, completionHandler: @escaping(_ isDeleted:Bool) -> ()){
        addLog(text: "func call:- deleteFocusMode :- focus-mode")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                let responsePath = "https://api.focusbear.io/focus-mode?id=\(id)"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call deleteFocusMode \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "DELETE";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    //                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let task = URLSession.shared.dataTask(with: request as URLRequest) {
                        data, response, error in
                        
                        if let httpResponse = response as? HTTPURLResponse{
                            self.isApiDeleteFocusModeErrorFound = false
                            if httpResponse.statusCode == 200{ //it means it is right
                                addLog(text: "api call deleteFocusMode success")
                                completionHandler(true)
                                return
                                
                            }else{
                                addLog(text: "api call editFocusMode error:- statusCode is \(httpResponse.statusCode)")
                                self.writeJsonInLog(data: data)
                                addLog(text: "accessToken is:- \(token)")
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
                
                let responsePath = "https://api.focusbear.io/focus-mode/\(focusType["id"] as? String ?? "")"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call editFocusMode \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "PATCH";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    var json: [String: Any] = [
                        "allowed_urls":focusType["allowed_urls"] as? [String] ?? [],
                        "allowed_apps":focusType["allowed_apps"] as? [String] ?? [],
                        "name":focusType["name"] as? String ?? "",
                        "metadata": [:]
                    ]
                    
                    var dic = focusType
                    
                    dic.removeValue(forKey: "name")
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
                                addLog(text: "accessToken is:- \(token)")
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
    
    func startFocusMode(id:String,intention:String, start_time:Date, finish_time:Date, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:- startFocusMode:- focus-mode/id/start")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/focus-mode/\(id)/start"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call startFocusMode \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "POST";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    let json: [String: Any] = [
                        "intention":intention,
                        "finish_time":getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
                        "start_time":getStringFromDateInUtc(date: start_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
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
                                            addLog(text: "accessToken is:- \(token)")
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
                            //                        }else{
                            //                            completionHandler(nil)
                            //                            return
                            //                        }
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
    
    func finishFocusMode(id:String,achievements:String, distractions:String, finish_time:Date, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        addLog(text: "func call:-  finishFocusMode:- focus-mode/id/finish")
        
        appdelegate!.credentialsManager.credentials {credentialsInfo in
            addLog(text: "get updated credentialsInfo from credentialsManager")
            
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            
            if appdelegate!.credential != nil{
                
                let responsePath = "https://api.focusbear.io/focus-mode/\(id)/finish"
                if let myUrl = NSURL(string: responsePath){
                    addLog(text: "api call finishFocusMode \(myUrl)")
                    let token = appdelegate!.credential!.accessToken
                    
                    
                    let request = NSMutableURLRequest(url:myUrl as URL);
                    request.httpMethod = "POST";
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.addValue("mac-os", forHTTPHeaderField: "platform")
                    request.addValue(getAppVersionInString(), forHTTPHeaderField: "app-version")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    
                    var json: [String: Any] = [
                        "achievements":achievements,
                        "distractions":distractions,
                        "finish_time":getStringFromDateInUtc(date: finish_time, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                    ]
                    
                    
                    
                    
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
                                            addLog(text: "accessToken is:- \(token)")
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
    
                                    allApiObject.finishFocusMode(id: id, achievements: achievements, distractions: distractions, finish_time: finish_time, completionHandler: {newDic in
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
    
    func getForgotPassword(emailAddress:String,completionHandler: @escaping(_ result: String?) -> ()) {
        addLog(text: "func call:- getForgotPassword")//


        
        let jsonResult:NSMutableDictionary = ["client_id":"dgMrlNC5mM634Sxi9SLqIqi0WvgVpwX7", "email":emailAddress, "connection":"Username-Password-Authentication"]
        

        
        
        
        let responsePath = "https://dev-2hidr8ad.us.auth0.com/dbconnections/change_password"
        if let myUrl = NSURL(string: responsePath){
            
            let request = NSMutableURLRequest(url:myUrl as URL);
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
    
}













