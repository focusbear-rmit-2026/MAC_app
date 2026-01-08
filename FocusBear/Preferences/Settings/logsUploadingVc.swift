//
//  logsUploadingVc.swift
//  FocusBear
//
//  Created by Manish Jain on 13/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


class logsUploadingVc: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    override func viewDidLoad() {
        lblTitle.stringValue = "Uploading..."
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            lblTitle.stringValue = common.value(forKey: "uploadingText") as? String ?? lblTitle.stringValue
        }
    }
    override func viewWillAppear() {
        loader.startAnimation(self)
    }
}