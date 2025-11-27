//
//  firefoxPermissions.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 27/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import AVKit

class firefoxPermissionsVc: NSViewController {
    
    @IBOutlet weak var lblPoint1_config: NSTextField!
    @IBOutlet weak var lblPoint2_config: NSTextField!
    @IBOutlet weak var lblPoint3_config: NSTextField!
    @IBOutlet weak var lblPoint4_config: NSTextField!
    
    @IBOutlet weak var lblStep1_config: NSTextField!
    @IBOutlet weak var lblStep2_config: NSTextField!
    @IBOutlet weak var lblStep3_config: NSTextField!
    @IBOutlet weak var lblStep4_config: NSTextField!
    @IBOutlet weak var btnClickToCopySearchTeram: underLineButton!
    
    
    
    @IBOutlet weak var avPlayerView: AVPlayerView!
    @IBOutlet weak var lblStep1: NSTextField!
    @IBOutlet weak var lblStep2: NSTextField!
    @IBOutlet weak var lblStep3: NSTextField!
    @IBOutlet weak var lblStep4: NSTextField!
    @IBOutlet weak var btnPlay: mouseDownEffectButton!
    @IBOutlet weak var boxPlay: NSBox!
    @IBOutlet weak var boxRightSide: NSBox!
    @IBOutlet weak var topSpaceTitleStep: NSLayoutConstraint!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var lblTitleStep: NSTextField!
    @IBOutlet weak var stackViewSecond: NSStackView!
    @IBOutlet weak var stackViewFirst: NSStackView!
    @IBOutlet weak var btnActivateFirefox: Button!
    @IBOutlet weak var btnContinue: cursorButton!
    @IBOutlet weak var lblPoint1: NSTextField!
    @IBOutlet weak var lblPoint2: NSTextField!
    @IBOutlet weak var lblPoint3: NSTextField!
    @IBOutlet weak var lblPoint4: NSTextField!
    
    @IBOutlet weak var collectionview: NSCollectionView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lbltitle: NSTextField!
    @IBOutlet weak var imgview: NSImageView!
    @IBOutlet weak var btnpreferences: NSButton!
    
    var showingFromOnboarding = true
    var currentBrowser:BROWSER = ._FIREFOX_
    var currentIndex = 1
    
    var indexPathsOfItemsBeingDragged: Set<IndexPath> = []
    var gridDraggedindex = [Int]()
    var videoPlayer:AVPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        lblPoint1_config.stringValue = "Click \"Open/Activate Firefox\" to open about:config"
        lblPoint2_config.stringValue = "Click \"Accept the Risk and Continue\" button on Firefox browser page (about:config page should automatically open)"
        lblPoint3_config.stringValue = "Search for accessibility.force_disabled in the \"Search preference name\" bar of Firefox page"
        lblPoint4_config.stringValue = "Double-click the setting and change its value to -1"
        btnClickToCopySearchTeram.title = "Click to copy search term"
        
        btnCancel.title = buttonCancelText
        lbltitle.stringValue = "Grant required permissions to Focus Bear to allow blocking in Firefox"
        lblSubTitle.stringValue = "In order to allow blocking within Firefox, you need to grant specific permissions to Focus Bear."
        

        lblPoint1.stringValue = "Open System Preferences > Security & Privacy > Privacy > Accessibility or use the button below."
        lblPoint2.stringValue = "Select the lock icon in the bottom left corner and enter your password to unlock."
        lblPoint3.stringValue = "Click on the icon and then drag it into the allowed apps list under Accessibility."
        lblPoint4.stringValue = "If Focus Bear is already in the list and checked, please remove Focus Bear by clicking the - button at the bottom and add it again."
//        lblPoint5.stringValue = "Edit setting - \"accessibility.force_disabled\" in Firefox to be able to block distractions."
        
