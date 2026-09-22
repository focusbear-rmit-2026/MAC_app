//
//  HabitTaskChecklistPane.swift
//  Focus Bear
//
//  Adds a "Tasks" pane (and its tab button) to the habit player, listing the Day Plan tasks the user
//  dragged onto the habit that is playing. Ticking a row completes the backing to-do through the Day
//  Plan's own write path, so the To-do list, project views and Day Plan all follow — and a tick made
//  on any of those screens ticks back here.
//
//  Built as an extension with associated objects — the same shape as the allowed-activity
//  "Habit Player | Day Plan" tabs in ScheduleViewController — so the storyboard and the 2,300-line
//  timerViewcontroller stay untouched apart from the calls that show/hide the pane.
//

import AppKit
import SwiftUI

private var tvcTaskPaneBoxKey: UInt8 = 0
private var tvcTaskPaneButtonKey: UInt8 = 0
private var tvcTaskPaneHeightKey: UInt8 = 0
private var tvcTaskPaneHabitNameKey: UInt8 = 0
private var tvcTaskPaneObserversKey: UInt8 = 0
private var tvcTaskPaneHostingKey: UInt8 = 0

extension timerViewcontroller {

    /// Height bounds for the pane: tall enough to read as a list, short enough that a long list
    /// scrolls instead of stretching the player (and, in windowed mode, the window itself).
    private static let taskPaneMinHeight: CGFloat = 90
    private static let taskPaneMaxHeight: CGFloat = 320

    // MARK: - Associated storage

