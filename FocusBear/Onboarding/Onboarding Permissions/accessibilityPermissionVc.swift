//
//  accessibilityPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/07/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa
import AVKit

class accessibilityPermissionVc: NSViewController {
    
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var boxCollectionView: DashedView!
    @IBOutlet weak var lblNextViewInfo: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblPoint1: NSTextField!
    @IBOutlet weak var lblPoint2: NSTextField!
    @IBOutlet weak var lblPoint3: NSTextField!
    @IBOutlet weak var lblPoint4: NSTextField!
    @IBOutlet weak var lblPoint5: NSTextField!
    @IBOutlet weak var collectionview: NSCollectionView!
    @IBOutlet weak var lbltitle: NSTextField!
    @IBOutlet weak var imgview: NSImageView!
    @IBOutlet weak var btnpreferences: NSButton!
    @IBOutlet weak var btnContinue: NSButton!
    
    @IBOutlet weak var lblStep1: NSTextField!
    @IBOutlet weak var lblStep2: NSTextField!
    @IBOutlet weak var lblStep3: NSTextField!
    @IBOutlet weak var lblStep4: NSTextField!
    
    @IBOutlet weak var avPlayerView: AVPlayerView!

    var indexPathsOfItemsBeingDragged: Set<IndexPath> = []
    var gridDraggedindex = [Int]()
    
    var videoPlayer:AVPlayer?
    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblNextViewInfo.stringValue = "On the next screen we will ask permissions for System Events."
        lbltitle.stringValue = "Grant accessibility permission to Focus Bear"
        lblSubTitle.stringValue = "In order to block distractions, you need to authorize Focus Bear in the Accessibility section of the Security & Privacy Pane of the System Preferences."
     
        lblPoint1.stringValue = "Open System Preferences > Security & Privacy > Privacy > Accessibility or use the button below."
        lblPoint2.stringValue = "Select the lock icon in the bottom left corner and enter your password to unlock."
        lblPoint3.stringValue = "Click on the icon and then drag it into the allowed apps list under Accessibility."
        lblPoint4.stringValue = "If Focus Bear is already in the list and checked, please remove Focus Bear by clicking the - button at the bottom and add it again."
        btnpreferences.title = "Open System Preferences"
        btnContinue.title = "Continue"
        var step1Text = "Step 1:"
        var step2Text = "Step 2:"
        var step3Text = "Step 3:"
        var step4Text = "Step 4:"
        
       
        
