//
//  VoiceCommandApi.swift
//  Focus Bear
//
//  Voice commands go through the backend `voice` module (POST /voice/transcribe, POST /voice/intent).
//  The app used to call OpenAI directly with a key compiled into the binary; that key is revoked and
//  must never come back. The key and the classifier prompt now live only on the server.
//

import Foundation

/// Backend voice-command endpoints, appended to `baseUrl`.
enum VoiceEndpoint {
    static let transcribe = "/voice/transcribe"
    static let intent = "/voice/intent"
}

/// Why a voice request failed, so the menu can say something more useful than "try again".
enum VoiceCommandError: Error, Equatable {
    case notSignedIn
    case unreadableRecording
    case network
    case rateLimited
    case recordingTooLarge
    case server(statusCode: Int)
    case invalidResponse
}

/// Builds the request bodies for the voice endpoints. Pure, so the wire format is unit-tested.
enum VoiceCommandRequestBuilder {
    /// Multipart field the backend reads the recording from.
    static let audioFormField = "file"
    /// The recorder writes 16-bit PCM WAV.
    static let audioContentType = "audio/wav"
    /// Local "now" format the backend accepts as `clientDatetime`.
    static let clientDatetimeFormat = "yyyy-MM-dd HH:mm:ss"
    private static let jsonContentType = "application/json"
    private static let contentTypeHeader = "Content-Type"
    private static let postMethod = "POST"
    private static let lineBreak = "\r\n"

    static func applyTranscriptionBody(to request: NSMutableURLRequest, audio: Data, filename: String, boundary: String) {
        request.httpMethod = postMethod
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: contentTypeHeader)
        request.httpBody = transcriptionBody(audio: audio, filename: filename, boundary: boundary)
    }

    static func transcriptionBody(audio: Data, filename: String, boundary: String) -> Data {
        var body = Data()
        body.append(Data("--\(boundary)\(lineBreak)".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(audioFormField)\"; filename=\"\(filename)\"\(lineBreak)".utf8))
        body.append(Data("Content-Type: \(audioContentType)\(lineBreak)\(lineBreak)".utf8))
        body.append(audio)
        body.append(Data("\(lineBreak)--\(boundary)--\(lineBreak)".utf8))
        return body
    }

    static func applyIntentBody(to request: NSMutableURLRequest, transcript: String, habits: [String],
                                now: Date, timeZone: TimeZone) {
        request.httpMethod = postMethod
        request.setValue(jsonContentType, forHTTPHeaderField: contentTypeHeader)
        request.httpBody = try? JSONEncoder().encode(
            intentBody(transcript: transcript, habits: habits, now: now, timeZone: timeZone))
    }

    static func intentBody(transcript: String, habits: [String], now: Date, timeZone: TimeZone) -> VoiceIntentRequestBody {
        VoiceIntentRequestBody(transcript: transcript,
                               habits: habits,
                               clientDatetime: clientDatetime(now, timeZone: timeZone),
                               timezone: timeZone.identifier)
    }

    static func clientDatetime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = clientDatetimeFormat
        return formatter.string(from: date)
    }
}

/// `POST /voice/intent` request body.
struct VoiceIntentRequestBody: Codable, Equatable {
    let transcript: String
    let habits: [String]
    let clientDatetime: String
    let timezone: String
}

private struct VoiceTranscriptionResponse: Decodable {
    let text: String
}

/// Turns a voice endpoint's response into a result. `statusCode` is 0 when no response arrived.
enum VoiceCommandResponseParser {
    static let successStatusCodes = 200..<300
    /// Reported when the request never got an HTTP response.
    static let noResponseStatusCode = 0
    private static let unauthorizedStatusCodes: Set<Int> = [401, 403]
    private static let payloadTooLargeStatusCode = 413
    private static let tooManyRequestsStatusCode = 429

    static func transcript(data: Data?, statusCode: Int) -> Result<String, VoiceCommandError> {
        decode(VoiceTranscriptionResponse.self, data: data, statusCode: statusCode).map(\.text)
    }

    static func intent(data: Data?, statusCode: Int) -> Result<IntentResponse, VoiceCommandError> {
        decode(IntentResponse.self, data: data, statusCode: statusCode)
    }

    static func error(forStatusCode statusCode: Int) -> VoiceCommandError {
        if statusCode == noResponseStatusCode { return .network }
        if unauthorizedStatusCodes.contains(statusCode) { return .notSignedIn }
        if statusCode == payloadTooLargeStatusCode { return .recordingTooLarge }
        if statusCode == tooManyRequestsStatusCode { return .rateLimited }
        return .server(statusCode: statusCode)
    }