    private var habitTaskPaneBox: NSBox? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneBoxKey) as? NSBox }
        set { objc_setAssociatedObject(self, &tvcTaskPaneBoxKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var habitTaskPaneButton: NSButton? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneButtonKey) as? NSButton }
        set { objc_setAssociatedObject(self, &tvcTaskPaneButtonKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var habitTaskPaneHeight: NSLayoutConstraint? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneHeightKey) as? NSLayoutConstraint }
        set { objc_setAssociatedObject(self, &tvcTaskPaneHeightKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Name of the habit whose tasks the pane is currently showing — the key half of the
    /// `"habit:<name>"` association. nil when the pane is hidden.
    private var habitTaskPaneHabitName: String? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneHabitNameKey) as? String }
        set { objc_setAssociatedObject(self, &tvcTaskPaneHabitNameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var habitTaskPaneHosting: NSHostingView<HabitTaskChecklistView>? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneHostingKey) as? NSHostingView<HabitTaskChecklistView> }
        set { objc_setAssociatedObject(self, &tvcTaskPaneHostingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var habitTaskPaneObservers: [NSObjectProtocol]? {
        get { objc_getAssociatedObject(self, &tvcTaskPaneObserversKey) as? [NSObjectProtocol] }
        set { objc_setAssociatedObject(self, &tvcTaskPaneObserversKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// True while the pane is showing tasks — the habit player counts it as one of its tabs and
    /// selects it first, because tasks dragged onto a habit are what the user wants in front of them.
    var hasHabitTaskChecklist: Bool { habitTaskPaneBox?.isHidden == false }

    // MARK: - Show / hide

    /// Show the tasks attached to `habit`, or hide the pane when there are none (or the caller passes
    /// nil, as the break/breathing/special-activity paths do). Bumps `tabCount` when it becomes
    /// visible, so it must be called after `tabCount` is reset and before the tab bar is resolved.
    func updateHabitTaskChecklist(for habit: habit?) {
        let name = habit?.name
        let tasks = HabitTaskChecklist.storedTasks(forHabitNamed: name)
        guard !tasks.isEmpty else { hideHabitTaskChecklist(); return }
        installHabitTaskPaneIfNeeded()
        habitTaskPaneHabitName = name
        renderHabitTaskPane(tasks)
        habitTaskPaneBox?.isHidden = false
        habitTaskPaneButton?.isHidden = false
        tabCount += 1
    }

    func hideHabitTaskChecklist() {
        habitTaskPaneHabitName = nil
        habitTaskPaneBox?.isHidden = true
        habitTaskPaneButton?.isHidden = true
        habitTaskPaneButton?.state = .off
    }

    /// Bring the tasks pane to the front (and push every other pane back), mirroring the existing
    /// `btnTab…Clicked` handlers.
    @objc func habitTaskPaneTabClicked(_ sender: Any) {
        webView.isHidden = true
        boxTakeNotes.isHidden = true
        boxInstructions.isHidden = true
        boxCheckList.isHidden = true
        boxTutorial.isHidden = true
        btnTabVideo.state = .off
        btnTabNotes.state = .off
        btnTabInstructions.state = .off
        btnTabCheckList.state = .off
        btnTutorial.state = .off
        habitTaskPaneBox?.isHidden = false
        habitTaskPaneButton?.state = .on
    }

    /// Called by every other tab handler so exactly one pane is in front.
    func deselectHabitTaskPane() {
        guard habitTaskPaneButton?.isHidden == false else { return }
        habitTaskPaneBox?.isHidden = true
        habitTaskPaneButton?.state = .off
    }

    // MARK: - Building

    private func installHabitTaskPaneIfNeeded() {
        guard habitTaskPaneBox == nil else { return }

        let box = NSBox()
        box.boxType = .custom
        box.borderType = .lineBorder
        box.borderWidth = 1
        box.borderColor = .separatorColor
        box.titlePosition = .noTitle
        box.contentViewMargins = .zero
        box.translatesAutoresizingMaskIntoConstraints = false
        let height = box.heightAnchor.constraint(equalToConstant: Self.taskPaneMinHeight)
        height.priority = .defaultHigh
        height.isActive = true
        habitTaskPaneHeight = height
        habitTaskPaneBox = box
        box.isHidden = true
        stackViewCustomTab.addArrangedSubview(box)

        let hosting = makeHabitTaskPaneHosting()
        habitTaskPaneHosting = hosting
        if let container = box.contentView {
            container.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.topAnchor.constraint(equalTo: container.topAnchor),
                hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
        }

        let button = cursorButton(frame: .zero)
        // Type before bezel: setButtonType(_:) resets cell attributes, so it has to come first or the
        // rounded bezel the other tab buttons use is thrown away.
        button.setButtonType(.pushOnPushOff)
        button.title = ScheduleText.habitTasksTab
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(habitTaskPaneTabClicked(_:))
        button.setContentHuggingPriority(.init(750), for: .vertical)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        habitTaskPaneButton = button
        (btnTabCheckList.superview as? NSStackView)?.addArrangedSubview(button)

        installHabitTaskPaneObserversIfNeeded()
    }

    /// A tick made elsewhere (the To-do list, the Day Plan, another device's sync landing) has to show
    /// up here too. `timerViewcontrollerObj` is a never-deallocated singleton, so these are registered
    /// once and simply no-op while the pane is hidden.
    private func installHabitTaskPaneObserversIfNeeded() {
        guard habitTaskPaneObservers == nil else { return }
        let completion = TodoCompletionBus.observe { [weak self] _ in self?.refreshHabitTaskChecklist() }
        let external = NotificationCenter.default.addObserver(forName: DayPlanTaskStore.tasksDidChangeExternally,
                                                             object: nil, queue: .main) { [weak self] _ in
            self?.refreshHabitTaskChecklist()
        }
        habitTaskPaneObservers = [completion, external]
    }

    private func refreshHabitTaskChecklist() {
        guard let name = habitTaskPaneHabitName else { return }
        renderHabitTaskPane(HabitTaskChecklist.storedTasks(forHabitNamed: name))
    }

    /// Swap in a fresh list. The hosting view itself is built once and only its `rootView` changes,
    /// so ticking a row re-renders in place instead of rebuilding (and losing the scroll position).
    private func renderHabitTaskPane(_ tasks: [DayPlanTask]) {
        let items = tasks.map { HabitChecklistItem(id: $0.id, title: $0.title, done: $0.done) }
        let content = HabitTaskChecklistView(items: items) { [weak self] taskID, done in
            HabitTaskChecklist.setDone(done, taskID: taskID)
            self?.refreshHabitTaskChecklist()
        }
        habitTaskPaneHosting?.rootView = content
        habitTaskPaneHeight?.constant = Self.habitTaskPaneHeight(rowCount: items.count)
    }

    private func makeHabitTaskPaneHosting() -> NSHostingView<HabitTaskChecklistView> {
        let hosting = NSHostingView(rootView: HabitTaskChecklistView(items: [], onToggle: { _, _ in }))
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // A hosting view's intrinsic size is its whole content; at the default 750 compression
        // resistance it outranks the player's own layout and would stretch the pane (and, in windowed
        // mode, the window) to fit every row. Let the pane's height constraint win and the list scroll.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        return hosting
    }

    /// Pane height for a list of `rowCount` rows, clamped so a single task doesn't look lost and a
    /// long list scrolls rather than stretching the player.
    static func habitTaskPaneHeight(rowCount: Int) -> CGFloat {
        let content = HabitTaskChecklistView.headerHeight
            + CGFloat(max(rowCount, 1)) * HabitTaskChecklistView.rowHeight + 16
        return min(max(content, taskPaneMinHeight), taskPaneMaxHeight)
    }
}
