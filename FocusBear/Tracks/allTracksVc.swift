//
//  allTracksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 12/01/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI

/// Hosts the SwiftUI Focus Music screen (FocusMusicView). Kept as an NSViewController — still
/// instantiated from the storyboard by identifier via getAllTracksVcObj() and slotted into
/// ViewController's containerView the same way every other screen is — but loadView() below
/// replaces the storyboard-loaded content entirely with an NSHostingView, per this repo's "new/
/// modified Mac UI is SwiftUI" convention.
class allTracksVc: NSViewController {

    let model = FocusMusicViewModel()

    /// Forwarded from the view model — other files (pause/resume-during-meetings, etc.) read this
    /// directly as allTracksVcObj?.currentSound.
    var currentSound: NSSound? { model.currentSound }

    override func loadView() {
        var descriptionText = "Here are some focus music tracks (some are binaural beats) you can use to help you focus. FYI the research is ambivalent about binaural beats - you'll likely get similar benefits from using your own music. Just make sure the music doesn't have lyrics otherwise you'll get distracted."
        var volumeLabelText = "Volume:"
        if let allTracksVcInfo = configjson.value(forKey: "allTracksVcInfo") as? NSDictionary {
            descriptionText = allTracksVcInfo.value(forKey: "title") as? String ?? descriptionText
            volumeLabelText = allTracksVcInfo.value(forKey: "titleVolumeText") as? String ?? volumeLabelText
        }

        var nowPlayingLabelText = "Now Playing"
        var sectionTitleSpotify = "Spotify"
        var sectionTitleYouTube = "YouTube Music"
        var sectionTitleLibrary = "Focus Music Library"
        var spotifyPlaceholder = "Paste a Spotify track/album/playlist link"
        var youtubePlaceholder = "Paste a YouTube Music link"
        var addButtonText = "Add"
        var youtubeHintText = "Add a music.youtube.com video or playlist link to play it here."
        var addOwnMusicButtonText = "Add my own music"
        if let focusMusicInfo = configjson.value(forKey: "focusMusicInfo") as? NSDictionary {
            nowPlayingLabelText = focusMusicInfo.value(forKey: "nowPlayingLabelText") as? String ?? nowPlayingLabelText
            sectionTitleSpotify = focusMusicInfo.value(forKey: "sectionTitleSpotify") as? String ?? sectionTitleSpotify
            sectionTitleYouTube = focusMusicInfo.value(forKey: "sectionTitleYouTubeMusic") as? String ?? sectionTitleYouTube
            sectionTitleLibrary = focusMusicInfo.value(forKey: "sectionTitleLibrary") as? String ?? sectionTitleLibrary
            spotifyPlaceholder = focusMusicInfo.value(forKey: "spotifyAddPlaceholder") as? String ?? spotifyPlaceholder
            youtubePlaceholder = focusMusicInfo.value(forKey: "youtubeAddPlaceholder") as? String ?? youtubePlaceholder
            addButtonText = focusMusicInfo.value(forKey: "addButtonText") as? String ?? addButtonText
            youtubeHintText = focusMusicInfo.value(forKey: "youtubeHintText") as? String ?? youtubeHintText
            addOwnMusicButtonText = focusMusicInfo.value(forKey: "addOwnMusicButtonText") as? String ?? addOwnMusicButtonText
        }

        let rootView = FocusMusicView(
            model: model,
            descriptionText: descriptionText,
            volumeLabelText: volumeLabelText,
            nowPlayingLabelText: nowPlayingLabelText,
            sectionTitleSpotify: sectionTitleSpotify,
            sectionTitleYouTube: sectionTitleYouTube,
            sectionTitleLibrary: sectionTitleLibrary,
            spotifyPlaceholder: spotifyPlaceholder,
            youtubePlaceholder: youtubePlaceholder,
            addButtonText: addButtonText,
            youtubeHintText: youtubeHintText,
            addOwnMusicButtonText: addOwnMusicButtonText
        )
        view = NSHostingView(rootView: rootView)
    }

    override func viewWillAppear() {
        model.refresh()
    }

    /// True while any focus music (local, Spotify or YouTube) is playing — see
    /// FocusMusicPromptManager, which skips the prompt/auto-start when music is already going.
    var isAnyMusicPlaying: Bool { model.isAnyMusicPlaying }

    /// Entry point for FocusMusicPromptManager's post-session-start auto-play. Bridges to the SwiftUI
    /// model (this VC no longer owns playback directly after the SwiftUI rewrite).
    func playLastPlayedOrRandomTrack() {
        model.playLastPlayedOrRandomTrack()
    }

    /// Stop the focus music the post-session-start prompt auto-started (focusModeData). The prompt only
    /// ever auto-plays a local library track, so this stops local playback — matching the pre-SwiftUI
    /// stopPlayback() that this bridges.
    func stopPlayback() {
        model.stopLocalTrack()
    }
}
