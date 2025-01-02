//
//  askOnboardingVideoVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class askOnboardingVideoVc: NSViewController {// not in use

    @IBOutlet weak var bgBoxHeight: NSLayoutConstraint!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnPlayVideo: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnNoThanks: underLineButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        imgView.wantsLayer = true
        imgView.layer?.cornerRadius = 3
        lblTitle.stringValue = "Your account's ready to go!"
        lblSubTitle.stringValue = "Here's a short video that explains how to use Focus Bear."// "Aquí tienes un breve vídeo que explica cómo utilizar Focus Bear."
        btnPlayVideo.title = "Play the video"
        btnNoThanks.title = "No thanks"
        
        if let askOnboardingVideoVcInfo = configjson.value(forKey: "askOnboardingVideoVcInfo") as? NSDictionary{
            lblTitle.stringValue = askOnboardingVideoVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = askOnboardingVideoVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnPlayVideo.title = askOnboardingVideoVcInfo.value(forKey: "buttonPlayText") as? String ?? btnPlayVideo.title
            btnNoThanks.title = askOnboardingVideoVcInfo.value(forKey: "buttonNoThanksText") as? String ?? btnNoThanks.title
        }
        
    }
    override func viewWillAppear() {
        appdelegate!.statusbutton?.action = #selector(appdelegate!.showAlertOnboardingVideo)//
    }
    func closeWindow(){
        if webView.isHidden == false{ // onboarding view is lodded
            let link = URL(string:"about:blank")!
            let request = URLRequest(url: link)
            self.webView.load(request)
            let secondsBetween = Date().timeIntervalSince(onboardingVideoStartTime ?? Date())
            allApiObject.capturePosthog(event: "onboarding-video-watched", metadata: ["watched_duration_seconds":Int(secondsBetween)])
        }
        self.view.window?.close()
        appdelegate!.loadCredentialsAndDeviceId() // not in use 
        appdelegate!.statusbutton?.action = nil
        showMenuTourWindow()
    }
    @IBAction func btnPlayVideoClicked(_ sender: Any) {
        if webView.isHidden == false{
            addLog(text:"onboarding video - btn Continue clicked")
            closeWindow()
            return;
        }
        
        playVideo()
    }
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        addLog(text:"onboarding video - btn No thanks clicked")
        closeWindow()
    }
    @IBAction func btnPlaySmallClicked(_ sender: Any) {
        playVideo()
    }
    
    func playVideo(){
        bgBoxHeight.constant = 900
        btnNoThanks.isHidden = true
        btnPlayVideo.title = "Continue"
        if let askOnboardingVideoVcInfo = configjson.value(forKey: "askOnboardingVideoVcInfo") as? NSDictionary{
            btnPlayVideo.title = askOnboardingVideoVcInfo.value(forKey: "buttonContinueText") as? String ?? btnPlayVideo.title
        }
        onboardingVideoStartTime = Date()
        webView.isHidden = false
        var videoUrl = "https://www.youtube.com/watch?v=TvfNJ1AaT9M"
        
        if let welcomeInfo = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            videoUrl = welcomeInfo.value(forKey: "welcomeVideoUrl") as? String ?? videoUrl
        }
        if videoUrl.lowercased().contains("watch?v="){
            videoUrl = videoUrl.replacingOccurrences(of: "watch?v=", with: "embed/")
        }else{
            
            if videoUrl.lowercased().contains("https://youtu.be/"){
                //https://www.youtube.com/watch?v=lExuhKRS8vo
                if let lastItem =  videoUrl.components(separatedBy: "/").last{
                    videoUrl = "https://www.youtube.com/embed/" + lastItem
                }
                
            }
        }
        if videoUrl.contains("?"){
            videoUrl = videoUrl + "&autoplay=1"
        }else{
            videoUrl = videoUrl + "?autoplay=1"
        }
        let link = URL(string:videoUrl)!
        let request = URLRequest(url: link)
        self.webView.load(request)
        self.view.window?.center()
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.view.window?.center()
            }
        }
    }
}
