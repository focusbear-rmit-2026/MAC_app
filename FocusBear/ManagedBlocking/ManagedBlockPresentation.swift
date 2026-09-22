import Cocoa
import SwiftUI

final class ManagedBlockPresentation {
    static let shared = ManagedBlockPresentation()
    private var window: NSWindow?

    func showMalformedWebsite(runtime: ManagedBlockingRuntime) {
        let alert = NSAlert()
        alert.messageText = ManagedBlockingText.value("blockedTitle", fallback: "This website is blocked")
        alert.informativeText = ManagedBlockingText.value("malformedWebsite", fallback: "A website address could not be safely classified. Access was blocked, but this attempt could not be synced.")
        alert.addButton(withTitle: ManagedBlockingText.value("close", fallback: "Close"))
        if let window = NSApp.keyWindow { alert.beginSheetModal(for: window, completionHandler: nil) }
        else { alert.runModal() }
    }

    func show(resource: ManagedResource, browser: BROWSER, target: ManagedBrowserObservation, reason: String, categories: [String],
              violationId: String?, runtime: ManagedBlockingRuntime) {
        window?.close()
        let model = ManagedBlockNotice(resource: resource, browser: browser, target: target, reason: reason,
            categories: categories, violationId: violationId, runtime: runtime)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = ManagedBlockingText.value("blockedTitle", fallback: "This website is blocked")
        window.isReleasedWhenClosed = false
        window.sharingType = .none
        window.level = .floating
        let host = NSHostingController(rootView: ManagedBlockNoticeView(model: model, close: { [weak window] in window?.close() }))
        if #available(macOS 13.0, *) { host.sizingOptions = [] }
        for axis in [NSLayoutConstraint.Orientation.horizontal, .vertical] {
            host.view.setContentCompressionResistancePriority(.defaultLow, for: axis)
            host.view.setContentHuggingPriority(.defaultLow, for: axis)
        }
        window.contentViewController = host
        window.center()
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

final class ManagedBlockNotice: ObservableObject {
    let resource: ManagedResource
    let browser: BROWSER
    @Published private(set) var reason: String
    let target: ManagedBrowserObservation
    private let session: UUID
    let categories: [String]
    @Published private(set) var violationId: String?
    private let runtime: ManagedBlockingRuntime
    @Published var explanation = ""
    @Published private(set) var isSubmitting = false
    @Published private(set) var result: String?
    @Published private(set) var isReopened = false

    init(resource: ManagedResource, browser: BROWSER, target: ManagedBrowserObservation, reason: String, categories: [String],
         violationId: String?, runtime: ManagedBlockingRuntime) {
        self.resource = resource; self.browser = browser; self.reason = reason
        self.target = target; self.session = runtime.sessionToken
        self.categories = categories; self.violationId = violationId; self.runtime = runtime
    }

    var canAppeal: Bool { violationId != nil && reason != "recovery" && !isSubmitting }

    func recheck() {
        guard !isSubmitting else { return }
        isSubmitting = true
        runtime.recheckForAppeal(resource, expectedSession: session) { [weak self] response in
            guard let self = self else { return }
            self.isSubmitting = false
            switch response {
            case .success(let decision):
                self.violationId = decision.violationId
                self.reason = decision.reason
                self.result = nil
                if decision.allowed {
                    self.runtime.revisit(self.resource, browser: self.browser, target: self.target, expectedSession: self.session) { self.isReopened = $0 }
                }
            case .failure:
                self.result = ManagedBlockingText.value("appealUnavailable", fallback: "Access could not be verified. The website remains blocked.")
            }
        }
    }

    func submit() {
        guard canAppeal, let id = violationId, (10...2000).contains(explanation.trimmingCharacters(in: .whitespacesAndNewlines).count) else { return }
        isSubmitting = true
        runtime.submitAppeal(violationId: id, explanation: explanation, expectedSession: session) { [weak self] response in
            guard let self = self else { return }
            self.isSubmitting = false
            switch response {
            case .success(let appeal):
                switch appeal.status {
                case "allow_scoped_access":
                    self.result = ManagedBlockingText.value("appealAllowed", fallback: "This website passed the safety review. Access is being verified again before reopening it.")
                case "needs_human_review":
                    self.result = ManagedBlockingText.value("appealReviewRequired", fallback: "This request needs review by your school or parent. The website remains blocked.")
                default:
                    self.result = ManagedBlockingText.value("appealDenied", fallback: "The safety review did not approve access. The website remains blocked.")
                }
                if appeal.status == "allow_scoped_access" {
                    self.isSubmitting = true
                    self.runtime.revisit(self.resource, browser: self.browser, target: self.target, expectedSession: self.session) { allowed in
                        self.isSubmitting = false; self.isReopened = allowed
                        if !allowed { self.result = ManagedBlockingText.value("appealUnavailable", fallback: "Access could not be verified. The website remains blocked.") }
                    }
                }
            case .failure:
                self.result = ManagedBlockingText.value("appealUnavailable", fallback: "Access could not be verified. The website remains blocked.")
            }
        }
    }
}

private struct ManagedBlockNoticeView: View {
    @ObservedObject var model: ManagedBlockNotice
    let close: () -> Void

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            Text(ManagedBlockingText.value(model.reason == "recovery" ? "recoveryTitle" : "blockedTitle", fallback: "This website is blocked"))
                .font(.title2).bold()
            Text(model.resource.host).font(.headline)
            Text(ManagedBlockingText.value(model.reason == "recovery" ? "recoveryBody" : "blockedBody",
                fallback: "Your managed schedule blocks this website. You can ask for a strict safety review if this decision is incorrect or the site is needed for learning."))
                .fixedSize(horizontal: false, vertical: true)
            if !model.categories.isEmpty {
                Text(model.categories.map(ManagedBlockingText.category).joined(separator: ", ")).font(.caption)
            }
            if model.canAppeal {
                Text(ManagedBlockingText.value("appealPrompt", fallback: "Explain why this website is safe or relevant to your learning (10–2000 characters)."))
                    .font(.subheadline)
                TextEditor(text: $model.explanation).frame(minHeight: 70, maxHeight: 100)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.4)))
            } else if model.violationId == nil {
                Text(ManagedBlockingText.value("appealUnavailable", fallback: "Connect and revisit the website to request a verified safety review. No offline override is available."))
                    .font(.caption)
            }
            if let result = model.result { Text(result).font(.subheadline).fixedSize(horizontal: false, vertical: true) }
            HStack {
                SwiftUI.Button(ManagedBlockingText.value("close", fallback: "Close"), action: close)
                Spacer()
                if model.isSubmitting { ProgressView().scaleEffect(0.7) }
                if model.violationId == nil {
                    SwiftUI.Button(ManagedBlockingText.value("recheckWebsite", fallback: "Reconnect and recheck"), action: model.recheck)
                        .disabled(model.isSubmitting)
                }
                if model.canAppeal {
                    SwiftUI.Button(ManagedBlockingText.value("appealButton", fallback: "Request safety review"), action: model.submit)
                        .disabled(!(10...2000).contains(model.explanation.trimmingCharacters(in: .whitespacesAndNewlines).count))
                }
            }
        }
        .padding(24)
        .frame(width: 512)
        .onChange(of: model.isReopened) { value in if value { close() } }
        }
    }
}
