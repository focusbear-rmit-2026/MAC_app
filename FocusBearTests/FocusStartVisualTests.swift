import AppKit
import QuartzCore
import SwiftUI
import XCTest
@testable import Focus_Bear

/// Explicit opt-in: these render only in a requested macOS visual-QA run. Fixtures construct the
/// real SwiftUI view directly; no controllers, work-choice loading, settings writes or API calls.
@MainActor
final class FocusStartVisualTests: XCTestCase {
    func testCapturePostponeNoticeInLightAndDarkMenus() throws {
        let outputKey = "FOCUSBEAR_POSTPONE_NOTICE_CAPTURE_DIRECTORY"
        guard let directory = ProcessInfo.processInfo.environment[outputKey] else {
            throw XCTSkip("Postpone notice visual capture is opt-in")
        }
        let destination = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
        for scheme in [ColorScheme.light, .dark] {
            let model = MenuModel()
            model.habitsPostponedUntil = "Habits postponed until 1:47 PM"
            let view = FocusBearMenuView(model: model)
                .environment(\.colorScheme, scheme)
                .frame(width: FocusBearMenuView.width)
            let host = NSHostingView(rootView: view)
            let size = NSSize(width: FocusBearMenuView.width, height: 700)
            let window = FixtureWindow(contentRect: NSRect(origin: NSPoint(x: -12000, y: -12000), size: size),
                                       styleMask: .borderless, backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = host
            window.orderBack(nil)
            defer { window.orderOut(nil); window.contentView = nil; window.close() }
            host.frame = NSRect(origin: .zero, size: size)
            for _ in 0..<3 {
                host.layoutSubtreeIfNeeded()
                RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            }
            let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: bitmap)
            let data = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
            let name = scheme == .light ? "postpone-menu-light.png" : "postpone-menu-dark.png"
            try data.write(to: destination.appendingPathComponent(name))
        }
    }