        btnActivateFirefox.title = "Open/Activate Firefox"
//        btnClickhere.title = "Click here to watch a video to learn how to edit the setting in Firefox."
        btnpreferences.title = "Open System Preferences"
        btnContinue.title = "Continue"
        
        
        if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
            lbltitle.stringValue = firefoxPermissionsVcInfo.value(forKey: "title") as? String ?? lbltitle.stringValue
            lblSubTitle.stringValue = firefoxPermissionsVcInfo.value(forKey: "description") as? String ?? lblSubTitle.stringValue
            lblPoint1.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFirstText") as? String ?? lblPoint1.stringValue
            lblPoint2.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointSecondText") as? String ?? lblPoint2.stringValue
            lblPoint3.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointThirdText") as? String ?? lblPoint3.stringValue
            lblPoint4.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFourthText") as? String ?? lblPoint4.stringValue
//            lblPoint5.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFifthText") as? String ?? lblPoint5.stringValue
            btnActivateFirefox.title = firefoxPermissionsVcInfo.value(forKey: "buttonActivateFirefoxText") as? String ?? btnActivateFirefox.title

            btnpreferences.title = firefoxPermissionsVcInfo.value(forKey: "buttonOpenAccessibilityPermissionsText") as? String ?? btnpreferences.title
            btnContinue.title = firefoxPermissionsVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            
            lblPoint1_config.stringValue = firefoxPermissionsVcInfo.value(forKey: "point1_configText") as? String ?? lblPoint1_config.stringValue
            lblPoint2_config.stringValue = firefoxPermissionsVcInfo.value(forKey: "point2_configText") as? String ?? lblPoint2_config.stringValue
            lblPoint3_config.stringValue = firefoxPermissionsVcInfo.value(forKey: "point3_configText") as? String ?? lblPoint3_config.stringValue
            lblPoint4_config.stringValue = firefoxPermissionsVcInfo.value(forKey: "point4_configText") as? String ?? lblPoint4_config.stringValue
            btnClickToCopySearchTeram.title = firefoxPermissionsVcInfo.value(forKey: "buttonClickToCopySearchTermText") as? String ?? btnClickToCopySearchTeram.title
        }

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
    }

    
    var timerCheck:Timer?
    override func viewWillAppear() {
        
        
        btnpreferences.keyEquivalent = "\r"
        btnpreferences.isEnabled = true
        timerCheck = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkPermission), userInfo: nil, repeats: true)
        currentIndex = 1
        if isAccessibilityEnabled(isPrompt: false) == true{
            timerCheck?.invalidate()
            currentIndex = 2
            btnpreferences.isEnabled = false
            btnContinue.isEnabled = true
        }
        
        resetView()
    }
    
    override func viewWillDisappear() {
        timerCheck?.invalidate()
        
        if videoPlayer != nil{
            videoPlayer?.pause()
            videoPlayer = nil
        }
    }
    
    
    func resetView(){
        lbltitle.stringValue = "Grant required permissions to Focus Bear to allow blocking in Firefox"
        lblSubTitle.stringValue = "In order to allow blocking within Firefox, you need to grant specific permissions to Focus Bear."
        if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
            lbltitle.stringValue = firefoxPermissionsVcInfo.value(forKey: "title") as? String ?? lbltitle.stringValue
            lblSubTitle.stringValue = firefoxPermissionsVcInfo.value(forKey: "description") as? String ?? lblSubTitle.stringValue
        }
        if currentBrowser == ._SIGMA_OS_{
            lbltitle.stringValue = lbltitle.stringValue.replacingOccurrences(of: "Firefox", with: "SigmaOS")
            lblSubTitle.stringValue = lblSubTitle.stringValue.replacingOccurrences(of: "Firefox", with: "SigmaOS")
        }
        
        btnContinue.isEnabled = true
        if currentIndex == 1{
            boxPlay.isHidden = true
            
            if firefoxPermissionVideoVcObj != nil{
                if boxRightSide.contentView!.subviews.contains(firefoxPermissionVideoVcObj!.view){
                    firefoxPermissionVideoVcObj?.view.removeFromSuperview()
                }
            }
            
            boxRightSide.isHidden = true
            topSpaceTitleStep.constant = 10
            stackViewFirst.isHidden = false
            stackViewSecond.isHidden = true
            imgview.animates = true
            
            imgview.isHidden = true
            avPlayerView.isHidden = false
            
            if #available(macOS 13.0, *) {
                lblPoint1.stringValue = "Open System Preferences > Privacy & Security > Accessibility or use the button below."
                if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                    lblPoint1.stringValue = firefoxPermissionsVcInfo.value(forKey: "pointFirstNewText") as? String ?? lblPoint1.stringValue
                }
                
                lblStep1.stringValue = "1."
                lblStep3.stringValue = "2."
                lblStep4.stringValue = "3."
                
                lblStep2.isHidden = true
                lblPoint2.isHidden = true
                
                
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
                
                lblStep1.stringValue = "1."
                lblStep2.stringValue = "2."
                lblStep3.stringValue = "3."
                lblStep4.stringValue = "4."
                
                lblStep2.isHidden = false
                lblPoint2.isHidden = false
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
            lblTitleStep.stringValue = "Step 1: Grant Accessibility permission to focus bear"
            if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                lblTitleStep.stringValue = firefoxPermissionsVcInfo.value(forKey: "step1Text") as? String ?? lblTitleStep.stringValue
            }
            if isAccessibilityEnabled(isPrompt: false) == false{
                btnContinue.isEnabled = false
            }
        }else{
            boxRightSide.isHidden = false
            boxPlay.isHidden = false
            imgview.isHidden = false
            avPlayerView.isHidden = true
            if firefoxPermissionVideoVcObj != nil{
                if boxRightSide.contentView!.subviews.contains(firefoxPermissionVideoVcObj!.view){
                    firefoxPermissionVideoVcObj?.view.removeFromSuperview()
                }
            }
            topSpaceTitleStep.constant = 50
            stackViewFirst.isHidden = true
            stackViewSecond.isHidden = false
            imgview.image = #imageLiteral(resourceName: "Firefox_Premission")
            lblTitleStep.stringValue = "Step 2: Edit specific setting in Firefox"
            if let firefoxPermissionsVcInfo = configjson.value(forKey: "firefoxPermissionsVcInfo") as? NSDictionary{
                lblTitleStep.stringValue = firefoxPermissionsVcInfo.value(forKey: "step2Text") as? String ?? lblTitleStep.stringValue
            }
        }
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        timerCheck?.invalidate()
        if showingFromOnboarding{
            permissionBlockDistractionWcObj?.showWindow(self)
        }else{
            mainWindowControllerObj?.showWindow(self)//preferencesWindowControllerObj
        }
        self.view.window?.close()
    }
    @IBAction func btnOpenPreferences(_ sender: Any) {
        let urlstring = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
        NSWorkspace.shared.open(URL(string: urlstring)!)
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        self.view.window?.setFrameOrigin(NSPoint(x: screenFrame.width - self.view.frame.width, y: self.view.window?.frame.minY ?? 0))
    }
    
    @objc func checkPermission(){
        if isAccessibilityEnabled(isPrompt: false) == true{
            timerCheck?.invalidate()
            btnpreferences.isEnabled = false
            btnContinue.isEnabled = true
            currentIndex = 2
            
            if currentBrowser == ._SIGMA_OS_{
                if showingFromOnboarding{
                    permissionBlockDistractionWcObj?.showWindow(self)
                    onboardingControllingBrowserVcObj?.requestSigmaOSBrowser()
                }else{
                    mainWindowControllerObj?.showWindow(self)//preferencesWindowControllerObj
                    permissionsVcObj?.requestSigmaOSBrowser()
                }
                self.view.window?.close()
                return;
            }
            
            
            resetView()
        }
    }
    @objc func terminateAndRestart(){
        let task = Process()
        var args: [AnyHashable] = []
        args.append("-c")
        args.append("sleep \(2); open \"\(Bundle.main.bundlePath)\"")
        task.launchPath = "/bin/sh"
        task.arguments = args as? [String]
        task.launch()
        NSApp.terminate(self)
        return;
    }

    
    @IBAction func btnContinueClicked(_ sender: Any) {
        if currentBrowser == ._SIGMA_OS_{
            if showingFromOnboarding{
                permissionBlockDistractionWcObj?.showWindow(self)
                onboardingControllingBrowserVcObj?.requestSigmaOSBrowser()
            }else{
                mainWindowControllerObj?.showWindow(self)//preferencesWindowControllerObj
                permissionsVcObj?.requestSigmaOSBrowser()
            }
            self.view.window?.close()
            return;
        }
        
        if currentIndex == 1{
            currentIndex = 2
            resetView()
            return;
        }
        timerCheck?.invalidate()
        if showingFromOnboarding{
            permissionBlockDistractionWcObj?.showWindow(self)
        }else{
            mainWindowControllerObj?.showWindow(self)//preferencesWindowControllerObj
        }
        self.view.window?.close()
    }

    
    @IBAction func btnOpenFirefoxSettingsClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Firefox.app"))
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        self.view.window?.setFrameOrigin(NSPoint(x: screenFrame.width - self.view.frame.width, y: self.view.window?.frame.minY ?? 0))
        let script = """
        tell application "Firefox"
        open location "about:config"
        end tell
        """
        
        executeScript(script: script)
    }
    
    @IBAction func btnPlayClicked(_ sender: Any) {
        imgview.isHidden = true
        avPlayerView.isHidden = true
        boxRightSide.addSubview(getFirefoxPermissionVideoVcObject().view)
        boxRightSide.addConstraints(subView: getFirefoxPermissionVideoVcObject().view)
        boxPlay.isHidden = true
    }
    
    @IBAction func btnClickToCopySearchTeramClicked(_ sender: Any) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("accessibility.force_disabled", forType: .string)
        

        
        var msg = "Copied"
        if let upgradeNowVcInfo = configjson.value(forKey: "upgradeNowVcInfo") as? NSDictionary{
            msg = upgradeNowVcInfo.value(forKey: "toolTipCopied") as? String ?? msg
        }
        showTooltip(sender: btnClickToCopySearchTeram, msg: msg, preferredEdge: NSRectEdge.minY, maxWidthVal:230)
        DispatchQueue.global().async {
            sleep(2)
            DispatchQueue.main.async {
                popoverTooltip?.close()
            }
        }
    }
}



