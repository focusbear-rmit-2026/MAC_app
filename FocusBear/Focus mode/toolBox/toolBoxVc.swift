//
//  toolBoxVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class toolBoxVc: NSViewController {//// not in use now  removed on 1/9/25  on version 2.27.408 // it could   // We may add it back in the future
    
    
    @IBOutlet weak var lblCheckBoxForActivity: NSTextField!
    @IBOutlet weak var checkBoxDontShowForActivity: NSButton!
    @IBOutlet weak var boxForAllowedActivity: NSBox!
    @IBOutlet weak var boxForFocusMode: NSBox!
    @IBOutlet weak var heightScrollView: NSLayoutConstraint!
    @IBOutlet weak var lblTitleUrls: NSTextField!
    @IBOutlet weak var lblTitleApps: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblCheckBox: NSTextField!
    @IBOutlet weak var checkBoxDontShow: NSButton!
    @IBOutlet weak var tblViewUrls: NSTableView!
    @IBOutlet weak var boxUrls: NSBox!
    @IBOutlet weak var boxApps: NSBox!
    //    @IBOutlet weak var heightBox: NSLayoutConstraint!
    //    @IBOutlet weak var scrollViewUrls: NSScrollView!
    @IBOutlet weak var scrollViewApps: NSScrollView!
    //    @IBOutlet weak var collectionViewUrls: NSCollectionView!
    @IBOutlet weak var collectionViewApps: NSCollectionView!
    
    var arrAllowedApps = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblCheckBoxForActivity.stringValue = "Don't Show toolbox when starting a habit with allowed apps"
        lblTitle.stringValue = "The toolbox makes it easy to open the apps and websites that you've allowed in the {focus_mode_name} focus mode. You can access it from the Menu under Tools."
        lblCheckBox.stringValue = "Don't show this anymore when I start a focus block"
        lblTitleApps.stringValue = "Apps:"
        lblTitleUrls.stringValue = "URLs:"
        
        if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
            lblCheckBox.stringValue = toolBoxVcInfo.value(forKey: "checkBoxText") as? String ?? lblCheckBox.stringValue
            lblTitleApps.stringValue = toolBoxVcInfo.value(forKey: "appsText") as? String ?? lblTitleApps.stringValue
            lblTitleUrls.stringValue = toolBoxVcInfo.value(forKey: "urlsText") as? String ?? lblTitleUrls.stringValue
            lblCheckBoxForActivity.stringValue = toolBoxVcInfo.value(forKey: "checkBoxActivityText") as? String ?? lblCheckBoxForActivity.stringValue
        }
        
    }
    
    var isFocusModeOn = false
    func resetView() {
        arrAllowedApps.removeAll()
        isFocusModeOn = Focus_Bear.isFocusModeOn()
        var focusMode = ""
        
        if currentHabitPlaying != nil{
            focusMode = currentHabitPlaying?.name ?? ""
            
            var titleText = "The toolbox makes it easy to open the apps and websites that you've allowed in the <ACTIVITY_NAME> activity. You can access it from the Menu under Tools."
            if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
                titleText = toolBoxVcInfo.value(forKey: "titleForActivity") as? String ?? titleText
            }
            titleText = titleText.replacingOccurrences(of: "<ACTIVITY_NAME>", with: focusMode)
            lblTitle.stringValue = titleText
            
        }else{
            focusMode = currentRunningFocusType["name"] as? String ?? ""
            var titleText = "The toolbox makes it easy to open the apps and websites that you've allowed in the <FOCUS_NAME> focus mode. You can access it from the Menu under Tools."
            if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
                titleText = toolBoxVcInfo.value(forKey: "title") as? String ?? titleText
            }
            titleText = titleText.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
            lblTitle.stringValue = titleText
        }
        
        //isAnyAllowedFocusModeActivityRunning
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            
            if allowAppsPath.count == 0 || isAllowedAllAppsInFocus {
                boxApps.isHidden = true
            }else{
                boxApps.isHidden = false
                for appPath in allowAppsPath{
                    if FileManager.default.fileExists(atPath: appPath){
                        arrAllowedApps.append(appPath)
                    }
                }
                
                collectionViewApps.reloadData()
            }
            
            let isAllowedAllUrlsInFocus = false//currentRunningFocusType["isAllowedAllUrls"] as? Bool ?? false#453
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            
            if arrAllowedUrlsForFocus.count == 0 || isAllowedAllUrlsInFocus || !isAllowedListApproachInFocus{
                boxUrls.isHidden = true
            }else{
                boxUrls.isHidden = false
                if arrAllowedUrlsForFocus.count > 5{
                    heightScrollView.constant = (5*29) + 5
                }else{
                    heightScrollView.constant = CGFloat(arrAllowedUrlsForFocus.count * 29) + 5
                }
                tblViewUrls.reloadData()
            }
            
            boxForFocusMode.isHidden = false
            boxForAllowedActivity.isHidden = true
        }else if currentHabitPlaying != nil{
            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
            
            if allowAppsPath.count == 0{
                boxApps.isHidden = true
            }else{
                boxApps.isHidden = false
                for app in allowAppsPath{
                    
                    let urls = FileManager.default.urls(for: .applicationDirectory, in: [.systemDomainMask, .localDomainMask])
                    for url in urls{
                        var appUrl = url.appendingPathComponent("\(app).app")
                        if FileManager.default.fileExists(atPath: appUrl.path){
                            self.arrAllowedApps.append(appUrl.path)
                            break;
                        }
                        let utilitiesUrl = url.appendingPathComponent("Utilities")
                        appUrl = utilitiesUrl.appendingPathComponent("\(app).app")
                        if FileManager.default.fileExists(atPath: appUrl.path){
                            self.arrAllowedApps.append(appUrl.path)
                            break;
                        }
                    }
                    
                }
                collectionViewApps.reloadData()
            }

            let arrAllowedUrlsForFocus = currentHabitPlaying?.allowUrls ?? []
            
            if arrAllowedUrlsForFocus.count == 0{
                boxUrls.isHidden = true
            }else{
                boxUrls.isHidden = false
                if arrAllowedUrlsForFocus.count > 5{
                    heightScrollView.constant = (5*29) + 5
                }else{
                    heightScrollView.constant = CGFloat(arrAllowedUrlsForFocus.count * 29) + 5
                }
                tblViewUrls.reloadData()
            }
            
            boxForFocusMode.isHidden = true
            boxForAllowedActivity.isHidden = false
        }

