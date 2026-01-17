//
//  askOccupationVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/04/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askOccupationVc: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var btnSkip: underLineButton!
    @IBOutlet weak var textFieldFreelancer: NSTextField!
    @IBOutlet weak var lblTitleSpecify: NSTextField!
    @IBOutlet weak var boxEmployee: NSBox!
    @IBOutlet weak var boxStudy: NSBox!
    @IBOutlet weak var radioBtnFieldWork: NSButton!
    @IBOutlet weak var radioBtnOtherOfficeWork: NSButton!
    @IBOutlet weak var radioBtnGraphicDesigner: NSButton!
    @IBOutlet weak var radioBtnProgrammer: NSButton!
    @IBOutlet weak var lblSelectIndustry: NSTextField!
    @IBOutlet weak var radioBtnPostGraduate: NSButton!
    @IBOutlet weak var radioBtnGraduate: NSButton!
    @IBOutlet weak var radioBtnUndergraduate: NSButton!
    @IBOutlet weak var radioBtnHighSchool: NSButton!
    @IBOutlet weak var lblSelectStudyLevel: NSTextField!
    @IBOutlet weak var textFieldFieldWork: NSTextField!
    @IBOutlet weak var textFieldOtherOfficeWork: NSTextField!
    @IBOutlet weak var stackViewEmployee: NSStackView!
    @IBOutlet weak var stackViewStudy: NSStackView!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var topSpaceCollectionView: NSLayoutConstraint!
