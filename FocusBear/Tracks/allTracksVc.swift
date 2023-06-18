//
//  allTracksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import AVFoundation

class allTracksVc: NSViewController {

    @IBOutlet weak var lblTitleVolume: NSTextField!
    @IBOutlet weak var sliderVolume: NSSlider!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    
    var currentSound:NSSound?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleVolume.stringValue = "Volume:"
        lblTitle.stringValue = "Here are some focus music tracks (some are binaural beats) you can use to help you focus. FYI the research is ambivalent about binaural beats - you'll likely get similar benefits from using your own music. Just make sure the music doesn't have lyrics otherwise you'll get distracted."
        if let allTracksVcInfo = configjson.value(forKey: "allTracksVcInfo") as? NSDictionary{
            lblTitle.stringValue = allTracksVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblTitleVolume.stringValue = allTracksVcInfo.value(forKey: "titleVolumeText") as? String ?? lblTitleVolume.stringValue
        }
        
        
    }
    
    override func viewWillAppear() {
        tblView.reloadData()
        
        for i in 0..<arrAllTracks.count{
            if arrAllTracks[i]["isPlaying"] as? Bool == true{
                tblView.selectRowIndexes(IndexSet(integer: i), byExtendingSelection: false)
                break;
            }
        }
        
    }
    @IBAction func sliderVolumeClicked(_ sender: Any) {
        if currentSound != nil{
            currentSound?.volume = sliderVolume.floatValue
        }
    }
}
extension allTracksVc: NSTableViewDelegate, NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrAllTracks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellTracks"), owner: nil) as? tblCellTracks {
            
            
            if row >= arrAllTracks.count{
                return cell
            }
            cell.lblTitle.stringValue = arrAllTracks[row]["name"] as? String ?? ""
            
            
            let description = arrAllTracks[row]["description"] as? String ?? ""
            let artist = arrAllTracks[row]["artist"] as? String ?? ""
            
            if artist.isEmpty{
                cell.lblArtist.stringValue = description
            }else{
                if description.isEmpty{
                    cell.lblArtist.stringValue = artist
                }else{
                    cell.lblArtist.stringValue = artist + "-" + description
                }
            }
           
            
//            let filePath = arrAllTracks[row]["url"] as? String ?? ""
            let thumbnailLocalUrl = arrAllTracks[row]["thumbnailLocalUrl"] as? String ?? ""
            cell.imgview.image = NSImage(byReferencingFile: thumbnailLocalUrl)//NSImage(byReferencing: URL(fileURLWithPath: arrAllTracks[row]["url"] as? String ?? ""))//
            
            //            var isFileDownloading = arrAllTracks[row]["isFileDownloading"] as? Bool ?? false
            let isFileDownloded = arrAllTracks[row]["isFileDownloded"] as? Bool ?? false
            
            if !isFileDownloded{
                cell.btnPlay.isHidden = true
            }else{
                cell.btnPlay.isHidden = false
            }
          
            let isPlaying = arrAllTracks[row]["isPlaying"] as? Bool ?? false
            let isPaused = arrAllTracks[row]["isPaused"] as? Bool ?? false
            if isPlaying{
                cell.imgview.image = #imageLiteral(resourceName: "audio Wave")
                if #available(macOS 11.0, *) {
                    cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
                    cell.btnPlay.image = NSImage(systemSymbolName: "stop.circle.fill", accessibilityDescription: nil)
                } else {
                    cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyDown
                    cell.btnPlay.image = NSImage(named: NSImage.touchBarRecordStopTemplateName)
                }
            }else{
                if isPaused{
                    if #available(macOS 11.0, *) {
                        cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
                        cell.btnPlay.image = NSImage(systemSymbolName: "stop.circle.fill", accessibilityDescription: nil)
                    } else {
                        cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyDown
                        cell.btnPlay.image = NSImage(named: NSImage.touchBarRecordStopTemplateName)
                    }
                }else{
                    if #available(macOS 11.0, *) {
                        cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
                        cell.btnPlay.image = NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: nil)
                    } else {
                        cell.btnPlay.imageScaling = NSImageScaling.scaleProportionallyDown
                        cell.btnPlay.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    }
                }
                
            }
            
            
            if arrAllTracks[row]["isFileDownloading"] as? Bool == true{
                cell.loader.startAnimation(self)
                cell.loader.isHidden = false
                cell.btnDownload.isHidden = true
            }else{
                cell.loader.stopAnimation(self)
                cell.loader.isHidden = true
                
                if !isFileDownloded{
                    cell.btnDownload.isHidden = false
                }else{
                    cell.btnDownload.isHidden = true
                }
            }
            
            cell.btnPlay.target = self
            cell.btnPlay.tag = row
            cell.btnPlay.action = #selector(btnPlayClicked(sender:))
            
            cell.btnDownload.target = self
            cell.btnDownload.tag = row
            cell.btnDownload.action = #selector(btnDownloadClicked(sender:))
            
            
            
            if let duration = arrAllTracks[row]["duration"] as? Int{
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: duration)
                var stringTime: String = ""
                
                stringTime = "\(h)" + hoursHText
                
                
                if stringTime.isEmpty{
                    stringTime = "\(m)" + minutesMText
                }else{
                    stringTime += " \(m)" + minutesMText
                }
                
                
                if stringTime.isEmpty{
                    stringTime = "\(s)" + secondsSText
                }else{
                    stringTime += " \(s)" + secondsSText
                }
                
                cell.lblDuration.stringValue = stringTime
            }else{
                cell.lblDuration.stringValue = ""
            }
            
