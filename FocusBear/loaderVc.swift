//
//  loaderVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/07/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class loaderVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    override func viewWillAppear() {
        loader.startAnimation(self)
    }
}