//    @IBOutlet weak var bottomSpaceCollectionView: NSLayoutConstraint!
    @IBOutlet weak var textFieldOther: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var collectionView: NSCollectionView!
    var selectedIndex = -1
    var arrOccupations = [String]()
    var isStudentSelected = false
    var studentIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnSkip.title = "Skip"
        lblTitle.stringValue = "Create your distraction blocking profile"
        
        
        lblSelectStudyLevel.stringValue = "Select level of study:"
        radioBtnHighSchool.title = "High school"
        radioBtnUndergraduate.title = "Undergraduate"
        radioBtnGraduate.title = "Graduate"
        radioBtnPostGraduate.title = "Postgraduate"
        lblSelectIndustry.stringValue = "Type of work:"
        radioBtnProgrammer.title = "Programmer"
        radioBtnGraphicDesigner.title = "Graphic designer"
        radioBtnOtherOfficeWork.title = "Other work from office"
        radioBtnFieldWork.title = "Non desk based work"
        
        lblTitleSpecify.stringValue = "Type of work:"
        
        var occupationFreelancer = "Freelancer"
        var occupationStudent = "University student"
        var occupationBusinessOwner = "Business owner"
        var occupationEmployee = "Employee"
        var occupationOther = "Other"
        
        
        
        
        lblSubTitle.stringValue = "What type of work do you do?"
        lblDescription.stringValue = "This will be used to recommend the most suitable features for your work."
        btnContinue.title = "Continue"
        arrOccupations = ["University student"," Software dev", "Graphic designer", "Business owner", "Other office work", "Field worker (not in front of computer)", "Parent (setting it up for child)", "Other"]

        if let askAppWorkVcInfo = configjson.value(forKey: "askAppWorkVcInfo") as? NSDictionary{
            btnContinue.title = askAppWorkVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = askOccupationVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblDescription.stringValue = askOccupationVcInfo.value(forKey: "description") as? String ?? lblDescription.stringValue

            lblSelectStudyLevel.stringValue = askOccupationVcInfo.value(forKey: "titleSelectLevelStudy") as? String ?? lblSelectStudyLevel.stringValue
            radioBtnHighSchool.title = askOccupationVcInfo.value(forKey: "optionSchool") as? String ?? radioBtnHighSchool.title
            radioBtnUndergraduate.title = askOccupationVcInfo.value(forKey: "optionUndergraduate") as? String ?? radioBtnUndergraduate.title
            radioBtnGraduate.title = askOccupationVcInfo.value(forKey: "optionGraduate") as? String ?? radioBtnGraduate.title
            radioBtnPostGraduate.title = askOccupationVcInfo.value(forKey: "optionPostgraduate") as? String ?? radioBtnPostGraduate.title
            lblSelectIndustry.stringValue = askOccupationVcInfo.value(forKey: "titleSelectIndustry") as? String ?? lblSelectIndustry.stringValue
            radioBtnProgrammer.title = askOccupationVcInfo.value(forKey: "optionProgrammer") as? String ?? radioBtnProgrammer.title
            radioBtnGraphicDesigner.title = askOccupationVcInfo.value(forKey: "optionGraphicDesigner") as? String ?? radioBtnGraphicDesigner.title
            radioBtnOtherOfficeWork.title = askOccupationVcInfo.value(forKey: "optionOtherOfficeWork") as? String ?? radioBtnOtherOfficeWork.title
            radioBtnFieldWork.title = askOccupationVcInfo.value(forKey: "optionFieldWork") as? String ?? radioBtnFieldWork.title
            occupationStudent = askOccupationVcInfo.value(forKey: "occupationStudent") as? String ?? occupationStudent
            occupationBusinessOwner = askOccupationVcInfo.value(forKey: "occupationBusinessOwner") as? String ?? occupationBusinessOwner
            occupationEmployee = askOccupationVcInfo.value(forKey: "occupationEmployee") as? String ?? occupationEmployee
            occupationOther = askOccupationVcInfo.value(forKey: "occupationOther") as? String ?? occupationOther
            occupationFreelancer = askOccupationVcInfo.value(forKey: "occupationFreelancer") as? String ?? occupationFreelancer
            
            
            lblTitleSpecify.stringValue = askOccupationVcInfo.value(forKey: "titleFreelancerType") as? String ?? lblTitleSpecify.stringValue
            lblTitle.stringValue = askOccupationVcInfo.value(forKey: "titleBlockingProfile") as? String ?? lblTitle.stringValue
        }
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            btnSkip.title = dic.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
        
        occupationStudentIndex = 0
        occupationBusinessOwnerIndex = 1
        occupationEmployeeIndex = 2
        occupationFreelancerIndex = 3
        occupationOtherIndex = 4
        
        arrOccupations = [occupationStudent, occupationBusinessOwner, occupationEmployee, occupationFreelancer, occupationOther]
        collectionView.allowsMultipleSelection = false
        selectedIndex = -1

        textFieldOther.delegate = self
        textFieldFieldWork.delegate = self
        textFieldOtherOfficeWork.delegate = self
        
        boxStudy.isHidden = true
        boxEmployee.isHidden = true
        textFieldOther.isHidden = true
        textFieldFreelancer.isHidden = true
        lblTitleSpecify.isHidden = true
    }

    @objc func viewDidResize(){
        if self.view.frame.height < 600{
            lblTitle.font = NSFont.systemFont(ofSize: 24)
            lblSubTitle.font = NSFont.systemFont(ofSize: 15)
            lblDescription.font = NSFont.systemFont(ofSize: 13)
            topSpaceCollectionView.constant = 8
            stackViewStudy.spacing = 3
            stackViewEmployee.spacing = 3
        }else if self.view.frame.height < 700{
            lblTitle.font = NSFont.systemFont(ofSize: 30)
            lblSubTitle.font = NSFont.systemFont(ofSize: 19)
            lblDescription.font = NSFont.systemFont(ofSize: 16)
            topSpaceCollectionView.constant = 20
            stackViewStudy.spacing = 7
            stackViewEmployee.spacing = 7
        }else if self.view.frame.height < 900{
            lblTitle.font = NSFont.systemFont(ofSize: 36)
            lblSubTitle.font = NSFont.systemFont(ofSize: 21)
            lblDescription.font = NSFont.systemFont(ofSize: 18)
            topSpaceCollectionView.constant = 30
            stackViewStudy.spacing = 12
            stackViewEmployee.spacing = 12
        }else{
            lblTitle.font = NSFont.systemFont(ofSize: 40)
            lblSubTitle.font = NSFont.systemFont(ofSize: 23)
            lblDescription.font = NSFont.systemFont(ofSize: 20)
            topSpaceCollectionView.constant = 35
            stackViewStudy.spacing = 15
            stackViewEmployee.spacing = 15
        }
        collectionView.reloadData()
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "ask-occupation-screen-shown", metadata: [:])
        textFieldOther.isHidden = true
        textFieldOther.stringValue = ""
        btnContinue.isEnabled = false
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "ask-occupation-screen")
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
        NotificationCenter.default.removeObserver(self)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldOther{
                checkContinueButtonState()
            }
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] ask occupation view:- button Skip clicked.")
//        mainViewControllerObj?.showCreateBlockingProfileVc()
        
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showAskAppWorkVc()
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        if selectedIndex == -1{
            return;
        }
        addLog(text: "[user-action] ask occupation view:- button continue clicked.")
        isStudentSelected = false
        var occupationToSave = ""
        var selectedIndexToSave = selectedIndex
        var posthogJson = [String : Any]()
        if selectedIndex == occupationStudentIndex{
            isStudentSelected = true
            var studentJson = [String : Any]()
            if radioBtnHighSchool.state == .on{
                studentJson = ["University student": "High school"]
                occupationToSave = "universityStudent_highSchool"
            }else if radioBtnUndergraduate.state == .on{
                studentJson = ["University student": "Undergraduate"]
                occupationToSave = "universityStudent_Undergraduate"
            }else if radioBtnGraduate.state == .on{
                studentJson = ["University student": "Graduate"]
                occupationToSave = "universityStudent_Graduate"
            }else if radioBtnPostGraduate.state == .on{
                studentJson = ["University student": "Postgraduate"]
                occupationToSave = "universityStudent_Postgraduate"
            }
            if studentJson.keys.isEmpty{
                posthogJson = [
                    "occupation": "University student"
                ]
                occupationToSave = "universityStudent"
            }else{
                posthogJson = [
                    "occupation": studentJson
                ]
            }
        }else if selectedIndex == occupationBusinessOwnerIndex{
            posthogJson = [
                "occupation": "Business owner"
            ]
            occupationToSave = "businessOwner"
        }else if selectedIndex == occupationEmployeeIndex{
            var employeeJson = [String : Any]()
            
            if radioBtnProgrammer.state == .on{
                employeeJson = ["Employee": "Programmer"]
                selectedIndexToSave = occupationProgrammerIndex
                occupationToSave = "employee_Programmer"
            }else if radioBtnGraphicDesigner.state == .on{
                employeeJson = ["Employee": "Graphic designer"]
                selectedIndexToSave = occupationGraphicDesignerIndex
                occupationToSave = "employee_GraphicDesigner"
            }else if radioBtnOtherOfficeWork.state == .on{
                employeeJson = ["Employee": ["Other work from office": textFieldOtherOfficeWork.stringValue]]
                selectedIndexToSave = occupationOtherOfficeWorkIndex
                
                if textFieldOtherOfficeWork.stringValue.isEmpty{
                    occupationToSave = "employee_OtherWorkFromOffice"
                }else{
                    occupationToSave = "employee_OtherWorkFromOffice_\(textFieldOtherOfficeWork.stringValue)"
                }
            }else if radioBtnFieldWork.state == .on{
                employeeJson = ["Employee": ["Non desk based work": textFieldFieldWork.stringValue]]
                selectedIndexToSave = occupationFieldWorkIndex
                
                if textFieldFieldWork.stringValue.isEmpty{
                    occupationToSave = "employee_NonDeskBasedWork"
                }else{
                    occupationToSave = "employee_NonDeskBasedWork_\(textFieldFieldWork.stringValue)"
                }
            }
            
            if employeeJson.keys.isEmpty{
                posthogJson = [
                    "occupation": "Employee"
                ]
                occupationToSave = "employee"
            }else{
                posthogJson = [
                    "occupation": employeeJson
                ]
            }
            
        }else if selectedIndex == occupationFreelancerIndex{
            var freelancerJson = [String : Any]()
            
            if !textFieldFreelancer.stringValue.isEmpty{
                freelancerJson = ["Freelancer": textFieldFreelancer.stringValue]
                occupationToSave = "freelancer_\(textFieldFreelancer.stringValue)"
            }
            if freelancerJson.keys.isEmpty{
                posthogJson = [
                    "occupation": "Freelancer"
                ]
                occupationToSave = "freelancer"
            }else{
                posthogJson = [
                    "occupation": freelancerJson
                ]
            }
            
        }else if selectedIndex == occupationOtherIndex{
            if !textFieldOther.stringValue.isEmpty{
                posthogJson = [
                    "occupation": textFieldOther.stringValue
                ]
                occupationToSave = "other_\(textFieldOther.stringValue)"
            }else{
                posthogJson = [
                    "occupation": "Other"
                ]
                occupationToSave = "other"
            }
        }
        UserDefaults.standard.set(occupationToSave, forKey: kUserDefaultsSelectedOccupationForPosthog)
        UserDefaults.standard.set(selectedIndexToSave, forKey: kUserDefaultsSelectedOccupationIndex)
        allApiObject.capturePosthog(event: "occupation-selected", metadata: posthogJson)
