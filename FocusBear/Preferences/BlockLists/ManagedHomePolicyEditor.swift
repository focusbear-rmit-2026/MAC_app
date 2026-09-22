import SwiftUI
import Combine

struct ManagedHomePolicyEditor: View {
    @ObservedObject var runtime: ManagedBlockingRuntime
    @Environment(\.presentationMode) private var presentation
    @SwiftUI.State private var draft: ManagedHomeDraft
    private let pollTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    init(runtime: ManagedBlockingRuntime, policy: ManagedPolicy) {
        self.runtime = runtime
        _draft = SwiftUI.State(initialValue: ManagedHomeDraft(policy))
    }

    private var canEdit: Bool {
        runtime.canProposeHomeChanges && runtime.effectivePolicy?.home?.id == draft.policyId &&
            runtime.effectivePolicy?.home?.revision == draft.baseRevision
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(text("homeChangesTitle", "Parent-approved home changes")).font(.title2)
                Spacer()
                SwiftUI.Button(text("close", "Close")) { presentation.wrappedValue.dismiss() }
            }
            Text(text("exactApproval", "A parent first approves an editing request, then reviews the exact changes. Your running schedule changes only after their final approval."))
                .foregroundColor(.secondary)
            requestStatus
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    generalFields
                    windowFields
                    categoryFields
                    allowlistFields
                    excludedDateFields
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
            }
            .disabled(!canEdit || runtime.isRequestBusy)
            if let key = draft.validationKey {
                Text(ManagedBlockingText.value(key, fallback: validationFallback(key)))
                    .foregroundColor(.red).font(.callout)
            }
            if let error = runtime.lastError { Text(error).foregroundColor(.orange).font(.callout) }
            HStack {
                Text(text("parentNotice", "All accepted parent managers receive an email after a parent commits the change."))
                    .font(.footnote).foregroundColor(.secondary)
                Spacer()
                SwiftUI.Button(text("submitProposal", "Send exact changes for approval")) {
                    guard canEdit, draft.validationKey == nil, draft.hasChanges else { return }
                    runtime.proposeSettingsChanges(draft.changes)
                }
                .disabled(!canEdit || runtime.isRequestBusy || draft.validationKey != nil || !draft.hasChanges)
            }
        }
        .padding(20)
        .frame(minWidth: 580, idealWidth: 660, maxWidth: 800, minHeight: 480, idealHeight: 640, maxHeight: 780)
        .onAppear { runtime.pollSettingsRequest() }
        .onReceive(pollTimer) { _ in runtime.pollSettingsRequest() }
        .environment(\.locale, ManagedPolicyPresentation.locale)
    }

    private var requestStatus: some View {
        VStack(alignment: .leading, spacing: 8) {
            if runtime.effectivePolicy?.home?.revision != draft.baseRevision {
                Text(text("draftStale", "The home schedule has changed. Close this editor and reopen it to review the latest revision."))
                    .foregroundColor(.orange)
            } else if let request = runtime.currentRequest {
                Text(requestMessage(request.status, canEdit: canEdit))
                if let expiry = ManagedDate.parse(request.expiresAt), ["pending", "approved", "proposed"].contains(request.status) {
                    HStack {
                        Text(text("requestExpires", "Request expires:"))
                        Text(expiry, style: .time)
                    }.font(.footnote).foregroundColor(.secondary)
                }
                if ["rejected", "expired", "committed"].contains(request.status) ||
                    (ManagedDate.parse(request.expiresAt).map { $0 <= runtime.effectiveNow } ?? true) {
                    requestButton
                }
            } else {
                Text(text("requestBeforeEditing", "Ask a parent to approve editing this device’s home schedule."))
                requestButton
            }
            Text(text("parentApprovalLocation", "Your parent can review the request in the Focus Bear dashboard’s approval inbox."))
                .font(.footnote).foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    private var requestButton: some View {
        SwiftUI.Button(text("requestApproval", "Request parent approval")) {
            runtime.requestSettingsEdit(scope: ManagedPolicyChanges.editableFields)
        }.disabled(runtime.isRequestBusy || runtime.effectivePolicy?.home?.revision != draft.baseRevision)
    }

    private var generalFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text("homeSchedule", "Home schedule")).font(.headline)
            TextField(text("policyName", "Schedule name"), text: $draft.name)
            TextField(text("timeZone", "IANA time zone (for example, Australia/Melbourne)"), text: $draft.timeZone)
            Toggle(text("enableSchedule", "Enable this home schedule"), isOn: $draft.isEnabled)
            Text(text("homePrecedence", "The home schedule applies only outside active school hours, including school holidays when a home window is scheduled."))
                .font(.footnote).foregroundColor(.secondary)
        }
    }

    private var windowFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text("schedule", "Weekly schedule")).font(.headline)
            ForEach(draft.windows) { row in
                windowEditor(binding(\.windows, row: row), id: row.id)
            }
            SwiftUI.Button(text("addWindow", "Add time window")) {
                draft.windows.append(ManagedEditorRow(value: ManagedWindow(daysOfWeek: ["MON", "TUE", "WED", "THU", "FRI"], startTime: "16:00", endTime: "20:00", allDay: false)))
            }.disabled(draft.windows.count >= 28)
            Text(text("windowHint", "Use 24-hour HH:mm times. An end time before the start continues into the next day."))
                .font(.footnote).foregroundColor(.secondary)
        }
    }

    private func windowEditor(_ value: Binding<ManagedWindow>, id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(ManagedDay.codes, id: \.self) { day in
                    Toggle(ManagedPolicyPresentation.days([day]), isOn: Binding(get: {
                        value.wrappedValue.daysOfWeek.contains(day)
                    }, set: { enabled in
                        var days = Set(value.wrappedValue.daysOfWeek)
                        if enabled { days.insert(day) } else { days.remove(day) }
                        value.wrappedValue.daysOfWeek = ManagedDay.ordered(Array(days))
                    })).toggleStyle(CheckboxToggleStyle())
                }
            }
            HStack {
                Toggle(text("allDay", "All day"), isOn: Binding(get: { value.wrappedValue.allDay == true }, set: { value.wrappedValue.allDay = $0 }))
                TextField(text("startTime", "Start (HH:mm)"), text: value.startTime).frame(maxWidth: 130)
                    .disabled(value.wrappedValue.allDay == true)
                TextField(text("endTime", "End (HH:mm)"), text: value.endTime).frame(maxWidth: 130)
                    .disabled(value.wrappedValue.allDay == true)
                Spacer()
                SwiftUI.Button(text("remove", "Remove")) { draft.windows.removeAll { $0.id == id } }
            }
        }.padding(10).background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
    }

    private var categoryFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text("blockedCategories", "Configured blocked categories")).font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), alignment: .leading)], alignment: .leading, spacing: 8) {
                ForEach(ManagedBlockingText.categoryLabels.keys.sorted(), id: \.self) { id in
                    Toggle(ManagedBlockingText.category(id), isOn: Binding(get: {
                        draft.blockedCategories.contains(id)
                    }, set: { selected in
                        if selected && !draft.blockedCategories.contains(id) { draft.blockedCategories.append(id) }
                        if !selected { draft.blockedCategories.removeAll { $0 == id } }
                    }))
                }
            }
            Text(text("coverageExplanation", "Available category sources can vary. Checks with missing coverage use the unavailable-result rule below."))
                .font(.footnote).foregroundColor(.secondary)
            Picker(text("unknownRule", "Uncategorised websites"), selection: $draft.unknownAction) {
                Text(text("allow", "Allow")).tag("allow")
                Text(text("block", "Block")).tag("block")
            }
            Picker(text("unavailableRule", "Unavailable category checks"), selection: $draft.unavailableAction) {
                Text(text("allow", "Allow")).tag("allow")
                Text(text("block", "Block")).tag("block")
            }
            Text(text("fallbackCategoryPrecedence", "Selecting Unknown or Not-Resolved blocks that result even if its fallback is Allow. With no selected categories, this policy allows websites."))
                .font(.footnote).foregroundColor(.secondary)
        }
    }

    private var allowlistFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text("allowedWebsites", "Allowed website exceptions")).font(.headline)
            Text(text("allowlistHint", "Enter a host or HTTP(S) address with an optional path. Queries and fragments are not allowed. Exceptions affect only this home schedule."))
                .font(.footnote).foregroundColor(.secondary)
            ForEach(draft.allowlist) { row in exceptionEditor(binding(\.allowlist, row: row), id: row.id) }
            SwiftUI.Button(text("addException", "Add website exception")) {
                draft.allowlist.append(ManagedEditorRow(value: ManagedException(url: "", includeSubdomains: false, reason: nil, expiresAt: nil)))
            }.disabled(draft.allowlist.count >= 250)
        }
    }

    private func exceptionEditor(_ value: Binding<ManagedException>, id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(text("websiteAddress", "Website address"), text: value.url)
            Toggle(text("includeSubdomains", "Includes subdomains"), isOn: value.includeSubdomains)
            TextField(text("exceptionReason", "Reason (optional)"), text: optionalText(value.reason))
            TextField(text("exceptionExpiry", "Expiry (optional ISO date and time, with Z or time-zone offset)"), text: optionalText(value.expiresAt))
            HStack {
                Spacer()
                SwiftUI.Button(text("remove", "Remove")) { draft.allowlist.removeAll { $0.id == id } }
            }
        }.padding(10).background(Color(NSColor.controlBackgroundColor)).cornerRadius(8)
    }

    private var excludedDateFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text("holidayDates", "Dates when this schedule does not run")).font(.headline)
            Text(text("inclusiveDates", "Both dates are included, in this schedule’s time zone."))
                .font(.footnote).foregroundColor(.secondary)
            ForEach(draft.excludedDates) { row in
                dateEditor(binding(\.excludedDates, row: row), id: row.id)
            }
            SwiftUI.Button(text("addExcludedDate", "Add excluded date range")) {
                draft.excludedDates.append(ManagedEditorRow(value: ManagedExcludedDates(startDate: "", endDate: "")))
            }.disabled(draft.excludedDates.count >= 120)
        }
    }

    private func dateEditor(_ value: Binding<ManagedExcludedDates>, id: UUID) -> some View {
        HStack {
            TextField(text("startDate", "Start date (YYYY-MM-DD)"), text: value.startDate)
            TextField(text("endDate", "End date (YYYY-MM-DD)"), text: value.endDate)
            SwiftUI.Button(text("remove", "Remove")) { draft.excludedDates.removeAll { $0.id == id } }
        }
    }

    /// Stable row identity prevents an old text-field callback writing into the next row after
    /// removal. Bindings for removed rows become inert instead of indexing a changed array.
    private func binding<Value>(_ path: WritableKeyPath<ManagedHomeDraft, [ManagedEditorRow<Value>]>, row: ManagedEditorRow<Value>) -> Binding<Value> {
        Binding(get: {
            draft[keyPath: path].first { $0.id == row.id }?.value ?? row.value
        }, set: { value in
            guard canEdit, let index = draft[keyPath: path].firstIndex(where: { $0.id == row.id }) else { return }
            draft[keyPath: path][index].value = value
        })
    }

    private func optionalText(_ value: Binding<String?>) -> Binding<String> {
        Binding(get: { value.wrappedValue ?? "" }, set: { value.wrappedValue = $0.isEmpty ? nil : $0 })
    }

    private func requestMessage(_ status: String, canEdit: Bool) -> String {
        switch status {
        case "pending": return text("requestPending", "Waiting for your parent to approve this editing request.")
        case "approved": return canEdit ? text("requestApproved", "Editing approved. Prepare changes for your parent to review.") : text("requestNotUsable", "Editing is locked. This approval is expired, offline, or no longer matches this device and schedule.")
        case "proposed": return text("requestProposed", "Changes sent. Waiting for your parent’s final approval; the current schedule still applies.")
        case "committed": return text("requestCommitted", "Your parent approved the changes. Refresh to see the updated schedule.")
        case "rejected": return text("requestRejected", "Your parent declined this request. The current schedule still applies.")
        default: return text("requestNotUsable", "Editing is locked. This approval is expired, offline, or no longer matches this device and schedule.")
        }
    }

    private func validationFallback(_ key: String) -> String {
        switch key {
        case "invalidName": return "Enter a schedule name with 1–120 characters."
        case "invalidZone": return "Enter a valid IANA time zone."
        case "invalidWindow": return "Choose days and valid HH:mm start/end times for each window. Equal times require All day."
        case "invalidCategories": return "Choose categories supported by this app’s registry."
        case "invalidFallback": return "Choose Allow or Block for both fallback rules."
        case "invalidException": return "Check exception addresses, reasons and expiry times. URLs must not include credentials, queries or fragments."
        default: return "Enter valid YYYY-MM-DD dates; the end must be on or after the start."
        }
    }

    private func text(_ key: String, _ fallback: String) -> String {
        ManagedBlockingText.value(key, fallback: fallback)
    }
}
