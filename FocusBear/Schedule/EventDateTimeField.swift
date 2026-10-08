//
//  EventDateTimeField.swift
//  Focus Bear
//
//  Date + time entry for the Day Plan's Add/Edit event form: a date picker for the DAY, and a
//  plain text field for the TIME.
//
//  The day half keeps `NSDatePicker` — nobody complained about typing dates, and its stepper is
//  useful. The time half deliberately does NOT: `NSDatePicker`'s hour/minute segments zero-pad and
//  commit per keystroke, so typing "3" for the minutes shows "03" and reaching "30" is fiddly
//  (report 2026-06-24_21-08-27). A text field has no segments, so "3" then "0" is just "30", and
//  `EventTimeParser` accepts the other spellings people type ("730", "7.30", "7:30 am", "19:30").
//
//  It exposes `dateValue` with the same meaning `NSDatePicker` had, so the form's existing readers
//  (`startPickerChanged`, `saveEventForm`) keep working unchanged.
//

import AppKit

final class EventDateTimeField: NSStackView, NSTextFieldDelegate {

    private enum Layout {
        static let spacing: CGFloat = 6
        static let timeFieldWidth: CGFloat = 90
    }

    private let dayPicker = NSDatePicker()
    private let timeField = NSTextField()

    /// The last time the user typed that actually parsed. Unreadable text falls back to this rather
    /// than to an arbitrary time, so a half-finished edit can never silently save a wrong value.
    private var lastValidTime: EventTimeParser.ClockTime

    /// Target/action forwarded from BOTH halves, so the owner is notified however the value changed.
    /// (`NSControl`'s own target/action are unused here: this is a plain view, not a control.)
    private weak var changeTarget: AnyObject?
    private var changeAction: Selector?

    // MARK: - Value

    /// The combined day + time, matching what the `NSDatePicker` this replaced used to report.
    var dateValue: Date {
        get { EventTimeParser.combine(day: dayPicker.dateValue, time: currentTime) }
        set {
            dayPicker.dateValue = newValue
            lastValidTime = EventTimeParser.clockTime(of: newValue)
            timeField.stringValue = EventTimeParser.format(lastValidTime)
        }
    }

    /// The typed time if it parses, otherwise the last one that did.
    private var currentTime: EventTimeParser.ClockTime {
        EventTimeParser.parse(timeField.stringValue) ?? lastValidTime
    }

    /// Enables/disables both halves together. (`NSStackView` is a plain view, so this is our own
    /// property rather than an `NSControl` override — it stands in for the `isEnabled` the
    /// `NSDatePicker` this replaced exposed.)
    var isEnabled: Bool = true {
        didSet {
            dayPicker.isEnabled = isEnabled
            timeField.isEnabled = isEnabled
            timeField.isEditable = isEnabled
        }
    }

    // MARK: - Setup

    init(date: Date, target: AnyObject?, action: Selector?) {
        lastValidTime = EventTimeParser.clockTime(of: date)
        changeTarget = target
        changeAction = action
        super.init(frame: .zero)

        orientation = .horizontal
        alignment = .firstBaseline
        spacing = Layout.spacing
        translatesAutoresizingMaskIntoConstraints = false

        dayPicker.datePickerStyle = .textFieldAndStepper
        dayPicker.datePickerElements = .yearMonthDay
        dayPicker.dateValue = date
        dayPicker.target = self
        dayPicker.action = #selector(valueChanged)
        dayPicker.translatesAutoresizingMaskIntoConstraints = false

        timeField.stringValue = EventTimeParser.format(lastValidTime)
        timeField.placeholderString = ScheduleText.eventTimePlaceholder
        timeField.delegate = self
        timeField.target = self
        timeField.action = #selector(valueChanged)
        timeField.alignment = .left
        timeField.translatesAutoresizingMaskIntoConstraints = false
        timeField.widthAnchor.constraint(equalToConstant: Layout.timeFieldWidth).isActive = true

        addArrangedSubview(dayPicker)
        addArrangedSubview(timeField)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Editing

    @objc private func valueChanged() {
        normaliseTimeText()
        guard let action = changeAction else { return }
        NSApp.sendAction(action, to: changeTarget, from: self)
    }

    /// Re-render the field from whatever was understood. Good input is tidied to the canonical
    /// spelling ("730" -> "7:30 am"); input that means nothing snaps back to the last good time, so
    /// the field always shows exactly the time that will be saved.
    private func normaliseTimeText() {
        if let typed = EventTimeParser.parse(timeField.stringValue) { lastValidTime = typed }
        timeField.stringValue = EventTimeParser.format(lastValidTime)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard (obj.object as? NSTextField) === timeField else { return }
        valueChanged()
    }
}
