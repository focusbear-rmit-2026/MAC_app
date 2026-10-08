import XCTest
@testable import Focus_Bear

/// Every test uses a throwaway defaults suite and an in-memory secret store: app-hosted tests run on
/// the developer's Mac, where `UserDefaults.standard` and the login keychain are the user's real ones.
final class AppPasswordStoreTests: XCTestCase {
    private static let legacyKey = "kUserdefaultsAppPasswordtest-user"
    private static let password = "hunter2"
    private static let encoded = password.toBase64()

    private var isolated: IsolatedDefaults!
    private var secrets: InMemorySecretItemStore!
    private var store: AppPasswordStore!

    override func setUp() {
        super.setUp()
        isolated = IsolatedDefaults()
        secrets = InMemorySecretItemStore()
        store = AppPasswordStore(defaults: isolated.defaults, secrets: secrets, legacyKey: Self.legacyKey)
    }

    override func tearDown() {
        isolated.destroy()
        isolated = nil
        secrets = nil
        store = nil
        super.tearDown()
    }

    private func storedStrings() -> [String] {
        isolated.defaults.dictionaryRepresentation().values.compactMap { $0 as? String }
    }

    func testMigrationMovesTheLegacyValueOutOfDefaultsOnceTheKeychainCopyReadsBack() {
        isolated.defaults.set(Self.encoded, forKey: Self.legacyKey)

        XCTAssertTrue(store.migrateLegacyValue())

        XCTAssertNil(isolated.defaults.object(forKey: Self.legacyKey))
        XCTAssertFalse(storedStrings().contains { $0.contains(Self.encoded) || $0.contains(Self.password) })
        XCTAssertEqual(secrets.read(account: Self.legacyKey), .found(Self.encoded))
        XCTAssertTrue(store.isSet)
        XCTAssertEqual(store.encodedValue, Self.encoded)
        XCTAssertTrue(store.matches(Self.password))
        XCTAssertFalse(store.matches("wrong"))
    }

    func testLockedKeychainKeepsTheLegacyValueAndTheNextLaunchFinishesTheMigration() {
        isolated.defaults.set(Self.encoded, forKey: Self.legacyKey)
        secrets.isAvailable = false

        XCTAssertFalse(store.migrateLegacyValue())
        XCTAssertEqual(isolated.defaults.string(forKey: Self.legacyKey), Self.encoded, "never drop the only copy")
        XCTAssertTrue(store.isSet)
        XCTAssertTrue(store.matches(Self.password))
        XCTAssertEqual(store.encodedValue, Self.encoded)

        secrets.isAvailable = true
        XCTAssertTrue(store.migrateLegacyValue())
        XCTAssertNil(isolated.defaults.object(forKey: Self.legacyKey))
        XCTAssertTrue(store.matches(Self.password))
    }

    func testMigrationIsIdempotent() {
        isolated.defaults.set(Self.encoded, forKey: Self.legacyKey)
        XCTAssertTrue(store.migrateLegacyValue())
        let verifier = isolated.defaults.dictionary(forKey: store.verifierKey)?[AppPasswordVerifier.Field.hash] as? Data

        XCTAssertTrue(store.migrateLegacyValue())

        XCTAssertEqual(isolated.defaults.dictionary(forKey: store.verifierKey)?[AppPasswordVerifier.Field.hash] as? Data, verifier)
        XCTAssertTrue(store.matches(Self.password))
    }

    func testAnUnreadableKeychainNeverLocksTheUserOut() {
        store.set(encoded: Self.encoded)
        secrets.isAvailable = false

        XCTAssertTrue(store.isSet)
        XCTAssertTrue(store.matches(Self.password), "the verifier lives in defaults, not the keychain")
        XCTAssertNil(store.encodedValue)
        XCTAssertTrue(store.isEncodedValueUnavailable, "settings upload must wait rather than send no password")
    }

    func testACorrectEntryRebuildsAMissingKeychainCopy() {
        store.set(encoded: Self.encoded)
        // What a re-signed build sees: its own (empty) keychain account.
        secrets.delete(account: Self.legacyKey)
        XCTAssertTrue(store.isEncodedValueUnavailable)

        XCTAssertTrue(store.matches(Self.password))

        XCTAssertEqual(store.encodedValue, Self.encoded)
        XCTAssertFalse(store.isEncodedValueUnavailable)
    }

