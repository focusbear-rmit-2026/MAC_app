//
//  leftMenuVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

/// A left-menu item whose availability a running routine governs.
enum LeftMenuRoutineItem: CaseIterable {
    case editHabits
    case settings
    case blocking
    case microBreaks
    case focusSession
    case habits
    case customRoutine
}

/// Why a routine has disabled a left-menu item. `leftMenuVc` maps this to the localized sentence
/// (`disableReasonMorningRoutine` and friends, loaded from `leftMenuVcInfo` in config.json).
enum LeftMenuDisableReason: CaseIterable {
    case morningRoutine
    case eveningRoutine
    case focusSummary
    case shutoffTime
    case customRoutine
}

/// Which left-menu items stay clickable in a given app state — a pure function of `CURRENTSTATE`, so
/// the rule is unit-testable and `leftMenuVc` only applies the answer to its boxes.
///
/// A routine "owns" the main window only while it is genuinely RUNNING. Every `_POSTPONE_*` state is
/// the user explicitly stepping away from the routine, so nothing is restricted there — postponed is
/// not active, and the menu comes back exactly as it is when idle.
enum LeftMenuAvailability {

    /// Items that stay available even while a routine owns the window. These are the "go and change a
    /// preference" destinations: the user must be able to adjust their settings, their habit list and
    /// what is blocked without first ending the routine. All three share the same tab handling —
    /// `askPasswordForSettingsIfNeeded()` still enforces strictness, and
    /// `checkScreenSizeIfFullScreenHabitIsRunning()` keeps the full-screen window — so opening any of
    /// them cannot let the user slip out of a running routine.
    static let alwaysAvailable: Set<LeftMenuRoutineItem> = [.editHabits, .settings, .blocking]

    /// Why the menu is restricted in `state`, or nil when no routine owns the window (idle, every
    /// `_POSTPONE_*` state, onboarding, a micro break — micro breaks run their own disable pass in
    /// `microBreaksStarted`).
    static func disableReason(for state: CURRENTSTATE) -> LeftMenuDisableReason? {
        switch state {
        case ._MORNING_HABIT_:  return .morningRoutine
        case ._EVENING_HABIT_:  return .eveningRoutine
        case ._FOCUS_SUMMARY_:  return .focusSummary
        case ._SHUTOFFMAC_:     return .shutoffTime
        case ._CUSTOM_ROUTINE_: return .customRoutine
        default:                return nil
        }
    }

    /// Whether `item` is clickable while the app is in `state`.
    static func isEnabled(_ item: LeftMenuRoutineItem, during state: CURRENTSTATE) -> Bool {
        guard let reason = disableReason(for: state) else { return true }
        if alwaysAvailable.contains(item) { return true }
        // The running routine's own tab is the way back into it, so it stays clickable; the other
        // routine tab — and the tabs that would start a competing activity — does not.
        switch item {
        case .habits:        return reason != .customRoutine
        case .customRoutine: return reason == .customRoutine
        default:             return false
        }
    }
}

class leftMenuVc: NSViewController, mainWindowListBoxDelegate {

    
    
    @IBOutlet weak var boxUpgradeNow: mainWindowListBox!
    @IBOutlet weak var btnExpandLeftMenu: cursorButton!
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

    /// Drives the "Focusing (Nm left)" row title while a session is running.
    private var focusMinutesTimer: Timer?
    @IBOutlet weak var boxToolsItems: accordionBox!
    @IBOutlet weak var boxBrowsersTabAudit: mainWindowListBox!
    // Programmatically-added TOOLS items, surfaced out of Settings > Add-Ons.
    var boxFocusButtonTool: mainWindowListBox?
    var boxTimeTrackerTool: mainWindowListBox?
    var boxLateNoMoreTool: mainWindowListBox?

    @IBOutlet weak var boxCustomRoutine: mainWindowListBox!
    @IBOutlet weak var boxMainItems: accordionBox!
    @IBOutlet weak var boxMicroBreaks: mainWindowListBox!
    @IBOutlet weak var boxFocusSession: mainWindowListBox!
    @IBOutlet weak var boxHabits: mainWindowListBox!
    @IBOutlet weak var boxDashboard: mainWindowListBox!

    var disableReasonMorningRoutine = "Disabled because your morning routine is in progress. Go to the Habits tab to continue."
    var disableReasonEveningRoutine = "Disabled because your evening routine is in progress. Go to the Habits tab to continue."
    var disableReasonFocusSummary = "Disabled because your all-day summary is visible. Go to the Habits tab to continue."
    var disableReasonShutoffTime = "Disabled because it’s your shutoff time. Go to the Habits tab to continue."
    var disableReasonMircoBreaks = "Disabled because your micro break is in progress. Go to the Micro Break tab to continue."
    var disableReasonCustomRoutine = "Disabled because your custom routine is in progress. Go to the Custom Routine tab to continue."
    
    var lastSelectedBox:mainWindowListBox?
    // #2352 (Bala feedback): TOOLS starts COLLAPSED — still true for anyone who has never opened it.
    // It is now REMEMBERED once the user chooses (report 2026-09-21_16-00-46: "tools keeps
    // collapsing"), so the default survives and a deliberate choice is not overridden every launch.
    // It still auto-expands when a tool inside it becomes selected, and that does NOT count as a
    // choice — see ToolsSectionPreference.
    private var isToolsSectionExpanded = ToolsSectionPreference.isExpandedForCurrentUser
    private var hiddenToolsPopover: NSPopover?

    override func viewDidLoad() {
        super.viewDidLoad()

        boxFocusModeSettings.isHidden = true
        
        boxToolsItems.title = "TOOLS"
        boxPreferences.title = "PREFERENCES"
        
        boxDashboard.isHidden = true
        
        if #available(macOS 11.0, *) {
            boxHabits.imageIcon = NSImage(systemSymbolName: "calendar", accessibilityDescription: nil)
        } else {
            boxHabits.imageIcon = NSImage(named: "play_circle")
        }
        boxHabits.title = "Day Plan"
        boxHabits.imageView?.image?.isTemplate = true
        boxHabits.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange   // match the other menu icons' orange tint

        
        boxCustomRoutine.imageIcon = NSImage(named: "play_circle")
        boxCustomRoutine.title = "Custom Routine"
        
