import SwiftUI

/// Reusable safety-policy detail. The block-list redesign can embed this without maintaining a
/// second copy of policy state or inferring school rules from a personal focus mode.
struct ManagedPolicyInspector: View {
    @ObservedObject var runtime: ManagedBlockingRuntime
    var onClose: (() -> Void)? = nil
    @SwiftUI.State private var showingHomeEditor = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label(text("safetyTitle", "Safety mode"), systemImage: "shield.lefthalf.fill")
                        .font(.title2)
                    Spacer()
                    SwiftUI.Button(text("refresh", "Refresh")) { runtime.refresh() }
                    if let close = onClose { SwiftUI.Button(text("close", "Close"), action: close) }
                }
                Text(text("safetyExplanation", "Your school and parent manage these website categories. Personal focus sessions can add more restrictions."))
                    .foregroundColor(.secondary)
                status
                if let snapshot = runtime.effectivePolicy {
                    if let school = snapshot.school { policyCard(school) }
                    if let home = snapshot.home { policyCard(home) }
                    if snapshot.school == nil && snapshot.home == nil {
                        Text(text("noManagedPolicy", "No school or home safety schedule is assigned."))
                    }
                } else {
                    Text(text("awaitingPolicy", "Waiting for your school and home schedules to sync."))
                }
                Text(text("browserScope", "Safety mode checks website addresses observed in supported browsers. Browser permissions are required."))
                    .font(.footnote).foregroundColor(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showingHomeEditor) {
            if let home = runtime.effectivePolicy?.home {
                ManagedHomePolicyEditor(runtime: runtime, policy: home)
            }
        }
        .environment(\.locale, ManagedPolicyPresentation.locale)
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            if runtime.syncState == .recovery {
                Label(text("recoveryStatus", "Reconnect to restore verified school controls. Settings stay locked; only essential recovery websites are available."), systemImage: "exclamationmark.shield")
                    .foregroundColor(.orange)
            } else if runtime.syncState == .loading {
                Label(text("checkingControls", "Checking school and parent controls…"), systemImage: "arrow.triangle.2.circlepath")
            } else if let policy = runtime.activePolicy {
                Label(text("activePolicy", "Active now: <POLICY>").replacingOccurrences(of: "<POLICY>", with: policy.name), systemImage: "clock.fill")
            } else {
                Label(text("noActivePolicy", "No school or home safety window is active now."), systemImage: "clock")
            }
            if runtime.syncState == .offline {
                Text(text("offlineStatus", "Offline: your saved school and home timetable still applies."))
                    .font(.footnote).foregroundColor(.secondary)
            }
            if runtime.isSettingsLocked {
                Label(text("settingsLocked", "Settings are locked. A parent must approve home schedule changes."), systemImage: "lock.fill")
            }
            if runtime.isSignedInAsWrongAccount {
                Text(text("accountMismatch", "This device is still supervised by its previous school account. Sign back in to that account to restore verified controls."))
                    .foregroundColor(.orange)
                SwiftUI.Button(text("returnToSupervisedSignIn", "Return to supervised sign-in")) { runtime.signOutWrongAccount() }
            }
            if let error = runtime.lastError { Text(error).foregroundColor(.orange) }
            if let synced = runtime.lastSyncedAt {
                HStack(spacing: 4) {
                    Text(text("lastSynced", "Last synced:"))
                    Text(synced, style: .date)
                    Text(synced, style: .time)
                }.font(.footnote).foregroundColor(.secondary)
            }
            if runtime.queuedViolationCount > 0 {
                Text(text("queuedReports", "<COUNT> blocked-attempt reports are waiting to sync.")
                    .replacingOccurrences(of: "<COUNT>", with: String(runtime.queuedViolationCount)))
                    .font(.footnote).foregroundColor(.secondary)
            }
            if runtime.rejectedViolationCount > 0 {
                Text(text("rejectedReports", "<COUNT> blocked-attempt reports could not be synced.")
                    .replacingOccurrences(of: "<COUNT>", with: String(runtime.rejectedViolationCount)))
                    .font(.footnote).foregroundColor(.orange)
            }
            if runtime.permissionStatus == "unknown" {
                Text(text("permissionUnknown", "Browser access has not been verified yet."))
                    .font(.footnote).foregroundColor(.secondary)
            } else if runtime.permissionStatus == "missing" {
                Text(text("permissionMissing", "Browser permissions are missing. School website blocking cannot run until permissions are restored."))
                    .font(.footnote).foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }

    private func policyCard(_ policy: ManagedPolicy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(policy.name).font(.headline)
                    Text(policy.kind == "school" ? text("schoolOwner", "Managed by your school") : text("homeOwner", "Managed by your parent"))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(policy.isEnabled ? (runtime.activePolicy?.id == policy.id ? text("active", "Active") : text("scheduled", "Scheduled")) : text("disabled", "Disabled"))
                    .font(.caption).padding(6)
                    .background(Color(NSColor.controlBackgroundColor)).cornerRadius(6)
            }
            Text(text("policyRevision", "Revision <REVISION> · <ZONE>")
                .replacingOccurrences(of: "<REVISION>", with: String(policy.revision))
                .replacingOccurrences(of: "<ZONE>", with: policy.timeZone))
                .font(.footnote).foregroundColor(.secondary)
            if policy.kind == "home" {
                Text(text("homePrecedence", "The home schedule applies only outside active school hours, including school holidays when a home window is scheduled."))
                    .font(.callout).foregroundColor(.secondary)
            }
            Divider()
            Text(text("blockedCategories", "Configured blocked categories")).font(.headline)
            if policy.blockedCategories.isEmpty {
                Text(text("noCategories", "No categories selected."))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ForEach(policy.blockedCategories.sorted(), id: \.self) { id in
                        Label(ManagedBlockingText.category(id), systemImage: "minus.circle")
                    }
                }
            }
            Text(text("coverageExplanation", "Available category sources can vary. Checks with missing coverage use the unavailable-result rule below."))
                .font(.footnote).foregroundColor(.secondary)
            if policy.blockedCategories.isEmpty {
                Text(text("emptyCategoriesAllow", "This policy allows websites until categories are selected. Its fallback rules are inactive."))
                    .font(.footnote).foregroundColor(.secondary)
            } else {
                fallbackRow(text("unknownRule", "Uncategorised websites"), blocks: policy.unknownAction == "block" || policy.blockedCategories.contains("unknown"))
                fallbackRow(text("unavailableRule", "Unavailable category checks"), blocks: policy.unavailableAction == "block" || policy.blockedCategories.contains("not_resolved"))
            }
            DisclosureGroup(text("schedule", "Weekly schedule")) {
                VStack(alignment: .leading, spacing: 8) {
                    if policy.windows.isEmpty { Text(text("noWindows", "No weekly windows are scheduled.")) }
                    ForEach(Array(policy.windows.enumerated()), id: \.offset) { _, window in
                        HStack(alignment: .top) {
                            Text(ManagedPolicyPresentation.days(window.daysOfWeek))
                            Spacer()
                            Text(window.allDay == true ? text("allDay", "All day") : "\(window.startTime)–\(window.endTime)")
                        }
                    }
                    Text(text("scheduleZone", "All times use <ZONE>. Overnight windows continue into the next day.")
                        .replacingOccurrences(of: "<ZONE>", with: policy.timeZone))
                        .font(.footnote).foregroundColor(.secondary)
                }.padding(.top, 8)
            }
            DisclosureGroup(text("exceptions", "Allowed website exceptions (<COUNT>)").replacingOccurrences(of: "<COUNT>", with: String(policy.allowlist.count))) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(text("exceptionScope", "These exceptions apply to this safety schedule. Other focus or teacher restrictions can still block a website."))
                        .font(.footnote).foregroundColor(.secondary)
                    ForEach(Array(policy.allowlist.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.url)
                            if entry.includeSubdomains { Text(text("includeSubdomains", "Includes subdomains")).font(.caption) }
                            if let reason = entry.reason, !reason.isEmpty { Text(reason).font(.caption).foregroundColor(.secondary) }
                            if let expiry = entry.expiresAt, let date = ManagedDate.parse(expiry) {
                                if date <= runtime.effectiveNow {
                                    Text(text("expiredException", "Expired exception")).font(.caption).foregroundColor(.orange)
                                }
                                HStack {
                                    Text(text("expires", "Expires:"))
                                    Text(date, style: .date)
                                    Text(date, style: .time)
                                }.font(.caption)
                            }
                        }
                    }
                }.padding(.top, 8)
            }
            DisclosureGroup(text("excludedDatesCount", "Dates when this schedule does not run (<COUNT>)").replacingOccurrences(of: "<COUNT>", with: String(policy.excludedDates.count))) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(text("inclusiveDates", "Both dates are included, in this schedule’s time zone."))
                        .font(.footnote).foregroundColor(.secondary)
                    ForEach(Array(policy.excludedDates.enumerated()), id: \.offset) { _, range in
                        Text(range.startDate == range.endDate ? range.startDate : "\(range.startDate) – \(range.endDate)")
                    }
                }.padding(.top, 8)
            }
            if policy.kind == "home" {
                SwiftUI.Button(text("requestHomeChanges", "Request parent-approved changes")) { showingHomeEditor = true }
            } else {
                Text(text("schoolChanges", "Contact your school to change this schedule or request a lasting website exception."))
                    .font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(NSColor.separatorColor)))
    }

    private func fallbackRow(_ title: String, blocks: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(blocks ? text("block", "Block") : text("allow", "Allow"))
        }.font(.callout)
    }

    private func text(_ key: String, _ fallback: String) -> String {
        ManagedBlockingText.value(key, fallback: fallback)
    }
}

enum ManagedPolicyPresentation {
    static var locale: Locale { Locale(identifier: currentLanguageCode.isEmpty ? "en" : currentLanguageCode) }

    static func days(_ values: [String]) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let labels = formatter.shortWeekdaySymbols ?? []
        return ManagedDay.ordered(values).compactMap { code in
            ManagedDay.index(of: code).flatMap { labels.indices.contains($0) ? labels[$0] : nil }
        }.joined(separator: ", ")
    }
}
