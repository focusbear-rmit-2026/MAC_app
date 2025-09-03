//
//  addTaskVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/03/24.
//

import Cocoa

class createTaskVc: NSViewController {


    @IBOutlet weak var comboBoxProjects: searchableComboBox!
    @IBOutlet weak var lblTitleProjects: NSTextField!
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnCreate: Button!
    @IBOutlet weak var popUpBtnElsenhowerQuadrant: NSPopUpButton!
    @IBOutlet weak var datePicker: NSDatePicker!
    @IBOutlet var textViewIntention: NSTextView!
    @IBOutlet var textViewDescription: NSTextView!
    @IBOutlet weak var lblTitleElsenhower: NSTextField!
    @IBOutlet weak var lblTitleDueDate: NSTextField!
    @IBOutlet weak var lblTitleIntention: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var textFieldTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Title"
        lblDescription.stringValue = "Description"
        lblTitleIntention.stringValue = "Why do you want to do this task? How will you motivate yourself to do this task?"
        lblTitleDueDate.stringValue = "Due Date"
        lblTitleElsenhower.stringValue = "Elsenhower quadrant"
        lblTitleProjects.stringValue = "Projects"
        popUpBtnElsenhowerQuadrant.removeAllItems()
        popUpBtnElsenhowerQuadrant.addItems(withTitles: ["Urgent and Important", "Important but not urgent", "Not important and urgent", "Not important and not urgent"])
        btnCreate.title = "Create"
        var arrItems = ["Urgent and Important", "Important but not urgent", "Not important and urgent", "Not important and not urgent"]
        if let createTaskVcInfo = configjson.value(forKey: "createTaskVcInfo") as? NSDictionary{
            lblTitle.stringValue = createTaskVcInfo.value(forKey: "titleName") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = createTaskVcInfo.value(forKey: "titleDescription") as? String ?? lblDescription.stringValue
            lblTitleIntention.stringValue = createTaskVcInfo.value(forKey: "titleIntention") as? String ?? lblTitleIntention.stringValue
            lblTitleDueDate.stringValue = createTaskVcInfo.value(forKey: "titleDueDatePlain") as? String ?? lblTitleDueDate.stringValue
            lblTitleElsenhower.stringValue = createTaskVcInfo.value(forKey: "titleElsenhower") as? String ?? lblTitleElsenhower.stringValue
            lblTitleProjects.stringValue = createTaskVcInfo.value(forKey: "titleProjects") as? String ?? lblTitleProjects.stringValue
            arrItems = createTaskVcInfo.value(forKey: "elsenhowerQuadrantOptions") as? [String] ?? arrItems
            btnCreate.title = createTaskVcInfo.value(forKey: "buttonCreateText") as? String ?? btnCreate.title
        }
        
        popUpBtnElsenhowerQuadrant.removeAllItems()
        popUpBtnElsenhowerQuadrant.addItems(withTitles: arrItems)
        
        btnCancel.title = buttonCancelText
        btnCancel.buttonColor = NSColor.white.cgColor
        textFieldTitle.delegate = self
        comboBoxProjects.customDelegate = self
        comboBoxProjects.stringValue = ""//"Remember the last project for create task" so do not do this in "resetData" func
    }
    var arrAllTags = [String]()
    func resetData(dueDate:Date) {
        textFieldTitle.stringValue = ""
        textViewDescription.string = ""
        textViewIntention.string = ""
        datePicker.dateValue = Date()
        popUpBtnElsenhowerQuadrant.selectItem(at: 0)
        textFieldTitle.setFocus()
        comboBoxProjects.items.removeAll()
        arrAllTags.removeAll()
        for tagInfo in arrAllFocusModeTags{
            arrAllTags.append(tagInfo["text"] ?? "")
            comboBoxProjects.items.append(tagInfo["text"] ?? "")
            print(tagInfo)
        }
        comboBoxProjects.reloadData()
        btnCreate.isEnabled = false
        datePicker.dateValue = dueDate
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }

    @IBAction func btnCreateClicked(_ sender: Any) {
        btnCreate.isEnabled = false
        btnCancel.isEnabled = false
        loader.startAnimation(self)
        let dateString = getStringFromDateInUtc(date: datePicker.dateValue, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        let title = textFieldTitle.stringValue
        let details = textViewDescription.string
        let objective = textViewIntention.string

        var tags = [[String:String]]()
        if !comboBoxProjects.stringValue.isEmpty{
            let tag = comboBoxProjects.stringValue
            let id = getIdForTag(tag: tag)
            tags = [["id": id, "text": tag]]
        }
        
        allApiObject.addTask(title: title, details: details, eisenhowerQuadrant: (popUpBtnElsenhowerQuadrant.indexOfSelectedItem + 1), dueDate: dateString, objective:objective, tags: tags, completionHandler: { result,json  in
            
            DispatchQueue.main.async {
                self.btnCreate.isEnabled = true
                self.btnCancel.isEnabled = true
                self.loader.stopAnimation(self)
            }
            if result{
                DispatchQueue.main.async {
                    addLog(text: "\(title) task created successfully.")
                    self.view.window?.close()
                }
            }
        })
    }
    @IBAction func comboBoxProjectsSelected(_ sender: Any) {
    }
}

extension createTaskVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if textField == self.textFieldTitle{
                if textFieldTitle.stringValue.isEmpty{
                    btnCreate.isEnabled = false
                }else{
                    btnCreate.isEnabled = true
                }
            }
        }
    }
}

extension createTaskVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if comboBox.stringValue.isEmpty{
            return;
        }

    }
}
