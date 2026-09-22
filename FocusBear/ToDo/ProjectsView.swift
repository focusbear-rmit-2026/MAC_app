//
//  ProjectsView.swift
//  Focus Bear
//
//  The Projects tab — the native version of the web's project portfolio (`dashboard/projects`):
//  "What matters" (local forecast regrouped into Ask for an extension / Start now /
//  Backburner, with the Overcommitted banner and today's pace) and "All projects" (`GET /projects`,
//  searched, filtered by lifecycle status, sorted by risk). Tapping a project filters the task list.
//

import SwiftUI
import AppKit

/// The "Still achievable" / "Backburner" separators were 11pt, which read as a caption rather than a
/// divider between two groups of projects — they did not stand out enough to see where one section
/// ended (report 2026-09-15_20-07-44). The colour rail grows with the text so the two stay in step.
enum ProjectsSectionHeader {
    static let titleSize: CGFloat = 15
    static let countSize: CGFloat = 13
    static let railWidth: CGFloat = 5
    static let railHeight: CGFloat = 20
    /// The title was drawn in the section's own accent, which for Backburner is
    /// `tertiaryLabelColor` — the faintest grey the app has, on a tinted background, at which point
    /// the heading is barely legible (report 2026-09-15_20-07-44, follow-up). The section's colour
    /// still reads: it is carried by the rail and the background tint, which have far more area than
    /// the letterforms and so carry it better anyway. `labelColor` rather than literal black, so
    /// this stays legible in dark mode instead of trading one contrast bug for another.
    static let titleColor = Color(NSColor.labelColor)
}

struct ProjectsTabView: View {
    @ObservedObject var store: ProjectsStore
    @ObservedObject var todoStore: ToDoStore
    @ObservedObject private var forecast: LocalForecastStore
    init(store: ProjectsStore, todoStore: ToDoStore) {
        self.store = store
        self.todoStore = todoStore
        self.forecast = store.forecast
    }
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let detail = store.detail {
                ProjectDetailView(store: detail, todoStore: todoStore, onBack: { store.closeDetail() },
                                  onShowInTaskList: { store.showInTaskList(detail.project) })
            } else {
                toolbar
                if store.viewMode == .forecast {
                    LocalTimeForecastView(store: store.forecast)
                } else if store.viewMode == .focus {
                    ProjectsFocusView(store: store, todoStore: todoStore)
                } else { ProjectsAllView(store: store) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // No reschedule sheet here any more: it moved to the Tasks list, which is where the PO asked
        // for it ("rather than Projects screen", report 2026-09-16_06-38-30). It is one sheet on one
        // shared `LocalForecastStore`, so presenting it from both tabs would be two call sites for
        // one piece of state — and "rather than" was a move, not an addition.
        .sheet(isPresented: $store.isCreateVisible) { ProjectCreateSheet(store: store) }
        .sheet(isPresented: $store.isSettingsVisible) { ProjectCapacitySheet(store: store) }
        .sheet(item: $store.mergeSource) { source in ProjectMergeSheet(store: store, source: source) }
        .sheet(isPresented: $store.isInvitationsVisible) { ProjectInvitationsSheet(store: store) }
    }

    /// Narrow the list to one tag — the point of tagging several projects `#phd` in the first place.
    ///
    /// `SearchableComboBoxField` is right here even though it was wrong for *entering* a tag: this
    /// picker only ever chooses among tags that already exist, which is exactly what a control that
    /// resolves typed text to a known option is for. The entry field in the project header has to
    /// accept a tag that does not exist yet, which that control cannot express. Two jobs, two
    /// controls — not an inconsistency to tidy away.
    ///
    /// Hidden entirely until the user has tagged something, so an unused feature costs no toolbar room.
    ///
    /// `.whenResolved`: the list reloads the moment the box names exactly one tag — typing `phd` in
    /// full is enough, no second gesture — while text that still matches several tags does nothing
    /// at all (report project-tags-2026-09-16_08-53-53; see `applyTagFilter` for the history).
    private var tagFilterPicker: some View {
        SearchableComboBoxField(options: store.knownTags.map { SearchableComboBoxField.Option(id: $0, name: $0) },
                                selectedId: Binding(get: { store.tagFilterSelection },
                                                    set: { store.applyTagFilter($0) }),
                                clearedOptionTitle: strings[.allTags],
                                commitPolicy: .whenResolved)
            .frame(width: ProjectsTabView.tagFilterWidth)
            .help(strings[.filterByTag])
    }

    private static let tagFilterWidth: CGFloat = 150

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $store.viewMode) {
                    Text(strings[.viewWhatMatters]).tag(ProjectsStore.ViewMode.focus)
                    Text(strings[.viewAllProjects]).tag(ProjectsStore.ViewMode.all)
                    Text(ForecastText[.tab]).tag(ProjectsStore.ViewMode.forecast)
                }
                .pickerStyle(SegmentedPickerStyle()).labelsHidden().frame(maxWidth: 400)
                Spacer()
                ToDoIconButton(systemImage: "envelope", help: strings[.pendingInvitations], isActive: !store.pendingInvitations.isEmpty) { store.isInvitationsVisible = true }
                ToDoIconButton(systemImage: "arrow.clockwise", help: strings[.refresh]) { store.refresh() }
                ForecastCapacitySettingsButton(store: forecast)
            }
            HStack(spacing: 8) {
                SwiftUI.Button(action: { store.isCreateVisible = true }) { Label(strings[.newProject], systemImage: "plus") }
                    .buttonStyle(AppOrangeButtonStyle(secondary: false, height: 30))
                Spacer()
            }
            // "What matters" searches the portfolio rows it already has; "All projects" also asks
            // the server. With 128 backburner projects, finding one by scrolling is hopeless
            // (report 2026-09-11_21-39-35).
            if store.viewMode != .forecast {
                HStack(spacing: 8) {
                    if store.viewMode == .all {
                        Picker("", selection: $store.statusFilter) {
                            ForEach(ProjectLifecycleStatus.allCases, id: \.self) { status in Text(strings.projectStatusLabel(status)).tag(status) }
                        }
                        .labelsHidden().pickerStyle(MenuPickerStyle()).frame(width: 130)
                    }
                    if store.viewMode == .all, !store.knownTags.isEmpty { tagFilterPicker }
                    ToDoSearchField(text: $store.searchQuery, placeholder: strings[.projectSearchPlaceholder], isBusy: store.isProjectsLoading && !store.projects.isEmpty)
                        .frame(maxWidth: 300)
                }
            }
        }
    }

}

