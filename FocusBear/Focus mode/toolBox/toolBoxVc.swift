//
//  toolBoxVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class toolBoxVc: NSViewController {


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
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        lblTitle.stringValue = "The toolbox makes it easy to open the apps and websites that you've allowed in the {focus_mode_name} focus mode. You can access it from the Menu under Tools."
        lblCheckBox.stringValue = "Don't show this anymore when I start a focus block"
        lblTitleApps.stringValue = "Apps:"
        lblTitleUrls.stringValue = "Urls:"
        
        if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
            lblCheckBox.stringValue = toolBoxVcInfo.value(forKey: "checkBoxText") as? String ?? lblCheckBox.stringValue
            lblTitleApps.stringValue = toolBoxVcInfo.value(forKey: "appsText") as? String ?? lblTitleApps.stringValue
            lblTitleUrls.stringValue = toolBoxVcInfo.value(forKey: "urlsText") as? String ?? lblTitleUrls.stringValue
        }
        
    }
    
    var isFocusModeOn = false
    func resetView() {
        isFocusModeOn = Focus_Bear.isFocusModeOn()
        var focusMode = ""
//        for dic in arrFocusType{
//            if dic["isOn"] as? Bool == true{//
//                focusMode = dic["name"] as? String ?? ""
//            }
//        }
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
            
        }else if currentHabitPlaying != nil{
            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
            
            if allowAppsPath.count == 0{
                boxApps.isHidden = true
            }else{
                boxApps.isHidden = false
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
        }
        

        
       
        
        
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        getToolBoxWindowObject().window?.setFrameOrigin(NSPoint(x: 0, y: ((screenFrame.height) - (self.view.window?.frame.height ?? 100))))
        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) as? Bool == false{
            checkBoxDontShow.state = .off
        }else{
            checkBoxDontShow.state = .on
        }
    }
    @IBAction func checkBoxDontShowAutoClicked(_ sender: Any) {
        if checkBoxDontShow.state == .on{
            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-checked", metadata: [:])
            addLog(text: "toolBoxVc:- checkBoxDontShowAutoClicked:- state is on")
            UserDefaults.standard.set(true, forKey: kUserdefaultsDontShowToolBoxAutomatically)
        }else{
            allApiObject.capturePosthog(event: "toolbox-checkbox-dont-show-unchecked", metadata: [:])
            addLog(text: "toolBoxVc:- checkBoxDontShowAutoClicked:- state is off")
            UserDefaults.standard.set(false, forKey: kUserdefaultsDontShowToolBoxAutomatically)
        }
        
    }
}

extension toolBoxVc:NSCollectionViewDelegate, NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            return allowAppsPath.count
        }else if currentHabitPlaying != nil{
            let allowAppsPath = currentHabitPlaying?.allowApps ?? []
            return allowAppsPath.count
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionCellToolBox"), for: indexPath) as! collectionCellToolBox
        
        var allowAppsPath = [String]()
        
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            if item.btnIcon != nil{
                item.btnIcon.image = NSWorkspace.shared.icon(forFile: allowAppsPath[indexPath.item])
            }
        }else if currentHabitPlaying != nil{
            allowAppsPath = currentHabitPlaying?.allowApps ?? []
            if item.btnIcon != nil{
                item.btnIcon.image = NSWorkspace.shared.icon(forFile: "/Applications/\(allowAppsPath[indexPath.item]).app")
            }
        }else{
            return item
        }
        
        
        item.urlString = ""
        item.btnIcon.target = self
        item.btnIcon.tag = indexPath.item
        item.btnIcon.action = #selector(btnOpenAppClicked(sender:))
        
        return item
    }
    
    @objc func btnOpenAppClicked(sender:NSButton){
        addLog(text: "toolBoxVc:- btnOpenAppClicked")
        var allowAppsPath = [String]()
        
        if isFocusModeOn || isAnyAllowedFocusModeActivityRunning{
            allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            NSWorkspace.shared.launchApplication(allowAppsPath[sender.tag])
        }else if currentHabitPlaying != nil{
            allowAppsPath = currentHabitPlaying?.allowApps ?? []
            NSWorkspace.shared.launchApplication("/Applications/\(allowAppsPath[sender.tag]).app")
        }else{
            return;
        }

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
        addLog(text: "toolBoxVc:- OpenUrlClicked")
        allApiObject.capturePosthog(event: "toolbox-open-url-clicked", metadata: [:])
    }
}
