//
//  StatsApi.swift
//  Focus Bear
//
//  Stats API calls. These mirror what the web dashboard's /webview/stats page requests
//  (`store/reducer/stats/extra.ts`, `store/reducer/user/extra.ts`) so the native Stats screen shows
//  exactly the numbers the dashboard and mobile app show.
//

import Foundation

/// Backend stats endpoints (web: `constants/endpoints.ts`).
enum StatsEndpoint {
    static let onboardingStats = "/user/stats/onboarding"
    static let longTermGoals = "/user/long-term-goals"
    static let userSettings = "/user-settings"
    static let consistencyStats = "/completed-activity/consistency-stats"
    static func activityStats(_ activityId: String) -> String { "/completed-activity/\(activityId)/stats" }
    static func logQuestionStats(_ questionId: String) -> String { "/completed-activity/log-question/\(questionId)/stats" }
    static let completedFocusBlocks = "/completed-focus-blocks"
    static let focusLog = "/user/weekly-focus-block-summary"
    static let focusModes = "/user/focus-modes"
    static let leaderboard = "/user-stats/leaderboard"
    static let username = "/user/username"
    static let motivationalSummary = "/user/motivational-summary"
}

/// Request sizes shared with the web (`HABIT_CONSISTENCY`, `DAYS_TO_FETCH_HEATMAP`,
/// `FOCUS_LOG_PAGE_SIZE`, `LEADER_BOARD.STAT_LIMIT`).
enum StatsRequestLimits {
    static let consistencyDays = 90
    static let maxConsistencyActivityIds = 100
    static let heatMapDays = HeatMapBuilder.fetchDays
    static let focusLogPageSize = 50
    static let leaderboardLimit = 20
}

private enum HTTPMethod {
    static let get = "GET"
    static let post = "POST"
    static let put = "PUT"
    static let patch = "PATCH"
    static let delete = "DELETE"
}

extension AllApi {

