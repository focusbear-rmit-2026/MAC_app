//
//  BlockListView.swift
//  Focus Bear
//
//  The block-list screen from the "DESKTOP BLOCKLIST" Figma exploration
//  (file ULUYn4BTeP7siyAGFAEkq4, node 5436-95408). The design is a 2x artboard, so every measurement
//  there is halved here: its 40px body text is 20pt, its 20px radii are 10pt, and so on.
//
//  The artboard is also drawn at a width no Focus Bear window reaches, so the screen must not copy
//  its widths literally. Every width is computed by `BlockListLayout` from the width the view is
//  actually handed; nothing here is a fixed column. That is what keeps the entry name visible in a
//  small window, and what stops the screen dictating a minimum width to the window hosting it.
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import SwiftUI

// NOTE: the app declares global AppKit types named `State` and `Button`, which shadow the SwiftUI
// ones. Every use below is therefore qualified as `SwiftUI.State` / `SwiftUI.Button`.

/// Colours, radii and metrics lifted from the Figma file, halved from its 2x artboard.
@available(macOS 11.0, *)
enum BlockListStyle {
    // Palette
    static let primaryOrange = Color(hex: 0xDE7400)
    static let selectedCardFill = Color(hex: 0xFFEBD3)
    static let categoryPillFill = Color(hex: 0xFFEDC9)
    static let badgeFill = Color(hex: 0xE48E24).opacity(0.2)
    static let badgeText = Color(hex: 0xDE8200)
    // #2571 (4): these neutrals were hardcoded for light mode and didn't adapt — the search field
    // (searchFill) rendered as a glaring white box in dark mode, borders/dividers vanished, and the
    // near-black row text sat on the dark panel with almost no contrast. Use system semantic colors so
    // they flip correctly. The cream/orange brand colours below stay fixed (they read in both modes).
    static let unselectedChipText = Color(NSColor.secondaryLabelColor)
    static let hairline = Color(NSColor.separatorColor)
    static let panelBorder = Color(NSColor.separatorColor)
    static let mutedText = Color(NSColor.secondaryLabelColor)
    static let rowText = Color(NSColor.labelColor)
    static let searchFill = Color(NSColor.textBackgroundColor)
    static let avatarFill = Color(hex: 0x71717A).opacity(0.2)
    static let buttonStroke = Color(hex: 0xFFF9F2).opacity(0.4)

    // Metrics. Everything width-related lives in `BlockListLayout`, which is testable and free of
    // SwiftUI; only sizes that never vary with the window stay here.
    static let cardRadius: CGFloat = 10
    static let cardStroke: CGFloat = 2
    static let cardSpacing: CGFloat = 8
    static let cardPadding = EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)
    static let badgeRadius: CGFloat = 12
    static let pillRadius: CGFloat = 8
    static let panelRadius: CGFloat = 3
    static let controlHeight: CGFloat = 40
    static let rowSpacing: CGFloat = 12
    static let chipSpacing: CGFloat = 16
    /// Trailing fade that signals the chip row scrolls rather than ending mid-word (the design has
    /// the same fade, node 5436:95455). `chipFadeStart` is where the gradient begins, as a fraction
    /// of the row's width.
    static let chipFadeWidth: CGFloat = 48
    static let chipFadeStart: CGFloat = 0.92
    static let pillHorizontalPadding: CGFloat = 12
    /// A block list's name wraps rather than truncating when the rail is narrow.
    static let cardTitleLineLimit = 3

    // Type scale. The weights are exactly what Figma (file ULUYn4BTeP7siyAGFAEkq4, node 5436-95408)
    // specifies — 590 = Semibold, 510 = Medium, 400 = Regular — so they are not ours to soften.
    // Sizes are the artboard's px halved, then taken to ~75% for macOS's denser settings UI. The
    // panel title is the exception: it scales with the panel it sits in, because a fixed size drawn
    // for the artboard's 1119pt panel swamps and truncates in a real window. See
    // `BlockListLayout.titleFontSize(forPanelWidth:)`.
    static let cardTitleFont = Font.system(size: 15, weight: .semibold)
    static let badgeFont = Font.system(size: 11, weight: .semibold)
    static let sectionLabelFont = Font.system(size: 13, weight: .semibold)
    /// Figma's third artboard (node 5436:95708) draws the selected chip at the same size as the
    /// unselected ones, with colour and opacity carrying the selection; a larger selected chip made
    /// the row reflow on every tap and pushed the rest of the chips out of view.
    static let chipFont = Font.system(size: 15, weight: .semibold)
    static let chipCountFont = Font.system(size: 12, weight: .medium)
    static let bodyFont = Font.system(size: 15)
    static let buttonFont = Font.system(size: 15, weight: .medium)
    static let dropdownFont = Font.system(size: 13, weight: .semibold)

    static func titleFont(size: CGFloat) -> Font { Font.system(size: size, weight: .semibold) }
}

