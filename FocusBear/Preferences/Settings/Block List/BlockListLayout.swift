//
//  BlockListLayout.swift
//  Focus Bear
//
//  Pure sizing maths for the block-list screen. It lives apart from `BlockListView` so it can be
//  unit tested: the screen previously hard-coded every column width, which meant the flexible NAME
//  column collapsed to nothing in a narrow window and entries rendered as a bare avatar letter.
//  Every width the screen uses is now derived here, from the width actually available.
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CoreGraphics

/// The widths of one entry row's columns, for a given available row width.
struct BlockListColumnWidths: Equatable {
    let name: CGFloat
    let category: CGFloat
    let type: CGFloat

    /// What the row's columns, avatar and remove button occupy in total, including the gaps.
    var totalRowWidth: CGFloat {
        name + category + type + BlockListLayout.rowFixedWidth
    }
}

/// Derives the block-list screen's widths from the space it is given.
///
/// Sizing priority when space is tight is NAME, then CATEGORY, then TYPE: a row whose name has been
/// squeezed away tells the user nothing, whereas a truncated category pill or type label still does.
enum BlockListLayout {

    // MARK: Left rail

    /// The rail width the Figma artboard specifies; it is never drawn wider than this.
    static let railIdealWidth: CGFloat = 340
    /// Below this the cards cannot fit an emoji, a name and the "N BLOCKS" badge.
    static let railMinWidth: CGFloat = 190
    /// The rail's share of a narrow window, so the panel keeps the majority of the width.
    static let railWidthFraction: CGFloat = 0.35
    /// The rail shrinks with the window instead of forcing it to stay wide. Below roughly a 750pt
    /// window the rail bottoms out at `railMinWidth`, where a long block-list name wraps tightly
    /// beside its badge; the table keeps the width instead, because that is where the content is.
    static func railWidth(forContentWidth contentWidth: CGFloat) -> CGFloat {
        let proportional = contentWidth * railWidthFraction
        return min(railIdealWidth, max(railMinWidth, proportional))
    }

    // MARK: Entry table columns

    /// Roomy enough for a domain like `facebook.com` at the row's body size. The screen guarantees
    /// the name column is never narrower than this, at any window width.
    static let nameMinWidth: CGFloat = 120
    /// The category pill's design width; it holds the longest category name untruncated.
    static let categoryIdealWidth: CGFloat = 190
    /// Enough for most category names; the longest ("Streaming services") truncates here, which is
    /// still readable, whereas losing the entry's name is not.
    static let categoryMinWidth: CGFloat = 110
    static let typeIdealWidth: CGFloat = 90
    /// Fits "Website" — the longer of the two type labels — whole at the row's body size. The label
    /// is only two values, so truncating it to "Webs…" is pure loss.
    static let typeMinWidth: CGFloat = 62
    static let removeButtonWidth: CGFloat = 36
    static let avatarSize: CGFloat = 34
    static let columnSpacing: CGFloat = 10
    /// The add-row's category dropdown; it flexes with the row rather than pinning it open, so the
    /// "Add a new URL…" field and the Add button keep their own space.
    static let pickerIdealWidth: CGFloat = 150
    static let pickerMinWidth: CGFloat = 110
    static let pickerWidthFraction: CGFloat = 0.28
    /// The entry table's vertical scroller overlays the row's trailing edge, so the row has to stop
    /// short of it or the remove button is drawn underneath.
    static let scrollerWidth: CGFloat = 16

    /// The part of a row that never flexes: the avatar tile, the remove button and the four gaps
    /// between the five cells.
    static let rowFixedWidth: CGFloat = avatarSize + removeButtonWidth + columnSpacing * 4

    /// The narrowest row that still fits every column at its minimum. A window narrower than this
    /// is drawn at this width anyway and clipped at its trailing edge, so the columns that go are
    /// Type and the remove button rather than the entry's name.
    static let minimumRowWidth: CGFloat =
        nameMinWidth + categoryMinWidth + typeMinWidth + rowFixedWidth

