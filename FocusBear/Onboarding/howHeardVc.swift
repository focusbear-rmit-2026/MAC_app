//
//  howHeardVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 09/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class howHeardVc: NSViewController {

    @IBOutlet weak var textfield: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnContinue: Button!
   
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    var arrayItems = [[String:Any]]()
    
    var optionFirstText = "Friend recommended it"
    var optionSecondText = "Google"
    var optionThirdText = "Ad on Reddit or Twitter"
    var optionFourthText = "Somewhere else"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        

        

        textfield.delegate = self
        lblTitle.stringValue = "How did you hear about Focus Bear?"
        btnContinue.title = "Continue" //
        
        if let dic = configjson.value(forKey: "howHeardVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnContinue.title = dic.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
            optionFirstText = dic.value(forKey: "optionFirstText") as? String ?? optionFirstText
            optionSecondText = dic.value(forKey: "optionSecondText") as? String ?? optionSecondText
            optionThirdText = dic.value(forKey: "optionThirdText") as? String ?? optionThirdText
            optionFourthText = dic.value(forKey: "optionFourthText") as? String ?? optionFourthText
        }
    }
    override func viewWillAppear() {
        arrayItems = [["title":optionFirstText, "state":false], ["title":optionSecondText, "state":false], ["title":optionThirdText, "state":false]]
        arrayItems = arrayItems.shuffled()
        arrayItems.append(["title":optionFourthText, "state":false])
        tblView.reloadData()
        btnContinue.isEnabled = false
        textfield.isHidden = true
    }
    

    @IBAction func btnContinueClicked(_ sender: Any) {
        var heardFrom = ""
        for i in 0..<arrayItems.count{
            if arrayItems[i]["state"] as? Bool == true{
                heardFrom = arrayItems[i]["title"] as? String ?? ""
                if i == arrayItems.count - 1{
                    heardFrom = textfield.stringValue
                }
                break;
            }
        }
        
        print(heardFrom)
        allApiObject.capturePosthog(event: "heard_about_focus_bear", metadata: ["heard-from":heardFrom])
        self.view.window?.close()
        showOnboardingVideoWindow()
    }
}

extension howHeardVc: NSTableViewDelegate, NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrayItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHowHeardVc"), owner: nil) as? tblCellHowHeardVc {
            
            
            if row >= arrayItems.count{
                return cell
            }
            if arrayItems[row]["state"] as? Bool == true{
                cell.radioBtn.state = .on
            }else{
                cell.radioBtn.state = .off
            }
            
            cell.radioBtn.title = arrayItems[row]["title"] as? String ?? ""
            
            cell.radioBtn.target = self
            cell.radioBtn.tag = row
            cell.radioBtn.action = #selector(btnRadioClicked(sender:))
            
            return cell
        }
        return NSTableCellView()
    }

    @objc func btnRadioClicked(sender:NSButton){
        for i in 0..<arrayItems.count{
            if i == sender.tag{
                arrayItems[i]["state"] = true
            }else{
                arrayItems[i]["state"] = false
            }
        }
        tblView.reloadData()
        if sender.tag == arrayItems.count - 1{
            textfield.isHidden = false
            textfield.stringValue = ""
            btnContinue.isEnabled = false
            textfield.setFocus()
        }else{
            btnContinue.isEnabled = true
            textfield.isHidden = true
        }
        
    }
}


extension howHeardVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == self.textfield{
                if textfield.stringValue.isEmpty{
                    btnContinue.isEnabled = false
                }else{
                    btnContinue.isEnabled = true
                }
            }
        }
    }
}

class tblCellHowHeardVc: NSTableCellView {


    @IBOutlet weak var radioBtn: NSButton!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
