//
//  breakurveyVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/07/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class breakSurveyVc: NSViewController {

    @IBOutlet weak var btnSkip: underLineButton!
    @IBOutlet weak var textFieldFeedback: NSTextField!
    @IBOutlet weak var btnBackToWork: Button!
    @IBOutlet weak var lblQuestionFirst: NSTextField!
    @IBOutlet weak var lblQuestionSecond: NSTextField!
    @IBOutlet weak var lblQuestionThird: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    
    @IBOutlet weak var btnFirstQuestionStarFirst: cursorButton!
    @IBOutlet weak var btnFirstQuestionStarSecond: cursorButton!
    @IBOutlet weak var btnFirstQuestionStarThird: cursorButton!
    @IBOutlet weak var btnFirstQuestionStarFourth: cursorButton!
    @IBOutlet weak var btnFirstQuestionStarFifth: cursorButton!
    
    @IBOutlet weak var btnSecondQuestionStarFirst: cursorButton!
    @IBOutlet weak var btnSecondQuestionStarSecond: cursorButton!
    @IBOutlet weak var btnSecondQuestionStarThird: cursorButton!
    @IBOutlet weak var btnSecondQuestionStarFourth: cursorButton!
    @IBOutlet weak var btnSecondQuestionStarFifth: cursorButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "How was the break?"
        lblQuestionFirst.stringValue = "How refreshed do you feel?"
        lblQuestionSecond.stringValue = "Did the break come at the right time?"
        lblQuestionThird.stringValue = "Any other feedback?"
        btnBackToWork.title = "Back to work!"
        btnSkip.title = "Skip"
        
        if let breakSurveyVcInfo = configjson.value(forKey: "breakSurveyVcInfo") as? NSDictionary{
            lblTitle.stringValue = breakSurveyVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblQuestionFirst.stringValue = breakSurveyVcInfo.value(forKey: "questionFirstText") as? String ?? lblQuestionFirst.stringValue
            lblQuestionSecond.stringValue = breakSurveyVcInfo.value(forKey: "questionSecondText") as? String ?? lblQuestionSecond.stringValue
            lblQuestionThird.stringValue = breakSurveyVcInfo.value(forKey: "questionThirdText") as? String ?? lblQuestionThird.stringValue
            btnBackToWork.title = breakSurveyVcInfo.value(forKey: "buttonContinueText") as? String ?? btnBackToWork.title
            btnSkip.title = breakSurveyVcInfo.value(forKey: "buttonSkipText") as? String ?? btnSkip.title
        }
        
    }
    override func viewWillAppear() {
        currentRatingCountFirstQuestion = 0
        currentRatingCountSecondQuestion = 0
        textFieldFeedback.stringValue = ""
        updateStarRatingView()
    }
    @IBAction func btnBackToWorkClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "break-feedback-left", metadata: ["how-refreshed":currentRatingCountFirstQuestion, "breaking-timing":currentRatingCountSecondQuestion, "other-feedback":textFieldFeedback.stringValue])
        self.view.window?.close()
    }
    @IBAction func btnSkipClicked(_ sender: Any) {
        self.view.window?.close()
    }
    
    var currentRatingCountFirstQuestion = 0
    var currentRatingCountSecondQuestion = 0
    func updateStarRatingView(){
        btnFirstQuestionStarFirst.image = NSImage(named: "star_Gray")
        btnFirstQuestionStarSecond.image = NSImage(named: "star_Gray")
        btnFirstQuestionStarThird.image = NSImage(named: "star_Gray")
        btnFirstQuestionStarFourth.image = NSImage(named: "star_Gray")
        btnFirstQuestionStarFifth.image = NSImage(named: "star_Gray")
        
        btnSecondQuestionStarFirst.image = NSImage(named: "star_Gray")
        btnSecondQuestionStarSecond.image = NSImage(named: "star_Gray")
        btnSecondQuestionStarThird.image = NSImage(named: "star_Gray")
        btnSecondQuestionStarFourth.image = NSImage(named: "star_Gray")
        btnSecondQuestionStarFifth.image = NSImage(named: "star_Gray")
        
       
        if currentRatingCountFirstQuestion == 1{
            btnFirstQuestionStarFirst.image = NSImage(named: "star_Golden")
        }else if currentRatingCountFirstQuestion == 2{
            btnFirstQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarSecond.image = NSImage(named: "star_Golden")
        }else if currentRatingCountFirstQuestion == 3{
            btnFirstQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarThird.image = NSImage(named: "star_Golden")
        }else if currentRatingCountFirstQuestion == 4{
            btnFirstQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarThird.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarFourth.image = NSImage(named: "star_Golden")
        }else if currentRatingCountFirstQuestion == 5{
            btnFirstQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarThird.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarFourth.image = NSImage(named: "star_Golden")
            btnFirstQuestionStarFifth.image = NSImage(named: "star_Golden")
        }
        
        if currentRatingCountSecondQuestion == 1{
            btnSecondQuestionStarFirst.image = NSImage(named: "star_Golden")
        }else if currentRatingCountSecondQuestion == 2{
            btnSecondQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarSecond.image = NSImage(named: "star_Golden")
        }else if currentRatingCountSecondQuestion == 3{
            btnSecondQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarThird.image = NSImage(named: "star_Golden")
        }else if currentRatingCountSecondQuestion == 4{
            btnSecondQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarThird.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarFourth.image = NSImage(named: "star_Golden")
        }else if currentRatingCountSecondQuestion == 5{
            btnSecondQuestionStarFirst.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarSecond.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarThird.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarFourth.image = NSImage(named: "star_Golden")
            btnSecondQuestionStarFifth.image = NSImage(named: "star_Golden")
        }
        
        if currentRatingCountFirstQuestion == 0 && currentRatingCountSecondQuestion == 0{
            btnBackToWork.isEnabled = false
        }else{
            btnBackToWork.isEnabled = true
        }
    }
    
    @IBAction func btnFirstQuestionStarFirstClicked(_ sender: Any) {
        currentRatingCountFirstQuestion = 1
        updateStarRatingView()
    }
    
    @IBAction func btnFirstQuestionStarSecondClicked(_ sender: Any) {
        currentRatingCountFirstQuestion = 2
        updateStarRatingView()
    }
    
    @IBAction func btnFirstQuestionStarThirdClicked(_ sender: Any) {
        currentRatingCountFirstQuestion = 3
        updateStarRatingView()
    }
    
    @IBAction func btnFirstQuestionStarFourthClicked(_ sender: Any) {
        currentRatingCountFirstQuestion = 4
        updateStarRatingView()
    }
    
    @IBAction func btnFirstQuestionStarFifthClicked(_ sender: Any) {
        currentRatingCountFirstQuestion = 5
        updateStarRatingView()
    }
 
    @IBAction func btnSecondQuestionStarFirstClicked(_ sender: Any) {
        currentRatingCountSecondQuestion = 1
        updateStarRatingView()
    }
    
    @IBAction func btnSecondQuestionStarSecondClicked(_ sender: Any) {
        currentRatingCountSecondQuestion = 2
        updateStarRatingView()
    }
    
    @IBAction func btnSecondQuestionStarThirdClicked(_ sender: Any) {
        currentRatingCountSecondQuestion = 3
        updateStarRatingView()
    }
    
    @IBAction func btnSecondQuestionStarFourthClicked(_ sender: Any) {
        currentRatingCountSecondQuestion = 4
        updateStarRatingView()
    }
    
    @IBAction func btnSecondQuestionStarFifthClicked(_ sender: Any) {
        currentRatingCountSecondQuestion = 5
        updateStarRatingView()
    }
}
