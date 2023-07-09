//
//  menuTour.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class menuTourVc: NSViewController {

    @IBOutlet weak var boxHeader: NSBox!
    @IBOutlet weak var boxMenu: NSBox!
    @IBOutlet weak var imgViewMenu: NSImageView!
    @IBOutlet weak var leadingMenu: NSLayoutConstraint!
    @IBOutlet weak var boxPreferences: NSBox!
    @IBOutlet weak var boxSetupFocusMode: NSBox!
    
    
    let popoverMenuTour = NSPopover()
    let menuTourPopoverVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourPopoverVc")) as? menuTourPopoverVc
    
    var currentIndex = 0
    
    var arrTourMessages = [["title": "Focus Bear", "description": "Let's get you familiar with the Focus Bear Menu and we will have you up and running in no time!", "buttonTitle": "Get Started"],
                           ["title": "Preferences", "description": "Click on the \"Preferences\" to", "buttonTitle": "Next >", "arrayListItems":["Edit activities for your morning routine, evening routine, breaks throught the day.", "Setup or change Password.", "View your progress stats."]],
                           ["title": "Setup Focus mode", "description": "Setup focus modes to et into deep work with distraction blocking. You can remove blocks if you have an emergency.", "buttonTitle": "Finish"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        if let frame = appdelegate?.statusbutton?.window?.frame{
            let leading = frame.midX - (self.imgViewMenu.frame.width / 2)
            leadingMenu.constant = leading
        }

        popoverMenuTour.contentViewController = menuTourPopoverVcObj
        popoverMenuTour.animates = false
        popoverMenuTour.behavior = .applicationDefined
       
        var buttonGetStartedText = "Get Started"
        var buttonNextText = "Next >"
        var buttonFinishText = "Finish"
        
        
        
        if let menuTourVcInfo = configjson.value(forKey: "menuTourVcInfo") as? NSDictionary{
            arrTourMessages = menuTourVcInfo.value(forKey: "tourMessagesInfo") as? [[String:Any]] ?? arrTourMessages
            buttonGetStartedText = menuTourVcInfo.value(forKey: "buttonGetStartedText") as? String ?? buttonGetStartedText
            buttonNextText = menuTourVcInfo.value(forKey: "buttonNextText") as? String ?? buttonNextText
            buttonFinishText = menuTourVcInfo.value(forKey: "buttonFinishText") as? String ?? buttonFinishText
        }
        
        for i in 0..<arrTourMessages.count{
            if i == 0{
                arrTourMessages[i]["buttonTitle"] = buttonGetStartedText
            }else if i == arrTourMessages.count - 1{
                arrTourMessages[i]["buttonTitle"] = buttonFinishText
            }else{
                arrTourMessages[i]["buttonTitle"] = buttonNextText
            }
        }
    }
    
    override func viewDidAppear() {
        popoverMenuTour.show(relativeTo: boxHeader.bounds, of: boxHeader, preferredEdge: NSRectEdge.minX)
        menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] as? String ?? "", description: arrTourMessages[currentIndex]["description"] as? String ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] as? String ?? "", indexText: "\(currentIndex + 1) of \(arrTourMessages.count)", arrList: arrTourMessages[currentIndex]["arrayListItems"] as? [String] ?? [], progress: currentIndex + 1)
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        popoverMenuTour.close()
        self.view.window?.close()
    }
    
    func btnNextClickedFromPopover(){
        currentIndex += 1
        if currentIndex == 1{
            popoverMenuTour.show(relativeTo: boxPreferences.bounds, of: boxPreferences, preferredEdge: NSRectEdge.minX)
        }else if currentIndex == 2{
            popoverMenuTour.show(relativeTo: boxSetupFocusMode.bounds, of: boxSetupFocusMode, preferredEdge: NSRectEdge.minX)
        }
        if currentIndex < arrTourMessages.count{
            menuTourPopoverVcObj?.showCurrentMessage(title: arrTourMessages[currentIndex]["title"] as? String ?? "", description: arrTourMessages[currentIndex]["description"] as? String ?? "", buttonTitle: arrTourMessages[currentIndex]["buttonTitle"] as? String ?? "", indexText: "\(currentIndex + 1) of \(arrTourMessages.count)", arrList: arrTourMessages[currentIndex]["arrayListItems"] as? [String] ?? [], progress: currentIndex + 1)
        }else{
            popoverMenuTour.close()
            self.view.window?.close()
        }
    }
}
