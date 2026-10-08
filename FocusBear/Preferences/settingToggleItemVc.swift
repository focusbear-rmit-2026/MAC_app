//
//  settingToggleItemVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

protocol SettingToggleItemDelegate {
    func switchClicked(state:NSControl.StateValue, object:settingToggleItemVc)
}

class settingToggleItemVc: NSViewController {

    @IBOutlet weak var stackViewMain: NSStackView!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lineBottom: NSBox!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var btnSwitch: NSSwitch!
    @IBOutlet weak var lblTitle: NSTextField!
    var delegate: SettingToggleItemDelegate?
    private var switchNameObservation: NSKeyValueObservation?
    
    var toolTip = ""{
        didSet{
            if toolTip.isEmpty{
                btnInfo.isHidden = true
            }else{
                btnInfo.isHidden = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchNameObservation = btnSwitch.keepAccessibilityName(matching: lblTitle)
    }
    
    @IBAction func btnSwitchClicked(_ sender: Any) {
        delegate?.switchClicked(state: btnSwitch.state, object: self)
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}

extension NSControl {
    /// Names the control after the label drawn beside it, as VoiceOver otherwise announces a bare
    /// "switch" or "pop-up button". Settings rows load from the storyboard with placeholder text and
    /// the pane that builds them titles them afterwards, so the name follows the label's text rather
    /// than being copied once. Keep the returned observation alive with the row.
    func keepAccessibilityName(matching label: NSTextField) -> NSKeyValueObservation {
        label.observe(\.stringValue, options: [.initial]) { [weak self] label, _ in
            self?.setAccessibilityLabel(label.stringValue)
        }
    }
}

extension NSImageView {
    /// For an icon whose meaning is already in the text beside it. An image view reaches VoiceOver
    /// through its cell as well as itself, so both are hidden.
    func hideDecorativeIconFromVoiceOver() {
        setAccessibilityElement(false)
        cell?.setAccessibilityElement(false)
    }
}
