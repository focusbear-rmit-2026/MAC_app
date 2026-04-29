//
//  distractionBlockingProgressVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 27/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class distractionBlockingProgressVc: NSViewController {

    @IBOutlet weak var imgViewTickFirst: NSImageView!
    @IBOutlet weak var lblFirst: NSTextField!
    @IBOutlet weak var boxLineFirst: NSBox!
    @IBOutlet weak var imgViewFirst: NSImageView!
    @IBOutlet weak var progressViewFirst: circularProgressView!
    
    @IBOutlet weak var imgViewTickSecond: NSImageView!
    @IBOutlet weak var lblSecond: NSTextField!
    @IBOutlet weak var boxLineSecond: NSBox!
    @IBOutlet weak var imgViewSecond: NSImageView!
    @IBOutlet weak var progressViewSecond: circularProgressView!
    
    @IBOutlet weak var imgViewTickThird: NSImageView!
    @IBOutlet weak var lblThird: NSTextField!
    @IBOutlet weak var imgViewThird: NSImageView!
    @IBOutlet weak var progressViewThird: circularProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblFirst.stringValue = "BLOCKING DISTRACTIONS"
        lblSecond.stringValue = "SET SCHEDULE"
        lblThird.stringValue = "GRANT PERMISSIONS"
        
        if let dic = configjson["distractionBlockingProgressVcInfo"] as? [String: Any] {
            lblFirst.stringValue = dic["labelFirst"] as? String ?? lblFirst.stringValue
            lblSecond.stringValue = dic["labelSecond"] as? String ?? lblSecond.stringValue
            lblThird.stringValue = dic["labelThird"] as? String ?? lblThird.stringValue
        }
    }
 
    func setClearAll(){
        showAllLebels()
        setLevelFirstNotStarted()
        setLevelSecondNotStarted()
        setLevelThirdNotStarted()
    }
    
    func setCompletedAll(){
        setLevelFirstCompleted()
        setLevelSecondCompleted()
        setLevelThirdCompleted()
        hideAllLebels()
    }
    
    func setProgress(level:Int, progress:CGFloat){
        hideAllLebels()
        
        if level == 1{
            lblFirst.isHidden = false
            if progress == 1{
                setLevelFirstCompleted()
            }else{
                setLevelFirstProgress(progress: progress)
            }
            setLevelSecondNotStarted()
            setLevelThirdNotStarted()
        }else if level == 2{
            lblSecond.isHidden = false
            if progress == 1{
                setLevelSecondCompleted()
            }else{
                setLevelSecondProgress(progress: progress)
            }
            setLevelFirstCompleted()
            setLevelThirdNotStarted()
        }else if level == 3{
            lblThird.isHidden = false
            if progress == 1{
                setLevelThirdCompleted()
            }else{
                setLevelThirdProgress(progress: progress)
            }
            setLevelFirstCompleted()
            setLevelSecondCompleted()
        }
    }
    
    func setLevelFirstProgress(progress:CGFloat){
        lblFirst.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        imgViewFirst.image = NSImage(named: "visibility_off_enabled")
        progressViewFirst.progress = progress
        boxLineFirst.fillColor = .quaternaryLabelColor
        imgViewTickFirst.isHidden = true
    }

    func setLevelSecondProgress(progress:CGFloat){
        lblSecond.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        imgViewSecond.image = NSImage(named: "watch_later_enabled")
        progressViewSecond.progress = progress
        boxLineSecond.fillColor = .quaternaryLabelColor
        imgViewTickSecond.isHidden = true
    }
    
    func setLevelThirdProgress(progress:CGFloat){
        lblThird.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        imgViewThird.image = NSImage(named: "lock_open_enabled")
        progressViewThird.progress = progress
        imgViewTickThird.isHidden = true
    }
    
    
    func showAllLebels(){
        lblFirst.isHidden = false
        lblSecond.isHidden = false
        lblThird.isHidden = false
    }
    
    func hideAllLebels(){
        lblFirst.isHidden = true
        lblSecond.isHidden = true
        lblThird.isHidden = true
    }
    
    func setLevelFirstCompleted(){
        lblFirst.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        progressViewFirst.progress = 1
        boxLineFirst.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        imgViewTickFirst.isHidden = false
        imgViewFirst.image = nil
    }
    
    func setLevelSecondCompleted(){
        lblSecond.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        progressViewSecond.progress = 1
        boxLineSecond.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        imgViewTickSecond.isHidden = false
        imgViewSecond.image = nil
    }
    
    func setLevelThirdCompleted(){
        lblThird.textColor = NSColor(named: "dark_OrangeColor") ?? NSColor.orange
        progressViewThird.progress = 1
        imgViewTickThird.isHidden = false
        imgViewThird.image = nil
    }
    
    func setLevelFirstNotStarted(){
        lblFirst.textColor = .quaternaryLabelColor
        imgViewFirst.image = NSImage(named: "visibility_off_disabled")
        progressViewFirst.progress = 0
        boxLineFirst.fillColor = .quaternaryLabelColor
        imgViewTickFirst.isHidden = true
    }
    
    func setLevelSecondNotStarted(){
        lblSecond.textColor = .quaternaryLabelColor
        imgViewSecond.image = NSImage(named: "watch_later_disabled")
        progressViewSecond.progress = 0
        boxLineSecond.fillColor = .quaternaryLabelColor
        imgViewTickSecond.isHidden = true
    }
    
    func setLevelThirdNotStarted(){
        lblThird.textColor = .quaternaryLabelColor
        imgViewThird.image = NSImage(named: "lock_open_disabled")
        progressViewThird.progress = 0
        imgViewTickThird.isHidden = true
    }
}
