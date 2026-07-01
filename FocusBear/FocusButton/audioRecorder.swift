//
//  AudioRecorder.swift
//  FocusBear
//
//  Created by Manish Jain on 11/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import AVFAudio
import AVFoundation
import CoreAudio

class audioRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate{
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    
    var isRecording: Bool = false
    
    var audioFilename: URL?
    var isPermissionGiven = false
    var isFloatingBarVisibleBeforeShowingGif = false
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    //Initialize the Audio Recorder Session
    private func setupAudioEngine() {
        addLog(text: "setupAudioEngine()")
        
        audioEngine = AVAudioEngine()
    }
    
    // Public method to request permission and start recording
    func requestPermissionAndStartRecording() {
        addLog(text: "requestPermissionAndStartRecording()")
        
        if isPermissionGiven{
            addLog(text: "Permission already granted")
            startRecording()
            return;
        }
        
        // Check microphone permission on macOS
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            // Permission already granted
            addLog(text: "Permission already granted")
            isPermissionGiven = true
            startRecording()
            
        case .denied, .restricted:
            // Permission denied or restricted
            addLog(text: "Permission denied or restricted")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: VoiceEvents.permissionDenied, object: nil)
            }

        case .notDetermined:
            // Request permission
            addLog(text: "Requesting microphone permission")
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        addLog(text: "Permission granted by user")
                        self?.startRecording()
                    } else {
                        addLog(text: "Permission denied by user")
                        NotificationCenter.default.post(name: VoiceEvents.permissionDenied, object: nil)
                    }
                }
            }
        @unknown default:
            addLog(text: "Unknown permission status")
        }
    }
    
    /// Whether the system has a real default audio input device. AVAudioEngine reports a phantom input
    /// format when none is connected, so we check Core Audio's default-input-device property directly:
    /// it's kAudioObjectUnknown when there's nothing to record from.
    private func hasDefaultInputDevice() -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster)
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                                &address, 0, nil, &size, &deviceID)
        return status == noErr && deviceID != kAudioObjectUnknown
    }

    //Function to Start Recording
    private func startRecording() {
        addLog(text:"startRecording() ")
        guard let audioEngine = audioEngine else {
            addLog(text:"Audio engine not initialized")
            return
        }
        
        // With no input device, AVAudioEngine still reports a phantom input format (e.g. 2ch / 44100),
        // so the format alone can't tell us a mic is missing — but engine.start()/installTap then aborts
        // with "Input HW format is invalid". Ask Core Audio whether a real default input device exists
        // and bail out gracefully (surfacing a message to the menu) when there isn't one.
        guard hasDefaultInputDevice() else {
            addLog(text: "No microphone input device available (no default input device)")
            isRecording = false
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: VoiceEvents.error, object: nil,
                                                userInfo: ["text": "No microphone found. Connect a microphone and try again."])
            }
            return
        }

        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)

        audioFilename = applicationSupportURL!.appendingPathComponent("recording.wav")
        
        if let audioFilename = audioFilename{
            do {
                
                // Delete existing file if it exists
                if FileManager.default.fileExists(atPath: audioFilename.path) {
                    try FileManager.default.removeItem(at: audioFilename)
                }
                
                audioFile = try AVAudioFile(forWriting: audioFilename, settings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: recordingFormat.sampleRate,
                    AVNumberOfChannelsKey: recordingFormat.channelCount,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsFloatKey: false
                ])
            } catch {
                addLog(text:"Error setting up audio file: \(error)")
                return
            }
            
            isRecording = true
            
            startAudioEngine()
        }
        
        isFloatingBarVisibleBeforeShowingGif = false
        if floatingTopBarWcObj != nil{
            if getFloatingTopBarWObject().window?.isVisible ?? false{
                if !getFloatingTopBarVObject().boxMain.isHidden{
                    isFloatingBarVisibleBeforeShowingGif = true
                }
            }
        }
        
        // show // close floating bar is shown for gif
        if floatingTopBarVcObj != nil {
            floatingTopBarVcObj?.boxMain.isHidden = false
            floatingTopBarVcObj?.boxMoreItems.isHidden = false
        }else{
            if let frame = appdelegate?.statusbutton?.window?.frame{
                let leading = frame.midX
                
                showFloatingTopBarWindow(windowTopMidPoint: (NSPoint(x: leading, y: frame.maxY - 24)))
            }else{
                if let screenFrame = NSScreen.main?.frame{
                    showFloatingTopBarWindow(windowTopMidPoint: (NSPoint(x: screenFrame.width - 350, y: screenFrame.height - 34)))
                }
            }
        }
        floatingTopBarVcObj?.showRecordingGif()
    }
    
    private func startAudioEngine() {
        addLog(text:"startAudioEngine()")
        
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.processBuffer(buffer)
        }
        
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
                addLog(text: "Audio engine started successfully")
            } catch {
                addLog(text:"Error starting audio engine: \(error)")
                isRecording = false
            }
        }
    }
    
    //function to writing the Audio buffers being recorded to the audio file
     private func processBuffer(_ buffer: AVAudioPCMBuffer) {
         if(isRecording)
         {
             guard let audioFile = audioFile else { return }
            
            do {
                try audioFile.write(from: buffer)
            } catch {
                addLog(text:"Error writing buffer to file: \(error)")
            }
         }
     }
    
    //Finalize the recorded audio file and save to disk
    private func finalizeAudioFile() {
        
        addLog(text:"finalizeAudioFile()")
        
        guard let audioFile = audioFile else { return }
        
        do {
            try audioFile.write(from: AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 1)!)
        } catch {
            addLog(text:"Error finalizing audio file: \(error)")
        }
        
        self.audioFile = nil
        
        // Stop the audio engine and remove tap
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        addLog(text: "Audio engine stopped")
    }
    
    //Function to Stop Recording when there is a silence of few seconds
    @objc func stopRecording() {
        addLog(text:"stopRecording()")
        if isRecording{
            
            // close floating bar is shown for gif
            if !isFloatingBarVisibleBeforeShowingGif{
                if floatingTopBarWcObj != nil{
                    if getFloatingTopBarWObject().window?.isVisible ?? false{
                        getFloatingTopBarVObject().boxMain.isHidden = true
                        getFloatingTopBarVObject().boxMoreItems.isHidden = true
                    }
                }
            }
            
            floatingTopBarVcObj?.hideRecordingGif()
            
            
            isRecording = false
            finalizeAudioFile()
            audioFile = nil
            
            if let audioFilename = audioFilename{
                let url = audioFilename//URL(fileURLWithPath: path)
                NotificationCenter.default.post(name: VoiceEvents.processing, object: nil)
                allApiObject.transcribeAudio(fileURL: url, completion: {result in
                    print("transcribeAudio is \(result)")
                    DispatchQueue.main.async { [self] in
                        switch result {
                        case .success(let transcription):
                            addLog(text: "Transcription text is:- \(transcription)")
                            NotificationCenter.default.post(name: VoiceEvents.transcript, object: nil,
                                                            userInfo: ["text": transcription])

                            let habitsString = isShutOffTimeGoing() ? sendEveningHabitsToFocusDevice() : sendMorningHabitsToFocusDevice()
                            getIntentFromOpenAIAndPerformTask(transcription: transcription, habits: habitsString)
                        case .failure(let error):
                            print("Error: \(error)")
                            NotificationCenter.default.post(name: VoiceEvents.error, object: nil,
                                                            userInfo: ["text": "Couldn't transcribe audio"])
                        }
                    }
                })
            }
        }
    }
    
    /// Stop recording and DISCARD the audio (no transcription) — used by the menu's Cancel button.
    @objc func cancelRecording() {
        addLog(text: "cancelRecording()")
        guard isRecording else { return }
        if !isFloatingBarVisibleBeforeShowingGif, floatingTopBarWcObj != nil,
           getFloatingTopBarWObject().window?.isVisible ?? false {
            getFloatingTopBarVObject().boxMain.isHidden = true
            getFloatingTopBarVObject().boxMoreItems.isHidden = true
        }
        floatingTopBarVcObj?.hideRecordingGif()
        isRecording = false
        finalizeAudioFile()
        audioFile = nil
    }

    func sendMorningHabitsToFocusDevice()-> String{
        var arrHabits = [String]()
        for i in 0..<arrFilteredMorningHabits.count{
            arrHabits.append(arrFilteredMorningHabits[i].name)
        }
        return getHabitsString(habits: arrHabits)
    }
    
    func sendEveningHabitsToFocusDevice()-> String{
        var arrHabits = [String]()
        for i in 0..<arrFilteredEveningHabits.count{
            arrHabits.append(arrFilteredEveningHabits[i].name)
        }
        return getHabitsString(habits: arrHabits)
    }
    
    func getHabitsString(habits: [String])-> String {
        habits.map { "- \($0)" }.joined(separator: "\n")
    }
    
    func getIntentFromOpenAIAndPerformTask(transcription:String, habits:String){
        allApiObject.getIntentFromOpenAI(userMessage: transcription, habits: habits) { intentResult in
            DispatchQueue.main.async {
                switch intentResult {
                case .success(let response):
                    addLog(text: "🎯 Action: \(response.action), Confidence: \(response.confidence)")
                    print("🎯 Action: \(response.action), Confidence: \(response.confidence)")
                    if response.confidence == "low"{
                        addLog(text: "🎯 Low confidence level detected — ignoring intent from OpenAI")
                        NotificationCenter.default.post(name: VoiceEvents.error, object: nil,
                                                        userInfo: ["text": "Sorry, I didn't catch that. Try again."])
                        return;
                    }
                    let knownActions = ["start_focus", "stop_focus", "pause_focus", "resume_focus", "create_task", "start_habit", "get_focus_stats"]
                    if knownActions.contains(response.action) {
                        NotificationCenter.default.post(name: VoiceEvents.actionDone, object: nil,
                                                        userInfo: ["text": self.voiceActionDescription(response)])
                    } else {
                        NotificationCenter.default.post(name: VoiceEvents.error, object: nil,
                                                        userInfo: ["text": "Sorry, I can't do that one yet."])
                    }
                    switch response.action {
                    case "start_focus":
                        let duration = response.parameters.duration_minutes ?? 25
                        let goal = response.parameters.goal
                        startFocusModeFromFocusDeviceButton(diffMinutes: duration, shouldUpdateFocusButton: true, goal: goal, initiatedByRecording: true)
                        
                    case "stop_focus":
                        addLog(text: "Stopping focus session")
                        finishFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
                        
                    case "pause_focus":
                        addLog(text: "Pausing focus session")
                        pauseFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
                        
                    case "resume_focus":
                        addLog(text: "Resuming focus session")
                        _ = resumeFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
                        
                    case "create_task":
                        let taskName = response.parameters.task ?? "Untitled Task"
                        let timeString = response.parameters.time ?? self.getTomorrowISOString()
                        
                        addLog(text: "Creating task: \(taskName) for \(timeString)")
                        createTask(with: taskName, dateString: timeString, shouldShowNotification: true)
                        
                    case "start_habit":
                        let habitName = response.parameters.habit_name ?? "Unknown habit"
                        addLog(text: "Starting habit: \(habitName)")
                    
                        let name = habitName.lowercased()
                        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                            
                            if currentAction != ._INPROGRESS_{
                                if currentState == ._MORNING_HABIT_{
                                    getHabitsVcObject().startMorningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
                                }else if currentState == ._EVENING_HABIT_{
                                    getHabitsVcObject().startEveningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
                                }
                            }
                        }else {
                            if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_{
                                getHabitsVcObject().stopPostponeEndTimer()
                                closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                                if currentState == ._POSTPONE_MORNING_HABIT_{
                                    getHabitsVcObject().startMorningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
                                }else if currentState == ._POSTPONE_EVENING_HABIT_{
                                    getHabitsVcObject().startEveningRouintHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
                                }
                            }
                            
                        }
                        
                    case "get_focus_stats":
                        addLog(text: "Voice query: focus stats")   // informational only; answer shown via actionDone

                    default:
                        addLog(text: "Unknown action: \(response.action)")
                        
                        // Handle low confidence
                        if response.confidence == "low", let clarification = response.clarification_needed {
                            addLog(text: "Clarification needed: \(clarification)")
                        }
                    }
                    
                case .failure(let error):
                    addLog(text: "Intent classification failed: \(error.localizedDescription)")
                    NotificationCenter.default.post(name: VoiceEvents.error, object: nil,
                                                    userInfo: ["text": "Couldn't understand that. Try again."])
                    //handleWithPatternMatching(transcription)
                }
            }
        }
    }

    func voiceActionDescription(_ response: IntentResponse) -> String {
        switch response.action {
        case "start_focus":
            if isFocusModeOn() || isFocusModePaused() { return "A focus session is already running" }
            return "Starting a \(response.parameters.duration_minutes ?? 25)-minute focus session"
        case "stop_focus":
            return isFocusModeOnOrPaused() ? "Stopping focus session" : "No focus session is running"
        case "pause_focus": return "Pausing focus session"
        case "resume_focus": return "Resuming focus session"
        case "create_task": return "Created task: \(response.parameters.task ?? "")"
        case "start_habit": return "Starting habit: \(response.parameters.habit_name ?? "")"
        case "get_focus_stats":
            let mins = Int(totalDeepFocusedTime) / 60
            let h = mins / 60, m = mins % 60
            let amount = h > 0 ? "\(h)h \(m)m" : "\(m)m"
            return "You've done \(amount) of deep work today"
        default: return "Done"
        }
    }

    func getTomorrowISOString() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: tomorrow)
    }
}