    private static func decode<T: Decodable>(_ type: T.Type, data: Data?, statusCode: Int) -> Result<T, VoiceCommandError> {
        guard successStatusCodes.contains(statusCode) else {
            return .failure(error(forStatusCode: statusCode))
        }
        guard let data = data, let value = try? JSONDecoder().decode(type, from: data) else {
            return .failure(.invalidResponse)
        }
        return .success(value)
    }
}

/// Sends voice requests to the backend. `authorizedRequest` and `session` are injectable so the whole
/// pipeline can be tested with the network stubbed.
struct VoiceCommandClient {
    /// Produces a request for `baseUrl + path` carrying the user's auth headers, or nil when signed out.
    let authorizedRequest: (_ path: String, _ completion: @escaping (NSMutableURLRequest?) -> Void) -> Void
    let session: URLSession
    var now: () -> Date = Date.init
    var timeZone: () -> TimeZone = { TimeZone.current }

    static let live = VoiceCommandClient(authorizedRequest: liveAuthorizedRequest, session: .shared)

    func transcribe(fileURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let audio = try? Data(contentsOf: fileURL), !audio.isEmpty else {
            completion(.failure(VoiceCommandError.unreadableRecording))
            return
        }
        authorizedRequest(VoiceEndpoint.transcribe) { request in
            guard let request = request else {
                completion(.failure(VoiceCommandError.notSignedIn))
                return
            }
            VoiceCommandRequestBuilder.applyTranscriptionBody(to: request, audio: audio,
                                                              filename: fileURL.lastPathComponent,
                                                              boundary: UUID().uuidString)
            send(request) { data, statusCode in
                completion(VoiceCommandResponseParser.transcript(data: data, statusCode: statusCode).mapError { $0 as Error })
            }
        }
    }

    func classifyIntent(transcript: String, habits: [String], completion: @escaping (Result<IntentResponse, Error>) -> Void) {
        authorizedRequest(VoiceEndpoint.intent) { request in
            guard let request = request else {
                completion(.failure(VoiceCommandError.notSignedIn))
                return
            }
            VoiceCommandRequestBuilder.applyIntentBody(to: request, transcript: transcript, habits: habits,
                                                       now: now(), timeZone: timeZone())
            send(request) { data, statusCode in
                completion(VoiceCommandResponseParser.intent(data: data, statusCode: statusCode).mapError { $0 as Error })
            }
        }
    }

    private func send(_ request: NSMutableURLRequest, completion: @escaping (_ data: Data?, _ statusCode: Int) -> Void) {
        let path = request.url?.path ?? ""
        session.dataTask(with: request as URLRequest) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                addLog(text: "api voice \(path) error:- \(error?.localizedDescription ?? "no response")")
                completion(nil, VoiceCommandResponseParser.noResponseStatusCode)
                return
            }
            if !VoiceCommandResponseParser.successStatusCodes.contains(httpResponse.statusCode) {
                addLog(text: "api voice \(path) Api error:- statusCode is \(httpResponse.statusCode)")
            }
            completion(data, httpResponse.statusCode)
        }.resume()
    }

    /// Refreshes the Auth0 credential like every other AllApi call, then attaches the auth headers via
    /// `makeRequest`.
    private static func liveAuthorizedRequest(path: String, completion: @escaping (NSMutableURLRequest?) -> Void) {
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil, let url = NSURL(string: "\(baseUrl)\(path)") else {
                completion(nil)
                return
            }
            completion(makeRequest(responsePathUrl: url))
        }
    }
}

/// Action names the backend classifier returns from `POST /voice/intent`.
enum VoiceIntentName: String {
    case startFocus = "start_focus"
    case stopFocus = "stop_focus"
    case pauseFocus = "pause_focus"
    case resumeFocus = "resume_focus"
    case createTask = "create_task"
    case startHabit = "start_habit"
    case focusStats = "get_focus_stats"
}

/// What the app does in response to a voice command.
enum VoiceCommandAction: Equatable {
    static let defaultFocusMinutes = 25

    case startFocus(minutes: Int, goal: String?)
    case stopFocus
    case pauseFocus
    case resumeFocus
    case createTask(name: String, time: String?)
    case startHabit(name: String)
    case focusStats

