//
//  accountabilityBuddyVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 17/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class accountabilityBuddyVc: NSViewController {

    @IBOutlet weak var customView: NSView!
    @IBOutlet weak var boxBg: NSBox!
    
    var enterPasswordVcObj: enterPasswordVc?
    
    var noBuddyFoundVcObj:noBuddyFoundVc?
    func getNoBuddyFoundVcObject()->noBuddyFoundVc{
        if noBuddyFoundVcObj == nil{
            noBuddyFoundVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("noBuddyFoundVc")) as? noBuddyFoundVc
        }
        return noBuddyFoundVcObj!
    }
    
    var createUnlockRequestVcObj:createUnlockRequestVc?
    func getCreateUnlockRequestVcObject()->createUnlockRequestVc{
        if createUnlockRequestVcObj == nil{
            createUnlockRequestVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("createUnlockRequestVc")) as? createUnlockRequestVc
        }
        return createUnlockRequestVcObj!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
    }
    
    override func viewWillAppear() {
        reloadView()
    }
    
    func reloadView(){
        if arrAllBuddies.count == 0{
            showNoBuddyFoundView()
        }else{
            showCreateUnlockRequestView()
        }
    }
    
    func showNoBuddyFoundView(){
        removeSubViews()
        customView.addSubview(getNoBuddyFoundVcObject().view)
        customView.addConstraints(subView: getNoBuddyFoundVcObject().view)
        getNoBuddyFoundVcObject().parentVc = self
    }
    
    func showCreateUnlockRequestView(){
        removeSubViews()
        customView.addSubview(getCreateUnlockRequestVcObject().view)
        customView.addConstraints(subView: getCreateUnlockRequestVcObject().view)
        getCreateUnlockRequestVcObject().enterPasswordVcObj = enterPasswordVcObj
    }
    
    func removeSubViews(){
        let viewsArr = customView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
    }
}
