//
//  ToDoModels.swift
//  Focus Bear
//
//  Data model for the native To-do List / Projects screens. Mirrors the web dashboard's
//  `src/interfaces/common.interface.ts` (ToDoTask), `src/interfaces/project.interface.ts` (Project,
//  PortfolioProjectRisk) and the backend `CreateToDoDto` / `PortfolioResponseDto`, so the native
//  screens round-trip exactly what the web app reads and writes.
//

import Foundation

// MARK: - Enums shared with the web (`src/enums/todo.ts`, `src/enums/projects.ts`)

/// `TO_DO_STATUS`. A task's `status` may also be a free-form external/custom label, so callers
/// should go through `ToDoTask.defaultStatus`.
enum ToDoStatus: String, Codable, CaseIterable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
}

/// `SORT_MODE` — the `sort_mode` query param of `GET /to-do`.
enum ToDoSortMode: String, Codable, CaseIterable {
    case smart = "SMART"
    case chronological = "CHRONOLOGICAL"
    case dueDate = "DUE_DATE"
}

/// `EISENHOWER_QUADRANT` (the API field is the number 1…4).
enum EisenhowerQuadrant: Int, CaseIterable {
    case doIt = 1
    case decide = 2
    case delegate = 3
    case delete = 4
}

/// `PortfolioBucket` — computed server-side by `GET /portfolio`; never recomputed on device.
enum PortfolioBucket: String, Codable, CaseIterable {
    case onTrack = "on_track"
    case atRisk = "at_risk"
    case critical = "critical"
    case noDeadline = "no_deadline"
}

/// `PortfolioBadge`. `unscheduled` / `pushed_back` come from the backend's Day Plan simulation
/// (backend #2363); a badge this build doesn't know decodes to `.unknown` rather than failing the
/// whole portfolio, so a newer backend can add badges without breaking older Macs.
enum PortfolioBadge: String, Codable {
    case overcommitted
    case startNow = "start_now"
    case sacrifice
    case unscheduled
    case pushedBack = "pushed_back"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = PortfolioBadge(rawValue: raw) ?? .unknown
    }
}

/// `PortfolioImportance`.
enum PortfolioImportance: Int, Codable, CaseIterable {
    case low = 1, medium = 2, high = 3, critical = 4
}

/// `ProjectLifecycleStatus`. Absent on legacy payloads = active.
enum ProjectLifecycleStatus: String, Codable, CaseIterable {
    case active, completed, archived
}

/// `PortfolioActionSection` — the three "This week" groups of the web's "What matters" view.
enum PortfolioActionSection: String, CaseIterable {
    case askForExtension = "ask_for_extension"
    case startNow = "start_now"
    case backBurner = "back_burner"
}

// MARK: - Lenient decoding helpers

/// The API returns `duration` as a string ("300") for some rows and a number for others.
struct LenientInt: Codable, Equatable {
    var value: Int

