//
//  HabitStatsStore.swift
//  Focus Bear
//
//  State for the Habit Stats tab — the web's `dashboard/stats/activityStats`: rank every routine
//  habit by consistency over the last 90 days, then show the selected habit's stat cards, completion
//  heat map and (for log-quantity habits) the logged-quantity graph.
//

import Foundation

struct HabitDetails: Equatable {
    var heatMap = HeatMapModel()
    var summary = HabitStatSummary()
    var questionPoints: [GraphPoint] = []
    var isEmpty: Bool { heatMap.totalCount == 0 && questionPoints.isEmpty }
}

final class HabitStatsStore: ObservableObject {
    @Published private(set) var activities: [StatsActivity] = []
    @Published private(set) var ranking = HabitConsistencyRanking.Split(mostConsistent: [], leastConsistent: [])
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    @Published private(set) var hasLoaded = false

    @Published private(set) var selectedHabitId: String?
    @Published private(set) var details: HabitDetails?
    @Published private(set) var isLoadingDetails = false
    @Published private(set) var selectedQuestionId: String?

    private var joinDate: Date?
    private var activityItems: [ActivityStatItem] = []
    /// Guards against a slow response for a previously selected habit overwriting the current one.
    private var detailsRequestId = 0

    var selectedHabit: StatsActivity? { activities.first { $0.id == selectedHabitId } }
    var hasHabits: Bool { !activities.isEmpty }

    var timezone: String { TimeZone.current.identifier }

    func load() {
        isLoading = true
        hasError = false
        allApiObject.getStatsUserSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard let settings = settings else {
                    self.isLoading = false
                    self.hasLoaded = true
                    self.hasError = true
                    return
                }
                self.activities = settings.uniqueActivities
                self.joinDate = StatsDates.parse(settings.createdAt)
                self.loadConsistency()
            }
        }
    }

    private func loadConsistency() {
        guard hasHabits else {
            isLoading = false
            hasLoaded = true
            return
        }
        let payload = ConsistencyStatsPayload(
            activityIds: Array(activities.map(\.id).prefix(StatsRequestLimits.maxConsistencyActivityIds)),
            daysNumber: StatsRequestLimits.consistencyDays,
            timezone: timezone)
        allApiObject.getConsistencyStats(payload) { [weak self] stats in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                self.hasLoaded = true
                guard let stats = stats else {
                    self.hasError = true
                    return
                }
                let ranked = HabitConsistencyRanking.build(activities: self.activities, stats: stats, today: Date())
                self.ranking = HabitConsistencyRanking.split(ranked)
                // Web: default to the most consistent habit, else the least consistent list's first row.
                let defaultHabit = self.ranking.mostConsistent.first ?? self.ranking.leastConsistent.first
                if let habit = defaultHabit?.activity, self.selectedHabit == nil {
                    self.select(habit)
                } else if let current = self.selectedHabit {
                    self.select(current)
                }
            }
        }
    }

    func select(_ habit: StatsActivity) {
        selectedHabitId = habit.id
        selectedQuestionId = habit.questions.count == 1 ? habit.questions.first?.id : nil
        details = nil
        isLoadingDetails = true
        detailsRequestId += 1
        let requestId = detailsRequestId
        allApiObject.getActivityStats(activityId: habit.id, days: StatsRequestLimits.heatMapDays, timezone: timezone) { [weak self] stats in
            DispatchQueue.main.async {
                guard let self = self, requestId == self.detailsRequestId else { return }
                self.activityItems = stats?.items ?? []
                self.isLoadingDetails = false
                self.rebuildDetails(questionPoints: [])
                if let questionId = self.selectedQuestionId { self.loadQuestion(questionId) }
            }
        }
    }

    func selectQuestion(_ questionId: String?) {
        selectedQuestionId = questionId
        guard let questionId = questionId else {
            rebuildDetails(questionPoints: [])
            return
        }
        loadQuestion(questionId)
    }

    private func loadQuestion(_ questionId: String) {
        let requestId = detailsRequestId
        allApiObject.getLogQuestionStats(questionId: questionId) { [weak self] stats in
            DispatchQueue.main.async {
                guard let self = self, requestId == self.detailsRequestId, self.selectedQuestionId == questionId else { return }
                self.rebuildDetails(questionPoints: LogQuantityGraph.points(stats?.items ?? []))
            }
        }
    }

    private func rebuildDetails(questionPoints: [GraphPoint]) {
        let today = Date()
        details = HabitDetails(
            heatMap: HeatMapBuilder.build(items: activityItems, joinDate: joinDate, today: today),
            summary: HabitStatSummary.compute(items: activityItems, today: today),
            questionPoints: questionPoints)
    }
}
