//
//  VoiceCommandTests.swift
//  Focus BearTests
//
//  Voice input goes recording → POST /voice/transcribe → POST /voice/intent → app action. These lock in
//  the wire format the backend `voice` module expects, the pipeline's decisions with the network stubbed,
//  and that no OpenAI key literal ever returns to the app sources (one shipped in the binary until
//  Mac-App#2732).
//

@testable import Focus_Bear
import XCTest

private let testHost = "api.voice.test"
private let testToken = "Bearer test-token"
private let habitNames = ["Drink water", "Stretch"]
private let melbourne = TimeZone(identifier: "Australia/Melbourne")!
/// 2026-09-28 03:04:05 UTC, which is 13:04:05 in Melbourne.
private let fixedNow = Date(timeIntervalSince1970: 1_790_564_645)

// MARK: - Network stub

/// Answers requests from canned responses keyed by URL path and records what was sent.
final class VoiceStubURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int
        let body: Data
    }

    static var stubs: [String: Stub] = [:]
    static var requests: [URLRequest] = []
    static var bodies: [String: Data] = [:]

    static func reset() {
        stubs = [:]
        requests = []
        bodies = [:]
    }

    static func stub(_ path: String, status: Int = 200, json: String) {
        stubs[path] = Stub(statusCode: status, body: Data(json.utf8))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        Self.requests.append(request)
        Self.bodies[path] = Self.readBody(of: request)
        guard let stub = Self.stubs[path], let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// URLSession hands protocols the body as a stream, not `httpBody`.
    private static func readBody(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private func stubbedClient(signedIn: Bool = true) -> VoiceCommandClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [VoiceStubURLProtocol.self]
    return VoiceCommandClient(
        authorizedRequest: { path, completion in
            guard signedIn else { return completion(nil) }
            let request = NSMutableURLRequest(url: URL(string: "https://\(testHost)\(path)")!)
            request.addValue(testToken, forHTTPHeaderField: "Authorization")
            completion(request)
        },
        session: URLSession(configuration: configuration),
        now: { fixedNow },
        timeZone: { melbourne })
}

private func decodeIntent(_ json: String) -> IntentResponse {
    try! JSONDecoder().decode(IntentResponse.self, from: Data(json.utf8))
}

// MARK: - Request building and response parsing

final class VoiceCommandRequestTests: XCTestCase {
    func testTranscriptionUploadIsOneMultipartWavPartNamedFile() {
        let request = NSMutableURLRequest(url: URL(string: "https://\(testHost)\(VoiceEndpoint.transcribe)")!)
        let audio = Data("RIFF-audio-bytes".utf8)

        VoiceCommandRequestBuilder.applyTranscriptionBody(to: request, audio: audio, filename: "recording.wav", boundary: "B0UNDARY")

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "multipart/form-data; boundary=B0UNDARY")
        let expected = "--B0UNDARY\r\n"
            + "Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n"
            + "Content-Type: audio/wav\r\n\r\n"
            + "RIFF-audio-bytes"
            + "\r\n--B0UNDARY--\r\n"
        XCTAssertEqual(String(data: request.httpBody ?? Data(), encoding: .utf8), expected)
    }

    func testTranscriptionUploadCarriesNoModelOrKeyFields() {
        let body = VoiceCommandRequestBuilder.transcriptionBody(audio: Data("x".utf8), filename: "recording.wav", boundary: "B")
        let text = String(decoding: body, as: UTF8.self)

        XCTAssertFalse(text.contains("whisper"))
        XCTAssertFalse(text.contains("name=\"model\""))
        XCTAssertFalse(text.contains("Bearer"))
    }

    func testIntentBodySendsHabitsAsAnArrayWithTheLocalTimeAndZone() throws {
        let request = NSMutableURLRequest(url: URL(string: "https://\(testHost)\(VoiceEndpoint.intent)")!)

        VoiceCommandRequestBuilder.applyIntentBody(to: request, transcript: "start drink water", habits: habitNames,
                                                   now: fixedNow, timeZone: melbourne)

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try JSONDecoder().decode(VoiceIntentRequestBody.self, from: request.httpBody ?? Data())
        XCTAssertEqual(body, VoiceIntentRequestBody(transcript: "start drink water", habits: habitNames,
                                                    clientDatetime: "2026-09-28 13:04:05",
                                                    timezone: "Australia/Melbourne"))
    }

    func testEndpointsArePathsOnTheFocusBearBackend() {
        XCTAssertEqual(VoiceEndpoint.transcribe, "/voice/transcribe")
        XCTAssertEqual(VoiceEndpoint.intent, "/voice/intent")
    }

    func testStatusCodesMapToErrorsTheUserCanActOn() {
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 0), .network)
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 401), .notSignedIn)
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 403), .notSignedIn)
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 413), .recordingTooLarge)
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 429), .rateLimited)
        XCTAssertEqual(VoiceCommandResponseParser.error(forStatusCode: 502), .server(statusCode: 502))
    }

    func testAnUndecodableSuccessIsAnInvalidResponse() {
        let result = VoiceCommandResponseParser.transcript(data: Data("{}".utf8), statusCode: 200)

        XCTAssertEqual(result, .failure(.invalidResponse))
    }
}

