//
//  popupCompletionRequirements.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 04/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class completionRequirementsVc: NSViewController {

    @IBOutlet weak var btnDone: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnDone.title = "I'm done"
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            btnDone.title = activityInfo.value(forKey: "buttonActivityDoneText") as? String ?? btnDone.title
        }
    }
    func resetView(title:String){
//        lblTitle.stringValue = title
        var textCompletionRequirements = "Complete After: <REQUIREMENTS>"
        
        if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
            textCompletionRequirements = activityInfo.value(forKey: "completionRequirementsText") as? String ?? textCompletionRequirements
        }
        
        lblTitle.stringValue = textCompletionRequirements.replacingOccurrences(of: "<REQUIREMENTS>", with: title)
    }
    @IBAction func btnDoneClicked(_ sender: Any) {
        timerViewcontrollerObj?.btnIAmDoneClicked(self)
        self.view.window?.close()
    }
}