        imgview.isHidden = true
        avPlayerView.isHidden = false
        if #available(macOS 13.0, *) {
            lblPoint1.stringValue = "Open System Preferences > Privacy & Security > Accessibility or use the button below."
            if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                lblPoint1.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFirstNewText") as? String ?? lblPoint1.stringValue
            }
            
            if let videoURL = Bundle.main.url(forResource: "Accessibility_Video", withExtension: "mp4") {
                // Create an AVPlayer with the video URL
                videoPlayer = AVPlayer(url: videoURL)
                
                // Assign the player to the playerView
                avPlayerView.player = videoPlayer
                
                // Start playing the video
                videoPlayer!.play()
            } else {
                print("Video file not found in bundle.")
            }
        }else {
            lblPoint1.stringValue = "Open System Preferences > Security & Privacy > Privacy > Accessibility or use the button below."
            if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                lblPoint1.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFirstText") as? String ?? lblPoint1.stringValue
            }
            
            if let videoURL = Bundle.main.url(forResource: "Monterey_Accessibility", withExtension: "mp4") {
                // Create an AVPlayer with the video URL
                videoPlayer = AVPlayer(url: videoURL)
                
                // Assign the player to the playerView
                avPlayerView.player = videoPlayer
                
                // Start playing the video
                videoPlayer!.play()
            } else {
                print("Video file not found in bundle.")
            }
            
        }
        
        //------------------------------------------------//1190 bold Privacy & Security
        let pointFirstText = lblPoint1.stringValue
        let startLocation = (getOccurrence(of: ">", in: pointFirstText, occurrenceCount: 1) ?? 5) + 1
        let endLocation = getOccurrence(of: ">", in: pointFirstText, occurrenceCount: 2) ?? 10
        
        let attributedString = NSMutableAttributedString(string: pointFirstText)
        
        let font = getBoldFont(size: lblPoint1.font?.pointSize ?? 20)
        attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location:startLocation,length:endLocation - startLocation))
        lblPoint1.attributedStringValue = attributedString
        
        
        //----------------------------------------------------//
        
        if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
            lblPoint2.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointSecondText") as? String ?? lblPoint2.stringValue
            lblPoint3.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointThirdText") as? String ?? lblPoint3.stringValue
            lblPoint4.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFourthText") as? String ?? lblPoint4.stringValue
            lblPoint5.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFifthText") as? String ?? lblPoint5.stringValue
            btnpreferences.title = firefoxPermissionsVcInfo.value(forKey: "buttonOpenAccessibilityPermissionsText") as? String ?? btnpreferences.title
            btnContinue.title = firefoxPermissionsVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        if let accessibilityPermissionVcInfo = configjson.value(forKey: "accessibilityPermissionVcInfo") as? NSDictionary{
            lblNextViewInfo.stringValue = accessibilityPermissionVcInfo.value(forKey: "nextViewInfoText") as? String ?? lblNextViewInfo.stringValue
            lbltitle.stringValue = accessibilityPermissionVcInfo.value(forKey: "title") as? String ?? lbltitle.stringValue
            lblSubTitle.stringValue = accessibilityPermissionVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            step1Text = accessibilityPermissionVcInfo.value(forKey: "step1Text") as? String ?? step1Text
            step2Text = accessibilityPermissionVcInfo.value(forKey: "step2Text") as? String ?? step2Text
            step3Text = accessibilityPermissionVcInfo.value(forKey: "step3Text") as? String ?? step3Text
            step4Text = accessibilityPermissionVcInfo.value(forKey: "step4Text") as? String ?? step4Text
        }
        
        
        
        if #available(macOS 13.0, *) {
            lblStep1.stringValue = step1Text
            lblStep3.stringValue = step2Text
            lblStep4.stringValue = step3Text
            
            lblStep2.isHidden = true
            lblPoint2.isHidden = true
        }else {
            lblStep1.stringValue = step1Text
            lblStep2.stringValue = step2Text
            lblStep3.stringValue = step3Text
            lblStep4.stringValue = step4Text
            
            lblStep2.isHidden = false
            lblPoint2.isHidden = false
        }
        
        
        lblStep4.isHidden = true
        lblPoint4.isHidden = true
        
        lblStep3.isHidden = true
        lblStep2.isHidden = true
        lblPoint3.isHidden = true
        lblPoint2.isHidden = true
        boxCollectionView.isHidden = true
        avPlayerView.isHidden = true
        
        lblNextViewInfo.isHidden = true
        btnContinue.isHidden = true
        
        collectionview.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)//.move, forLocal: true)
        // 1
        var ptype: NSPasteboard.PasteboardType?
        if #available(OSX 10.13, *) {
            ptype = NSPasteboard.PasteboardType.fileURL
        } else {
            ptype = NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }
        self.collectionview.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String),            // single url from pasteboard
                                                     //
                                                     ptype!,     // from Safari or Finder
                                                     NSPasteboard.PasteboardType.filePromise,NSPasteboard.PasteboardType(kUTTypeItem as String)])        // 2
        
        
        collectionview.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)

        allApiObject.capturePosthog(event: "accessibility-permission-shown", metadata: [:])
        addLog(text: "[user-action] accessibility-permission-shown")
    }
    
    func startTimerCheckPermission() {
        totalDuration = 5
        self.timer?.invalidate()
        self.timer = nil
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCountCheckPermission), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    
    @objc func performTimerCountCheckPermission() {
        currentTimer += 1
        if isAccessibilityEnabled(isPrompt: false){
            lblNextViewInfo.isHidden = false
            btnContinue.isHidden = false
            self.timer?.invalidate()
            btnContinueClicked(self)
            return;
        }
        if currentTimer >= totalDuration{
            DispatchQueue.main.async {
                self.lblNextViewInfo.isHidden = false
                self.btnContinue.isHidden = false
            }
        }
    }
    
    func getOccurrence(of char: Character, in string: String, occurrenceCount:Int) -> Int? {
        var count = 0
        
        for (index, currentChar) in string.enumerated() {
            if currentChar == char {
                count += 1
            }
            if count == occurrenceCount {
                return index
            }
        }
        
        // If the character doesn't appear twice
        return nil
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "accessibility-permission-screen")
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }
    
    override func viewWillAppear() {
        
    }
    
    override func viewWillDisappear() {
        self.timer?.invalidate()
        hideOnboardingBellIcon(view: self.view)
        if videoPlayer != nil{
            videoPlayer?.pause()
        }
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] accessibilityPermissionVc:- Button Continue clicked")
        self.view.window?.contentViewController = getSystemEventsPermissionVcObject()
    }
    
    @IBAction func btnInfoClicked(_ sender: hoverInfoButton) {
        var msg = "We use accessibility permissions to resize full screen windows (otherwise we can't block distractions)."
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "accessibilityPermissionVcInfo") as? NSDictionary{
            msg = systemEventsPermissionVcInfo.value(forKey: "toolTipText") as? String ?? msg
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnOpenPreferences(_ sender: Any) {
        let urlstring = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
        NSWorkspace.shared.open(URL(string: urlstring)!)
        
        
        lblStep3.isHidden = false
        lblStep2.isHidden = false
        lblPoint3.isHidden = false
        lblPoint2.isHidden = false
        boxCollectionView.isHidden = false
        avPlayerView.isHidden = false
        
        
        if #available(macOS 13.0, *) {
            lblStep2.isHidden = true
            lblPoint2.isHidden = true
        }else {
            lblStep2.isHidden = false
            lblPoint2.isHidden = false
        }
        videoPlayer?.seek(to: .zero)
        videoPlayer!.play()
        
        startTimerCheckPermission()
    }
}


extension accessibilityPermissionVc: NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionview.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath) as! CollectionViewItem

        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
        gridDraggedindex.removeAll()
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        gridDraggedindex.append(indexPath.item)
        return Bundle.main.bundleURL as? NSPasteboardWriting
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        indexPathsOfItemsBeingDragged = indexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        indexPathsOfItemsBeingDragged = []
        gridDraggedindex.removeAll()
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        if proposedDropOperation.pointee == NSCollectionView.DropOperation.on {
            proposedDropOperation.pointee = NSCollectionView.DropOperation.before
        }
        
        if indexPathsOfItemsBeingDragged.count == 0 {
            return NSDragOperation.copy
        } else {
            return NSDragOperation.move
        }
        return NSDragOperation.move
    }


    func collectionView(_ collectionView: NSCollectionView,layout collectionViewLayout: NSCollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.bounds.width-5, height: (collectionView.enclosingScrollView?.bounds.height ?? 5)-10)
    }
}






