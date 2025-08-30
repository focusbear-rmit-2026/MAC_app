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





//focus-block.html // python3 -m http.server 8000//http://localhost:8000




//import Network
//
//class localHost:NSObject{
//    // Define the port for the server
//    let port: UInt16 = 8000
//
//    func start(){
//        // Create a listener for incoming TCP connections
//        //        guard let listener = try? NWListener(using: .tcp, on: NWEndpoint.Port(rawValue: port)!) else{
//        //            return;
//        //        }
//        //        print("Server running on port \(port)...")
//        //
//        //        listener.newConnectionHandler = { connection in
//        //            connection.start(queue: .main)
//        //
//        //            connection.receiveMessage { (data, context, isComplete, error) in
//        //                guard let data = data, !data.isEmpty else {
//        //                    print("No data received.")
//        //                    return
//        //                }
//        //
//        //                // Parse HTTP request
//        //                if let request = String(data: data, encoding: .utf8) {
//        //                    print("Received request:\n\(request)")
//        //                }
//        //
//        //                // Prepare an HTTP response
//        //                let responseBody = "<html><body><h1>Welcome to Swift HTTP Server!</h1></body></html>"
//        //                let httpResponse =
//        //                """
//        //                HTTP/1.1 200 OK
//        //                Content-Type: text/html
//        //                Content-Length: \(responseBody.utf8.count)
//        //
//        //                \(responseBody)
//        //                """
//        //
//        //                // Send response
//        //                connection.send(content: httpResponse.data(using: .utf8), completion: .contentProcessed({ error in
//        //                    if let error = error {
//        //                        print("Failed to send response: \(error)")
//        //                    } else {
//        //                        print("Response sent successfully.")
//        //                    }
//        //                }))
//        //            }
//        //        }
//        //
//        //        // Start the listener
//        //        listener.start(queue: .main)
//        //
//        //        // Keep the server running
//        //        RunLoop.main.run()
//        //    }
//
//
//        do {
//            // Convert port to NWEndpoint.Port
//            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
//                print("Invalid port number: \(port)")
//                exit(1)//
//            }
//
//            // Create the NWListener
//            let listener = try NWListener(using: .tcp, on: nwPort)
//            print("Server attempting to start on port \(port)...")
//
//            listener.stateUpdateHandler = { state in
//                switch state {
//                case .ready:
//                    print("Server is ready and listening on port \(self.port).")
//                case .failed(let error):
//                    print("Listener failed with error: \(error.localizedDescription)")
//                case .waiting(let error):
//                    print("Listener is waiting with error: \(error.localizedDescription)")
//                case .cancelled:
//                    print("Listener has been cancelled.")
//                default:
//                    break
//                }
//            }
//
//            // Handle new connections
//            listener.newConnectionHandler = { connection in
//                print("New connection received!")
////                connection.start(queue: .main)
//                connection.start(queue: DispatchQueue.global(qos: .background))
//                connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { (data, context, isComplete, error) in
//                    if let error = error {
//                        print("Error receiving message: \(error.localizedDescription)")
//                        return
//                    }
//
//                    guard let data = data, let request = String(data: data, encoding: .utf8) else {
//                        print("No valid data received.")
//                        return
//                    }
//
//                    self.handleRequest(request, connection: connection)
//
//
//                }
//
//                connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
//                    if let error = error {
//                        print("Error receiving message: \(error.localizedDescription)")
//                        return
//                    }
//
//                    guard let data = data, !data.isEmpty else {
//                        print("No data received.")
//                        return
//                    }
//
//                    // Process received data
//                    if let request = String(data: data, encoding: .utf8) {
//                        print("Received request:\n\(request)")
//                    }
//                }
//            }
//
//            // Start the listener
////            listener.start(queue: .main)
//
//
//
//            let backgroundQueue = DispatchQueue.global(qos: .background)
//            listener.start(queue: backgroundQueue)
//            print("Listener started on background queue, awaiting connections...")
//
//
//
//
//
//
//
//            // Keep the server running
//           // RunLoop.main.run()
//
//        } catch {
//            print("Failed to start the server: \(error.localizedDescription)")
//            exit(1)// 
//        }
//
//    }//file:///Users/manish/Library/Application%20Support/com.App.EarnYourScreentime/focus-block.html?old_url=https%3A%2F%2Fwww.facebook.com%2F&block_type=always-blocked&block_mode=cuddly&encouraging_info=%7B%0A%20%20%22focused_time%22%20%3A%202367.366,%0A%20%20%22long_term_goals%22%20%3A%20%5B%0A%20%20%20%20%22Meditate%20consistently%22%0A%20%20%5D%0A%7D&version=1.21.354
//
//
//    //http://localhost:8000/open?file=/Users/manish/Library/Application%20Support/com.App.EarnYourScreentime/focus-block.html?old_url=https%3A%2F%2Fwww.facebook.com%2F&block_type=always-blocked&block_mode=cuddly&encouraging_info=%7B%0A%20%20%22focused_time%22%20%3A%202367.366,%0A%20%20%22long_term_goals%22%20%3A%20%5B%0A%20%20%20%20%22Meditate%20consistently%22%0A%20%20%5D%0A%7D&version=1.21.354
//
////    private func handleRequest(_ request: String, connection: NWConnection) {
////            print("Received request:\n\(request)")
////
////            // Extract requested file path from HTTP request
//////            let lines = request.split(separator: "\n")
//////            guard let firstLine = lines.first else { return }
//////            let components = firstLine.split(separator: " ")
//////
//////            guard components.count > 1, components[0] == "GET" else {
//////                send404Response(connection)
//////                return
//////            }
//////
//////            let urlPath = String(components[1]).removingPercentEncoding ?? "/"
//////
//////            // Check if the request is for a local file
//////            if urlPath.hasPrefix("/open?file=") {
//////                let filePath = urlPath.replacingOccurrences(of: "/open?file=", with: "")
//////                serveFile(at: filePath, connection: connection)
//////            } else {
//////                send404Response(connection)
//////            }
////
////        guard let firstLine = request.components(separatedBy: "\n").first,
////                  firstLine.starts(with: "GET ") else {
////                send404Response(connection)
////                return
////            }
////
////            // Extract the full URL path (e.g., /Users/you/Desktop/file.html?abc=123)
////            let pathWithParams = firstLine.components(separatedBy: " ")[1]
////
////            // Split the path and query
////            let split = pathWithParams.components(separatedBy: "?")
////            let encodedPath = split[0]
////
////            // Decode percent encoding to get actual file path
////            guard let decodedPath = encodedPath.removingPercentEncoding else {
////                send404Response(connection)
////                return
////            }
////
////            // Serve the file
////            serveFile(at: decodedPath, connection: connection)
////
////        }
//
//
//    private func handleRequest(_ request: String, connection: NWConnection) {
//        guard let firstLine = request.components(separatedBy: "\n").first,
//              firstLine.starts(with: "GET ") else {
//            send404Response(connection)
//            return
//        }
//
//        let pathWithParams = firstLine.components(separatedBy: " ")[1]
//        let split = pathWithParams.components(separatedBy: "?")
//        let encodedPath = split[0]
//
//        guard let decodedPath = encodedPath.removingPercentEncoding else {
//            send404Response(connection)
//            return
//        }
//
//        serveFile(at: decodedPath, connection: connection)
//    }
//
//    private func getContentType(for pathExtension: String) -> String {
//        switch pathExtension.lowercased() {
//            case "html": return "text/html"
//            case "css": return "text/css"
//            case "js": return "application/javascript"
//            case "json": return "application/json"
//            case "png": return "image/png"
//            case "jpg", "jpeg": return "image/jpeg"
//            case "gif": return "image/gif"
//            case "svg": return "image/svg+xml"
//            default: return "application/octet-stream"
//        }
//    }
//
////    private func serveFile(at filePath: String, connection: NWConnection) {
////           let fileURL = URL(fileURLWithPath: filePath)
////
////           if FileManager.default.fileExists(atPath: fileURL.path) {
////               do {
////                   let fileData = try Data(contentsOf: fileURL)
////                   let contentType = getContentType(for: fileURL.pathExtension)
////
////                   let httpResponse =
////                   """
////                   HTTP/1.1 200 OK
////                   Content-Type: \(contentType)
////                   Content-Length: \(fileData.count)
////
////                   """.data(using: .utf8)! + fileData
////
//////                   connection.send(content: httpResponse, completion: .contentProcessed({ _ in
//////                       connection.cancel()
//////                   }))
////                   // Send response
////                   connection.send(content: httpResponse, completion: .contentProcessed({ error in
////                       if let error = error {
////                           print("Failed to send response: \(error)")
////                       } else {
////                           print("Response sent successfully.")
////                           connection.cancel()
////                       }
////                   }))
////
//////                   connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
//////                       if let error = error {
//////                           print("Error receiving message: \(error.localizedDescription)")
//////                           return
//////                       }
//////
//////                       guard let data = data, !data.isEmpty else {
//////                           print("No data received.")
//////                           return
//////                       }
//////
//////                       // Process received data
//////                       if let request = String(data: data, encoding: .utf8) {
//////                           print("Received request:\n\(request)")
//////                       }
//////                   }
////               } catch {
////                   print("Error reading file: \(error.localizedDescription)")
////                   send404Response(connection)
////               }
////           } else {
////               send404Response(connection)
////           }
////       }
//
//    private func serveFile(at filePath: String, connection: NWConnection) {
//        let fileURL = URL(fileURLWithPath: filePath)
//        print(filePath)
//
//        if FileManager.default.fileExists(atPath: fileURL.path) {
//            do {
//                let fileData = try Data(contentsOf: fileURL)
//                let contentType = getContentType(for: fileURL.pathExtension)
//
//                let httpResponse =
//                """
//                HTTP/1.1 200 OK
//                Content-Type: \(contentType)
//                Content-Length: \(fileData.count)
//
//                """.data(using: .utf8)! + fileData
//
//                connection.send(content: httpResponse, completion: .contentProcessed({ error in
//                    if let error = error {
//                        print("Failed to send response: \(error)")
//                    } else {
//                        print("Response sent successfully for file: \(fileURL.lastPathComponent)")
//                    }
//                    connection.cancel()
//                }))
//            } catch {
//                print("Error reading file: \(error)")
//                send404Response(connection)
//            }
//        } else {
//            print("File not found: \(filePath)")
//            send404Response(connection)
//        }
//    }
//
//       private func send404Response(_ connection: NWConnection) {
//           let response =
//           """
//           HTTP/1.1 404 Not Found
//           Content-Type: text/html
//
//           <html><body><h1>404 Not Found</h1></body></html>
//           """.data(using: .utf8)
//
//           connection.send(content: response, completion: .contentProcessed({ _ in
//               connection.cancel()
//           }))
//       }
//
////       private func getContentType(for fileExtension: String) -> String {
////           switch fileExtension.lowercased() {
////           case "html": return "text/html"
////           case "css": return "text/css"
////           case "js": return "application/javascript"
////           case "png": return "image/png"
////           case "jpg", "jpeg": return "image/jpeg"
////           case "gif": return "image/gif"
////           case "json": return "application/json"
////           case "txt": return "text/plain"
////           default: return "application/octet-stream"
////           }
////       }
//}




