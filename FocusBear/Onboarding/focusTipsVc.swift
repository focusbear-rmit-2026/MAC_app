//
//  focusTipsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class focusTipsVc: NSViewController {

    @IBOutlet weak var heightBoxBg: NSLayoutConstraint!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var boxSmall_slide0: NSBox!
    @IBOutlet weak var boxSmall_slide1: NSBox!
    @IBOutlet weak var boxSmall_slide2: NSBox!
    @IBOutlet weak var boxSmall_slide3: NSBox!
   
 
    @IBOutlet weak var btnGotIt: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitle: NSTextField!
    

    
    
    @IBOutlet weak var btnBack: Button!
    var currentSlideIndex = 0
    
    var nextTitle = "Next"
    
        
    var arrCurrentDic = [["subTitle":"Tip 1: Try focus block", "description":"You can try it out now by clicking the Play icon next to your new focus mode in the list that appears on clicking the top menu icon.", "image":#imageLiteral(resourceName: "focusTip_1")],
                         ["subTitle":"Tip 2: Teach Focus Bear what is productive", "description":"As you use this Focus Mode, Focus Bear will ask you whether each website/app is productive.", "image":#imageLiteral(resourceName: "tip_blockPopup")],
                         ["subTitle":"Tip 3: Permanently allow apps/websites", "description":"At the end of the focus block, you can permanently allow those apps/websites (or choose not to).", "image":#imageLiteral(resourceName: "tip_allowApps")],
                         ["subTitle":"Tip 4: Use keywords", "description":"You can even add keywords, e.g. \"React Native\" and any website with that keyword will be allowed.", "image":#imageLiteral(resourceName: "tip_allowKeywords")]]
    
//    var arrFinalCurrentDic = [[String : Any]]()
    var isHabitsDisabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

        
        lblTitle.stringValue = "All set up!"
        lblSubTitle.stringValue = ""
        lblDescription.stringValue = ""
        btnGotIt.title = "Onwards"
        btnBack.title = "Back"
        
        if let dic = configjson.value(forKey: "focusTipsVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title

            lblSubTitle.stringValue = dic.value(forKey: "controllingBrowserText") as? String ?? lblSubTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "controllingBrowserDescription") as? String ?? lblDescription.stringValue

            arrCurrentDic[0]["subTitle"] = dic.value(forKey: "tip1title") as? String ?? arrCurrentDic[1]["subTitle"]
            arrCurrentDic[0]["description"] = dic.value(forKey: "tip1Text") as? String ?? arrCurrentDic[1]["description"]
            
            arrCurrentDic[1]["subTitle"] = dic.value(forKey: "tip2Newtitle") as? String ?? arrCurrentDic[1]["subTitle"]
            arrCurrentDic[1]["description"] = dic.value(forKey: "tip2NewText") as? String ?? arrCurrentDic[1]["description"]

            arrCurrentDic[2]["subTitle"] = dic.value(forKey: "tip3Newtitle") as? String ?? arrCurrentDic[2]["subTitle"]
            arrCurrentDic[2]["description"] = dic.value(forKey: "tip3NewText") as? String ?? arrCurrentDic[2]["description"]

            arrCurrentDic[3]["subTitle"] = dic.value(forKey: "tip4Newtitle") as? String ?? arrCurrentDic[3]["subTitle"]
            arrCurrentDic[3]["description"] = dic.value(forKey: "tip4NewText") as? String ?? arrCurrentDic[3]["description"]

            btnBack.title = dic.value(forKey: "buttonBackText") as? String ?? btnBack.title
            nextTitle = dic.value(forKey: "buttonNextText") as? String ?? nextTitle
        }
        

        
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
            heightBoxBg.constant = 660
        }else{
            heightBoxBg.constant = 600
        }
        currentSlideIndex = 0
        recheckSlideState()
    }

    
    func recheckSlideState(){

        
        if currentSlideIndex == 0{
            boxSmall_slide0.fillColor = NSColor.systemBlue
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor

            btnBack.isHidden = true
            btnGotIt.title = nextTitle
        }else if currentSlideIndex == 1{
            boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide1.fillColor = NSColor.systemBlue
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor

            btnBack.isHidden = false
            btnGotIt.title = nextTitle
        }else if currentSlideIndex == 2{
            
            boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.systemBlue
            boxSmall_slide3.fillColor = NSColor.quaternaryLabelColor

            btnBack.isHidden = false
            btnGotIt.title = nextTitle
            
            
        }else if currentSlideIndex == 3{
            boxSmall_slide0.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide1.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide2.fillColor = NSColor.quaternaryLabelColor
            boxSmall_slide3.fillColor = NSColor.systemBlue

            btnBack.isHidden = false
            btnGotIt.title = "Onwards"
            if let dic = configjson.value(forKey: "focusTipsVcInfo") as? NSDictionary{
                btnGotIt.title = dic.value(forKey: "buttonGotItText") as? String ?? btnGotIt.title
            }
        }

        lblSubTitle.stringValue = arrCurrentDic[currentSlideIndex]["subTitle"] as? String ?? ""
        lblDescription.stringValue = arrCurrentDic[currentSlideIndex]["description"] as? String ?? ""
        imgView.image = arrCurrentDic[currentSlideIndex]["image"] as? NSImage
        
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        addLog(text: "focusTipsVc:-  Button Back clicked")
        currentSlideIndex -= 1
        recheckSlideState()
    }
    
    @IBAction func btnGotItClicked(_ sender: Any) {
        if currentSlideIndex == arrCurrentDic.count - 1{
            addLog(text:"focusTipsVc:- btn GotIt Clicked")
//            preloadFocusModesWindowControllerObj!.contentViewController = getHowHeardVcObj()
            self.view.window?.close()
        }else{
            addLog(text:"focusTipsVc:- btn Next Clicked")
            currentSlideIndex += 1
            
            recheckSlideState()
        }
        
    }
    
}

//Click next to explore the tips to use Focus Bear.
