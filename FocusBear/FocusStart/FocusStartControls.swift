//
//  FocusStartControls.swift
//  Focus Bear
//
//  The pieces both start screens are built from: the duration dial, the accordion card, the pill
//  toggle, the radio row, the primary button and the bear panel. Everything sizes itself from a
//  `FocusStartScale` so one window resize re-derives the whole screen.
//

import SwiftUI

// MARK: - Primary button

@available(macOS 11.0, *)
struct FocusStartPrimaryButton: SwiftUI.View {
    let title: String
    let scale: FocusStartScale
    let isEnabled: Bool
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            Text(title)
                .font(scale.font(FocusStartLayout.buttonFont, .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: scale.pt(FocusStartLayout.primaryButtonHeight))
                // PlainButtonStyle otherwise hit-tests only the text, leaving the painted
                // padding inert. Match the full visible button without adding another gesture.
                .contentShape(RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.buttonCornerRadius)))
        }
        .buttonStyle(FBButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.buttonCornerRadius))
                .fill(FocusStartPalette.accent)
        )
        .overlay(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.buttonCornerRadius))
                .stroke(Color.white.opacity(0.4), lineWidth: scale.pt(2))
        )
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }
}

// MARK: - The link between the simple and the advanced screen

@available(macOS 11.0, *)
struct FocusStartModeLink: SwiftUI.View {
    let topLine: String
    let bottomLine: String
    /// The advanced screen puts its chevron on the left and points it back.
    let pointsBack: Bool
    let scale: FocusStartScale
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            HStack(spacing: scale.pt(24)) {
                if pointsBack { chevron }
                VStack(alignment: pointsBack ? .leading : .trailing, spacing: 0) {
                    Text(topLine)
                        .font(scale.font(FocusStartLayout.cardTitleFont, .semibold))
                        .foregroundColor(FocusStartPalette.accent)
                    Text(bottomLine)
                        .font(scale.font(FocusStartLayout.cardTitleFont, .semibold))
                        .foregroundColor(FocusStartPalette.primaryText)
                }
                // #2449: without a line limit the header row's leftover width squeezed the link into a
                // four-line ragged column that broke "Regular" as "Regul / ar". One line each, and a
                // long translation loses its tail rather than a word being split down the middle.
                // The advanced screen pairs this with a fixed-width column so the width is knowable.
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)
                if !pointsBack { chevron }
            }
            .padding(.vertical, scale.pt(36))
            .padding(.horizontal, scale.pt(48))
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }

    private var chevron: some SwiftUI.View {
        Image(systemName: pointsBack ? "chevron.left" : "chevron.right")
            .font(scale.font(FocusStartLayout.cardTitleFont, .medium))
            .foregroundColor(FocusStartPalette.primaryText)
    }
}

// MARK: - Duration dial

/// The "− 00 hr 25 min +" readout plus the 0–8 HRS slider under it, shared by both screens.
@available(macOS 11.0, *)
struct FocusStartDurationDial: SwiftUI.View {
    @Binding var duration: FocusStartDuration
    let strings: FocusStartStrings
    let scale: FocusStartScale
    let isEnabled: Bool

    var body: some SwiftUI.View {
        VStack(spacing: scale.pt(52)) {
            HStack(spacing: scale.pt(42)) {
                stepperButton(systemName: "minus.circle", steps: -1)
                readout
                stepperButton(systemName: "plus.circle", steps: 1)
            }
            slider
        }
        .opacity(isEnabled ? 1 : 0.5)
        .disabled(!isEnabled)
    }

    private var readout: some SwiftUI.View {
        Group {
            if let clock = FocusStartDurationFormatter(strings: strings).clockComponents(for: duration) {
                HStack(alignment: .firstTextBaseline, spacing: scale.pt(16)) {
                    Text(clock.hours)
                        .font(scale.font(FocusStartLayout.durationNumberFont, .semibold))
                        .foregroundColor(FocusStartPalette.accent)
                    Text(strings.hourUnit)
                        .font(scale.font(FocusStartLayout.durationUnitFont))
                        .foregroundColor(FocusStartPalette.mutedText)
                    Text(clock.minutes)
                        .font(scale.font(FocusStartLayout.durationNumberFont, .semibold))
                        .foregroundColor(FocusStartPalette.accent)
                    Text(strings.minuteUnit)
                        .font(scale.font(FocusStartLayout.durationUnitFont))
                        .foregroundColor(FocusStartPalette.mutedText)
                }
            } else {
                Text(strings.untimedGlyph)
                    .font(scale.font(FocusStartLayout.durationNumberFont, .semibold))
                    .foregroundColor(FocusStartPalette.accent)
            }
        }
    }