// MARK: - What matters

private struct ProjectsFocusView: View {
    @ObservedObject var store: ProjectsStore
    /// Only for the project icons: `/portfolio` rows carry no icon, and the Projects list itself is
    /// paged nine at a time, so the icon comes from the To-do store's full active-project catalogue.
    @ObservedObject var todoStore: ToDoStore
    /// Sections the user has expanded past their visible limit, for this visit to the screen.
    @SwiftUI.State private var expandedSections: Set<PortfolioActionSection> = []
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForecastStatus(store: store.forecast)
            // Groups come from the local forecast when it has run, and from the server's portfolio
            // rows when it hasn't — the screen stays usable either way (report 2026-09-13_20-05-06).
            if !store.isInitialPortfolioLoading {
                let groups = store.actionGroups
                let assessed = store.assessedProjectIDs
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if store.localPortfolio?.isOvercommitted == true {
                            OvercommittedBanner(strings: strings, mostAtRisk: groups.askForExtension)
                        }
                        if groups.isEmpty {
                            emptyState
                        } else {
                            section(.askForExtension, matching(groups.askForExtension), limit: nil, assessedIDs: assessed)
                            section(.startNow, matching(groups.startNow), limit: PortfolioGrouping.startNowVisibleLimit, assessedIDs: assessed)
                            section(.backBurner, matching(groups.backBurner), limit: PortfolioGrouping.backBurnerVisibleLimit, assessedIDs: assessed)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { store.forecast.refreshIfNeeded() }
    }

    private func matching(_ projects: [PortfolioProject]) -> [PortfolioProject] {
        PortfolioGrouping.matching(projects, query: store.debouncedSearch)
    }

    @ViewBuilder
    private func section(_ kind: PortfolioActionSection, _ projects: [PortfolioProject], limit: Int?, assessedIDs: Set<String>) -> some View {
        if !projects.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(accent(kind))
                        .frame(width: ProjectsSectionHeader.railWidth, height: ProjectsSectionHeader.railHeight)
                    Text(strings.sectionLabel(kind).uppercased())
                        .font(Font(getSemiBoldFont(size: ProjectsSectionHeader.titleSize)))
                        .foregroundColor(ProjectsSectionHeader.titleColor)
                    Text("\(projects.count)")
                        .font(Font(getRegularFont(size: ProjectsSectionHeader.countSize)))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(accent(kind).opacity(0.08)).cornerRadius(6)
                let visible = expandedSections.contains(kind) ? projects : (limit.map { Array(projects.prefix($0)) } ?? projects)
                ProjectCardGrid(cards: visible.map { project in
                    AnyView(RiskProjectCard(store: store, project: project, isAssessed: assessedIDs.contains(project.id),
                                            icon: store.forecast.projects.first { $0.id == project.id }?.iconEmoji ?? todoStore.project(id: project.id)?.iconEmoji,
                                            section: kind))
                })
                if visible.count < projects.count || expandedSections.contains(kind) && limit.map({ projects.count > $0 }) == true {
                    SwiftUI.Button(action: { toggle(kind) }) {
                        Text(expandedSections.contains(kind)
                             ? strings[.showFewerProjects]
                             : strings.format(.showAllProjects, ToDoStrings.countToken, String(projects.count)))
                    }
                    .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                    .font(Font(getSemiBoldFont(size: 12))).foregroundColor(ToDoTheme.accent)
                }
            }
        }
    }

    private func toggle(_ kind: PortfolioActionSection) {
        if expandedSections.contains(kind) { expandedSections.remove(kind) } else { expandedSections.insert(kind) }
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
                Text(strings[.overcommittedTitle]).font(Font(getSemiBoldFont(size: 13)))
                Text(names.isEmpty ? strings[.overcommittedDescriptionFallback] : strings.format(.overcommittedDescription, ToDoStrings.projectsToken, names))
                    .font(Font(getRegularFont(size: 12))).fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(12)
        .background(ToDoTheme.overdue.opacity(0.1))
        .cornerRadius(ToDoTheme.cornerRadius)
    }
}

