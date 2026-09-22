import AppKit
import XCTest
@testable import Focus_Bear

final class MainWindowContentLayoutTests: XCTestCase {
    private let display = NSRect(x: 0, y: 0, width: 1440, height: 900)
    private let visible = NSRect(x: 0, y: 70, width: 1440, height: 806)

    @MainActor
    func testDayPlanSplitContentAndExitControlStayInsideNarrowWindowAfterResize() {
        // Reproduce the actual root -> NSBox -> NSSplitView -> habits page hierarchy. A long
        // intrinsic heading plus an expanded sidebar used to grow the content view beyond the
        // NSWindow, even though its outer frame still fitted the 1024pt Retina display.
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1024, height: 666),
                              styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let controller = mainWindowController(window: window)
        let rootController = CleanupFixtureViewController()
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1114, height: 775))
        rootController.view = root
        // Style-mask transitions normally protect page cleanup in the production caller.
        rootController.shouldIgnoreViewWilDisappear = true
        window.contentViewController = rootController
        defer { window.close() }

        let content = customBoxBg()
        content.boxType = .custom; content.borderWidth = 0; content.contentViewMargins = .zero
        root.addSubview(content)
        root.addConstraints(subView: content)
        rootController.boxContainer = content
        let split = NSSplitView()
        split.isVertical = true; split.dividerStyle = .thin
        content.contentView!.addSubview(split)
        content.contentView!.addConstraints(subView: split)
        let sidebar = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 666))
        let page = NSView(frame: NSRect(x: 231, y: 0, width: 883, height: 666))
        split.addSubview(sidebar); split.addSubview(page)
        split.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        let sidebarContents = NSView()
        sidebar.addSubview(sidebarContents)
        sidebar.addConstraints(subView: sidebarContents)
        sidebarContents.widthAnchor.constraint(equalToConstant: 230).isActive = true
        let timeline = NSView()
        let tasks = NSView()
        let heading = NSTextField(labelWithString:
            "An unusually long routine heading with its time range and remaining tasks in the Day Plan")
        heading.lineBreakMode = .byTruncatingTail
        let exit = NSButton(title: "Exit Fullscreen", target: nil, action: nil)
        for child in [timeline, tasks, exit] {
            child.translatesAutoresizingMaskIntoConstraints = false
            page.addSubview(child)
        }
        heading.translatesAutoresizingMaskIntoConstraints = false
        timeline.addSubview(heading)
        NSLayoutConstraint.activate([
            timeline.leadingAnchor.constraint(equalTo: page.leadingAnchor),
            timeline.topAnchor.constraint(equalTo: page.topAnchor),
            timeline.bottomAnchor.constraint(equalTo: page.bottomAnchor),
            timeline.trailingAnchor.constraint(equalTo: tasks.leadingAnchor, constant: -1),
            tasks.trailingAnchor.constraint(equalTo: page.trailingAnchor),
            tasks.topAnchor.constraint(equalTo: page.topAnchor),
            tasks.bottomAnchor.constraint(equalTo: page.bottomAnchor),
            tasks.widthAnchor.constraint(equalToConstant: 306), // reported user's saved panel width
            heading.leadingAnchor.constraint(equalTo: timeline.leadingAnchor, constant: 16),
            heading.trailingAnchor.constraint(equalTo: timeline.trailingAnchor, constant: -16),
            heading.topAnchor.constraint(equalTo: timeline.topAnchor, constant: 40),
            exit.trailingAnchor.constraint(equalTo: page.trailingAnchor, constant: -10),
            exit.topAnchor.constraint(equalTo: page.topAnchor, constant: 3)
        ])
        // Exercise both the custom borderless viewport and ordinary window geometry. No window
        // is ordered onto a screen, no live controller data is loaded, and no action is invoked.
        for style: NSWindow.StyleMask in [[.borderless, .resizable], [.titled, .resizable]] {
            window.styleMask = style
            for width: CGFloat in [1024, 986, 1600, 1024] {
                window.setFrame(NSRect(x: -20000, y: -20000, width: width, height: 666), display: false)
                controller.windowDidResize(Notification(name: NSWindow.didResizeNotification, object: window))
                root.layoutSubtreeIfNeeded()
                let viewport = window.contentLayoutRect.width
                XCTAssertEqual(window.frame.width, width, accuracy: 0.5, "Do not enlarge the user's window")
                XCTAssertEqual(root.bounds.width, viewport, accuracy: 0.5)
                XCTAssertEqual(split.bounds.width, viewport, accuracy: 0.5)
                XCTAssertEqual(sidebar.frame.width, 230, accuracy: 0.5)
                XCTAssertEqual(tasks.bounds.width, 306, accuracy: 0.5)
                for control in [tasks, exit] {
                    let bounds = root.convert(control.bounds, from: control)
                    XCTAssertGreaterThanOrEqual(bounds.minX, 0)
                    XCTAssertLessThanOrEqual(bounds.maxX, viewport + 0.5,
                        "The full task panel and exit hit target must fit, not just the NSWindow frame")
                }
                XCTAssertGreaterThan(heading.bounds.width, 200, "Keep a readable timeline on the narrow display")
                XCTAssertEqual(rootController.view, root, "Resizing must preserve the current page")
            }
        }
    }

    @MainActor
    func testApprovedPostponementDefersWindowRestorationAndPreservesTheCurrentPage() {
        let oldLoaded = isMainWindowLoaded
        let oldCovers = arrWindows
        isMainWindowLoaded = false
        arrWindows = []
        defer { isMainWindowLoaded = oldLoaded; arrWindows = oldCovers }
        for state in [CURRENTSTATE._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_, ._POSTPONE_FOCUS_SUMMARY_] {
            let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1000, height: 700),
                                  styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
            window.isReleasedWhenClosed = false
            let root = CleanupFixtureViewController()
            root.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
            let page = NSView(frame: root.view.bounds)
            root.view.addSubview(page)
            root.containerView = page
            window.contentViewController = root
            let controller = mainWindowController(window: window)
            controller.isFullScreenVisible = true
            controller.restoreWindowAfterPostponement(stateProvider: { state })
            XCTAssertTrue(controller.isFullScreenVisible, "Do not mutate AppKit hierarchy inside the approval callback")
            XCTAssertFalse(window.styleMask.contains(.titled))
            let finished = expectation(description: "Deferred normal-window restoration")
            DispatchQueue.main.async {
                XCTAssertFalse(controller.isFullScreenVisible)
                XCTAssertTrue(window.styleMask.contains(.titled))
                XCTAssertTrue(page.superview === root.view, "Keep the focus/Help page and any entered draft")
                XCTAssertFalse(root.shouldIgnoreViewWilDisappear)
                // Avoid triggering unrelated production cleanup from this fixture's final close.
                root.shouldIgnoreViewWilDisappear = true
                window.close()
                finished.fulfill()
            }
            wait(for: [finished], timeout: 2)
        }
    }

    @MainActor
    func testDeferredPostponeRestorationCannotInterruptANewRoutineOrMicrobreak() {
        let window = NSWindow(contentRect: .zero, styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let controller = mainWindowController(window: window)
        for newState in [CURRENTSTATE._MORNING_HABIT_, ._EVENING_HABIT_, ._MICRO_BREAK_, ._SHUTOFFMAC_] {
            controller.isFullScreenVisible = true
            var state = CURRENTSTATE._POSTPONE_EVENING_HABIT_
            controller.restoreWindowAfterPostponement(stateProvider: { state })
            state = newState
            let finished = expectation(description: "New routine retains fullscreen")
            DispatchQueue.main.async {
                XCTAssertTrue(controller.isFullScreenVisible)
                XCTAssertFalse(window.styleMask.contains(.titled))
                finished.fulfill()
            }
            wait(for: [finished], timeout: 2)
        }
    }

    @MainActor
    func testDeferredPostponeRestorationDoesNotMutateAReplacementWindow() {
        let original = NSWindow(contentRect: .zero, styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        let replacement = NSWindow(contentRect: .zero, styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        original.isReleasedWhenClosed = false; replacement.isReleasedWhenClosed = false
        defer { original.close(); replacement.close() }
        let controller = mainWindowController(window: original)
        controller.isFullScreenVisible = true
        controller.restoreWindowAfterPostponement(stateProvider: { ._POSTPONE_EVENING_HABIT_ })
        controller.window = replacement
        let finished = expectation(description: "Replacement keeps its own lifecycle")
        DispatchQueue.main.async {
            XCTAssertTrue(controller.isFullScreenVisible)
            XCTAssertFalse(original.styleMask.contains(.titled))
            XCTAssertFalse(replacement.styleMask.contains(.titled))
            finished.fulfill()
        }
        wait(for: [finished], timeout: 2)
    }

    @MainActor
    func testLeavingCustomFullscreenClearsActualSecondaryWindowCollection() {
        let oldLoaded = isMainWindowLoaded
        let oldMain = mainWindowControllerObj
        let oldCovers = arrWindows
        isMainWindowLoaded = false
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1000, height: 700),
                              styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let controller = mainWindowController(window: window)
        mainWindowControllerObj = controller
        let cover = SecondaryCoverFixtureWindow(contentRect: .zero, styleMask: .borderless,
                                                backing: .buffered, defer: true)
        cover.isReleasedWhenClosed = false
        defer {
            arrWindows = oldCovers
            mainWindowControllerObj = oldMain
            isMainWindowLoaded = oldLoaded
            window.close(); cover.close()
        }
        controller.isFullScreenVisible = true
        arrWindows = [cover]

        // Exercise the actual transition called by Help/Settings navigation. A preference-only
        // fullscreen check used to leave this window covering the other monitor afterwards.
        controller.showSmallSizeWindow()

        XCTAssertFalse(controller.isFullScreenVisible)
        XCTAssertTrue(window.styleMask.contains(.titled))
        XCTAssertEqual(cover.orderOutCount, 1)
        XCTAssertTrue(arrWindows.isEmpty)
        XCTAssertFalse(controller.shouldCoverSecondaryScreens)
        // A queued routine callback after the transition must remove a stale cover as well,
        // before any modal-loop handling or blocker creation can run.
        arrWindows = [cover]
        showBlankWindowInSecondaryMonitor()
        XCTAssertTrue(arrWindows.isEmpty)
        XCTAssertEqual(cover.orderOutCount, 2)
    }

    @MainActor
    func testSecondaryCoversRequireVisibleCustomFullscreenNotAStalePreference() {
        let window = SecondaryCoverFixtureWindow(contentRect: .zero, styleMask: [.borderless, .resizable],
                                                backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let controller = mainWindowController(window: window)
        controller.isFullScreenVisible = true
        window.fixtureIsVisible = false
        XCTAssertFalse(controller.shouldCoverSecondaryScreens, "A closed main window cannot block another screen")
        window.fixtureIsVisible = true
        XCTAssertTrue(controller.shouldCoverSecondaryScreens)
        window.styleMask = [.titled, .resizable]
        XCTAssertFalse(controller.shouldCoverSecondaryScreens, "A stale fullscreen flag must not cover screens beside Help")
        window.styleMask = [.borderless, .resizable]
        controller.isFullScreenVisible = false
        XCTAssertFalse(controller.shouldCoverSecondaryScreens)
    }

    @MainActor
    func testPostPasswordIntentionUsesAttachedMainHostWhenHelpDetachesDayPlan() throws {
        let oldMain = mainWindowControllerObj
        let window = SecondaryCoverFixtureWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1000, height: 700),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.fixtureIsVisible = true
        let root = NSViewController()
        root.view = NSView(frame: NSRect(x: 0, y: 0, width: 1000, height: 700))
        window.contentViewController = root
        let controller = mainWindowController(window: window)
        mainWindowControllerObj = controller
        defer { mainWindowControllerObj = oldMain; window.close() }
        let routine = PostponeHostFixtureController()
        routine.view = NSView(frame: root.view.bounds)
        let help = NSView(frame: root.view.bounds)
        root.view.addSubview(help)

        XCTAssertNil(routine.view.window, "Reproduce the report's detached Day Plan on Help")
        let presenter = try XCTUnwrap(routine.postponeIntentionPresenter())
        XCTAssertTrue(presenter === root)
        XCTAssertTrue(presenter.view.window === window)
        XCTAssertTrue(help.superview === root.view, "Showing the approval sheet must not replace Help")

        root.view.addSubview(routine.view)
        XCTAssertTrue(routine.postponeIntentionPresenter() === routine, "Day Plan keeps its existing sheet host")
        routine.view.removeFromSuperview()
        window.fixtureIsVisible = false
        XCTAssertNil(routine.postponeIntentionPresenter(), "Do not hide an approval on a closed main window")
        window.fixtureIsVisible = true
        window.fixtureIsMiniaturized = true
        XCTAssertNil(routine.postponeIntentionPresenter(), "A minimized window cannot host a visible approval")
        window.fixtureIsMiniaturized = false
        XCTAssertTrue(routine.postponeIntentionPresenter() === root)
        mainWindowControllerObj = nil
        XCTAssertNil(routine.postponeIntentionPresenter(), "No window must not authorize or postpone anything")
    }

    @MainActor
    func testPageCleanupPreservesWeakWindowChromeOutletsAcrossNavigation() throws {
        let frame = NSRect(x: 0, y: 0, width: 1600, height: 900)
        let window = NSWindow(contentRect: frame, styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let root = NSView(frame: frame)
        window.contentView = root
        let controller = CleanupFixtureViewController()
        controller.view = root
        let content = customBoxBg(frame: root.bounds)
        root.addSubview(content)
        controller.boxContainer = content
        let pageHost = NSView(frame: root.bounds)
        content.contentView!.addSubview(pageHost)
        controller.containerView = pageHost

        // Match the actual storyboard's weak outlets and nested NSBox/NSStackView hierarchy.
        // Once setup ends, only the root view hierarchy owns the chrome, as in the real app.
        weak var originalChrome: NSBox?
        do {
            let chrome = NSBox(frame: NSRect(x: 0, y: 882, width: 25, height: 18))
            let stack = NSStackView()
            let minimize = NSBox()
            let button = NSButton()
            button.target = controller
            button.action = #selector(ViewController.btnMinimizeClicked(_:))
            minimize.contentView!.addSubview(button)
            stack.addArrangedSubview(minimize)
            chrome.contentView!.addSubview(stack)
            content.contentView!.addSubview(chrome)
            controller.boxTopButtons = chrome
            controller.stackViewTopButtons = stack
            controller.boxMinimize = minimize
            originalChrome = chrome
            MainWindowContentLayout.attachWindowControls(chrome, to: root)
        }

        for isHidden in [false, true] {
            controller.boxTopButtons.isHidden = isHidden
            let outgoingPage = NSView()
            let outgoingModal = NSView()
            pageHost.addSubview(outgoingPage)
            root.addSubview(outgoingModal)

            // Exercise the production navigation cleanup, not just the reparenting helper.
            controller.removeSubViews()

            XCTAssertNotNil(originalChrome, "Navigation must not deallocate the weak chrome outlets")
            let chrome = try XCTUnwrap(controller.boxTopButtons)
            XCTAssertTrue(chrome === originalChrome)
            XCTAssertTrue(chrome.superview === root)
            XCTAssertEqual(chrome.isHidden, isHidden, "Cleanup must preserve window-mode visibility")
            XCTAssertNotNil(controller.stackViewTopButtons)
            let minimize = try XCTUnwrap(controller.boxMinimize)
            let button = try XCTUnwrap(minimize.contentView?.subviews.first as? NSButton)
            XCTAssertTrue(button.target === controller)
            XCTAssertEqual(button.action, #selector(ViewController.btnMinimizeClicked(_:)))
            XCTAssertNil(outgoingPage.superview)
            XCTAssertNil(outgoingModal.superview)
            XCTAssertTrue(pageHost.subviews.isEmpty)
            XCTAssertEqual(root.subviews.count, 2)
            XCTAssertTrue(content.superview === root)
        }
    }

    @MainActor
    func testCustomMinimizeControlStaysInWindowChromeWhileRealWindowContentIsInset() {
        let frame = NSRect(x: 0, y: 0, width: 1600, height: 900)
        let window = NSWindow(contentRect: frame, styleMask: [.borderless, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let root = NSView(frame: frame)
        window.contentView = root
        defer { window.close() }
        let content = NSBox(frame: root.bounds)
        content.boxType = .custom; content.borderWidth = 0; content.contentViewMargins = .zero
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: root.topAnchor),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        // Match the storyboard: controls start inside the NSBox's content view, with the dot
        // six points below their top edge. The original target/action must survive reparenting.
        let oldHost = content.contentView!
        let controls = NSView()
        controls.translatesAutoresizingMaskIntoConstraints = false
        oldHost.addSubview(controls)
        let button = NSButton(frame: NSRect(x: 13, y: 0, width: 12, height: 12))
        button.target = window; button.action = #selector(NSWindow.miniaturize(_:))
        controls.addSubview(button)
        NSLayoutConstraint.activate([
            controls.topAnchor.constraint(equalTo: oldHost.topAnchor),
            controls.leadingAnchor.constraint(equalTo: oldHost.leadingAnchor),
            controls.widthAnchor.constraint(equalToConstant: 25),
            controls.heightAnchor.constraint(equalToConstant: 18)
        ])
        MainWindowContentLayout.attachWindowControls(controls, to: root)
        let constraintCount = root.constraints.count
        for inset: CGFloat in [25, 38, 0] {
            MainWindowContentLayout.apply(topInset: inset, to: content, in: root)
            MainWindowContentLayout.attachWindowControls(controls, to: root)
            root.layoutSubtreeIfNeeded()
            let dot = root.convert(button.bounds, from: button)
            XCTAssertEqual(root.bounds.maxY - dot.midY, 12, accuracy: 0.01,
                           "The reported dot moved from y12 to y37 when the content inset was 25")
            XCTAssertEqual(content.frame.maxY, root.bounds.maxY - inset, accuracy: 0.01)
            XCTAssertEqual(root.constraints.count, constraintCount, "Repeated layout must not duplicate constraints")
            XCTAssertTrue(controls.superview === root)
            XCTAssertTrue(button.target === window)
            XCTAssertEqual(button.action, #selector(NSWindow.miniaturize(_:)))
            if inset > 0 {
                XCTAssertGreaterThanOrEqual(dot.minY, content.frame.maxY, "The dot must stay above sidebar content")
                XCTAssertTrue(root.hitTest(NSPoint(x: dot.midX, y: dot.midY)) === button)
            }
        }
        controls.isHidden = true
        MainWindowContentLayout.attachWindowControls(controls, to: root)
        XCTAssertTrue(controls.isHidden, "Window-mode transitions still control chrome visibility")
    }

    @MainActor
    func testStoryboardHostConstraintMovesContentBelowMenuAndRestoresOnExit() {
        // Match Main.storyboard's root NSView, boxContainer NSBox, and four edge constraints.
        // No storyboard controllers, live settings, or visible window are needed for AppKit layout.
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1600, height: 900))
        let content = NSBox()
        content.boxType = .custom
        content.borderWidth = 0
        content.contentViewMargins = .zero
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: root.topAnchor),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])
        let screen = root.frame
        let available = NSRect(x: 0, y: 0, width: 1600, height: 875)
        let inset = MainWindowContentLayout.topInset(contentFrameOnScreen: screen, screenFrame: screen,
            visibleScreenFrame: available, screenSafeAreaTop: 0,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable])
        XCTAssertTrue(MainWindowContentLayout.apply(topInset: inset, to: content, in: root),
                      "Production must discover the storyboard's existing top constraint")
        root.layoutSubtreeIfNeeded()
        XCTAssertEqual(content.frame, available, "Content must move down below the menu bar")
        XCTAssertEqual(root.frame, screen, "The window's outer content frame still covers the display")
        XCTAssertTrue(MainWindowContentLayout.apply(topInset: 0, to: content, in: root))
        root.layoutSubtreeIfNeeded()
        XCTAssertEqual(content.frame, root.bounds, "Leaving custom fullscreen must remove the inset")
    }

    func testBorderlessContentStartsBelowMenuBarWithoutGivingUpFullWindowCoverage() {
        let inset = MainWindowContentLayout.topInset(contentFrameOnScreen: display, screenFrame: display,
            visibleScreenFrame: visible, screenSafeAreaTop: 0,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable])
        XCTAssertEqual(inset, 24)
        XCTAssertEqual(display.maxY - inset, visible.maxY)
        XCTAssertEqual(display.height - inset, 876, "The Dock does not shrink the fullscreen content from below")
    }

    func testCameraSafeAreaAndMenuBarAreNotAddedTogether() {
        let inset = MainWindowContentLayout.topInset(contentFrameOnScreen: display, screenFrame: display,
            visibleScreenFrame: visible, screenSafeAreaTop: 38,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable])
        XCTAssertEqual(inset, 38)
    }

    func testAlreadyInsetContentDoesNotGetAnotherMenuBarGap() {
        XCTAssertEqual(MainWindowContentLayout.topInset(contentFrameOnScreen: visible, screenFrame: display,
            visibleScreenFrame: visible, screenSafeAreaTop: 0,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable]), 0)
    }

    func testSecondaryDisplayUsesItsOwnGlobalOrigin() {
        let secondary = NSRect(x: -1920, y: -200, width: 1920, height: 1080)
        let secondaryVisible = NSRect(x: -1920, y: -200, width: 1920, height: 1056)
        XCTAssertEqual(MainWindowContentLayout.topInset(contentFrameOnScreen: secondary, screenFrame: secondary,
            visibleScreenFrame: secondaryVisible, screenSafeAreaTop: 0,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable]), 24)
    }

    func testAutoHiddenMenuBarWithoutCameraNeedsNoInset() {
        XCTAssertEqual(MainWindowContentLayout.topInset(contentFrameOnScreen: display, screenFrame: display,
            visibleScreenFrame: display, screenSafeAreaTop: 0,
            isCustomFullScreen: true, styleMask: [.borderless, .resizable]), 0)
    }

    func testNormalAndNativeFullScreenWindowsKeepAppKitGeometry() {
        let modes: [(Bool, NSWindow.StyleMask)] = [(false, .resizable),
            (true, [.titled, .resizable]), (true, [.fullScreen, .resizable])]
        for (custom, style) in modes {
            XCTAssertEqual(MainWindowContentLayout.topInset(contentFrameOnScreen: display, screenFrame: display,
                visibleScreenFrame: visible, screenSafeAreaTop: 38,
                isCustomFullScreen: custom, styleMask: style), 0)
        }
    }

    // MARK: - Menu outside-click dismissal (report 2026-09-11_21-40-57)

    /// The to-do editor opens as a sheet on the menu window. A sheet is its own NSWindow, so the
    /// menu's outside-click dismissal used to treat the first click inside the editor — clicking
    /// into the due-date field — as a click outside, and tore the menu down mid-edit.
    func testMenuOwnershipTreatsSheetsAndChildWindowsAsInsideTheMenu() {
        let menu = NSObject(), sheet = NSObject(), nested = NSObject(), unrelated = NSObject()
        let parents: [ObjectIdentifier: AnyObject] = [ObjectIdentifier(sheet): menu, ObjectIdentifier(nested): sheet]
        let parent: (AnyObject) -> AnyObject? = { parents[ObjectIdentifier($0)] }
        XCTAssertTrue(MenuWindowOwnership.isOwned(menu, by: menu, parent: parent), "The menu window itself")
        XCTAssertTrue(MenuWindowOwnership.isOwned(sheet, by: menu, parent: parent), "A sheet presented on the menu")
        XCTAssertTrue(MenuWindowOwnership.isOwned(nested, by: menu, parent: parent), "A popover inside that sheet")
        XCTAssertFalse(MenuWindowOwnership.isOwned(unrelated, by: menu, parent: parent), "A genuinely unrelated window")
    }

    func testMenuOwnershipStopsOnACycleInsteadOfHanging() {
        let menu = NSObject(), a = NSObject(), b = NSObject()
        var parents: [ObjectIdentifier: AnyObject] = [:]
        parents[ObjectIdentifier(a)] = b
        parents[ObjectIdentifier(b)] = a
        XCTAssertFalse(MenuWindowOwnership.isOwned(a, by: menu, parent: { parents[ObjectIdentifier($0)] }))
    }

    @MainActor
    func testMenuOwnershipFollowsARealSheetToItsParentWindow() {
        let menu = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 320, height: 480),
                            styleMask: [.borderless], backing: .buffered, defer: true)
        let child = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 320, height: 200),
                             styleMask: [.borderless], backing: .buffered, defer: true)
        menu.isReleasedWhenClosed = false; child.isReleasedWhenClosed = false
        defer { menu.removeChildWindow(child); child.close(); menu.close() }
        menu.addChildWindow(child, ordered: .above)
        XCTAssertEqual(MenuWindowOwnership.owner(of: child), menu, "A child window's owner is its parent")
        XCTAssertTrue(MenuWindowOwnership.isOwned(child, by: menu))
        XCTAssertFalse(MenuWindowOwnership.isOwned(menu, by: child))
    }


    // MARK: Window resizing (report 2026-09-14_15-04-30)

    /// The viewport constraint must never be an equality. A required `width == N` on the content view
    /// is defended by Auto Layout against the user dragging the window edge, which is what made the
    /// window unresizable. As a cap it still keeps content inside the viewport.
    @MainActor
    func testTheViewportConstraintIsACapSoTheWindowStaysResizable() {
        for style: NSWindow.StyleMask in [[.borderless, .resizable], [.titled, .closable, .resizable]] {
            let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1200, height: 700),
                                  styleMask: style, backing: .buffered, defer: true)
            window.isReleasedWhenClosed = false
            defer { window.close() }
            let root = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 700))
            window.contentView = root

            MainWindowContentLayout.constrainWidthToWindow(root)
            let constraint = root.constraints.first { $0.identifier == "mainWindowViewportWidth" }
            XCTAssertEqual(constraint?.relation, .lessThanOrEqual,
                           "An equality here is what pinned the window's width")
            XCTAssertEqual(constraint?.constant ?? 0, window.contentLayoutRect.width, accuracy: 0.5)
        }
    }

    @MainActor
    func testTheCapFollowsTheWindowInsteadOfAccumulatingConstraints() {
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1200, height: 700),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 700))
        window.contentView = root

        MainWindowContentLayout.constrainWidthToWindow(root)
        window.setFrame(NSRect(x: -20000, y: -20000, width: 900, height: 700), display: false)
        MainWindowContentLayout.constrainWidthToWindow(root)

        let caps = root.constraints.filter { $0.identifier == "mainWindowViewportWidth" }
        XCTAssertEqual(caps.count, 1, "One constraint, re-used — never a new one per resize")
        XCTAssertEqual(caps.first?.constant ?? 0, window.contentLayoutRect.width, accuracy: 0.5)
    }

    // MARK: The cap must not become the window's own ceiling (report 2026-09-16_10-36-19)

    /// The reported symptom — the window grew taller but never wider — is what a required width cap on
    /// a window's content view does: AppKit reads it as the window's maximum width. Since the cap sits
    /// on the width the window already has, every attempt to drag it wider is vetoed. So the cap has to
    /// be lifted before the resize, and only ever lifted: pulling it back down is the layout pass's job.
    @MainActor
    func testTheViewportCapIsLiftedForAResizeTheWindowIsAboutToMake() {
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1200, height: 700),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 700))
        window.contentView = root

        MainWindowContentLayout.constrainWidthToWindow(root)
        let cap = MainWindowContentLayout.viewportWidthCap(on: root)
        XCTAssertNotNil(cap)
        let viewport = window.contentLayoutRect.width

        XCTAssertTrue(MainWindowContentLayout.allowWindowWidth(viewport + 300, on: root))
        XCTAssertEqual(cap?.constant ?? 0, viewport + 300, accuracy: 0.5,
                       "The ceiling has to be out of the way before AppKit applies the wider frame")

        XCTAssertFalse(MainWindowContentLayout.allowWindowWidth(viewport - 100, on: root),
                       "Narrowing needs no lift; the layout pass tightens the cap back onto the viewport")
        XCTAssertEqual(cap?.constant ?? 0, viewport + 300, accuracy: 0.5)

        MainWindowContentLayout.constrainWidthToWindow(root)
        XCTAssertEqual(cap?.constant ?? 0, window.contentLayoutRect.width, accuracy: 0.5,
                       "Back to the real viewport once the resize is over — that is what contains content")
        XCTAssertEqual(root.constraints.filter { $0.identifier == MainWindowContentLayout.viewportWidthConstraintIdentifier }.count, 1)
    }

    @MainActor
    func testDraggingTheWindowWiderLiftsTheCapAndKeepsTheSizeTheUserAskedFor() {
        let window = NSWindow(contentRect: NSRect(x: -20000, y: -20000, width: 1200, height: 700),
                              styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        let controller = mainWindowController(window: window)
        defer { window.close() }
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 1200, height: 700))
        window.contentView = root
        MainWindowContentLayout.constrainWidthToWindow(root)

        let wider = NSSize(width: window.frame.width + 300, height: window.frame.height + 120)
        XCTAssertEqual(controller.windowWillResize(window, to: wider), wider, "The drag is the user's to make")
        XCTAssertGreaterThanOrEqual(MainWindowContentLayout.viewportWidthCap(on: root)?.constant ?? 0, wider.width - 0.5)

        // Full screen still owns its own size: there the window is not the user's to resize at all.
        controller.isFullScreenVisible = true
        XCTAssertEqual(controller.windowWillResize(window, to: wider), window.frame.size)
    }

    func testTheLiveResizeCeilingSpansEveryScreen() {
        let left = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let right = NSRect(x: 1440, y: 0, width: 2560, height: 1440)
        XCTAssertEqual(MainWindowContentLayout.liveResizeCeiling(screenFrames: [left, right]), 4000, accuracy: 0.5,
                       "A drag can carry the window across the whole desktop, so the ceiling has to")
        XCTAssertEqual(MainWindowContentLayout.liveResizeCeiling(screenFrames: [left]), left.width, accuracy: 0.5)
        XCTAssertEqual(MainWindowContentLayout.liveResizeCeiling(screenFrames: []), 0, accuracy: 0.5)
    }

    // MARK: Which states full screen covers (report 2026-09-14_16-31-53)

    func testFullScreenCoversARunningRoutine() {
        for state in [CURRENTSTATE._MORNING_HABIT_, ._EVENING_HABIT_, ._CUSTOM_ROUTINE_, ._SHUTOFFMAC_] {
            XCTAssertTrue(FullScreenStates.shouldUseFullScreen(setting: true, state: state),
                          "\(state) is a routine — full-screen mode is exactly for this")
        }
    }

    func testAPostponedRoutineAndABreakAreNotFullScreen() {
        for state in [CURRENTSTATE._POSTPONE_MORNING_HABIT_, ._POSTPONE_EVENING_HABIT_,
                      ._POSTPONE_FOCUS_SUMMARY_, ._MICRO_BREAK_, ._NOTHING_] {
            XCTAssertFalse(FullScreenStates.shouldUseFullScreen(setting: true, state: state),
                           "\(state) is not a running routine, so it must not take the whole screen")
        }
    }

    func testTheSettingStillGovernsEverything() {
        XCTAssertFalse(FullScreenStates.shouldUseFullScreen(setting: false, state: ._MORNING_HABIT_),
                       "Full-screen mode off means off, routine or not")
    }

    func testTheAbortPromptStaysFullScreenSoItIsNotAnEscapeHatch() {
        XCTAssertTrue(FullScreenStates.shouldUseFullScreen(setting: true, state: ._ABORT_))
    }
}

/// Avoid unrelated live sidebar/settings initialization while exercising ViewController's real
/// navigation cleanup against AppKit views and the same weak outlets used by the storyboard.
private final class CleanupFixtureViewController: ViewController {
    override func viewDidLoad() {}
    override func viewWillAppear() {} // Skip unrelated live sidebar restoration in offscreen fixtures.
}

/// No visible windows or live sidebar initialization are required for these host/transition tests.
private final class PostponeHostFixtureController: habitsVc {
    override func viewDidLoad() {}
}

private final class SecondaryCoverFixtureWindow: NSWindow {
    var orderOutCount = 0
    var fixtureIsVisible = false
    var fixtureIsMiniaturized = false
    override var isVisible: Bool { fixtureIsVisible }
    override var isMiniaturized: Bool { fixtureIsMiniaturized }
    override func orderOut(_ sender: Any?) {
        orderOutCount += 1
        super.orderOut(sender)
    }

}
