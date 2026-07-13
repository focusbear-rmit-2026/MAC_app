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
                // Sleep = primary (orange) app button; Shut Down = secondary. Both borderless.
                SwiftUI.Button(action: onSleep) { Text(sleepLabel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false))
                    .keyboardShortcut(.defaultAction)
                SwiftUI.Button(action: onShutDown) { Text(shutDownLabel) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true))
            }
            // "Not now" = underlined text button.
            SwiftUI.Button(action: onDismiss) {
                Text(notNowLabel).underline().foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .pointingHandCursor()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
    }
}

/// SwiftUI mirror of the AppKit `Button` app style (Buttons.swift): orange fill + white text for the
/// primary action, white fill + gray border + black text for the secondary. Borderless (no system
/// push-button bezel), rounded, with the pointing-hand cursor on hover. Kept in SwiftUI (not the
/// storyboard-only AppKit Button class) so NSHostingView screens can use it — the evening shutdown
/// prompt and the Focus Button tool tab (ViewController.swift).
struct AppOrangeButtonStyle: ButtonStyle {
    let secondary: Bool
    /// Optional fixed button height; nil keeps the natural padding-based height. The Focus Button tab
    /// passes 33; the evening shutdown prompt leaves it nil.
    var height: CGFloat? = nil

    private var orange: Color { Color(NSColor(named: "dark_OrangeColor") ?? NSColor.systemOrange) }
    private var lightOrange: Color { Color(NSColor(named: "light_OrangeColor") ?? NSColor.systemOrange) }

    func makeBody(configuration: Configuration) -> some View {
        let bg: Color
        let fg: Color
        let border: Color
        if secondary {
            bg = configuration.isPressed ? lightOrange : Color.white
            fg = .black
            border = Color(red: 220/255, green: 220/255, blue: 220/255)   // matches Button.grayBorderColor
        } else {
            bg = configuration.isPressed ? orange.opacity(0.7) : orange
            fg = .white
            border = orange
        }
        return configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(fg)
            .frame(minWidth: 110, minHeight: height, maxHeight: height)
            .padding(.vertical, height == nil ? 9 : 0)
            .padding(.horizontal, 18)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(border, lineWidth: 1))
            .contentShape(Rectangle())
            .pointingHandCursor()
    }
}

// Uses the app's existing `pointingHandCursor()` View modifier (BlockingScheduleStore.swift) for the
// hover cursor, so behaviour matches other custom buttons.

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
