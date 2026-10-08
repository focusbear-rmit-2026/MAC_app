//
//  NoteModels.swift
//  Focus Bear
//
//  Data model for the notes / brain dump feature. Mirrors the web dashboard's
//  `src/interfaces/note.interface.ts` and the backend `NoteResponseDto` so the native Notes view
//  round-trips exactly what the web app reads and writes.
//

import Foundation

struct NoteTag: Codable, Equatable {
    /// Empty for a tag the user just typed and hasn't saved yet (the backend assigns the id on upsert).
    var id: String
    var text: String
    var color: String?

    /// Stable identity for SwiftUI lists: unsaved tags have no id, so fall back to the text.
    var listIdentity: String { id.isEmpty ? text : id }
}

struct Note: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var body: String?
    var completed_activity_id: String?
    var tags: [NoteTag]?
    var embedded_todo_ids: [String]?
    var activity_name: String?
    var activity_emoji: String?
    var logged_at: String?
    var created_at: String
    var updated_at: String
    var is_brain_dump: Bool?

    var isBrainDump: Bool { is_brain_dump == true }
    /// The web list shows `logged_at ?? created_at`.
    var displayDateString: String { logged_at ?? created_at }
}

/// One page of `GET /note` (`PaginationDto<NoteResponseDto>`: `{ data, meta: { hasNextPage, … } }`).
struct NotesPage: Decodable {
    struct Meta: Decodable {
        var hasNextPage: Bool?
        var hasPreviousPage: Bool?
    }
    var data: [Note]
    var meta: Meta?
}

/// Tag as sent to `PUT /note` (`CreateNoteTagDto`). The web sends `{ text, color }` only; an `id` is
/// optional and lets the backend reuse an existing tag instead of `findOrCreate`-ing by text.
struct NoteTagPayload: Encodable {
    var id: String?
    var text: String
    var color: String?
}

/// Body of `PUT /note` (`CreateNoteDto`). Optional fields are omitted from the JSON when nil — the
/// backend only touches a field when its key is present (`hasDtoProperty`), so an update that omits
/// `tags` keeps the existing tags.
struct NoteUpsertPayload: Encodable {
    var id: String?
    var title: String
    var body: String?
    var tags: [NoteTagPayload]?
    var completed_activity_id: String?
    var is_brain_dump: Bool?
}