//old morning habit check work

//                                            //
//                                            if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
//                                                if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
//                                                    if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
//
//                                                        if let currentActivity = json?.value(forKey: "current_activity") as? NSDictionary{
//                                                            if let sequenceId = currentActivitySequence.value(forKey: "id") as? String, let activityId = currentActivity.value(forKey: "id") as? String{
//
//                                                                if let habitSequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
//
//
//
//                                                                    if activityAssignedDate.compare(startDate) == .orderedDescending{//if activityAssignedDate > startDate
//                                                                        // morning activity start hui thi lekin puri nahi hui hai
//                                                                        if habitSequenceID == sequenceId{
//                                                                            //                print("current_activity_sequence is pending")
//                                                                            addLog(text: "morning habit sequnce is pending. start from current pending habit")
//                                                                            self.isProcessingHabitRoutine = false
//                                                                            var skippedActivities = [String]()
//                                                                            if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
//                                                                                skippedActivities = activities
//                                                                            }//current_sequence_completed_activities
//
//                                                                            var completedActivities = [String]()
//                                                                            if let activities = json?.value(forKey: "current_sequence_completed_activities") as? [String]{
//                                                                                completedActivities = activities
//                                                                            }
//                                                                            self.startHabitsCall(activityId: activityId, skippedActivities:skippedActivities, completedActivities: completedActivities)
//                                                                        }else{//it means current activity is not morning habit and morning habit done for today
//                                                                            addLog(text: "current activity is not morning habit and it means morning habit done for today")//
//                                                                            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
//
//                                                                            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
//
//                                                                            isHabitAlreadyShowed = true
//                                                                            self.isProcessingHabitRoutine = false
//                                                                            if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
//                                                                                self.abortAllProcess()
//                                                                                mainWindowControllerObj?.window?.close()
//                                                                                hideBlankWindowInSecondaryMonitor()
//                                                                            }
//                                                                            currentState = ._NOTHING_
//                                                                            mainWindowControllerObj?.loadWindow()
//                                                                            getHabitsVcObject().setActivityTimer()
//
//                                                                            allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
//
//
//                                                                                DispatchQueue.main.async {
//
//                                                                                }
//                                                                            })
//
//                                                                        }
//                                                                    }
//                                                                    else{//
//                                                                        //                print("pending routin is not from current day clean all running sequence")
//                                                                        addLog(text: "pending routin is not from current day clean all running sequence")
//                                                                        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: false, completionHandler: {json in
//
//
//                                                                            DispatchQueue.main.async {
//                                                                                addLog(text: "start new morning routine sequence")
//                                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                                                self.isProcessingHabitRoutine = false
//                                                                            }
//                                                                        })
//                                                                    }
//
//                                                                }
//                                                            }else{
//                                                                addLog(text: "start new morning routine sequence:- current sequence Id or current activity Id not found")
//                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                                self.isProcessingHabitRoutine = false
//                                                            }
//                                                        }else{
//                                                            addLog(text: "start new morning routine sequence:- current_activity not found as dictionary")// ktyaa krna chahiye yha
//                                                            //
//                                                            var isForToday = false
//                                                            if activityAssignedDate.compare(startDate) == .orderedDescending{
//                                                                isForToday = true
//                                                            }
//                                                            if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
//                                                                addLog(text: "pending routin is not for use clean all running sequence")
//                                                                allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
//
//
//                                                                    DispatchQueue.main.async {
//                                                                        addLog(text: "start new morning routine sequence")
//                                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                                        self.isProcessingHabitRoutine = false
//                                                                    }
//                                                                })
//                                                            }else{
//                                                                addLog(text: "start new morning routine sequence")
//                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                                self.isProcessingHabitRoutine = false
//                                                            }
//                                                        }
//                                                    }else{
//                                                        addLog(text: "start new morning routine sequence:- current_activity_sequence not found as dictionary")
//                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                        self.isProcessingHabitRoutine = false
//                                                    }
//                                                }else{
//                                                    addLog(text: "start new morning routine sequence:- can't create Date object from current_activity_assigned_at")
//                                                    self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                    self.isProcessingHabitRoutine = false
//                                                }
//                                            }else{
//                                                addLog(text: "start new morning routine sequence :- current_activity_assigned_at not found :- \(json!)")
//                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
//                                                self.isProcessingHabitRoutine = false
//                                            }
//
//                                            self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])//
//                                            self.isProcessingHabitRoutine = false




