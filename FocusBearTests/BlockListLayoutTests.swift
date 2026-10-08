//
//  BlockListLayoutTests.swift
//  Focus BearTests
//
//  Pins the block-list screen's sizing. The screen used to hard-code every column width, so in a
//  narrow window the flexible NAME column was squeezed to nothing and each entry rendered as a bare
//  avatar letter with blank space where `facebook.com` should have been. These tests exist so that
//  cannot happen again at any width, and so the screen never demands a width the window has to grow
//  to satisfy.
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import AppKit
@testable import Focus_Bear
import XCTest

final class BlockListLayoutTests: XCTestCase {

    /// Widths are in points and the maths is in `CGFloat`, so comparisons need a little slack.
    private let tolerance: CGFloat = 0.001

    /// Every width a Focus Bear window could plausibly hand this screen, plus absurd extremes.
    private let screenWidths: [CGFloat] = stride(from: 200, through: 2400, by: 10).map { CGFloat($0) }

    // MARK: - The name column

    func testTheNameColumnNeverCollapsesAtAnyWindowWidth() {
        for width in screenWidths {
            let name = BlockListLayout.metrics(forScreenWidth: width).columns.name
            XCTAssertGreaterThanOrEqual(
                name, BlockListLayout.nameMinWidth - tolerance,
                "the entry name collapsed to \(name)pt at a \(width)pt window")
        }
    }

    func testTheNameColumnNeverCollapsesForAnyRowWidth() {
        for rowWidth in stride(from: CGFloat(0), through: 2400, by: 5) {
            let name = BlockListLayout.columnWidths(forRowWidth: rowWidth).name
            XCTAssertGreaterThanOrEqual(name, BlockListLayout.nameMinWidth - tolerance,
                                        "the name collapsed to \(name)pt in a \(rowWidth)pt row")
        }
    }

    func testTheNameColumnIsWideEnoughForATypicalDomain() {
        // `facebook.com` at the row's 15pt body size is the case the product owner reported missing.
        let domain = "facebook.com" as NSString
        let rendered = domain.size(withAttributes: [.font: NSFont.systemFont(ofSize: 15)]).width
        XCTAssertGreaterThan(BlockListLayout.nameMinWidth, rendered,
                             "the guaranteed name width cannot even render facebook.com")
    }

    func testTheNameColumnNeverShrinksAsTheRowGrows() {
        var previous: CGFloat = 0
        for rowWidth in stride(from: CGFloat(0), through: 2400, by: 5) {
            let name = BlockListLayout.columnWidths(forRowWidth: rowWidth).name
            XCTAssertGreaterThanOrEqual(name, previous - tolerance,
                                        "the name shrank when the row grew to \(rowWidth)pt")
            previous = name
        }
    }

    func testExtraWidthGoesToTheNameOnceTheOtherColumnsReachTheDesign() {
        let narrower = BlockListLayout.columnWidths(forRowWidth: 900)
        let wider = BlockListLayout.columnWidths(forRowWidth: 1100)
        XCTAssertEqual(narrower.category, BlockListLayout.categoryIdealWidth, accuracy: tolerance)
        XCTAssertEqual(wider.category, BlockListLayout.categoryIdealWidth, accuracy: tolerance)
        XCTAssertEqual(wider.type, BlockListLayout.typeIdealWidth, accuracy: tolerance)
        XCTAssertEqual(wider.name - narrower.name, 200, accuracy: tolerance)
    }

    // MARK: - Fitting the row

    func testColumnsFitTheRowWheneverItMeetsTheMinimum() {
        for rowWidth in stride(from: BlockListLayout.minimumRowWidth, through: 2400, by: 5) {
            let total = BlockListLayout.columnWidths(forRowWidth: rowWidth).totalRowWidth
            XCTAssertLessThanOrEqual(total, rowWidth + tolerance,
                                     "columns totalling \(total)pt overflowed a \(rowWidth)pt row")
        }
    }

