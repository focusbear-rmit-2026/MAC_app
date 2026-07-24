//
//  BlockingScheduleCalendarView.swift
//  Focus Bear
//
//  "Calendar" tab of the redesigned blocking-schedules screen.
//  Implements Figma calendar options 4.2 (Week) and 4.3 (Day): a Google-style
//  timeline where each recurring weekly schedule is drawn as a block on the days
//  it applies to. Fully interactive — drag an empty slot to create, drag a
//  block's edges to resize, drag its body to move; all changes persist.
//

import SwiftUI

@available(macOS 11.0, *)
struct BlockingScheduleCalendarView: View {
    @ObservedObject var store: BlockingScheduleStore
    /// Open the existing editor for the schedule with this id.
    var onSelectSchedule: (String) -> Void
    /// Drag-create: open the editor pre-filled for a new schedule.
    var onCreate: (_ weekday: Int, _ startMinutes: Int, _ endMinutes: Int) -> Void
    /// Start the add flow (Quick-Start presets).
    var onAdd: () -> Void

    enum CalendarMode: String, CaseIterable { case week = "Week", day = "Day" }

    @SwiftUI.State private var mode: CalendarMode = .week
    @SwiftUI.State private var anchorDate = Date()
    @SwiftUI.State private var segmentDrag: SegmentDragState?
    @SwiftUI.State private var createDraft: CreateDraft?
    @SwiftUI.State private var hoveredSegmentID: String?

