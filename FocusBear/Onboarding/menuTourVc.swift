//
//  menuTour.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class menuTourVc: NSViewController {// not in use  v2.28.446

    @IBOutlet weak var topSpaceBoxStartFocus: NSLayoutConstraint! //89 & 49
    @IBOutlet weak var boxTools: NSBox!
    @IBOutlet weak var boxStartPomodoro: NSBox!
    @IBOutlet weak var constraintsBoxPreferencesTop: NSLayoutConstraint!
    @IBOutlet weak var boxStartRoutine: NSBox!
    @IBOutlet weak var btnSkip: Button!
    @IBOutlet weak var boxHeader: NSBox!
    @IBOutlet weak var boxMenu: NSBox!
    @IBOutlet weak var imgViewMenu: NSImageView!
    @IBOutlet weak var boxPreferences: NSBox!
    @IBOutlet weak var boxSetupFocusMode: NSBox!
    
    var isHabitsDisabled: Bool = false
    let popoverMenuTour = NSPopover()
    let menuTourPopoverVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourPopoverVc")) as? menuTourPopoverVc
    
    var currentIndex = 0
    var indexText = "<CURRENTINDEX> of <TOTALCOUNT>"
    var arrTourMessages:[[String:Any]] = [["title": "Focus Bear", "description": "Let's get you familiar with the Focus Bear Menu and we will have you up and running in no time!", "buttonTitle": "Get Started"],
                           ["title": "Start first routine", "description": "Your first morning routine does not starts automatically on first day. Click Start first routine to initiate your first routine.", "buttonTitle": "Next >"],
                           ["title": "Preferences", "description": "Click on the \"Preferences\" to", "buttonTitle": "Next >", "arrayListItems":["Edit activities for your morning routine, evening routine, breaks throught the day.", "Setup or change Password.", "View your progress stats."]],
                           ["title": "Setup Focus mode", "description": "Setup focus modes to et into deep work with distraction blocking. You can remove blocks if you have an emergency.", "buttonTitle": "Finish"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        popoverMenuTour.contentViewController = menuTourPopoverVcObj
        popoverMenuTour.animates = false
        popoverMenuTour.behavior = .applicationDefined
       
        
        var itemStartPomodoroTitle = "Start Focus Session"
        var descriptionPomodoro = "You may want to Start a Focus session to focus on specific work for a set duration."
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            itemStartPomodoroTitle = menuInfo.value(forKey: "menuItemStartPomodoroTitle") as? String ?? itemStartPomodoroTitle
            descriptionPomodoro = menuInfo.value(forKey: "toolTipPomodoroSessionText") as? String ?? descriptionPomodoro
        }

        var buttonGetStartedText = "Get Started"
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        btnSkip.title = "Skip"
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkip.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
        
        
        var tourMenu = "Focus Bear"
        var descriptionMenu = "Let's get you familiar with the Focus Bear Menu and we will have you up and running in no time!"
        var tourFirstRoutine = "Start first routine"
        var descriptionFirstRoutine = "Your first morning routine does not starts automatically on first day. Click Start first routine to initiate your first routine."
        var tourPreferences = "Preferences"
        var descriptionPreferences = "Click on \"Preferences\" to"
        var arrayListItemsPreferences = [
            "Edit activities for your morning routine, evening routine, breaks throughout the day.",
            "Setup or change Password.",
            "View your progress stats."
        ]
        var tourSetupFocusMode = "Setup Focus mode"
        var descriptionSetupFocusMode = "Setup focus modes to get into deep work with distraction blocking. You can remove blocks if you have an emergency."
        
        var itemToolsTitle = "Tools"
        var descriptionTools = "A collection of helpful tools including Brain Dump, To-Do List/To-Do Player, focus music, and more."
        
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            buttonGetStartedText = menuTourVcInfo.value(forKey: "buttonGetStartedText") as? String ?? buttonGetStartedText
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
            indexText = menuTourVcInfo.value(forKey: "indexText") as? String ?? indexText
            
            
            tourMenu = menuTourVcInfo.value(forKey: "tourMenu") as? String ?? tourMenu
            descriptionMenu = menuTourVcInfo.value(forKey: "descriptionMenu") as? String ?? descriptionMenu
            tourFirstRoutine = menuTourVcInfo.value(forKey: "tourFirstRoutine") as? String ?? tourFirstRoutine
            descriptionFirstRoutine = menuTourVcInfo.value(forKey: "descriptionFirstRoutine") as? String ?? descriptionFirstRoutine
            
            if isShutOffTimeGoing(){
                descriptionFirstRoutine = "Your evening routine does not start automatically on the first day. Click Start evening routine to kick off your first routine."
                descriptionFirstRoutine = menuTourVcInfo.value(forKey: "descriptionEveningRoutine") as? String ?? descriptionFirstRoutine
            }else{
                descriptionFirstRoutine = "Your morning routine does not start automatically on the first day. Click Start morning routine to kick off your first routine."
                descriptionFirstRoutine = menuTourVcInfo.value(forKey: "descriptionMorningRoutine") as? String ?? descriptionFirstRoutine
            }
            
            tourPreferences = menuTourVcInfo.value(forKey: "tourPreferences") as? String ?? tourPreferences
            descriptionPreferences = menuTourVcInfo.value(forKey: "descriptionPreferences") as? String ?? descriptionPreferences
            arrayListItemsPreferences = menuTourVcInfo.value(forKey: "arrayListItemsPreferences") as? [String] ?? arrayListItemsPreferences
            tourSetupFocusMode = menuTourVcInfo.value(forKey: "tourSetupFocusMode") as? String ?? tourSetupFocusMode
            descriptionSetupFocusMode = menuTourVcInfo.value(forKey: "descriptionSetupFocusMode") as? String ?? descriptionSetupFocusMode
            
            itemToolsTitle = menuTourVcInfo.value(forKey: "tourTools") as? String ?? itemToolsTitle
            descriptionTools = menuTourVcInfo.value(forKey: "descriptionTools") as? String ?? descriptionTools
        }
        
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            if isShutOffTimeGoing(){
                tourFirstRoutine = "Start evening routine"
                tourFirstRoutine = menuInfo.value(forKey: "menuItemStartEveningHabitsFirstTimeTitle") as? String ?? tourFirstRoutine
            }else{
                tourFirstRoutine = "Start morning routine"
                tourFirstRoutine = menuInfo.value(forKey: "menuItemStartMorningHabitsFirstTimeTitle") as? String ?? tourFirstRoutine
            }
        }
        
        arrTourMessages.removeAll()
        arrTourMessages.append(["title": tourMenu, "description": descriptionMenu, "box": boxHeader as Any])
        
       
        isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
        arrTourMessages.append(["title": tourPreferences, "description": descriptionPreferences, "arrayListItems": arrayListItemsPreferences, "box": boxPreferences as Any])
        if !isHabitsDisabled{
            imgViewMenu.image = NSImage(named: NSImage.Name("menu_ScreenShot_MorningRoutine_new"))
            arrTourMessages.append(["title": tourFirstRoutine, "description": descriptionFirstRoutine, "box": boxStartRoutine as Any])
            topSpaceBoxStartFocus.constant = 89
        }else{
            imgViewMenu.image = NSImage(named: NSImage.Name("menu_HabitDisabled_ScreenShot_new"))
            topSpaceBoxStartFocus.constant = 49
        }
        
        
        
        arrTourMessages.append(["title": itemStartPomodoroTitle, "description": descriptionPomodoro, "box": boxStartPomodoro as Any])
        
        
        
        
        arrTourMessages.append(["title": itemToolsTitle, "description": descriptionTools, "box": boxTools as Any])
        
        
        for i in 0..<arrTourMessages.count{
            if i == 0{
                arrTourMessages[i]["buttonTitle"] = buttonGetStartedText
            }else if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
        
        menuTourPopoverVcObj?.delegate = self
        menuTourPopoverVcObj?.loadView()
        menuTourPopoverVcObj?.lblMainTitle.stringValue = "Focus Bear Menu"
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            menuTourPopoverVcObj?.lblMainTitle.stringValue = menuTourVcInfo.value(forKey: "title") as? String ?? "Focus Bear Menu"//
        }
        addLog(text: "menuTourVc viewDidLoad")
    }
    
    override func viewDidAppear() {
        addLog(text: "menuTourVc viewDidAppear")
        DispatchQueue.global().async {
            sleep(2)
            DispatchQueue.main.async {
                self.startTour()
            }
        }
        
        if !isHabitsDisabled{
            if isShutOffTimeGoing(){
                imgViewMenu.image = NSImage(named: NSImage.Name("menu_ScreenShot_EveningRoutine_new"))
            }else{
                imgViewMenu.image = NSImage(named: NSImage.Name("menu_ScreenShot_MorningRoutine_new"))
            }
        }
    }
    
    func startTour(){
        if let box = arrTourMessages[currentIndex]["box"] as? NSBox {
            popoverMenuTour.show(relativeTo: box.bounds, of: box, preferredEdge: NSRectEdge.minX)
            
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] as? String ?? "", description: arrTourMessages[currentIndex]["description"] as? String ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] as? String ?? "", indexText: currentIndexText, arrList: arrTourMessages[currentIndex]["arrayListItems"] as? [String] ?? [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
        }
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        popoverMenuTour.close()
        self.view.window?.close()

        if !(menuViewControllerObj?.isViewLoaded ?? false){
            menuViewControllerObj?.loadView()
        }
        allApiObject.capturePosthog(event: "menu_tour_close_clicked", metadata: [:])

