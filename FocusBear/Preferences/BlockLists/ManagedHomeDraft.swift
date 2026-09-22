import Foundation

struct ManagedEditorRow<Value>: Identifiable {
    let id = UUID()
    var value: Value
}

/// A draft is separate from the enforced snapshot. Only the server's exact-diff parent commit
/// can update a policy; preparing or closing this editor never changes running restrictions.
struct ManagedHomeDraft {
    let policyId: String
    let baseRevision: Int
    let original: ManagedPolicyChanges
    var name: String
    var timeZone: String
    var isEnabled: Bool
    var blockedCategories: [String]
    var unknownAction: String
    var unavailableAction: String
    var windows: [ManagedEditorRow<ManagedWindow>]
    var allowlist: [ManagedEditorRow<ManagedException>]
    var excludedDates: [ManagedEditorRow<ManagedExcludedDates>]

    init(_ policy: ManagedPolicy) {
        policyId = policy.id
        baseRevision = policy.revision
        original = policy.changes
        name = policy.name
        timeZone = policy.timeZone
        isEnabled = policy.isEnabled
        blockedCategories = policy.blockedCategories
        unknownAction = policy.unknownAction
        unavailableAction = policy.unavailableAction
        windows = policy.windows.map { ManagedEditorRow(value: $0) }
        allowlist = policy.allowlist.map { ManagedEditorRow(value: $0) }
        excludedDates = policy.excludedDates.map { ManagedEditorRow(value: $0) }
    }

    var changes: ManagedPolicyChanges {
        ManagedPolicyChanges(name: name, timeZone: timeZone, isEnabled: isEnabled,
            windows: windows.map(\.value), blockedCategories: blockedCategories,
            allowlist: allowlist.map(\.value), excludedDates: excludedDates.map(\.value),
            unknownAction: unknownAction, unavailableAction: unavailableAction)
    }

    var hasChanges: Bool { changes != original }

    /// Early feedback only. The backend revalidates scope, grant, revision and every field.
    var validationKey: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.count > 120 { return "invalidName" }
        if timeZone.count > 80 || TimeZone(identifier: timeZone) == nil { return "invalidZone" }
        let validTime = #"^([01]\d|2[0-3]):[0-5]\d$"#
        if windows.count > 28 || windows.contains(where: { row in
            let window = row.value
            return window.daysOfWeek.isEmpty || Set(window.daysOfWeek).count != window.daysOfWeek.count ||
                window.daysOfWeek.contains { !ManagedDay.isValid($0) } ||
                window.startTime.range(of: validTime, options: .regularExpression) == nil ||
                window.endTime.range(of: validTime, options: .regularExpression) == nil ||
                (window.allDay != true && window.startTime == window.endTime)
        }) { return "invalidWindow" }
        if blockedCategories.count > 39 || Set(blockedCategories).count != blockedCategories.count ||
            blockedCategories.contains(where: { ManagedBlockingText.categoryLabels[$0] == nil }) { return "invalidCategories" }
        if !["allow", "block"].contains(unknownAction) || !["allow", "block"].contains(unavailableAction) { return "invalidFallback" }
        if allowlist.count > 250 || allowlist.contains(where: { row in
            let entry = row.value
            guard let resource = ManagedResource(entry.url) else { return true }
            if entry.url.contains("?") || entry.url.contains("#") || (entry.reason?.count ?? 0) > 500 { return true }
            if let expiry = entry.expiresAt, ManagedDate.parse(expiry) == nil { return true }
            // The server also rejects subdomain matching on IP literals. Avoid coercing this
            // flag or changing an existing exception while preparing a different field.
            if entry.includeSubdomains && (resource.host.contains(":") || isIPv4(resource.host)) { return true }
            return false
        }) { return "invalidException" }
        if excludedDates.count > 120 || excludedDates.contains(where: { row in
            !Self.isCalendarDate(row.value.startDate) || !Self.isCalendarDate(row.value.endDate) || row.value.startDate > row.value.endDate
        }) { return "invalidDates" }
        return nil
    }

    private func isIPv4(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts.allSatisfy { Int($0).map { (0...255).contains($0) } ?? false }
    }

    private static func isCalendarDate(_ value: String) -> Bool {
        guard value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil else { return false }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value).map { formatter.string(from: $0) == value } ?? false
    }
}