        boxFocusSession.imageIcon = NSImage(named: "start-pomodoro")
        boxFocusSession.title = "Start Focus Session"
        
        
        if #available(macOS 11.0, *) {
            boxMicroBreaks.imageIcon = NSImage(systemSymbolName: "figure.walk.circle.fill", accessibilityDescription: nil)
        } else {
            boxMicroBreaks.imageIcon = NSImage(named: NSImage.touchBarUserTemplateName)
        }

        boxMicroBreaks.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        boxMicroBreaks.title = "Start Micro Break"
        
        boxTodoPlayer.imageIcon = NSImage(named: "validIcon")
        boxTodoPlayer.alwaysEnabled = true   // Todo List must always stay reachable (never greyed out)
        applyTodoToolTitle()
        
        boxBrainDump.imageIcon = NSImage(named: "brainDump")
        boxBrainDump.title = "Notes"   // i18n-ignore: last-resort default; the real string comes from config (menuNotes)

        // TOOLS rows the user can hover-hide via ✕ and restore via the TOOLS gear icon.
        let hideableTools: [(mainWindowListBox, ToolID)] = [
            (boxFocusMusic, .focusMusic), (boxBrainDump, .brainDump),
            (boxTodoPlayer, .todoList), (boxMotivation, .stats),
            (boxBrowsersTabAudit, .tabAudit)
        ]
        for (box, id) in hideableTools {
            box.showsHideButton = true
            box.onHideRequested = { [weak self] in
                ToolVisibilityStore.hide(id)
                self?.refreshToolsVisibility()
            }
        }

        
        boxBrowsersTabAudit.imageIcon = NSImage(named: "NSTouchBarOpenInBrowserTemplate")
        boxBrowsersTabAudit.title = "Tab Audit"
        boxBrowsersTabAudit.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        boxFocusMusic.imageIcon = NSImage(named: "music_albums_fill")
        boxFocusMusic.title = "Focus Music"
        
