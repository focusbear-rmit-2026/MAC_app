//
//  TaskShortcutCardTests.swift
//  Focus BearTests
//
//  The dismissible card that explains what can be typed into a task name (report
//  2026-09-21_07-42-02). Three things are worth protecting. The first two are about content; the
//  third was added after the user reported the card unusable, because "neither is the drawing" —
//  what this header used to say — turned out to be wrong. The card collapsed to no height and its
//  labels drew straight over the task rows, and every content test still passed.
//
//  * WHAT IT PROMISES. The Day Plan row and the menu's quick add do not share a grammar — a spelled
//    "30m" is a duration in the menu and part of the name on a row — so a card that listed one set
//    everywhere would be teaching a behaviour that does not exist where it is read.
//  * WHERE THE DISMISSAL IS KEPT. "Don't show it again" is per account, and the key must not be the
//    unsuffixed one that every account on this Mac shares before login (SettingsManager.isUserScopedKey).
//

import XCTest
import Cocoa
@testable import Focus_Bear

final class TaskShortcutCardTests: XCTestCase {

    // MARK: What the card lists

    func testDayPlanRowCardListsProjectPriorityAndMinutes() {
        XCTAssertEqual(TaskShortcutCard.hints(for: .dayPlanRow),
                       [ScheduleText.tasksShortcutProject,
                        ScheduleText.tasksShortcutPriority,
                        ScheduleText.tasksShortcutMinutes])
    }

    func testMenuCardAddsTheSpelledDurationToTheRowList() {
        XCTAssertEqual(TaskShortcutCard.hints(for: .menuQuickAdd),
                       TaskShortcutCard.hints(for: .dayPlanRow) + [ScheduleText.tasksShortcutDurationWords])
    }