    func testAWrongEntryDoesNotTouchTheKeychain() {
        store.set(encoded: Self.encoded)
        secrets.delete(account: Self.legacyKey)

        XCTAssertFalse(store.matches("wrong"))

        XCTAssertEqual(secrets.read(account: Self.legacyKey), .missing)
    }

    func testTwentyFourHourResetClearsThePasswordEvenWhenTheKeychainIsLocked() {
        store.set(encoded: Self.encoded)
        secrets.isAvailable = false

        store.clear()

        XCTAssertFalse(store.isSet)
        XCTAssertNil(isolated.defaults.object(forKey: Self.legacyKey))
        XCTAssertNil(isolated.defaults.object(forKey: store.verifierKey))
        XCTAssertFalse(store.matches(Self.password))
    }

    func testClearRemovesTheKeychainCopy() {
        store.set(encoded: Self.encoded)
        store.clear()
        XCTAssertEqual(secrets.read(account: Self.legacyKey), .missing)
        XCTAssertNil(store.encodedValue)
    }

    func testServerValueReplacesThePassword() {
        store.set(encoded: Self.encoded)
        let replacement = "correct horse".toBase64()

        store.adoptServerValue(replacement)

        XCTAssertTrue(store.matches("correct horse"))
        XCTAssertFalse(store.matches(Self.password))
        XCTAssertEqual(store.encodedValue, replacement)
    }

    func testSettingWhileTheKeychainIsLockedKeepsTheValueForTheNextUpload() {
        secrets.isAvailable = false

        XCTAssertFalse(store.set(encoded: Self.encoded))

        XCTAssertEqual(store.encodedValue, Self.encoded)
        XCTAssertTrue(store.matches(Self.password))
    }

    func testEachVerifierHasItsOwnSalt() {
        let first = AppPasswordVerifier.make(password: Self.password)
        let second = AppPasswordVerifier.make(password: Self.password)
        XCTAssertNotEqual(first[AppPasswordVerifier.Field.salt] as? Data, second[AppPasswordVerifier.Field.salt] as? Data)
        XCTAssertNotEqual(first[AppPasswordVerifier.Field.hash] as? Data, second[AppPasswordVerifier.Field.hash] as? Data)
        XCTAssertTrue(AppPasswordVerifier.matches(password: Self.password, record: first))
        XCTAssertTrue(AppPasswordVerifier.matches(password: Self.password, record: second))
    }
}

final class ScriptToDoListTests: XCTestCase {
    private static let accountID = "user-1"

    private final class FakeServer {
        var requests: [(path: String, accountID: String)] = []
        var response: (Data?, Int) = (nil, 0)

        func fetch(path: String, accountID: String, completion: @escaping (Data?, Int) -> Void) {
            requests.append((path, accountID))
            completion(response.0, response.1)
        }
    }

    private func respond(_ server: FakeServer, accountID: String? = ScriptToDoListTests.accountID,
                         request: ScriptToDoListRequest) -> Result<String, ScriptToDoListError>? {
        let responder = ScriptToDoListResponder(accountID: { accountID }, fetch: server.fetch)
        var result: Result<String, ScriptToDoListError>?
        responder.respond(to: request) { result = $0 }
        return result
    }

    private func parse(_ status: String? = nil, _ sortMode: String? = nil, _ take: Int? = nil) -> ScriptToDoListRequest? {
        try? ScriptToDoListRequest.parse(status: status, sortMode: sortMode, take: take).get()
    }

    func testDefaultsMatchTheSkillsTopTasksQuery() {
        let request = parse()
        XCTAssertEqual(request?.status, .notStarted)
        XCTAssertEqual(request?.sortMode, .smart)
        XCTAssertEqual(request?.take, ToDoPaging.tasksPerPage)
    }

