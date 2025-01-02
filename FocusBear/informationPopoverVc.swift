//
//  informationPopoverVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 25/07/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class informationPopoverVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblMainTitle: NSTextField!
    @IBOutlet weak var btnClose: cursorButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    func showCurrentMessage(mainTitle:String, title:String, description:String){
        addLog(text: "informationPopoverVc showCurrentMessage")
        lblTitle.stringValue = title
        lblDescription.stringValue = description
        lblMainTitle.stringValue = mainTitle
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        popoverInformation?.close()
    }
}
