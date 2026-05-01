//
//  askOccupationVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/04/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class askOccupationVc: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var boxTextField: NSBox!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var textFieldOccupation: NSTextField!
    @IBOutlet weak var btnSkip: hoverUnderlineButton!

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
 
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var selectedIndex = -1
    var arrOccupations = [String]()
    var isStudentSelected = false
    var studentIndex = 0
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
        lblDescription.stringValue = "I’ll suggest which websites to block and which ones are productive."
        btnContinue.title = "That’s me!"

        btnSkip.title = "Skip"

        var occupationFreelancer = "Freelancer"
        var occupationStudent = "University student"
        var occupationBusinessOwner = "Business owner"
        var occupationEmployee = "Employee"
        var occupationOther = "Other"
        

        lblSubTitle.stringValue = "What type of work do you do?"
        arrOccupations = ["University student"," Software dev", "Graphic designer", "Business owner", "Other office work", "Field worker (not in front of computer)", "Parent (setting it up for child)", "Other"]

        
        if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = askOccupationVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            occupationStudent = askOccupationVcInfo.value(forKey: "occupationStudent") as? String ?? occupationStudent
            occupationBusinessOwner = askOccupationVcInfo.value(forKey: "occupationBusinessOwner") as? String ?? occupationBusinessOwner
            occupationEmployee = askOccupationVcInfo.value(forKey: "occupationEmployee") as? String ?? occupationEmployee
            occupationOther = askOccupationVcInfo.value(forKey: "occupationOther") as? String ?? occupationOther
            occupationFreelancer = askOccupationVcInfo.value(forKey: "occupationFreelancer") as? String ?? occupationFreelancer
            lblDescription.stringValue = askOccupationVcInfo.value(forKey: "descriptionNew") as? String ?? lblDescription.stringValue
            btnContinue.title = askOccupationVcInfo.value(forKey: "buttonContinue") as? String ?? btnContinue.title
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

        textFieldOccupation.textColor = .labelColor
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 1, progress: 0.35)
        
        
        textFieldOccupation.delegate = self
    }

    override func viewDidAppear() {
        // Show bubble
        
        var bubbleText = "Tell me your profession and I’ll find them all!"
        if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
            bubbleText = askOccupationVcInfo.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, horizontalOffset: 25, fontSize: 13)
        }
        showOnboardingBellIcon(view: self.view, screen: "ask-occupation-screen")
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @objc func viewDidResize(){
      
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "ask-occupation-screen-shown", metadata: [:])
        boxTextField.isHidden = true
        textFieldOccupation.stringValue = ""
        btnContinue.isEnabled = false
        viewDidResize()
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidResize), name: NSView.frameDidChangeNotification, object: self.view)
        selectedIndex = -1
        collectionView.deselectAll(self)
        collectionView.reloadData()
    }
    

    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
        NotificationCenter.default.removeObserver(self)// todo need to check everyehere
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldOccupation{
                checkContinueButtonState()
            }
        }
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] ask occupation view:- button Skip clicked.")
        allApiObject.capturePosthog(event: "ask-occupation-skipped", metadata: [:])
        getOnboardingVcObject().navigateToAllowedUrlsVc()
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        if selectedIndex == -1{
            return;
        }
        addLog(text: "[user-action] ask occupation view:- button continue clicked.")
        isStudentSelected = false
        var occupationToSave = ""
        let selectedIndexToSave = selectedIndex
        var occupationForRelevantSites = ""
        var posthogJson = [String : Any]()
        if selectedIndex == occupationStudentIndex{
            isStudentSelected = true
            var studentJson = [String : Any]()

            occupationForRelevantSites = "student"
            if !textFieldOccupation.stringValue.isEmpty{
                studentJson = ["University student": textFieldOccupation.stringValue]
                occupationToSave = "universityStudent_\(textFieldOccupation.stringValue)"
                occupationForRelevantSites = textFieldOccupation.stringValue
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
            occupationForRelevantSites = "business owner"
            var businessOwnerJson = [String : Any]()
            
            if !textFieldOccupation.stringValue.isEmpty{
                businessOwnerJson = ["Business owner": textFieldOccupation.stringValue]
                occupationToSave = "businessOwner_\(textFieldOccupation.stringValue)"
                occupationForRelevantSites = textFieldOccupation.stringValue
            }
            
            if businessOwnerJson.keys.isEmpty{
                posthogJson = [
                    "occupation": "Business owner"
                ]
                occupationToSave = "businessOwner"
            }else{
                posthogJson = [
                    "occupation": businessOwnerJson
                ]
            }
        }else if selectedIndex == occupationEmployeeIndex{
            var employeeJson = [String : Any]()
            occupationForRelevantSites = "employee"
            
            if !textFieldOccupation.stringValue.isEmpty{
                employeeJson = ["Employee": textFieldOccupation.stringValue]
                occupationToSave = "employee_\(textFieldOccupation.stringValue)"
                occupationForRelevantSites = textFieldOccupation.stringValue
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
            occupationForRelevantSites = "freelancer"
            
            if !textFieldOccupation.stringValue.isEmpty{
                freelancerJson = ["Freelancer": textFieldOccupation.stringValue]
                occupationToSave = "freelancer_\(textFieldOccupation.stringValue)"
                occupationForRelevantSites = textFieldOccupation.stringValue
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
            occupationForRelevantSites = "other"
            if !textFieldOccupation.stringValue.isEmpty{
                posthogJson = [
                    "occupation": textFieldOccupation.stringValue
                ]
                occupationToSave = "other_\(textFieldOccupation.stringValue)"
                
                occupationForRelevantSites = textFieldOccupation.stringValue
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

        
        loader.startAnimation(self)
        btnSkip.isEnabled = false
        btnContinue.isEnabled = false
        textFieldOccupation.isEnabled = false
        allApiObject.generateOccupationRelevantSites(userOccupation: occupationForRelevantSites, completionHandler: {result in
            if let result = result{
                print(result)
                occupationSpecificRelevantSitesForFocusMode = result
            }
            DispatchQueue.main.async{ [self] in
                loader.stopAnimation(self)
                btnSkip.isEnabled = true
                btnContinue.isEnabled = true
                textFieldOccupation.isEnabled = true
                getOnboardingVcObject().navigateToAllowedUrlsVc()
            }
        })
    }
    
    func checkContinueButtonState(){
        if selectedIndex == -1{
            btnContinue.isEnabled = false
            return;
        }
        btnContinue.isEnabled = true
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
            var placeHolder = ""
            if selectedIndex == occupationStudentIndex{
                var studentInfoText = "FYI your university might be able to pay for premium access to Focus Bear. Email support@focusbear.io for details."
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    studentInfoText = askOccupationVcInfo.value(forKey: "studentInfoText") as? String ?? studentInfoText
                }
                guard let item = collectionView.item(at: indexPath) as? collectionViewItemOccupation else {
                    showTooltip(sender: collectionView, msg: studentInfoText, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
                    return
                }
                showTooltip(sender: item.view, msg: studentInfoText, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
                placeHolder = "What do you study?"
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    placeHolder = askOccupationVcInfo.value(forKey: "placeHolderStudy") as? String ?? placeHolder
                }
            }else if selectedIndex == occupationBusinessOwnerIndex{
                placeHolder = "What kind of business do you run?"
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    placeHolder = askOccupationVcInfo.value(forKey: "placeHolderBusinessOwner") as? String ?? placeHolder
                }
            }else if selectedIndex == occupationEmployeeIndex{
                placeHolder = "What do you do for work?"
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    placeHolder = askOccupationVcInfo.value(forKey: "placeHolderEmployee") as? String ?? placeHolder
                }
            }else if selectedIndex == occupationFreelancerIndex{
                placeHolder = "What kind of work do you do as a freelancer?"
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    placeHolder = askOccupationVcInfo.value(forKey: "placeHolderFreelancer") as? String ?? placeHolder
                }
            }else if selectedIndex == occupationOtherIndex{
                placeHolder = "What do you spend most of your time on?"
                if let askOccupationVcInfo = configjson.value(forKey: "askOccupationVcInfo") as? NSDictionary{
                    placeHolder = askOccupationVcInfo.value(forKey: "placeHolderOther") as? String ?? placeHolder
                }           }
            
            boxTextField.isHidden = false
            textFieldOccupation.setFocus()
            
            checkContinueButtonState()
            
            textFieldOccupation.placeholderString = placeHolder
        }
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        checkContinueButtonState()
    }
}
