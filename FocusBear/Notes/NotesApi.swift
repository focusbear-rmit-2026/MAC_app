//
//  NotesApi.swift
//  Focus Bear
//
//  Notes / brain dump API calls. These mirror the web dashboard's `store/reducer/note/extra.ts`
//  (getNotes, searchNotes, getUserNoteTags, createOrUpdateNote, deleteNote) against the backend
//  `NoteController`, so the native Notes view and the web app share one source of truth.
//

import Foundation

/// Backend note endpoints (web: `Endpoints.NOTE`).
enum NotesEndpoint {
    static let base = "/note"
    static let tags = "/note/tags"
    static let search = "/note/search"
}

/// Paging constants shared with the web (`PAGE.TAKE`, `searchNotes` default `take`).
enum NotesPaging {
    static let pageSize = 10
    static let firstPage = 1
    static let searchTake = 20
    /// One-off scan size used to find the brain-dump note when it has fallen off the first page
    /// (`GET /note` orders by created_at, and the brain dump is usually old). Backend max take is 50.
    static let brainDumpScanTake = 50
}

extension AllApi {

    /// `GET /note?page=&take=&order=DESC[&tag_id=]` — one page of the user's notes, newest first,
    /// optionally only those carrying `tagId`.
    func getNotes(page: Int, take: Int, tagId: String? = nil, completionHandler: @escaping (_ page: NotesPage?) -> ()) {
        var path = "\(NotesEndpoint.base)?page=\(page)&take=\(take)&order=DESC"
        if let tagId = tagId, !tagId.isEmpty {
            path += "&tag_id=\(tagId)"
        }
        performNotesRequest(path: path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeNotes(NotesPage.self, from: data, statusCode: statusCode, call: "getNotes"))
        }
    }

    /// `GET /note/search?query=&take=` — plain array of matching notes.
    func searchNotes(query: String, take: Int, completionHandler: @escaping (_ notes: [Note]?) -> ()) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let path = "\(NotesEndpoint.search)?query=\(encoded)&take=\(take)"
        performNotesRequest(path: path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeNotes([Note].self, from: data, statusCode: statusCode, call: "searchNotes"))
        }
    }

    /// `GET /note/tags` — every tag the user has used on a note.
    func getNoteTags(completionHandler: @escaping (_ tags: [NoteTag]?) -> ()) {
        performNotesRequest(path: NotesEndpoint.tags, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeNotes([NoteTag].self, from: data, statusCode: statusCode, call: "getNoteTags"))
        }
    }

    /// `PUT /note` — create (no id) or update (id) a note. Returns the saved note and the HTTP status.
    func upsertNote(_ payload: NoteUpsertPayload, completionHandler: @escaping (_ note: Note?, _ statusCode: Int) -> ()) {
        let body = try? JSONEncoder().encode(payload)
        performNotesRequest(path: NotesEndpoint.base, method: "PUT", body: body) { data, statusCode in
            completionHandler(AllApi.decodeNotes(Note.self, from: data, statusCode: statusCode, call: "upsertNote"), statusCode)
        }
    }

    /// `DELETE /note?note_id=` — succeeds with an empty 200 body.
    func deleteNote(id: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let path = "\(NotesEndpoint.base)?note_id=\(id)"
        performNotesRequest(path: path, method: "DELETE", body: nil) { _, statusCode in
            completionHandler(statusCode == 200)
        }
    }

    /// Shared plumbing: refresh the Auth0 credential (like every other call in AllApi), attach the
    /// bearer token via `makeRequest`, run the request and hand back `(data, statusCode)` — `statusCode`
    /// is 0 when the request never reached the server. Non-2xx bodies are logged via `writeJsonInLog`
    /// so validation errors are visible in the app log.
    private func performNotesRequest(path: String, method: String, body: Data?,
                                     completionHandler: @escaping (_ data: Data?, _ statusCode: Int) -> ()) {
        addLog(text: "func call:- api notes \(method) \(path)")
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil, let url = NSURL(string: "\(baseUrl)\(path)") else {
                completionHandler(nil, 0)
                return
            }
            let request = makeRequest(responsePathUrl: url)
            request.httpMethod = method
            if let body = body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    addLog(text: "api notes \(method) \(path) error:- \(error?.localizedDescription ?? "no response")")
                    completionHandler(nil, 0)
                    return
                }
                if httpResponse.statusCode != 200 {
                    addLog(text: "api notes \(method) \(path) Api error:- statusCode is \(httpResponse.statusCode)")
                    self.writeJsonInLog(data: data)
                }
                completionHandler(data, httpResponse.statusCode)
            }
            task.resume()
        }
    }

    private static func decodeNotes<T: Decodable>(_ type: T.Type, from data: Data?, statusCode: Int, call: String) -> T? {
        guard statusCode == 200, let data = data else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            addLog(text: "api notes \(call) decode error:- \(error)")
            return nil
        }
    }
}
