//
//  todoListToolVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//
//  Hosts the native To-do List / Projects screen (FocusBear/ToDo). It replaced the
//  dashboard.focusbear.io/webview/tools-todo-list webview; the native views talk to the same /to-do,
//  /projects and /portfolio APIs the web page uses, so tasks stay in sync with the dashboard and
//  mobile app. Shown by ViewController.showTaskView when no focus session is running (the running
//  focus-session To-do Player is still taskPlayerVc's webview).
//

import Cocoa
import SwiftUI

class todoListToolVc: NSViewController {

    let todoStore: ToDoStore
    let projectsStore: ProjectsStore
    /// Which tab is showing; a project tap on the Projects tab switches back to Tasks.
    private let tabSubject = ToDoTabSelection()

    init() {
        let strings = ToDoStrings.load()
        todoStore = ToDoStore(strings: strings)
        projectsStore = ProjectsStore(strings: strings)
        super.init(nibName: nil, bundle: nil)
        projectsStore.onSelectProject = { [weak self] project in
            self?.todoStore.setProjectFilter(project.id)
            self?.tabSubject.selectedTab = .tasks
        }
        todoStore.onTaskChanged = { [weak self] in self?.projectsStore.detail?.reloadTasks() }
        // The row's Snooze is the Day Plan's smart snooze; it scans the schedule's free time per day.
        todoStore.scheduleFreeMinutes = { scheduleViewController.scheduleFreeMinutes(on: $0) }
        // A project created on either tab must show up on the other: the Projects list / portfolio
        // and the task editor's project catalogue are separate stores.
        projectsStore.onProjectCreated = { [weak self] project in self?.todoStore.insertProject(project) }
        todoStore.onProjectCreated = { [weak self] project in self?.projectsStore.insertProject(project) }
    }

    required init?(coder: NSCoder) {
        fatalError("todoListToolVc is built in code")
    }

    /// Built in code (no storyboard scene) — new Mac UI is SwiftUI hosted in an NSHostingView.
    override func loadView() {
        let container = NSView()
        let screen = ToDoHostView(todoStore: todoStore, projectsStore: projectsStore, tabSelection: tabSubject) { [weak self] in
            self?.view.window?.close()
        }
        let hosting = NSHostingView(rootView: screen)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        // The hosting view's intrinsic (ideal) size is the whole task list; at the default 750
        // compression resistance it outranks the window's size and would grow the main window to fit
        // every row. Let the window size win so the list scrolls instead.
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.setContentCompressionResistancePriority(.init(1), for: .vertical)
        hosting.setContentCompressionResistancePriority(.init(1), for: .horizontal)
        hosting.setContentHuggingPriority(.init(1), for: .vertical)
        hosting.setContentHuggingPriority(.init(1), for: .horizontal)
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
    }

    /// Reload every time the screen is shown (the webview reloaded the page on each open).
    override func viewWillAppear() {
        super.viewWillAppear()
        reloadData()
    }

    func reloadData() {
        todoStore.screenAppeared()
        projectsStore.screenAppeared()
    }

    /// The webview used to refresh focus-mode tags on close because the user may have created
    /// projects in it; the native editor can too (`POST /projects`), so keep the Day Plan's tag
    /// cache in step.
    override func viewWillDisappear() {
        super.viewWillDisappear()
        allApiObject.getFocusModeTags(completionHandler: { _ in })
    }
}

/// Bridges the VC's tab selection into SwiftUI so a project tap can switch tabs.
final class ToDoTabSelection: ObservableObject {
    @Published var selectedTab = ToDoScreenTab.tasks
}

private struct ToDoHostView: View {
    @ObservedObject var todoStore: ToDoStore
    @ObservedObject var projectsStore: ProjectsStore
    @ObservedObject var tabSelection: ToDoTabSelection
    let onClose: () -> Void

    var body: some View {
        ToDoScreen(todoStore: todoStore, projectsStore: projectsStore, selectedTab: $tabSelection.selectedTab, onClose: onClose)
    }
}