    /// The row keeps "run 30m sprint" as a name, so the card under a row must not offer the spelled
    /// form — the exact way this card could lie about the thing the report asked it to explain.
    func testDayPlanRowCardDoesNotPromiseSpelledDurations() {
        XCTAssertFalse(TaskShortcutCard.hints(for: .dayPlanRow).contains(ScheduleText.tasksShortcutDurationWords))
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("run 30m sprint", knownProjects: []),
                       .save(ParsedQuickAddTask(title: "run 30m sprint", durationMinutes: nil)))
    }

    /// Every token the card names on a row is one the row's own grammar strips and applies. If the
    /// grammar moves again (as `*priority` → `!priority` just did), this fails next to the card.
    func testTheRowTokensTheCardNamesAreTheTokensTheRowHonours() {
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("draft the brief #Focus Bear", knownProjects: ["Focus Bear"]),
                       .save(ParsedQuickAddTask(title: "draft the brief", project: "Focus Bear")))
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("draft the brief !3", knownProjects: []),
                       .save(ParsedQuickAddTask(title: "draft the brief", outcome: 6)))
        XCTAssertEqual(TaskNameCommit.forDayPlanRow("draft the brief *15", knownProjects: []),
                       .save(ParsedQuickAddTask(title: "draft the brief", durationMinutes: 15)))
    }

    func testTitleAndDismissTooltipAreNotBlank() {
        XCTAssertFalse(TaskShortcutCard.title.isEmpty)
        XCTAssertFalse(TaskShortcutCard.dismissTooltip.isEmpty)
        for composer in [TaskShortcutCard.Composer.dayPlanRow, .menuQuickAdd] {
            XCTAssertFalse(TaskShortcutCard.hints(for: composer).contains { $0.isEmpty })
        }
    }

    // MARK: Remembering the dismissal

    private var defaults: UserDefaults!
    private let suite = "io.focusbear.tests.shortcutcard"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    func testCardShowsUntilItIsDismissed() {
        XCTAssertFalse(TaskShortcutCardPreference.isDismissed(userId: "user-a", defaults: defaults))
        TaskShortcutCardPreference.setDismissed(userId: "user-a", defaults: defaults)
        XCTAssertTrue(TaskShortcutCardPreference.isDismissed(userId: "user-a", defaults: defaults))
    }

    func testOneAccountsDismissalDoesNotSilenceAnother() {
        TaskShortcutCardPreference.setDismissed(userId: "user-a", defaults: defaults)
        XCTAssertFalse(TaskShortcutCardPreference.isDismissed(userId: "user-b", defaults: defaults))
    }

    /// Before login there is no user id. That must land in its own named slot rather than in the bare
    /// key the legacy per-user settings fall back to, which belongs to no account and is read by all.
    func testSignedOutDismissalHasItsOwnSlot() {
        TaskShortcutCardPreference.setDismissed(userId: nil, defaults: defaults)
        XCTAssertTrue(TaskShortcutCardPreference.isDismissed(userId: nil, defaults: defaults))
        XCTAssertFalse(TaskShortcutCardPreference.isDismissed(userId: "user-a", defaults: defaults))
        XCTAssertEqual(TaskShortcutCardPreference.key(forUserId: nil),
                       TaskShortcutCardPreference.key(forUserId: "   "))
        XCTAssertTrue(TaskShortcutCardPreference.key(forUserId: nil)
            .hasSuffix(TaskShortcutCardPreference.signedOutAccount))
    }

    /// The key is a whole account segment, never a prefix another account's key could extend — the
    /// failure mode of building keys by bare string concatenation.
    func testAccountKeysAreDistinct() {
        let keys = ["user-a", "user-ab", "  user-a  ", nil].map { TaskShortcutCardPreference.key(forUserId: $0) }
        XCTAssertEqual(keys[0], keys[2], "surrounding whitespace is not a different account")
        XCTAssertNotEqual(keys[0], keys[1])
        XCTAssertNotEqual(keys[0], keys[3])
    }

    // MARK: The card on a Day Plan row

    /// Editing a task name puts the card under that task, and its ✕ takes it away for every task from
    /// then on — the whole of what the report asked for, on the panel the reporter was typing into.
    @MainActor
    func testEditingATaskNameShowsTheCardUntilItsCloseButtonIsClicked() {
        let previousMock = DayPlanTaskStore.mockMode
        DayPlanTaskStore.mockMode = true
        let store = DayPlanTaskStore.shared
        let day = Calendar.current.date(from: DateComponents(year: 2060, month: 9, day: 21))!
        let previousTasks = store.allTasks(for: day)
        let first = DayPlanTask(title: "Post the Focus Button")
        let second = DayPlanTask(title: "Answer the support queue")
        store.loadMock([first, second], for: day)
        // The preference is the signed-in user's real one, so put back whatever this Mac had.
        let key = TaskShortcutCardPreference.key(forUserId: TaskShortcutCardPreference.currentUserId)
        let storedDismissal = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        let panel = DayPlanTasksPanel(frame: NSRect(x: 0, y: 0, width: 600, height: 500))
        let window = NSWindow(contentRect: panel.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = panel
        panel.date = day
        defer {
            window.makeFirstResponder(nil)
            window.close()
            store.loadMock(previousTasks, for: day)
            DayPlanTaskStore.mockMode = previousMock
            if let storedDismissal = storedDismissal { UserDefaults.standard.set(storedDismissal, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }

        beginEditingName(of: first, in: panel, window: window)
        guard let card = firstCard(in: panel) else { return XCTFail("No shortcut card under the task being edited") }
        // A set: the heading sits in its own nested stack alongside the ✕, so the view tree's order is
        // not the reading order. What matters is that the card shows the row grammar and nothing else.
        XCTAssertEqual(Set(lines(in: card)),
                       Set([TaskShortcutCard.title] + TaskShortcutCard.hints(for: .dayPlanRow)))

        guard let close = closeButton(in: card) else { return XCTFail("The card has no ✕") }
        close.performClick(nil)
        XCTAssertNil(firstCard(in: panel), "The ✕ must take the card away immediately")
        XCTAssertTrue(TaskShortcutCardPreference.isDismissedForCurrentUser)

        beginEditingName(of: second, in: panel, window: window)
        XCTAssertNil(firstCard(in: panel), "A dismissed card must not come back on the next task")
    }

    /// Focus the row's name field the way a click does, then run the panel's begin-editing handler:
    /// AppKit may hold that notification back until the first keystroke, which would make the test
    /// about its timing rather than about the card.
    @MainActor
    private func beginEditingName(of task: DayPlanTask, in panel: DayPlanTasksPanel, window: NSWindow) {
        guard let field = descendants(of: panel).compactMap({ $0 as? NSTextField })
            .first(where: { $0.identifier?.rawValue == "name:" + task.id }) else {
            return XCTFail("Row for \(task.title) is missing")
        }
        XCTAssertTrue(window.makeFirstResponder(field))
        panel.controlTextDidBeginEditing(Notification(name: NSControl.textDidBeginEditingNotification, object: field))
        drainMainQueue()
    }

    /// The panel defers the action row — and the card under it — to the next main-queue turn, so that
    /// AppKit has finished tearing down the previous field editor first.
    private func drainMainQueue() {
        let drained = expectation(description: "Deferred panel work ran")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 3)
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }

    private func firstCard(in panel: DayPlanTasksPanel) -> TaskShortcutCardView? {
        descendants(of: panel).compactMap { $0 as? TaskShortcutCardView }.first
    }

    private func closeButton(in card: TaskShortcutCardView) -> NSButton? {
        descendants(of: card).compactMap { $0 as? NSButton }
            .first { $0.toolTip == TaskShortcutCard.dismissTooltip }
    }

    private func lines(in card: TaskShortcutCardView) -> [String] {
        descendants(of: card).compactMap { $0 as? NSTextField }.map(\.stringValue).filter { !$0.isEmpty }
    }

    // MARK: That it actually takes up space
    //
    // The bug these exist for: the card is built around an NSBox, and assigning an auto-layout
    // subtree to `box.contentView` gives the box nothing to derive a height from. The card then
    // measured zero, the stack gave it no room, and its labels rendered on top of the rows above
    // and below — visible in the report's screenshot as the heading crossing "Doesn't fit today".
    // Everything the other tests assert was true the whole time.

    /// A frame small enough that a zero-height card passes nothing, and large enough that a
    /// correctly-measured one is not being clipped by the host.
    private func laidOutCard(width: CGFloat = 320) -> TaskShortcutCardView {
        let card = TaskShortcutCardView(hints: TaskShortcutCard.hints(for: .dayPlanRow),
                                        title: TaskShortcutCard.title,
                                        dismissTooltip: TaskShortcutCard.dismissTooltip)
        let host = NSView(frame: NSRect(x: 0, y: 0, width: width, height: 600))
        host.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            card.topAnchor.constraint(equalTo: host.topAnchor),
        ])
        host.layoutSubtreeIfNeeded()
        return card
    }

    func testCardMeasuresTallEnoughForEveryLineItLists() {
        let card = laidOutCard()
        // Heading plus one line per hint, at 11pt with 3pt spacing and the box's 6pt margins. The
        // bound is deliberately loose — it is checking "did this measure at all", not the metrics.
        let lines = CGFloat(TaskShortcutCard.hints(for: .dayPlanRow).count + 1)
        XCTAssertGreaterThan(card.frame.height, lines * 12,
                             "a card that measures shorter than its own text has nowhere to draw it")
    }

    func testNoLabelDrawsOutsideTheCard() {
        let card = laidOutCard()
        for label in Self.descendantLabels(of: card) {
            let frame = label.convert(label.bounds, to: card)
            XCTAssertTrue(card.bounds.contains(frame),
                          "\(label.stringValue) escapes the card: \(frame) vs \(card.bounds)")
        }
    }

    func testCardDoesNotOverlapItsNeighboursInAStack() {
        let above = NSTextField(labelWithString: "a task above")
        let below = NSTextField(labelWithString: "a task below")
        let card = TaskShortcutCardView(hints: TaskShortcutCard.hints(for: .dayPlanRow),
                                        title: TaskShortcutCard.title,
                                        dismissTooltip: TaskShortcutCard.dismissTooltip)
        let stack = NSStackView(views: [above, card, below])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.frame = NSRect(x: 0, y: 0, width: 320, height: 600)
        card.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.layoutSubtreeIfNeeded()

        // In a vertical stack the card must sit strictly between its neighbours, with no shared pixels.
        XCTAssertFalse(card.frame.intersects(above.frame), "the card overlaps the row above it")
        XCTAssertFalse(card.frame.intersects(below.frame), "the card overlaps the row below it")
        XCTAssertGreaterThan(card.frame.height, 0)
    }

    /// Every NSTextField under a view, at any depth — the card nests them inside an NSBox's content view.
    private static func descendantLabels(of view: NSView) -> [NSTextField] {
        view.subviews.flatMap { subview -> [NSTextField] in
            let here = (subview as? NSTextField).map { [$0] } ?? []
            return here + descendantLabels(of: subview)
        }
    }


    // MARK: The TOOLS section's remembered state (report 2026-09-21_16-00-46)
    //
    // "tools keeps collapsing. It should remember its state." #2352 made TOOLS start collapsed every
    // launch and did NOT persist it. Collapsed is the right default for a new account; applying it
    // as an override is what made a deliberate choice evaporate at every restart.

    func testToolsIsCollapsedForAnAccountThatHasNeverChosen() {
        let defaults = UserDefaults(suiteName: "tools-never-chosen-\(UUID().uuidString)")!
        XCTAssertFalse(ToolsSectionPreference.isExpanded(userId: "u1", defaults: defaults),
                       "#2352's default survives for anyone who has not touched it")
        XCTAssertFalse(ToolsSectionPreference.hasChosen(userId: "u1", defaults: defaults))
    }

    func testAChoiceIsRememberedInBothDirections() {
        let defaults = UserDefaults(suiteName: "tools-choice-\(UUID().uuidString)")!

        ToolsSectionPreference.setExpanded(true, userId: "u1", defaults: defaults)
        XCTAssertTrue(ToolsSectionPreference.isExpanded(userId: "u1", defaults: defaults))

        // "and vice versa" — collapsing must be as sticky as expanding, which a bool default of
        // false would hide.
        ToolsSectionPreference.setExpanded(false, userId: "u1", defaults: defaults)
        XCTAssertFalse(ToolsSectionPreference.isExpanded(userId: "u1", defaults: defaults))
        XCTAssertTrue(ToolsSectionPreference.hasChosen(userId: "u1", defaults: defaults),
                      "chose collapsed is a choice, not an absence")
    }

    func testOneAccountsToolsChoiceDoesNotFollowAnother() {
        let defaults = UserDefaults(suiteName: "tools-accounts-\(UUID().uuidString)")!
        ToolsSectionPreference.setExpanded(true, userId: "u1", defaults: defaults)

        XCTAssertFalse(ToolsSectionPreference.isExpanded(userId: "u2", defaults: defaults))
        XCTAssertNotEqual(ToolsSectionPreference.key(forUserId: "u1"),
                          ToolsSectionPreference.key(forUserId: "u2"))
    }

    /// The ownerless-key hazard that cost a user their full-screen setting: a value written before
    /// the account is restored must not be inherited by whoever signs in first.
    func testASignedOutChoiceHasItsOwnSlot() {
        let defaults = UserDefaults(suiteName: "tools-signedout-\(UUID().uuidString)")!
        ToolsSectionPreference.setExpanded(true, userId: nil, defaults: defaults)

        XCTAssertTrue(ToolsSectionPreference.isExpanded(userId: nil, defaults: defaults))
        XCTAssertFalse(ToolsSectionPreference.isExpanded(userId: "u1", defaults: defaults))
        // `hasSuffix` alone is vacuous when the constant is empty — and an EMPTY signed-out segment
        // is precisely the ownerless-key shape this exists to avoid, so assert it is a real name.
        XCTAssertFalse(ToolsSectionPreference.signedOutAccount.isEmpty)
        XCTAssertTrue(ToolsSectionPreference.key(forUserId: nil).hasSuffix(ToolsSectionPreference.signedOutAccount))
        // Namespaced, so it cannot collide with another feature keyed on the bare user id.
        XCTAssertNotEqual(ToolsSectionPreference.key(forUserId: "u1"), "u1")
        XCTAssertTrue(ToolsSectionPreference.key(forUserId: "u1").hasPrefix("sidebarTools"))
        XCTAssertEqual(ToolsSectionPreference.key(forUserId: "   "),
                       ToolsSectionPreference.key(forUserId: nil),
                       "a blank id is not an account")
    }

    /// The distinction the fix turns on: TOOLS auto-expands when a tool inside it is selected, and
    /// that must not be recorded — otherwise selecting a tool silently cancels a collapse.
    func testOnlyAClickIsRecordedNotAProgrammaticExpand() {
        let box = accordionBox()
        var userToggles: [Bool] = []
        var allChanges: [Bool] = []
        box.onUserToggled = { userToggles.append($0) }
        box.onStateChanged = { allChanges.append($0) }

        box.setExpanded(true)      // what the auto-expand path does
        box.setExpanded(false)

        XCTAssertEqual(allChanges, [true, false], "the view still hears every change")
        XCTAssertTrue(userToggles.isEmpty, "but none of them was the user's doing")

        // And the other half of the rule: a click IS recorded. Asserting only the negative let a
        // mutation that never records anything pass the suite.
        box.setFrameSize(NSSize(width: 100, height: 30))
        box.handleHeaderClick(at: NSPoint(x: 50, y: 15))
        XCTAssertEqual(userToggles, [true], "a click on the header is the user's doing")

        box.handleHeaderClick(at: NSPoint(x: 500, y: 500))
        XCTAssertEqual(userToggles, [true], "a click outside the header is not a toggle at all")
    }

}
