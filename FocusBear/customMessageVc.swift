//
//  customMessageVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class customMessageVc: NSViewController {

    @IBOutlet weak var lblMessage: NSTextField!
    @IBOutlet weak var btnOk: Button!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnOk.title = buttonOkText
    }
    
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.removeFromSuperview()
        getHabitsVcObject().okClickedFromCustomMessage()
    }
}
