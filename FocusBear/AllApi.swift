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
        addLog(text: "downloading config file")
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
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/user-settings"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call isSettingsValid \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "PUT";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let jsonData = try? JSONSerialization.data(withJSONObject: settings)
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse{
                        //                    if httpResponse.statusCode == 200{ //it means it is right
                        
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
                        //                    }else{
                        //                        completionHandler(nil)
                        //                        return
                        //                    }
                    }
                    //            isUploadingPopupResponse = false
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
    
    
    func getDeviceId(completionHandler: @escaping(_ deviceId:String?) -> ()){
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/device"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getDeviceId \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                            completionHandler(nil)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call getDeviceId error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
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
    
    func getSettings(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "downloading Settings file")
        if appdelegate!.credential != nil{
            let responsePath = "https://api.focusbear.io/user-settings"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getSettings \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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

    func getUserLocalDeviceSettings(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "downloading user-local-device-settings file")
        if appdelegate!.credential != nil{
            let responsePath = "https://api.focusbear.io/user-local-device-settings"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getSettings \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
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
                            completionHandler(nil)
                            return
                        }
                    }
                    if error != nil {
                        addLog(text: "error user-local-device-settings file: \(error!.localizedDescription)")
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
    func getLastActivityInfo(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "downloading getLastActivityInfo file")
        if appdelegate!.credential != nil{
            let responsePath = "https://api.focusbear.io/user/details/current-activity-props"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getLastActivityInfo \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
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
                            completionHandler(nil)
                            return
                        }
                    }
                    if error != nil {
                        addLog(text: "error getLastActivityInfo: \(error!.localizedDescription)")
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
    
    func getuserDetailsInfo(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
        addLog(text: "downloading getuserDetailsInfo file")
        if appdelegate!.credential != nil{
            let responsePath = "https://api.focusbear.io/user/details"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getuserDetailsInfo \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse {
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
                            completionHandler(nil)
                            return
                        }
                    }
                    if error != nil {
                        addLog(text: "error getuserDetailsInfo: \(error!.localizedDescription)")
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
    func putUserLocalDeviceSettings(settings:[String: [String:Any]], completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        if appdelegate!.credential != nil{

            let responsePath = "https://api.focusbear.io/user-local-device-settings"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call putUserLocalDeviceSettings \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "PUT";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                let jsonData = try? JSONSerialization.data(withJSONObject: settings)
                request.httpBody = jsonData
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse{
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
                        }
                    }
                    if error != nil {
                        addLog(text: "api call putUserLocalDeviceSettings return error:- \(error!.localizedDescription)")
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
    func activityCompletedApi(activity_id:String, activity_sequence_id:String, start_time:Date, quantity_logged:Double?, duration_logged:Int, choice_id:String?, completionHandler: @escaping(_ result: NSDictionary?) -> ()){
        //80F7CCF5-7FE54D41-B5A2DD9F-4A84B894
        //    isUploadingPopupResponse = true
        

        let calendar = Calendar.current
        let finish_time = calendar.date(byAdding: .second, value: duration_logged, to: start_time) ?? Date()
        
        let responsePath = "https://api.focusbear.io/completed-activity"
        if let myUrl = NSURL(string: responsePath){
            addLog(text: "api call activityCompletedApi \(myUrl)")
            let token = appdelegate!.credential?.accessToken ?? ""
            
            let request = NSMutableURLRequest(url:myUrl as URL);
            request.httpMethod = "POST";
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
    //                if httpResponse.statusCode == 200{
                        
                        if data != nil{
                            do {
                                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                    addLog(text: "api call activityCompletedApi success")
                                    print("*************** Activity completed response****************")
                                    print(jsonResult)
                                    print("***********************************************************")
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
    //                }else{
    //                    completionHandler(nil)
    //                    return
    //                }
                }
                //            isUploadingPopupResponse = false
                if error != nil {
                    addLog(text: "api call activityCompletedApi error:- \(error!.localizedDescription)")
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
    func forceCompleteCurrentSequence(activity_sequence_id:String, completionHandler: @escaping(_ result: NSDictionary?) -> ()){

        let responsePath = "https://api.focusbear.io/completed-activity-sequence/\(activity_sequence_id)/force-complete-current-sequence"
        if let myUrl = NSURL(string: responsePath){
            addLog(text: "api call forceCompleteCurrentSequence \(myUrl)")
            let token = appdelegate!.credential?.accessToken ?? ""
            
            let request = NSMutableURLRequest(url:myUrl as URL);
            request.httpMethod = "POST";
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let json: [String: Any] = [:]
            let jsonData = try? JSONSerialization.data(withJSONObject: json)
                
                
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if let httpResponse = response as? HTTPURLResponse {
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
                        completionHandler(nil)
                        return
                    }
                }
                //            isUploadingPopupResponse = false
                if error != nil {
                    addLog(text: "api call forceCompleteCurrentSequence error:- \(error!.localizedDescription)")
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
    func getACtivityStats(activityId:String, activityChoiceId:String?, completionHandler: @escaping(_ stats:NSDictionary?) -> ()){
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            let id = activityChoiceId ?? activityId
            
            
            let responsePath = "https://api.focusbear.io/completed-activity/\(id)/stats?days_number=30&timezone=UTC"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getActivityStats \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse{
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
                            completionHandler(nil)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call getActivityStats error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
                }
                
                task.resume()
            }else{
                completionHandler(nil)
                return
            }
            
        }else{
            completionHandler(nil)
        }
    }
    
    func getACtivityCurrentDayStats(activityId:String, activityChoiceId:String?, completionHandler: @escaping(_ stats:[NSDictionary]?) -> ()){
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let id = activityChoiceId ?? activityId
            
            
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!

            let fromTime = getStringFromDateInUtc(date: startDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            let toTime = getStringFromDateInUtc(date: shutOffDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            
            
            let responsePath = "https://api.focusbear.io/completed-activity/\(id)?from_time=\(fromTime)&to_time=\(toTime)"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call getActivityStats \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "GET";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{ //it means it is right
                            if data != nil{
                                do {
                                    if let jsonResult: [NSDictionary] = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? [NSDictionary]{
                                        print(jsonResult)
                                        addLog(text: "api call getActivityStats success")
                                        graphOneDayData = jsonResult//
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
                            completionHandler(nil)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call getActivityStats error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
                }
                
                task.resume()
            }else{
                completionHandler(nil)
                return
            }
            
        }else{
            completionHandler(nil)
        }
    }
    func getAbortJsonToUpload(emailAddress:String?, feedback:String, abortReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
        addLog(text: "get Abort Json To Upload response - error")
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
        
        let systemVersion = ProcessInfo().operatingSystemVersion
        let version = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["abortReason":abortReason, "settingsJSON":settingsJson, "macOSVersion":version, "feedback":feedback, "usageStartDate":myDateString]
        
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
                            addLog(text: "get Abort Json To Upload response - success")
                            let status = String(data: data!, encoding: .utf8)!
                            if status == "1"{
                                print("success")
                                
                            }else{
                                addLog(text: "get Abort Json To Upload response - data nil")
                            }
                        }
                    }else{
                        addLog(text: "get Abort Json To Upload response - error")
                    }
                    
                }
                //            isUploadingPopupResponse = false
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
        addLog(text: "get Quit Json To Upload response - success")
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
        
        let systemVersion = ProcessInfo().operatingSystemVersion
        let version = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["quitReason":quitReason, "settingsJSON":settingsJson, "macOSVersion":version, "feedback":feedback, "usageStartDate":myDateString]
        
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
                            addLog(text: "get Quit Json To Upload response - success")
                            let status = String(data: data!, encoding: .utf8)!
                            if status == "1"{
                                print("success")
                                
                            }else{
                                addLog(text: "get Quit Json To Upload response - nil data")
                            }
                        }
                    }else{
                        addLog(text: "get Quit Json To Upload response - error")
                    }
                    
                }
                //            isUploadingPopupResponse = false
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
    
    
    func getUninstallJsonToUpload(emailAddress:String?, uninstallReason:String,completionHandler: @escaping(_ result: NSDictionary) -> ()) {
        
        addLog(text: "get Uninstall Json To Upload")
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
        
        let systemVersion = ProcessInfo().operatingSystemVersion
        let version = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        
        let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let myDateString = formatter.string(from: firstRunDate)
        
        let jsonResult:NSMutableDictionary = ["uninstallReason":uninstallReason, "settingsJSON":settingsJson, "macOSVersion":version, "usageStartDate":myDateString]//, "feedback":feedback
        
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
                        addLog(text: "get Uninstall Json To Upload response - data nil")
                    }
                    
                }
                //            isUploadingPopupResponse = false
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
    func activateKey(license_key:String,completionHandler: @escaping(_ result: NSDictionary?) -> ()){
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
                //            isUploadingPopupResponse = false
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
        if appdelegate!.credential != nil{
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/focus-mode"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call addFocusMode \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                        if httpResponse.statusCode == 201{ //it means it is right
                            
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                       // if let id = jsonResult.value(forKey: "id") as? String{
                                            
                                        addLog(text: "api call addFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                            
                                      //  }
                                        
                                    }
                                    
                                }catch{
                                    addLog(text: "api call addFocusMode error:- \(error.localizedDescription)")
                                    completionHandler(nil)
                                    print(error)
                                    return;
                                }
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call addFocusMode error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
                }
                
                task.resume()
            }else{
           
            }
            
        }else{
            completionHandler(nil)
        }
    }
    func deleteFocusMode(id:String, completionHandler: @escaping(_ isDeleted:Bool) -> ()){
        if appdelegate!.credential != nil{
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/focus-mode?id=\(id)"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call deleteFocusMode \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "DELETE";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if let httpResponse = response as? HTTPURLResponse{
                        if httpResponse.statusCode == 200{ //it means it is right
                            addLog(text: "api call deleteFocusMode success")
                            completionHandler(true)
                            return
                            
                        }else{
                            completionHandler(false)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call deleteFocusMode error:- \(error!.localizedDescription)")
                        completionHandler(false)
                        return
                    }
                    completionHandler(false)
                    return
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
    
    func editFocusMode(focusType:[String:Any], completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        if appdelegate!.credential != nil{

            let responsePath = "https://api.focusbear.io/focus-mode/\(focusType["id"] as? String ?? "")"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call editFocusMode \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "PATCH";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                        if httpResponse.statusCode == 200{ //it means it is right
                            
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                       // if let id = jsonResult.value(forKey: "id") as? String{
                                            
                                        addLog(text: "api call editFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                            
                                      //  }
                                        
                                    }
                                    
                                }catch{
                                    addLog(text: "api call editFocusMode error:- \(error.localizedDescription)")
                                    completionHandler(nil)
                                    print(error)
                                    return;
                                }
                            }
                        }else{
                            completionHandler(nil)
                            return
                        }
                    }
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call editFocusMode error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
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
    
    func startFocusMode(id:String,intention:String, start_time:Date, finish_time:Date, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/focus-mode/\(id)/start"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call startFocusMode \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                
                var json: [String: Any] = [
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
                            
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                       // if let id = jsonResult.value(forKey: "id") as? String{
                                            
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call startFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }else{
                                            addLog(text: "api call startFocusMode error")
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
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call startFocusMode error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
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
    
    func finishFocusMode(id:String,achievements:String, distractions:String, finish_time:Date, completionHandler: @escaping(_ newDic:NSDictionary?) -> ()){
        if appdelegate!.credential != nil{
            
            
            // Valid credentials; you can access token properties such as `idToken`, `accessToken`.
            //        print(credentials)
            
            let responsePath = "https://api.focusbear.io/focus-mode/\(id)/finish"
            if let myUrl = NSURL(string: responsePath){
                addLog(text: "api call finishFocusMode \(myUrl)")
                let token = appdelegate!.credential!.accessToken
                
                
                let request = NSMutableURLRequest(url:myUrl as URL);
                request.httpMethod = "POST";
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
                            
                            if data != nil{
                                do {
                                    if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
                                        
                                        
                                       // if let id = jsonResult.value(forKey: "id") as? String{
                                        if httpResponse.statusCode == 201{
                                            addLog(text: "api call finishFocusMode success")
                                            completionHandler(jsonResult)
                                            return
                                        }else{
                                            addLog(text: "api call finishFocusMode error")
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
                    //            isUploadingPopupResponse = false
                    if error != nil {
                        addLog(text: "api call finishFocusMode error:- \(error!.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    completionHandler(nil)
                    return
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









