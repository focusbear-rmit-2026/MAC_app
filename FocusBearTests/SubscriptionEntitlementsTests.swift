import XCTest
@testable import Focus_Bear

/// A paid team admin was being offered an upgrade. `activeEntitlements` comes back as a list, and the
/// old check read only its first element — so `team_admin`, which is not itself a paid tier and sorts
/// first, decided the answer while `team_member` and `team_owner` sat unread behind it.
final class SubscriptionEntitlementsTests: XCTestCase {

    /// The exact array from the affected account (report 2026-09-14_19-47-35).
    func testATeamAdminWithMemberAndOwnerEntitlementsIsPaid() {
        let active = ["team_admin", "team_member", "team_owner"]
        XCTAssertNotNil(SubscriptionEntitlements.payingEntitlement(in: active),
                        "A team admin holding member and owner entitlements is a paying customer")
    }

    /// The precise regression: a non-paying entitlement first must not mask a paying one behind it.
    func testANonPayingEntitlementFirstDoesNotMaskAPayingOne() {
        XCTAssertEqual(SubscriptionEntitlements.payingEntitlement(in: ["trial", "personal"]), "personal")
        XCTAssertEqual(SubscriptionEntitlements.payingEntitlement(in: ["something_new", "team_owner"]), "team_owner")
    }

    func testEachPaidTierCountsOnItsOwn() {
        for tier in ["personal", "team_admin", "team_member", "team_owner", "team_size_5"] {
            XCTAssertEqual(SubscriptionEntitlements.payingEntitlement(in: [tier]), tier, "\(tier) should grant access")
        }
    }

    /// The guard still has to say no when it should.
    func testTrialAloneIsNotPaid() {
        XCTAssertNil(SubscriptionEntitlements.payingEntitlement(in: ["trial"]))
    }

    func testNoEntitlementsIsNotPaid() {
        XCTAssertNil(SubscriptionEntitlements.payingEntitlement(in: []))
    }

    func testAnUnknownEntitlementIsNotPaid() {
        XCTAssertNil(SubscriptionEntitlements.payingEntitlement(in: ["some_future_tier"]),
                     "An unrecognised entitlement must not silently grant access")
    }

    /// The returned name is used to look up the expiry, so it must be the paying one.
    func testReturnsThePayingEntitlementNotMerelyTheFirst() {
        XCTAssertEqual(SubscriptionEntitlements.payingEntitlement(in: ["trial", "team_member"]), "team_member")
    }
}
