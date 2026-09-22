//
//  BlockListCategoryTests.swift
//  Focus BearTests
//
//  Covers the block-list category taxonomy: that a selection round-trips through the focus-mode
//  store, that it encodes to the exact wire shape the backend expects, and that categories ride
//  top-level on a focus-mode write rather than inside the `metadata` blob (which every save
//  replaces wholesale, and which an older client would therefore wipe).
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

@testable import Focus_Bear
import XCTest

final class BlockListCategoryTests: XCTestCase {

    // MARK: - Helpers

    /// Installs a single focus mode into the global `arrFocusType` and returns its index.
    @discardableResult
    private func installFocusMode(_ focusMode: [String: Any]) -> Int {
        arrFocusType = [focusMode]
        return 0
    }

    override func tearDown() {
        arrFocusType = []
        super.tearDown()
    }

    private func blockListFocusMode(
        categories: [[String: String]]? = nil,
        blockUrls: [String] = ["instagram.com"]
    ) -> [String: Any] {
        var focusMode: [String: Any] = [
            "id": "block-list-under-test",
            "name": "Deep Work",
            "blockUrlsArray": blockUrls,
            "isAllowedListApproach": false,
        ]
        if let categories { focusMode["categories"] = categories }
        return focusMode
    }

    // MARK: - Wire shape

    func testEncodeCategoriesProducesEntryAndCategoryPairs() {
        let encoded = BlockListStore.encodeCategories([
            "instagram.com": .socialMedia,
            "bbc.com": .news,
        ])

        // Sorted by entry, so an unrelated edit can't churn the payload.
        XCTAssertEqual(encoded, [
            ["entry": "bbc.com", "category": "news"],
            ["entry": "instagram.com", "category": "social_media"],
        ])
    }

    func testCategoryRawValuesAreTheStableWireIdentifiers() {
        // These strings are persisted and sent to the backend; renaming one silently re-files every
        // entry a user has already categorised.
        XCTAssertEqual(DistractionCategory.socialMedia.rawValue, "social_media")
        XCTAssertEqual(DistractionCategory.news.rawValue, "news")
        XCTAssertEqual(DistractionCategory.video.rawValue, "video")
        XCTAssertEqual(DistractionCategory.gaming.rawValue, "gaming")
        XCTAssertEqual(DistractionCategory.dating.rawValue, "dating")
        XCTAssertEqual(DistractionCategory.realEstate.rawValue, "real_estate")
        XCTAssertEqual(DistractionCategory.porn.rawValue, "porn")
        XCTAssertEqual(DistractionCategory.gambling.rawValue, "gambling")
        XCTAssertEqual(DistractionCategory.other.rawValue, "other")
    }

    // MARK: - Round trip through the store

    func testAssignedCategoriesDecodesTheStoredWireShape() {
        installFocusMode(blockListFocusMode(categories: [
            ["entry": "instagram.com", "category": "social_media"],
            ["entry": "bbc.com", "category": "news"],
        ]))

        let assigned = BlockListStore.assignedCategories(at: 0)

        XCTAssertEqual(assigned["instagram.com"], .socialMedia)
        XCTAssertEqual(assigned["bbc.com"], .news)
    }

    func testCategorySelectionRoundTripsThroughTheStore() {
        installFocusMode(blockListFocusMode())

        let encoded = BlockListStore.encodeCategories(["instagram.com": .socialMedia])
        arrFocusType[0]["categories"] = encoded

        XCTAssertEqual(BlockListStore.assignedCategories(at: 0)["instagram.com"], .socialMedia)
    }

    func testUnknownCategoryIdsAreDroppedRatherThanFailingTheWholeDecode() {
        // A newer client (or another platform) may file an entry under a category this build has
        // never heard of. That entry should degrade to uncategorised, not break the screen.
        installFocusMode(blockListFocusMode(categories: [
            ["entry": "instagram.com", "category": "social_media"],
            ["entry": "example.com", "category": "a_category_from_the_future"],
        ]))

        let assigned = BlockListStore.assignedCategories(at: 0)

        XCTAssertEqual(assigned["instagram.com"], .socialMedia)
        XCTAssertNil(assigned["example.com"])
    }

    func testAFocusModeWithNoCategoriesDecodesToAnEmptyMap() {
        installFocusMode(blockListFocusMode())

        XCTAssertTrue(BlockListStore.assignedCategories(at: 0).isEmpty)
    }

