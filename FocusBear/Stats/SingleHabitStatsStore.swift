//
//  SingleHabitStatsStore.swift
//  Focus Bear
//
//  State for the per-habit stats sheet opened from a habit's action bar (the "Stats" button next to
//  Edit). The Stats screen's Habit Stats tab ranks every habit and then drills into the selected one;
//  here the habit is already chosen, so this skips the consistency ranking and loads exactly that
//  habit's streak, heat map and — for a log-quantity habit — one series per question.
//
//  Everything it computes comes from the shared pure logic in StatsMath.swift, so the numbers match
//  the Stats screen and the web dashboard.
//

import Foundation

/// One log-quantity question's chart: the question text, its daily series, and whether the backend
/// aggregates it as a total or an average (so the chart can say which).
struct HabitQuestionGraph: Identifiable, Equatable {
    let id: String
    let question: String
    let points: [GraphPoint]
    let isAveraged: Bool
}

final class SingleHabitStatsStore: ObservableObject {
    @Published private(set) var habit: StatsActivity?
    @Published private(set) var heatMap = HeatMapModel()
    @Published private(set) var summary = HabitStatSummary()
    @Published private(set) var questionGraphs: [HabitQuestionGraph] = []
    /// False for a quantity habit, where `summary` is a logged amount rather than seconds — an
    /// "hours spent" tile built from it would be nonsense.
    @Published private(set) var showsHoursSpent = true
    @Published private(set) var isLoading = true
    @Published private(set) var hasError = false

    /// The habit's server id — the same id the Day Plan's Edit button carries.
    let habitId: String
    /// Name/icon from the Day Plan row, shown while `/user-settings` is still in flight (and kept as
    /// the fallback if that habit isn't in the settings payload at all).
    private let fallbackTitle: String

    private var timezone: String { TimeZone.current.identifier }

    init(habitId: String, fallbackTitle: String) {
        self.habitId = habitId
        self.fallbackTitle = fallbackTitle
    }

    /// The habit's display name: the settings entry's icon + name once loaded, else the Day Plan's row title.
    var title: String {
        guard let habit = habit else { return fallbackTitle }
        let composed = [habit.habitIcon, habit.name].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        return composed.isEmpty ? fallbackTitle : composed
    }

    var hasAnyData: Bool { heatMap.totalCount > 0 || questionGraphs.contains { !$0.points.isEmpty } }

    func load() {
        isLoading = true
        hasError = false
        // /user-settings carries the habit's name, icon, join date and its log-quantity questions
        // (including each question's SUM/AVG setting) — everything the charts need to label themselves.
        allApiObject.getStatsUserSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let settings = settings else {
                    self.isLoading = false
                    self.hasError = true
                    return
                }
                self.habit = settings.uniqueActivities.first { $0.id == self.habitId }
                self.loadActivityStats(joinDate: StatsDates.parse(settings.createdAt))
            }
        }
    }

    private func loadActivityStats(joinDate: Date?) {
        allApiObject.getActivityStats(activityId: habitId, days: StatsRequestLimits.heatMapDays,
                                      timezone: timezone) { [weak self] stats in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let stats = stats else {
                    self.isLoading = false
                    self.hasError = true
                    return
                }
                let items = stats.items ?? []
                let today = Date()
                self.heatMap = HeatMapBuilder.build(items: items, joinDate: joinDate, today: today)
                self.summary = HabitStatSummary.compute(items: items, today: today)
                self.showsHoursSpent = stats.isDurationBased
                self.loadQuestionGraphs()
            }
        }
    }

    /// One `/completed-activity/log-question/:id/stats` call per question, in parallel, collected in
    /// the habit's own question order (not whichever response lands first).
    private func loadQuestionGraphs() {
        let questions = habit?.questions ?? []
        guard !questions.isEmpty else {
            isLoading = false
            return
        }
        var pointsById: [String: [GraphPoint]] = [:]
        let group = DispatchGroup()
        let lock = NSLock()
        for question in questions {
            group.enter()
            allApiObject.getLogQuestionStats(questionId: question.id) { stats in
                lock.lock()
                pointsById[question.id] = LogQuantityGraph.points(stats?.items ?? [])
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.questionGraphs = questions.map {
                HabitQuestionGraph(id: $0.id, question: $0.question ?? $0.id,
                                   points: pointsById[$0.id] ?? [], isAveraged: $0.isAveraged)
            }
            self.isLoading = false
        }
    }
}
