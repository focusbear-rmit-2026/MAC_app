//
//  ProjectsView.swift
//  Focus Bear
//
//  The Projects tab — the native version of the web's project portfolio (`dashboard/projects`):
//  "What matters" (server-bucketed `GET /portfolio` regrouped into Ask for an extension / Start now /
//  Backburner, with the Overcommitted banner and today's pace) and "All projects" (`GET /projects`,
//  searched, filtered by lifecycle status, sorted by risk). Tapping a project filters the task list.
//

import SwiftUI
import AppKit

struct ProjectsTabView: View {
    @ObservedObject var store: ProjectsStore
    @ObservedObject var todoStore: ToDoStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let detail = store.detail {
                ProjectDetailView(store: detail, todoStore: todoStore, onBack: { store.closeDetail() },
                                  onShowInTaskList: { store.showInTaskList(detail.project) })
            } else {
                toolbar
                if store.viewMode == .focus { ProjectsFocusView(store: store) } else { ProjectsAllView(store: store) }
            }
        }
        .sheet(isPresented: $store.isCreateVisible) { ProjectCreateSheet(store: store) }
        .sheet(isPresented: $store.isSettingsVisible) { ProjectCapacitySheet(store: store) }
        .sheet(isPresented: $store.isInvitationsVisible) { ProjectInvitationsSheet(store: store) }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $store.viewMode) {
                Text(strings[.viewWhatMatters]).tag(ProjectsStore.ViewMode.focus)
                Text(strings[.viewAllProjects]).tag(ProjectsStore.ViewMode.all)
            }
            .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(width: 230)
            if store.viewMode == .all {
                Picker("", selection: $store.statusFilter) {
                    ForEach(ProjectLifecycleStatus.allCases, id: \.self) { status in Text(strings.projectStatusLabel(status)).tag(status) }
                }
                .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 130)
                ToDoSearchField(text: $store.searchQuery, placeholder: strings[.projectSearchPlaceholder], isBusy: store.isProjectsLoading && !store.projects.isEmpty)
                    .frame(maxWidth: 260)
            }
            Spacer()
            SwiftUI.Button(action: { store.isCreateVisible = true }) { Label(strings[.newProject], systemImage: "plus") }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            ToDoIconButton(systemImage: "speedometer", help: strings[.capacitySettings]) { store.openSettings() }
            ToDoIconButton(systemImage: "envelope", help: strings[.pendingInvitations], isActive: !store.pendingInvitations.isEmpty) { store.isInvitationsVisible = true }
            ToDoIconButton(systemImage: "arrow.clockwise", help: strings[.refresh]) { store.refresh() }
        }
    }
}

// MARK: - What matters

private struct ProjectsFocusView: View {
    @ObservedObject var store: ProjectsStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        Group {
            if store.isInitialPortfolioLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let groups = store.actionGroups
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if store.portfolio?.isOvercommitted == true {
                            OvercommittedBanner(strings: strings, mostAtRisk: groups.askForExtension)
                        }
                        if groups.isEmpty {
                            emptyState
                        } else {
                            section(.askForExtension, groups.askForExtension, limit: nil)
                            RecommendedTodaySummary(strings: strings, projects: Array(groups.startNow.prefix(PortfolioGrouping.startNowVisibleLimit)))
                            section(.startNow, groups.startNow, limit: PortfolioGrouping.startNowVisibleLimit)
                            section(.backBurner, groups.backBurner, limit: PortfolioGrouping.backBurnerVisibleLimit)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func section(_ kind: PortfolioActionSection, _ projects: [PortfolioProject], limit: Int?) -> some View {
        if !projects.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(accent(kind)).frame(width: 4, height: 16)
                    Text(strings.sectionLabel(kind).uppercased()).font(.system(size: 11, weight: .bold)).foregroundColor(accent(kind))
                    Text("\(projects.count)").font(.system(size: 11)).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(accent(kind).opacity(0.08)).cornerRadius(6)
                ProjectCardGrid(cards: (limit.map { Array(projects.prefix($0)) } ?? projects).map { project in
                    AnyView(RiskProjectCard(store: store, project: project))
                })
            }
        }
    }