//        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//        getToolBoxWindowObject().window?.setFrameOrigin(NSPoint(x: 0, y: ((screenFrame.height) - (self.view.window?.frame.height ?? 100))))
//        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) as? Bool == false{
//            checkBoxDontShow.state = .off
//        }else{
//            checkBoxDontShow.state = .on
//        }
//        
//        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity) as? Bool == false{
//            checkBoxDontShowForActivity.state = .off
//        }else{
//            checkBoxDontShowForActivity.state = .on
//        }
    }
    @IBAction func checkBoxDontShowAutoClicked(_ sender: Any) {
//        if checkBoxDontShow.state == .on{
//            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-checked", metadata: [:])
//            addLog(text: "toolBoxVc:- checkBoxDontShowAutoClicked:- state is on")
//            UserDefaults.standard.set(true, forKey: kUserdefaultsDontShowToolBoxAutomatically)
//        }else{
//            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-unchecked", metadata: [:])
//            addLog(text: "toolBoxVc:- checkBoxDontShowAutoClicked:- state is off")
//            UserDefaults.standard.set(false, forKey: kUserdefaultsDontShowToolBoxAutomatically)
//        }
        
    }
    
    @IBAction func checkBoxDontShowAutoForActivityClicked(_ sender: Any) {
//        if checkBoxDontShowForActivity.state == .on{
//            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-checked-for-activity", metadata: [:])
//            addLog(text: "toolBoxVc:- checkBoxDontShowAutoForActivityClicked:- state is on")
//            UserDefaults.standard.set(true, forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity)
//        }else{
//            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-unchecked-for-activity", metadata: [:])
//            addLog(text: "toolBoxVc:- checkBoxDontShowAutoForActivityClicked:- state is off")
//            UserDefaults.standard.set(false, forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity)
//        }
        
    }
}

extension toolBoxVc:NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrAllowedApps.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionCellToolBox"), for: indexPath) as! collectionCellToolBox
        
        if item.btnIcon != nil{
            item.appName = URL(fileURLWithPath: arrAllowedApps[indexPath.item]).lastPathComponent
            item.btnIcon.image = NSWorkspace.shared.icon(forFile: arrAllowedApps[indexPath.item])
        }
        item.lblAppName.stringValue = item.appName
        item.btnIcon.target = self
        item.btnIcon.tag = indexPath.item
        item.btnIcon.action = #selector(btnOpenAppClicked(sender:))
        item.setTrackingArea()
        return item
    }
    
    @objc func btnOpenAppClicked(sender:NSButton){
        addLog(text: "[user-action] toolBoxVc:- btnOpenAppClicked")
        NSWorkspace.shared.launchApplication(arrAllowedApps[sender.tag])
        
        allApiObject.capturePosthog(event: "toolbox-open-app-clicked", metadata: [:])
    }
    
    
}


extension toolBoxVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        var arrAllowedUrls = [String]()
        
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            arrAllowedUrls = currentRunningFocusType["allowed_urls"] as? [String] ?? []
        }else if currentHabitPlaying != nil{
            arrAllowedUrls = currentHabitPlaying?.allowUrls ?? []
        }
        
        return arrAllowedUrls.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellToolBox"), owner: nil) as? tblCellToolBox {
            var arrAllowedUrls = [String]()
            
            if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
                arrAllowedUrls = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            }else if currentHabitPlaying != nil{
                arrAllowedUrls = currentHabitPlaying?.allowUrls ?? []
            }
            cell.lblUrl.stringValue = arrAllowedUrls[row]
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblViewUrls.selectedRow == -1{
            return
        }
        var arrAllowedUrls = [String]()
        
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            arrAllowedUrls = currentRunningFocusType["allowed_urls"] as? [String] ?? []
        }else if currentHabitPlaying != nil{
            arrAllowedUrls = currentHabitPlaying?.allowUrls ?? []
        }
        
        var url = arrAllowedUrls[tblViewUrls.selectedRow]
        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
            url = "http://"+url
        }
        NSWorkspace.shared.open(URL(string: url)!)
        tblViewUrls.reloadData()
        addLog(text: "[user-action] toolBoxVc:- OpenUrlClicked")
        allApiObject.capturePosthog(event: "toolbox-open-url-clicked", metadata: [:])
    }
}
