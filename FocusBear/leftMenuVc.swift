//
//  leftMenuVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class leftMenuVc: NSViewController, mainWindowListBoxDelegate {

    @IBOutlet weak var boxHelpAndSupport: mainWindowListBox!
    @IBOutlet weak var boxMotivation: mainWindowListBox!
    @IBOutlet weak var boxEditHabits: mainWindowListBox!
    @IBOutlet weak var boxSettings: mainWindowListBox!
    @IBOutlet weak var boxBlocks: mainWindowListBox!
    @IBOutlet weak var boxFocusModeSettings: mainWindowListBox!
    @IBOutlet weak var boxPreferences: accordionBox!
    
    @IBOutlet weak var boxFocusMusic: mainWindowListBox!
    @IBOutlet weak var boxBrainDump: mainWindowListBox!
    @IBOutlet weak var boxTodoPlayer: mainWindowListBox!
    @IBOutlet weak var boxToolsItems: accordionBox!
    
    @IBOutlet weak var boxMainItems: accordionBox!
    @IBOutlet weak var boxMicroBreaks: mainWindowListBox!
    @IBOutlet weak var boxFocusSession: mainWindowListBox!
    @IBOutlet weak var boxHabits: mainWindowListBox!
    @IBOutlet weak var boxDashboard: mainWindowListBox!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // todo text
        boxMainItems.title = "MAIN"
        boxToolsItems.title = "TOOLS"
        boxPreferences.title = "PREFERENCES"
        
        boxDashboard.imageIcon = NSImage(named: "brainDump")
        boxDashboard.title = "Dashboard"
        
        boxHabits.imageIcon = NSImage(named: "play_circle")
        boxHabits.title = "Habits"
        
        
        boxFocusSession.imageIcon = NSImage(named: "start-pomodoro")
        boxFocusSession.title = "Start Focus Session"
        
        
        if #available(macOS 11.0, *) {
            boxMicroBreaks.imageIcon = NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: nil)
        } else {
//            boxMicroBreaks.imageIcon = NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: nil) // todo menu mai bhi
        }
        boxMicroBreaks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        boxMicroBreaks.title = "Start Micro Break"
        
        boxTodoPlayer.imageIcon = NSImage(named: "validIcon")
        boxTodoPlayer.title = "Todo Player / Todo List"
        
        boxBrainDump.imageIcon = NSImage(named: "brainDump")
        boxBrainDump.title = "Brain Dump"
        
        boxFocusMusic.imageIcon = NSImage(named: "music_albums_fill")
        boxFocusMusic.title = "Focus Music"
        
        boxFocusModeSettings.imageIcon = NSImage(named: "NSTouchBarQuickLookTemplate")
        boxFocusModeSettings.title = "Focus"
        boxFocusModeSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxBlocks.imageIcon = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
        } else {
            boxBlocks.imageIcon = NSImage(named: NSImage.stopProgressTemplateName)
        }
        boxBlocks.title = "Blocks"
        boxBlocks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxSettings.imageIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        } else {
            boxSettings.imageIcon = NSImage(named: "NSSmartBadgeTemplate")
        }
        boxSettings.title = "Settings"
        boxSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        if #available(macOS 11.0, *) {
            boxEditHabits.imageIcon = NSImage(systemSymbolName: "checkmark.rectangle", accessibilityDescription: nil)
        } else {
            boxEditHabits.imageIcon = NSImage(named: "checkmark")
        }
        boxEditHabits.title = "Edit Habits"
        boxEditHabits.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue

        if #available(macOS 11.0, *) {
            boxMotivation.imageIcon = NSImage(systemSymbolName: "person", accessibilityDescription: nil)
        } else {
            boxMotivation.imageIcon = NSImage(named: "NSTouchBarUserTemplate")
        }
        boxMotivation.title = "Motivation"
        boxMotivation.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue

        boxHelpAndSupport.imageIcon = NSImage(named: NSImage.infoName)
        boxHelpAndSupport.title = "Help & Support"
        boxHelpAndSupport.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        boxMainItems.setExpanded(true)
        boxMainItems.onStateChanged = { isExpanded in
            print("MainItems is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxMicroBreaks.isHidden = false
                self.boxFocusSession.isHidden = false
                self.boxHabits.isHidden = false
                self.boxDashboard.isHidden = false
            }else{
                self.boxMicroBreaks.isHidden = true
                self.boxFocusSession.isHidden = true
                self.boxHabits.isHidden = true
                self.boxDashboard.isHidden = true
            }
        }
        
        boxToolsItems.setExpanded(true)
        boxToolsItems.onStateChanged = { isExpanded in
            print("Tools is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxFocusMusic.isHidden = false
                self.boxBrainDump.isHidden = false
                self.boxTodoPlayer.isHidden = false
            }else{
                self.boxFocusMusic.isHidden = true
                self.boxBrainDump.isHidden = true
                self.boxTodoPlayer.isHidden = true
            }
            
        }
        
        boxPreferences.setExpanded(true)
        boxPreferences.onStateChanged = { isExpanded in
            print("Preferences is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxMotivation.isHidden = false
                self.boxEditHabits.isHidden = false
                self.boxSettings.isHidden = false
                self.boxBlocks.isHidden = false
                self.boxFocusModeSettings.isHidden = false
            }else{
                self.boxMotivation.isHidden = true
                self.boxEditHabits.isHidden = true
                self.boxSettings.isHidden = true
                self.boxBlocks.isHidden = true
                self.boxFocusModeSettings.isHidden = true
            }
        }

        boxHelpAndSupport.delegate = self
        boxMotivation.delegate = self
        boxEditHabits.delegate = self
        boxSettings.delegate = self
        boxBlocks.delegate = self
        boxFocusModeSettings.delegate = self
        
        boxFocusMusic.delegate = self
        boxBrainDump.delegate = self
        boxTodoPlayer.delegate = self

        boxMicroBreaks.delegate = self
        boxFocusSession.delegate = self
        boxHabits.delegate = self
        boxDashboard.delegate = self

    }
    
    func selectableListBoxDidChangeSelection(_ box: mainWindowListBox) {
        switch box{
            
        case boxDashboard:
            break;
        case boxHabits:
            break;
        case boxFocusSession:
            break;
        case boxMicroBreaks:
            break;
        case boxTodoPlayer:
            break;
        case boxBrainDump:
            break;
        case boxFocusMusic:
            break;
        case boxFocusModeSettings:
            break;
        case boxBlocks:
            break;
        case boxSettings:
            break;
        case boxEditHabits:
            break;
        case boxMotivation:
            break;
        case boxHelpAndSupport:
            break;
        default:
            break;
        }
    }
    
    func habitStarted(){
        boxHelpAndSupport.isEnabled = true
        boxMotivation.isEnabled = true
        boxEditHabits.isEnabled = true
        boxSettings.isEnabled = true
        boxBlocks.isEnabled = true
        boxFocusModeSettings.isEnabled = true
        
        boxFocusMusic.isEnabled = false
        boxBrainDump.isEnabled = false
        boxTodoPlayer.isEnabled = false

        boxMicroBreaks.isEnabled = false
        boxFocusSession.isEnabled = false
        boxHabits.isEnabled = true
        boxDashboard.isEnabled = false
        boxHabits.isSelected = true
    }
    
    
    func habitOver(){
        boxHelpAndSupport.isEnabled = true
        boxMotivation.isEnabled = true
        boxEditHabits.isEnabled = true
        boxSettings.isEnabled = true
        boxBlocks.isEnabled = true
        boxFocusModeSettings.isEnabled = true
        
        boxFocusMusic.isEnabled = true
        boxBrainDump.isEnabled = true
        boxTodoPlayer.isEnabled = true

        boxMicroBreaks.isEnabled = true
        boxFocusSession.isEnabled = true
        boxHabits.isEnabled = true
        boxDashboard.isEnabled = true
    }
}
