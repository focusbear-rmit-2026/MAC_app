//
//  HabitTaskChecklistView.swift
//  Focus Bear
//
//  The checklist of Day Plan tasks attached to the habit currently playing, shown inside the habit
//  player. Deliberately quiet — a small caption and one line per task, in a pane the user only ever
//  sees for a habit they dragged tasks onto. Renders nothing when no task is attached.
//

import AppKit
import SwiftUI

/// One row of the habit player's task checklist.
struct HabitChecklistItem: Identifiable, Equatable {
    let id: String
    let title: String
    let done: Bool
}

struct HabitTaskChecklistView: View {

    let items: [HabitChecklistItem]
    /// Called with the task id and the completion state it should take.
    let onToggle: (String, Bool) -> Void

    static let rowHeight: CGFloat = 24
    static let headerHeight: CGFloat = 26
    /// Rows that fit the pane's maximum height; past this the list actually scrolls.
    static let rowsBeforeScrolling = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ScheduleText.habitTasksTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(height: Self.headerHeight - 6)
            // A short list never overflows the pane, so the scroller would be pure noise — but keep
            // the ScrollView so a long one can still be reached.
            ScrollView(.vertical, showsIndicators: items.count > Self.rowsBeforeScrolling) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(items) { item in
                        row(for: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 6))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func row(for item: HabitChecklistItem) -> some View {
        SwiftUI.Button(action: { onToggle(item.id, !item.done) }) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.done ? .accentColor : .secondary)
                    .font(.system(size: 13))
                Text(item.title)
                    .font(.system(size: 13))
                    .strikethrough(item.done)
                    .foregroundColor(item.done ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(minHeight: Self.rowHeight, alignment: .topLeading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(label: Text(item.title))
    }
}
