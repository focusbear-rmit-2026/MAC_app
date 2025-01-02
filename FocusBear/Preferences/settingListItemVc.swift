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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func btnClicked(_ sender: Any) {
        delegate?.buttonClicked(object: self)
    }
    @IBAction func btnInfoClicked(_ sender: Any) {
        showTooltip(sender: btnInfo, msg: toolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:350)
    }
}