// `Color(hex:)` for the Figma `0xRRGGBB` literals above comes from the extension in MenuView.swift.

// MARK: - Screen

@available(macOS 11.0, *)
/// Classifies a typed block-list entry as a URL or a keyword, matching the blocking engine's rule
/// (`urlValidation.isUrlAlwaysBlocked`): a value with a dot and no whitespace is treated as a
/// domain/URL; anything else is a keyword. Pure, so it's unit-tested.
enum BlockListEntryClassifier {
    static func looksLikeURL(_ rawValue: String) -> Bool {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return false }
        return value.contains(".") && !value.contains(where: { $0.isWhitespace })
    }
}

struct BlockListView: View {
    @ObservedObject var store: BlockListStore

    /// Opens the existing Advanced sheet for the selected mode — the design's top-right edit affordance.
    let onEdit: (Int) -> Void
    /// Runs the legacy "Add Block List" flow.
    let onCreate: () -> Void
    /// Keeps the hidden AppKit table's `selectedRow` in step, because the legacy sheets read it.
    let onSelect: (Int) -> Void
    /// Leaves the screen. The storyboard back button is hidden behind this view, so the SwiftUI
    /// header has to offer the way out.
    let onBack: () -> Void
    /// #2571 (14): duplicate the focus mode (legacy `makeDuplicateFocus`).
    let onDuplicate: (Int) -> Void
    /// #2571 (14): hide/show the focus mode in the pickers.
    let onToggleHide: (Int) -> Void
    /// #2571 (14): delete the focus mode, reusing the legacy delete guards + confirmation.
    let onDelete: (Int) -> Void
    /// #2571 (14): rename the focus mode to the given name (validated + persisted in the host).
    let onRename: (Int, String) -> Void
    /// #2571 (14): open the colour panel for the focus mode.
    let onChangeColor: (Int) -> Void
    /// #2571 (11): open a file picker to add one or more apps to the selected block list.
    let onAddApp: () -> Void

    /// #2571 (14): drives the inline name editor in the panel header. Only one mode's header shows at
    /// a time, so a single flag + draft is enough.
    @SwiftUI.State private var isEditingName = false
    @SwiftUI.State private var nameDraft = ""
    /// Installed apps (from the Applications folders) — the source for the search-driven "Add app" card.
    @SwiftUI.State private var installedApps: [InstalledApp] = []

    var body: some View {
        // The screen sizes itself from the width it is handed rather than from fixed columns, so it
        // never demands a minimum width of the window it is hosted in — see
        // `focusPreferencesVc.setupBlockListRedesign()`, which also stops the hosting view
        // propagating an intrinsic size.
        GeometryReader { proxy in
            screen(BlockListLayout.metrics(forScreenWidth: proxy.size.width))
        }
        .background(Color(NSColor.textBackgroundColor))
        // Draw hover tooltips at the root so they float above the clipped panel, not inside it (#2571).
        .fastTooltipLayer()
        .onAppear { InstalledApps.shared.load { self.installedApps = $0 } }
    }

