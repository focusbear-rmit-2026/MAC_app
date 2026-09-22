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
/// Buffer bytes until a complete SSE line exists: URLSession may split an emoji/accent across
/// packets. Stop at DONE so the server's following prompt never reaches the UI or diagnostics.
struct MotivationalSummaryDecoder {
    enum Event: Equatable { case text(String), done, fatal, invalid }
    private var buffer = Data()
    private(set) var finished = false
    mutating func consume(_ data: Data) -> [Event] {
        guard !finished else { return [] }
        buffer.append(data)
        var events: [Event] = []
        while let newline = buffer.firstIndex(of: 10) {
            let bytes = buffer[..<newline]
            buffer.removeSubrange(...newline)
            guard var line = String(data: bytes, encoding: .utf8) else {
                finished = true; return events + [.invalid]
            }
            if line.hasSuffix("\r") { line.removeLast() }
            if line == "event: fatal_error" {
                finished = true; return events + [.fatal]
            }
            guard line.hasPrefix("data:") else { continue }
            var value = String(line.dropFirst(5))
            if value.hasPrefix(" ") { value.removeFirst() }
            if value == "[DONE]" { finished = true; return events + [.done] }
            if !value.isEmpty { events.append(.text(value)) }
        }
        if buffer.count > 65_536 { finished = true; return events + [.invalid] }
        return events
    }
}

/// Why a pep talk didn't arrive. The stream used to hand the UI a bare `Bool`, so every failure —
/// rate limit, server error, dropped connection — produced the same "try again later", and a user
/// being rate-limited had no way to know that pressing Retry again could not work. Report
/// 2026-09-22_07-45-26: five attempts in two minutes, all HTTP 429, two of them two seconds apart.
enum PepTalkFailure: Equatable {
    /// HTTP 429. `retryAfter` is the server's own advice when it sent any.
    case rateLimited(retryAfter: TimeInterval?)
    /// The server answered, but not with something usable.
    case serverError
    /// Never reached the server, or the connection died mid-stream.
    case connection
    /// Everything else, including a 2xx that carried no text.
    case other

    /// How long to hold the Retry button, when we can say. Only a rate limit has a knowable answer;
    /// guessing one for the rest would be inventing a number.
    var retryDelay: TimeInterval? {
        if case .rateLimited(let after) = self { return after ?? PepTalkFailure.defaultRateLimitWait }
        return nil
    }

    /// Used when a 429 carries no `Retry-After`. A minute is long enough to clear a burst limit and
    /// short enough not to feel broken.
    static let defaultRateLimitWait: TimeInterval = 60

    /// Classify an HTTP response. `retryAfterHeader` is the raw header value, which the spec allows
    /// to be either seconds or an HTTP date; only the seconds form is honoured, because a date needs
    /// a clock both ends agree on and a wrong one would hold the button for hours.
    static func from(status: Int, retryAfterHeader: String?) -> PepTalkFailure {
        if status == 429 {
            let seconds = retryAfterHeader
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .flatMap(TimeInterval.init)
            guard let seconds, seconds > 0 else { return .rateLimited(retryAfter: nil) }
            return .rateLimited(retryAfter: min(seconds, maximumHonouredWait))
        }
        if status == 0 { return .connection }
        if (500..<600).contains(status) { return .serverError }
        return .other
    }

    /// However long the server asks for, never hold the button longer than this — a misconfigured
    /// header should not disable the feature for the rest of the day.
    static let maximumHonouredWait: TimeInterval = 15 * 60
}

final class MotivationalSummaryStream: NSObject, URLSessionDataDelegate {
    static let desktopDeviceType = "desktop"
    private let onChunk: (String) -> Void
    private let onFinish: (_ succeeded: Bool, _ failure: PepTalkFailure?) -> Void
    private var session: URLSession?
    private var decoder = MotivationalSummaryDecoder()
    private var finished = false
    private var receivedText = false
    private var receivedBytes = 0
    private var accountID = ""

    init(onChunk: @escaping (String) -> Void,
         onFinish: @escaping (Bool, PepTalkFailure?) -> Void) {
        self.onChunk = onChunk
        self.onFinish = onFinish
    }

    func start(tone: String, language: String) {
        guard let delegate = appdelegate, let account = delegate.user?.userId, !account.isEmpty else {
            finish(succeeded: false, reason: "missing_account"); return
        }
        accountID = account
        delegate.credentialsManager.credentials { [weak self] credentialsInfo in
            DispatchQueue.main.async {
                guard let self = self, !self.finished else { return }
                guard delegate.user?.userId == account else { self.cancel(); return }
                delegate.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
                guard delegate.user?.userId == account, delegate.credential != nil else {
                    self.finish(succeeded: false, reason: "credentials_unavailable"); return
                }
                let query = "?tone=\(tone.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? tone)"
                    + "&device_type=\(Self.desktopDeviceType)&language=\(language.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "en")"
                guard let url = NSURL(string: "\(baseUrl)\(StatsEndpoint.motivationalSummary)\(query)") else {
                    self.finish(succeeded: false, reason: "invalid_url"); return
                }
                let request = makeRequest(responsePathUrl: url)
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                // All state/callbacks share main's serial queue, including explicit cancellation.
                let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
                self.session = session
                session.dataTask(with: request as URLRequest).resume()
            }
        }
    }

    func cancel() {
        finished = true
        session?.invalidateAndCancel()
        session = nil
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard !finished, appdelegate?.user?.userId == accountID else { cancel(); completionHandler(.cancel); return }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let isEventStream = response.mimeType?.lowercased() == "text/event-stream"
        addLog(text: "pep talk stream: status=\(status) eventStream=\(isEventStream)")
        guard (200..<300).contains(status), isEventStream else {
            completionHandler(.cancel)
            let retryAfter = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Retry-After")
            finish(succeeded: false, reason: "http_\(status)",
                   failure: PepTalkFailure.from(status: status, retryAfterHeader: retryAfter))
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !finished, appdelegate?.user?.userId == accountID else { cancel(); return }
        receivedBytes += data.count
        for event in decoder.consume(data) {
            switch event {
            case .text(let value): receivedText = true; onChunk(value)
            case .done: finish(succeeded: receivedText, reason: "done")
            case .fatal: finish(succeeded: false, reason: "server_fatal")
            case .invalid: finish(succeeded: false, reason: "invalid_stream")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard appdelegate?.user?.userId == accountID else { cancel(); return }
        finish(succeeded: receivedText && error == nil,
               reason: error.map { "transport_\(($0 as NSError).code)" } ?? "eof",
               failure: error == nil ? .other : .connection)
    }

    private func finish(succeeded: Bool, reason: String, failure: PepTalkFailure? = nil) {
        guard !finished else { return }
        finished = true
        // Never log the response body, prompt, identity or credentials.
        addLog(text: "pep talk stream: finished=\(succeeded) reason=\(reason) bytes=\(receivedBytes) receivedText=\(receivedText)")
        session?.invalidateAndCancel()
        session = nil
        onFinish(succeeded, succeeded ? nil : (failure ?? .other))
    }
}
