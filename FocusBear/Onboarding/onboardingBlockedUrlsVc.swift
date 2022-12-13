//
//  onboardingBlockedUrlsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 09/12/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingBlockedUrlsVc: NSViewController {

    @IBOutlet weak var btnAddUrl: Button!
    @IBOutlet weak var lblEnterUrl: NSTextField!
    @IBOutlet weak var textFieldUrl: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblBottom: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var arrBlockedUrls:[[String:Any]] = [["url":"facebook.com", "isSelected":true],
                                         ["url":"twitter.com", "isSelected":true],
                                         ["url":"instagram.com", "isSelected":true],
                                         ["url":"tiktok.com", "isSelected":true],
                                         ["url":"bbc.com", "isSelected":true],
                                         ["url":"cnn.com", "isSelected":true]]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblEnterUrl.stringValue = "Enter utl to block:"
        btnAddUrl.title = "Add url"
        
        lblTitle.stringValue = "Welcome to Focus Bear"
        lblQuestion.stringValue = "Which sites do you find distracting?"
        lblDescription.stringValue = "You can block certain sites by default to avoid going down rabbit holes."
        lblBottom.stringValue = "If you want to block other sites by default, you can change your Always Blocked settings in Preferences."
        btnContinue.title = "Continue"
        
        
        if let onboardingBlockedUrlsInfo = configjson.value(forKey: "onboardingBlockedUrlsInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingBlockedUrlsInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestion.stringValue = onboardingBlockedUrlsInfo.value(forKey: "questionText") as? String ?? lblQuestion.stringValue
            lblDescription.stringValue = onboardingBlockedUrlsInfo.value(forKey: "description") as? String ?? lblDescription.stringValue
            lblBottom.stringValue = onboardingBlockedUrlsInfo.value(forKey: "bottomText") as? String ?? lblBottom.stringValue
            btnContinue.title = onboardingBlockedUrlsInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            lblEnterUrl.stringValue = onboardingBlockedUrlsInfo.value(forKey: "enterUrlText") as? String ?? lblEnterUrl.stringValue
            btnAddUrl.title = onboardingBlockedUrlsInfo.value(forKey: "buttonAddUrlText") as? String ?? btnAddUrl.title
        }
        
        tblView.delegate = self
        tblView.dataSource = self
        
        textFieldUrl.delegate = self
    }
    
    override func viewWillAppear() {
        tblView.reloadData()
        btnAddUrl.isEnabled = false
        textFieldUrl.stringValue = ""
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
//todo logs // 

        UserDefaults.standard.set(arrBlockedUrls, forKey: kUserdefaultsBlockedUrlsFromOnboarding)
        addLog(text: "habitSkip Onboarding view:- btnContinueClicked:")
        appdelegate!.showOnbardingHabit()
    }
    @IBAction func btnAddUrlClicked(_ sender: Any) {
        let domain = textFieldUrl.stringValue
        for dic in arrBlockedUrls{
            if let url = dic["url"] as? String {
                if url.lowercased() == domain.lowercased(){
                    btnAddUrl.isEnabled = false
                    textFieldUrl.stringValue = ""
                    return;
                }
            }
        }
        
        arrBlockedUrls.append(["url":domain, "isSelected":true])
        tblView.reloadData()
        tblView.selectRowIndexes(IndexSet(arrayLiteral: (arrBlockedUrls.count - 1)), byExtendingSelection: false)
        tblView.scrollRowToVisible(arrBlockedUrls.count - 1)
        btnAddUrl.isEnabled = false
        textFieldUrl.stringValue = ""
    }
    
}
extension onboardingBlockedUrlsVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrBlockedUrls.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellOnboardingBlockedUrls"), owner: nil) as? tblCellOnboardingBlockedUrls {
            
            let dic = arrBlockedUrls[row]
            if let url = dic["url"] as? String {
                cell.btnCheckBox.title = url
            }else{
                cell.btnCheckBox.title = ""
            }
            
            if let isSelected = dic["isSelected"] as? Bool {
                if isSelected{
                    cell.btnCheckBox.state = .on
                }else{
                    cell.btnCheckBox.state = .off
                }
            }else{
                cell.btnCheckBox.state = .off
            }
            
            cell.btnCheckBox.target = self
            cell.btnCheckBox.tag = row
            cell.btnCheckBox.action = #selector(btnCheckBoxClicked(sender:))
            
            return cell
        }
        
        return NSTableCellView()
    }

    @objc func btnCheckBoxClicked(sender:NSButton){
        var dic = arrBlockedUrls[sender.tag]

        if dic["isSelected"] as? Bool == true{
            dic["isSelected"] = false
        }else{
            dic["isSelected"] = true
        }
        arrBlockedUrls[sender.tag] = dic
        tblView.reloadData()
    }
}
extension onboardingBlockedUrlsVc:NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if obj.object as? NSTextField == textFieldUrl{
            if textFieldUrl.stringValue.isEmpty{
                btnAddUrl.isEnabled = false
            }else{
                
                let domain = textFieldUrl.stringValue
                if domain.contains("*"){
                    let string = domain.replacingOccurrences(of: "*", with: "")
                    if string.isEmpty{
                        btnAddUrl.isEnabled = false
                    }else{
                        btnAddUrl.isEnabled = true
                    }
                }else{
                    btnAddUrl.isEnabled = true
                }
            }
        }
    }
}