extension firefoxPermissionsVc: NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionview.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem"), for: indexPath) as! CollectionViewItem
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
 
    }
    
    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {///retuen yes or no
//        print("11")
        gridDraggedindex.removeAll()
        return true
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {///return image
        gridDraggedindex.append(indexPath.item)
        return Bundle.main.bundleURL as NSPasteboardWriting
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
//        print("33")
        indexPathsOfItemsBeingDragged = indexPaths
    }//image index
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
//        print("44")
        indexPathsOfItemsBeingDragged = []
        gridDraggedindex.removeAll()
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
//        print("55")
        if proposedDropOperation.pointee == NSCollectionView.DropOperation.on {
            proposedDropOperation.pointee = NSCollectionView.DropOperation.before
        }
        
        if indexPathsOfItemsBeingDragged.count == 0 {
            //  print("aaaaaaaaaaaaaaa")
            return NSDragOperation.copy
        } else {
            //   print("bbbbbbbbbbbbbbb")
            return NSDragOperation.move
        }
    }
    
    func moveImageFromIndexPath(indexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView,layout collectionViewLayout: NSCollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> NSSize {
        return CGSize(width: collectionView.bounds.width-5, height: (collectionView.enclosingScrollView?.bounds.height ?? 5)-10)
    }
}






func getAttributedString(string: String, font:NSFont)->NSAttributedString{
    var attributes = [NSAttributedString.Key: AnyObject]()
    attributes[.foregroundColor] = NSColor.labelColor
    attributes[.font] = font
    let attributedString = NSAttributedString(string: string, attributes: attributes)
    return attributedString
}