    init(_ value: Int) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = Int(double)
        } else if let string = try? container.decode(String.self), let int = Int(string) ?? Double(string).map({ Int($0) }) {
            value = int
        } else {
            value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// A string the API is supposed to always send but sometimes doesn't: `GET /to-do?sort_mode=DUE_DATE`
/// has returned a completed row with no `title`, and `PUT /to-do` answers a create without
/// `created_at`. One such row must not fail the whole page, so the value decodes as "" when the key
/// is missing or null. Encodes as a plain string.
@propertyWrapper
struct DefaultEmpty: Codable, Equatable, Hashable {
    var wrappedValue: String

    init(wrappedValue: String) { self.wrappedValue = wrappedValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(String.self)) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

extension KeyedDecodingContainer {
    /// Lets the synthesised decoder tolerate an absent key for a `@DefaultEmpty` property.
    func decode(_ type: DefaultEmpty.Type, forKey key: Key) throws -> DefaultEmpty {
        try decodeIfPresent(type, forKey: key) ?? DefaultEmpty(wrappedValue: "")
    }
}

/// Decodes as nil instead of throwing, so a list can drop one malformed row and keep the rest.
struct LenientRow<Element: Decodable>: Decodable {
    let value: Element?

    init(from decoder: Decoder) throws {
        value = try? Element(from: decoder)
    }
}

// MARK: - To-do

/// `Tag` — `{ id, text }`. For a native project the tag id IS the project id.
struct ToDoTag: Codable, Equatable, Hashable {
    var id: String
    var text: String
}

/// `SubTask` — the backend's canonical `{ name, is_completed }` (an `id` may come back on old rows).
struct ToDoSubtask: Codable, Equatable {
    var id: String?
    var name: String
    var is_completed: Bool

    init(id: String? = nil, name: String, is_completed: Bool) {
        self.id = id
        self.name = name
        self.is_completed = is_completed
    }
}

/// `TaskAssignee` as returned inside `GET /to-do` rows (`{ id, username }`).
struct ToDoAssignee: Codable, Equatable {
    var id: String
    var username: String?
    var email: String?
}

/// `ToDoTask` (web `src/interfaces/common.interface.ts`) / backend `ToDoResponse`.
struct ToDoTask: Codable, Equatable, Identifiable {
    var id: String
    @DefaultEmpty var title: String
    var details: String?
    var objective: String?
    var status: String
    var due_date: String?
    @DefaultEmpty var created_at: String
    var updated_at: String?
    var eisenhower_quadrant: Int?
    var outcome: Int?
    var perspiration_level: Int?
    var top_score: Double?
    var duration: LenientInt?
    var icon: String?
    var tags: [ToDoTag]?
    var subtasks: [ToDoSubtask]?
    var project_id: String?
    var synced_project_id: String?
    var custom_status_id: String?
    var focus_type: String?
    var external_task_id: String?
    var external_task_status: String?
    var assignee_id: String?
    var assigned_mcp_token_id: String?
    var assignee: ToDoAssignee?
    var planned_date: String?
    var planned_block_key: String?
    var planned_order: Int?

    /// The default-status bucket this task belongs to. Unknown / external statuses count as "doing",
    /// like the web's `getEffectiveTaskStatus` fallback.
    var defaultStatus: ToDoStatus { ToDoStatus(rawValue: status) ?? .inProgress }
    var isCompleted: Bool { defaultStatus == .completed }
    var durationSeconds: Int { duration?.value ?? 0 }
    var quadrant: EisenhowerQuadrant { EisenhowerQuadrant(rawValue: eisenhower_quadrant ?? 1) ?? .doIt }
    var hasDetails: Bool { !(details ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var subtaskList: [ToDoSubtask] { subtasks ?? [] }
    var tagList: [ToDoTag] { tags ?? [] }

    /// Web `refineTaskTopMetrics`: outcome/perspiration clamped into 1…10 (defaults 1).
    var effectiveOutcome: Int { min(10, max(1, outcome ?? 1)) }
    var effectivePerspiration: Int { min(10, max(1, perspiration_level ?? 1)) }

    /// Web `resolveTaskIconEmoji`.
    var iconEmoji: String? { EmojiIcon.resolve(icon) }
}

/// Web `resolveTaskIconEmoji`: a stored `icon` is either an emoji glyph already ("📝") or the hex
/// unified code the web's emoji picker writes ("1f600", "1f1e6-1f1e8"), which has to be turned back
/// into scalars before it can be rendered. Tasks and projects both store icons this way.
/// One file attached to a task. The backend keeps the bytes in R2 and hands back a short-lived
/// `download_url`; `file_key` is the server's own path and is never built on the client.
struct ToDoAttachment: Codable, Identifiable, Equatable {
    let id: String
    var task_id: String?
    var file_name: String
    var file_key: String
    var content_type: String
    var file_size: Int
    var download_url: String?
    var created_at: String?

    /// 20 MB, matching the server's `MAX_ATTACHMENT_SIZE_BYTES`; it rejects anything larger.
    static let maximumBytes = 20 * 1024 * 1024
    /// 20 per task, matching the server's `MAX_TASK_ATTACHMENTS`.
    static let maximumPerTask = 20

    var isImage: Bool { content_type.lowercased().hasPrefix("image/") }
}

/// MIME types for the files a user can attach. The server stores whatever it is told and signs the
/// upload URL with it, so a wrong type would be baked into the object — worth naming explicitly
/// rather than guessing per call site.
enum ToDoAttachmentType {
    static let fallback = "application/octet-stream"
    private static let byExtension = [
        "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif",
        "heic": "image/heic", "webp": "image/webp", "tiff": "image/tiff", "bmp": "image/bmp",
        "pdf": "application/pdf", "txt": "text/plain",
    ]
    static let imageExtensions = ["png", "jpg", "jpeg", "gif", "heic", "webp", "tiff", "bmp"]
    /// The non-image files the picker offers — the ones the in-app preview can actually render.
    static let documentExtensions = ["pdf", "txt"]
    static let pdf = "application/pdf"
    private static let textPrefix = "text/"

    static func contentType(forExtension ext: String) -> String {
        byExtension[ext.lowercased()] ?? fallback
    }

    static func isPDF(_ contentType: String) -> Bool { contentType.lowercased().hasPrefix(pdf) }
    static func isText(_ contentType: String) -> Bool { contentType.lowercased().hasPrefix(textPrefix) }
}

/// "1.2 MB" for an attachment row.
enum ToDoAttachmentSize {
    static func label(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(max(0, bytes)))
    }
}

struct ToDoAttachmentUploadTicket: Codable {
    let uploadUrl: String
    let fileKey: String
}

/// Reads an icon back for display. `habit_icon` is stored as hyphen-joined hex codepoints
/// ("1f486-200d-2642-fe0f"); a project's `icon` is the literal character (see `ProjectIcon`). This
/// takes either, so both render. Nothing writes hex — an earlier `encode` that did was written on a
/// wrong reading of the server contract and is gone (report 2026-09-14_20-07-42, backend#2404).
enum EmojiIcon {
    private static let minHexDigits = 4
    private static let maxHexDigits = 6

    static func resolve(_ raw: String?) -> String? {
        guard let icon = raw?.trimmingCharacters(in: .whitespaces), !icon.isEmpty else { return nil }
        let parts = icon.lowercased().split(separator: "-")
        let looksLikeHex = parts.allSatisfy { part in
            part.count >= minHexDigits && part.count <= maxHexDigits && part.allSatisfy { $0.isHexDigit }
        }
        guard looksLikeHex else { return icon }
        var result = ""
        for part in parts {
            guard let value = UInt32(part, radix: 16), let scalar = Unicode.Scalar(value) else { return icon }
            result.unicodeScalars.append(scalar)
        }
        return result
    }
}

/// One page of `GET /to-do` (`PaginationDto<ToDoResponse>`).
struct ToDoPage: Decodable {
    struct Meta: Decodable {
        var page: Int?
        var take: Int?
        var itemCount: Int?
        var pageCount: Int?
        var hasNextPage: Bool?
        var hasPreviousPage: Bool?
        /// Present only when the server applied effective unfinished-task filtering before paging.
        var excludesCompleted: Bool?
    }
    var data: [ToDoTask]
    var meta: Meta?
    /// How many rows the server actually sent, undecodable ones included. `meta.itemCount` counts
    /// rows on the server and `data` counts rows we can render; this sits between them, so a caller
    /// can tell "not fetched yet" apart from "fetched but unrenderable".
    var receivedRowCount: Int

    private enum CodingKeys: String, CodingKey { case data, meta }

    /// A row the client can't read is dropped (and logged) rather than failing the page: the
    /// web's fetch would still render the others.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rows = try container.decode([LenientRow<ToDoTask>].self, forKey: .data)
        data = rows.compactMap { $0.value }
        meta = try container.decodeIfPresent(Meta.self, forKey: .meta)
        receivedRowCount = rows.count
        let dropped = rows.count - data.count
        if dropped > 0 { addLog(text: "api todo page dropped \(dropped) undecodable row(s)") }
    }
}

/// One task returned by `POST /to-do/convert-brain-dump` (`BraindumpTaskDto`). The backend sends
/// `estimated_time` (minutes); the web reads `estimated_duration_minutes` — accept both.
struct BrainDumpTask: Decodable, Identifiable, Equatable {
    var id = UUID().uuidString
    var task_name: String
    var estimatedMinutes: Int
    var subtasks: [String]
    var outcome: Int?
    var perspiration_level: Int?
    var due_date: String?

    enum CodingKeys: String, CodingKey {
        case task_name, estimated_time, estimated_duration_minutes, subtasks, outcome, perspiration_level, due_date
    }

    init(task_name: String, estimatedMinutes: Int, subtasks: [String], outcome: Int? = nil,
         perspiration_level: Int? = nil, due_date: String? = nil) {
        self.task_name = task_name
        self.estimatedMinutes = estimatedMinutes
        self.subtasks = subtasks
        self.outcome = outcome
        self.perspiration_level = perspiration_level
        self.due_date = due_date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        task_name = try container.decodeIfPresent(String.self, forKey: .task_name) ?? ""
        let minutes = (try? container.decodeIfPresent(LenientInt.self, forKey: .estimated_time))?.value
            ?? (try? container.decodeIfPresent(LenientInt.self, forKey: .estimated_duration_minutes))?.value
        estimatedMinutes = minutes ?? 0
        subtasks = try container.decodeIfPresent([String].self, forKey: .subtasks) ?? []
        outcome = try container.decodeIfPresent(Int.self, forKey: .outcome)
        perspiration_level = try container.decodeIfPresent(Int.self, forKey: .perspiration_level)
        due_date = try container.decodeIfPresent(String.self, forKey: .due_date)
    }
}

/// `POST /to-do/generate-subtasks` response.
struct GeneratedSubtasksResponse: Decodable {
    var subtasks: [String]
}

/// `TaskComment` (`GET /to-do/:id/comments` returns a `PaginationDto`).
struct ToDoComment: Codable, Equatable, Identifiable {
    struct Author: Codable, Equatable {
        var id: String?
        var username: String?
    }
    var id: String
    var task_id: String?
    var user_id: String?
    var content: String
    var user: Author?
    var created_at: String
    var updated_at: String?
    /// Loaded separately (`GET …/comments/:id/reactions`), like the web merges them.
    var reactions: [ToDoReaction]?

    var reactionList: [ToDoReaction] { reactions ?? [] }
}

struct ToDoCommentsPage: Decodable {
    var data: [ToDoComment]
}

/// `TaskReaction` / `CommentReaction`.
struct ToDoReaction: Codable, Equatable, Identifiable {
    var id: String
    var task_id: String?
    var comment_id: String?
    var user_id: String?
    var emoji: String
    var created_at: String?
}

/// `GET /saved-website` row (the Procrastinate drawer).
struct SavedWebsite: Codable, Equatable, Identifiable {
    var id: String
    var url: String
    var title: String?
    var note: String?
    var created_at: String?
}

// MARK: - Projects

/// `ProjectStatus` — a project's custom kanban column.
struct ProjectCustomStatus: Codable, Equatable, Identifiable {
    var id: String
    var label: String
    var color: String?
    var order: Int?
    var should_complete_task: Bool?
}

/// `ProjectMemberRole` / `ProjectMemberInvitationStatus`.
enum ProjectMemberRole: String, Codable, CaseIterable {
    case owner, admin, member
}

enum ProjectInvitationStatus: String, Codable {
    /// `failed` is the server's fourth state: the invitation row exists but the email send threw
    /// (`ProjectMemberInvitationStatus.FAILED`). Without it such a row fell into the `.declined`
    /// fallback below and read as "Declined" — exactly the case a resend is there to rescue.
    case pending, accepted, declined, failed
}

/// `ProjectMember`.
struct ProjectMember: Codable, Equatable, Identifiable {
    var id: String
    var user_id: String?
    var email: String?
    var role: String?
    var invitation_status: String?
    var invitation_sent_at: String?
    var invitation_responded_at: String?

    var memberRole: ProjectMemberRole? { ProjectMemberRole(rawValue: role ?? "") }
    var invitationStatus: ProjectInvitationStatus { ProjectInvitationStatus(rawValue: invitation_status ?? "") ?? .declined }
}

/// `ProjectNoteResponseDto` (`GET /projects/:id/notes`); `content` (ProseMirror JSON) only comes
/// back on the single-note response.
struct ProjectNote: Decodable, Equatable, Identifiable {
    var id: String
    var project_id: String?
    var created_by: String?
    var title: String
    var content: JSONValue?
    var created_at: String?
    var updated_at: String?
    /// When the note was filed away, or nil while it is active. Archived notes keep their content and
    /// collaborative document but leave the default list. Absent on payloads from an older API.
    var archived_at: String? = nil

    var isArchived: Bool { archived_at != nil }

    /// The note body flattened to plain text, paragraph breaks kept — for previews and search.
    var plainText: String { content.map { JSONValue.plainText($0) } ?? "" }
}

struct ProjectNotesPage: Decodable {
    var data: [ProjectNote]
}

/// Minimal JSON tree, used to read ProseMirror documents without modelling them.
indirect enum JSONValue: Decodable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(Double.self) { self = .number(value) }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: JSONValue].self)) }
    }

    /// Concatenates every `text` leaf; block nodes (paragraph, heading, list item…) end with a newline.
    static func plainText(_ value: JSONValue) -> String {
        var output = ""
        func walk(_ node: JSONValue) {
            switch node {
            case .object(let fields):
                if case .string(let text)? = fields["text"] { output += text }
                if case .array(let children)? = fields["content"] { children.forEach(walk) }
                if case .string(let type)? = fields["type"], ["paragraph", "heading", "blockquote", "codeBlock", "taskListEmbed"].contains(type) {
                    output += "\n"
                }
            case .array(let items): items.forEach(walk)
            default: break
            }
        }
        walk(value)
        return output.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// The task a project card offers as its NEXT one. Deliberately NOT decoded from the payload's
/// `top_priority_task` (which names completed tasks) — `PortfolioNextTask.pick` builds it from the
/// project's open to-dos instead, so `top_score` is always the locally computed TOP score.
struct ProjectTopPriorityTask: Codable, Equatable {
    var id: String
    var title: String
    var top_score: Double?
}

/// `Project` (`GET /projects`).
/// `projects.metadata` — the server's open jsonb bag (backend#2412). Only `tags` is modelled: it is
/// the one key the server validates, normalizes and indexes, and the only one this client writes.
///
/// Unknown keys are deliberately **not** decoded, and that is safe because nothing here ever re-sends
/// the whole bag: writes go through `ProjectDetailStore.tagsBody`, which sends `metadata.tags` alone,
/// and the server shallow-merges it (`jsonb ||`). A key another client owns therefore survives a tag
/// edit from the Mac — the failure mode that nulled `assigned_mcp_token_id` on every task save.
struct ProjectMetadata: Codable, Equatable {
    var tags: [String]?
}

struct Project: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var description: String?
    var owner_id: String?
    var custom_statuses: [ProjectCustomStatus]?
    var icon: String?
    var metadata: ProjectMetadata?
    var members: [ProjectMember]?
    var task_count: Int?
    var uncompleted_task_count: Int?
    var synced_project_id: String?
    var synced_platform: String?
    var due_date: String?
    var importance: Int?
    var outcome: Int?
    var status: String?
    var created_at: String?
    var updated_at: String?

    var lifecycleStatus: ProjectLifecycleStatus { ProjectLifecycleStatus(rawValue: status ?? "") ?? .active }
    /// The project's tags, as stored (already lower-cased by the server). Empty when it has none.
    var tagList: [String] { metadata?.tags ?? [] }
    /// The project's emoji, decoded from whichever form the picker stored (see `EmojiIcon`).
    var iconEmoji: String? { EmojiIcon.resolve(icon) }
    var customStatuses: [ProjectCustomStatus] { custom_statuses ?? [] }
    var isSynced: Bool { !(synced_project_id ?? "").isEmpty }
    /// Web `projectUsesCustomStatuses`: native project with at least one custom column.
    var usesCustomStatuses: Bool { !isSynced && !customStatuses.isEmpty }
    var acceptedMembers: [ProjectMember] { (members ?? []).filter { $0.invitationStatus == .accepted } }
    /// Columns sorted by `order` (the web's toggle / list helpers sort; the kanban move uses array
    /// position — sorting once keeps the two consistent).
    var orderedStatuses: [ProjectCustomStatus] { customStatuses.sorted { ($0.order ?? 0) < ($1.order ?? 0) } }
    var importanceLevel: PortfolioImportance { PortfolioImportance(rawValue: importance ?? 2) ?? .medium }
}

