import XCTest
@testable import Focus_Bear

final class LogRedactorTests: XCTestCase {
    /// Shaped like a JWT, signed by nobody.
    private let fakeJWT = "eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ0ZXN0LXVzZXIifQ.c2lnbmF0dXJlLW5vdC1yZWFs"

    func testRemovesJWTsWhereverTheyAppear() {
        let line = "api call failed, accessToken is:- \(fakeJWT) retrying"
        let redacted = LogRedactor.redact(line)
        XCTAssertFalse(redacted.contains(fakeJWT))
        XCTAssertTrue(redacted.contains(LogRedactor.redactedJWT))
        XCTAssertTrue(redacted.hasPrefix("api call failed"))
    }

    func testRemovesBearerCredentials() {
        let redacted = LogRedactor.redact("Authorization: Bearer abc.DEF-123_xyz==")
        XCTAssertEqual(redacted, "Authorization: Bearer \(LogRedactor.redactedValue)")
    }

    func testRemovesTokenFieldsInJSONAndDictionaryDescriptions() {
        let json = #"{"access_token":"opaque-access","refresh_token": "opaque-refresh","id_token":"x"}"#
        let description = "json is:- {\n    accessToken = opaqueAccess;\n    refreshToken = opaqueRefresh;\n}"
        for line in [json, description] {
            let redacted = LogRedactor.redact(line)
            for secret in ["opaque-access", "opaque-refresh", "opaqueAccess", "opaqueRefresh"] {
                XCTAssertFalse(redacted.contains(secret), "\(secret) survived in \(redacted)")
            }
        }
    }

    func testRemovesPasswordValues() {
        let lines = [
            #"{"password":"hunter2"}"#,
            "kAppPassword = aHVudGVyMg==;",
            #"body: {"new_password": "correct horse"}"#,
        ]
        for line in lines {
            let redacted = LogRedactor.redact(line)
            XCTAssertTrue(redacted.contains(LogRedactor.redactedValue), redacted)
            for secret in ["hunter2", "aHVudGVyMg==", "correct horse"] {
                XCTAssertFalse(redacted.contains(secret), "\(secret) survived in \(redacted)")
            }
        }
    }

    func testLeavesPasswordFlagNamesAndBooleanValuesAlone() {
        let lines = [
            "kUserdefaultsPasswordRequireInQuit = 1;",
            "PasswordRequireInSettings: true",
            "hasPassword = 0;",
            "password gate shown for quit",
        ]
        for line in lines {
            XCTAssertEqual(LogRedactor.redact(line), line)
        }
    }

    func testHashesEmailsStablyAndCaseInsensitively() {
        let first = LogRedactor.redact("signed in as Someone@Example.com")
        let second = LogRedactor.redact("logout someone@example.com")
        XCTAssertFalse(first.localizedCaseInsensitiveContains("someone@example.com"))
        let token = first.components(separatedBy: " ").last
        XCTAssertNotNil(token)
        XCTAssertTrue(token?.hasPrefix("<email:") ?? false)
        XCTAssertTrue(second.hasSuffix(token ?? "missing"))
    }

    func testLeavesOrdinaryLinesUntouched() {
        let line = "checkAppFromAi: Safari window title Focus Bear docs https://focusbear.io/help?q=1"
        XCTAssertEqual(LogRedactor.redact(line), line)
    }
}

final class LogRedactorURLSecretTests: XCTestCase {
    func testRemovesCredentialsCarriedInURLQueries() {
        let line = "open url https://example.org/cb?code=abc123&email_token=e-secret&signupToken=s-secret"
            + "&X-Amz-Signature=sig-secret&X-Amz-Credential=AKIAEXAMPLE&page=2"
        let redacted = LogRedactor.redact(line)
        for secret in ["abc123", "e-secret", "s-secret", "sig-secret", "AKIAEXAMPLE"] {
            XCTAssertFalse(redacted.contains(secret), "\(secret) survived in \(redacted)")
        }
        XCTAssertTrue(redacted.hasSuffix("&page=2"), redacted)
        XCTAssertEqual(LogRedactor.redact(redacted), redacted, "redacting twice changes nothing")
    }

    func testLeavesTokenFlagsAlone() {
        for line in ["hasToken = 0;", "isTokenExpired: true", "[token-refresh] REQUEST_ACCESS_TOKEN reason=expired"] {
            XCTAssertEqual(LogRedactor.redact(line), line)
        }
    }
}

final class LogPrivacyTests: XCTestCase {
    private let task = "Renew the passport for Lisbon"

