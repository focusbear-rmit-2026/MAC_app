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

private func discardVoiceRecording(at url: URL) {
    try? FileManager.default.removeItem(at: url)
}

class audioRecorder: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate{
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    
    var isRecording: Bool = false
    
    var audioFilename: URL?
    var isPermissionGiven = false
    var isFloatingBarVisibleBeforeShowingGif = false
    private let voicePipeline = VoiceCommandPipeline.live
    
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
                                                userInfo: ["text": VoiceCommandMessage.noMicrophone])
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
                NotificationCenter.default.post(name: VoiceEvents.processing, object: nil)
                voicePipeline.run(recording: audioFilename,
                                  habits: currentRoutineHabitNames(),
                                  onTranscript: { transcript in
                                      addLog(text: "Transcription text is:- \(LogPrivacy.text(transcript))")
                                      DispatchQueue.main.async {
                                          NotificationCenter.default.post(name: VoiceEvents.transcript, object: nil,
                                                                          userInfo: ["text": transcript])
                                      }
                                  },
                                  completion: { [weak self] outcome in
                                      // The transcript is all the app needs; the audio of the user's voice
                                      // must not stay on disk until the next recording replaces it.
                                      discardVoiceRecording(at: audioFilename)
                                      DispatchQueue.main.async { self?.handleVoiceCommand(outcome) }
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
        if let audioFilename { discardVoiceRecording(at: audioFilename) }
    }

    /// Names of the habits in the routine that's active now, so "start my X habit" can match one.
    private func currentRoutineHabitNames() -> [String] {
        let habits = isShutOffTimeGoing() ? arrFilteredEveningHabits : arrFilteredMorningHabits
        return habits.map { $0.name }
    }

    private func handleVoiceCommand(_ outcome: VoiceCommandOutcome) {
        switch outcome {
        case .perform(let action, let intent):
            addLog(text: "🎯 Action: \(intent.action), Confidence: \(intent.confidence)")
            // Describe before performing: the description reads the state the action is about to change.
            NotificationCenter.default.post(name: VoiceEvents.actionDone, object: nil,
                                            userInfo: ["text": voiceActionDescription(intent)])
            perform(action)
        case .notUnderstood:
            addLog(text: "🎯 Nothing heard, low confidence or missing details — ignoring the voice command")
            postVoiceError(VoiceCommandMessage.notUnderstood)
        case .unsupported(let action):
            addLog(text: "Unknown voice action: \(action)")
            postVoiceError(VoiceCommandMessage.unsupported)
        case .transcriptionFailed(let error):
            addLog(text: "Transcription failed: \(error)")
            postVoiceError(VoiceCommandMessage.transcriptionFailed(error))
        case .classificationFailed(let error):
            addLog(text: "Intent classification failed: \(error)")
            postVoiceError(VoiceCommandMessage.classificationFailed(error))
        }
    }

    private func postVoiceError(_ message: String) {
        NotificationCenter.default.post(name: VoiceEvents.error, object: nil, userInfo: ["text": message])
    }

    private func perform(_ action: VoiceCommandAction) {
        switch action {
        case .startFocus(let minutes, let goal):
            startFocusModeFromFocusDeviceButton(diffMinutes: minutes, shouldUpdateFocusButton: true, goal: goal, initiatedByRecording: true)
        case .stopFocus:
            addLog(text: "Stopping focus session")
            finishFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
        case .pauseFocus:
            addLog(text: "Pausing focus session")
            pauseFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
        case .resumeFocus:
            addLog(text: "Resuming focus session")
            _ = resumeFocusModeFromFocusDeviceButton(shouldUpdateFocusButton: true)
        case .createTask(let name, let time):
            let timeString = time ?? getTomorrowISOString()
            addLog(text: "Creating task: \(LogPrivacy.text(name)) for \(timeString)")
            createTask(with: name, dateString: timeString, shouldShowNotification: true)
        case .startHabit(let name):
            addLog(text: "Starting habit: \(LogPrivacy.text(name))")
            startRoutineHabit(named: name.lowercased())
        case .focusStats:
            addLog(text: "Voice query: focus stats")   // informational only; answer shown via actionDone
        }
    }

    private func startRoutineHabit(named name: String) {
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            guard currentAction != ._INPROGRESS_ else { return }
            if currentState == ._MORNING_HABIT_{
                getHabitsVcObject().startMorningRoutineHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
            }else{
                getHabitsVcObject().startEveningRoutineHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
            }
            return
        }
        guard currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ else { return }
        getHabitsVcObject().stopPostponeEndTimer()
        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
        if currentState == ._POSTPONE_MORNING_HABIT_{
            getHabitsVcObject().startMorningRoutineHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
        }else{
            getHabitsVcObject().startEveningRoutineHabitFromDeviceButton(name: name, shouldUpdateDeviceButton: true)
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