    private func accent(_ kind: PortfolioActionSection) -> Color {
        switch kind {
        case .askForExtension: return ToDoTheme.overdue
        case .startNow: return ToDoTheme.accent
        case .backBurner: return ToDoTheme.neutral
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal").font(.system(size: 36)).foregroundColor(ToDoTheme.good)
            Text(strings[.focusEmptyTitle]).font(.headline)
            Text(strings[.focusEmptyDescription]).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            SwiftUI.Button(action: { store.viewMode = .all }) { Text(strings[.browseAllProjects]) }
                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

/// Two-column card grid (macOS 11 has no `Grid`).
private struct ProjectCardGrid: View {
    let cards: [AnyView]
    private static let columns = 2

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<rowCount, id: \.self) { row in
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<ProjectCardGrid.columns, id: \.self) { column in
                        let index = row * ProjectCardGrid.columns + column
                        if index < cards.count { cards[index].frame(maxWidth: .infinity) } else { Color.clear.frame(maxWidth: .infinity, maxHeight: 0) }
                    }
                }
            }
        }
    }

    private var rowCount: Int { (cards.count + ProjectCardGrid.columns - 1) / ProjectCardGrid.columns }
}

private struct OvercommittedBanner: View {
    let strings: ToDoStrings
    let mostAtRisk: [PortfolioProject]

    var body: some View {
        let named = mostAtRisk.map { project -> PortfolioProject in var copy = project; copy.name = strings.projectName(project.name); return copy }
        let names = PortfolioGrouping.overcommittedNames(named) { strings.format(.overcommittedAndMore, ToDoStrings.countToken, String($0)) }
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ToDoTheme.overdue)
            VStack(alignment: .leading, spacing: 3) {
                Text(strings[.overcommittedTitle]).font(.system(size: 13, weight: .bold))
                Text(names.isEmpty ? strings[.overcommittedDescriptionFallback] : strings.format(.overcommittedDescription, ToDoStrings.projectsToken, names))
                    .font(.system(size: 12)).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(ToDoTheme.overdue.opacity(0.1))
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

/// Web `RecommendedTodaySummary`: "Spend ~1h on X" for the Start-now projects.
private struct RecommendedTodaySummary: View {
    let strings: ToDoStrings
    let projects: [PortfolioProject]

    private var items: [(name: String, hours: Double)] {
        projects.compactMap { project in PortfolioGrouping.recommendedDailyHours(project).map { (strings.projectName(project.name), $0) } }
    }

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            let visible = Array(items.prefix(PortfolioGrouping.recommendedTodayVisibleLimit))
            let total = items.reduce(0) { $0 + $1.hours }
            VStack(alignment: .leading, spacing: 4) {
                Text(strings[.recommendedTodayTitle]).font(.system(size: 12, weight: .semibold))
                ForEach(Array(visible.enumerated()), id: \.offset) { _, item in
                    Text(strings.format(.recommendedTodayItem, [ToDoStrings.durationToken: label(item.hours), ToDoStrings.projectToken: item.name]))
                        .font(.system(size: 12))
                }
                if items.count > visible.count {
                    Text(strings.format(.recommendedTodayMore, ToDoStrings.countToken, String(items.count - visible.count)))
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
                Text(strings.format(.recommendedTodayTotal, ToDoStrings.durationToken, label(total)))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(10)
            .background(ToDoTheme.accent.opacity(0.08))
            .cornerRadius(ToDoTheme.cornerRadius)
        }
    }

    private func label(_ hours: Double) -> String {
        let parts = PortfolioGrouping.durationParts(hours: hours)
        return ToDoDates.durationLabel(hours: parts.hours, minutes: parts.minutes)
    }
}

// MARK: - Cards

/// Web `RiskProjectCard` (portfolio) — name, bucket badge, NEXT task, due / effort / pace chips.
private struct RiskProjectCard: View {
    @ObservedObject var store: ProjectsStore
    let project: PortfolioProject
    @SwiftUI.State private var isDuePopoverShown = false
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                SwiftUI.Button(action: { store.open(portfolioProject: project) }) {
                    Text(strings.projectName(project.name)).font(.system(size: 14, weight: .semibold)).lineLimit(1).foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                Spacer()
                ProjectBucketBadge(strings: strings, bucket: project.portfolioBucket)
            }
            ProjectNextTaskRow(strings: strings, task: project.top_priority_task)
            ProjectCardFooter(strings: strings, risk: project, memberCount: nil, taskCount: nil, showBadges: true) {
                isDuePopoverShown = true
            }
            .popover(isPresented: $isDuePopoverShown, arrowEdge: .bottom) {
                ToDoDueDatePopover(strings: strings, currentDue: project.due_date) { day in
                    isDuePopoverShown = false
                    store.setDueDate(projectId: project.id, day: day)
                }
            }
        }
        .padding(12)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius).stroke(ToDoTheme.bucketColor(project.portfolioBucket).opacity(0.5)))
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

