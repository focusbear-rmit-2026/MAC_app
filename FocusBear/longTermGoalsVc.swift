//
//  longTermGoalsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/01/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class longTermGoalsVc: NSViewController {

    @IBOutlet weak var lblList: NSTextField!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnSure: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    var arrGoals = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnCancel.buttonColor = NSColor.white.cgColor
        btnCancel.title = buttonCancelText
        btnSure.title = "Sure"
        lblTitle.stringValue = "Are you sure?"
        lblSubTitle.stringValue = "Just a reminder that this is what you are trying to achieve with Focus Bear"
        if let longTermGoalsVcInfo = configjson.value(forKey: "longTermGoalsVcInfo") as? NSDictionary{
            lblTitle.stringValue = longTermGoalsVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = longTermGoalsVcInfo.value(forKey: "description") as? String ?? lblSubTitle.stringValue
            btnSure.title = longTermGoalsVcInfo.value(forKey: "buttonContinueText") as? String ?? btnSure.title
        }
        var title:String = ""
        for goal in arrGoals{
            if title.isEmpty{
                title = "● " + goal
            }else{
                title += "\n● " + goal
            }
        }
        
        let bold14:NSFont = NSFont.systemFont(ofSize: 12)
        let textColor:NSColor = NSColor.labelColor
        let textParagraph:NSMutableParagraphStyle = NSMutableParagraphStyle()
        textParagraph.lineSpacing = 10.0  /*this sets the space BETWEEN lines to 10points*/
//        textParagraph.maximumLineHeight = 12.0/*this sets the MAXIMUM height of the lines to 12points*/
        let attribs = [NSAttributedString.Key.font:bold14,NSAttributedString.Key.foregroundColor:textColor,NSAttributedString.Key.paragraphStyle:textParagraph]
        let attrString:NSAttributedString = NSAttributedString.init(string: title, attributes: attribs)
        lblList.attributedStringValue = attrString
    }
    override func viewWillAppear() {
        allApiObject.getuserLongTermGoals(completionHandler: {json in
            
        })
    }
    @IBAction func btnSureClicked(_ sender: Any) {
        showQuittingConfirmView()
        self.dismiss(self)
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
}

