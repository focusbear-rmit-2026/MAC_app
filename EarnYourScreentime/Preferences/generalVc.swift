//
//  generalVc.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 09/02/22.

//

import Cocoa

class generalVc: NSViewController {

    
    @IBOutlet weak var checkBoxPromptToAskNextHabit: NSButton!
    @IBOutlet weak var lblCheckBoxPromptToAskNextHabit: NSTextField!
    @IBOutlet weak var lblTitleAskNextHabit: NSTextField!
    @IBOutlet weak var lblTitleReduceMotion: NSTextField!
    @IBOutlet weak var lblCheckBoxStringReduceMotion: NSTextField!
    @IBOutlet weak var checkBoxReduceMotion: NSButton!
    @IBOutlet weak var checkBoxPomodoroMode: NSButton!
    @IBOutlet weak var lblCheckBoxStringPomodoroMode: NSTextField!
    @IBOutlet weak var lblCurrentFolderUrl: NSTextField!
    @IBOutlet weak var lblTitleSync: NSTextField!
    @IBOutlet weak var lblTitleCurrentFolder: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnSelectFolder: NSButton!
    @IBOutlet weak var lblTitlePomodoroMode: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        var titleReduceMotion = "Reduce motion:"
        var checkBoxReduceMotionText = "Prefer reduced motion (don't show animated bears)"
        var titleAskNextHabit = "Next habit remembrance:"
        var checkBoxPromptToAskNextHabitText = "Occasionally prompt me to remember the next habit"
        
        
        
        var titleSync = "Sync data across devices:"
        var titleCurrentFolder = "Current Folder:"
        var buttonSelectFolderText = "Select Folder"
        var syncDescription = "You can specify a folder (e.g. a dropbox folder) to store the usage data so that if you complete the morning routine on one computer, it automatically syncs on other devices. It is required to select such synced folder on all devices."
        
        var titlePomodoro = "Pomodoro Mode:"
        var checkBoxPomodoroText = "Enter Pomodoro mode after completing morning routine"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            titleSync = preferencesInfo.value(forKey: "titleSync") as? String ?? titleSync
            titleCurrentFolder = preferencesInfo.value(forKey: "titleCurrentFolder") as? String ?? titleCurrentFolder
            buttonSelectFolderText = preferencesInfo.value(forKey: "buttonSelectFolderText") as? String ?? buttonSelectFolderText
            syncDescription = preferencesInfo.value(forKey: "syncDescription") as? String ?? syncDescription
            titlePomodoro = preferencesInfo.value(forKey: "titlePomodoro") as? String ?? titlePomodoro
            checkBoxPomodoroText = preferencesInfo.value(forKey: "checkBoxPomodoroText") as? String ?? checkBoxPomodoroText
            titleReduceMotion = preferencesInfo.value(forKey: "titleReduceMotion") as? String ?? titleReduceMotion
            checkBoxReduceMotionText = preferencesInfo.value(forKey: "checkBoxReduceMotionText") as? String ?? checkBoxReduceMotionText
            titleAskNextHabit = preferencesInfo.value(forKey: "titleAskNextHabit") as? String ?? titleAskNextHabit
            checkBoxPromptToAskNextHabitText = preferencesInfo.value(forKey: "checkBoxPromptToAskNextHabitText") as? String ?? checkBoxPromptToAskNextHabitText
            
        }
        
        lblTitleSync.stringValue = titleSync
        lblTitleCurrentFolder.stringValue = titleCurrentFolder
        btnSelectFolder.title = buttonSelectFolderText
        lblDescription.stringValue = syncDescription

        lblTitlePomodoroMode.stringValue = titlePomodoro
        lblCheckBoxStringPomodoroMode.stringValue = checkBoxPomodoroText
        
        lblTitleReduceMotion.stringValue = titleReduceMotion
        lblCheckBoxStringReduceMotion.stringValue = checkBoxReduceMotionText
        lblTitleAskNextHabit.stringValue = titleAskNextHabit
        lblCheckBoxPromptToAskNextHabit.stringValue = checkBoxPromptToAskNextHabitText
        
    }
    
    
    override func viewWillAppear() {
        if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
            lblCurrentFolderUrl.stringValue = path
        }else{
            lblCurrentFolderUrl.stringValue = "Please select a Folder."
        }
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool{
            if state{
                checkBoxPomodoroMode.state = .on
            }else{
                checkBoxPomodoroMode.state = .off
            }
        }
        
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsReducedMotion) as? Bool{
            if state{
                checkBoxReduceMotion.state = .on
                kIsReducedMotion = true
            }else{
                checkBoxReduceMotion.state = .off
                kIsReducedMotion = false
            }
        }
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsPromptToRememberHabit) as? Bool{
            if state{
                checkBoxPromptToAskNextHabit.state = .on
                isPromptToRememberHabit = true
            }else{
                checkBoxPromptToAskNextHabit.state = .off
                isPromptToRememberHabit = false
            }
        }
    }
    @IBAction func btnSelectFolderClicked(_ sender: Any) {
        if let url = SelectUrlofFolder(){
            UserDefaults.standard.set(url.path, forKey: kUserdefaultsSelectedFolder)
            lblCurrentFolderUrl.stringValue = url.path
        }
    }
    func SelectUrlofFolder()->URL?{
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.message = "Please select a folder"
        dialog.prompt = "Select"
        let choice = dialog.runModal()
        
        if choice.rawValue == NSFileHandlingPanelOKButton {
            if let url = dialog.url {
                //            let image = NSImage(byReferencingFile: url.path)!
                return url
            }
        }
        return nil
    }
    
    @IBAction func checkBoxPomodoroModeClicked(_ sender: Any) {
        if checkBoxPomodoroMode.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroModeEnabled)
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsPomodoroModeEnabled)
        }
    }
    @IBAction func checkBoxReduceMotionClicked(_ sender: Any) {
        if checkBoxReduceMotion.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsReducedMotion)
            kIsReducedMotion = true
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsReducedMotion)
            kIsReducedMotion = false
        }
    }
    @IBAction func checkBoxPromptToAskNextHabitClicked(_ sender: Any) {
        if checkBoxPromptToAskNextHabit.state == .on{
            UserDefaults.standard.set(true, forKey: kUserdefaultsPromptToRememberHabit)
            isPromptToRememberHabit = true
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsPromptToRememberHabit)
            isPromptToRememberHabit = false
        }
    }
}