    /// The narrow end the window is allowed to reach: the columns must still be satisfiable there
    /// rather than the screen insisting the window stay wide.
    func testColumnWidthsAreSatisfiableInASixHundredPointRow() {
        let columns = BlockListLayout.columnWidths(forRowWidth: 600)
        XCTAssertLessThanOrEqual(columns.totalRowWidth, 600 + tolerance)
        XCTAssertGreaterThanOrEqual(columns.name, BlockListLayout.nameMinWidth - tolerance)
        XCTAssertGreaterThanOrEqual(columns.category, BlockListLayout.categoryMinWidth - tolerance)
        XCTAssertGreaterThanOrEqual(columns.type, BlockListLayout.typeMinWidth - tolerance)
    }

    func testCategoryAndTypeGiveUpWidthBeforeTheNameDoes() {
        let tight = BlockListLayout.columnWidths(forRowWidth: BlockListLayout.minimumRowWidth)
        XCTAssertEqual(tight.name, BlockListLayout.nameMinWidth, accuracy: tolerance)
        XCTAssertEqual(tight.category, BlockListLayout.categoryMinWidth, accuracy: tolerance)
        XCTAssertEqual(tight.type, BlockListLayout.typeMinWidth, accuracy: tolerance)
        XCTAssertEqual(tight.totalRowWidth, BlockListLayout.minimumRowWidth, accuracy: tolerance)
    }

    func testNoColumnEverExceedsItsDesignWidth() {
        for rowWidth in screenWidths {
            let columns = BlockListLayout.columnWidths(forRowWidth: rowWidth)
            XCTAssertLessThanOrEqual(columns.category, BlockListLayout.categoryIdealWidth + tolerance)
            XCTAssertLessThanOrEqual(columns.type, BlockListLayout.typeIdealWidth + tolerance)
        }
    }

    // MARK: - The left rail

    func testTheRailShrinksWithTheWindowButNeverBelowItsMinimum() {
        for width in screenWidths {
            let rail = BlockListLayout.railWidth(forContentWidth: width)
            XCTAssertGreaterThanOrEqual(rail, BlockListLayout.railMinWidth - tolerance)
            XCTAssertLessThanOrEqual(rail, BlockListLayout.railIdealWidth + tolerance)
        }
    }

    func testTheRailReachesTheDesignWidthInAWideWindowAndGivesWidthUpInANarrowOne() {
        XCTAssertEqual(BlockListLayout.railWidth(forContentWidth: 1600),
                       BlockListLayout.railIdealWidth, accuracy: tolerance)
        XCTAssertLessThan(BlockListLayout.railWidth(forContentWidth: 800),
                          BlockListLayout.railIdealWidth)
    }

    func testTheRailNeverTakesMoreThanItsShareOfANarrowWindow() {
        // Above the point where the minimum binds, the rail stays a minority of the window.
        for width in stride(from: CGFloat(700), through: 2400, by: 10) {
            let rail = BlockListLayout.railWidth(forContentWidth: width)
            XCTAssertLessThan(rail, width / 2, "the rail took more than half of a \(width)pt window")
        }
    }

    // MARK: - Whole-screen metrics

    /// The widths the screen was rendered and reviewed at.
    func testEveryReviewedWindowWidthLeavesALegibleNameColumn() {
        for width: CGFloat in [700, 820, 1000, 1200, 1600] {
            let metrics = BlockListLayout.metrics(forScreenWidth: width)
            XCTAssertGreaterThanOrEqual(metrics.rowWidth, BlockListLayout.minimumRowWidth,
                                        "a \(width)pt window could not fit a full row")
            XCTAssertLessThanOrEqual(metrics.columns.totalRowWidth, metrics.rowWidth + tolerance,
                                     "the row overflowed a \(width)pt window")
            XCTAssertGreaterThanOrEqual(metrics.columns.name, BlockListLayout.nameMinWidth - tolerance)
        }
    }