    func testCategoriesForEntriesNoLongerInTheListArePruned() {
        // An older client can delete a blocked URL without knowing categories exist, stranding the
        // row. Pruning happens on the next write so the stored list can't only ever grow.
        installFocusMode(blockListFocusMode(
            categories: [["entry": "instagram.com", "category": "social_media"],
                         ["entry": "deleted-elsewhere.com", "category": "news"]],
            blockUrls: ["instagram.com"]))

        BlockListStore.pruneOrphanedCategories(at: 0)

        let assigned = BlockListStore.assignedCategories(at: 0)
        XCTAssertEqual(assigned["instagram.com"], .socialMedia)
        XCTAssertNil(assigned["deleted-elsewhere.com"])
    }

    func testPruningLeavesAFullyLiveCategoryListAlone() {
        installFocusMode(blockListFocusMode(
            categories: [["entry": "instagram.com", "category": "social_media"]],
            blockUrls: ["instagram.com"]))

        BlockListStore.pruneOrphanedCategories(at: 0)

        XCTAssertEqual(BlockListStore.assignedCategories(at: 0)["instagram.com"], .socialMedia)
    }

    // MARK: - Sync payload

    func testCategoriesAreSentTopLevelAndStrippedFromMetadata() {
        // The macOS PATCH replaces `metadata` wholesale on every save, so categories stored there
        // would be wiped by any client that doesn't know about them. They must ride top-level.
        let stored = [["entry": "instagram.com", "category": "social_media"]]
        let focusType = blockListFocusMode(categories: stored)
        var json: [String: Any] = ["name": "Deep Work", "metadata": [:]]
        var metadata: [String: Any] = focusType

        applyFocusModeCategories(from: focusType, to: &json, metadata: &metadata)

        XCTAssertEqual(json["categories"] as? [[String: String]], stored)
        XCTAssertNil(metadata["categories"], "categories must not also ride inside the metadata blob")
    }

    func testAFocusModeWithoutCategoriesSendsAnEmptyList() {
        let focusType = blockListFocusMode()
        var json: [String: Any] = ["name": "Deep Work", "metadata": [:]]
        var metadata: [String: Any] = focusType

        applyFocusModeCategories(from: focusType, to: &json, metadata: &metadata)

        XCTAssertEqual(json["categories"] as? [[String: String]], [])
    }

    // MARK: - Catalog

    func testSeedDomainsAreClassifiedIntoTheirOwnCategory() {
        XCTAssertEqual(DistractionCategoryCatalog.inferredCategory(for: "instagram.com"), .socialMedia)
        XCTAssertEqual(DistractionCategoryCatalog.inferredCategory(for: "www.bbc.com/news"), .news)
        XCTAssertEqual(DistractionCategoryCatalog.inferredCategory(for: "netflix"), .video)
        XCTAssertEqual(DistractionCategoryCatalog.inferredCategory(for: "tinder.com"), .dating)
        XCTAssertEqual(DistractionCategoryCatalog.inferredCategory(for: "zillow.com"), .realEstate)
    }

    func testAnUnknownDomainIsNotForcedIntoACategory() {
        XCTAssertNil(DistractionCategoryCatalog.inferredCategory(for: "some-internal-tool.example"))
    }

    func testVeryShortEntriesAreNotMatchedBySubstring() {
        // "x" would otherwise match x.com and half the catalog.
        XCTAssertNil(DistractionCategoryCatalog.inferredCategory(for: "x"))
    }

    func testOnboardingShowsTheHistoricalCategorySubsetOfTheSharedTaxonomy() {
        let onboarding = DistractionCategory.allCases.filter { $0.appearsInOnboarding }

        XCTAssertEqual(Set(onboarding), [.socialMedia, .news, .video, .dating, .realEstate])
        // The block-list screen offers strictly more, from the same enum — one taxonomy, not two.
        XCTAssertTrue(DistractionCategory.orderedForFiltering.count > onboarding.count)
    }

    func testOtherSortsLastAmongTheFilterChips() {
        XCTAssertEqual(DistractionCategory.orderedForFiltering.last, .other)
        XCTAssertEqual(
            Set(DistractionCategory.orderedForFiltering),
            Set(DistractionCategory.allCases),
            "every category must be reachable as a filter")
    }

    // MARK: - Card presentation

    func testALeadingEmojiIsLiftedOutOfTheBlockListName() {
        XCTAssertEqual(BlockListStore.leadingEmoji(in: "🤚 Deep Work"), "🤚")
        XCTAssertEqual(BlockListStore.leadingEmoji(in: "💻 No work in the evening"), "💻")
    }

    func testANameWithoutAnEmojiHasNone() {
        XCTAssertNil(BlockListStore.leadingEmoji(in: "Deep Work"))
        // Digits carry an emoji property in Unicode; they must not be mistaken for one.
        XCTAssertNil(BlockListStore.leadingEmoji(in: "1Password"))
    }
}
