//
//  AdvancedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import AppKit

class advancedVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var boxMain: NSBox!
    @IBOutlet weak var stackView: NSStackView!

    let meetingsListItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let privacyListItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
//    let breaksListItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let addOnsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let researchItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let talkingClockListItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc

    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.subviews.removeAll()

        var meetingsSettingTitle = "Meetings"
        var privacySettingTitle = "Privacy"
        var addOnsSettingTitle = "Add Ons"
        var researchSettingTitle = "Research"
        let talkingClockSettingTitle = "Talking Clock"
        
        var iconPrivacy:NSImage?
        var iconMeetings:NSImage?
        var iconAddOns:NSImage?
        var iconResearch:NSImage?
        var iconTalkingClock:NSImage?
        
        if #available(macOS 11.0, *) {
            iconPrivacy = NSImage(systemSymbolName: "eye", accessibilityDescription: nil)
            iconMeetings = NSImage(systemSymbolName: "headphones.circle", accessibilityDescription: nil)
            iconAddOns = NSImage(systemSymbolName: "plus.diamond", accessibilityDescription: nil)
            iconResearch = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: nil)
            iconTalkingClock = NSImage(systemSymbolName: "clock.badge.fill", accessibilityDescription: nil)
        } else {
            iconPrivacy = NSImage(named: NSImage.touchBarHistoryTemplateName)
            iconMeetings = NSImage(named: NSImage.everyoneName)
            iconAddOns = NSImage(named: NSImage.touchBarAddDetailTemplateName)
            iconResearch = NSImage(named: NSImage.touchBarSearchTemplateName)
            iconTalkingClock = NSImage(named: NSImage.touchBarAlarmTemplateName)
        }
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            meetingsSettingTitle = settingsNew.value(forKey: "meetingsSettingTitle") as? String ?? meetingsSettingTitle
            privacySettingTitle = settingsNew.value(forKey: "privacySettingTitle") as? String ?? privacySettingTitle
            addOnsSettingTitle = settingsNew.value(forKey: "addOnsTitle") as? String ?? addOnsSettingTitle
            researchSettingTitle = settingsNew.value(forKey: "researchSettingTitle") as? String ?? researchSettingTitle
        }
        
        var advanced_Meetings = "Change settings related to meetings"
        var advanced_Privacy = "Configure privacy related settings"
        var advanced_AddOns = "We've built add ons to help you with punctuality and tracking your time."
        let advanced_TalkingClock = "Announce the current time at regular intervals to help you stay time-aware."
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            advanced_Meetings = tooltips.value(forKey: "advanced_Meetings") as? String ?? advanced_Meetings
            advanced_Privacy = tooltips.value(forKey: "advanced_Privacy") as? String ?? advanced_Privacy
            advanced_AddOns = tooltips.value(forKey: "advanced_AddOns") as? String ?? advanced_AddOns
        }
        
        stackView.addView(meetingsListItemVcObj!.view, in: .bottom)
        meetingsListItemVcObj?.lblTitle.stringValue = meetingsSettingTitle
        meetingsListItemVcObj?.imgViewIcon.image = iconMeetings
        meetingsListItemVcObj?.lblDescription.isHidden = true
        meetingsListItemVcObj?.delegate = self
        meetingsListItemVcObj?.toolTip = advanced_Meetings
        
        stackView.addView(privacyListItemVcObj!.view, in: .bottom)
        privacyListItemVcObj?.lblTitle.stringValue = privacySettingTitle
        privacyListItemVcObj?.imgViewIcon.image = iconPrivacy
        privacyListItemVcObj?.lblDescription.isHidden = true
        privacyListItemVcObj?.delegate = self
        privacyListItemVcObj?.toolTip = advanced_Privacy
        

        
        stackView.addView(addOnsItemVcObj!.view, in: .bottom)
        addOnsItemVcObj?.lblTitle.stringValue = addOnsSettingTitle
        addOnsItemVcObj?.imgViewIcon.image = iconAddOns
        addOnsItemVcObj?.lblDescription.isHidden = true
        addOnsItemVcObj?.delegate = self
        addOnsItemVcObj?.toolTip = advanced_AddOns

        stackView.addView(talkingClockListItemVcObj!.view, in: .bottom)
        talkingClockListItemVcObj?.lblTitle.stringValue = talkingClockSettingTitle
        talkingClockListItemVcObj?.imgViewIcon.image = iconTalkingClock
        talkingClockListItemVcObj?.lblDescription.isHidden = true
        talkingClockListItemVcObj?.delegate = self
        talkingClockListItemVcObj?.toolTip = advanced_TalkingClock

        stackView.addView(researchItemVcObj!.view, in: .bottom)
        researchItemVcObj?.lblTitle.stringValue = researchSettingTitle
        researchItemVcObj?.imgViewIcon.image = iconResearch
        researchItemVcObj?.lblDescription.isHidden = true
        researchItemVcObj?.delegate = self
        researchItemVcObj?.lineBottom.isHidden = true
        
        
        arrForSearchFromSettings.append(["title": meetingsListItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": meetingsListItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": privacyListItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": privacyListItemVcObj!.bgBox as Any])
//        arrForSearchFromSettings.append(["title": breaksListItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": breaksListItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": addOnsItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": addOnsItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": talkingClockListItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": talkingClockListItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": researchItemVcObj!.lblTitle.stringValue, "tabId": idAdvanced, "object": researchItemVcObj!.bgBox as Any])
        identifyRowsForUITests()
    }

    private func identifyRowsForUITests() {
        let rows: [(settingListItemVc?, String)] = [(meetingsListItemVcObj, idMeetings), (privacyListItemVcObj, idPrivacy),
                                                     (addOnsItemVcObj, idAddOns), (talkingClockListItemVcObj, idTalkingClock),
                                                     (researchItemVcObj, idResearch)]
        for (row, pageId) in rows {
            row?.btnRow.setAccessibilityIdentifier(UITestContract.Identifier.SettingsRegression.advancedRowPrefix + pageId)
        }
    }
    override func viewWillAppear() {
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{9
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
    }
}
extension advancedVc: SettingListItemDelegate{
    func buttonClicked(object:settingListItemVc) {
        if object == meetingsListItemVcObj{
            settingsContainerVcObj?.showMeetingDetactionView()
        }else if object == privacyListItemVcObj{
            settingsContainerVcObj?.showPrivacyView()
        }else if object == addOnsItemVcObj{
            settingsContainerVcObj?.showAddOnsView()
        }else if object == talkingClockListItemVcObj{
            settingsContainerVcObj?.showTalkingClockView()
        }else if object == researchItemVcObj{
            settingsContainerVcObj?.showResearchSettingView()
        }
    }
}
