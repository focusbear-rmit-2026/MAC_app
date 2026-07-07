//
//  EveningShutdownScreen.swift
//  Focus Bear
//
//  The "well done — sleep / shut down" prompt shown at the bottom of the Day Plan once the evening
//  routine is done (#2005 part 4). SwiftUI, hosted in the Day Plan's stack via NSHostingView.
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
        VStack(spacing: 12) {
            Text("😴").font(.system(size: 34))
            Text(title).font(.headline).multilineTextAlignment(.center)
            Text(subtitle).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                SwiftUI.Button(action: onSleep) { Text(sleepLabel).frame(minWidth: 110) }
                    .keyboardShortcut(.defaultAction)
                SwiftUI.Button(action: onShutDown) { Text(shutDownLabel).frame(minWidth: 110) }
            }
            .controlSize(.large)
            SwiftUI.Button(action: onDismiss) { Text(notNowLabel).foregroundColor(.secondary) }
                .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

/// Builds the evening shutdown prompt with config-driven labels; each action dismisses it first, then
/// runs its power command.
func makeEveningShutdownView(onDismiss: @escaping () -> Void) -> EveningShutdownView {
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
    return EveningShutdownView(
        title: title, subtitle: subtitle,
        sleepLabel: sleepLabel, shutDownLabel: shutDownLabel, notNowLabel: notNowLabel,
        onSleep: { onDismiss(); sleepMac() },
        onShutDown: { onDismiss(); shutDownMac() },
        onDismiss: onDismiss)
}
