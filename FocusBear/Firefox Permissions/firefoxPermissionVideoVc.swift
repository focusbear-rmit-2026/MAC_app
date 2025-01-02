//
//  firefoxPermissionVideoVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import AVKit

class firefoxPermissionVideoVc: NSViewController {

    @IBOutlet weak var avPlayerView: AVPlayerView!
    var videoPlayer:AVPlayer?
    var playerItem: AVPlayerItem?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        
    }
    
    override func viewWillAppear() {
        let videoURL: URL = Bundle.main.url(forResource: "FB-Firefox", withExtension: "mov")!
        videoPlayer = AVPlayer(playerItem: nil)
        avPlayerView.player = videoPlayer
        let avAsset = AVURLAsset(url: videoURL)
        playerItem = AVPlayerItem(asset: avAsset)
        videoPlayer?.replaceCurrentItem(with: playerItem)
        videoPlayer?.play()
    }
    override func viewWillDisappear() {
        videoPlayer?.pause()
        videoPlayer = nil
    }
}