// MARK: - Cards

/// Web `RiskProjectCard` (portfolio) — name, bucket badge, NEXT task, due / effort / pace chips.
private struct RiskProjectCard: View {
    @ObservedObject var store: ProjectsStore
    let project: PortfolioProject
    let isAssessed: Bool
    /// Resolved by the caller from the project catalogue — `/portfolio` rows don't carry one.
    let icon: String?
    /// The heading this card sits under, when it has one; badges that merely repeat it are dropped.
    var section: PortfolioActionSection? = nil
    @SwiftUI.State private var isDuePopoverShown = false
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 6) {
                ProjectIconGlyph(icon: icon)
                SwiftUI.Button(action: { store.open(portfolioProject: project) }) {
                    Text(strings.projectName(project.name)).font(Font(getSemiBoldFont(size: 14))).lineLimit(1).foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                Spacer()
                if isAssessed {
                    ProjectBucketBadge(strings: strings, bucket: project.portfolioBucket)
                }
            }
            ProjectNextTaskRow(strings: strings, task: store.nextTask(for: project.id), isPending: store.isNextTaskPending(project.id))
            if let metadata = store.metadata(for: project.id), metadata.isSynced {
                Text(strings.projectSyncSource(metadata)).font(.system(size: 12)).foregroundColor(.secondary)
            }
            ForecastProjectEstimate(store: store.forecast, projectID: project.id)
            if let finish = project.projected_completion_date.flatMap(ToDoDates.parse) {
                Text(ForecastText.format(.completeBy, ["<DATE>": ForecastText.date(finish)]))
                    .font(Font(getRegularFont(size: 12))).foregroundColor(.secondary)
            }
            ProjectCardFooter(strings: strings, risk: project, memberCount: nil, taskCount: nil, showBadges: true,
                              section: section, riskTint: isAssessed ? nil : ToDoTheme.neutral) {
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
        .overlay(RoundedRectangle(cornerRadius: ToDoTheme.cornerRadius).stroke((isAssessed ? ToDoTheme.bucketColor(project.portfolioBucket) : ToDoTheme.neutral).opacity(0.5)))
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
                ProjectIconGlyph(icon: project.iconEmoji)
                SwiftUI.Button(action: { store.open(project) }) {
                    Text(strings.projectName(project.name)).font(.system(size: 14, weight: .semibold)).lineLimit(1).foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                if isMember { ToDoChip(text: strings[.memberBadge], systemImage: "person.2") }
                if project.lifecycleStatus != .active { ToDoChip(text: strings.projectStatusLabel(project.lifecycleStatus)) }
                Spacer()
                ProjectCardActions(store: store, project: project)
            }
            if let description = project.description, !description.isEmpty {
                Text(description).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
            }
            if project.isSynced {
                Text(strings.projectSyncSource(project)).font(.system(size: 12)).foregroundColor(.secondary)
            }
            if let completion = store.completion(for: project) {
                Text(strings[.projectTaskCompletion]
                    .replacingOccurrences(of: "<PERCENT>", with: String(completion.percent))
                    .replacingOccurrences(of: "<DONE>", with: String(completion.completed))
                    .replacingOccurrences(of: "<TOTAL>", with: String(completion.total)))
                    .font(.system(size: 12, weight: .semibold))
            }
            ProjectNextTaskRow(strings: strings, task: store.nextTask(for: project.id), isPending: store.isNextTaskPending(project.id))
            ForecastProjectEstimate(store: store.forecast, projectID: project.id)
            ProjectCardFooter(strings: strings, risk: placeholderRisk, memberCount: project.members?.count ?? 0,
                              taskCount: store.forecast.unfinishedCountsByProject[project.id]
                                  ?? project.uncompleted_task_count ?? project.task_count ?? 0,
                              countsUnfinishedOnly: store.forecast.unfinishedCountsByProject[project.id] != nil
                                  || project.uncompleted_task_count != nil,
                              showBadges: false) { isDuePopoverShown = true }
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
                         days_until_due: nil, latest_start: nil, badges: nil)
    }
}