    func testPrimaryButtonUsesItsFullVisibleHitTargetAndHonorsDisabledState() throws {
        for contentWidth: CGFloat in [794, 1370] {
            let scale = FocusStartScale(contentWidth: contentWidth)
            let width = scale.pt(FocusStartLayout.contentColumnWidth)
            let height = scale.pt(FocusStartLayout.primaryButtonHeight)
            for enabled in [true, false] {
                var actionCount = 0
                let button = FocusStartPrimaryButton(title: FocusStartStrings().startSessionButton,
                    scale: scale, isEnabled: enabled, action: { actionCount += 1 })
                    .frame(width: width)
                    .padding(20)
                let host = NSHostingView(rootView: button)
                if #available(macOS 13.0, *) { host.sizingOptions = [] }
                let size = NSSize(width: width + 40, height: height + 40)
                host.frame = NSRect(origin: .zero, size: size)
                let window = FixtureWindow(contentRect: NSRect(origin: NSPoint(x: -12000, y: -12000), size: size),
                    styleMask: [.borderless], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.ignoresMouseEvents = true
                window.contentView = host
                window.orderBack(nil)
                defer { window.orderOut(nil); window.contentView = nil; window.close() }
                for _ in 0..<3 {
                    host.layoutSubtreeIfNeeded()
                    window.displayIfNeeded()
                    RunLoop.main.run(until: Date().addingTimeInterval(0.05))
                }
                // Each inset edge is well outside the centered label. The last point covers
                // the label too, guarding against a replacement gesture that only fixes padding.
                let points = [NSPoint(x: 30, y: 20 + height / 2),
                              NSPoint(x: 10 + width, y: 20 + height / 2),
                              NSPoint(x: 20 + width / 2, y: 25),
                              NSPoint(x: 20 + width / 2, y: 15 + height),
                              NSPoint(x: 20 + width / 2, y: 20 + height / 2)]
                for (index, point) in points.enumerated() {
                    try clickSyntheticWindow(window, host: host, point: point)
                    XCTAssertEqual(actionCount, enabled ? index + 1 : 0,
                        "The visible button must activate exactly once at \(point), enabled=\(enabled), width=\(contentWidth).")
                }
                try clickSyntheticWindow(window, host: host, point: NSPoint(x: 5, y: 20 + height / 2))
                XCTAssertEqual(actionCount, enabled ? points.count : 0, "The surrounding page must not activate Start.")
            }
        }
    }

    /// Dispatch only to an offscreen fixture window in this XCTest process. The queued release
    /// also lets a native button finish a synchronous tracking loop; no global mouse is moved.
    private func clickSyntheticWindow(_ window: NSWindow, host: NSView, point: NSPoint) throws {
        let location = host.convert(point, to: nil)
        let timestamp = ProcessInfo.processInfo.systemUptime
        let down = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseDown, location: location,
            modifierFlags: [], timestamp: timestamp, windowNumber: window.windowNumber,
            context: nil, eventNumber: 1, clickCount: 1, pressure: 1))
        let up = try XCTUnwrap(NSEvent.mouseEvent(with: .leftMouseUp, location: location,
            modifierFlags: [], timestamp: timestamp + 0.01, windowNumber: window.windowNumber,
            context: nil, eventNumber: 2, clickCount: 1, pressure: 0))
        NSApp.postEvent(up, atStart: true)
        window.sendEvent(down)
        // SwiftUI's gesture path may return without a native tracking loop consuming the release.
        if let release = NSApp.nextEvent(matching: .leftMouseUp, until: Date(), inMode: .eventTracking, dequeue: true) {
            window.sendEvent(release)
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    func testAdvancedFocusStartVisualFixtures() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["FOCUS_START_VISUAL_QA"] == "1"
                || environment["TEST_RUNNER_FOCUS_START_VISUAL_QA"] == "1" else {
            throw XCTSkip("Enable FOCUS_START_VISUAL_QA for an isolated macOS visual-QA run.")
        }
        let sizes: [(String, NSSize)] = [
            ("narrow-650", NSSize(width: 650, height: 1000)),
            ("wide-1728", NSSize(width: 1728, height: 1400)),
            ("native-main-content", NSSize(width: 1370, height: 875)),
            ("native-secondary-content", NSSize(width: 794, height: 644))
        ]
        for (sizeName, size) in sizes {
            for dark in [false, true] {
                for scenario in Scenario.allCases {
                    let name = "focus-start-\(scenario.rawValue)-\(sizeName)-\(dark ? "dark" : "light")"
                    try XCTContext.runActivity(named: name) { activity in
                        let state = try fixture(scenario)
                        let result = try capture(state: state, size: size, dark: dark)
                        XCTAssertGreaterThan(result.png.count, 20_000, "A blank or missing render must fail visual QA.")
                        let attachment = XCTAttachment(data: result.png, uniformTypeIdentifier: "public.png")
                        attachment.name = name
                        attachment.lifetime = .keepAlways
                        activity.add(attachment)
                        let geometry = XCTAttachment(data: result.geometry, uniformTypeIdentifier: "public.json")
                        geometry.name = name + "-geometry"
                        geometry.lifetime = .keepAlways
                        activity.add(geometry)
                    }
                }
            }
        }
    }

    private enum Scenario: String, CaseIterable {
        case duration, projectSearch = "project-search", selectedTasks = "selected-tasks", blockSearch = "block-search"
    }

