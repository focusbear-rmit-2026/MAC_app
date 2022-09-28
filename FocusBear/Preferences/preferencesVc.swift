//
//  preferencesVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class preferencesVc: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let preferencesTabViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preferencesTabViewController")) as? preferencesTabViewController
        self.view.addSubview(preferencesTabViewControllerObj!.tabView)
        self.view.addConstraints(subView: preferencesTabViewControllerObj!.view)
        
    }
    
}