// old evening habit check work

//
//                        if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
//                            if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
//                                if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
//
//                                    if let currentActivity = json?.value(forKey: "current_activity") as? NSDictionary{
//                                        if let sequenceId = currentActivitySequence.value(forKey: "id") as? String, let activityId = currentActivity.value(forKey: "id") as? String{
//
//
//
//                                            addLog(text: "processEveningHabit - pending sequence id - \(sequenceId)")
//                                            if let habitSequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
//
//
//                                                if activityAssignedDate.compare(shutoffDate) == .orderedDescending && habitSequenceID == sequenceId{//if activityAssignedDate > shutoffDate
//                                                    // evening activity started but not completed
//
//                                                    if habitSequenceID == sequenceId{
//                                                        //                print("current evening routine sequence is pending")
//                                                        addLog(text: "current evening routine sequence is pending")
//                                                        self.isProcessingHabitRoutine = false
//                                                        var skippedActivities = [String]()
//                                                        if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
//                                                            skippedActivities = activities
//                                                        }
//                                                        var completedActivities = [String]()
//                                                        if let activities = json?.value(forKey: "current_sequence_completed_activities") as? [String]{
//                                                            completedActivities = activities
//                                                        }
//                                                        self.showEveningHabit(activityId: activityId, skippedActivities: skippedActivities, completedActivities: completedActivities)
//                                                    }else{
//
//                                                        addLog(text: "pending routine is not evening routine - \(sequenceId)")
//                                                        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
//                                                            // and strt break activity
//                                                            DispatchQueue.main.async {
//                                                                addLog(text: "start new evening routine sequence")
//                                                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                                                self.isProcessingHabitRoutine = false
//                                                            }
//                                                        })
//                                                    }
//
//                                                }else{
//                                                    //                print("processEveningHabit - pending  routine is not from current day clean all running sequence or pending sequence is not evening routine - \(sequenceId)")
//                                                    addLog(text: "processEveningHabit - pending  routine is not from current day clean all running sequence or pending sequence is not evening routine - \(sequenceId)")
//
//                                                    var isForToday = false
//                                                    if activityAssignedDate.compare(shutoffDate) == .orderedDescending{
//                                                        isForToday = true
//                                                    }
//
//                                                    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
//                                                        // and strt break activity
//                                                        DispatchQueue.main.async {
//                                                            addLog(text: "start new evening routine sequence")
//                                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                                            self.isProcessingHabitRoutine = false
//                                                        }
//                                                    })
//                                                }
//                                            }
//
//                                        }else{
//                                            addLog(text: "start new evening routine sequence:- current sequence Id or current activity Id not found")
//                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                            self.isProcessingHabitRoutine = false
//                                        }
//                                    }else{
//                                        addLog(text: "start new evening routine sequense:- current_activity not found as dictionary")
//
//                                        if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
//                                            addLog(text: "pending routin is not for use clean all running sequence")
//
//                                            var isForToday = false
//                                            if activityAssignedDate.compare(shutoffDate) == .orderedDescending{
//                                                isForToday = true
//                                            }
//
//
//                                            allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
//                                                // and strt break activity
//                                                DispatchQueue.main.async {
//                                                    addLog(text: "start new evening routine sequence")
//                                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                                    self.isProcessingHabitRoutine = false
//                                                }
//                                            })
//
//                                        }else{
//                                            addLog(text: "start new evening routine sequence")
//                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                            self.isProcessingHabitRoutine = false
//                                        }
//                                    }
//                                }else{
//                                    addLog(text: "start new evening routine sequense:- current_activity_sequence not found as dictionary")
//                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                    self.isProcessingHabitRoutine = false
//                                }
//                            }else{
//                                addLog(text: "start new evening routine sequence:- can't create Date object from current_activity_assigned_at")
//                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                                self.isProcessingHabitRoutine = false
//                            }
//                        }else{
//                            addLog(text: "start new evening routine sequence :- current_activity_assigned_at not found :- \(json!)")
//                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
//                            self.isProcessingHabitRoutine = false
//                        }

/*
 
 //        let args = CommandLine.arguments
 //        print("Command-line arguments: \(args)")
 //        for param in args{
 //            if param.contains("baseUrl="){
 //                baseUrl = param.replacingOccurrences(of: "baseUrl=", with: "")
 //                let alert = NSAlert()
 //                alert.messageText = baseUrl
 //                alert.runModal()
 //                break;
 //            }
 //        }
 */
//        let url:String? = "https://www.youtube.com/watch?v=j8Hkh-x2cKw"
//        let url:String? = "https://vimeo.com/1113240264?fl=wc"
//        url = "https://player.vimeo.com/video/1113240264"