/// `GetProjectsResponseDto` — `{ data, meta }` plus the deprecated `projects` / `total_count` aliases.
struct ProjectsPage: Decodable {
    var data: [Project]?
    var projects: [Project]?
    var meta: ToDoPage.Meta?
    var total_count: Int?

    var items: [Project] {
        let fromData = data ?? []
        let fromAlias = projects ?? []
        return fromAlias.count > fromData.count ? fromAlias : fromData
    }
    var hasNextPage: Bool { meta?.hasNextPage ?? false }
    var totalCount: Int { total_count ?? meta?.itemCount ?? items.count }
}

/// `PortfolioProjectRisk`. The payload's `top_priority_task` is ignored — see `PortfolioNextTask`.
struct PortfolioProject: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var due_date: String?
    var importance: Int?
    var outcome: Int?
    var required_hours: Double?
    var risk_score: Double?
    var bucket: String
    var deficit_hours: Double?
    var days_until_due: Int?
    var latest_start: String?
    var badges: [String]?
    // Day Plan simulation fields (backend #2363) — all optional so older backends still decode.
    var scheduled_hours: Double?
    var unscheduled_hours: Double?
    var projected_completion_date: String?
    var plan_feasible: Bool?
    var pushed_task_ids: [String]?

    var portfolioBucket: PortfolioBucket { PortfolioBucket(rawValue: bucket) ?? .noDeadline }
    var badgeList: [PortfolioBadge] { (badges ?? []).map { PortfolioBadge(rawValue: $0) ?? .unknown } }
    var importanceLevel: PortfolioImportance { PortfolioImportance(rawValue: importance ?? 2) ?? .medium }
    var riskScore: Double { risk_score ?? 0 }
    var requiredHours: Double { required_hours ?? 0 }
    var hasDueDate: Bool { !(due_date ?? "").isEmpty }
    var isOverdue: Bool { (days_until_due ?? 0) < 0 && days_until_due != nil }
    /// The backend simulated the Day Plan for this project (the "Scheduled X of Y" line has data).
    var hasScheduleBreakdown: Bool { scheduled_hours != nil && requiredHours > 0 }
    /// Remaining work with no task planned in the horizon.
    var isUnscheduled: Bool { badgeList.contains(.unscheduled) }
}

