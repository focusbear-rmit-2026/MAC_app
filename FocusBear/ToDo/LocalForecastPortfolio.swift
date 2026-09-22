import Foundation

/// Adapts the local allocator to the existing grouped portfolio cards. These are presentation rows,
/// never server risk estimates or proposed schedule writes. Keep uncertain work visible without
/// giving it an unsupported "on track" / "critical" badge.
struct LocalForecastPortfolio {
    let rows: [PortfolioProject]
    let groups: PortfolioActionGroups
    let assessedProjectIDs: Set<String>
    let isOvercommitted: Bool

    static func make(projects: [Project], forecast: LocalTimeForecast.Result,
                     calendar: Calendar) -> LocalForecastPortfolio {
        let catalogue = Dictionary(projects.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let today = forecast.days.first?.date
        let horizon = forecast.days.last?.date
        var rows: [PortfolioProject] = []
        var groups = PortfolioActionGroups()
        var assessed = Set<String>()
        let epsilon = 0.000_001
        let unfinishedIDs = Set(forecast.tasks.filter { !$0.task.completed }.compactMap { $0.task.projectID })
        let startsTodayIDs = Set(forecast.tasks.flatMap(\.allocations).filter {
            $0.day == today && $0.totalMinutes > epsilon
        }.compactMap(\.projectID))
        for estimate in forecast.projects {
            guard let project = catalogue[estimate.id] else { continue }
            let due = estimate.project.dueDate.map { calendar.startOfDay(for: $0) }
            let remaining = max(0, estimate.estimatedMinutes - estimate.completedMinutes)
            let missing = estimate.unknownTaskCount > 0
            let unfinished = unfinishedIDs.contains(estimate.id)
            let deficit = max(0, remaining - estimate.allocatedByDeadlineMinutes)
            let completion = estimate.completionDate.map { calendar.startOfDay(for: $0) }
            let startsToday = startsTodayIDs.contains(estimate.id)
            var bucket: PortfolioBucket
            if due == nil {
                bucket = .noDeadline
                assessed.insert(project.id) // A missing deadline is a fact, not a feasibility claim.
            } else if let due = due, let horizon = horizon, due <= horizon, deficit > epsilon {
                bucket = .critical // Even the known work cannot fit before this deadline.
                assessed.insert(project.id)
            } else if estimate.isFinished {
                // Nothing outstanding is left to place, so the deadline cannot be missed. Without
                // this a project whose last task was just ticked off fell into the zero-estimate
                // branch below and kept an at-risk badge (report 2026-09-15_17-41-45).
                bucket = .onTrack
                assessed.insert(project.id)
            } else if missing || (unfinished && completion == nil) || estimate.estimatedMinutes <= epsilon {
                bucket = .atRisk // Placement below is actionable; the unsupported risk badge stays hidden.
            } else if let due = due, let completion = completion, completion >= due {
                bucket = completion > due ? .critical : .atRisk
                assessed.insert(project.id)
            } else {
                bucket = .onTrack
                assessed.insert(project.id)
            }
            let days = today.flatMap { start in due.flatMap { calendar.dateComponents([.day], from: start, to: $0).day } }
            var badges: [String] = []
            if startsToday && unfinished { badges.append(PortfolioBadge.startNow.rawValue) }
            if bucket == .critical { badges.append(PortfolioBadge.overcommitted.rawValue) }
            let row = PortfolioProject(id: project.id, name: project.name, due_date: project.due_date,
                importance: project.importance, outcome: project.outcome,
                required_hours: missing ? nil : remaining / 60,
                risk_score: remaining > epsilon ? deficit / remaining : nil, bucket: bucket.rawValue,
                deficit_hours: deficit > epsilon ? deficit / 60 : nil, days_until_due: days,
                latest_start: nil, badges: badges,
                projected_completion_date: completion.map { ISO8601DateFormatter().string(from: $0) })
            rows.append(row)
            switch bucket {
            case .critical: groups.askForExtension.append(row)
            case .atRisk:
                // Empty projects have nothing to start; missing estimates on actual tasks need attention.
                if unfinished { groups.startNow.append(row) } else { groups.backBurner.append(row) }
            case .onTrack, .noDeadline:
                if startsToday && unfinished { groups.startNow.append(row) } else { groups.backBurner.append(row) }
            }
        }
        // Retain the old encouragement rule and visible limits, using the allocator's outcome order
        // instead of interpreting the unrelated legacy importance1–4 field as an outcome.
        if groups.startNow.isEmpty {
            let dueDated = groups.backBurner.filter { unfinishedIDs.contains($0.id) && $0.hasDueDate }
            let candidates = dueDated.isEmpty
                ? groups.backBurner.filter { unfinishedIDs.contains($0.id) && ($0.outcome ?? 0) >= 8 }
                : dueDated
            groups.startNow = Array(candidates.prefix(PortfolioGrouping.encouragedStartNowLimit))
            let promoted = Set(groups.startNow.map(\.id))
            groups.backBurner.removeAll { promoted.contains($0.id) }
        }
        return LocalForecastPortfolio(rows: rows, groups: groups, assessedProjectIDs: assessed,
            isOvercommitted: !groups.askForExtension.isEmpty || forecast.days.contains { $0.capacity.overcommittedMinutes > epsilon })
    }
}
