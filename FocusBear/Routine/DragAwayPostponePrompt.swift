//
//  DragAwayPostponePrompt.swift
//  Focus Bear
//
//  Issue #2091: while a routine runs (non-full-screen), stepping away starts a 60s timer that
//  re-centres the window once — a fair grace period. If the user then drags the window aside
//  AGAIN in the same session, instead of silently re-centring (which felt like the app fighting
//  them), we ask via this SwiftUI overlay (hosted on the window content view, per repo convention)
//  whether to postpone the routine or keep going. Trigger + grace logic lives in
//  mainWindowController (scheduleDragAwayCheck / recenterRoutineWindowForAwayTimer).
//
//  Strings are config-driven (`dragAwayPostponeVcInfo` in config.json) — no hardcoded
//  user-facing English.
//

import SwiftUI

private let dragPromptAccent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)
private func dragPromptBold(_ size: CGFloat) -> Font { Font(getBoldFont(size: size)) }
private func dragPromptSemiBold(_ size: CGFloat) -> Font { Font(getSemiBoldFont(size: size)) }
private func dragPromptMedium(_ size: CGFloat) -> Font { Font(getMediumFont(size: size)) }

/// Config-driven copy + callbacks for the drag-away postpone overlay.
final class DragAwayPostponeViewModel: ObservableObject {
    @Published var title = "I noticed you moved the routine window away. Do you want to postpone it?"
    @Published var postponeTitle = "Postpone"
    @Published var keepGoingTitle = "Keep going"

    var onPostpone: () -> Void = {}
    var onKeepGoing: () -> Void = {}
}

struct DragAwayPostponeView: View {
    @ObservedObject var model: DragAwayPostponeViewModel

    var body: some View {
        ZStack {
            // Dimmed backdrop. contentShape + an empty onTapGesture make it a real hit target so clicks
            // on it are swallowed instead of falling through to the window controls behind the overlay.
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }

            VStack(spacing: 22) {
                Text(model.title)
                    .font(dragPromptBold(18))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    SwiftUI.Button(action: model.onKeepGoing) {
                        Text(model.keepGoingTitle)
                            .font(dragPromptMedium(14))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()

                    SwiftUI.Button(action: model.onPostpone) {
                        Text(model.postponeTitle)
                            .font(dragPromptSemiBold(14))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 8).fill(dragPromptAccent))
                            .foregroundColor(.white)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                }
            }
            .padding(28)
            .frame(width: 420)
            // Shadow lives on the card's background shape only — applying it to the whole card also
            // shadowed the opaque Postpone button, which pooled a shadow beneath it.
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color("backgroundColor"))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(dragPromptAccent.opacity(0.35), lineWidth: 1))
        }
    }
}

/// NSHostingView that swallows every click within its bounds, so the dimmed overlay actually blocks
/// interaction with the window controls underneath (#2091). Without this, SwiftUI's hit-testing lets
/// clicks in non-interactive regions of the overlay fall through to the AppKit views below — the user
/// could still click buttons on the routine window while the prompt was up.
private final class ClickBlockingHostingView: NSHostingView<DragAwayPostponeView> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Never return nil inside our bounds: honour SwiftUI's own hit (so the Postpone / Keep going
        // buttons still work), otherwise claim the point ourselves so the click can't fall through to
        // the controls behind the overlay. (Don't override mouseDown — SwiftUI buttons are driven
        // through the hosting view's normal event handling, so swallowing it would break them.)
        super.hitTest(point) ?? (frame.contains(point) ? self : nil)
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Presents / dismisses the drag-away postpone overlay on the main window's content view.
/// Singleton so the window-move delegate can check `isVisible` and avoid stacking prompts
/// while one is already on screen.
final class DragAwayPostponePromptManager {
    static let shared = DragAwayPostponePromptManager()

    private var hostingView: NSHostingView<DragAwayPostponeView>?
    private let model = DragAwayPostponeViewModel()

    var isVisible: Bool { hostingView != nil }

    private init() {}

    private func applyConfigStrings() {
        guard let info = configjson.value(forKey: "dragAwayPostponeVcInfo") as? NSDictionary else { return }
        model.title = info.value(forKey: "titleText") as? String ?? model.title
        model.postponeTitle = info.value(forKey: "buttonPostponeText") as? String ?? model.postponeTitle
        model.keepGoingTitle = info.value(forKey: "buttonKeepGoingText") as? String ?? model.keepGoingTitle
    }

    func present(onPostpone: @escaping () -> Void, onKeepGoing: @escaping () -> Void) {
        guard !isVisible, let host = mainWindowControllerObj?.window?.contentView else { return }
        applyConfigStrings()
        model.onPostpone = { [weak self] in
            self?.dismiss()
            onPostpone()
        }
        model.onKeepGoing = { [weak self] in
            self?.dismiss()
            onKeepGoing()
        }

        let hosting = ClickBlockingHostingView(rootView: DragAwayPostponeView(model: model))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: host.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        hostingView = hosting
    }

    func dismiss() {
        hostingView?.removeFromSuperview()
        hostingView = nil
    }
}