private struct ProjectCardActions: View {
    @ObservedObject var store: ProjectsStore
    let project: Project
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        Menu {
            SwiftUI.Button(strings[.edit]) { store.open(project) }
            if store.canManage(project) {
                if !project.isSynced {
                    SwiftUI.Button(strings[.mergeProject]) { store.beginMerge(project) }
                }
                if project.lifecycleStatus != .completed {
                    SwiftUI.Button(strings[.markCompleteProject]) { store.setLifecycle(project, status: .completed) }
                }
                if project.lifecycleStatus != .archived {
                    SwiftUI.Button(strings[.archiveProject]) { store.setLifecycle(project, status: .archived) }
                }
                if project.lifecycleStatus != .active {
                    SwiftUI.Button(strings[.restoreProject]) { store.setLifecycle(project, status: .active) }
                }
            }
        } label: {
            Image(systemName: "ellipsis").frame(width: 24, height: 24).contentShape(Rectangle())
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .fixedSize()
        .help(strings[.moreOptions])
        .accessibilityLabel(strings[.moreOptions])
        .disabled(store.updatingProjectIDs.contains(project.id))
    }
}

/// A project's emoji at a fixed width, with a muted folder in its place when the project has none.
/// The fixed width is the point: in a grid of cards, an icon on some and nothing on others would
/// leave the names starting at two different left edges.
struct ProjectIconGlyph: View {
    let icon: String?
    var size: CGFloat = ProjectIconGlyph.defaultSize

    static let defaultSize: CGFloat = 14

    var body: some View {
        Group {
            if let icon = icon, !icon.isEmpty {
                Text(icon).font(.system(size: size))
            } else {
                Image(systemName: "folder").font(.system(size: size * ProjectIconGlyph.placeholderScale)).foregroundColor(ToDoTheme.neutral)
            }
        }
        .frame(width: size * ProjectIconGlyph.slotScale, alignment: .center)
    }

    /// SF Symbols run visually larger than an emoji at the same point size.
    private static let placeholderScale: CGFloat = 0.85
    private static let slotScale: CGFloat = 1.3
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
    /// The project's to-dos are still in flight — a blank row beats claiming there is no next task.
    let isPending: Bool
    private static let highTier = 8.0
    private static let mediumTier = 5.0