    func getOnboardingStats(completionHandler: @escaping (OnboardingStats?) -> ()) {
        performStatsRequest(path: StatsEndpoint.onboardingStats, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats(OnboardingStats.self, from: data, statusCode: status, call: "onboardingStats"))
        }
    }

    func getLongTermGoals(completionHandler: @escaping ([String]?) -> ()) {
        performStatsRequest(path: StatsEndpoint.longTermGoals, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats([String].self, from: data, statusCode: status, call: "longTermGoals"))
        }
    }

    func updateLongTermGoals(_ goals: [String], completionHandler: @escaping (Bool) -> ()) {
        let body = try? StatsJSON.encoder.encode(LongTermGoalsPayload(goals: goals))
        performStatsRequest(path: StatsEndpoint.longTermGoals, method: HTTPMethod.patch, body: body) { _, status in
            completionHandler(AllApi.isSuccess(status))
        }
    }

    /// The routine activities (+ account creation date) the Habit Stats tab ranks.
    func getStatsUserSettings(completionHandler: @escaping (StatsUserSettings?) -> ()) {
        performStatsRequest(path: StatsEndpoint.userSettings, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats(StatsUserSettings.self, from: data, statusCode: status, call: "statsUserSettings"))
        }
    }

    /// `POST /completed-activity/consistency-stats` — read-only despite the verb (bulk ids in the body).
    func getConsistencyStats(_ payload: ConsistencyStatsPayload, completionHandler: @escaping (BulkConsistencyStats?) -> ()) {
        let body = try? StatsJSON.encoder.encode(payload)
        performStatsRequest(path: StatsEndpoint.consistencyStats, method: HTTPMethod.post, body: body) { data, status in
            completionHandler(AllApi.decodeStats(BulkConsistencyStats.self, from: data, statusCode: status, call: "consistencyStats"))
        }
    }

    func getActivityStats(activityId: String, days: Int, timezone: String,
                          completionHandler: @escaping (CompletedActivityStats?) -> ()) {
        let path = "\(StatsEndpoint.activityStats(activityId))?days_number=\(days)&timezone=\(AllApi.queryEncoded(timezone))"
        performStatsRequest(path: path, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats(CompletedActivityStats.self, from: data, statusCode: status, call: "activityStats"))
        }
    }

    func getLogQuestionStats(questionId: String, completionHandler: @escaping (LogQuantityAnswersStats?) -> ()) {
        performStatsRequest(path: StatsEndpoint.logQuestionStats(questionId), method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats(LogQuantityAnswersStats.self, from: data, statusCode: status, call: "logQuestionStats"))
        }
    }

    func getCompletedFocusBlocks(from: Date, to: Date, completionHandler: @escaping ([FocusSessionSummary]?) -> ()) {
        let path = "\(StatsEndpoint.completedFocusBlocks)?from_time=\(AllApi.queryEncoded(StatsDates.iso(from)))&to_time=\(AllApi.queryEncoded(StatsDates.iso(to)))"
        performStatsRequest(path: path, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats([FocusSessionSummary].self, from: data, statusCode: status, call: "completedFocusBlocks"))
        }
    }

    func getFocusLog(limit: Int, offset: Int, completionHandler: @escaping ([FocusLogEntry]?) -> ()) {
        let path = "\(StatsEndpoint.focusLog)?limit=\(limit)&offset=\(offset)"
        performStatsRequest(path: path, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats([FocusLogEntry].self, from: data, statusCode: status, call: "focusLog"))
        }
    }

    func createFocusBlock(_ payload: CreateFocusBlockPayload, completionHandler: @escaping (Bool) -> ()) {
        let body = try? StatsJSON.encoder.encode(payload)
        performStatsRequest(path: StatsEndpoint.focusLog, method: HTTPMethod.post, body: body) { _, status in
            completionHandler(AllApi.isSuccess(status))
        }
    }

    func updateFocusBlock(id: String, _ payload: UpdateFocusBlockPayload, completionHandler: @escaping (Bool) -> ()) {
        let body = try? StatsJSON.encoder.encode(payload)
        performStatsRequest(path: "\(StatsEndpoint.focusLog)/\(id)", method: HTTPMethod.patch, body: body) { _, status in
            completionHandler(AllApi.isSuccess(status))
        }
    }

    func deleteFocusBlock(id: String, completionHandler: @escaping (Bool) -> ()) {
        performStatsRequest(path: "\(StatsEndpoint.focusLog)/\(id)", method: HTTPMethod.delete, body: nil) { _, status in
            completionHandler(AllApi.isSuccess(status))
        }
    }

    func getFocusModeSummaries(completionHandler: @escaping ([FocusModeSummary]?) -> ()) {
        performStatsRequest(path: StatsEndpoint.focusModes, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats([FocusModeSummary].self, from: data, statusCode: status, call: "focusModeSummaries"))
        }
    }

    /// `streak_type` (backend `StreakTypes`) picks which streak the server ranks by — and therefore
    /// which users make the top `limit` among those active in the last 30 days. (The web sends none, so
    /// it always gets the morning pool and re-sorts it locally.)
    func getLeaderboard(limit: Int, streakType: String, completionHandler: @escaping (LeaderboardResponse?) -> ()) {
        let path = "\(StatsEndpoint.leaderboard)?limit=\(limit)&streak_type=\(AllApi.queryEncoded(streakType))"
        performStatsRequest(path: path, method: HTTPMethod.get, body: nil) { data, status in
            completionHandler(AllApi.decodeStats(LeaderboardResponse.self, from: data, statusCode: status, call: "leaderboard"))
        }
    }

    func updateUsername(_ username: String, completionHandler: @escaping (Bool) -> ()) {
        let body = try? StatsJSON.encoder.encode(UsernamePayload(username: username))
        performStatsRequest(path: StatsEndpoint.username, method: HTTPMethod.put, body: body) { _, status in
            completionHandler(AllApi.isSuccess(status))
        }
    }

    /// Shared plumbing: refresh the Auth0 credential (like every other call in AllApi), attach the
    /// bearer token via `makeRequest`, run the request and hand back `(data, statusCode)` — `statusCode`
    /// is 0 when the request never reached the server. Non-2xx bodies are logged via `writeJsonInLog`.
    private func performStatsRequest(path: String, method: String, body: Data?,
                                     completionHandler: @escaping (_ data: Data?, _ statusCode: Int) -> ()) {
        addLog(text: "func call:- api stats \(method) \(path)")
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil, let url = NSURL(string: "\(baseUrl)\(path)") else {
                completionHandler(nil, 0)
                return
            }
            let request = makeRequest(responsePathUrl: url)
            request.httpMethod = method
            if let body = body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    addLog(text: "api stats \(method) \(path) error:- \(error?.localizedDescription ?? "no response")")
                    completionHandler(nil, 0)
                    return
                }
                if !AllApi.isSuccess(httpResponse.statusCode) {
                    addLog(text: "api stats \(method) \(path) Api error:- statusCode is \(httpResponse.statusCode)")
                    self.writeJsonInLog(data: data)
                }
                completionHandler(data, httpResponse.statusCode)
            }
            task.resume()
        }
    }

    private static func isSuccess(_ statusCode: Int) -> Bool { (200..<300).contains(statusCode) }

    private static func queryEncoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    private static func decodeStats<T: Decodable>(_ type: T.Type, from data: Data?, statusCode: Int, call: String) -> T? {
        guard isSuccess(statusCode), let data = data else { return nil }
        do {
            return try StatsJSON.decoder.decode(type, from: data)
        } catch {
            addLog(text: "api stats \(call) decode error:- \(error)")
            return nil
        }
    }
}