    private func fixture(_ scenario: Scenario) throws -> FocusStartState {
        let state = FocusStartState(strings: FocusStartStrings(), todoStrings: ToDoStrings(), dayPlanTasks: { [] })
        state.duration = FocusStartDuration(minutes: 90)
        state.breakDurationMinutes = 5
        state.breakFrequencyMinutes = 30
        state.isMicroBreaksOn = true
        state.isBreakSettingsExpanded = true
        state.isAiBlockingOn = true
        state.strictness = .captain
        state.projects = try decode([
            ["id": "project-1", "name": "Portfolio case study", "icon": "🎨", "importance": 3],
            ["id": "project-2", "name": "Website redesign", "icon": "💻", "importance": 2],
            ["id": "project-3", "name": "Research and writing", "icon": "📚"]
        ])
        let tasks: [ToDoTask] = try decode([
            ["id": "task-1", "title": "Write the research summary and outline the next steps", "status": "NOT_STARTED",
             "project_id": "project-1", "duration": 1800, "top_score": 8.5, "icon": "📝"],
            ["id": "task-2", "title": "Review the latest design feedback", "status": "NOT_STARTED",
             "project_id": "project-1", "duration": 1200, "top_score": 6.0, "icon": "🎨"],
            ["id": "task-3", "title": "Prepare tomorrow’s notes", "status": "NOT_STARTED", "duration": 900]
        ])
        state.blockLists = ["Deep work", "Deep research", "Deep writing", "Deep study", "Deep coding", "Deep reading", "Evening leisure"]
            .enumerated().map { index, name in
                FocusStartBlockList(id: "block-\(index)", name: name, itemCount: 12 + index * 7,
                    focusAlignmentScoreThreshold: nil, lastIntentionUsed: "", lastDurationUsedMinutes: nil,
                    isDefault: false, isRelaxFocus: false, isAIEnabled: index != 2)
            }
        state.selectedBlockListIndex = 0
        switch scenario {
        case .duration:
            state.expandedCard = .duration
        case .projectSearch:
            state.expandedCard = .goal
            state.isEditingGoal = true
            state.suggestedTasks = tasks
        case .selectedTasks:
            state.expandedCard = .goal
            state.goal = state.projects[0].name
            state.selectedProjectID = state.projects[0].id
            state.selectedTasks = Array(tasks.prefix(2))
        case .blockSearch:
            state.expandedCard = .blocking
            state.goal = state.projects[0].name
            state.selectedProjectID = state.projects[0].id
            state.selectedTasks = Array(tasks.prefix(2))
            state.blockListQuery = "Deep"
        }
        return state
    }

    private func decode<T: Decodable>(_ rows: [[String: Any]]) throws -> [T] {
        try JSONDecoder().decode([T].self, from: JSONSerialization.data(withJSONObject: rows))
    }

    private struct Capture {
        let png: Data
        let geometry: Data
    }

    private final class PrimaryActionGeometry {
        var frame: CGRect?
    }

    private func capture(state: FocusStartState, size: NSSize, dark: Bool) throws -> Capture {
        let appearance = try XCTUnwrap(NSAppearance(named: dark ? .darkAqua : .aqua))
        // SwiftUI's colorScheme does not set AppKit's semantic NSColor drawing context. Keep
        // this isolated XCTest process consistent through construction, layout and bitmap drawing.
        let previousAppearance = NSApp.appearance
        NSApp.appearance = appearance
        defer { NSApp.appearance = previousAppearance }
        var result: Result<Capture, Error>!
        appearance.performAsCurrentDrawingAppearance {
            result = Result { try captureInCurrentAppearance(state: state, size: size, dark: dark) }
        }
        return try result.get()
    }

