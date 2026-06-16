//
//  BreakWarningView.swift
//  Focus Bear
//
//  SwiftUI conversion of the break-reminder popup (#1590). Driven by a view-model the
//  AppKit controller (breakWarningVc) updates from the existing break timer / postpone
//  logic. Adds the "friction to postpone" from the issue comments: postponing requires
//  pressing and HOLDING the postpone button, and the required hold time escalates with
//  each consecutive postpone (5s → 10s → 15s, capped at 15s).
//
//  Styling matches the rest of the app: the app background colour ("backgroundColor")
//  and the user's selected app font (via getBold/SemiBold/Regular/MediumFont).
//

import SwiftUI

/// State + callbacks for the SwiftUI break-warning popup. Owned by breakWarningVc.
final class BreakWarningViewModel: ObservableObject {
    @Published var title = ""
    @Published var quote = ""
    @Published var timeSinceLastBreak = ""
    @Published var showTimeSinceLastBreak = false
    @Published var timerText = ""
    @Published var countdownProgress: Double = 1      // 1 → 0 as the auto-start countdown elapses
    @Published var minutesOptions: [String] = ["5", "10", "15", "20", "25", "30", "45", "60", "90"]
    @Published var selectedMinutes = "25"
    /// Seconds the user must hold the postpone button. 0 == no hold (easy-skip).
    @Published var requiredHoldSeconds: Double = 5
    /// 0…1 escalation used to tint the UI as time-without-a-break grows.
    @Published var urgency: Double = 0

    @Published var startTitle = "Start micro break now"
    @Published var skipTitle = "Skip"
    @Published var postponeTitle = "Postpone"
    @Published var selectMinutesTitle = "Select minutes to postpone:"

    var onStartBreak: () -> Void = {}
    var onSkip: () -> Void = {}
    var onPostpone: () -> Void = {}
    /// Called as the user presses/releases the postpone hold control, so the controller
    /// can pause/resume the auto-start countdown while a hold is in progress.
    var onPostponePressing: (Bool) -> Void = { _ in }
}

private let breakAccent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)
// App-font bridges (honours the user's selected font; falls back to system).
private func appBold(_ size: CGFloat) -> Font { Font(getBoldFont(size: size)) }
private func appSemiBold(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }
private func appRegular(_ size: CGFloat) -> Font { Font(getRegularFont(size: size)) }
private func appMedium(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }

struct BreakWarningView: View {
    @ObservedObject var model: BreakWarningViewModel

    /// Urgency colour: amber → red as the user goes longer without a break.
    private var urgencyColor: Color {
        Color(red: 0.86 + 0.14 * model.urgency,
              green: 0.45 - 0.30 * model.urgency,
              blue: 0.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if model.showTimeSinceLastBreak {
                Text(model.timeSinceLastBreak)
                    .font(appSemiBold(13))
                    .foregroundColor(urgencyColor)
            }

            Text(model.title)
                .font(appBold(16))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Countdown to auto-start
            VStack(alignment: .leading, spacing: 6) {
                Text(model.timerText)
                    .font(appSemiBold(24))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.2))
                        Capsule().fill(breakAccent)
                            .frame(width: max(0, geo.size.width * model.countdownProgress))
                    }
                }
                .frame(height: 5)
            }

            Text(model.quote)
                .font(appRegular(12))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Primary action
            SwiftUI.Button(action: model.onStartBreak) {
                Text(model.startTitle)
                    .font(appSemiBold(14))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 8).fill(breakAccent))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text(model.selectMinutesTitle)
                    .font(appRegular(12))
                    .foregroundColor(.secondary)
                Picker("", selection: $model.selectedMinutes) {
                    ForEach(model.minutesOptions, id: \.self) { Text($0) }
                }
                .labelsHidden()
                .frame(width: 72)
            }

            HStack(spacing: 12) {
                SwiftUI.Button(action: model.onSkip) {
                    Text(model.skipTitle)
                        .font(appMedium(13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)

                HoldToPostponeButton(seconds: model.requiredHoldSeconds,
                                     title: model.postponeTitle,
                                     accent: breakAccent,
                                     onComplete: model.onPostpone,
                                     onPressingChanged: model.onPostponePressing)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
        .frame(width: 360)
        .background(Color("backgroundColor"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(urgencyColor.opacity(0.25 + 0.5 * model.urgency), lineWidth: 1 + model.urgency)
        )
    }
}

/// A button that must be pressed and HELD for `seconds` before it fires `onComplete`.
/// A progress fill shows hold progress; releasing early cancels. `onPressingChanged`
/// reports press start/stop so callers can pause a countdown during the hold. When
/// `seconds <= 0` it behaves as a normal tap button (used when easy-skip is enabled).
struct HoldToPostponeButton: View {
    let seconds: Double
    let title: String
    let accent: Color
    var onComplete: () -> Void
    var onPressingChanged: (Bool) -> Void = { _ in }

    @SwiftUI.State private var progress: CGFloat = 0
    @SwiftUI.State private var isPressing = false

    private var label: String {
        seconds <= 0 ? title : (isPressing ? "Keep holding…" : "\(title) (hold \(Int(seconds))s)")
    }

    var body: some View {
        if seconds <= 0 {
            SwiftUI.Button(action: onComplete) {
                Text(title)
                    .font(appMedium(13))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 1))
            }
            .buttonStyle(.plain)
        } else {
            ZStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.12))
                        RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.35))
                            .frame(width: geo.size.width * progress)
                    }
                }
                Text(label)
                    .font(appMedium(13))
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 6)
            }
            .frame(height: 38)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onLongPressGesture(minimumDuration: seconds, maximumDistance: 60, pressing: { pressing in
                isPressing = pressing
                onPressingChanged(pressing)
                if pressing {
                    withAnimation(.linear(duration: seconds)) { progress = 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                }
            }, perform: {
                progress = 0
                isPressing = false
                onPressingChanged(false)
                onComplete()
            })
            .accessibility(label: Text("\(title), hold for \(Int(seconds)) seconds"))
        }
    }
}
