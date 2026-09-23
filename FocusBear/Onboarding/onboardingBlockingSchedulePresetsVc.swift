//
//  onboardingBlockingSchedulePresetsVc.swift
//  Focus Bear
//
//  Onboarding step shown between "Do you want a blocking schedule?" (_ASK_CREATE_BLOCKING_SCHEDULE_)
//  and the editor (_CREATE_BLOCKING_SCHEDULE_). Presents the same Quick-Start Presets grid the running
//  app offers when adding a schedule (BlockingSchedulePresetsView), inside the onboarding chrome
//  (progress bar, title, bear + bubble, global back button). Picking a preset records it on onboardingVc
//  for createFirstBlockingScheduleVc to pre-fill the editor; "Custom Schedule" advances with a blank one.
//

import Cocoa
import SwiftUI

class onboardingBlockingSchedulePresetsVc: NSViewController {

    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var imgViewBear: NSImageView!

    var bubbleView: BubbleView?
    var distractionBlockingProgressVcObj: distractionBlockingProgressVc?

    override func viewDidLoad() {
        super.viewDidLoad()

        lblTitle.stringValue = "Quick-Start Presets"
        // Tapping a preset tile (incl. "Custom Schedule") already advances, so the storyboard's Continue
        // button is unused here — hide it.
        btnContinue.isHidden = true

        // Sub-heading under the title. Same font as confirmBlockingScheduleCreationVc.lblSubTitle
        // (storyboard: metaFont "system", size 15).
        var subtitleText = "Pick a template to start with — you can fine-tune it on the next screen."
        if let info = configjson.value(forKey: "createFirstBlockingScheduleVcInfo") as? NSDictionary {
            lblTitle.stringValue = info.value(forKey: "presetsTitle") as? String ?? lblTitle.stringValue
            subtitleText = info.value(forKey: "presetsSubtitle") as? String ?? subtitleText
        }
        let subtitle = NSTextField(labelWithString: subtitleText)
        subtitle.font = NSFont.systemFont(ofSize: 15)
        subtitle.textColor = .labelColor
        subtitle.alignment = .center
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitle)
        NSLayoutConstraint.activate([
            subtitle.centerXAnchor.constraint(equalTo: lblTitle.centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 20),
        ])

        // Same progress bar as the other blocking-schedule onboarding screens (checkmark → SET SCHEDULE → lock).
        customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 2, progress: 0.30)
        
        // Host the quick-start presets grid (same as the running app), with its own header hidden — the
        // onboarding chrome (title, progress, global back) already covers that. Picking a preset records
        // it for createFirstBlockingScheduleVc and advances to the editor; "Custom Schedule" advances blank.
        if #available(macOS 11.0, *) {
            let root = BlockingSchedulePresetsView(
                onPick: { preset in
                    getOnboardingVcObject().chosenSchedulePreset = preset.isCustom ? nil : preset
                    getOnboardingVcObject().navigate(to: ._CREATE_BLOCKING_SCHEDULE_)
                },
                onBack: {},                 // onboarding's global back button handles going back
                showHeader: false)
            let hosting = NSHostingView(rootView: root)
            hosting.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(hosting)
            containerView.addConstraints(subView: hosting)
        }
    }

    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "blocking-schedule-presets-screen-shown", metadata: [:])
    }

    func getDistractionBlockingProgressVcObj() -> distractionBlockingProgressVc {
        if distractionBlockingProgressVcObj == nil {
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        // The presets grid is SwiftUI (macOS 11+); on older systems there's nothing to show, so skip
        // straight to the editor rather than stranding the user on a blank screen.
        if #available(macOS 11.0, *) {} else {
            getOnboardingVcObject().navigate(to: ._CREATE_BLOCKING_SCHEDULE_)
        }

        // Show bubble
        var bubbleText = "For example, block distracting websites during work hours"
        if let info = configjson.value(forKey: "createFirstBlockingScheduleVcInfo") as? NSDictionary {
            bubbleText = info.value(forKey: "bubbleText") as? String ?? bubbleText
        }

        if bubbleView == nil {
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: 20, horizontalOffset: 25, fontSize: 13)
        }
    }

    @IBAction func btnContinueClicked(_ sender: Any) {
        // Currently unreachable: the Continue button is hidden (its stackView is hidden in the storyboard),
        // since tapping a preset tile — incl. "Custom Schedule" — already advances. Kept wired in case the
        // button is shown again: proceed without a preset → a blank editor (same as the Custom tile).
        getOnboardingVcObject().chosenSchedulePreset = nil
        getOnboardingVcObject().navigate(to: ._CREATE_BLOCKING_SCHEDULE_)
    }
}