    private func captureInCurrentAppearance(state: FocusStartState, size: NSSize, dark: Bool) throws -> Capture {
        let primaryAction = PrimaryActionGeometry()
        let root = FocusStartAdvancedScreen(state: state)
            .onPreferenceChange(FocusStartPrimaryActionFrameKey.self) { primaryAction.frame = $0 }
            .environment(\.colorScheme, dark ? .dark : .light)
            .environment(\.locale, Locale(identifier: "en_US"))
            .transaction { transaction in
                transaction.disablesAnimations = true
                transaction.animation = nil
            }
        let host = NSHostingView(rootView: root)
        if #available(macOS 13.0, *) { host.sizingOptions = [] }
        for orientation: NSLayoutConstraint.Orientation in [.horizontal, .vertical] {
            host.setContentHuggingPriority(.defaultLow, for: orientation)
            host.setContentCompressionResistancePriority(.defaultLow, for: orientation)
        }
        host.frame = NSRect(origin: .zero, size: size)
        host.autoresizingMask = [.width, .height]
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let window = FixtureWindow(contentRect: NSRect(origin: NSPoint(x: -12000, y: -12000), size: size),
                                   styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.contentView = host
        window.orderBack(nil)
        defer { window.orderOut(nil); window.contentView = nil; window.close() }
        // Allow SwiftUI layout preferences (the bear's active-card position) and the layer tree to settle.
        for _ in 0..<6 {
            window.makeFirstResponder(nil)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            host.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            CATransaction.commit()
            CATransaction.flush()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(host.bounds.width, size.width, accuracy: 0.5, "Hosting must not widen the fixture window.")
        XCTAssertEqual(host.bounds.height, size.height, accuracy: 0.5)
        let actionFrame = try XCTUnwrap(primaryAction.frame, "The actual Start action must report its rendered bounds.")
        XCTAssertGreaterThan(actionFrame.width, 0)
        XCTAssertGreaterThan(actionFrame.height, 0)
        XCTAssertGreaterThanOrEqual(actionFrame.minX, -0.5, "Start must stay inside the visible page without horizontal scrolling.")
        XCTAssertGreaterThanOrEqual(actionFrame.minY, -0.5)
        XCTAssertLessThanOrEqual(actionFrame.maxX, size.width + 0.5)
        XCTAssertLessThanOrEqual(actionFrame.maxY, size.height + 0.5, "Start must be fully visible without scrolling the cards.")
        // Preserve AppKit's actual backing density; metadata records the measured pixel scale.
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.needsDisplay = true
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let metadata: [String: Any] = [
            "appearance": dark ? "dark" : "light",
            "pointWidth": size.width, "pointHeight": size.height,
            "pixelWidth": bitmap.pixelsWide, "pixelHeight": bitmap.pixelsHigh,
            "pixelScale": CGFloat(bitmap.pixelsWide) / size.width,
            "hostBounds": NSStringFromRect(host.bounds),
            "primaryActionFrame": NSStringFromRect(actionFrame),
            "firstResponder": String(describing: window.firstResponder),
            "views": viewGeometry(host),
            "accessibility": accessibilityGeometry(host, in: host)
        ]
        return Capture(png: try XCTUnwrap(bitmap.representation(using: .png, properties: [:])),
                       geometry: try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]))
    }

    /// Record native scroll offsets separately from pixels so a clipped header cannot pass as an
    /// appearance issue. Accessibility includes the actual title/card text and its measured frame.
    private func viewGeometry(_ view: NSView) -> [String: Any] {
        var row: [String: Any] = ["class": String(describing: type(of: view)),
                                  "frame": NSStringFromRect(view.frame),
                                  "bounds": NSStringFromRect(view.bounds)]
        if let scroll = view as? NSScrollView {
            row["documentVisibleRect"] = NSStringFromRect(scroll.documentVisibleRect)
        }
        row["children"] = view.subviews.map(viewGeometry)
        return row
    }

    private func accessibilityGeometry(_ root: AnyObject, in host: NSView) -> [[String: Any]] {
        var rows: [[String: Any]] = []
        var visited = Set<ObjectIdentifier>()
        func visit(_ object: AnyObject, depth: Int) {
            guard depth < 20, rows.count < 500, visited.insert(ObjectIdentifier(object)).inserted,
                  let element = object as? NSAccessibilityProtocol else { return }
            let screenFrame = element.accessibilityFrame()
            let windowFrame = host.window?.convertFromScreen(screenFrame) ?? .zero
            rows.append(["role": element.accessibilityRole()?.rawValue ?? "",
                         "label": element.accessibilityLabel() ?? "",
                         "value": String(describing: element.accessibilityValue() ?? ""),
                         "frame": NSStringFromRect(host.convert(windowFrame, from: nil))])
            for child in element.accessibilityChildren() ?? [] { visit(child as AnyObject, depth: depth + 1) }
        }
        visit(root, depth: 0)
        return rows
    }
}

/// A runner may have a smaller display than a wide fixture; preserve the requested viewport.
private final class FixtureWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}
