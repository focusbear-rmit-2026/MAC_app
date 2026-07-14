//
//  alertMaxTabLimitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class alertMaxTabLimitVc: NSViewController {

    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Max tab count (\(SettingsManagerObject.maxTabLimitCount)) exceeded."
        btnOk.title = buttonOkText
    }
    override func viewWillAppear() {
        resetView()
    }
    func resetView(){
        var title = "Max tab count (<COUNT>) exceeded."
        if let alertMaxTabLimitVcInfo = configjson.value(forKey: "alertMaxTabLimitVcInfo") as? NSDictionary{
            title = alertMaxTabLimitVcInfo.value(forKey: "title") as? String ?? title
        }
        title = title.replacingOccurrences(of: "<COUNT>", with: "\(SettingsManagerObject.maxTabLimitCount)")
        
        var titleTabsCount = "Number of open tabs:"
        if let alertMaxTabLimitVcInfo = configjson.value(forKey: "alertMaxTabLimitVcInfo") as? NSDictionary{
            titleTabsCount = alertMaxTabLimitVcInfo.value(forKey: "titleTabsCount") as? String ?? titleTabsCount
        }
        
        
        title += "\n\n\(titleTabsCount)\n"
        let (_, numberOfOpenTabsPerBrowserInString) = getNumberOfOpenTabsPerBrowserInString()
        
        lblTitle.stringValue = title + numberOfOpenTabsPerBrowserInString
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()
    }
}
