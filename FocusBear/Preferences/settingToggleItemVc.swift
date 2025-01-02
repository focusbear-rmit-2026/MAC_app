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
        // Do view setup here.
    }
    
    @IBAction func btnSwitchClicked(_ sender: Any) {
        delegate?.switchClicked(state: btnSwitch.state, object: self)
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