    private let hourHeight: CGFloat = 46
    private let gutterWidth: CGFloat = 52
    private var dayHeight: CGFloat { hourHeight * 24 }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 0) {
            controlsBar
            Divider()
            GeometryReader { geo in
                // reserve ~16pt for the always-visible vertical scroller
                let dayWidth = max(60, (geo.size.width - gutterWidth - 16) / CGFloat(displayedDays.count))
                // .leading so the header row isn't centred (it's narrower than the full width); it must
                // start at x=0 like the full-width timeline scroll view, or the columns won't line up.
                VStack(alignment: .leading, spacing: 0) {
                    dayHeaderRow(dayWidth: dayWidth)
                    Divider()
                    timeline(dayWidth: dayWidth)
                }
            }
            // Inset the timeline from the window's right edge so the always-visible (legacy) vertical
            // scroller isn't flush against — and clipped by — the edge.
            .padding(.trailing, 12)
        }
        .background(FBColor.background)
    }

    // MARK: Controls

    private var controlsBar: some View {
        HStack(spacing: 12) {
            SwiftUI.Button("Today") { anchorDate = Date() }
                .buttonStyle(FBButtonStyle())
                .font(.fbSemibold(13))
                .foregroundColor(FBColor.accent)

            SwiftUI.Button(action: { shift(by: -1) }) { Image(systemName: "chevron.left") }
                .buttonStyle(FBButtonStyle())
            Text(periodLabel)
                .font(.fbSemibold(14))
                .frame(minWidth: 150)
            SwiftUI.Button(action: { shift(by: 1) }) { Image(systemName: "chevron.right") }
                .buttonStyle(FBButtonStyle())

            Spacer()

            SwiftUI.Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add blocking schedule")
                }
                .font(.fbSemibold(13))
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(FBColor.accent))
            }
            .buttonStyle(FBButtonStyle())

            Menu {
                ForEach(CalendarMode.allCases, id: \.self) { m in
                    SwiftUI.Button(m.rawValue) { mode = m }
                }
            } label: {
                Text(mode.rawValue)
                    .font(.fbMedium(13))
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .fixedSize()
            .pointingHandCursor()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: Day header

    private func dayHeaderRow(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // fixed-width spacer matching the timeline's hour gutter (both are exactly gutterWidth),
            // so the day columns start at the same x in the header and the timeline.
            // (a plain Color.clear is vertically greedy and would inflate the row.)
            Color.clear.frame(width: gutterWidth, height: 1)
            ForEach(displayedDays, id: \.self) { date in
                VStack(spacing: 2) {
                    Text(weekdaySymbol(date).uppercased())
                        .font(.fbMedium(11))
                        .foregroundColor(.secondary)
                    Text(dayNumber(date))
                        .font(.fbSemibold(15))
                        .foregroundColor(isToday(date) ? .white : .primary)
                        .frame(width: 26, height: 26)
                        .background(
                            Circle().fill(isToday(date) ? FBColor.accent : Color.clear)
                        )
                }
                // fill the row height so the separator spans the full header and lines up with the
                // timeline's column grid below.
                .frame(width: dayWidth)
                .frame(maxHeight: .infinity)
                .overlay(Rectangle().frame(width: 1).foregroundColor(FBColor.grayBorder.opacity(0.4)),
                         alignment: .trailing)
            }
        }
        .frame(height: 52)
        // Fill the width and left-align so the header row starts at x=0 (same origin as the timeline),
        // instead of being centred as a narrower-than-full-width row.
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Timeline

    private func timeline(dayWidth: CGFloat) -> some View {
        AlwaysVerticalScroll(initialScrollY: CGFloat(7) * hourHeight) {
            HStack(alignment: .top, spacing: 0) {
                hoursColumn
                ForEach(displayedDays, id: \.self) { date in
                    dayColumn(date: date, dayWidth: dayWidth)
                }
            }
            // left-align inside the scroll's document view so the columns start at x=0, matching the header.
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var hoursColumn: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(hourLabel(hour))
                    .font(.fbRegular(10))
                    .foregroundColor(.secondary)
                    // (gutterWidth - 6) + 6pt trailing padding = gutterWidth total, so the hours gutter
                    // is exactly as wide as the header's gutter spacer and the day columns line up.
                    .frame(width: gutterWidth - 6, height: hourHeight, alignment: .topTrailing)
                    .padding(.trailing, 6)
                    .id("hour-\(hour)")
            }
        }
    }

    private func dayColumn(date: Date, dayWidth: CGFloat) -> some View {
        let weekday = calendar.component(.weekday, from: date)
        let daySegments = store.segments(forWeekdays: [weekday]).filter { $0.weekday == weekday }
        let lanes = laneLayout(daySegments)
        return ZStack(alignment: .topLeading) {
            // hour gridlines
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { _ in
                    VStack(spacing: 0) {
                        Divider()
                        Spacer(minLength: 0)
                    }
                    .frame(height: hourHeight)
                }
            }

            // empty-area drag-to-create layer (sits below the blocks)
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: dayWidth, height: dayHeight)
                .gesture(createGesture(weekday: weekday))

            // create preview
            if let draft = createDraft, draft.weekday == weekday {
                let y = CGFloat(draft.startMinutes) / 60 * hourHeight
                let h = max(14, CGFloat(draft.endMinutes - draft.startMinutes) / 60 * hourHeight)
                RoundedRectangle(cornerRadius: 6)
                    .fill(FBColor.accent.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(FBColor.accent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    .frame(width: dayWidth - 4, height: h)
                    .offset(x: 2, y: y)
            }

            // schedule blocks (split into side-by-side lanes where they overlap)
            ForEach(daySegments) { segment in
                segmentView(segment, dayWidth: dayWidth,
                            lane: lanes[segment.id] ?? SegLane(index: 0, count: 1))
            }
        }
        .frame(width: dayWidth, height: dayHeight, alignment: .topLeading)
        .overlay(Rectangle().frame(width: 1).foregroundColor(FBColor.grayBorder.opacity(0.4)), alignment: .trailing)
    }

    /// Google-Calendar-style overlap layout: within each cluster of mutually
    /// overlapping segments, assign each a lane so they sit side by side.
    private func laneLayout(_ segments: [ScheduleSegment]) -> [String: SegLane] {
        var result: [String: SegLane] = [:]
        let sorted = segments.sorted { $0.startMinutes < $1.startMinutes }
        var i = 0
        while i < sorted.count {
            // build a cluster of transitively-overlapping segments
            var cluster = [sorted[i]]
            var clusterEnd = sorted[i].endMinutes
            var j = i + 1
            while j < sorted.count && sorted[j].startMinutes < clusterEnd {
                cluster.append(sorted[j])
                clusterEnd = max(clusterEnd, sorted[j].endMinutes)
                j += 1
            }
            // greedy lane assignment within the cluster
            var laneEnds: [Int] = []
            var laneOf: [String: Int] = [:]
            for seg in cluster {
                if let lane = laneEnds.firstIndex(where: { seg.startMinutes >= $0 }) {
                    laneEnds[lane] = seg.endMinutes
                    laneOf[seg.id] = lane
                } else {
                    laneEnds.append(seg.endMinutes)
                    laneOf[seg.id] = laneEnds.count - 1
                }
            }
            for seg in cluster {
                result[seg.id] = SegLane(index: laneOf[seg.id] ?? 0, count: laneEnds.count)
            }
            i = j
        }
        return result
    }

    // MARK: Segment view

    private func segmentView(_ segment: ScheduleSegment, dayWidth: CGFloat, lane: SegLane) -> some View {
        // use live preview values while this segment is being dragged
        let dragging = segmentDrag?.scheduleID == segment.scheduleID && !segment.isContinuation
        let start = dragging ? segmentDrag!.previewStart : segment.startMinutes
        let end = dragging ? segmentDrag!.previewEnd : segment.endMinutes
        let y = CGFloat(start) / 60 * hourHeight
        let height = max(18, CGFloat(end - start) / 60 * hourHeight)

        let laneWidth = dayWidth / CGFloat(lane.count)
        let blockWidth = max(16, laneWidth - 3)
        let xOffset = CGFloat(lane.index) * laneWidth + 1.5
        let color = FBColor.scheduleColor(segment.colorIndex)
        let isHovered = hoveredSegmentID == segment.id
        return VStack(alignment: .leading, spacing: 2) {
            Text(segment.name)
                .font(.fbSemibold(11))
                .foregroundColor(.white)
                .lineLimit(2)
            if height > 40 {
                Text("\(BlockingScheduleStore.hhmm(fromMinutes: start)) – \(BlockingScheduleStore.hhmm(fromMinutes: end))")
                    .font(.fbRegular(9))
                    .foregroundColor(Color.white.opacity(0.9))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .frame(width: blockWidth, height: height, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 6).fill(color))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(segment.isActive || isHovered ? Color.white : Color.black.opacity(0.12),
                              lineWidth: segment.isActive || isHovered ? 2 : 1)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.28) : Color.clear, radius: isHovered ? 4 : 0, y: 1)
        .opacity(segment.isContinuation ? 0.6 : 1)
        .contentShape(Rectangle())
        .onHover { hovering in hoveredSegmentID = hovering ? segment.id : nil }
        .popover(isPresented: Binding(
            get: { hoveredSegmentID == segment.id },
            set: { shown in if !shown && hoveredSegmentID == segment.id { hoveredSegmentID = nil } }
        ), arrowEdge: .trailing) {
            detailPopover(for: segment)
        }
        .onTapGesture { onSelectSchedule(segment.scheduleID) }
        .gesture(segmentGesture(segment, height: height),
                 including: segment.isContinuation ? .subviews : .all)
        // Position by layout (padding), NOT .offset. `.offset` is a render-time transform that leaves
        // `.onHover`'s tracking area at the block's pre-offset position — so any block not starting at
        // midnight (e.g. a 3-hour schedule) has its hover region stranded at the top of the column,
        // under the taller blocks, and never fires. (A full-day block works only because its offset y
        // is 0, so visual and layout coincide.) Padding moves the real laid-out frame, so hover, click
        // and popover all align with where the block is actually drawn. The wrapping infinity-frame
        // makes the segment fill the column; its transparent area isn't hit-testable, so it doesn't
        // block sibling blocks or the empty-area create gesture underneath.
        .padding(.leading, xOffset)
        .padding(.top, y)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Large hover card with the schedule's details.
    private func detailPopover(for segment: ScheduleSegment) -> some View {
        let schedule = store.schedules.first(where: { $0.id == segment.scheduleID })
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let chosen = schedule?.emoji, !chosen.isEmpty {
                    Text(chosen).font(.system(size: 18))
                } else {
                    Circle().fill(FBColor.scheduleColor(segment.colorIndex)).frame(width: 12, height: 12)
                }
                Text(schedule?.name ?? segment.name)
                    .font(.fbBold(15))
                    .foregroundColor(.primary)
            }
            Divider()
            if let s = schedule {
                detailRow("Time", "\(s.startTime.formattedTime()) – \(s.endTime.formattedTime())")
                detailRow("Days", s.daysOfWeek.formattedDays())
                let blockList = store.blockListName(for: s)
                if !blockList.isEmpty { detailRow("Block list", blockList) }
                detailRow("Strictness", s.blockLevelString)
            }
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.fbMedium(12)).foregroundColor(.secondary)
                .frame(width: 74, alignment: .leading)
            Text(value)
                .font(.fbMedium(12)).foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Gestures

    private func segmentGesture(_ segment: ScheduleSegment, height: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let handle: CGFloat = 10
                let mode: SegmentDragState.Mode
                if segmentDrag?.scheduleID != segment.scheduleID {
                    // decide mode from where the drag started within the block
                    if value.startLocation.y <= handle { mode = .resizeStart }
                    else if value.startLocation.y >= height - handle { mode = .resizeEnd }
                    else { mode = .move }
                    segmentDrag = SegmentDragState(
                        scheduleID: segment.scheduleID, mode: mode,
                        origStart: segment.startMinutes, origEnd: segment.endMinutes,
                        previewStart: segment.startMinutes, previewEnd: segment.endMinutes)
                }
                guard var state = segmentDrag else { return }
                let delta = snap(Int(value.translation.height / hourHeight * 60))
                switch state.mode {
                case .move:
                    let duration = state.origEnd - state.origStart
                    var newStart = state.origStart + delta
                    newStart = max(0, min(1440 - duration, newStart))
                    state.previewStart = newStart
                    state.previewEnd = newStart + duration
                case .resizeStart:
                    state.previewStart = max(0, min(state.origEnd - 15, state.origStart + delta))
                case .resizeEnd:
                    state.previewEnd = max(state.origStart + 15, min(1440, state.origEnd + delta))
                }
                segmentDrag = state
            }
            .onEnded { _ in
                if let state = segmentDrag {
                    store.updateTimes(scheduleID: state.scheduleID,
                                      startMinutes: state.previewStart,
                                      endMinutes: state.previewEnd)
                }
                segmentDrag = nil
            }
    }

    private func createGesture(weekday: Int) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                let a = snap(Int(value.startLocation.y / hourHeight * 60))
                let b = snap(Int(value.location.y / hourHeight * 60))
                createDraft = CreateDraft(weekday: weekday,
                                          startMinutes: max(0, min(a, b)),
                                          endMinutes: min(1440, max(a, b)))
            }
            .onEnded { value in
                let a = snap(Int(value.startLocation.y / hourHeight * 60))
                let b = snap(Int(value.location.y / hourHeight * 60))
                var start = max(0, min(a, b))
                var end = min(1440, max(a, b))
                if end - start < 30 { end = min(1440, start + 60) }      // tap / tiny drag → default 1h
                if end <= start { start = max(0, end - 60) }
                createDraft = nil
                onCreate(weekday, start, end)
            }
    }

    // MARK: Date helpers

    private var displayedDays: [Date] {
        switch mode {
        case .day:
            return [calendar.startOfDay(for: anchorDate)]
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: anchorDate) else {
                return [calendar.startOfDay(for: anchorDate)]
            }
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
        }
    }

    private func shift(by amount: Int) {
        let component: Calendar.Component = mode == .week ? .weekOfYear : .day
        if let next = calendar.date(byAdding: component, value: amount, to: anchorDate) {
            anchorDate = next
        }
    }

    private var periodLabel: String {
        let formatter = DateFormatter()
        if mode == .day {
            formatter.dateFormat = "EEE, d MMM"
            return formatter.string(from: anchorDate)
        } else {
            formatter.dateFormat = "d MMM"
            let days = displayedDays
            guard let first = days.first, let last = days.last else { return "" }
            return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
        }
    }

    private func weekdaySymbol(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date)
    }
    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private func isToday(_ date: Date) -> Bool { calendar.isDateInToday(date) }

    private func hourLabel(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour == 12 { return "12 PM" }
        return hour < 12 ? "\(hour) AM" : "\(hour - 12) PM"
    }

    private func snap(_ minutes: Int) -> Int { Int((Double(minutes) / 15).rounded()) * 15 }
}

