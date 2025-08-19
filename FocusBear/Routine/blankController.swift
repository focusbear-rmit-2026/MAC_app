//
//  blankController.swift
//  FocusBear
//
//  Created by Manish Jain on 13/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


class blankController: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        lblTitle.stringValue = appName//"Focus Bear"
    }
}