//            if let duration = arrAllTracks[row]["duration"] as? String{
//                cell.lblDuration.stringValue = duration
//            }else{
//                let audioAsset = AVURLAsset.init(url: URL(fileURLWithPath: filePath), options: nil)
//                let duration = audioAsset.duration
//                let durationInSeconds = CMTimeGetSeconds(duration)
//                let stringTime: String = getStringTimeFromSeconds(seconds: Int(durationInSeconds))
//                arrAllTracks[row]["duration"] = stringTime
//                cell.lblDuration.stringValue = stringTime
//            }
            
            
            
            
            return cell
        }
        return NSTableCellView()
    }
 
    @objc func btnPlayClicked(sender:NSButton){
        let track = arrAllTracks[sender.tag]
        let isPlaying = track["isPlaying"] as? Bool ?? false
        let localUrlString = track["url"] as? String ?? ""
        let isPaused = track["isPaused"] as? Bool ?? false
        
        if isPlaying || isPaused{
            currentSound?.stop()
            currentSound = nil
            for i in 0..<arrAllTracks.count{
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = false
            }
        }else{
            for i in 0..<arrAllTracks.count{
                //if arrAllTracks[i]["isPlaying"] as? Bool == true{
                    arrAllTracks[i]["isPlaying"] = false
                    arrAllTracks[i]["isPaused"] = false
                    currentSound?.stop()
                    currentSound = nil
                //}
            }
            
            arrAllTracks[sender.tag]["isPlaying"] = true
            currentSound = NSSound(contentsOfFile: localUrlString, byReference: true)
            currentSound?.play()
            currentSound?.volume = sliderVolume.floatValue
            currentSound?.delegate = self
        }
        tblView.reloadData()
        tblView.selectRowIndexes(IndexSet(integer: sender.tag), byExtendingSelection: false)
    }
    
    @objc func btnDownloadClicked(sender:NSButton){
        let senderTag = sender.tag
        arrAllTracks[senderTag]["isFileDownloading"] = true
        tblView.reloadData()
        let track = arrAllTracks[senderTag]

        let localUrlString = track["url"] as? String ?? ""
        let localUrl = URL(fileURLWithPath: localUrlString)
        let download_urlString = track["download_url"] as? String ?? ""
        let download_url = URL(string: download_urlString)//URL(fileURLWithPath: download_urlString)

        let thumbnailLocalUrlString = track["thumbnailLocalUrl"] as? String ?? ""
        let thumbnailLocalUrl = URL(fileURLWithPath: thumbnailLocalUrlString)
        let thumbnail_download_urlString = track["thumbnail_download_url"] as? String ?? ""
        let thumbnail_download_url = URL(string: thumbnail_download_urlString)//URL(fileURLWithPath: download_urlString)
        
        if !FileManager.default.fileExists(atPath: thumbnailLocalUrlString){
            allApiObject.downloadFileAsync(url: thumbnail_download_url, destinationUrl: thumbnailLocalUrl){ (success, error) in
                
                DispatchQueue.main.async {
                    self.tblView.reloadData()
                }
            }
            
        }
        
        
        allApiObject.downloadFileAsync(url: download_url, destinationUrl: localUrl){ (success, error) in
            print(success as Any)
            DispatchQueue.main.async {
                arrAllTracks[senderTag]["isFileDownloading"] = false
                
                if FileManager.default.fileExists(atPath: localUrl.path){
                    arrAllTracks[senderTag]["isFileDownloded"] = true
                }else{
                    arrAllTracks[senderTag]["isFileDownloded"] = false
                }
                UserDefaults.standard.set(arrAllTracks, forKey: kUserdefaultsAllTracks)
                self.tblView.reloadData()
            }

        }
        
    }
    
}



extension allTracksVc:NSSoundDelegate{
    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        for i in 0..<arrAllTracks.count{
            if arrAllTracks[i]["isPlaying"] as? Bool == true{
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = false
            }
        }
        currentSound = nil
        tblView.reloadData()
    }
}
