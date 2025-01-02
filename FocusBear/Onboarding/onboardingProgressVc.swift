//
//  onboardingProgressVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 30/01/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingProgressVc: NSViewController {
    
    @IBOutlet weak var lblProgressPercentage: NSTextField!
    @IBOutlet weak var lblTitleProgress: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    var totalProgress = 21 + 3// 3 is install habits pack steps
    
    var titleActivatingBlockingProgress = "Activating Distracting Blocking"
    var titleSettingHabitsProgress = "Setting up habits"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleProgress.stringValue = titleActivatingBlockingProgress
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            titleActivatingBlockingProgress = common.value(forKey: "titleActivatingBlockingProgress") as? String ?? titleActivatingBlockingProgress
            titleSettingHabitsProgress = common.value(forKey: "titleSettingHabitsProgress") as? String ?? titleSettingHabitsProgress
        }
    }
    func resetData(progress:Int){
        progressBar.minValue = 1
        progressBar.maxValue = Double(totalProgress)
        progressBar.doubleValue = Double(progress)
        let progress = (Double(progress) / Double(totalProgress)) * 100
        lblProgressPercentage.stringValue = "\(Int(progress))%"
    }
}