/// Web `ProjectCard` (All projects) — adds description, lifecycle badge, member / task counts.
private struct AllProjectCard: View {
    @ObservedObject var store: ProjectsStore
    let project: Project
    @SwiftUI.State private var isDuePopoverShown = false
    private var strings: ToDoStrings { store.strings }
    private var risk: PortfolioProject? { store.risksById[project.id] }
    private var isMember: Bool {
        guard let owner = project.owner_id, let me = appdelegate?.user?.userId, !me.isEmpty else { return false }
        return owner != me
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                if let icon = project.icon, !icon.isEmpty { Text(icon) }
                SwiftUI.Button(action: { store.open(project) }) {
                    Text(strings.projectName(project.name)).font(.system(size: 14, weight: .semibold)).lineLimit(1).foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                if isMember { ToDoChip(text: strings[.memberBadge], systemImage: "person.2") }
                if project.lifecycleStatus != .active { ToDoChip(text: strings.projectStatusLabel(project.lifecycleStatus)) }
                Spacer()
                if let risk = risk {
                    ProjectBucketBadge(strings: strings, bucket: risk.portfolioBucket)
                } else if project.due_date == nil {
                    SwiftUI.Button(action: { isDuePopoverShown = true }) { ToDoChip(text: strings[.setDueDate], systemImage: "calendar") }
                        .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                }
            }
            if let description = project.description, !description.isEmpty {
                Text(description).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
            }
            ProjectNextTaskRow(strings: strings, task: project.top_priority_task)
            ProjectCardFooter(strings: strings, risk: risk ?? placeholderRisk, memberCount: project.members?.count ?? 0,
                              taskCount: project.task_count ?? 0, showBadges: false) { isDuePopoverShown = true }
                .popover(isPresented: $isDuePopoverShown, arrowEdge: .bottom) {
                    ToDoDueDatePopover(strings: strings, currentDue: project.due_date) { day in
                        isDuePopoverShown = false
                        store.setDueDate(projectId: project.id, day: day)
                    }
                }
        }
        .padding(12)
        .background(ToDoTheme.card)
        .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius).stroke(ToDoTheme.separator))
        .cornerRadius(ToDoTheme.cornerRadius)
    }

    /// Projects outside the portfolio (completed/archived/synced) have no risk row.
    private var placeholderRisk: PortfolioProject {
        PortfolioProject(id: project.id, name: project.name, due_date: project.due_date, importance: project.importance,
                         required_hours: nil, risk_score: nil, bucket: PortfolioBucket.noDeadline.rawValue, deficit_hours: nil,
                         days_until_due: nil, latest_start: nil, badges: nil, top_priority_task: project.top_priority_task)
    }
}

private struct ProjectBucketBadge: View {
    let strings: ToDoStrings
    let bucket: PortfolioBucket

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(ToDoTheme.bucketColor(bucket)).frame(width: 7, height: 7)
            Text(strings.bucketLabel(bucket))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(ToDoTheme.bucketColor(bucket))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(ToDoTheme.bucketColor(bucket).opacity(0.14))
        .cornerRadius(10)
    }
}

