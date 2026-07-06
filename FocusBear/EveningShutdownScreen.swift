//
//  EveningShutdownScreen.swift
//  Focus Bear
//
//  Shown after the evening routine finishes (from the focus summary): a friendly "well done" screen
//  that lets the user shut down or sleep the Mac, instead of an automatic shut-off. New UI is SwiftUI
//  (hosted in a programmatic NSViewController) per the app's SwiftUI-only rule for new/modified UI.
//

import SwiftUI
import AppKit

struct EveningShutdownView: View {
    let title: String
    let subtitle: String
    let sleepLabel: String
    let shutDownLabel: String
    let notNowLabel: String
    let onSleep: () -> Void
    let onShutDown: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Text("😴").font(.system(size: 56))
            Text(title)
                .font(.title).fontWeight(.semibold)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.title3).foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button(action: onSleep) {
                    Text(sleepLabel).frame(minWidth: 130)
                }
                .keyboardShortcut(.defaultAction)

                Button(action: onShutDown) {
                    Text(shutDownLabel).frame(minWidth: 130)
                }
            }
            .controlSize(.large)
            .padding(.top, 8)

            Button(action: onDismiss) {
                Text(notNowLabel).foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(48)
        .frame(minWidth: 480, minHeight: 360)
    }
}

/// Hosts EveningShutdownView; each action dismisses this screen first, then runs the power command.
final class eveningShutdownVc: NSViewController {

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 380))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var title = "Well done on finishing your evening routine"
        var subtitle = "Have a restful sleep"
        var sleepLabel = "Sleep"
        var shutDownLabel = "Shut Down"
        var notNowLabel = "Not now"
        if let info = configjson.value(forKey: "eveningShutdownInfo") as? NSDictionary {
            title = info.value(forKey: "title") as? String ?? title
            subtitle = info.value(forKey: "subtitle") as? String ?? subtitle
            sleepLabel = info.value(forKey: "buttonSleepText") as? String ?? sleepLabel
            shutDownLabel = info.value(forKey: "buttonShutDownText") as? String ?? shutDownLabel
            notNowLabel = info.value(forKey: "buttonNotNowText") as? String ?? notNowLabel
        }

        let root = EveningShutdownView(
            title: title, subtitle: subtitle,
            sleepLabel: sleepLabel, shutDownLabel: shutDownLabel, notNowLabel: notNowLabel,
            onSleep: { [weak self] in self?.dismiss(nil); sleepMac() },
            onShutDown: { [weak self] in self?.dismiss(nil); shutDownMac() },
            onDismiss: { [weak self] in self?.dismiss(nil) }
        )
        let hosting = NSHostingView(rootView: root)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

/// Present the evening "well done / sleep / shut down" screen after the evening routine finishes.
func showEveningShutdownScreen() {
    let vc = eveningShutdownVc()
    if let presenter = mainViewControllerObj {
        presenter.presentAsModalWindow(vc)
    } else {
        mainWindowControllerObj?.window?.contentViewController = vc
        mainWindowControllerObj?.showWindow(nil)
    }
}
