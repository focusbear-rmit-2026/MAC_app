//
//  noBuddyFoundVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 17/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class noBuddyFoundVc: NSViewController {

    @IBOutlet weak var btnRefresh: underLineButton!
    @IBOutlet weak var btnAddNewBuddy: underLineButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var parentVc: accountabilityBuddyVc?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "No buddy for unlock requests"
        lblSubTitle.stringValue = "You need an accountability buddy to create unlock requests."
        btnAddNewBuddy.title = "Add a new Buddy"
        btnRefresh.title = "Refresh"
        
        if let accountabilityBuddyInfo = configjson.value(forKey: "accountabilityBuddyInfo") as? NSDictionary{
            lblTitle.stringValue = accountabilityBuddyInfo.value(forKey: "titleNoBuddyFound") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = accountabilityBuddyInfo.value(forKey: "subTitleNoBuddyFound") as? String ?? lblSubTitle.stringValue
            btnAddNewBuddy.title = accountabilityBuddyInfo.value(forKey: "buttonAddBuddy") as? String ?? btnAddNewBuddy.title
            btnRefresh.title = accountabilityBuddyInfo.value(forKey: "buttonRefreshBuddiesList") as? String ?? btnRefresh.title
        }
    }
    
    @IBAction func btnAddNewBuddyClicked(_ sender: Any) {
        if let url = URL(string: "https://dashboard.focusbear.io/accountability-buddy"){
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func btnRefreshClicked(_ sender: Any) {
        allApiObject.getAllBuddies(completionHandler: {data in
            if let data = data{
                convertJsonToBuddies(json: data)
                DispatchQueue.main.async {
                    self.parentVc?.reloadView()
                }
            }
        })
    }
}