//        mainViewControllerObj?.showAchieveWithFocusBearVc()
//        mainViewControllerObj?.showCreateBlockingProfileVc()
        
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showAskAppWorkVc()
    }
    
    func checkContinueButtonState(){
        if selectedIndex == -1{
            btnContinue.isEnabled = false
            return;
        }
        btnContinue.isEnabled = true
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        var msg = "We’ll set up a special focus mode designed for your job that will have websites and apps that are relevant for your work. This information also helps us understand who’s using the app so we can improve the features."
        if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
            msg = askOccupationVcInfo.value(forKey: "infoText") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:300, autoCloseOnMouseExit: true)
    }
    
    @IBAction func radioBtnHighSchoolClicked(_ sender: Any) {
        radioBtnUndergraduate.state = .off
        radioBtnGraduate.state = .off
        radioBtnPostGraduate.state = .off
    }
    @IBAction func radioBtnUndergraduateClicked(_ sender: Any) {
        radioBtnHighSchool.state = .off
        radioBtnGraduate.state = .off
        radioBtnPostGraduate.state = .off
    }
    @IBAction func radioBtnGraduateClicked(_ sender: Any) {
        radioBtnHighSchool.state = .off
        radioBtnUndergraduate.state = .off
        radioBtnPostGraduate.state = .off
    }
    @IBAction func radioBtnPostGraduateClicked(_ sender: Any) {
        radioBtnHighSchool.state = .off
        radioBtnUndergraduate.state = .off
        radioBtnGraduate.state = .off
    }
    @IBAction func radioBtnProgrammerClicked(_ sender: Any) {
        radioBtnGraphicDesigner.state = .off
        radioBtnOtherOfficeWork.state = .off
        radioBtnFieldWork.state = .off
        textFieldFieldWork.isHidden = true
        textFieldOtherOfficeWork.isHidden = true
    }
    @IBAction func radioBtnGraphicDesignerClicked(_ sender: Any) {
        radioBtnProgrammer.state = .off
        radioBtnOtherOfficeWork.state = .off
        radioBtnFieldWork.state = .off
        textFieldFieldWork.isHidden = true
        textFieldOtherOfficeWork.isHidden = true
    }
    @IBAction func radioBtnOtherOfficeWorkClicked(_ sender: Any) {
        radioBtnProgrammer.state = .off
        radioBtnGraphicDesigner.state = .off
        radioBtnFieldWork.state = .off
        textFieldFieldWork.isHidden = true
        textFieldOtherOfficeWork.isHidden = false
        textFieldOtherOfficeWork.setFocus()
    }
    @IBAction func radioBtnFieldWorkClicked(_ sender: Any) {
        radioBtnProgrammer.state = .off
        radioBtnGraphicDesigner.state = .off
        radioBtnOtherOfficeWork.state = .off
        textFieldFieldWork.isHidden = false
        textFieldOtherOfficeWork.isHidden = true
        textFieldFieldWork.setFocus()
    }
}
extension askOccupationVc: NSCollectionViewDelegate, NSCollectionViewDataSource{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return arrOccupations.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionViewItemOccupation"), for: indexPath) as! collectionViewItemOccupation
        item.lblTitle.stringValue = arrOccupations[indexPath.item]
        if selectedIndex == indexPath.item{
            item.isItemSelected = true
        }else{
            item.isItemSelected = false
        }
        item.updateSelection()
        return item
    }
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        if let indexPath = indexPaths.first{
            selectedIndex = indexPath.item
            collectionView.reloadData()
            boxStudy.isHidden = true
            boxEmployee.isHidden = true
            textFieldOther.isHidden = true
            
            lblTitleSpecify.isHidden = true
            textFieldFreelancer.isHidden = true
            if selectedIndex == occupationStudentIndex{
                boxStudy.isHidden = false
                radioBtnHighSchool.state = .off
                radioBtnGraduate.state = .off
                radioBtnUndergraduate.state = .off
                radioBtnPostGraduate.state = .off
                var studentInfoText = "FYI your university might be able to pay for premium access to Focus Bear. Email support@focusbear.io for details."
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    studentInfoText = askOccupationVcInfo.value(forKey: "studentInfoText") as? String ?? studentInfoText
                }
                
                showTooltip(sender: collectionView, msg: studentInfoText, preferredEdge: NSRectEdge.minX, maxWidthVal:230)//todo 
            }else if selectedIndex == occupationEmployeeIndex{
                boxEmployee.isHidden = false
                radioBtnProgrammer.state = .off
                radioBtnGraphicDesigner.state = .off
                radioBtnOtherOfficeWork.state = .off
                radioBtnFieldWork.state = .off
                textFieldFieldWork.isHidden = true
                textFieldOtherOfficeWork.isHidden = true
            }else if selectedIndex == occupationFreelancerIndex{
                lblTitleSpecify.isHidden = false
                textFieldFreelancer.isHidden = false
                textFieldFreelancer.setFocus()
            }else if selectedIndex == occupationOtherIndex{
                textFieldOther.isHidden = false
                textFieldOther.setFocus()
            }
            
            checkContinueButtonState()
        }
    }
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        checkContinueButtonState()
    }
}