/// Web `TopPriorityTaskRow`: "NEXT · task title · TOP 4.3".
private struct ProjectNextTaskRow: View {
    let strings: ToDoStrings
    let task: ProjectTopPriorityTask?
    private static let highTier = 8.0
    private static let mediumTier = 5.0

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(ToDoTheme.accent).frame(width: 3)
            if let task = task {
                Text(strings[.nextTask].uppercased()).font(.system(size: 9, weight: .bold)).foregroundColor(ToDoTheme.accent)
                Text(task.title).font(.system(size: 12)).lineLimit(1).help(task.title)
                Spacer()
                if let score = task.top_score {
                    ToDoChip(text: "\(strings[.topShort]) \(ToDoScoring.rounded(score))", systemImage: "star.fill", tint: tier(score))
                        .help(strings[.topScoreTooltip])
                }
            } else {
                Text(strings[.nextTaskEmpty]).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(2)
                Spacer()
            }
        }
        .frame(minHeight: 22)
    }

    private func tier(_ score: Double) -> Color {
        if score >= ProjectNextTaskRow.highTier { return ToDoTheme.today }
        if score >= ProjectNextTaskRow.mediumTier { return ToDoTheme.accent }
        return ToDoTheme.neutral
    }
}

/// Web `ProjectCardFooter`: due (editable) · effort · pace · badges · members · tasks.
private struct ProjectCardFooter: View {
    let strings: ToDoStrings
    let risk: PortfolioProject
    let memberCount: Int?
    let taskCount: Int?
    let showBadges: Bool
    let onEditDue: () -> Void

    var body: some View {
        // No flow layout on macOS 11: dates / effort / pace on one row, badges and counts on a second.
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                SwiftUI.Button(action: onEditDue) {
                    ToDoChip(text: risk.hasDueDate ? strings.format(.dueWithDate, ToDoStrings.dateToken, strings.dueLabel(risk.due_date)) : strings[.setDueDate],
                             systemImage: "calendar", tint: ToDoTheme.bucketColor(risk.portfolioBucket))
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.editDueDate])
                if risk.requiredHours > 0 {
                    ToDoChip(text: strings.format(.requiredHours, ToDoStrings.durationToken, ToDoDates.durationLabel(seconds: Int(risk.requiredHours * 3600))), systemImage: "clock")
                }
                if let daily = PortfolioGrouping.recommendedDailyHours(risk) {
                    let parts = PortfolioGrouping.durationParts(hours: daily)
                    let label = ToDoDates.durationLabel(hours: parts.hours, minutes: parts.minutes)
                    ToDoChip(text: strings.format(.recommendedDaily, ToDoStrings.durationToken, label), systemImage: "bolt")
                        .help(strings.format(.recommendedDailyTooltip, ToDoStrings.durationToken, label))
                }
                Spacer(minLength: 0)
            }
            if hasSecondRow {
                HStack(spacing: 6) {
                if showBadges {
                    ForEach(orderedBadges, id: \.self) { badge in
                        ToDoChip(text: strings.badgeLabel(badge), systemImage: badgeIcon(badge), tint: badgeTint(badge))
                    }
                }
                if let members = memberCount {
                    ToDoChip(text: strings.format(.membersCount, ToDoStrings.countToken, String(members)), systemImage: "person.2")
                }
                if let tasks = taskCount {
                    ToDoChip(text: strings.format(.tasksCount, ToDoStrings.countToken, String(tasks)), systemImage: "checklist")
                }
                Spacer(minLength: 0)
                }
            }
        }
        .padding(.top, 4)
        .overlay(Rectangle().fill(ToDoTheme.separator).frame(height: 1), alignment: .top)
    }

    private var hasSecondRow: Bool { (showBadges && !orderedBadges.isEmpty) || memberCount != nil || taskCount != nil }

    /// Web `BADGE_DISPLAY_ORDER`: start now → overcommitted → sacrifice.
    private var orderedBadges: [PortfolioBadge] {
        [.startNow, .overcommitted, .sacrifice].filter { risk.badgeList.contains($0) }
    }

    private func badgeIcon(_ badge: PortfolioBadge) -> String {
        switch badge {
        case .overcommitted: return "exclamationmark.triangle"
        case .startNow: return "bolt.fill"
        case .sacrifice: return "minus.circle"
        }
    }

    private func badgeTint(_ badge: PortfolioBadge) -> Color {
        switch badge {
        case .overcommitted: return ToDoTheme.overdue
        case .startNow: return ToDoTheme.accent
        case .sacrifice: return ToDoTheme.neutral
        }
    }
}