// MARK: - Full pipeline with the network stubbed

final class VoiceCommandPipelineTests: XCTestCase {
    private var recording: URL!

    override func setUpWithError() throws {
        VoiceStubURLProtocol.reset()
        recording = FileManager.default.temporaryDirectory.appendingPathComponent("voice-command-test-\(UUID().uuidString).wav")
        try Data("RIFF-recorded-audio".utf8).write(to: recording)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: recording)
        VoiceStubURLProtocol.reset()
    }

    private func run(_ client: VoiceCommandClient = stubbedClient()) -> (outcome: VoiceCommandOutcome?, transcript: String?) {
        let pipeline = VoiceCommandPipeline(transcribe: client.transcribe, classify: client.classifyIntent)
        let finished = expectation(description: "voice command finished")
        var outcome: VoiceCommandOutcome?
        var transcript: String?
        pipeline.run(recording: recording, habits: habitNames, onTranscript: { transcript = $0 }) {
            outcome = $0
            finished.fulfill()
        }
        wait(for: [finished], timeout: 5)
        return (outcome, transcript)
    }

    func testTranscribesClassifiesAndResolvesAStartFocusAction() throws {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"  start a 45 minute focus session to write the report \n"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, json: """
            {"action":"start_focus","parameters":{"duration_minutes":45,"goal":"write the report"},
             "confidence":"high","clarification_needed":null}
            """)

        let (outcome, transcript) = run()

        XCTAssertEqual(transcript, "start a 45 minute focus session to write the report")
        guard case .perform(let action, let intent)? = outcome else { return XCTFail("expected an action, got \(String(describing: outcome))") }
        XCTAssertEqual(action, .startFocus(minutes: 45, goal: "write the report"))
        XCTAssertEqual(intent.action, "start_focus")

        let requests = VoiceStubURLProtocol.requests
        XCTAssertEqual(requests.map { $0.url?.path }, [VoiceEndpoint.transcribe, VoiceEndpoint.intent])
        XCTAssertTrue(requests.allSatisfy { $0.url?.host == testHost }, "voice must only talk to the Focus Bear backend")
        XCTAssertTrue(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == testToken })

        let upload = String(decoding: VoiceStubURLProtocol.bodies[VoiceEndpoint.transcribe] ?? Data(), as: UTF8.self)
        XCTAssertTrue(upload.contains("name=\"file\"; filename=\"\(recording.lastPathComponent)\""))
        XCTAssertTrue(upload.contains("RIFF-recorded-audio"))

        let intentBody = try JSONDecoder().decode(VoiceIntentRequestBody.self,
                                                  from: VoiceStubURLProtocol.bodies[VoiceEndpoint.intent] ?? Data())
        XCTAssertEqual(intentBody.transcript, "start a 45 minute focus session to write the report")
        XCTAssertEqual(intentBody.habits, habitNames)
        XCTAssertEqual(intentBody.timezone, "Australia/Melbourne")
    }

    func testResolvesATaskWithItsTime() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"remind me to call mom tomorrow at 9"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, json: """
            {"action":"create_task","parameters":{"task":"call mom","time":"2026-09-29 09:00:00"},"confidence":"high"}
            """)

        guard case .perform(let action, _)? = run().outcome else { return XCTFail("expected an action") }
        XCTAssertEqual(action, .createTask(name: "call mom", time: "2026-09-29 09:00:00"))
    }

    func testSilenceNeverReachesTheIntentEndpoint() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"   "}"#)

        guard case .notUnderstood? = run().outcome else { return XCTFail("expected notUnderstood") }
        XCTAssertEqual(VoiceStubURLProtocol.requests.map { $0.url?.path }, [VoiceEndpoint.transcribe])
    }

    func testLowConfidenceIsNotActedOn() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"mumble"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, json: #"{"action":"stop_focus","parameters":{},"confidence":"low"}"#)

        guard case .notUnderstood? = run().outcome else { return XCTFail("expected notUnderstood") }
    }

    func testAnActionTheAppCannotDoIsReportedAsUnsupported() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"pause my habit"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, json: #"{"action":"pause_habit","parameters":{},"confidence":"high"}"#)

        guard case .unsupported(let action)? = run().outcome else { return XCTFail("expected unsupported") }
        XCTAssertEqual(action, "pause_habit")
    }

    func testATaskWithoutANameIsNotCreated() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"remind me"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, json: #"{"action":"create_task","parameters":{},"confidence":"high"}"#)

        guard case .notUnderstood? = run().outcome else { return XCTFail("expected notUnderstood") }
    }

    func testRateLimitedTranscriptionGetsItsOwnMessage() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, status: 429, json: #"{"statusCode":429}"#)

        guard case .transcriptionFailed(let error)? = run().outcome else { return XCTFail("expected transcriptionFailed") }
        XCTAssertEqual(error as? VoiceCommandError, .rateLimited)
        XCTAssertNotEqual(VoiceCommandMessage.transcriptionFailed(error),
                          VoiceCommandMessage.transcriptionFailed(VoiceCommandError.server(statusCode: 500)))
    }

    func testOfflineIsReportedAsANetworkFailure() {
        guard case .transcriptionFailed(let error)? = run().outcome else { return XCTFail("expected transcriptionFailed") }
        XCTAssertEqual(error as? VoiceCommandError, .network)
    }

    func testSignedOutSendsNothing() {
        guard case .transcriptionFailed(let error)? = run(stubbedClient(signedIn: false)).outcome else {
            return XCTFail("expected transcriptionFailed")
        }
        XCTAssertEqual(error as? VoiceCommandError, .notSignedIn)
        XCTAssertTrue(VoiceStubURLProtocol.requests.isEmpty)
    }

    func testAnIntentServerErrorIsAClassificationFailure() {
        VoiceStubURLProtocol.stub(VoiceEndpoint.transcribe, json: #"{"text":"do the thing"}"#)
        VoiceStubURLProtocol.stub(VoiceEndpoint.intent, status: 422, json: #"{"statusCode":422}"#)

        guard case .classificationFailed(let error)? = run().outcome else { return XCTFail("expected classificationFailed") }
        XCTAssertEqual(error as? VoiceCommandError, .server(statusCode: 422))
    }

    func testEveryFailureHasAMessage() {
        let failures: [VoiceCommandError] = [.notSignedIn, .unreadableRecording, .network, .rateLimited,
                                             .recordingTooLarge, .server(statusCode: 500), .invalidResponse]
        for failure in failures {
            XCTAssertFalse(VoiceCommandMessage.transcriptionFailed(failure).isEmpty)
            XCTAssertFalse(VoiceCommandMessage.classificationFailed(failure).isEmpty)
        }
    }

    func testIntentOutcomeMapsEverySupportedAction() {
        let cases: [(String, VoiceCommandAction)] = [
            (#"{"action":"start_focus","parameters":{},"confidence":"high"}"#,
             .startFocus(minutes: VoiceCommandAction.defaultFocusMinutes, goal: nil)),
            (#"{"action":"stop_focus","parameters":{},"confidence":"high"}"#, .stopFocus),
            (#"{"action":"pause_focus","parameters":{},"confidence":"medium"}"#, .pauseFocus),
            (#"{"action":"resume_focus","parameters":{},"confidence":"high"}"#, .resumeFocus),
            (#"{"action":"start_habit","parameters":{"habit_name":"Stretch"},"confidence":"high"}"#, .startHabit(name: "Stretch")),
            (#"{"action":"get_focus_stats","parameters":{},"confidence":"high"}"#, .focusStats),
        ]
        for (json, expected) in cases {
            guard case .perform(let action, _) = VoiceCommandPipeline.outcome(for: .success(decodeIntent(json))) else {
                XCTFail("expected an action for \(json)")
                continue
            }
            XCTAssertEqual(action, expected)
        }
    }
}

// MARK: - No API key literals in the app

final class SourceSecretsTests: XCTestCase {
    private static let scannedDirectories = ["FocusBear", "FBHelper"]
    private static let scannedExtensions: Set<String> = ["swift", "m", "mm", "h", "plist", "json", "xcconfig", "strings", "js", "py"]
    /// Fewer files than this means the scan pointed at the wrong place and proved nothing.
    private static let minimumScannedFiles = 100
    /// OpenAI secret keys (`sk-…`, `sk-proj-…`). The lookbehind skips words that merely end in "sk-", like "task-".
    private static let openAIKeyPattern = #"(?<![A-Za-z0-9_-])sk-(?:proj-)?[A-Za-z0-9_-]{20,}"#

    /// Anything compiled into the app is readable with `strings`; an OpenAI key shipped that way until
    /// Mac-App#2732. Keys belong in the backend's secret store. The failure names files, never the match.
    func testNoOpenAIKeyLiteralInAppSources() throws {
        let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pattern = try NSRegularExpression(pattern: Self.openAIKeyPattern)
        var scannedFiles = 0
        var offenders: [String] = []

        for directory in Self.scannedDirectories {
            let root = repoRoot.appendingPathComponent(directory)
            guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { continue }
            for case let file as URL in files where Self.scannedExtensions.contains(file.pathExtension) {
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                scannedFiles += 1
                if pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                    offenders.append(file.path.replacingOccurrences(of: repoRoot.path + "/", with: ""))
                }
            }
        }

        XCTAssertGreaterThanOrEqual(scannedFiles, Self.minimumScannedFiles)
        XCTAssertEqual(offenders, [], "API key literal in the app sources; move it to the backend secret store")
    }
}