    var body: some View {
        HStack(spacing: 6) {
            Rectangle().fill(ToDoTheme.accent).frame(width: 3)
            if isPending {
                Spacer()
            } else if let task = task {
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
    /// Whether `taskCount` is the unfinished tasks rather than every task the project has ever had.
    /// A project whose only task is done said "1 tasks" (report 2026-09-13_21-20-29).
    var countsUnfinishedOnly = false
    let showBadges: Bool
    var section: PortfolioActionSection? = nil
    var riskTint: Color? = nil
    let onEditDue: () -> Void

    var body: some View {
        // No flow layout on macOS 11: dates / effort / pace on one row, badges and counts on a second.
        VStack(alignment: .leading, spacing: 4) {
            if risk.hasScheduleBreakdown { scheduledLine }
            HStack(spacing: 6) {
                SwiftUI.Button(action: onEditDue) {
                    ToDoChip(text: risk.hasDueDate ? strings.format(.dueWithDate, ToDoStrings.dateToken, strings.dueLabel(risk.due_date)) : strings[.setDueDate],
                             systemImage: "calendar", tint: riskTint ?? ToDoTheme.bucketColor(risk.portfolioBucket))
                }
                .buttonStyle(PlainButtonStyle()).pointingHandCursor()
                .help(strings[.editDueDate])
                if risk.requiredHours > 0 {
                    // "project effort" read as the project's whole size; it is only what is left,
                    // the server having excluded finished tasks (report 2026-09-11_20-39-23).
                    ToDoChip(text: strings.format(.requiredHours, ToDoStrings.durationToken, ToDoDates.durationLabel(seconds: Int(risk.requiredHours * 3600))), systemImage: "clock")
                        .help(strings[.requiredHoursTooltip])
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
                    ToDoChip(text: strings.format(countsUnfinishedOnly ? .tasksToDoCount : .tasksCount,
                                                  ToDoStrings.countToken, String(tasks)), systemImage: "checklist")
                }
                Spacer(minLength: 0)
                }
            }
        }
        .padding(.top, 4)
        .overlay(Rectangle().fill(ToDoTheme.separator).frame(height: 1), alignment: .top)
    }

    private var hasSecondRow: Bool { (showBadges && !orderedBadges.isEmpty) || memberCount != nil || taskCount != nil }

    /// "Scheduled 2h of 5h" from the backend's Day Plan simulation (#2418); amber when the plan
    /// can't finish the project by its due date.
    private var scheduledLine: some View {
        let scheduled = ToDoDates.durationLabel(seconds: Int((risk.scheduled_hours ?? 0) * 3600))
        let total = ToDoDates.durationLabel(seconds: Int(risk.requiredHours * 3600))
        let text = strings.format(.scheduledOfRequired, [ToDoStrings.scheduledToken: scheduled, ToDoStrings.totalToken: total])
        return HStack(spacing: 4) {
            Image(systemName: "calendar.badge.clock").font(.system(size: 10, weight: .semibold))
            Text(text).lineLimit(1)
        }
        .font(.system(size: 11))
        .foregroundColor(risk.plan_feasible == false ? ToDoTheme.today : .secondary)
        .help(projectedCompletionTooltip)
    }

    private var projectedCompletionTooltip: String {
        guard let projected = risk.projected_completion_date, !projected.isEmpty else { return "" }
        return strings.format(.projectedCompletionTooltip, ToDoStrings.dateToken, strings.dueLabel(projected))
    }

    /// Web `BADGE_DISPLAY_ORDER`: start now → overcommitted → sacrifice, then the Day Plan ones.
    private var orderedBadges: [PortfolioBadge] {
        let ordered = [PortfolioBadge.startNow, .overcommitted, .sacrifice, .unscheduled, .pushedBack]
            .filter { risk.badgeList.contains($0) }
        return PortfolioGrouping.badges(ordered, in: section)
    }

    private func badgeIcon(_ badge: PortfolioBadge) -> String {
        switch badge {
        case .overcommitted: return "exclamationmark.triangle"
        case .startNow: return "bolt.fill"
        case .sacrifice: return "minus.circle"
        case .unscheduled: return "calendar.badge.exclamationmark"
        case .pushedBack: return "arrow.uturn.forward"
        case .unknown: return "questionmark.circle"
        }
    }

    private func badgeTint(_ badge: PortfolioBadge) -> Color {
        switch badge {
        case .overcommitted: return ToDoTheme.overdue
        case .startNow: return ToDoTheme.accent
        case .sacrifice, .unknown: return ToDoTheme.neutral
        case .unscheduled: return ToDoTheme.today
        case .pushedBack: return ToDoTheme.info
        }
    }
}

// MARK: - All projects

private struct ProjectsAllView: View {
    @ObservedObject var store: ProjectsStore
    private var strings: ToDoStrings { store.strings }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if store.isProjectsLoading {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
                    Text(strings[.loading]).font(.caption).foregroundColor(.secondary)
                }
            }
            if store.emptyVariant != .none {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Construct and measure visible cards only; a large catalogue previously
                        // blocked the main thread before the loading indicator could paint.
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                            ForEach(store.sortedProjects) { project in
                                AllProjectCard(store: store, project: project)
                            }
                        }
                        if store.isLoadingMore {
                            ProgressView().scaleEffect(0.6).frame(maxWidth: .infinity)
                        } else if store.showsMoreProjects {
                            Text(store.strings[.projectAlphabeticalSubset]).font(.caption).foregroundColor(.secondary)
                            SwiftUI.Button(action: { store.loadMore() }) { Text(strings[.loadMore]) }
                                .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 26))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            case .tagFiltered:
                // Name the tag: a chosen tag leaves no text on screen the way a search box does, so
                // "no projects" alone would read as "you have no projects" rather than "one filter is
                // hiding them". Clearing the tag leaves any search in place.
                Text(strings.format(.noProjectsWithTag, ToDoStrings.titleToken, store.tagFilter)).font(.headline)
                if !store.searchQuery.isEmpty {
                    Text(strings[.tagAndSearchBothActive]).font(.subheadline).foregroundColor(.secondary)
                }
                SwiftUI.Button(action: { store.applyTagFilter(nil) }) { Text(strings[.showAllTags]) }
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
    @SwiftUI.State private var outcome: Int? = nil
    private static let nameMaxLength = 80
    private var strings: ToDoStrings { store.strings }
    private var canCreate: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= ProjectCreateSheet.nameMaxLength && !store.isCreatingProject
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings[.newProject]).font(.title2).bold()
            // NOT SwiftUI's `TextField(_:text:onCommit:)`: on macOS that fires `onCommit` when the
            // field merely loses focus, so clicking the due-date box below created the project and
            // dismissed the sheet mid-sentence ("when I clicked on the due date text box the modal
            // closed immediately", report 2026-09-15_20-13-26). `ReturnGuardTextField` commits on
            // Return only.
            ReturnGuardTextField(text: $name, placeholder: strings[.projectNamePlaceholder], onCommit: create)
            HStack(spacing: 6) {
                Text(strings[.due]).font(.system(size: 12, weight: .semibold))
                Text(strings[.optional]).font(.system(size: 11)).foregroundColor(.secondary)
            }
            ToDoDueDateField(day: $dueDate, strings: strings)
            // The create sheet rates a new project the same way the settings sheet does.
            ForecastOutcomePicker(wireValue: $outcome)
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
        store.createProject(named: name, dueDate: dueDate, outcome: outcome) { _ in }
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
            horizon = PortfolioSettings.horizonOptions.contains(settings.planning_horizon_days) ? settings.planning_horizon_days : settings.planning_horizon_days
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