    func testTextIsAStableShortDescriptionThatNeverHoldsTheValue() {
        let described = LogPrivacy.text(task)
        XCTAssertFalse(described.contains("passport"))
        XCTAssertEqual(described, LogPrivacy.text(task), "the same value must read the same across lines")
        XCTAssertNotEqual(described, LogPrivacy.text(task + "!"))
        XCTAssertTrue(described.hasSuffix(":len\(task.count)>"), described)
        XCTAssertEqual(LogPrivacy.text(nil), LogPrivacy.noValue)
        XCTAssertEqual(LogPrivacy.text(""), LogPrivacy.noValue)
    }

    func testStructureNamesTheShapeAndNoValues() {
        let payload: [String: Any] = ["intention": task, "current_tasks": [task], "url": "example.org"]
        let described = LogPrivacy.structure(payload)
        XCTAssertEqual(described, "<dictionary keys=current_tasks,intention,url>")
        XCTAssertEqual(LogPrivacy.structure(NSDictionary(dictionary: ["title": task])), "<dictionary keys=title>")
        XCTAssertEqual(LogPrivacy.structure([task, task]), "<array count=2>")
        XCTAssertEqual(LogPrivacy.structure(Data(count: 5)), "<5 bytes>")
        XCTAssertEqual(LogPrivacy.structure(nil), LogPrivacy.noValue)
    }

    func testURLKeepsThePathAndReadableValuesAndDescribesText() {
        let url = "focusbear://event-about-to-start?event_title=Dentist%20visit&start=2026-10-05T09:30:00Z"
            + "&minutes=15&status=NOT_STARTED&flag=true#notes"
        let described = LogPrivacy.url(url)
        XCTAssertTrue(described.hasPrefix("focusbear://event-about-to-start?event_title=<text:"), described)
        XCTAssertFalse(described.contains("Dentist"))
        for kept in ["start=2026-10-05T09:30:00Z", "minutes=15", "status=NOT_STARTED", "flag=true"] {
            XCTAssertTrue(described.contains(kept), "\(kept) missing from \(described)")
        }
        XCTAssertFalse(described.hasSuffix("#notes"))
        XCTAssertEqual(LogPrivacy.url(described), described, "describing twice changes nothing")
        XCTAssertEqual(LogPrivacy.url("/to-do?page=1&take=50"), "/to-do?page=1&take=50")
        let decoded = LogPrivacy.url("focusbear://event-about-to-start?start=2026-10-05 09:30:00&event_title=Q&A with Sam")
        XCTAssertFalse(decoded.contains("Sam"), "a title holding \"&\" after decoding must not leak its tail: \(decoded)")
        XCTAssertTrue(decoded.contains("start=2026-10-05 09:30:00"), decoded)
        XCTAssertFalse(LogPrivacy.url("focusbear://e?event_title=OOO").contains("OOO"), "an all-caps title is still text")
        XCTAssertEqual(LogPrivacy.url("/projects"), "/projects")
    }
}

final class FocusButtonLogFormatTests: XCTestCase {
    func testDescribesGoalsHabitNamesAndNotificationText() {
        let lines = [
            "SET|START|1500|Write the grant report",
            "SET|GOAL|Write the grant report",
            "SET|HABITS|1,Take morning meds,300|2,Stretch,120",
            "SET|NOTIFY|Dentist visit|120",
            "INFO|RUNNING|1200|FOCUS|Write the grant report",
        ]
        for line in lines {
            let described = FocusButtonLogFormat.describe(line)
            for text in ["grant", "meds", "Stretch", "Dentist"] {
                XCTAssertFalse(described.contains(text), "\(text) survived in \(described)")
            }
            XCTAssertEqual(FocusButtonLogFormat.describe(described), described, "describing twice changes nothing")
        }
        XCTAssertTrue(FocusButtonLogFormat.describe("SET|HABITS|1,Stretch,120").hasPrefix("SET|HABITS|1,<text:"))
        XCTAssertTrue(FocusButtonLogFormat.describe("SET|HABITS|1,Stretch,120").hasSuffix(",120"))
    }

    func testKeepsTheProtocolAndTheFirmwaresOwnMessages() {
        let lines = [
            "SET|UPDATE|300", "ACK|EMOJI|1f4de|1", "EMOJI|1f9d1-200d-1f4bb|0", "ERROR|invalid_state",
            "FIRMWAREVER|M50-1.5.0", "SET|STARTHBID|42", "STATUS",
            "RTC not set — waiting for set_time command",
        ]
        for line in lines {
            XCTAssertEqual(FocusButtonLogFormat.describe(line), line)
        }
    }
}
