//
//  firstViewController.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {

    @IBOutlet weak var btnWidth: NSLayoutConstraint!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStartFirstHabit: NSButton!
    @IBOutlet weak var tblViewHabits: NSTableView!
    var isFirstTime = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = startMorningHabitTitleText
        btnStartFirstHabit.cell?.wraps = true
    }

    override func viewWillAppear() {
        if isFirstTime{
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            let welcomeText = "Welcome to Earn Your Screen Time"
            
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "welcomeMessageHeading") as? String ?? welcomeText
                if let subTitle = dic.value(forKey: "welcomeMessageIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
                if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                    let name = arr.first?.value(forKey: "name") as? String ?? ""
                    let durationSeconds = arr.first?.value(forKey: "durationSeconds") as? Int ?? 0
                    let videoUrl = arr.first?.value(forKey: "videoUrl") as? String
//                    if durationSeconds < 60{
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(durationSeconds) seconds", name: name)//"Start \(durationSeconds) seconds \(name)"
//                    }else{
//                        let minutes = durationSeconds/60
//                        if minutes == 1 {
//                            btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(minutes) minute", name: name)//"Start \(minutes) minute \(name)"
//                        }else {
//                            btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(minutes) minutes", name: name)//"Start \(minutes) minutes \(name)"
//                        }
//                    }
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                    introActivity = morningHabit(name: name, durationSeconds: durationSeconds, url: videoUrl)
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    introActivity = morningHabit(name: "mindful breathing", durationSeconds: 60, url: nil)
                }
            }else{
                introActivity = morningHabit(name: "mindful breathing", durationSeconds: 60, url: nil)
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
            }
            
            
           // btnWidth.constant = 460
        }else{
           // btnWidth.constant = 360
//            lblTitle.stringValue = "Good Morning! It’s time to earn your screentime. Here are the habits you need to accomplish before you can use your computer."
            if arrAllHabits.count != 0 {
//                if arrAllHabits[0].durationSeconds! == 1 {
//                    btnStartFirstHabit.title = "Start \(arrAllHabits[0].durationSeconds!) second \(arrAllHabits[0].name!)"
//                }else {
//                    btnStartFirstHabit.title = "Start \(arrAllHabits[0].durationSeconds!) seconds \(arrAllHabits[0].name!)"
//                }
                let time = arrAllHabits[0].durationSeconds!
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllHabits[0].name!)
//                if time < 60{
//                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(time) seconds", name: arrAllHabits[0].name!)//"Start \(time) seconds \(arrAllHabits[0].name!)"
//                }else{
//                    let minutes = time/60
//                    if minutes == 1 {
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(minutes) minute", name: arrAllHabits[0].name!)//"Start \(minutes) minute \(arrAllHabits[0].name!)"
//                    }else {
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: "\(minutes) minutes", name: arrAllHabits[0].name!)//"Start \(minutes) minutes \(arrAllHabits[0].name!)"
//                    }
//                }
            }
            tblViewHabits.isHidden = false
            tblViewHabits.reloadData()
            lblSubTitle.isHidden = true
            
         //   lblTitle.stringValue = "d"
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = .center
//            let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
//            let placeHolderStr = NSMutableAttributedString(string: "Good Morning! It’s time to earn your screentime. Here are the habits you need to accomplish before you can use your computer.", attributes: attrs)
//            let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("clock22")))
//            let attachment: NSTextAttachment = NSTextAttachment()
//            attachment.attachmentCell = attachmentCell
//            let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
//            placeHolderStr.append(attrString)
//            lblTitle.attributedStringValue = placeHolderStr
            // icon ase set krte h
        }
        
    }
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        if isFirstTime{
            mainViewControllerObj?.startBreathing()
        }else{
            mainViewControllerObj?.startFirstHabit()
        }
    }
}
extension firstViewController:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {

        return  arrAllHabits.count
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            cell.lblTitle.stringValue  = "\(row + 1).   \(arrAllHabits[row].name ?? "")"
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
}
