//
//  settingListItemVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

protocol SettingListItemDelegate {
    func buttonClicked(object:settingListItemVc)
}

class settingListItemVc: NSViewController {

    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var btnRow: settingsMouseDownEffectButton!
    @IBOutlet weak var imgViewChevron: NSImageView!
    @IBOutlet weak var boxNewBadge: customNewBadgeBox!
    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var imgViewIcon: NSImageView!
    @IBOutlet weak var lineBottom: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var toolTip = ""{
        didSet{
            if toolTip.isEmpty{
                btnInfo.isHidden = true
            }else{
                btnInfo.isHidden = false
            }
        }
    }
    var delegate: SettingListItemDelegate?
    private var rowNameObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // The row is one untitled button laid over its icon, title and chevron: the button reads the
        // title, so the label itself would be read twice.
        rowNameObservation = btnRow.keepAccessibilityName(matching: lblTitle)
        lblTitle.setAccessibilityElement(false)
        imgViewIcon.hideDecorativeIconFromVoiceOver()
        imgViewChevron.hideDecorativeIconFromVoiceOver()
    }
    
    @IBAction func btnClicked(_ sender: Any) {
        delegate?.buttonClicked(object: self)
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