//        showAskProcrastinatingWindow()
//        if !isEmailVerified{
//            showUnverifiedEmailWindow()
//        }
    }
    
//    func showAlertSetupComplete(){
//        addLog(text: "menuTourVc show Alert Setup Complete")
//        allApiObject.capturePosthog(event: "menu_tour_setup_complete", metadata: [:])
//        let alert = NSAlert()
//        alert.setSharingType()
//        alert.messageText = "Setup complete!"
//        alert.informativeText = "To get up and running quickly, have a read of our quick start guide."
//        var buttonOkText = "Enlighten me"
//        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
//            alert.messageText = menuTourVcInfo.value(forKey: "titleAlertSetupComplete") as? String ?? alert.messageText
//            alert.informativeText = menuTourVcInfo.value(forKey: "subTitleAlertSetupComplete") as? String ?? alert.informativeText
//            buttonOkText = menuTourVcInfo.value(forKey: "buttonOkText") as? String ?? buttonOkText
//        }
//        alert.addButton(withTitle: buttonOkText)
//        NSApplication.shared.activate(ignoringOtherApps: true)
//        alert.runModal()
//
//        if let url = URL(string: "https://www.focusbear.io/en/post-install-mac"){
//            NSWorkspace.shared.open(url)
//        }
//    }
    func btnNextClickedFromPopover(){
        addLog(text: "menuTourVc button Next Clicked From Popover")
        allApiObject.capturePosthog(event: "menu_tour_next_clicked", metadata: [:])
        currentIndex += 1
        
        if currentIndex < arrTourMessages.count{
            if let box = arrTourMessages[currentIndex]["box"] as? NSBox {
                popoverMenuTour.show(relativeTo: box.bounds, of: box, preferredEdge: NSRectEdge.minX)
            }
            var currentIndexText = indexText.replacingOccurrences(of: "<CURRENTINDEX>", with: "\(currentIndex + 1)")
            currentIndexText = currentIndexText.replacingOccurrences(of: "<TOTALCOUNT>", with: "\(arrTourMessages.count)")
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] as? String ?? "", description: arrTourMessages[currentIndex]["description"] as? String ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] as? String ?? "", indexText: "\(currentIndex + 1) of \(arrTourMessages.count)", arrList: arrTourMessages[currentIndex]["arrayListItems"] as? [String] ?? [], progress: currentIndex + 1, progressMaxValue: arrTourMessages.count)
        }else{
            popoverMenuTour.close()
            self.view.window?.close()
            
            if !(menuViewControllerObj?.isViewLoaded ?? false){
                menuViewControllerObj?.loadView()
            }
//            showAskProcrastinatingWindow()
//            if !isEmailVerified{
//                showUnverifiedEmailWindow()
//            }
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        popoverMenuTour.close()
        self.view.window?.close()
        
        if !(menuViewControllerObj?.isViewLoaded ?? false){
            menuViewControllerObj?.loadView()
        }

        allApiObject.capturePosthog(event: "menu_tour_Skip_clicked", metadata: [:])
//        showAskProcrastinatingWindow()
//        if !isEmailVerified{
//            showUnverifiedEmailWindow()
//        }
    }
    
    @IBAction func btnBgClicked(_ sender: Any) {
        var thisIsDemoText = "This is a demo - you can open the menu after the tour is done"
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            thisIsDemoText = menuTourVcInfo.value(forKey: "thisIsDemoText") as? String ?? thisIsDemoText
        }
        showTooltip(sender: boxMenu, msg: thisIsDemoText, preferredEdge: .minY, maxWidthVal: 250)
    }
}

extension menuTourVc: TourDelegate{
    func buttonNextClicked() {
        btnNextClickedFromPopover()
    }
    func buttonCloseClicked() {
        btnCloseClicked(self)
    }
}