//        boxFocusModeSettings.imageIcon = NSImage(named: "NSTouchBarQuickLookTemplate")
//        boxFocusModeSettings.title = "Focus"
//        boxFocusModeSettings.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
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
            boxMotivation.imageIcon = NSImage(systemSymbolName: "chart.bar.xaxis", accessibilityDescription: nil)
        } else {
            boxMotivation.imageIcon = NSImage(named: "NSTouchBarUserTemplate")
        }
        boxMotivation.title = "Stats"
        boxMotivation.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue

        boxHelpAndSupport.imageIcon = NSImage(named: NSImage.infoName)
        boxHelpAndSupport.title = "Help & Support"
        boxHelpAndSupport.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        boxUpgradeNow.title = "Upgrade Now"
        boxUpgradeNow.imageIcon = NSImage(named: "upgrade")
        
        // MAIN is no longer a collapsible group — its rows sit flat with no section
        // header, like boxHelpAndSupport/boxUpgradeNow below. Hide the (now unused)
        // accordion header view rather than removing it from the storyboard, and force
        // its rows permanently visible.
        boxMainItems.isHidden = true
        boxMicroBreaks.isHidden = false
        boxFocusSession.isHidden = false
        boxHabits.isHidden = false
        // Custom routines now live in the Day Plan's Custom Routines panel, so the menu item
        // is removed.
        boxCustomRoutine.isHidden = true

        installToolsAddOnItems()
        ensureMenuScrolls()

        // Custom Routine is removed from the menu (now lives in the Day Plan's Custom Routines
        // panel); hide it explicitly here.
        boxCustomRoutine.isHidden = true

        // Restore what this account last chose; collapsed if it never has (#2352's default).
        // setExpanded runs before onStateChanged is assigned, so it doesn't apply row visibility
        // itself — refreshToolsVisibility() below does that.
        boxToolsItems.setExpanded(ToolsSectionPreference.isExpandedForCurrentUser)
        boxToolsItems.onStateChanged = { [weak self] isExpanded in
            self?.isToolsSectionExpanded = isExpanded
            self?.refreshToolsVisibility()
        }
        // Only a click is a choice. The auto-expand in selectableListBoxSelectionDidChange goes
        // through setExpanded and so never lands here, which is what stops it silently cancelling a
        // collapse the user asked for.
        boxToolsItems.onUserToggled = { isExpanded in
            ToolsSectionPreference.recordUserChoice(isExpanded)
        }
        boxToolsItems.onGearClicked = { [weak self] in
            self?.showHiddenToolsPopover()
        }
        // setExpanded(false) above ran before onStateChanged was assigned, so it didn't apply
        // hidden-row state on first load — apply it explicitly now (collapses all tool rows).
        refreshToolsVisibility()

        boxPreferences.setExpanded(true)
        boxPreferences.onStateChanged = { isExpanded in
            print("Preferences is now \(isExpanded ? "expanded" : "collapsed")")
            if isExpanded{
                self.boxEditHabits.isHidden = false
                self.boxSettings.isHidden = false
                self.boxBlocks.isHidden = false
            }else{
                self.boxEditHabits.isHidden = true
                self.boxSettings.isHidden = true
                self.boxBlocks.isHidden = true
            }
        }

        boxHelpAndSupport.delegate = self
        boxEditHabits.delegate = self
        boxSettings.delegate = self
        boxBlocks.delegate = self
        
        boxFocusMusic.delegate = self
        boxBrainDump.delegate = self
        boxTodoPlayer.delegate = self
        boxMotivation.delegate = self
        boxBrowsersTabAudit.delegate = self
        
        boxMicroBreaks.delegate = self
        boxFocusSession.delegate = self
        boxHabits.delegate = self
        boxCustomRoutine.delegate = self
        boxUpgradeNow.delegate = self
        
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            boxToolsItems.title = leftMenuVcInfo.value(forKey: "titleTools") as? String ?? boxToolsItems.title
            boxPreferences.title = leftMenuVcInfo.value(forKey: "titlePreferences") as? String ?? boxPreferences.title
            

            // Mac-only "Day Plan" label — a NEW key, NOT menuHabits (which other platforms still
            // use for their Habits view). Falls back to the hardcoded "Day Plan" (set above), never
            // to menuHabits, so the Mac never shows "Habits" here even before the new key ships.
            boxHabits.title = (leftMenuVcInfo.value(forKey: "menuDayPlan") as? String) ?? boxHabits.title
            boxCustomRoutine.title = leftMenuVcInfo.value(forKey: "menuCustomRoutine") as? String ?? boxCustomRoutine.title
            boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStartFocusSession") as? String ?? boxFocusSession.title
            boxMicroBreaks.title = leftMenuVcInfo.value(forKey: "menuStartMicroBreak") as? String ?? boxMicroBreaks.title
            
            applyTodoToolTitle()
            boxBrainDump.title = leftMenuVcInfo.value(forKey: "menuNotes") as? String ?? boxBrainDump.title
            boxBrowsersTabAudit.title = leftMenuVcInfo.value(forKey: "menuTabAudit") as? String ?? boxBrowsersTabAudit.title
            boxFocusMusic.title = leftMenuVcInfo.value(forKey: "menuFocusMusic") as? String ?? boxFocusMusic.title
            
            boxBlocks.title = leftMenuVcInfo.value(forKey: "menuBlocksPreferences") as? String ?? boxFocusMusic.title
            boxSettings.title = leftMenuVcInfo.value(forKey: "menuSettings") as? String ?? boxFocusMusic.title
            boxEditHabits.title = leftMenuVcInfo.value(forKey: "menuEditHabits") as? String ?? boxFocusMusic.title
            // Renamed to "Stats". Hardcoded (not config-driven) because the synced/cached config can
            // still carry the old "Motivation" label; the bundled + assets config also say "Stats" now,
            // so this can revert to the config value once that has propagated.
            boxMotivation.title = "Stats"
            boxHelpAndSupport.title = leftMenuVcInfo.value(forKey: "menuHelpAndSupport") as? String ?? boxFocusMusic.title
            boxUpgradeNow.title = leftMenuVcInfo.value(forKey: "menuUpgradeNow") as? String ?? boxFocusMusic.title
            
            disableReasonMorningRoutine = leftMenuVcInfo.value(forKey: "disableReasonMorningRoutine") as? String ?? disableReasonMorningRoutine
            disableReasonEveningRoutine = leftMenuVcInfo.value(forKey: "disableReasonEveningRoutine") as? String ?? disableReasonEveningRoutine
            disableReasonFocusSummary = leftMenuVcInfo.value(forKey: "disableReasonFocusSummary") as? String ?? disableReasonFocusSummary
            disableReasonShutoffTime = leftMenuVcInfo.value(forKey: "disableReasonShutoffTime") as? String ?? disableReasonShutoffTime
            disableReasonMircoBreaks = leftMenuVcInfo.value(forKey: "disableReasonMircoBreaks") as? String ?? disableReasonMircoBreaks
            disableReasonCustomRoutine = leftMenuVcInfo.value(forKey: "disableReasonCustomRoutine") as? String ?? disableReasonCustomRoutine
        }
        
        arrForSearchFromSettings.append(["title": boxSettings.title, "tabId": idSettings])
        arrForSearchFromSimpleModeSettings.append(["title": boxSettings.title, "tabId": idSettings])
        
        arrForSearchFromSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        arrForSearchFromSimpleModeSettings.append(["title": boxEditHabits.title, "tabId": idEditHabits])
        
        arrForSearchFromSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
        arrForSearchFromSimpleModeSettings.append(["title": boxBlocks.title, "tabId": idTabStrictness])
    }
    
    override func viewWillAppear() {
        resetFocusModeTitle()
        checkPurchaseState()
    }
    
    func reloadHabitStatus(){

    }
    
    
    func checkPurchaseState(){
        if !isPurchased{
            boxUpgradeNow.isHidden = false
        }else{
            boxUpgradeNow.isHidden = true
        }
    }
    
    func resetFocusModeTitle(){
        let isFocusModeOn = isFocusModeOn()
        let isFocusModePaused = isFocusModePaused()

        if isFocusModeOn{
            // The row says what is happening, not what tapping it does — it has never stopped the
            // session, it opens the session screen (see `case boxFocusSession`), where pause and End
            // Session live. It used to read "Stop Focus Session", which promised something it did not do.
            boxFocusSession.title = focusingRowTitle()
            startFocusMinutesTicker()
        }else if isFocusModePaused{
            stopFocusMinutesTicker()
            boxFocusSession.title = "Resume Focus Session"
//            imgViewStopSuperFocusSession.image = iconResumeFocusSession
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? boxFocusSession.title
            }
        }else if isHardCorePomodoroModeOn{
            stopFocusMinutesTicker()
            boxFocusSession.title = "Stop Super Focus Session"
//            imgViewStopSuperFocusSession.image = iconStopFocusSession
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStopSuperFocusSession") as? String ?? boxFocusSession.title
            }
        }else{
            stopFocusMinutesTicker()
            boxFocusSession.title = "Start Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                boxFocusSession.title = leftMenuVcInfo.value(forKey: "menuStartFocusSession") as? String ?? boxFocusSession.title
            }
        }
    }
    
    /// Applies both the TOOLS accordion's expanded/collapsed state and each row's user-hidden state
    /// (via the hover ✕ / gear-restore flow). A row is visible only when the section is expanded AND
    /// the user hasn't hidden it.
    private func refreshToolsVisibility() {
        let hideableTools: [(mainWindowListBox, ToolID)] = [
            (boxFocusMusic, .focusMusic), (boxBrainDump, .brainDump),
            (boxTodoPlayer, .todoList), (boxMotivation, .stats),
            (boxBrowsersTabAudit, .tabAudit)
        ]
        for (box, id) in hideableTools {
            box.isHidden = !isToolsSectionExpanded || ToolVisibilityStore.isHidden(id)
        }
        let addOnHideableTools: [(mainWindowListBox?, ToolID)] = [
            (boxFocusButtonTool, .focusButton), (boxTimeTrackerTool, .timeTracker), (boxLateNoMoreTool, .lateNoMore)
        ]
        for (box, id) in addOnHideableTools {
            box?.isHidden = !isToolsSectionExpanded || ToolVisibilityStore.isHidden(id)
        }
    }

    /// True if `box` is one of the rows living under the collapsible TOOLS section (storyboard tools +
    /// the programmatic Focus Button / Time Tracker / Late No More add-ons). Used to auto-expand TOOLS
    /// when a tool is selected (#2352).
    private func isToolBox(_ box: mainWindowListBox) -> Bool {
        let toolBoxes: [mainWindowListBox?] = [
            boxFocusMusic, boxBrainDump, boxTodoPlayer, boxMotivation, boxBrowsersTabAudit,
            boxFocusButtonTool, boxTimeTrackerTool, boxLateNoMoreTool
        ]
        return toolBoxes.contains { $0 === box }
    }

    private func showHiddenToolsPopover() {
        if let popover = hiddenToolsPopover, popover.isShown {
            popover.performClose(nil)
            return
        }
        let view = RestoreHiddenToolsView(onRestore: { [weak self] _ in
            self?.refreshToolsVisibility()
        })
        let popover = NSPopover()
        let hosting = NSHostingController(rootView: view)
        // Let the popover track the SwiftUI content's size, so it resizes as rows are restored.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = [.preferredContentSize]
        }
        popover.contentViewController = hosting
        popover.behavior = .transient
        // Give the content a concrete size BEFORE showing. Without this, a short list (0–3 rows) has no
        // established fitting size yet, so NSPopover falls back to a degenerate default — the arrow
        // renders as a blunt square and the popover is mispositioned, only self-correcting once enough
        // rows force a bigger intrinsic size. Forcing layout + pinning contentSize fixes both.
        hosting.view.layoutSubtreeIfNeeded()
        popover.contentSize = hosting.view.fittingSize
        hiddenToolsPopover = popover
        popover.show(relativeTo: boxToolsItems.bounds, of: boxToolsItems, preferredEdge: .maxX)
    }

    /// Adds Focus Button / Time Tracker / Late No More to the TOOLS group programmatically, so the
    /// storyboard left-menu stack stays untouched. Inserted right after Stats.
    private func installToolsAddOnItems() {
        guard boxFocusButtonTool == nil,
              let stack = boxMotivation.superview as? NSStackView else { return }
        let focusBtn = makeToolBox(title: "Focus Button", systemIcon: "button.programmable")
        let timeTracker = makeToolBox(title: "Time Tracker", systemIcon: "clock")
        let lateNoMore = makeToolBox(title: "Late No More", systemIcon: "calendar.badge.clock")
        boxFocusButtonTool = focusBtn
        boxTimeTrackerTool = timeTracker
        boxLateNoMoreTool = lateNoMore

        let addOnHideableTools: [(mainWindowListBox, ToolID)] = [
            (focusBtn, .focusButton), (timeTracker, .timeTracker), (lateNoMore, .lateNoMore)
        ]
        for (box, id) in addOnHideableTools {
            box.showsHideButton = true
            box.onHideRequested = { [weak self] in
                ToolVisibilityStore.hide(id)
                self?.refreshToolsVisibility()
            }
        }

        let after = stack.arrangedSubviews.firstIndex(of: boxMotivation) ?? (stack.arrangedSubviews.count - 1)
        stack.insertArrangedSubview(focusBtn, at: after + 1)
        stack.insertArrangedSubview(timeTracker, at: after + 2)
        stack.insertArrangedSubview(lateNoMore, at: after + 3)
        for box in [focusBtn, timeTracker, lateNoMore] {
            box.heightAnchor.constraint(equalToConstant: 32).isActive = true
            // Pin leading/trailing to an existing item so the row lines up exactly with it.
            box.leadingAnchor.constraint(equalTo: boxMotivation.leadingAnchor).isActive = true
            box.trailingAnchor.constraint(equalTo: boxMotivation.trailingAnchor).isActive = true
        }
    }

    /// Make the menu scroll when its items are taller than the window (the document view already grows
    /// with the stack content; this just enables the scroller and lets it scroll past the visible area).
    private func ensureMenuScrolls() {
        guard let scroll = boxMotivation.enclosingScrollView else { return }
        scroll.hasVerticalScroller = true
        scroll.verticalScrollElasticity = .allowed
        scroll.drawsBackground = false
    }

    private func makeToolBox(title: String, systemIcon: String) -> mainWindowListBox {
        let box = mainWindowListBox(frame: .zero)
        box.translatesAutoresizingMaskIntoConstraints = false
        box.contentViewMargins = NSSize(width: 0, height: 0)   // match storyboard items (no extra inset)
        box.title = title
        if #available(macOS 11.0, *) {
            // Fixed point size + centred scaling so the three symbols line up consistently with each
            // other (raw SF Symbols have differing aspect ratios and render at different visual sizes).
            let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
            box.imageIcon = NSImage(systemSymbolName: systemIcon, accessibilityDescription: title)?
                .withSymbolConfiguration(config)
            box.imageView?.imageScaling = .scaleProportionallyDown
        }
        box.imageView?.contentTintColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        box.delegate = self
        return box
    }

    /// Show the habits / Day Plan area with the correct state view for the CURRENT app state. Shared by
    /// the sidebar `boxHabits` selection and the menu's Open-Day-Plan action so both populate it
    /// identically. The menu path used to skip this dispatch, so the Day Plan rendered blank on first
    /// open in the postpone states (habits area never got its state view) until you navigated away and
    /// back — reported 2026-07-08.
    func showDayPlanForCurrentState() {
        mainViewControllerObj?.showHabitsView()
        // The active routine states already have their habit content up — don't disturb it (that
        // previously caused a blank-habit-state regression, v 3.33.494).
        guard currentState != ._MORNING_HABIT_, currentState != ._EVENING_HABIT_, currentState != ._FOCUS_SUMMARY_ else { return }
        // Tracks whether one of the branches below actually populated the habits/Day Plan area, so the
        // safety net at the end can catch any state combination none of them account for — this exact
        // function has already shipped one blank-Day-Plan fix (see the doc comment above) and another
        // was reported 2026-07-13 (isUserOnMeeting + isHabitAlreadyShowed both landing on a combination
        // no branch matched); rather than chase every future combination individually, never leave the
        // area blank instead.
        var didShowHabitState = false
        if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ {
            habitsVcObj?.showHabitState(); didShowHabitState = true
        } else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit {
            habitsVcObj?.showHabitState(); didShowHabitState = true
        } else if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit {
            habitsVcObj?.showHabitState(); didShowHabitState = true
        } else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeMorningHabit {
            habitsVcObj?.showHabitState(); didShowHabitState = true
        } else if currentState == ._CUSTOM_ROUTINE_ && isCustomRoutineWasRunningInPostponeEveningHabit {
            habitsVcObj?.showHabitState(); didShowHabitState = true
        } else {
            if isHabitAlreadyShowed && !isShutOffTimeGoing() {
                habitsVcObj?.showHabitState(); didShowHabitState = true
            } else if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date,
                      Date().compare(date) == .orderedAscending {
                habitsVcObj?.showHabitState(); didShowHabitState = true
            }

            let currentDate = Date()
            let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
            let sameDay = Calendar.current.isDate(currentDate, equalTo: firstRunDate, toGranularity: .day)
            let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false

            if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_ && UserDefaults.standard.object(forKey: kUserdefaultsStartRoutineButtonClicked) == nil {
                if isHabitsDisabled {
                    UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                    habitsVcObj?.showHabitState(); didShowHabitState = true
                } else if sameDay || !shouldDoHabits() {
                    habitsVcObj?.showHabitState(); didShowHabitState = true
                } else {
                    UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                }
            } else {
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date {
                    if Date().compare(date) == .orderedAscending {// evening habits already shown for today
                        if isShutOffTimeGoing() && !isCutOffTimeGoing() {
                            habitsVcObj?.showHabitState(); didShowHabitState = true // free time
                        }
                    }
                } else if isShutOffTimeGoing() && currentState != ._EVENING_HABIT_ && currentState != ._FOCUS_SUMMARY_ && currentState != ._POSTPONE_EVENING_HABIT_ && currentState != ._POSTPONE_FOCUS_SUMMARY_ && arrAllDaysEveningHabits.count == 0 {
                    habitsVcObj?.showHabitState(); didShowHabitState = true // v 2.28.437
                } else if (appdelegate?.isUserOnMeeting ?? false) && !isHabitAlreadyShowed && !isShutOffTimeGoing() {
                    habitsVcObj?.showHabitState(); didShowHabitState = true // v 2.28.445
                } else if !isAppEnable {
                    habitsVcObj?.showHabitState(); didShowHabitState = true // v 2.28.456
                } else if sameDay || !shouldDoHabits() {
                    if isHabitsDisabled {
                        UserDefaults.standard.set(true, forKey: kUserdefaultsStartRoutineButtonClicked)
                    }
                    habitsVcObj?.showHabitState(); didShowHabitState = true
                }
            }
        }
        // Safety net: every branch above is a narrow, historically-patched special case: if none of
        // them matched for the current state/flag combination, fall back to showing the habit state
        // anyway rather than leaving the Day Plan area blank — showHabitState() just re-adds its view
        // (removeSubViews() first), so calling it here is a no-op if something already handled it and
        // the state genuinely needed nothing shown, and a real fix if nothing did.
        if !didShowHabitState {
            addLog(text: "showDayPlanForCurrentState: no branch matched for state=\(currentState) — falling back to showHabitState() so Day Plan isn't left blank")
            habitsVcObj?.showHabitState()
        }
    }

    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox) {
        if box == boxFocusButtonTool { mainViewControllerObj?.showFocusButtonToolView(); return }
        if box == boxTimeTrackerTool { mainViewControllerObj?.showTimeTrackerToolView(); return }
        if box == boxLateNoMoreTool { mainViewControllerObj?.showLateNoMoreToolView(); return }
        switch box{
            
        case boxHabits:
            showDayPlanForCurrentState()
            break;
        case boxFocusSession:
            showFocusSessionTabContent()
        case boxMicroBreaks:
            if currentState == ._MICRO_BREAK_{
                var isBreakWarningVisible = false
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        isBreakWarningVisible = true// will not happened now beacuse changing selection will start break if warning is visible
                    }
                }
                
                if isBreakWarningVisible{
                    mainViewControllerObj?.showHabitsView()
                    habitsVcObj?.showBreakState()
                }else{
                    mainViewControllerObj?.showHabitsView()
                }
            }else{
                mainViewControllerObj?.showHabitsView()
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{ 
                    if Date().compare(date) == .orderedAscending || isShutOffTimeGoing(){
                        habitsVcObj?.showHabitState()
                    }else{
                        habitsVcObj?.showBreakState()
                    }
                }else{
                    habitsVcObj?.showBreakState()
                }
            }
        case boxCustomRoutine:
            if currentState == ._CUSTOM_ROUTINE_ {
                if customRoutineTimeWcObj != nil {
                    if customRoutineTimeWcObj?.window?.isVisible ?? false{
                        mainViewControllerObj?.showHabitsView()
                        habitsVcObj?.showCustomRoutineState()
                    }else{
                        mainViewControllerObj?.showHabitsView()
                    }
                }else{
                    mainViewControllerObj?.showHabitsView()
                }
            }else{
                mainViewControllerObj?.showHabitsView()
                habitsVcObj?.showCustomRoutineState()
            }
        case boxTodoPlayer:
            mainViewControllerObj?.showTaskView()
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                    boxTodoPlayer.isEnabled = true
                }
            }
        case boxBrainDump:
            mainViewControllerObj?.showBrainDumpView()
        case boxBrowsersTabAudit:
            mainViewControllerObj?.showBrowsersTabAuditView()
        case boxFocusMusic:
            mainViewControllerObj?.showAllTracksView()
        case boxBlocks:
            mainViewControllerObj?.showBlocksPreferencesView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxSettings:
            mainViewControllerObj?.showSettingsView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxEditHabits:
            mainViewControllerObj?.showEditHabitsView()
            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
        case boxMotivation:
            mainViewControllerObj?.showMotivationView()
        case boxHelpAndSupport:
            mainViewControllerObj?.showHelpView()
        default:
            break;
        }
    }
    
    func selectableListBoxSelectionDidChange(_ box: mainWindowListBox) {
        lastSelectedBox = box
        // #2352: TOOLS is collapsed by default; auto-expand it when a tool inside it becomes the
        // selection (e.g. the app restores onto a tool view, or a tool is opened from the menu) so the
        // highlighted tool stays visible.
        if !isToolsSectionExpanded, isToolBox(box) {
            boxToolsItems.setExpanded(true)   // fires onStateChanged → sets the flag + refreshToolsVisibility()
        }
        switch box{

        case boxHabits:
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_{
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxFocusSession:
            // Starting a session lands here (showRunningFocusSessionWindow -> showFocusModeStateView),
            // so this runs on every session start. It used to call showSmallScreen(showMinimumSize: true)
            // for every state but _MICRO_BREAK_, which snapped the window back to 1008x600 — the user's
            // "starting a session changes the size of the window". The window is now left alone unless
            // the app's borderless full-screen window is actually up; see FocusSessionRouting.windowSizing.
            switch FocusSessionRouting.windowSizing(
                isFullScreenWindowVisible: mainWindowControllerObj?.isFullScreenVisible ?? false,
                isFullScreenModeEnabled: checkIsFullScreenEnabled()){
            case .keepFullScreen:
                mainViewControllerObj?.checkIsFullScreenNeeded()
            case .restoreSmallWindow:
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            case .leaveAsIs:
                break
            }
        case boxMicroBreaks:
            if currentState == ._MICRO_BREAK_{
                var isBreakWarningVisible = false
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        isBreakWarningVisible = true // will not happened now beacuse changing selection will start break if warning is visible
                    }
                }
                
                if isBreakWarningVisible{
                    mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxCustomRoutine:
            if currentState == ._CUSTOM_ROUTINE_ {
                if customRoutineTimeWcObj != nil {
                    if customRoutineTimeWcObj?.window?.isVisible ?? false{
                        mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                    }else{
                        mainViewControllerObj?.checkIsFullScreenNeeded()
                    }
                }else{
                    mainViewControllerObj?.checkIsFullScreenNeeded()
                }
            }else{
                mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            }
        case boxTodoPlayer:
            checkScreenSizeIfFullScreenHabitIsRunning()
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
                self.view.window?.styleMask.insert(.miniaturizable)// task player should be miniaturizable
            }
        case boxBrainDump:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxBrowsersTabAudit:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxFocusMusic:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxBlocks:
            keepFullScreenLockOrShrink()
        case boxSettings:
            keepFullScreenLockOrShrink()
        case boxEditHabits:
            keepFullScreenLockOrShrink()
        case boxMotivation:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxHelpAndSupport:
            checkScreenSizeIfFullScreenHabitIsRunning()
        case boxFocusButtonTool, boxTimeTrackerTool, boxLateNoMoreTool:
            // Keep the full-size window while a full-screen habit/routine/break/shut-off is running —
            // these tool tabs were unconditionally shrinking it, which let the user drop out of a
            // full-screen activity (and expose the desktop) by opening a tool. checkScreenSize… shrinks
            // to the standard small window when no full-screen activity is active, matching the other
            // inline tabs (Todo Player / Brain Dump).
            checkScreenSizeIfFullScreenHabitIsRunning()
        default:
            break;
        }
    }
    
    /// Settings / Blocks / Edit-Habits nav items used to unconditionally shrink to a normal window — which,
    /// in Focus Bear's borderless full-screen (kiosk) mode, DROPPED OUT of full-screen and exposed the
    /// desktop / other apps (e.g. opening Settings from a full-screen Day Plan). When full-screen mode is
    /// on, keep the lock (show the pane inside the full-screen window); otherwise shrink as before. Mirrors
    /// the tool-tab fix that uses checkScreenSizeIfFullScreenHabitIsRunning for routine states.
    private func keepFullScreenLockOrShrink() {
        if checkIsFullScreenEnabled() {
            mainViewControllerObj?.checkIsFullScreenNeeded()
        } else {
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        }
    }

    func checkScreenSizeIfFullScreenHabitIsRunning(){
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._SHUTOFFMAC_ || currentState == ._CUSTOM_ROUTINE_ || currentState == ._MICRO_BREAK_{
            
            if !isAnyAllowedFocusModeActivityRunning && checkIsFullScreenEnabled(){
                mainViewControllerObj?.checkIsFullScreenNeeded()
            }else{
                if isAnyAllowedFocusModeActivityRunning{
                    mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
                }
            }
        }else{
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        }
    }
    
    func selectableListBoxShouldChangeSelection(_ box: mainWindowListBox) -> Bool {
        if areSettingsEdited{
            showAlertSettingsEdited()
            areSettingsEdited = false
            return false
        }
        
        if box == boxMicroBreaks{
            if currentState == ._MICRO_BREAK_{ // if currentstate is microbreak and break warning is visible thne if user click on this tab. start break immediately
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        breakWarningVcObj?.btnStartMicroBreakClicked(self)
                        return false
                    }
                }
            }
        }

        // Leaving the Micro Break tab after changing the break interval but not turning breaks on:
        // confirm first instead of silently discarding the change.
        if boxMicroBreaks.isSelected, box != boxMicroBreaks,
           breaksStateVcObj?.hasUnsavedFrequencyChange == true {
            promptUnsavedBreakFrequency(targetBox: box)
            return false
        }
        if box == boxUpgradeNow{
            addLog(text:"[user-action] leftMenuVc:- btnUpgradeNowClicked")
            showUpgradeNowWindow(reason: "upgrade_now_button")
            return false
        }
        
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return false
        }
        return true
    }
    
    func showAlertSettingsEdited(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var message = "You've made changes to your habits/breaks but haven't saved them yet. It is recommended to review and save the changes (the app will restart)?"
        var buttonReviewSettingsText = "I'll review and Save"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            message = settings.value(forKey: "settingsEditedButNotSavedText") as? String ?? message
            buttonReviewSettingsText = settings.value(forKey: "buttonReviewSettingsText") as? String ?? buttonReviewSettingsText
        }
        alert.messageText = message
        alert.addButton(withTitle: buttonReviewSettingsText)
        if let window = self.view.window{
            alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                }


            })
        }
    }

    /// The user changed the break interval but didn't turn breaks on, then tried to switch tabs. Confirm
    /// before leaving: turn breaks on with the new interval, discard the change, or stay.
    private func promptUnsavedBreakFrequency(targetBox: mainWindowListBox){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        var message = "You changed how often you'd like a break but haven't turned breaks on yet. Turn breaks on with the new interval?"
        var buttonTurnOn = "Turn breaks on"
        var buttonDiscard = "Discard change"
        var buttonCancel = "Cancel"
        if let breakStateVcInfo = configjson.value(forKey: "breakStateVcInfo") as? NSDictionary{
            message = breakStateVcInfo.value(forKey: "unsavedFrequencyMessage") as? String ?? message
            buttonTurnOn = breakStateVcInfo.value(forKey: "unsavedFrequencyTurnOnButton") as? String ?? buttonTurnOn
            buttonDiscard = breakStateVcInfo.value(forKey: "unsavedFrequencyDiscardButton") as? String ?? buttonDiscard
            buttonCancel = breakStateVcInfo.value(forKey: "unsavedFrequencyCancelButton") as? String ?? buttonCancel
        }
        alert.messageText = message
        alert.addButton(withTitle: buttonTurnOn)   // .alertFirstButtonReturn
        alert.addButton(withTitle: buttonDiscard)  // .alertSecondButtonReturn
        alert.addButton(withTitle: buttonCancel)   // .alertThirdButtonReturn
        guard let window = self.view.window else { return }
        alert.beginSheetModal(for: window, completionHandler: { [weak self] response in
            guard let self = self else { return }
            switch response{
            case .alertFirstButtonReturn:
                breaksStateVcObj?.turnOnBreaksWithPendingFrequency()
                self.switchToTab(targetBox)
            case .alertSecondButtonReturn:
                breaksStateVcObj?.discardPendingFrequencyChange()
                self.switchToTab(targetBox)
            default:
                break // Cancel — stay on the Micro Break tab
            }
        })
    }

    /// Programmatically complete a tab switch that selectableListBoxShouldChangeSelection had blocked
    /// (the pending-change flag is cleared by the callers above, so this won't re-prompt).
    private func switchToTab(_ box: mainWindowListBox){
        box.isSelected = true
        selectableListBoxDidChangeSelectionByUser(box)
    }
    
    
    func habitStarted(){
        applyRoutineMenuAvailability()

        boxHabits.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
    }
    
    func customRoutineStarted(){
        applyRoutineMenuAvailability()

        boxCustomRoutine.isSelected = true
        mainViewControllerObj?.showHabitsView()
        reloadHabitStatus()
        mainViewControllerObj?.collapseLeftPanel()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    
    /// Bring the routine-governed left-menu items in line with `currentState` (`LeftMenuAvailability`).
    /// Disabled items carry that state's reason as their tooltip; in a state where no routine owns the
    /// window — idle, or any `_POSTPONE_*` — everything here is re-enabled.
    func applyRoutineMenuAvailability(){
        let toolTipDisableReason = localizedDisableReason(LeftMenuAvailability.disableReason(for: currentState))
        for item in LeftMenuRoutineItem.allCases {
            let box = boxFor(item)
            if LeftMenuAvailability.isEnabled(item, during: currentState) {
                box.isEnabled = true
            } else {
                box.setDisableWithRaason(reason: toolTipDisableReason)
            }
        }
    }

    private func boxFor(_ item: LeftMenuRoutineItem) -> mainWindowListBox {
        switch item {
        case .editHabits:    return boxEditHabits
        case .settings:      return boxSettings
        case .blocking:      return boxBlocks
        case .microBreaks:   return boxMicroBreaks
        case .focusSession:  return boxFocusSession
        case .habits:        return boxHabits
        case .customRoutine: return boxCustomRoutine
        }
    }

    private func localizedDisableReason(_ reason: LeftMenuDisableReason?) -> String {
        switch reason {
        case .morningRoutine: return disableReasonMorningRoutine
        case .eveningRoutine: return disableReasonEveningRoutine
        case .focusSummary:   return disableReasonFocusSummary
        case .shutoffTime:    return disableReasonShutoffTime
        case .customRoutine:  return disableReasonCustomRoutine
        case nil:             return ""
        }
    }

    func disableAllTabForOnboarding(){
        let toolTipDisableReason = ""
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxFocusMusic.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrainDump.setDisableWithRaason(reason: toolTipDisableReason)
        boxBrowsersTabAudit.setDisableWithRaason(reason: toolTipDisableReason)
        boxTodoPlayer.setDisableWithRaason(reason: toolTipDisableReason)
        boxMotivation.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.setDisableWithRaason(reason: toolTipDisableReason)
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxUpgradeNow.setDisableWithRaason(reason: toolTipDisableReason)
        boxHelpAndSupport.setDisableWithRaason(reason: toolTipDisableReason)

        // The add-on TOOLS tabs are created programmatically (installToolsAddOnItems), so they aren't
        // storyboard outlets and were missing from this disable pass — leaving Focus Button / Time
        // Tracker / Late No More clickable on the login and onboarding screens, which let a logged-out
        // user leave the login view with no way back. Optionals: nil until the tools are installed.
        boxFocusButtonTool?.setDisableWithRaason(reason: toolTipDisableReason)
        boxTimeTrackerTool?.setDisableWithRaason(reason: toolTipDisableReason)
        boxLateNoMoreTool?.setDisableWithRaason(reason: toolTipDisableReason)
    }
    
    
    func habitOver(){
        mainWindowControllerObj?.restoreWindowAfterPostponement()
        enableAllItems()
        reloadHabitStatus()
        mainViewControllerObj?.expandLeftPanel()
        resumeIfAnyFocusMusicStoppedAutomatically()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }
    
    func microBreaksStarted(){
        let toolTipDisableReason = disableReasonMircoBreaks
        
        boxEditHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxSettings.setDisableWithRaason(reason: toolTipDisableReason)
        boxBlocks.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.isEnabled = true
        boxFocusSession.setDisableWithRaason(reason: toolTipDisableReason)
        boxHabits.setDisableWithRaason(reason: toolTipDisableReason)
        boxCustomRoutine.setDisableWithRaason(reason: toolTipDisableReason)
        
        boxMicroBreaks.isSelected = true
        mainViewControllerObj?.showHabitsView()
        pauseAutomaticallyIfAnyFocusMusicPlaying()
        mainViewControllerObj?.collapseLeftPanel()
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    
    func microBreaksOver(){
        resumeIfAnyFocusMusicStoppedAutomatically()
        mainViewControllerObj?.expandLeftPanel()
        enableAllItems()
        
        //Don't show brain dump after microbreak
        //        #1565     v 2.28.436  28/11/25
        if isFocusModeOn(){
            if let breaksBrainDumpVcObj = breaksBrainDumpVcObj{
                if let id = breaksBrainDumpVcObj.taskIdSaveFromBrainDump, let taskTitle = breaksBrainDumpVcObj.taskSaveFromBrainDump{
                    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: false)
                    breaksBrainDumpVcObj.taskIdSaveFromBrainDump = nil
                    breaksBrainDumpVcObj.taskSaveFromBrainDump = nil
                }
            }
        }else if isHardCorePomodoroModeOn{//Super Focus session stops blocking after closing the break popup; session remains active but blocking and timer disappear#1572  v 2.28.440   (resume super pomodoro after micro breaks)
            appdelegate?.showAutoPomodoroModeView()
        }
        mainWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }

    func enableAllItems(){
        boxMotivation.isEnabled = true
        boxEditHabits.isEnabled = true
        boxSettings.isEnabled = true
        boxBlocks.isEnabled = true

        boxFocusMusic.isEnabled = true
        boxBrainDump.isEnabled = true
        boxBrowsersTabAudit.isEnabled = true
        boxTodoPlayer.isEnabled = true

        boxMicroBreaks.isEnabled = true
        boxFocusSession.isEnabled = true
        boxHabits.isEnabled = true

        boxCustomRoutine.isEnabled = true
        boxUpgradeNow.isEnabled = true
        boxHelpAndSupport.isEnabled = true

        // Re-enable the programmatic TOOLS tabs alongside the rest, so they recover after the login/
        // onboarding disable pass (disableAllTabForOnboarding). Optionals: nil until tools are installed.
        // isEnabled is independent of the user's hide choice (ToolVisibilityStore/isHidden), so a hidden
        // tool stays hidden regardless.
        boxFocusButtonTool?.isEnabled = true
        boxTimeTrackerTool?.isEnabled = true
        boxLateNoMoreTool?.isEnabled = true
    }
    
    func showPomodoro(pomodoroVcObj:NSView){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusSessionView(pomodoroView: pomodoroVcObj)
    }
    
    
    func showHabitsView(){
        boxHabits.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }
    
    func showBreaksView(){
        boxMicroBreaks.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }
    
    func showCustomRoutineView(){
        boxCustomRoutine.isSelected = true
        mainViewControllerObj?.showHabitsView()
    }

    func showBrainDump(){
        boxBrainDump.isSelected = true
        mainViewControllerObj?.showBrainDumpView()
    }
    
    func showBrowsersTabAuditView(){
        boxBrowsersTabAudit.isSelected = true
        mainViewControllerObj?.showBrowsersTabAuditView()
    }
    
    func showAllTracks(){
        boxFocusMusic.isSelected = true
        mainViewControllerObj?.showAllTracksView()
    }
    
    func showTaskPlayer(){
        boxTodoPlayer.isSelected = true
        mainViewControllerObj?.showTaskView()
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                boxTodoPlayer.isEnabled = true
            }
        }
    }
    
    func showFocusCompletedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusCompletedView()
    }
    
    func showFocusAbortedView(){
        boxFocusSession.isSelected = true
        mainViewControllerObj?.showFocusAbortedView()
    }
    
    func showCustomScheduleAbortedView(){
        if abortingCustomScheduleBlockingVcObj != nil{
            if abortingCustomScheduleBlockingVcObj?.isViewVisible ?? false{
                return;
            }
        }
        boxFocusSession.isSelected = true
        if SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.menuShowPomodoroModeView()
        }else{
            appdelegate?.menuShowSimplePomodoroModeView()
        }
        if self.view.window != nil{
            self.presentAsSheet(getAbortingCustomScheduleBlockingVcObject())
        }
        getAbortingCustomScheduleBlockingVcObject().resetData()
    }
    
    func showHelpAndSupportView(){
        boxHelpAndSupport.isSelected = true
        mainViewControllerObj?.showHelpView()
    }
    
    
    func showSettingsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        if !(mainWindowControllerObj!.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(self)
        }
        boxSettings.isSelected = true
        mainViewControllerObj?.showSettingsView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    
    func showFocusModeSettingsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        if !(leftMenuVcObj?.boxBlocks.isSelected ?? false){
            leftMenuVcObj?.boxBlocks.isSelected = true
        }
        mainViewControllerObj?.showFocusPreferencesView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    
    func showBlocksView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxBlocks.isSelected = true
        mainViewControllerObj?.showBlocksPreferencesView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    func showFocusModeStateView(){
        boxFocusSession.isSelected = true
        showFocusSessionTabContent()
    }

    /// Puts the right screen in the Focus Session tab: the ongoing-session screen while there IS a
    /// session, otherwise the start-a-session screen.
    ///
    /// The single funnel for both the left-menu click and every `showRunningFocusSessionWindow()`
    /// caller, so the two can't drift. A running **blocking schedule** is not a session and must land
    /// on "start a session" — report 2026-09-16_15-13-57: an all-day schedule left the tab stuck on
    /// "Ongoing Focus Session" (headed with the *schedule's* block list), with no way to start a real
    /// one. The schedule stays visible — it still blocks, and the start screen names it.
    func showFocusSessionTabContent(){
        switch FocusSessionRouting.destinationNow{
        case .runningSession:
            mainViewControllerObj?.showFocusModeState()
        case .startSession:
            showStartFocusSessionView()
        }
    }

    /// The start-a-session screen — advanced in geek mode, simple otherwise. Each entry point returns
    /// early for the mode it isn't, so the choice has to be made here.
    func showStartFocusSessionView(){
        if SettingsManagerObject.isGeekModeEnabled{
            appdelegate?.menuShowPomodoroModeView()
        }else{
            appdelegate?.menuShowSimplePomodoroModeView()
        }
    }

    func showEditHabitsView(){
        if mainViewControllerObj?.isEnterPasswordForPreferencesViewVisible() ?? false{
            return;
        }
        
        boxEditHabits.isSelected = true
        mainViewControllerObj?.showEditHabitsView()
        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
    }
    
    /// "Focusing (29m left)" — the running session and how much of it is left.
    private func focusingRowTitle() -> String {
        var template = "Focusing (<MINUTES>m left)"   // i18n-ignore: last-resort default; the real string comes from config (menuFocusingTimeLeft)
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            template = leftMenuVcInfo.value(forKey: "menuFocusingTimeLeft") as? String ?? template
        }
        guard let end = endFocusModeTime else { return template.replacingOccurrences(of: "<MINUTES>", with: "0") }
        let minutes = FocusSessionClock.minutesRemaining(until: end)
        return template.replacingOccurrences(of: "<MINUTES>", with: "\(minutes)")
    }

    /// Keeps the countdown in the row's title honest while a session runs. Deliberately re-enters
    /// `resetFocusModeTitle()` so the title has exactly one place it is computed, and every other
    /// branch of that method stops the ticker — so pause, finish and abort all revert cleanly.
    private func startFocusMinutesTicker(){
        guard focusMinutesTimer == nil else { return }
        let timer = Timer(timeInterval: leftMenuFocusMinutesTickInterval, repeats: true) { [weak self] _ in
            self?.resetFocusModeTitle()
        }
        RunLoop.main.add(timer, forMode: .common)
        focusMinutesTimer = timer
    }

    private func stopFocusMinutesTicker(){
        focusMinutesTimer?.invalidate()
        focusMinutesTimer = nil
    }

    /// The TOOLS entry is the To-do list in every session state. It used to flip to "Todo Player"
    /// while a focus session, allowed activity or blocking schedule was running, because the slot then
    /// opened the web To-do Player instead; the running session now carries its own native task queue,
    /// so the slot is only ever the list. Kept as one helper so the title has a single source.
    private func applyTodoToolTitle(){
        boxTodoPlayer.title = "Todo List"   // i18n-ignore: last-resort default; the real string comes from config (menuTodoList)
        if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
            boxTodoPlayer.title = leftMenuVcInfo.value(forKey: "menuTodoList") as? String ?? boxTodoPlayer.title
        }
    }

    /// Session start / finish no longer change the TOOLS title, but both are called from ~20 places
    /// across the routine, pomodoro and blocking paths; they stay as the one place that would need to
    /// react if the tool ever becomes session-dependent again.
    func focusModeOrFocusModeHabitStarted(){// also for custom schedule blocking
        applyTodoToolTitle()
    }

    func focusModeOrFocusModeHabitFinished(){
        applyTodoToolTitle()
    }

    @IBAction func btnExpandLeftMenuClicked(_ sender: Any) {
        mainViewControllerObj?.toggleLeftPaneWidth()
    }
}

var idGeneral = "General"
var idStats = "Stats"
var idFocus = "Focus"
var idEditHabits = "EditHabits"
var idSettings = "Settings"
var idHelp = "Help"
var idTabStrictness = "tabStrictness"