/// "Merge into another project" — a searchable list of the user's other active projects. The list
/// is the whole active catalogue rather than the loaded page: the projects worth merging are the
/// near-duplicates, which are rarely both on screen at once (report 2026-09-11_07-31-36).
private struct ProjectMergeSheet: View {
    @ObservedObject var store: ProjectsStore
    let source: Project
    private var strings: ToDoStrings { store.strings }
    private var isMerging: Bool { store.mergingIntoProjectID != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings.format(.mergeProjectTitle, ToDoStrings.projectToken, source.name)).font(.title2).bold()
            Text(strings.format(.mergeProjectExplanation, ToDoStrings.projectToken, source.name))
                .font(.system(size: 12)).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            TextField(strings[.mergeProjectSearch], text: $store.mergeQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle()).disabled(isMerging)
            if store.isLoadingMergeCandidates {
                ProgressView().frame(maxWidth: .infinity)
            } else if store.visibleMergeCandidates.isEmpty {
                Text(strings[.mergeProjectNoDestinations]).font(.system(size: 12)).foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(store.visibleMergeCandidates) { project in
                            destinationRow(project)
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
            HStack {
                if isMerging {
                    ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
                    Text(strings[.mergeProjectRunning]).font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer()
                SwiftUI.Button(action: store.cancelMerge) { Text(strings[.cancel]) }
                    .buttonStyle(AppOrangeButtonStyle(secondary: true, height: 30))
                    .keyboardShortcut(.cancelAction).disabled(isMerging)
            }
        }
        .padding(16)
        .frame(width: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func destinationRow(_ project: Project) -> some View {
        SwiftUI.Button(action: { store.merge(into: project) }) {
            HStack(spacing: 8) {
                ProjectIconGlyph(icon: project.iconEmoji)
                Text(strings.projectName(project.name)).font(.system(size: 13)).lineLimit(1).foregroundColor(.primary)
                Spacer()
                if let count = project.task_count {
                    Text(strings.format(.tasksCount, ToDoStrings.countToken, String(count)))
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
                Text(strings[.mergeProjectConfirm]).font(.system(size: 11, weight: .semibold)).foregroundColor(ToDoTheme.accent)
            }
            .padding(.vertical, 6).padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle()).pointingHandCursor().disabled(isMerging)
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
