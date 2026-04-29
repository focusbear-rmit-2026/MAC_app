//
//  messageBoxVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/02/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class messageBoxVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    func resetView(title:String){
        lblTitle.stringValue = title
    }
}