// MARK: - Drag state

struct SegmentDragState {
    enum Mode { case move, resizeStart, resizeEnd }
    let scheduleID: String
    let mode: Mode
    let origStart: Int
    let origEnd: Int
    var previewStart: Int
    var previewEnd: Int
}

struct CreateDraft {
    let weekday: Int
    let startMinutes: Int
    let endMinutes: Int
}

/// Horizontal lane for a calendar segment when schedules overlap.
struct SegLane {
    let index: Int
    let count: Int
}

// MARK: - Always-visible vertical scroll

/// Wraps SwiftUI content in an AppKit `NSScrollView` with a permanent (legacy)
/// vertical scroller, so it's obvious the calendar scrolls. Also sets the
/// initial scroll position (e.g. to ~7 AM) after first layout.
@available(macOS 11.0, *)
struct AlwaysVerticalScroll<Content: View>: NSViewRepresentable {
    let initialScrollY: CGFloat
    @ViewBuilder var content: () -> Content

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = false
        scroll.scrollerStyle = .legacy
        scroll.drawsBackground = false

        let host = NSHostingView(rootView: AnyView(content()))
        host.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = host
        let clip = scroll.contentView
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: clip.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: clip.trailingAnchor),
            host.topAnchor.constraint(equalTo: clip.topAnchor),
        ])
        context.coordinator.scrollView = scroll
        DispatchQueue.main.async { context.coordinator.applyInitialScroll(initialScrollY) }
        return scroll
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let host = nsView.documentView as? NSHostingView<AnyView> {
            host.rootView = AnyView(content())
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        weak var scrollView: NSScrollView?
        private var didInitialScroll = false
        func applyInitialScroll(_ y: CGFloat) {
            guard !didInitialScroll, let scroll = scrollView, let doc = scroll.documentView else { return }
            didInitialScroll = true
            let maxY = max(0, doc.frame.height - scroll.contentView.bounds.height)
            scroll.contentView.scroll(to: NSPoint(x: 0, y: min(y, maxY)))
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}