    /// Chooses the three flexible column widths for the width a row actually has.
    ///
    /// Category and type start at their minimums and grow toward their design widths with whatever
    /// the row has spare once the name has been promised `nameMinWidth`; anything still left over
    /// after both reach their design widths goes to the name. So a wide row looks like the design,
    /// and a narrow one gives up category and type width before it gives up the name.
    ///
    /// The columns are guaranteed to fit within `rowWidth` whenever `rowWidth` is at least
    /// `minimumRowWidth`; below that the name still keeps `nameMinWidth` and the row's trailing edge
    /// is clipped instead.
    static func columnWidths(forRowWidth rowWidth: CGFloat) -> BlockListColumnWidths {
        let flexible = max(rowWidth - rowFixedWidth, 0)
        let secondaryFloor = categoryMinWidth + typeMinWidth
        let categoryHeadroom = categoryIdealWidth - categoryMinWidth
        let typeHeadroom = typeIdealWidth - typeMinWidth
        let secondaryHeadroom = categoryHeadroom + typeHeadroom

        let secondaryBudget = max(flexible - nameMinWidth, secondaryFloor)
        let growth = min(max(secondaryBudget - secondaryFloor, 0), secondaryHeadroom)
        let share = secondaryHeadroom > 0 ? growth / secondaryHeadroom : 0

        let category = categoryMinWidth + categoryHeadroom * share
        let type = typeMinWidth + typeHeadroom * share
        let name = max(nameMinWidth, flexible - category - type)
        return BlockListColumnWidths(name: name, category: category, type: type)
    }

    /// The add-row dropdown shrinks with the row so the "Add a new URL…" field keeps a usable size.
    static func pickerWidth(forRowWidth rowWidth: CGFloat) -> CGFloat {
        min(pickerIdealWidth, max(pickerMinWidth, rowWidth * pickerWidthFraction))
    }

    // MARK: Panel title

    /// Figma draws a 40pt title inside a 1119pt-wide panel. The app's panel is a fraction of that,
    /// so the title is scaled by the same ratio; kept at Figma's 30pt-equivalent it swamped the
    /// panel and truncated against the edit button.
    static let titleFigmaFontSize: CGFloat = 40
    static let titleFigmaPanelWidth: CGFloat = 1119
    static let titleMinFontSize: CGFloat = 18
    static let titleMaxFontSize: CGFloat = 28

    static func titleFontSize(forPanelWidth panelWidth: CGFloat) -> CGFloat {
        let proportional = panelWidth * titleFigmaFontSize / titleFigmaPanelWidth
        return min(titleMaxFontSize, max(titleMinFontSize, proportional))
    }

    // MARK: Whole screen

    /// Screen chrome that sits between the hosting view's width and one table row's width.
    static let outerPadding: CGFloat = 16
    static let railPanelGap: CGFloat = 16
    static let panelInset: CGFloat = 25

    /// Every width the screen needs, derived from the width the hosting view was actually given.
    struct Metrics: Equatable {
        let railWidth: CGFloat
        let panelWidth: CGFloat
        let rowWidth: CGFloat
        let columns: BlockListColumnWidths
        let titleFontSize: CGFloat

        /// The width a row is drawn at. Never below `minimumRowWidth`, so the name column survives
        /// a window too narrow for the design; the table clips its trailing edge instead.
        var laidOutRowWidth: CGFloat { max(rowWidth, BlockListLayout.minimumRowWidth) }
    }

    static func metrics(forScreenWidth screenWidth: CGFloat) -> Metrics {
        let contentWidth = max(screenWidth - outerPadding * 2, 0)
        let rail = railWidth(forContentWidth: contentWidth)
        let panel = max(contentWidth - rail - railPanelGap, 0)
        let row = max(panel - panelInset * 2 - scrollerWidth, 0)
        return Metrics(railWidth: rail,
                       panelWidth: panel,
                       rowWidth: row,
                       columns: columnWidths(forRowWidth: max(row, minimumRowWidth)),
                       titleFontSize: titleFontSize(forPanelWidth: panel))
    }
}