    private func screen(_ metrics: BlockListLayout.Metrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SwiftUI.Button(action: onBack) {
                Image(nsImage: NSImage(named: NSImage.goBackTemplateName) ?? NSImage())
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(FBButtonStyle())
            .accessibility(label: Text(BlockListText.back))

            if let message = store.syncFailureMessage { syncFailureBanner(message) }

            HStack(alignment: .top, spacing: BlockListLayout.railPanelGap) {
                leftRail(width: metrics.railWidth)
                rightPanel(metrics)
            }
        }
        .padding(BlockListLayout.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Switching modes cancels an in-progress rename so the field never carries over.
        .onChange(of: store.selectedIndex) { _ in isEditingName = false }
    }

    // MARK: Sync failure

    /// The edit is already stored locally, so this reports what did *not* happen rather than
    /// pretending the save failed outright. Same banner treatment as the blocking-schedule screen.
    private func syncFailureBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(BlockListStyle.primaryOrange)
            Text(message)
                .font(BlockListStyle.bodyFont)
                // This banner's background is always the cream categoryPillFill, so keep dark text in
                // both appearances (rowText is now the adaptive panel colour, which would be white here).
                .foregroundColor(Color(hex: 0x101014))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            SwiftUI.Button(action: store.dismissSyncFailure) {
                Text(BlockListText.dismiss)
                    .font(BlockListStyle.buttonFont)
                    .foregroundColor(BlockListStyle.primaryOrange)
            }
            .buttonStyle(FBButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: BlockListStyle.pillRadius)
            .fill(BlockListStyle.categoryPillFill))
        .overlay(RoundedRectangle(cornerRadius: BlockListStyle.pillRadius)
            .strokeBorder(BlockListStyle.primaryOrange.opacity(0.4), lineWidth: 1))
    }

    // MARK: Left rail

    private func leftRail(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(BlockListText.myBlockLists) (\(store.blockLists.count))")
                .font(BlockListStyle.sectionLabelFont)
                .foregroundColor(BlockListStyle.mutedText)

            ScrollView {
                LazyVStack(spacing: BlockListStyle.cardSpacing) {
                    ForEach(store.blockLists) { summary in
                        blockListCard(summary)
                    }
                }
                .padding(.trailing, 2)   // room for the 2pt selected border
            }

            // The reveal toggle only exists once something is hidden — same as the legacy checkbox.
            if store.hasHiddenModes {
                Toggle(isOn: $store.revealHidden) {
                    Text(BlockListText.revealHiddenModes)
                        .font(BlockListStyle.sectionLabelFont)
                        .foregroundColor(BlockListStyle.mutedText)
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.top, 2)
            }

            SwiftUI.Button(action: onCreate) {
                Text(BlockListText.createNewBlockList)
                    .font(BlockListStyle.buttonFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    // #2571: the bottom add controls match this height, so share one constant.
                    .frame(height: BlockListStyle.controlHeight)
            }
            .buttonStyle(FBButtonStyle())
            .background(BlockListStyle.primaryOrange)
            .overlay(
                RoundedRectangle(cornerRadius: BlockListStyle.cardRadius)
                    .stroke(BlockListStyle.buttonStroke, lineWidth: 1))
            .cornerRadius(BlockListStyle.cardRadius)
        }
        .frame(width: width)
    }

    private func blockListCard(_ summary: BlockListSummary) -> some View {
        let isSelected = store.selectedIndex == summary.index
        // The WHOLE card selects (a tap gesture on the padded card, not just its content), while the
        // per-mode action buttons stay real buttons that consume their own taps — so clicking anywhere
        // on the row selects it, but the trash/duplicate/hide icons still do their own thing.
        return VStack(alignment: .leading, spacing: 10) {
            cardContent(summary, isSelected: isSelected)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected { cardActions(summary) }
        }
        .padding(BlockListStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? BlockListStyle.selectedCardFill : Color(NSColor.textBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: BlockListStyle.cardRadius)
                .stroke(isSelected ? BlockListStyle.primaryOrange : BlockListStyle.hairline,
                        lineWidth: BlockListStyle.cardStroke))
        .cornerRadius(BlockListStyle.cardRadius)
        // A hidden mode is dimmed so its state reads at a glance, matching the legacy list.
        .opacity(summary.isHidden ? 0.55 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedIndex = summary.index
            onSelect(summary.index)
        }
        .pointingHandCursor()
        .accessibility(addTraits: isSelected ? .isSelected : [])
    }

    /// The delete / duplicate / hide icon buttons shown on the selected card, mirroring the legacy
    /// list's per-row `-`, duplicate and "Hide" controls. Each respects the mode's eligibility.
    private func cardActions(_ summary: BlockListSummary) -> some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            if summary.canDelete {
                cardActionButton("trash", help: BlockListText.deleteBlockList) { onDelete(summary.index) }
            }
            if summary.canDuplicate {
                cardActionButton("plus.square.on.square", help: BlockListText.duplicateBlockList) {
                    onDuplicate(summary.index)
                }
            }
            if summary.canHide {
                cardActionButton(summary.isHidden ? "eye" : "eye.slash",
                                 help: summary.isHidden ? BlockListText.showBlockList : BlockListText.hideBlockList) {
                    onToggleHide(summary.index)
                }
            }
        }
    }

    private func cardActionButton(_ systemName: String,
                                  help: String,
                                  action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                // The selected card is always cream (both appearances), so the glyph must stay dark.
                .foregroundColor(Color(hex: 0x101014))
                .frame(width: 28, height: 28)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(BlockListStyle.primaryOrange.opacity(0.5), lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
        .fastTooltip(help)
        .accessibility(label: Text(help))
    }

    private func cardContent(_ summary: BlockListSummary, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            cardLeading(summary)
            cardTitle(summary, isSelected: isSelected)
            Spacer(minLength: 4)
            cardBadge(summary, isSelected: isSelected)
        }
    }

    private func cardTitle(_ summary: BlockListSummary, isSelected: Bool) -> some View {
        // While reveal mode is on, a hidden mode is labelled as such (and the card is dimmed).
        Text(summary.isHidden ? summary.title + BlockListText.hiddenSuffix : summary.title)
            .font(BlockListStyle.cardTitleFont)
            // #2571 (4): the selected card's fill is always cream/orange (both appearances), so its title
            // must stay dark — `.primary` turns white in dark mode and washes out against the selection.
            .foregroundColor(isSelected ? Color(hex: 0x101014) : .primary)
            .lineLimit(BlockListStyle.cardTitleLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }

    private func cardBadge(_ summary: BlockListSummary, isSelected: Bool) -> some View {
        Text(BlockListText.blocksBadge(for: summary.entryCount).uppercased())
            .font(BlockListStyle.badgeFont)
            .foregroundColor(isSelected ? BlockListStyle.selectedCardFill : BlockListStyle.badgeText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? BlockListStyle.primaryOrange : BlockListStyle.badgeFill)
            .cornerRadius(BlockListStyle.badgeRadius)
            .fixedSize()
    }

    /// The design draws an emoji tile; focus modes have no emoji field, so fall back to the mode's
    /// menu-bar colour swatch, which is what the legacy list shows today.
    @ViewBuilder
    private func cardLeading(_ summary: BlockListSummary) -> some View {
        if let emoji = summary.emoji {
            Text(emoji).font(.system(size: 22))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(HexToColor(hexString: summary.colorString)))
                .frame(width: 16, height: 16)
        }
    }

    // MARK: Right panel

    private func rightPanel(_ metrics: BlockListLayout.Metrics) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selected = store.selectedBlockList {
                panelHeader(selected, titleFontSize: metrics.titleFontSize)
                // The field still searches/filters the existing entries (unchanged). While it has text it
                // also offers quick-add cards (URL/keyword/app) just beneath it — replacing the old
                // bottom add bar.
                searchRow
                addResults
                categoryChips
                Divider().background(BlockListStyle.hairline)
                if selected.usesAllowList {
                    Text(BlockListText.allowListNotice)
                        .font(.system(size: 12))
                        .foregroundColor(BlockListStyle.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                suggestionChips
                entryTable(metrics)
            } else {
                Text(BlockListText.noBlockListSelected)
                    .font(BlockListStyle.bodyFont)
                    .foregroundColor(BlockListStyle.mutedText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(BlockListLayout.panelInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.textBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: BlockListStyle.panelRadius)
                .stroke(BlockListStyle.panelBorder, lineWidth: 1))
        .cornerRadius(BlockListStyle.panelRadius)
        // The panel is what absorbs a window narrower than the design allows for; clipping here
        // keeps any overflow inside the panel instead of painting over the window's edge.
        .clipped()
    }

    private func panelHeader(_ summary: BlockListSummary, titleFontSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if isEditingName && summary.canRename {
                // #2571 (14): the title turns into an inline field — type and press Enter to save,
                // Escape to cancel — mirroring the legacy list's inline rename.
                InlineNameField(
                    text: $nameDraft,
                    font: NSFont.systemFont(ofSize: titleFontSize, weight: .semibold),
                    onCommit: {
                        isEditingName = false
                        onRename(summary.index, nameDraft)
                    },
                    onCancel: { isEditingName = false })
                    .frame(height: titleFontSize + 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                titleLabel(summary, titleFontSize: titleFontSize)
                if summary.canRename {
                    SwiftUI.Button(action: { beginNameEdit(summary) }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 15))
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(FBButtonStyle())
                    .fastTooltip(BlockListText.renameBlockList)
                    .accessibility(label: Text(BlockListText.renameBlockList))
                }
            }

            Spacer(minLength: 12)

            // #2571 (14): the mode's colour swatch, sitting before the edit button; click to recolour.
            SwiftUI.Button(action: { onChangeColor(summary.index) }) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(HexToColor(hexString: summary.colorString)))
                    .frame(width: 20, height: 20)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(BlockListStyle.panelBorder, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
            .fastTooltip(BlockListText.changeColor)
            .accessibility(label: Text(BlockListText.changeColor))

            SwiftUI.Button(action: { onEdit(summary.index) }) {
                Image(nsImage: NSImage(named: NSImage.actionTemplateName) ?? NSImage())
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(FBButtonStyle())
            .fastTooltip(BlockListText.editBlockList)
            .accessibility(label: Text(BlockListText.editBlockList))
        }
    }

    /// The mode name. Clickable (like the pencil) to start renaming, unless the mode's name is fixed.
    @ViewBuilder
    private func titleLabel(_ summary: BlockListSummary, titleFontSize: CGFloat) -> some View {
        let label = Text([summary.emoji, summary.title].compactMap { $0 }.joined(separator: " "))
            .font(BlockListStyle.titleFont(size: titleFontSize))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .truncationMode(.tail)
        if summary.canRename {
            SwiftUI.Button(action: { beginNameEdit(summary) }) {
                label.contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
            .fastTooltip(BlockListText.renameBlockList)
            .accessibility(label: Text(BlockListText.renameBlockList))
        } else {
            label
        }
    }

    private func beginNameEdit(_ summary: BlockListSummary) {
        nameDraft = store.selectedName
        isEditingName = true
    }

    /// #2571 (NEW-A): the top field, dedicated to searching/filtering the existing URLs and apps.
    private var searchRow: some View {
        HStack(spacing: 6) {
            Image(nsImage: NSImage(named: NSImage.touchBarSearchTemplateName) ?? NSImage())
            TextField(BlockListText.searchEntries, text: $store.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(BlockListStyle.bodyFont)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .frame(height: BlockListStyle.controlHeight)
        .background(BlockListStyle.searchFill)
        .overlay(
            RoundedRectangle(cornerRadius: BlockListStyle.cardRadius)
                .stroke(BlockListStyle.hairline, lineWidth: BlockListStyle.cardStroke))
        .cornerRadius(BlockListStyle.cardRadius)
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    // MARK: Quick-add cards (search-driven)

    /// While the search field has text, quick-add cards sit beneath it: a URL/keyword card for the typed
    /// text (a URL once it looks like a domain, otherwise a keyword), and the single best-matching
    /// installed app — or "Add app manually" when nothing matches. Tapping a card adds the entry and
    /// clears the search. With an empty field there are no cards; the field just filters the list as before.
    @ViewBuilder
    private var addResults: some View {
        let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            // Cards hug their content but stay inside the panel: the trailing spacer absorbs slack while
            // there's room, and when the two cards would exceed the width their labels truncate instead
            // of overflowing the frame.
            HStack(alignment: .top, spacing: 10) {
                websiteAddCard(query)
                appAddCard(query)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The typed text offered as a URL (once it looks like a domain) or otherwise as a keyword.
    private func websiteAddCard(_ query: String) -> some View {
        let isURL = BlockListEntryClassifier.looksLikeURL(query)
        let shown = cardTitle(query)
        return addCard(
            eyebrow: isURL ? BlockListText.addUrlEyebrow : BlockListText.addKeywordEyebrow,
            title: isURL ? shown : "\u{201C}\(shown)\u{201D}",
            icon: .symbol(isURL ? "link" : "keyboard"),
            action: { addWebsiteFromSearch(query) })
    }

    /// Caps an over-long typed entry for the card label; the full value is still what gets added.
    private func cardTitle(_ text: String) -> String {
        let maxChars = 44
        return text.count > maxChars ? String(text.prefix(maxChars)) + "\u{2026}" : text
    }

    /// The single best-matching installed app, or the manual file-picker fallback when nothing matches.
    @ViewBuilder
    private func appAddCard(_ query: String) -> some View {
        if let app = bestAppMatch(for: query) {
            addCard(eyebrow: BlockListText.addAppEyebrow,
                    title: InstalledApps.shared.distinctDisplayName(for: app) ?? app.name,
                    icon: .app(app),
                    action: { addAppFromSearch(app) })
        } else {
            addCard(eyebrow: BlockListText.addAppManuallyEyebrow,
                    title: BlockListText.addAppManually,
                    icon: .emoji("🤔"),
                    action: openAppPicker)
        }
    }

    /// Best installed-app match for the query: a prefix hit if any, otherwise the first substring hit.
    private func bestAppMatch(for query: String) -> InstalledApp? {
        installedApps.first { $0.hasPrefix(query) } ?? installedApps.first { $0.matches(query) }
    }

    private enum AddCardIcon { case symbol(String); case emoji(String); case app(InstalledApp) }

    /// One quick-add card: leading icon, a small eyebrow label, the entry title, and a trailing arrow —
    /// the layout from the design. Tapping runs `action`.
    private func addCard(eyebrow: String, title: String, icon: AddCardIcon,
                         action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            HStack(spacing: 8) {
                switch icon {
                case .app(let app):
                    Image(nsImage: InstalledApps.shared.icon(for: app))
                        .resizable().frame(width: 24, height: 24)
                case .symbol(let name):
                    Image(systemName: name)
                        .font(.system(size: 18))
                        .foregroundColor(BlockListStyle.mutedText)
                        .frame(width: 24, height: 24)
                case .emoji(let glyph):
                    Text(glyph)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(eyebrow)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(BlockListStyle.mutedText)
                        .lineLimit(1)
                    Text(title)
                        .font(BlockListStyle.bodyFont)
                        .foregroundColor(Color(NSColor.labelColor))
                        .lineLimit(1)
                }
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BlockListStyle.primaryOrange)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .frame(height: BlockListStyle.controlHeight + 12)
            // No fixedSize: the card hugs its content while there's room, but can shrink (labels
            // truncate) so the two cards always stay inside the panel instead of overflowing.
            .overlay(RoundedRectangle(cornerRadius: BlockListStyle.cardRadius)
                .stroke(BlockListStyle.hairline, lineWidth: BlockListStyle.cardStroke))
            .cornerRadius(BlockListStyle.cardRadius)
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }

    private func addWebsiteFromSearch(_ query: String) {
        _ = store.addWebsite(query)
        DispatchQueue.main.async { store.searchText = "" }
    }

    private func addAppFromSearch(_ app: InstalledApp) {
        _ = store.addApp(app.url.path)
        DispatchQueue.main.async { store.searchText = "" }
    }

    /// "Add app manually": opens the host's file picker and clears the search, like the other cards.
    private func openAppPicker() {
        onAddApp()
        DispatchQueue.main.async { store.searchText = "" }
    }

    /// There are ten chips, so they scroll horizontally at any realistic panel width. The trailing
    /// fade is what tells the user that — without it the last chip simply looks cut in half.
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: BlockListStyle.chipSpacing) {
                chip(for: nil)
                ForEach(DistractionCategory.orderedForFiltering, id: \.self) { category in
                    chip(for: category)
                }
            }
            .padding(.vertical, 2)
            .padding(.trailing, BlockListStyle.chipFadeWidth)
        }
        .mask(chipScrollFade)
    }

    /// Dissolves the chips into the panel at the trailing edge. A mask rather than an overlay,
    /// because an overlay drawn over a `ScrollView` does not composite on macOS 11.
    private var chipScrollFade: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: BlockListStyle.chipFadeStart),
                .init(color: .clear, location: 1),
            ]),
            startPoint: .leading,
            endPoint: .trailing)
    }

    private func chip(for category: DistractionCategory?) -> some View {
        let isSelected = store.activeCategory == category
        let title = category?.displayName ?? BlockListText.filterAll
        return SwiftUI.Button(action: { store.activeCategory = category }) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(title)
                    .font(BlockListStyle.chipFont)
                    .fixedSize()
                Text("(\(store.count(for: category)))")
                    .font(BlockListStyle.chipCountFont)
                    .fixedSize()
            }
            .foregroundColor(isSelected ? BlockListStyle.primaryOrange : BlockListStyle.unselectedChipText)
            .opacity(isSelected ? 1 : 0.8)
        }
        .buttonStyle(FBButtonStyle())
        .accessibility(addTraits: isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var suggestionChips: some View {
        let suggestions = store.suggestions()
        if let category = store.activeCategory, !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(BlockListText.commonlyBlockedIn(category))
                    .font(BlockListStyle.sectionLabelFont)
                    .foregroundColor(BlockListStyle.mutedText)
                    .lineLimit(1)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            suggestionChip(suggestion, in: category)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func suggestionChip(_ suggestion: String, in category: DistractionCategory) -> some View {
        SwiftUI.Button(action: {
            store.draftCategory = category
            store.addWebsite(suggestion)
        }) {
            HStack(spacing: 8) {
                Image(nsImage: NSImage(named: NSImage.addTemplateName) ?? NSImage())
                Text(suggestion).font(BlockListStyle.buttonFont)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: BlockListStyle.cardRadius)
                    .stroke(BlockListStyle.hairline, lineWidth: BlockListStyle.cardStroke))
            .cornerRadius(BlockListStyle.cardRadius)
        }
        .buttonStyle(FBButtonStyle())
    }

    private func entryTable(_ metrics: BlockListLayout.Metrics) -> some View {
        let columns = metrics.columns
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: BlockListLayout.columnSpacing) {
                Spacer().frame(width: BlockListLayout.avatarSize)
                Text(BlockListText.columnName).frame(width: columns.name, alignment: .leading)
                Text(BlockListText.columnCategory).frame(width: columns.category, alignment: .leading)
                Text(BlockListText.columnType).frame(width: columns.type, alignment: .leading)
                Spacer().frame(width: BlockListLayout.removeButtonWidth)
            }
            .font(BlockListStyle.sectionLabelFont)
            .foregroundColor(BlockListStyle.mutedText)
            .lineLimit(1)
            .frame(width: metrics.laidOutRowWidth, alignment: .leading)
            .padding(.bottom, 8)

            if store.visibleEntries.isEmpty {
                Text(store.activeCategory == nil ? BlockListText.noEntries : BlockListText.noEntriesForCategory)
                    .font(BlockListStyle.bodyFont)
                    .foregroundColor(BlockListStyle.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.visibleEntries) { entry in
                            entryRow(entry, columns: columns, rowWidth: metrics.laidOutRowWidth)
                            Divider().background(BlockListStyle.hairline)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func entryRow(_ entry: BlockListEntry,
                          columns: BlockListColumnWidths,
                          rowWidth: CGFloat) -> some View {
        HStack(spacing: BlockListLayout.columnSpacing) {
            Text(entry.avatarLetter)
                .font(BlockListStyle.bodyFont)
                .foregroundColor(BlockListStyle.rowText)
                .frame(width: BlockListLayout.avatarSize, height: BlockListLayout.avatarSize)
                .background(BlockListStyle.avatarFill)
                .cornerRadius(BlockListStyle.pillRadius)

            Text(entry.displayName)
                .font(BlockListStyle.bodyFont)
                .foregroundColor(BlockListStyle.rowText)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: columns.name, alignment: .leading)

            categoryMenu(for: entry, width: columns.category)

            Text(entry.type.displayName)
                .font(BlockListStyle.bodyFont)
                .foregroundColor(BlockListStyle.rowText)
                .lineLimit(1)
                .frame(width: columns.type, alignment: .leading)

            SwiftUI.Button(action: { store.remove(entry) }) {
                Image(nsImage: NSImage(named: NSImage.removeTemplateName) ?? NSImage())
                    // #2571: a SQUARE bordered-button affordance for the remove control (equal sides),
                    // centred in the reserved column slot rather than a wide rectangle.
                    .frame(width: 28, height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(BlockListStyle.panelBorder, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(FBButtonStyle())
            .frame(width: BlockListLayout.removeButtonWidth)
            .fastTooltip(BlockListText.removeEntry)
            .accessibility(label: Text(BlockListText.removeEntry))
        }
        .frame(width: rowWidth, alignment: .leading)
        .padding(.vertical, BlockListStyle.rowSpacing)
    }

    /// The category cell is the design's pill, made editable — it is how a user files an entry.
    private func categoryMenu(for entry: BlockListEntry, width: CGFloat) -> some View {
        Menu {
            ForEach(DistractionCategory.orderedForFiltering, id: \.self) { category in
                SwiftUI.Button(category.displayName) {
                    store.setCategory(category, forEntry: entry.value)
                }
            }
        } label: {
            Text(entry.category.displayName)
                .font(BlockListStyle.sectionLabelFont)
                .foregroundColor(BlockListStyle.primaryOrange)
                .lineLimit(1)
                .truncationMode(.tail)
                // The pill hugs its text at comfortable widths and stops growing at the column's,
                // so a long category name can never push the Type column off the row.
                .frame(maxWidth: width - BlockListStyle.pillHorizontalPadding * 2, alignment: .leading)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        // The pill fill has to sit outside the Menu: a borderless menu style discards the label's
        // own background, so styling the Text alone renders an unfilled pill.
        .fixedSize()
        .padding(.horizontal, BlockListStyle.pillHorizontalPadding)
        .padding(.vertical, 5)
        .background(BlockListStyle.categoryPillFill)
        .cornerRadius(BlockListStyle.pillRadius)
        .frame(width: width, alignment: .leading)
        .clipped()
    }
}

// MARK: - Inline name editor

/// A single-line `NSTextField` that grabs focus as soon as it appears, commits on Return and cancels
/// on Escape — the AppKit inline-edit behaviour the legacy focus-mode list had. Used for renaming a
/// focus mode in place of its title. (#2571 14)
@available(macOS 11.0, *)
private struct InlineNameField: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.font = font
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.usesSingleLineMode = true
        field.lineBreakMode = .byTruncatingTail
        field.maximumNumberOfLines = 1
        field.delegate = context.coordinator
        field.cell?.sendsActionOnEndEditing = false
        // Focus and select all on the next runloop tick, once the field is in a window.
        DispatchQueue.main.async {
            guard field.window?.firstResponder !== field.currentEditor() else { return }
            field.window?.makeFirstResponder(field)
            field.currentEditor()?.selectAll(nil)
        }
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Don't clobber what the user is typing; only sync when the field isn't being edited.
        if nsView.currentEditor() == nil, nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        private let parent: InlineNameField
        init(_ parent: InlineNameField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView,
                     doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.text = (control as? NSTextField)?.stringValue ?? parent.text
                parent.onCommit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.onCancel()
                return true
            default:
                return false
            }
        }
    }
}

// The reusable `.fastTooltip(_:)` modifier lives in BlockingScheduleStore.swift, alongside the other
// shared SwiftUI redesign helpers (FBButtonStyle, pointingHandCursor).