    /// The product owner's window: roughly 1040pt wide with a 220pt sidebar.
    func testTheReportedWindowSizeShowsBothTheNameAndTheFullCategoryPill() {
        let metrics = BlockListLayout.metrics(forScreenWidth: 820)
        XCTAssertGreaterThanOrEqual(metrics.columns.name, BlockListLayout.nameMinWidth - tolerance)
        XCTAssertGreaterThan(metrics.columns.category, BlockListLayout.categoryMinWidth)
        XCTAssertLessThanOrEqual(metrics.columns.totalRowWidth, metrics.rowWidth + tolerance)
    }

    func testAWindowNarrowerThanTheDesignStillLaysOutRatherThanDemandingMoreWidth() {
        // The window must be free to shrink; the screen absorbs it by clipping the row's trailing
        // edge, never by dropping the name.
        for width: CGFloat in [400, 500, 600, 680] {
            let metrics = BlockListLayout.metrics(forScreenWidth: width)
            XCTAssertGreaterThanOrEqual(metrics.columns.name, BlockListLayout.nameMinWidth - tolerance)
            XCTAssertGreaterThanOrEqual(metrics.laidOutRowWidth, BlockListLayout.minimumRowWidth,
                                        "a \(width)pt window laid a row out below the minimum")
            XCTAssertLessThanOrEqual(metrics.columns.totalRowWidth,
                                     metrics.laidOutRowWidth + tolerance,
                                     "the columns overflowed the row they were laid out in")
        }
    }

    func testMetricsAccountForEveryPieceOfScreenChrome() {
        let metrics = BlockListLayout.metrics(forScreenWidth: 1000)
        let reassembled = BlockListLayout.outerPadding * 2
            + metrics.railWidth
            + BlockListLayout.railPanelGap
            + metrics.panelWidth
        XCTAssertEqual(reassembled, 1000, accuracy: tolerance)
        XCTAssertEqual(metrics.rowWidth,
                       metrics.panelWidth - BlockListLayout.panelInset * 2
                           - BlockListLayout.scrollerWidth,
                       accuracy: tolerance)
    }

    // MARK: - Title

    func testTheTitleScalesWithThePanelAndStaysWithinItsClamps() {
        for panel in stride(from: CGFloat(100), through: 2400, by: 10) {
            let size = BlockListLayout.titleFontSize(forPanelWidth: panel)
            XCTAssertGreaterThanOrEqual(size, BlockListLayout.titleMinFontSize - tolerance)
            XCTAssertLessThanOrEqual(size, BlockListLayout.titleMaxFontSize + tolerance)
        }
        XCTAssertEqual(BlockListLayout.titleFontSize(forPanelWidth: 100),
                       BlockListLayout.titleMinFontSize, accuracy: tolerance)
        XCTAssertEqual(BlockListLayout.titleFontSize(forPanelWidth: 2400),
                       BlockListLayout.titleMaxFontSize, accuracy: tolerance)
    }

    func testTheTitleIsSmallerInANarrowPanelThanAWideOne() {
        XCTAssertLessThan(BlockListLayout.titleFontSize(forPanelWidth: 560),
                          BlockListLayout.titleFontSize(forPanelWidth: 760))
    }

    // MARK: - Add-row dropdown

    func testTheAddRowDropdownFlexesBetweenItsBounds() {
        for rowWidth in screenWidths {
            let width = BlockListLayout.pickerWidth(forRowWidth: rowWidth)
            XCTAssertGreaterThanOrEqual(width, BlockListLayout.pickerMinWidth - tolerance)
            XCTAssertLessThanOrEqual(width, BlockListLayout.pickerIdealWidth + tolerance)
        }
        XCTAssertEqual(BlockListLayout.pickerWidth(forRowWidth: 1200),
                       BlockListLayout.pickerIdealWidth, accuracy: tolerance)
    }
}
