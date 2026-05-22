//
//  AudioRecorder.swift
//  FocusBear
//
//  Created by Manish Jain on 11/05/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import AVFAudio
import AVFoundation

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
                // Show alert that permission is needed
                // You can post a notification or call a delegate method here
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
                    }
                }
            }
        @unknown default:
            addLog(text: "Unknown permission status")
        }
    }
    
    //Function to Start Recording
    private func startRecording() {
        addLog(text:"startRecording() ")
        guard let audioEngine = audioEngine else {
            addLog(text:"Audio engine not initialized")
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
                allApiObject.transcribeAudio(fileURL: url, completion: {result in
                    print("transcribeAudio is \(result)")
                    DispatchQueue.main.async { [self] in
                        switch result {
                        case .success(let transcription):
                            addLog(text: "Transcription text is:- \(transcription)")
                            
                            getIntentFromOpenAIAndPerformTask(transcription: transcription)
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    }
                })
            }
        }
    }
    
    func getIntentFromOpenAIAndPerformTask(transcription:String){
        allApiObject.getIntentFromOpenAI(userMessage: transcription) { intentResult in
            DispatchQueue.main.async {
                switch intentResult {
                case .success(let response):
                    addLog(text: "🎯 Action: \(response.action), Confidence: \(response.confidence)")
                    print("🎯 Action: \(response.action), Confidence: \(response.confidence)")
                    if response.confidence == "low"{
                        addLog(text: "🎯 Low confidence level detected — ignoring intent from OpenAI")
                        return;
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
                        // Call your habit function here
                        // startHabit(name: habitName)
                        
                    default:
                        addLog(text: "Unknown action: \(response.action)")
                        
                        // Handle low confidence
                        if response.confidence == "low", let clarification = response.clarification_needed {
                            addLog(text: "Clarification needed: \(clarification)")
                        }
                    }
                    
                case .failure(let error):
                    addLog(text: "Intent classification failed: \(error.localizedDescription)")
                    //handleWithPatternMatching(transcription)
                }
            }
        }
    }

    func getTomorrowISOString() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: tomorrow)
    }
}