    private func stepperButton(systemName: String, steps: Int) -> some SwiftUI.View {
        SwiftUI.Button(action: { duration = duration.stepped(by: steps) }) {
            Image(systemName: systemName)
                .resizable()
                .frame(width: scale.pt(FocusStartLayout.stepperDiameter),
                       height: scale.pt(FocusStartLayout.stepperDiameter))
                .foregroundColor(FocusStartPalette.accent)
                .opacity(0.5)
        }
        .buttonStyle(FBButtonStyle())
        .disabled(duration.isUntimed)
    }

    private var slider: some SwiftUI.View {
        HStack(spacing: scale.pt(31)) {
            Text(strings.sliderMinimumLabel)
                .font(scale.font(FocusStartLayout.sliderBoundFont, .medium))
                .foregroundColor(FocusStartPalette.mutedText)
                .fixedSize()
            track
            Text(strings.sliderMaximumLabel)
                .font(scale.font(FocusStartLayout.sliderBoundFont, .medium))
                .foregroundColor(FocusStartPalette.mutedText)
                .fixedSize()
        }
    }

    private var track: some SwiftUI.View {
        let width = scale.pt(FocusStartLayout.sliderTrackWidth)
        let height = scale.pt(FocusStartLayout.sliderTrackHeight)
        let thumbWidth = scale.pt(FocusStartLayout.sliderThumbWidth)
        let thumbHeight = scale.pt(FocusStartLayout.sliderThumbHeight)
        let fraction = CGFloat(duration.sliderFraction)
        return ZStack(alignment: .leading) {
            Capsule().fill(FocusStartPalette.trackFill)
                .frame(width: width, height: height)
            Capsule().fill(FocusStartPalette.accent)
                .frame(width: max(height, width * fraction), height: height)
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.sliderThumbCornerRadius))
                .fill(FocusStartPalette.thumbFill)
                .frame(width: thumbWidth, height: thumbHeight)
                .overlay(dragHandle)
                .focusStartShadow(scale, blur: 40)
                .offset(x: min(width - thumbWidth, max(0, width * fraction - thumbWidth / 2)))
        }
        .frame(width: width, height: thumbHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !duration.isUntimed else { return }
                    duration = FocusStartDuration.fromSliderFraction(Double(value.location.x / width),
                                                                     isUntimed: duration.isUntimed)
                }
        )
    }

    /// The design's `drag_handle` glyph inside the thumb: two short vertical bars.
    private var dragHandle: some SwiftUI.View {
        HStack(spacing: scale.pt(14)) {
            ForEach(0..<2, id: \.self) { _ in
                Capsule()
                    .fill(FocusStartPalette.primaryText.opacity(0.8))
                    .frame(width: scale.pt(8), height: scale.pt(46))
            }
        }
    }
}

// MARK: - Accordion card

/// One of the advanced screen's three cards. Collapsed it is a title plus a summary line and a
/// chevron; expanded it shows `content` and its chevron points down.
@available(macOS 11.0, *)
struct FocusStartAccordionCard<Content: SwiftUI.View>: SwiftUI.View {
    let title: String
    let summary: String
    let systemIcon: String
    let isExpanded: Bool
    let scale: FocusStartScale
    let onToggle: () -> Void
    let content: () -> Content