// MARK: - All projects

private struct ProjectsAllView: View {
    @ObservedObject var store: ProjectsStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        Group {
            if store.isProjectsLoading && store.projects.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.emptyVariant != .none {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ProjectCardGrid(cards: store.sortedProjects.map { AnyView(AllProjectCard(store: store, project: $0)) })
                        if store.isLoadingMore {
                            ProgressView().scaleEffect(0.6).frame(maxWidth: .infinity)
                        } else if store.hasNextPage {
                            SwiftUI.Button(action: { store.loadMore() }) { Text(strings[.loadMore]) }
                                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder").font(.system(size: 36)).foregroundColor(.secondary)
            switch store.emptyVariant {
            case .search:
                Text(strings[.noMatchingProjects]).font(.headline)
                Text(strings[.tryDifferentSearch]).font(.subheadline).foregroundColor(.secondary)
                SwiftUI.Button(action: { store.searchQuery = "" }) { Text(strings[.clear]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
            case .completed:
                Text(strings[.noCompletedProjects]).font(.headline)
                SwiftUI.Button(action: { store.statusFilter = .active }) { Text(strings.projectStatusLabel(.active)) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
            case .archived:
                Text(strings[.noArchivedProjects]).font(.headline)
                SwiftUI.Button(action: { store.statusFilter = .active }) { Text(strings.projectStatusLabel(.active)) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
            default:
                Text(strings[.noProjectsYet]).font(.headline)
                Text(strings[.createFirstProject]).font(.subheadline).foregroundColor(.secondary)
                SwiftUI.Button(action: { store.isCreateVisible = true }) { Label(strings[.newProject], systemImage: "plus") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sheets

/// Web `CreateProjectModal`: name plus a due date (optional, but asked up front — the portfolio
/// can only rank a project with a deadline).
struct ProjectCreateSheet: View {
    @ObservedObject var store: ProjectsStore
    @SwiftUI.State private var name = ""
    @SwiftUI.State private var dueDate: Date? = nil
    private static let nameMaxLength = 80
    private var strings: ToDoStrings { store.strings }
    private var canCreate: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= ProjectCreateSheet.nameMaxLength && !store.isCreatingProject
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings[.newProject]).font(.title2).bold()
            TextField(strings[.projectNamePlaceholder], text: $name, onCommit: create).textFieldStyle(RoundedBorderTextFieldStyle())
            HStack(spacing: 6) {
                Text(strings[.due]).font(.system(size: 12, weight: .semibold))
                Text(strings[.optional]).font(.system(size: 11)).foregroundColor(.secondary)
            }
            ToDoDueDateField(day: $dueDate, strings: strings)
            HStack {
                Spacer()
                SwiftUI.Button(action: { store.isCreateVisible = false }) { Text(strings[.cancel]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30)).keyboardShortcut(.cancelAction)
                SwiftUI.Button(action: create) { Text(store.isCreatingProject ? strings[.saving] : strings[.save]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30)).disabled(!canCreate)
            }
        }
        .padding(16)
        .frame(width: 520)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func create() {
        guard canCreate else { return }
        store.createProject(named: name, dueDate: dueDate) { _ in }
    }
}

/// Web `CapacitySettingsModal`: hours per weekday + planning horizon.
private struct ProjectCapacitySheet: View {
    @ObservedObject var store: ProjectsStore
    @SwiftUI.State private var hours: [Double] = Array(repeating: 4, count: PortfolioSettings.daysPerWeek)
    @SwiftUI.State private var horizon = 28
    @SwiftUI.State private var hasLoaded = false
    private static let maxHoursPerDay = 24.0
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings[.capacitySettings]).font(.title2).bold()
            if store.settings == nil && !hasLoaded {
                ProgressView().frame(maxWidth: .infinity)
            }
            Text(strings[.weeklyCapacity]).font(.system(size: 12, weight: .semibold))
            HStack(spacing: 8) {
                ForEach(0..<PortfolioSettings.daysPerWeek, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text(weekday(index)).font(.system(size: 11)).foregroundColor(.secondary)
                        TextField("", text: Binding(get: { formatted(hours[index]) }, set: { hours[index] = min(ProjectCapacitySheet.maxHoursPerDay, max(0, Double($0) ?? 0)) }))
                            .textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 48).multilineTextAlignment(.center)
                    }
                }
            }
            Text(strings.format(.weeklyTotal, ToDoStrings.hoursToken, formatted(hours.reduce(0, +)))).font(.system(size: 11)).foregroundColor(.secondary)
            HStack(spacing: 8) {
                Text(strings[.planningHorizon]).font(.system(size: 12, weight: .semibold))
                Picker("", selection: $horizon) {
                    ForEach(PortfolioSettings.horizonOptions, id: \.self) { days in
                        Text(strings.format(.horizonDays, ToDoStrings.daysToken, String(days))).tag(days)
                    }
                }
                .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 120)
            }
            HStack {
                Spacer()
                SwiftUI.Button(action: { store.isSettingsVisible = false }) { Text(strings[.cancel]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30)).keyboardShortcut(.cancelAction)
                SwiftUI.Button(action: { store.saveSettings(PortfolioSettings(weekly_capacity_hours: hours, planning_horizon_days: horizon)) }) {
                    Text(store.isSavingSettings ? strings[.saving] : strings[.save])
                }
                .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30)).disabled(store.isSavingSettings)
            }
        }
        .padding(16)
        .frame(width: 520)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(store.$settings) { settings in
            guard let settings = settings, !hasLoaded else { return }
            hasLoaded = true
            if settings.weekly_capacity_hours.count == PortfolioSettings.daysPerWeek { hours = settings.weekly_capacity_hours }
            // Fall back to the default when the server sends a horizon that isn't one of the picker's
            // options, otherwise the segmented control has no matching tag (blank selection) and Save
            // would round-trip the off-list value.
            horizon = PortfolioSettings.horizonOptions.contains(settings.planning_horizon_days) ? settings.planning_horizon_days : 28
        }
    }

    private func weekday(_ index: Int) -> String {
        let names = strings.list(.weekdaysShort)
        return index < names.count ? names[index] : String(index + 1)
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

private struct ProjectInvitationsSheet: View {
    @ObservedObject var store: ProjectsStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(strings[.pendingInvitations]).font(.title2).bold()
                Spacer()
                SwiftUI.Button(action: { store.isInvitationsVisible = false }) { Text(strings[.close]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30)).keyboardShortcut(.cancelAction)
            }
            if store.pendingInvitations.isEmpty {
                Text(strings[.noPendingInvitations]).font(.system(size: 12)).foregroundColor(.secondary).frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                ForEach(store.pendingInvitations) { project in
                    HStack {
                        Text(strings.projectName(project.name)).font(.system(size: 13, weight: .medium))
                        Spacer()
                        SwiftUI.Button(action: { store.respondToInvitation(project, accept: false) }) { Text(strings[.decline]) }
                            .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                        SwiftUI.Button(action: { store.respondToInvitation(project, accept: true) }) { Text(strings[.accept]) }
                            .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 26))
                    }
                    .padding(10).background(ToDoTheme.card).cornerRadius(ToDoTheme.cornerRadius)
                }
            }
        }
        .padding(16)
        .frame(width: 480)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