/// One entry of `PortfolioResponse.pushed_tasks`: a to-do the simulation could not fit on its
/// planned day; `projected_date` is the day it would actually complete.
struct PortfolioPushedTask: Codable, Equatable {
    var id: String
    var project_id: String?
    var planned_date: String?
    var projected_date: String?
}

/// `PortfolioResponse` (`GET /portfolio`).
struct PortfolioResponse: Codable, Equatable {
    var projects: [PortfolioProject]
    var due_this_week: [String]?
    var start_now: [String]?
    var overcommitted: Bool?
    var total_required_hours: Double?
    var total_available_hours: Double?
    var plan_feasible: Bool?
    var pushed_tasks: [PortfolioPushedTask]?

    var isOvercommitted: Bool { overcommitted == true }
    var pushedTasks: [PortfolioPushedTask] { pushed_tasks ?? [] }
}

/// `PortfolioSettings` (`GET/PUT /portfolio/settings`). Index 0 = Monday.
struct PortfolioSettings: Codable, Equatable {
    var weekly_capacity_hours: [Double]
    var planning_horizon_days: Int

    static let daysPerWeek = 7
    static let horizonOptions = [7, 14, 28, 60, 90]
    /// Backend default when the user never saved capacity settings (also used when the fetch fails).
    static let defaultHorizonDays = 14
}

/// Body of `PUT /portfolio/busy-hours`: hours already taken by calendar events the backend can't
/// see (the Mac's EventKit calendars), per local day. The backend merges sources with `max`.
struct BusyHoursReport: Codable, Equatable {
    /// Identifies this device's calendars server-side; one row per (user, source).
    static let macEventKitSource = "mac-eventkit"

    var source: String
    var days: [String: Double]
}
