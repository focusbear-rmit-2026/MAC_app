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
    
    
    func resetView() {
        
        var focusMode = ""
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                focusMode = dic["name"] as? String ?? ""
            }
        }
        
        var titleText = "The toolbox makes it easy to open the apps and websites that you've allowed in the <FOCUS_NAME> focus mode. You can access it from the Menu under Tools."
        if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
            titleText = toolBoxVcInfo.value(forKey: "title") as? String ?? titleText
        }
        titleText = titleText.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
        
        lblTitle.stringValue = titleText

//        var viewHeight:CGFloat = 170
        if appdelegate!.allowAppsPath.count == 0 || isAllowedAllAppsInFocus {
            boxApps.isHidden = true
//            viewHeight = 71
        }else{
            boxApps.isHidden = false
            collectionViewApps.reloadData()
        }
        if appdelegate!.arrAllowedUrlsForFocus.count == 0 || isAllowedAllUrlsInFocus || !isAllowedListApproachInFocus{
            boxUrls.isHidden = true
//            viewHeight = 71
        }else{
            boxUrls.isHidden = false
            if appdelegate!.arrAllowedUrlsForFocus.count > 5{
                heightScrollView.constant = (5*29) + 5
            }else{
                heightScrollView.constant = CGFloat(appdelegate!.arrAllowedUrlsForFocus.count * 29) + 5
            }
            tblViewUrls.reloadData()
        }
       // heightBox.constant = viewHeight
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
//        if collectionView == collectionViewApps{
            return appdelegate!.allowAppsPath.count
//        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
     //   collectionview.register(collectionviewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionviewItem"))
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionCellToolBox"), for: indexPath) as! collectionCellToolBox
        
//        if collectionView == collectionViewApps{
            if item.btnIcon != nil{
                item.btnIcon.image = NSWorkspace.shared.icon(forFile: appdelegate!.allowAppsPath[indexPath.item])
            }
            item.urlString = ""
            item.btnIcon.target = self
            item.btnIcon.tag = indexPath.item
            item.btnIcon.action = #selector(btnOpenAppClicked(sender:))
//        }
//        else {
//            if item.btnIcon != nil{
//                item.btnIcon.image = NSImage(named: NSImage.networkName)
//            }
//            item.urlString = appdelegate!.arrAllowedUrlsForFocus[indexPath.item]
//            item.btnIcon.target = self
//            item.btnIcon.tag = indexPath.item
//            item.btnIcon.action = #selector(btnOpenUrlClicked(sender:))
//
//            print(indexPath)
//            print("***indexPath***")
//        }
        
        return item
    }
    
    @objc func btnOpenAppClicked(sender:NSButton){
        addLog(text: "toolBoxVc:- btnOpenAppClicked")
        NSWorkspace.shared.launchApplication(appdelegate!.allowAppsPath[sender.tag])
        allApiObject.capturePosthog(event: "toolbox-open-app-clicked", metadata: [:])
    }
    @objc func btnOpenUrlClicked(sender:NSButton){
        addLog(text: "toolBoxVc:- btnOpenUrlClicked")
        var url = appdelegate!.arrAllowedUrlsForFocus[sender.tag]
        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
            url = "http://"+url
        }
        NSWorkspace.shared.open(URL(string: url)!)
        allApiObject.capturePosthog(event: "toolbox-open-url-clicked", metadata: [:])
    }
    
}


extension toolBoxVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {

        return appdelegate!.arrAllowedUrlsForFocus.count
    }



    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellToolBox"), owner: nil) as? tblCellToolBox {


//            if cell.btnIcon != nil{
//                cell.btnIcon.image = NSImage(named: NSImage.networkName)
//            }
            cell.lblUrl.stringValue = appdelegate!.arrAllowedUrlsForFocus[row]
//            cell.btnIcon.target = self
//            cell.btnIcon.tag = indexPath.item
//            cell.btnIcon.action = #selector(btnOpenUrlClicked(sender:))
            
            return cell
        }

        return NSTableCellView()
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if tblViewUrls.selectedRow == -1{
            return
        }
        var url = appdelegate!.arrAllowedUrlsForFocus[tblViewUrls.selectedRow]
        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
            url = "http://"+url
        }
        NSWorkspace.shared.open(URL(string: url)!)
        tblViewUrls.reloadData()
        addLog(text: "toolBoxVc:- OpenUrlClicked")
        allApiObject.capturePosthog(event: "toolbox-open-url-clicked", metadata: [:])
    }
}