    /// nil when the intent lacks a detail the action can't do without (a task or habit name).
    init?(_ name: VoiceIntentName, parameters: IntentResponse.Parameters) {
        switch name {
        case .startFocus:
            self = .startFocus(minutes: parameters.duration_minutes ?? Self.defaultFocusMinutes, goal: parameters.goal)
        case .stopFocus: self = .stopFocus
        case .pauseFocus: self = .pauseFocus
        case .resumeFocus: self = .resumeFocus
        case .createTask:
            guard let task = parameters.task, !task.isEmpty else { return nil }
            self = .createTask(name: task, time: parameters.time)
        case .startHabit:
            guard let habit = parameters.habit_name, !habit.isEmpty else { return nil }
            self = .startHabit(name: habit)
        case .focusStats: self = .focusStats
        }
    }
}

/// The result of one voice command, from recording to a decision the recorder acts on.
enum VoiceCommandOutcome {
    case perform(VoiceCommandAction, IntentResponse)
    /// Nothing was heard, the model wasn't confident, or a required detail was missing.
    case notUnderstood
    case unsupported(action: String)
    case transcriptionFailed(Error)
    case classificationFailed(Error)
}

/// Recording → transcript → intent → action. The network calls are injected so the flow is testable.
struct VoiceCommandPipeline {
    static let lowConfidence = "low"

    let transcribe: (URL, @escaping (Result<String, Error>) -> Void) -> Void
    let classify: (String, [String], @escaping (Result<IntentResponse, Error>) -> Void) -> Void

    static let live = VoiceCommandPipeline(transcribe: VoiceCommandClient.live.transcribe,
                                           classify: VoiceCommandClient.live.classifyIntent)

    func run(recording: URL, habits: [String], onTranscript: @escaping (String) -> Void,
             completion: @escaping (VoiceCommandOutcome) -> Void) {
        transcribe(recording) { result in
            switch result {
            case .failure(let error):
                completion(.transcriptionFailed(error))
            case .success(let transcript):
                let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                onTranscript(spoken)
                guard !spoken.isEmpty else {
                    completion(.notUnderstood)
                    return
                }
                classify(spoken, habits) { intentResult in
                    completion(Self.outcome(for: intentResult))
                }
            }
        }
    }

    static func outcome(for intentResult: Result<IntentResponse, Error>) -> VoiceCommandOutcome {
        switch intentResult {
        case .failure(let error):
            return .classificationFailed(error)
        case .success(let intent):
            if intent.confidence == lowConfidence { return .notUnderstood }
            guard let name = VoiceIntentName(rawValue: intent.action) else { return .unsupported(action: intent.action) }
            guard let action = VoiceCommandAction(name, parameters: intent.parameters) else { return .notUnderstood }
            return .perform(action, intent)
        }
    }
}

/// User-facing voice messages, from the `menuView` config section so they are translated.
enum VoiceCommandMessage {
    static var noMicrophone: String {
        menuLocalized("voiceErrorNoMicrophone", "No microphone found. Connect a microphone and try again.")
    }
    static var notUnderstood: String { menuLocalized("voiceErrorNotCaught", "Sorry, I didn't catch that. Please try again.") }
    static var unsupported: String { menuLocalized("voiceErrorUnsupported", "Sorry, I can't do that one yet.") }
    static var timedOut: String { menuLocalized("voiceErrorTimedOut", "Your voice command is taking too long. Please try again.") }
    static var generic: String { menuLocalized("voiceErrorGeneric", "Something went wrong. Please try again.") }

    static func transcriptionFailed(_ error: Error) -> String {
        specific(error) ?? menuLocalized("voiceErrorTranscribe", "Couldn't transcribe audio. Try again.")
    }

    static func classificationFailed(_ error: Error) -> String {
        specific(error) ?? menuLocalized("voiceErrorUnderstand", "Couldn't understand that. Try again.")
    }

    /// A message for failures the user can act on; nil for ones where "try again" is all we can say.
    private static func specific(_ error: Error) -> String? {
        switch error as? VoiceCommandError {
        case .notSignedIn:
            return menuLocalized("voiceErrorSignedOut", "Sign in to Focus Bear to use voice commands.")
        case .network:
            return menuLocalized("voiceErrorOffline", "Couldn't reach Focus Bear. Check your internet connection and try again.")
        case .rateLimited:
            return menuLocalized("voiceErrorRateLimited", "That's a lot of voice commands in a row. Wait a minute, then try again.")
        case .recordingTooLarge:
            return menuLocalized("voiceErrorTooLong", "That recording was too long. Try a shorter command.")
        default:
            return nil
        }
    }
}