// MARK: - Pep talk (server-sent events)

/// Streams `GET /user/motivational-summary` (text/event-stream) like the web's `fetchEventSource`:
/// each `data:` line is a text chunk, `[DONE]` ends the message (the server keeps streaming its prompt
/// afterwards, which must be ignored), `event: fatal_error` aborts.
final class MotivationalSummaryStream: NSObject, URLSessionDataDelegate {
    private static let dataPrefix = "data:"
    private static let eventPrefix = "event:"
    private static let doneSentinel = "[DONE]"
    private static let fatalEvent = "fatal_error"
    static let desktopDeviceType = "desktop"

    private let onChunk: (String) -> Void
    private let onFinish: (_ succeeded: Bool) -> Void
    private var session: URLSession?
    private var buffer = ""
    private var finished = false
    private var receivedText = false

    init(onChunk: @escaping (String) -> Void, onFinish: @escaping (Bool) -> Void) {
        self.onChunk = onChunk
        self.onFinish = onFinish
    }

    func start(tone: String, language: String) {
        appdelegate!.credentialsManager.credentials { [weak self] credentialsInfo in
            guard let self = self else { return }
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            let query = "?tone=\(tone.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? tone)"
                + "&device_type=\(MotivationalSummaryStream.desktopDeviceType)&language=\(language)"
            guard appdelegate!.credential != nil,
                  let url = NSURL(string: "\(baseUrl)\(StatsEndpoint.motivationalSummary)\(query)") else {
                self.finish(succeeded: false)
                return
            }
            let request = makeRequest(responsePathUrl: url)
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.session = session
            session.dataTask(with: request as URLRequest).resume()
        }
    }

    func cancel() {
        finished = true
        session?.invalidateAndCancel()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !finished, let text = String(data: data, encoding: .utf8) else { return }
        buffer += text
        while let newline = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<newline])
            buffer = String(buffer[buffer.index(after: newline)...])
            handle(line: line)
            if finished { return }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        finish(succeeded: receivedText && error == nil)
    }

    private func handle(line: String) {
        if line.hasPrefix(MotivationalSummaryStream.eventPrefix) {
            let event = line.dropFirst(MotivationalSummaryStream.eventPrefix.count).trimmingCharacters(in: .whitespaces)
            if event == MotivationalSummaryStream.fatalEvent { finish(succeeded: false) }
            return
        }
        guard line.hasPrefix(MotivationalSummaryStream.dataPrefix) else { return }
        // SSE strips exactly one leading space after the colon; the rest of the chunk is content.
        var value = String(line.dropFirst(MotivationalSummaryStream.dataPrefix.count))
        if value.hasPrefix(" ") { value.removeFirst() }
        if value == MotivationalSummaryStream.doneSentinel {
            finish(succeeded: receivedText)
            return
        }
        guard !value.isEmpty else { return }
        receivedText = true
        DispatchQueue.main.async { self.onChunk(value) }
    }

    private func finish(succeeded: Bool) {
        guard !finished else { return }
        finished = true
        session?.invalidateAndCancel()
        DispatchQueue.main.async { self.onFinish(succeeded) }
    }
}