    func testParsingIsCaseInsensitiveAndAllDropsTheStatusFilter() {
        XCTAssertEqual(parse("in_progress", "due_date")?.status, .inProgress)
        XCTAssertEqual(parse("in_progress", "due_date")?.sortMode, .dueDate)
        XCTAssertNotNil(parse("all"))
        XCTAssertNil(parse("all")?.status)
        XCTAssertFalse(parse("all")?.query.path.contains("status=") ?? true)
    }

    func testTakeIsClampedToWhatTheServerAccepts() {
        XCTAssertEqual(parse(nil, nil, 500)?.take, ToDoPaging.tasksPerPage)
        XCTAssertEqual(parse(nil, nil, 0)?.take, 1)
    }

    func testUnknownArgumentsAreRejectedBeforeAnyRequest() {
        XCTAssertEqual(ScriptToDoListRequest.parse(status: "DONE", sortMode: nil, take: nil), .failure(.invalidStatus("DONE")))
        XCTAssertEqual(ScriptToDoListRequest.parse(status: nil, sortMode: "RANDOM", take: nil), .failure(.invalidSortMode("RANDOM")))
    }

    func testReturnsTheTasksInServerOrderForTheSignedInAccount() throws {
        let server = FakeServer()
        let body = #"{"data":[{"id":"b","title":"Second by id, first by SMART"},{"id":"a","title":"Other"}],"meta":{"page":1}}"#
        server.response = (Data(body.utf8), 200)

        let result = respond(server, request: try XCTUnwrap(parse(nil, nil, 10)))

        let json = try XCTUnwrap(try result?.get())
        let tasks = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]])
        XCTAssertEqual(tasks.compactMap { $0["id"] as? String }, ["b", "a"])
        XCTAssertFalse(json.contains("meta"))
        XCTAssertEqual(server.requests.count, 1)
        XCTAssertEqual(server.requests.first?.accountID, Self.accountID)
        let path = try XCTUnwrap(server.requests.first?.path)
        XCTAssertTrue(path.hasPrefix(ToDoEndpoint.toDo + "?"))
        for parameter in ["take=10", "status=NOT_STARTED", "sort_mode=SMART"] {
            XCTAssertTrue(path.contains(parameter), path)
        }
    }

    func testSignedOutAppAnswersWithoutCallingTheServer() {
        let server = FakeServer()
        XCTAssertEqual(respond(server, accountID: nil, request: parse()!), .failure(.notSignedIn))
        XCTAssertEqual(respond(server, accountID: "", request: parse()!), .failure(.notSignedIn))
        XCTAssertTrue(server.requests.isEmpty)
    }

    func testServerFailuresBecomeScriptErrors() {
        let server = FakeServer()
        server.response = (Data(#"{"message":"Unauthorized"}"#.utf8), 401)
        XCTAssertEqual(respond(server, request: parse()!), .failure(.requestFailed(statusCode: 401)))

        server.response = (Data("not json".utf8), 200)
        XCTAssertEqual(respond(server, request: parse()!), .failure(.unreadableResponse))
    }

    func testErrorNumbersAreDistinct() {
        let errors: [ScriptToDoListError] = [.invalidStatus(""), .invalidSortMode(""), .notSignedIn,
                                             .requestFailed(statusCode: 0), .unreadableResponse]
        XCTAssertEqual(Set(errors.map(\.number)).count, errors.count)
    }
}

/// Build-structure guards for the AppleScript interface. It has shipped with the dictionary missing
/// from the bundle and the glue file missing from the build (a Sources entry with no build-file behind
/// it), which silently drops every scripting command — including the `list to dos` the
/// focusbear-tasks skill reads the to-do list through now the token is no longer in the shared suite.
final class ScriptingInterfaceWiringTests: XCTestCase {
    private static let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    private static let projectPath = "FocusBear.xcodeproj/project.pbxproj"
    private static let infoPlistPath = "FocusBear/Info.plist"
    private static let dictionaryPath = "FocusBear/FocusBear.sdef"
    private static let scriptingSourcePath = "FocusBear/AppleScriptScripting.swift"
    private static let appTargetName = "Focus Bear"
    private static let sourcesPhase = "Sources"
    private static let resourcesPhase = "Resources"
    private static let listToDosCommand = "list to dos"
    private static let listToDosClass = "FBListToDosCommand"
    /// Provided by AppKit, not by the scripting sources.
    private static let systemScriptingClasses: Set<String> = ["NSApplication"]

    private func contents(of relativePath: String) throws -> String {
        try String(contentsOf: Self.repoRoot.appendingPathComponent(relativePath), encoding: .utf8)
    }

    private func captures(_ pattern: String, in text: String) throws -> [[String]] {
        let expression = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        return expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).map { match in
            (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).map { String(text[$0]) } }
        }
    }

    /// File names in one of the app target's build phases, counting only entries backed by a real
    /// PBXBuildFile → PBXFileReference pair (a dangling phase entry compiles nothing).
    private func appTargetFiles(inPhase phase: String) throws -> Set<String> {
        let project = try contents(of: Self.projectPath)
        let target = try XCTUnwrap(try captures(#"/\* \#(Self.appTargetName) \*/ = \{\s*isa = PBXNativeTarget;.*?buildPhases = \((.*?)\);"#,
                                                in: project).first?.first, "app target not found")
        let phaseID = try XCTUnwrap(try captures(#"(\w+) /\* \#(phase) \*/"#, in: target).first?.first, "\(phase) phase not found")
        let entries = try XCTUnwrap(try captures(#"\t\#(phaseID) /\* \#(phase) \*/ = \{.*?files = \((.*?)\);"#,
                                                 in: project).first?.first, "\(phase) phase body not found")
        let buildFiles = Dictionary(try captures(#"\t(\w+) /\* [^\n]*? \*/ = \{isa = PBXBuildFile; fileRef = (\w+)"#, in: project)
            .map { ($0[0], $0[1]) }, uniquingKeysWith: { first, _ in first })
        let paths = Dictionary(try captures(#"\t(\w+) /\* [^\n]*? \*/ = \{isa = PBXFileReference;[^\n]*? path = "?([^";]+)"?;"#, in: project)
            .map { ($0[0], ($0[1] as NSString).lastPathComponent) }, uniquingKeysWith: { first, _ in first })
        return Set(try captures(#"(\w+) /\* [^\n]*? in \#(phase) \*/"#, in: entries).compactMap { entry in
            buildFiles[entry[0]].flatMap { paths[$0] }
        })
    }

    private func dictionary() throws -> XMLDocument {
        try XMLDocument(contentsOf: Self.repoRoot.appendingPathComponent(Self.dictionaryPath), options: [])
    }

    func testTheAppTargetCompilesTheScriptingGlue() throws {
        XCTAssertTrue(try appTargetFiles(inPhase: Self.sourcesPhase).contains((Self.scriptingSourcePath as NSString).lastPathComponent))
    }

    func testTheAppBundlesTheScriptingDictionary() throws {
        XCTAssertTrue(try appTargetFiles(inPhase: Self.resourcesPhase).contains((Self.dictionaryPath as NSString).lastPathComponent))
    }

    func testInfoPlistEnablesScriptingWithTheBundledDictionary() throws {
        let data = try Data(contentsOf: Self.repoRoot.appendingPathComponent(Self.infoPlistPath))
        let plist = try XCTUnwrap(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        XCTAssertEqual(plist["NSAppleScriptEnabled"] as? Bool, true)
        XCTAssertEqual(plist["OSAScriptingDefinition"] as? String, (Self.dictionaryPath as NSString).lastPathComponent)
    }

    func testTheDictionaryDeclaresListToDosWithTheArgumentsTheCommandReads() throws {
        let command = try XCTUnwrap(try dictionary().nodes(forXPath: "//command[@name='\(Self.listToDosCommand)']").first as? XMLElement)
        let commandClass = try command.nodes(forXPath: "cocoa/@class").first?.stringValue
        XCTAssertEqual(commandClass, Self.listToDosClass)
        XCTAssertEqual(try command.nodes(forXPath: "result/@type").first?.stringValue, "text")
        let keys = try command.nodes(forXPath: "parameter/cocoa/@key").compactMap(\.stringValue)
        XCTAssertFalse(keys.isEmpty)
        let scripting = try contents(of: Self.scriptingSourcePath)
        for key in keys {
            XCTAssertTrue(scripting.contains("\"\(key)\""), "\(Self.listToDosClass) never reads the \(key) argument")
        }
    }

    func testEveryScriptingClassTheDictionaryNamesIsExportedUnderThatName() throws {
        let classes = Set(try dictionary().nodes(forXPath: "//cocoa/@class").compactMap(\.stringValue))
            .subtracting(Self.systemScriptingClasses)
        XCTAssertTrue(classes.contains(Self.listToDosClass))
        let scripting = try contents(of: Self.scriptingSourcePath)
        for name in classes {
            XCTAssertTrue(scripting.contains("@objc(\(name))"), "\(name) is not exported to the Objective-C runtime")
        }
    }
}

final class LegacyLogScrubberTests: XCTestCase {
    /// Shaped like a JWT, signed by nobody.
    private let fakeJWT = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.c2lnbmF0dXJlLW5vdC1yZWFs"
    private var folder: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        folder = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyLogScrubberTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: folder)
        folder = nil
        try super.tearDownWithError()
    }

    func testRewritesSecretsOnceAndKeepsTheCreationDateRotationUses() throws {
        let log = folder.appendingPathComponent("Debug_Logs - 2026-09-01.txt")
        let text = "2026-09-01 10:00:00 - accessToken is:- \(fakeJWT)\n2026-09-01 10:00:01 - signed in as someone@example.com\n"
        try Data(text.utf8).write(to: log)
        let created = Date(timeIntervalSince1970: 1_756_000_000)
        try FileManager.default.setAttributes([.creationDate: created], ofItemAtPath: log.path)

        XCTAssertTrue(LegacyLogScrubber.scrub(file: log))

        let scrubbed = try String(contentsOf: log, encoding: .utf8)
        XCTAssertFalse(scrubbed.contains(fakeJWT))
        XCTAssertFalse(scrubbed.contains("someone@example.com"))
        XCTAssertTrue(scrubbed.hasPrefix("2026-09-01 10:00:00 - accessToken is:- "))
        let attributes = try FileManager.default.attributesOfItem(atPath: log.path)
        XCTAssertEqual(attributes[.creationDate] as? Date, created)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.int16Value, LogFilePermissions.fileMode)
        XCTAssertFalse(LegacyLogScrubber.scrub(file: log), "redacting twice changes nothing")
    }

    func testLeavesCleanFilesUntouched() throws {
        let log = folder.appendingPathComponent("Debug_Logs.txt")
        let text = "2026-09-01 10:00:00 - checkLogFileRotation\n"
        try Data(text.utf8).write(to: log)

        XCTAssertFalse(LegacyLogScrubber.scrub(file: log))

        XCTAssertEqual(try String(contentsOf: log, encoding: .utf8), text)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertEqual(leftovers, ["Debug_Logs.txt"])
    }
}

final class LogContentScrubberTests: XCTestCase {
    private let task = "Renew the passport for Lisbon"

    func testRemovesDumpsWithTheirContinuationLinesAndKeepsTheLabel() {
        let text = """
        2026-10-01 09:00:00 - json is:- {
            habits = (
                { name = "Take morning meds"; }
            );
        }
        2026-10-01 09:00:01 - chatGPTIsURLSafe: json data for api is:- ["intention": "\(task)"]
        2026-10-01 09:00:02 - checkLogFileRotation

        """
        let scrubbed = LogContentScrubber.scrub(text)
        XCTAssertEqual(scrubbed, """
        2026-10-01 09:00:00 - json is:- \(LogContentScrubber.removedDump)
        2026-10-01 09:00:01 - chatGPTIsURLSafe: json data for api is:- \(LogContentScrubber.removedDump)
        2026-10-01 09:00:02 - checkLogFileRotation

        """)
    }

    func testDescribesCurrentTasksDeepLinksRequestPathsAndFocusButtonText() {
        let text = [
            "2026-10-01 09:00:00 - currentTask in is URL Safe to use:Optional(\"\(task)\")",
            "2026-10-01 09:00:01 - event-about-to-start:- focusbear://event-about-to-start?event_title=Dentist&minutes=5",
            "2026-10-01 09:00:01 - func:- open url focusbear://event-about-to-start?start=2026-10-01 09:30:00&event_title=Lisbon trip",
            "2026-10-01 09:00:02 - func call:- api todo GET /to-do/search?title=passport&take=20",
            "2026-10-01 09:00:03 - FocusButton: SendCmd >> SET|GOAL|\(task)",
        ].joined(separator: "\n")
        let scrubbed = LogContentScrubber.scrub(text)
        for value in ["passport", "Dentist", "Lisbon"] {
            XCTAssertFalse(scrubbed.contains(value), "\(value) survived in \(scrubbed)")
        }
        for kept in ["currentTask in is URL Safe to use:<text:", "minutes=5", "api todo GET /to-do/search?title=<text:",
                     "take=20", "FocusButton: SendCmd >> SET|GOAL|<text:"] {
            XCTAssertTrue(scrubbed.contains(kept), "\(kept) missing from \(scrubbed)")
        }
        XCTAssertEqual(LogContentScrubber.scrub(scrubbed), scrubbed, "scrubbing twice changes nothing")
    }

    func testScrubsEachEntryAsItIsLoggedSoCallSitesThatStillLogTheOldWayAreCaught() {
        let dump = "evaluateAccountabilityConversation: json data for api is:- [\"goal\": \"\(task)\",\n \"recent\": []]"
        XCTAssertEqual(LogContentScrubber.scrubEntry(dump),
                       "evaluateAccountabilityConversation: json data for api is:- \(LogContentScrubber.removedDump)")
        let deepLink = LogContentScrubber.scrubEntry("event-about-to-start:- focusbear://event-about-to-start?event_title=Dentist&minutes=5")
        XCTAssertFalse(deepLink.contains("Dentist"), deepLink)
        XCTAssertTrue(deepLink.hasSuffix("&minutes=5"), deepLink)
        let described = "json is:- <dictionary keys=habits,id>"
        XCTAssertEqual(LogContentScrubber.scrubEntry(described), described, "a described payload is kept")
        XCTAssertEqual(LogContentScrubber.scrubEntry("checkLogFileRotation"), "checkLogFileRotation")
    }

    func testLeavesWhatCurrentBuildsWriteAlone() {
        let text = "2026-10-05 13:00:00 - currentTask in is App Safe :<none>\n"
            + "2026-10-05 13:00:01 - FocusButton: HandleLine << INFO|RUNNING|1200|FOCUS|<text:1a2b:len29>\n"
        XCTAssertEqual(LogContentScrubber.scrub(text), text)
    }
}

/// The AppleScript commands read and write the Day Plan and the block lists through the same sealed
/// stores the app uses. Under the logic test host `SecureStore.shared` is a throwaway store keyed in
/// memory (see `SecureStore.shared`), so these run the real sealing path on no real data.
final class ScriptingEncryptedDataPathTests: XCTestCase {
    private let dayPlan = DayPlanTaskStore.shared
    private let today = Date()
    private var createdTaskIDs: [String] = []

    private var accountScope: String { SecureStore.accountScope(for: SecureStore.logicTestHostAccountId) }

    override func setUpWithError() throws {
        try super.setUpWithError()
        XCTAssertFalse(DayPlanTaskStore.mockMode, "mock mode never persists, so it would prove nothing")
        XCTAssertTrue(SecureStore.shared.currentState.isReady,
                      "the logic test host's store must be encrypting: \(SecureStore.shared.currentState.summary)")
    }

    override func tearDown() {
        createdTaskIDs.forEach { dayPlan.delete(id: $0, for: today) }
        SecureStore.shared.flush()
        super.tearDown()
    }

    func testMakeNewTaskIsSealedAtRestAndReadsBackThroughTheScriptingObject() throws {
        let title = "Scripted task \(UUID().uuidString)"
        let staged = FBScriptTask()
        staged.name = title
        staged.duration = 25
        staged.project = "Grants"
        staged.materializeIfNeeded()
        createdTaskIDs.append(staged.uniqueID)

        let bound = FBScriptTask(taskID: staged.uniqueID)
        XCTAssertEqual(bound.name, title)
        XCTAssertEqual(bound.duration, 25)
        XCTAssertEqual(bound.project, "Grants")
        XCTAssertFalse(bound.completed)
        XCTAssertFalse(bound.modifiedByUser, "a scripted write is never reported as the user's")

        try assertSealed(title, forKey: kUserdefaultsDayPlanTasksByDay)
        XCTAssertEqual(try sealedDayPlanTask(id: staged.uniqueID)?.title, title)
    }

    func testSettingPropertiesAndCompletingWriteThroughTheSealedStore() throws {
        let seeded = DayPlanTask(title: "Seeded \(UUID().uuidString)", durationMinutes: 10)
        dayPlan.add(seeded, for: today, source: .appleScript)
        createdTaskIDs.append(seeded.id)

        let task = FBScriptTask(taskID: seeded.id)
        task.duration = 40
        task.project = "Admin"
        task.completed = true

        try assertSealed(seeded.title, forKey: kUserdefaultsDayPlanTasksByDay)
        let stored = try XCTUnwrap(try sealedDayPlanTask(id: seeded.id))
        XCTAssertEqual(stored.durationMinutes, 40)
        XCTAssertEqual(stored.project, "Admin")
        XCTAssertTrue(stored.done)
        XCTAssertNil(stored.lastUserModifiedAt)
        XCTAssertFalse(dayPlan.recentlyUserModifiedTasks(since: nil, for: today).contains { $0.id == seeded.id })
    }

    func testRecentlyModifiedTasksReportsUserEditsReadFromTheSealedStore() throws {
        let edited = DayPlanTask(title: "User edit \(UUID().uuidString)", durationMinutes: 10)
        dayPlan.add(edited, for: today, source: .user)
        createdTaskIDs.append(edited.id)

        let reported = dayPlan.recentlyUserModifiedTasks(since: nil, for: today).map { FBScriptTask(taskID: $0.id) }
        XCTAssertTrue(reported.contains { $0.uniqueID == edited.id && $0.name == edited.title && $0.modifiedByUser })
        try assertSealed(edited.title, forKey: kUserdefaultsDayPlanTasksByDay)
    }

    func testStartFocusSessionFindsBlockListsSealedAtRest() throws {
        let modeName = "Scripted block list \(UUID().uuidString)"
        let previousModes = arrFocusType
        let previousStored = SensitiveDefaults.object(forKey: kUserdefaultsArrFocusTypes)
        defer {
            arrFocusType = previousModes
            SensitiveDefaults.set(previousStored, forKey: kUserdefaultsArrFocusTypes)
            SecureStore.shared.flush()
        }
        SensitiveDefaults.set([["id": "scripted-mode", "name": modeName]], forKey: kUserdefaultsArrFocusTypes)
        arrFocusType = []

        FBStartFocusSessionCommand.hydrateFocusModesIfNeeded()

        XCTAssertEqual(FBStartFocusSessionCommand.focusModeIndex(matching: modeName.uppercased()), 0)
        XCTAssertEqual(FBStartFocusSessionCommand.focusModeIndex(matching: "scripted-mode"), 0)
        try assertSealed(modeName, forKey: kUserdefaultsArrFocusTypes)
    }

    /// The value is on disk only as ciphertext, opens with the account's key, and left nothing in
    /// the plaintext defaults.
    private func assertSealed(_ text: String, forKey key: String, file: StaticString = #filePath, line: UInt = #line) throws {
        SecureStore.shared.flush()
        let sealed = try Data(contentsOf: SecureStore.shared.valueFile(forKey: key, scope: accountScope))
        XCTAssertNil(sealed.range(of: Data(text.utf8)), "\(key) holds plaintext on disk", file: file, line: line)
        XCTAssertNotNil(try openSealedValue(forKey: key).range(of: Data(text.utf8)), "\(key) did not seal the value", file: file, line: line)
        XCTAssertNil(SecureStore.shared.legacyDefaults.object(forKey: key), "\(key) was written to plaintext defaults", file: file, line: line)
    }

    private func openSealedValue(forKey key: String) throws -> Data {
        let sealed = try Data(contentsOf: SecureStore.shared.valueFile(forKey: key, scope: accountScope))
        return try SecureStore.shared.open(sealed, slot: SecureStore.slot(forKey: key), scope: accountScope)
    }

    private func sealedDayPlanTask(id: String) throws -> DayPlanTask? {
        let payload = try openSealedValue(forKey: kUserdefaultsDayPlanTasksByDay)
        let record = try XCTUnwrap(try PropertyListSerialization.propertyList(from: payload, format: nil) as? [String: Any])
        let json = try XCTUnwrap(record.values.compactMap { $0 as? Data }.first)
        let byDay = try JSONDecoder().decode([String: [DayPlanTask]].self, from: json)
        return byDay.values.flatMap { $0 }.first { $0.id == id }
    }
}

/// Source-level guards: the at-rest rules are easy to undo with one innocent-looking line.
final class PlaintextSecretSourceTests: XCTestCase {
    private static let scannedDirectories = ["FocusBear", "FBHelper"]
    /// Fewer files than this means the scan pointed at the wrong place and proved nothing.
    private static let minimumScannedFiles = 100

    private static let repoRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()

    private func swiftSources() -> [(path: String, text: String)] {
        var sources: [(String, String)] = []
        for directory in Self.scannedDirectories {
            let root = Self.repoRoot.appendingPathComponent(directory)
            guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { continue }
            for case let file as URL in files where file.pathExtension == "swift" {
                guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
                sources.append((file.path.replacingOccurrences(of: Self.repoRoot.path + "/", with: ""), text))
            }
        }
        return sources
    }

    private func offendingFiles(matching pattern: String, except allowed: Set<String> = []) throws -> [String] {
        let expression = try NSRegularExpression(pattern: pattern)
        let sources = swiftSources()
        XCTAssertGreaterThanOrEqual(sources.count, Self.minimumScannedFiles)
        return sources.filter { source in
            !allowed.contains(source.path)
                && expression.firstMatch(in: source.text, range: NSRange(source.text.startIndex..., in: source.text)) != nil
        }.map(\.path).sorted()
    }

    func testTheAppPasswordIsOnlyStoredThroughAppPasswordStore() throws {
        XCTAssertEqual(try offendingFiles(matching: #"UserDefaults[^\n]*kUserdefaultsAppPassword"#), [],
                       "use SettingsManagerObject.appPassword; the plaintext key is legacy only")
    }

    func testTheSharedSuiteTokenKeyIsOnlyNamedToDeleteIt() throws {
        XCTAssertEqual(try offendingFiles(matching: "kUserdefaultsSharedAccessToken",
                                          except: ["FBHelper/SharedSuiteIdentity.swift"]), [])
    }

    func testNoLogLineInterpolatesAToken() throws {
        XCTAssertEqual(try offendingFiles(matching: #"addLog\(text:[^\n]*\\\((token|[^)]*accessToken|[^)]*refreshToken)"#), [])
    }

    /// Pages and window titles go to the log as `LogPrivacy.site` / `LogPrivacy.text`; the full values
    /// only to the 30-minute `BrowsingHistory`. The exception logs an API request URL, not a page.
    func testNoLogLineWritesAPageOrAWindowTitle() throws {
        XCTAssertEqual(try offendingFiles(
            matching: #"addLog\(text: ?"[^\n]*\\\((url|tabUrl|fullUrl|checkedUrl|extractedUrl|videoUrl|windowTitle|tabTitle|tab_title|title|context\.itemLabel|currentBrowserUrlForAi)\)"#,
            except: ["FocusBear/LateNoMoreDismissSync.swift"]), [])
    }

    func testTheScriptingInterfaceNeverHandlesCredentials() throws {
        let scripting = try String(contentsOf: Self.repoRoot.appendingPathComponent("FocusBear/AppleScriptScripting.swift"), encoding: .utf8)
        for credential in ["accessToken", "refreshToken", "credentialsManager", "Authorization"] {
            XCTAssertFalse(scripting.contains(credential), credential)
        }
    }
}
