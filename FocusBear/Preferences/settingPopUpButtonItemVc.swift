//
//  settingPopUpButtonItemVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

protocol SettingPopUpButtonItemDelegate {
    func popUpButtonClicked(index:Int, object:settingPopUpButtonItemVc)
}

class settingPopUpButtonItemVc: NSViewController {

    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lineBottom: NSBox!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    var delegate: SettingPopUpButtonItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    var toolTip = ""{
        didSet{
            if toolTip.isEmpty{
                btnInfo.isHidden = true
            }else{
                btnInfo.isHidden = false
            }
        }
    }
    
    @IBAction func popUpBtnClicked(_ sender: Any) {
        delegate?.popUpButtonClicked(index: popUpBtn.indexOfSelectedItem, object: self)
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