    var body: some SwiftUI.View {
        VStack(spacing: scale.pt(FocusStartLayout.cardContentGap)) {
            header
            if isExpanded {
                content()
                    .padding(.horizontal, scale.pt(FocusStartLayout.cardInnerPadding))
            }
        }
        .padding(.top, scale.pt(FocusStartLayout.cardPadding))
        .padding(.horizontal, scale.pt(FocusStartLayout.cardPadding))
        .padding(.bottom, scale.pt(isExpanded ? FocusStartLayout.cardBottomPadding
                                              : FocusStartLayout.collapsedCardBottomPadding))
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.cardCornerRadius))
                .fill(FocusStartPalette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.cardCornerRadius))
                .stroke(FocusStartPalette.border, lineWidth: scale.pt(FocusStartLayout.cardBorder))
        )
    }

    private var header: some SwiftUI.View {
        SwiftUI.Button(action: onToggle) {
            HStack(spacing: 0) {
                // The collapsed card centres its title/summary column and parks the chevron on the
                // trailing edge, so the title needs a matching spacer on the leading edge.
                Spacer(minLength: 0)
                VStack(spacing: scale.pt(4)) {
                    HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
                        Image(systemName: systemIcon)
                            .font(scale.font(FocusStartLayout.cardTitleFont, .medium))
                            .foregroundColor(FocusStartPalette.accent)
                        Text(title)
                            .font(scale.font(FocusStartLayout.cardTitleFont, .semibold))
                            .foregroundColor(FocusStartPalette.primaryText)
                    }
                    if !isExpanded {
                        Text(summary)
                            .font(scale.font(FocusStartLayout.summaryFont, .medium))
                            .foregroundColor(FocusStartPalette.primaryText)
                            .opacity(0.5)
                    }
                }
                Spacer(minLength: 0)
                // #2571 (6): keep the chevron in a fixed position (the trailing edge) in both states,
                // changing only the glyph. Previously the expanded card moved it inline next to the
                // title, so it jumped ~50px to the left on expand.
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(scale.font(FocusStartLayout.cardTitleFont, .medium))
                    .foregroundColor(FocusStartPalette.primaryText)
                    .opacity(0.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }
}

// MARK: - Disclosure section

/// A collapsible sub-section *inside* an accordion card — the duration card's break settings (#2449:
/// the timing card had the dial, the slider, the break length, micro-breaks and untimed mode all in
/// one dense block).
///
/// Deliberately not a second `FocusStartAccordionCard`: it is drawn in the same rounded well as the
/// screen's other controls so it reads as part of the card it sits in rather than a card of its own,
/// while keeping the accordion's chevron language.
///
/// The summary shows in **both** states. Collapsing a section hides settings, so the header has to
/// keep saying what the session will actually do — otherwise a user who changed the break length can
/// no longer see it.
@available(macOS 11.0, *)
struct FocusStartDisclosureSection<Content: SwiftUI.View>: SwiftUI.View {
    let title: String
    let summary: String
    let systemIcon: String
    let isExpanded: Bool
    let scale: FocusStartScale
    let onToggle: () -> Void
    let content: () -> Content

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: scale.pt(FocusStartLayout.cardContentGap)) {
            header
            if isExpanded { content() }
        }
        .padding(scale.pt(FocusStartLayout.cardInnerPadding))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.controlCornerRadius))
                .fill(FocusStartPalette.fieldFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.controlCornerRadius))
                .stroke(FocusStartPalette.border, lineWidth: scale.pt(FocusStartLayout.fieldBorder))
        )
    }

    private var header: some SwiftUI.View {
        SwiftUI.Button(action: onToggle) {
            VStack(alignment: .leading, spacing: scale.pt(FocusStartLayout.tightGap)) {
                HStack(spacing: scale.pt(FocusStartLayout.inlineGap)) {
                    Image(systemName: systemIcon)
                        .font(scale.font(FocusStartLayout.bodyFont, .medium))
                        .foregroundColor(FocusStartPalette.accent)
                    Text(title)
                        .font(scale.font(FocusStartLayout.bodyFont, .medium))
                        .foregroundColor(FocusStartPalette.primaryText)
                    Spacer(minLength: scale.pt(FocusStartLayout.inlineGap))
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(scale.font(FocusStartLayout.summaryFont, .medium))
                        .foregroundColor(FocusStartPalette.primaryText)
                        .opacity(0.5)
                }
                // Collapsed, this line is the only thing saying what the session will do, so it gets
                // the full row width rather than competing with the title for it — a Spanish summary
                // beside the title truncated to "Descansos de 3…" and lost the micro-breaks state.
                if !isExpanded {
                    Text(summary)
                        .font(scale.font(FocusStartLayout.summaryFont))
                        .foregroundColor(FocusStartPalette.supportingText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }
}

// MARK: - Typeahead block-list picker

/// The block-list picker: a typeahead combo rather than a plain popup menu, because a user with a
/// dozen lists (several named after UUIDs) cannot find one in a long unsearchable scroll (#2449).
/// Type to filter, or open the dropdown as before.
///
/// AppKit-backed for the same reason the menu bar's `BlockListComboBox` is: SwiftUI on macOS 11 has
/// no searchable picker, and `NSComboBox.completes` gives the app's established typeahead behaviour
/// for free. Kept separate from that one because this screen sizes its type from `FocusStartScale`
/// rather than the menu's fixed 13pt; the two should collapse into one control when the start flow
/// and the menu share a design system.
@available(macOS 11.0, *)
struct FocusStartBlockListCombo: NSViewRepresentable {
    let items: [FocusStartBlockList]
    @Binding var selectedIndex: Int
    let placeholder: String
    let isEnabled: Bool
    let scale: FocusStartScale
    let onChange: () -> Void

    func makeNSView(context: Context) -> NSComboBox {
        let box = NSComboBox()
        box.completes = true                 // typeahead autocomplete as you type
        box.isEditable = true
        box.usesDataSource = false
        box.isBordered = false
        box.drawsBackground = false
        box.focusRingType = .none
        // The design draws the well; without this the combo stacks its own bezel and button border
        // inside it.
        (box.cell as? NSComboBoxCell)?.isButtonBordered = false
        box.numberOfVisibleItems = 10
        box.delegate = context.coordinator
        box.cell?.lineBreakMode = .byTruncatingTail
        return box
    }

    func updateNSView(_ box: NSComboBox, context: Context) {
        context.coordinator.parent = self
        box.font = getRegularFont(size: scale.pt(FocusStartLayout.fieldFont))
        box.placeholderString = placeholder
        box.isEnabled = isEnabled

        let names = items.map { $0.name }
        if (box.objectValues as? [String]) != names {
            box.removeAllItems()
            box.addItems(withObjectValues: names)
        }
        // Never fight the user's half-typed text: only push the model's name in when the field is not
        // being edited.
        let isEditing = box.currentEditor() != nil
        if !isEditing, items.indices.contains(selectedIndex), box.stringValue != names[selectedIndex] {
            box.stringValue = names[selectedIndex]
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: FocusStartBlockListCombo
        init(_ parent: FocusStartBlockListCombo) { self.parent = parent }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let box = notification.object as? NSComboBox else { return }
            // The selection isn't reflected in stringValue until the run loop turns; read it next tick.
            DispatchQueue.main.async { [weak box] in
                guard let box = box else { return }
                self.commit(index: box.indexOfSelectedItem)
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let box = obj.object as? NSComboBox else { return }
            let typed = box.stringValue
            if let index = parent.items.firstIndex(where: { $0.name.caseInsensitiveCompare(typed) == .orderedSame }) {
                commit(index: index)
            } else if parent.items.indices.contains(parent.selectedIndex) {
                // Unrecognised text is not a selection — put the current list's name back rather than
                // leaving the field showing something the session will not use.
                box.stringValue = parent.items[parent.selectedIndex].name
            }
        }

        private func commit(index: Int) {
            guard parent.items.indices.contains(index), index != parent.selectedIndex else { return }
            parent.selectedIndex = index
            parent.onChange()
        }
    }
}

// MARK: - Small controls

/// The design's pill switch. `Toggle` with the system switch style would draw the macOS blue one.
@available(macOS 11.0, *)
struct FocusStartToggle: SwiftUI.View {
    @Binding var isOn: Bool
    let scale: FocusStartScale

    var body: some SwiftUI.View {
        let width = scale.pt(FocusStartLayout.toggleWidth)
        let height = scale.pt(FocusStartLayout.toggleHeight)
        let knob = scale.pt(FocusStartLayout.toggleKnob)
        return SwiftUI.Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? FocusStartPalette.accent : FocusStartPalette.fieldFill)
                    .overlay(Capsule().stroke(FocusStartPalette.border, lineWidth: scale.pt(3)))
                    .frame(width: width, height: height)
                Circle()
                    .fill(isOn ? Color.white : FocusStartPalette.primaryText)
                    .frame(width: knob, height: knob)
                    .padding(.horizontal, (height - knob) / 2)
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }
}

/// One strictness option: a radio dot, its name and its one-line description.
@available(macOS 11.0, *)
struct FocusStartRadioOption: SwiftUI.View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let scale: FocusStartScale
    let action: () -> Void

    var body: some SwiftUI.View {
        SwiftUI.Button(action: action) {
            HStack(spacing: scale.pt(24)) {
                ZStack {
                    Circle()
                        .fill(FocusStartPalette.fieldFill)
                        .overlay(Circle().stroke(isSelected ? FocusStartPalette.accent : FocusStartPalette.controlBorder,
                                                 lineWidth: scale.pt(FocusStartLayout.fieldBorder)))
                    if isSelected {
                        Circle()
                            .fill(FocusStartPalette.accent)
                            .padding(scale.pt(12))
                    }
                }
                .frame(width: scale.pt(FocusStartLayout.radioDiameter),
                       height: scale.pt(FocusStartLayout.radioDiameter))
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(scale.font(FocusStartLayout.fieldFont, isSelected ? .semibold : .medium))
                        .foregroundColor(FocusStartPalette.primaryText)
                    Text(subtitle)
                        .font(scale.font(FocusStartLayout.summaryFont))
                        .foregroundColor(FocusStartPalette.supportingText)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FBButtonStyle())
    }
}

/// The design's rounded input well — used for the "Breaks after" number and the search fields.
@available(macOS 11.0, *)
struct FocusStartFieldBackground: ViewModifier {
    let scale: FocusStartScale
    let height: CGFloat
    let horizontalPadding: CGFloat

    func body(content: Content) -> some SwiftUI.View {
        content
            .padding(.horizontal, scale.pt(horizontalPadding))
            .frame(height: scale.pt(height))
            .background(
                RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.controlCornerRadius))
                    .fill(FocusStartPalette.fieldFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.controlCornerRadius))
                    .stroke(FocusStartPalette.border, lineWidth: scale.pt(FocusStartLayout.fieldBorder))
            )
    }
}

@available(macOS 11.0, *)
extension SwiftUI.View {
    func focusStartField(_ scale: FocusStartScale,
                         height: CGFloat = FocusStartLayout.fieldHeight,
                         horizontalPadding: CGFloat = 40) -> some SwiftUI.View {
        modifier(FocusStartFieldBackground(scale: scale, height: height, horizontalPadding: horizontalPadding))
    }
}

// MARK: - Bear panel

/// The bear illustration inside its cream disc, with the speech bubble the design hangs off it.
@available(macOS 11.0, *)
struct FocusStartBearPanel: SwiftUI.View {
    let imageName: String
    let bearWidthDesignPixels: CGFloat
    let bubbleText: String
    let scale: FocusStartScale

    var body: some SwiftUI.View {
        VStack(spacing: scale.pt(-40)) {
            ZStack {
                Circle()
                    .fill(FocusStartPalette.bearHalo)
                    .frame(width: scale.pt(FocusStartLayout.bearCircleDiameter),
                           height: scale.pt(FocusStartLayout.bearCircleDiameter))
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: scale.pt(bearWidthDesignPixels))
            }
            speechBubble
        }
    }

    private var speechBubble: some SwiftUI.View {
        Text(bubbleText)
            .font(scale.font(FocusStartLayout.bubbleFont))
            .multilineTextAlignment(.center)
            .foregroundColor(FocusStartPalette.speechText)
            .padding(.vertical, scale.pt(60))
            .padding(.horizontal, scale.pt(80))
            .frame(maxWidth: scale.pt(FocusStartLayout.speechBubbleWidth))
            .background(
                RoundedRectangle(cornerRadius: scale.pt(40))
                    .fill(FocusStartPalette.speechBackground)
            )
            .focusStartShadow(scale, blur: 14)
    }
}

// MARK: - Banners

/// The "Distraction blocking inactive… [Fix it]" strip both screens show above the title.
@available(macOS 11.0, *)
struct FocusStartPermissionsBanner: SwiftUI.View {
    let tip: String
    let buttonTitle: String
    let scale: FocusStartScale
    let action: () -> Void

    var body: some SwiftUI.View {
        HStack(spacing: scale.pt(FocusStartLayout.rowGap)) {
            Text(tip)
                .font(scale.font(FocusStartLayout.summaryFont))
                .foregroundColor(FocusStartPalette.primaryText)
                .multilineTextAlignment(.leading)
            SwiftUI.Button(action: action) {
                Text(buttonTitle)
                    .font(scale.font(FocusStartLayout.summaryFont, .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, scale.pt(36))
                    .padding(.vertical, scale.pt(16))
                    .background(
                        RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.badgeCornerRadius))
                            .fill(FocusStartPalette.accent)
                    )
            }
            .buttonStyle(FBButtonStyle())
        }
        .padding(scale.pt(28))
        .background(
            RoundedRectangle(cornerRadius: scale.pt(FocusStartLayout.fieldCornerRadius))
                .fill(FocusStartPalette.accent.opacity(0.08))
        )
    }
}
