//
//  ToDoApi.swift
//  Focus Bear
//
//  To-do / project / portfolio API calls for the native To-do List screen. These mirror the web
//  dashboard's `store/reducer/to-do/extra.ts`, `store/reducer/project/extra.ts` and
//  `store/reducer/portfolio/extra.ts` against the backend `TodoController`, `ProjectController` and
//  `PortfolioController`, so the native screen and the web app share one source of truth.
//
//  The older NSDictionary-based helpers in AllApi (`getSmartTasks`, `addTask`, `getProjectsList`) are
//  left for their existing Day Plan callers; everything here is typed.
//

import Foundation

/// Backend endpoints (web `Endpoints.*`).
enum ToDoEndpoint {
    static let toDo = "/to-do"
    static let search = "/to-do/search"
    static let convertBrainDump = "/to-do/convert-brain-dump"
    static let generateSubtasks = "/to-do/generate-subtasks"
    static func comments(taskId: String) -> String { "/to-do/\(taskId)/comments" }
    static func comment(taskId: String, commentId: String) -> String { "/to-do/\(taskId)/comments/\(commentId)" }
    static func reactions(taskId: String) -> String { "/to-do/\(taskId)/reactions" }
    static func attachments(taskId: String) -> String { "/to-do/\(taskId)/attachments" }
    static func attachmentUploadUrl(taskId: String) -> String { "/to-do/\(taskId)/attachments/generate-upload-url" }
    static func attachment(taskId: String, attachmentId: String) -> String { "/to-do/\(taskId)/attachments/\(attachmentId)" }
    static func commentReactions(taskId: String, commentId: String) -> String { "/to-do/\(taskId)/comments/\(commentId)/reactions" }
    static let savedWebsite = "/saved-website"
    static let savedWebsiteBulkDelete = "/saved-website/delete"
    static let projects = "/projects"
    static func project(id: String) -> String { "/projects/\(id)" }
    static func projectTodos(id: String) -> String { "/projects/\(id)/todos" }
    static func projectMembers(id: String) -> String { "/projects/\(id)/members" }
    static func projectMember(id: String, memberId: String) -> String { "/projects/\(id)/members/\(memberId)" }
    static func leaveProject(id: String) -> String { "/projects/\(id)/members/leave" }
    static func projectNotes(id: String) -> String { "/projects/\(id)/notes" }
    static func projectNote(id: String, noteId: String) -> String { "/projects/\(id)/notes/\(noteId)" }
    static let pendingInvitations = "/projects/invitations/pending"
    static func acceptInvitation(projectId: String) -> String { "/projects/\(projectId)/members/accept" }
    static func declineInvitation(projectId: String) -> String { "/projects/\(projectId)/members/decline" }
    static let portfolio = "/portfolio"
    static let portfolioSettings = "/portfolio/settings"
    static let portfolioBusyHours = "/portfolio/busy-hours"
    /// `UserController`: the declared IANA timezone the busy-hours day keys are validated against.
    static let userTimezone = "/user/timezone"
}

/// Paging constants shared with the web (`DEFAULT_TASKS_PER_PAGE`, `EXPORT_TASKS`, `DEFAULT_PROJECTS_PARAMS`).
enum ToDoPaging {
    static let firstPage = 1
    /// `GET /to-do` rejects take > 50.
    static let tasksPerPage = 50
    static let exportMaxPages = 400
    /// `SearchToDosDto.take` max.
    static let searchTake = 20
    static let projectsPerPage = 9
    static let allProjectsTake = 50
    static let allProjectsMaxPages = 100
    /// Web `fetchProjectDetailsTasks` take.
    static let projectTasksTake = 20
    static let projectNotesTake = 20
}

/// Query for `GET /to-do` (web `getToDos` params).
struct ToDoListQuery {
    var page: Int
    var take: Int = ToDoPaging.tasksPerPage
    var status: ToDoStatus?
    var sortMode: ToDoSortMode = .smart
    var projectId: String?
    var syncedProjectId: String?
    var excludeCompleted = false

    /// Stable due-date/id ordering, with effective completion filtered on the server before paging.
    static func forecast(page: Int) -> ToDoListQuery {
        ToDoListQuery(page: page, sortMode: .dueDate, excludeCompleted: true)
    }

    var path: String {
        var items = ["page=\(page)", "take=\(take)", "order=DESC", "sort_mode=\(sortMode.rawValue)"]
        if let status = status { items.append("status=\(status.rawValue)") }
        if let projectId = projectId, !projectId.isEmpty { items.append("project_id=\(projectId)") }
        if let syncedProjectId = syncedProjectId, !syncedProjectId.isEmpty { items.append("synced_project_id=\(syncedProjectId)") }
        if excludeCompleted { items.append("exclude_completed=true") }
        return "\(ToDoEndpoint.toDo)?\(items.joined(separator: "&"))"
    }
}

extension AllApi {

    /// Raw task snapshots retain field presence and server metadata for guarded native edits.
    /// Keep the transport here so compatibility reads use the same captured-account credentials.
    func getTaskSnapshotData(path: String, expectedAccountID: String,
                             completion: @escaping (Data?, Int) -> Void) {
        performToDoRequest(path: path, method: "GET", body: nil,
                           expectedAccountID: expectedAccountID, completionHandler: completion)
    }

    // MARK: To-dos

    func getToDoPage(_ query: ToDoListQuery, completionHandler: @escaping (_ page: ToDoPage?) -> ()) {
        performToDoRequest(path: query.path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoPage.self, from: data, statusCode: statusCode, call: "getToDoPage"))
        }
    }

    /// `GET /to-do/search?title=&take=` — the backend ranks in memory (exact → prefix → word → substring)
    /// and ignores every other filter; the caller filters client-side like the web.
    func searchToDoTasks(title: String, completionHandler: @escaping (_ tasks: [ToDoTask]?) -> ()) {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?#"))) ?? title
        let path = "\(ToDoEndpoint.search)?title=\(encoded)&take=\(ToDoPaging.searchTake)"
        performToDoRequest(path: path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([ToDoTask].self, from: data, statusCode: statusCode, call: "searchToDoTasks"))
        }
    }

    /// `PUT /to-do` — the only to-do write endpoint (upsert: no id = create). Returns the saved task;
    /// on a non-2xx, the server's own reason (`ToDoServerError`) so the toast can show it.
    func upsertToDo(_ body: [String: Any], expectedAccountID: String? = nil,
                   completionHandler: @escaping (_ task: ToDoTask?, _ statusCode: Int, _ serverMessage: String?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: body)
        guard data != nil else { completionHandler(nil, 0, nil); return }
        performToDoRequest(path: ToDoEndpoint.toDo, method: "PUT", body: data, expectedAccountID: expectedAccountID) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoTask.self, from: data, statusCode: statusCode, call: "upsertToDo"), statusCode,
                              AllApi.toDoFailureMessage(data: data, statusCode: statusCode))
        }
    }

    /// `DELETE /to-do?todo_id=`.
    func deleteToDo(id: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: "\(ToDoEndpoint.toDo)?todo_id=\(id)", method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `POST /to-do/convert-brain-dump { contents }` — OpenAI turns free text into tasks.
    func convertBrainDumpToTasks(contents: String, timeout: TimeInterval, expectedAccountID: String? = nil,
                                 completionHandler: @escaping (_ tasks: [BrainDumpTask]?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["contents": contents])
        performToDoRequest(path: ToDoEndpoint.convertBrainDump, method: "POST", body: data, timeout: timeout, expectedAccountID: expectedAccountID) { data, statusCode in
            completionHandler(AllApi.decodeToDo([BrainDumpTask].self, from: data, statusCode: statusCode, call: "convertBrainDumpToTasks"))
        }
    }

    /// `POST /to-do/generate-subtasks { task, language }`.
    func generateSubtasks(task: String, completionHandler: @escaping (_ subtasks: [String]?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["task": task, "language": currentLanguageCode])
        performToDoRequest(path: ToDoEndpoint.generateSubtasks, method: "POST", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(GeneratedSubtasksResponse.self, from: data, statusCode: statusCode, call: "generateSubtasks")?.subtasks)
        }
    }

    /// Strict decoding for capacity: dropping one bad row would silently understate workload.
    struct ForecastTasksPage: Decodable {
        let data: [ToDoTask]
        let meta: ToDoPage.Meta
    }
    func getForecastTasksPage(page: Int, expectedAccountID: String? = nil, completion: @escaping (ForecastTasksPage?) -> Void) {
        let path = ToDoListQuery.forecast(page: page).path
        performToDoRequest(path: path, method: "GET", body: nil, expectedAccountID: expectedAccountID) { data, code in
            completion(AllApi.decodeToDo(ForecastTasksPage.self, from: data, statusCode: code, call: "getForecastTasksPage"))
        }
    }
    func getForecastTask(id: String, completion: @escaping (ToDoTask?) -> Void) {
        performToDoRequest(path: "\(ToDoEndpoint.toDo)/by-ids?ids=\(id)", method: "GET", body: nil) { data, code in
            let rows = AllApi.decodeToDo([ToDoTask].self, from: data, statusCode: code, call: "getForecastTask")
            completion(rows?.first { $0.id == id })
        }
    }

    // MARK: Comments / reactions

    func getToDoComments(taskId: String, completionHandler: @escaping (_ comments: [ToDoComment]?) -> ()) {
        performToDoRequest(path: "\(ToDoEndpoint.comments(taskId: taskId))?page=1&take=50", method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoCommentsPage.self, from: data, statusCode: statusCode, call: "getToDoComments")?.data)
        }
    }

    // MARK: Attachments
    //
    // Three steps, as the backend defines them: ask for a presigned URL, PUT the bytes straight to R2
    // (no Authorization header — the signature IS the auth), then record the attachment. The server
    // verifies the object exists and takes the real size from storage, so a lying `file_size` changes
    // nothing.

    func getTaskAttachments(taskId: String, completionHandler: @escaping (_ attachments: [ToDoAttachment]?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.attachments(taskId: taskId), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([ToDoAttachment].self, from: data, statusCode: statusCode,
                                                call: "getTaskAttachments"))
        }
    }

    func generateTaskAttachmentUpload(taskId: String, fileName: String, contentType: String,
                                      completionHandler: @escaping (_ ticket: ToDoAttachmentUploadTicket?) -> ()) {
        let body = try? JSONSerialization.data(withJSONObject: ["file_name": fileName, "content_type": contentType])
        performToDoRequest(path: ToDoEndpoint.attachmentUploadUrl(taskId: taskId), method: "POST", body: body) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoAttachmentUploadTicket.self, from: data, statusCode: statusCode,
                                                call: "generateTaskAttachmentUpload"))
        }
    }

    /// PUT the bytes to the presigned URL. Deliberately not `performToDoRequest`: this goes to R2, not
    /// our API, and must carry no Authorization header.
    func uploadTaskAttachmentData(_ data: Data, to uploadUrl: String, contentType: String,
                                  completionHandler: @escaping (_ success: Bool) -> ()) {
        guard let url = URL(string: uploadUrl) else { completionHandler(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        URLSession.shared.uploadTask(with: request, from: data) { _, response, error in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let error = error { addLog(text: "attachment upload failed: \(error.localizedDescription)") }
            completionHandler(error == nil && (200...299).contains(code))
        }.resume()
    }

    func createTaskAttachment(taskId: String, fileName: String, fileKey: String, contentType: String, fileSize: Int,
                              completionHandler: @escaping (_ attachment: ToDoAttachment?) -> ()) {
        let body = try? JSONSerialization.data(withJSONObject: [
            "file_name": fileName, "file_key": fileKey, "content_type": contentType, "file_size": fileSize,
        ])
        performToDoRequest(path: ToDoEndpoint.attachments(taskId: taskId), method: "POST", body: body) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoAttachment.self, from: data, statusCode: statusCode,
                                                call: "createTaskAttachment"))
        }
    }

    func deleteTaskAttachment(taskId: String, attachmentId: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.attachment(taskId: taskId, attachmentId: attachmentId),
                           method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200...299).contains(statusCode))
        }
    }

    func addToDoComment(taskId: String, content: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["content": content])
        performToDoRequest(path: ToDoEndpoint.comments(taskId: taskId), method: "POST", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func updateToDoComment(taskId: String, commentId: String, content: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["content": content])
        performToDoRequest(path: ToDoEndpoint.comment(taskId: taskId, commentId: commentId), method: "PUT", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func deleteToDoComment(taskId: String, commentId: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.comment(taskId: taskId, commentId: commentId), method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func getToDoReactions(taskId: String, completionHandler: @escaping (_ reactions: [ToDoReaction]?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.reactions(taskId: taskId), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([ToDoReaction].self, from: data, statusCode: statusCode, call: "getToDoReactions"))
        }
    }

    func addToDoReaction(taskId: String, emoji: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["emoji": emoji])
        performToDoRequest(path: ToDoEndpoint.reactions(taskId: taskId), method: "POST", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func removeToDoReaction(taskId: String, emoji: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let encoded = emoji.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? emoji
        performToDoRequest(path: "\(ToDoEndpoint.reactions(taskId: taskId))?emoji=\(encoded)", method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func getToDoCommentReactions(taskId: String, commentId: String, completionHandler: @escaping (_ reactions: [ToDoReaction]?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.commentReactions(taskId: taskId, commentId: commentId), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([ToDoReaction].self, from: data, statusCode: statusCode, call: "getToDoCommentReactions"))
        }
    }

    func addToDoCommentReaction(taskId: String, commentId: String, emoji: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["emoji": emoji])
        performToDoRequest(path: ToDoEndpoint.commentReactions(taskId: taskId, commentId: commentId), method: "POST", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func removeToDoCommentReaction(taskId: String, commentId: String, emoji: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let encoded = emoji.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? emoji
        performToDoRequest(path: "\(ToDoEndpoint.commentReactions(taskId: taskId, commentId: commentId))?emoji=\(encoded)", method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    // MARK: Saved websites (Procrastinate)

    func getSavedWebsites(completionHandler: @escaping (_ websites: [SavedWebsite]?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.savedWebsite, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([SavedWebsite].self, from: data, statusCode: statusCode, call: "getSavedWebsites"))
        }
    }

    /// `POST /saved-website [{ url, title, note }]` — the body is an array.
    func addSavedWebsite(url: String, note: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: [["url": url, "title": "", "note": note]])
        performToDoRequest(path: ToDoEndpoint.savedWebsite, method: "POST", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func deleteSavedWebsite(id: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: "\(ToDoEndpoint.savedWebsite)?website_id=\(id)", method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `PUT /saved-website/delete [ids]`.
    func deleteSavedWebsites(ids: [String], completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ids)
        performToDoRequest(path: ToDoEndpoint.savedWebsiteBulkDelete, method: "PUT", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    // MARK: Projects

    /// `GET /projects?page=&take=&order=DESC[&search=][&status=][&tag=]` (status omitted = active, the
    /// server default).
    ///
    /// `tag` filters on `metadata.tags` server-side (backend#2412). It has to be the server's job
    /// rather than a predicate over the pages already loaded: the list is paged at
    /// `ToDoPaging.projectsPerPage`, so filtering locally would quietly show only the matches that
    /// happened to be on the fetched pages and call that the answer.
    func getProjectsPage(page: Int, take: Int, search: String?, status: ProjectLifecycleStatus, tag: String? = nil,
                         expectedAccountID: String? = nil,
                         completionHandler: @escaping (_ page: ProjectsPage?) -> ()) {
        var items = ["page=\(page)", "take=\(take)", "order=DESC"]
        if let search = search?.trimmingCharacters(in: .whitespaces), !search.isEmpty {
            items.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)")
        }
        if status != .active { items.append("status=\(status.rawValue)") }
        // Folded, because the server stores tags folded and matches them exactly.
        if let tag = ProjectTags.normalize(tag ?? "") {
            items.append("tag=\(tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tag)")
        }
        performToDoRequest(path: "\(ToDoEndpoint.projects)?\(items.joined(separator: "&"))", method: "GET", body: nil, expectedAccountID: expectedAccountID) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectsPage.self, from: data, statusCode: statusCode, call: "getProjectsPage"))
        }
    }

    /// Web `fetchAllProjects`: every active project, paging `take=50` until `hasNextPage` is false.
    func getAllActiveProjects(completionHandler: @escaping (_ projects: [Project]?) -> ()) {
        fetchActiveProjects(page: ToDoPaging.firstPage, accumulated: [], completionHandler: completionHandler)
    }

    private func fetchActiveProjects(page: Int, accumulated: [Project], completionHandler: @escaping (_ projects: [Project]?) -> ()) {
        getProjectsPage(page: page, take: ToDoPaging.allProjectsTake, search: nil, status: .active) { [weak self] result in
            guard let result = result else {
                completionHandler(accumulated.isEmpty ? nil : accumulated)
                return
            }
            let known = Set(accumulated.map { $0.id })
            let merged = accumulated + result.items.filter { !known.contains($0.id) }
            if result.hasNextPage, page < ToDoPaging.allProjectsMaxPages, !result.items.isEmpty {
                self?.fetchActiveProjects(page: page + 1, accumulated: merged, completionHandler: completionHandler)
            } else {
                completionHandler(merged)
            }
        }
    }

    /// `POST /projects { name, description[, due_date] }` — `due_date` as a local `YYYY-MM-DD` like the
    /// web's create modal (`CreateProjectDto.due_date` is an ISO date string); omitted when unset.
    /// `outcome` is the project's rating on the server's 1–10 wire scale — a real column since
    /// backend#2385, stored as sent (the API applies no 1–5 conversion). Omitted means unrated;
    /// legacy `importance` (1–4) is left alone for the server's own portfolio ranking.
    func createToDoProject(name: String, dueDate: Date?, outcome: Int? = nil,
                           completionHandler: @escaping (_ project: Project?, _ serverMessage: String?) -> ()) {
        var body: [String: Any] = ["name": name, "description": ""]
        if let outcome = outcome { body["outcome"] = outcome }
        if let dueDate = dueDate { body["due_date"] = ToDoDates.ymd(dueDate) }
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.projects, method: "POST", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(Project.self, from: data, statusCode: statusCode, call: "createToDoProject"),
                              AllApi.toDoFailureMessage(data: data, statusCode: statusCode))
        }
    }

    /// `PUT /projects/:id` with a partial body (e.g. `{ due_date }`, `{ status }`). On a non-2xx the
    /// server's own reason comes back too, so an optimistic change can roll back with a real message.
    func updateProject(id: String, body: [String: Any], expectedAccountID: String? = nil,
                       completionHandler: @escaping (_ project: Project?, _ serverMessage: String?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.project(id: id), method: "PUT", body: data, expectedAccountID: expectedAccountID) { data, statusCode in
            completionHandler(AllApi.decodeToDo(Project.self, from: data, statusCode: statusCode, call: "updateProject"),
                              AllApi.toDoFailureMessage(data: data, statusCode: statusCode))
        }
    }

    /// Web `fetchProjectTodos`: the candidates a project card's NEXT task is picked from
    /// (`GET /to-do?project_id=` / `synced_project_id=`, SMART). The card can't trust the payload's
    /// own `top_priority_task` — see `PortfolioNextTask`.
    func getProjectNextTaskCandidates(target: PortfolioNextTask.FetchTarget,
                                      completionHandler: @escaping (_ tasks: [ToDoTask]?) -> ()) {
        let synced = target.syncedProjectId ?? ""
        let query = ToDoListQuery(page: ToDoPaging.firstPage, take: PortfolioNextTask.fetchTake, sortMode: .smart,
                                  projectId: synced.isEmpty ? target.projectId : nil,
                                  syncedProjectId: synced.isEmpty ? nil : synced)
        getToDoPage(query) { completionHandler($0?.data) }
    }

    /// `GET /projects/:id` — the full project (members, custom statuses, counts).
    func getProject(id: String, completionHandler: @escaping (_ project: Project?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.project(id: id), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(Project.self, from: data, statusCode: statusCode, call: "getProject"))
        }
    }

    /// `DELETE /projects/:id`.
    func deleteProject(id: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.project(id: id), method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `GET /projects/:id/todos?page&take&sort_mode` (web `fetchProjectDetailsTasks`), or the
    /// `GET /to-do?synced_project_id=` variant for a synced project.
    func getProjectTasks(project: Project, sortMode: ToDoSortMode, completionHandler: @escaping (_ page: ToDoPage?) -> ()) {
        let path: String
        if let synced = project.synced_project_id, !synced.isEmpty {
            path = ToDoListQuery(page: ToDoPaging.firstPage, take: ToDoPaging.projectTasksTake, sortMode: sortMode, syncedProjectId: synced).path
        } else {
            path = "\(ToDoEndpoint.projectTodos(id: project.id))?page=\(ToDoPaging.firstPage)&take=\(ToDoPaging.projectTasksTake)&sort_mode=\(sortMode.rawValue)"
        }
        performToDoRequest(path: path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoPage.self, from: data, statusCode: statusCode, call: "getProjectTasks"))
        }
    }

    /// `POST /projects/:id/members { email, role? }`.
    func inviteProjectMember(projectId: String, email: String, role: String?, completionHandler: @escaping (_ success: Bool, _ statusCode: Int) -> ()) {
        var body: [String: Any] = ["email": email]
        if let role = role { body["role"] = role }
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.projectMembers(id: projectId), method: "POST", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode), statusCode)
        }
    }

    /// Re-sends an invitation that is still outstanding. There is no separate resend route: the server's
    /// `inviteMember` updates the existing row, re-stamps `invitation_sent_at` and emails the invite
    /// again for anyone who hasn't accepted yet, so a resend is the same POST with the row's own email
    /// and role. Reports the server's reason on failure (e.g. "This email is already a member").
    func resendProjectInvitation(projectId: String, email: String, role: String?,
                                 completionHandler: @escaping (_ success: Bool, _ serverMessage: String?) -> ()) {
        var body: [String: Any] = ["email": email]
        if let role = role { body["role"] = role }
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.projectMembers(id: projectId), method: "POST", body: data) { data, statusCode in
            completionHandler((200..<300).contains(statusCode),
                              AllApi.toDoFailureMessage(data: data, statusCode: statusCode))
        }
    }

    /// `DELETE /projects/:id/members/:memberId`.
    func removeProjectMember(projectId: String, memberId: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.projectMember(id: projectId, memberId: memberId), method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `PUT /projects/:id/members/:memberId { role }`.
    func updateProjectMemberRole(projectId: String, memberId: String, role: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["role": role])
        performToDoRequest(path: ToDoEndpoint.projectMember(id: projectId, memberId: memberId), method: "PUT", body: data) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `POST /projects/:id/members/leave`.
    func leaveProject(id: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.leaveProject(id: id), method: "POST", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    /// `GET /projects/:id/notes?page=1&take=20` — shared project notes (no body in the list).
    ///
    /// `archived` is the server's two-state filter: omitted lists the active notes, true lists only
    /// the archived ones. Archived notes are a separate fetch rather than a flag on one list, so an
    /// active view can never accidentally show one.
    ///
    /// The parameter is only sent when it is asked for. An API that predates it validates query
    /// parameters strictly, so sending `archived=false` on every call would turn the ordinary notes
    /// list into a 400 everywhere the new backend has not been deployed yet — the default has to stay
    /// byte-for-byte the request that already works.
    /// The status code comes back alongside the notes because a caller sweeping every project has to
    /// tell "this project has no notes" from "the server would not answer it": the sweep gets rate
    /// limited (429), and recording that as an empty project silently hides real notes — see
    /// `ProjectNotesSweep`. `statusCode` is 0 when the request never reached the server.
    func getProjectNotes(projectId: String, archived: Bool = false,
                         completionHandler: @escaping (_ notes: [ProjectNote]?, _ statusCode: Int) -> ()) {
        var path = "\(ToDoEndpoint.projectNotes(id: projectId))?page=\(ToDoPaging.firstPage)"
            + "&take=\(ToDoPaging.projectNotesTake)&order=DESC"
        if archived { path += "&archived=true" }
        performToDoRequest(path: path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNotesPage.self, from: data, statusCode: statusCode,
                                                call: "getProjectNotes")?.data, statusCode)
        }
    }

    /// `PATCH /projects/:id/notes/:noteId { archived }` — file a note away, or restore it.
    ///
    /// Archiving is reversible and non-destructive: the note keeps its content, its history and its
    /// collaborative document, and only leaves the default list. The client says which way; the
    /// `archived_at` timestamp is the server's, so two clients can never disagree about when.
    func setProjectNoteArchived(projectId: String, noteId: String, archived: Bool,
                                completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        let body = try? JSONSerialization.data(withJSONObject: ["archived": archived])
        performToDoRequest(path: ToDoEndpoint.projectNote(id: projectId, noteId: noteId), method: "PATCH", body: body) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "setProjectNoteArchived"))
        }
    }

    /// `GET /projects/:id/notes/:noteId` — one note including its ProseMirror `content`.
    func getProjectNote(projectId: String, noteId: String, completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.projectNote(id: projectId, noteId: noteId), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "getProjectNote"))
        }
    }

    /// Collaborative bodies use the document endpoint, which merges Yjs updates atomically.
    /// Keep credentials in native code and bind every read, save and channel authorization to
    /// the account that opened the editor. Never log document/auth response bodies.
    func projectNoteDocumentRequest(identity: ProjectNoteIdentity, action: ProjectNoteRequestAction,
                                    body: Data? = nil, completion: @escaping (Data?, Int) -> Void) {
        guard let path = ProjectNoteRequestAction.path(identity: identity, action: action) else {
            completion(nil, 0)
            return
        }
        performToDoRequest(path: path, method: action.method, body: body, timeout: 25,
                          expectedAccountID: identity.accountID, logErrorBody: false,
                          completionHandler: completion)
    }

    /// `POST /projects/:id/notes { title }`.
    func createProjectNote(projectId: String, title: String, completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["title": title])
        performToDoRequest(path: ToDoEndpoint.projectNotes(id: projectId), method: "POST", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "createProjectNote"))
        }
    }

    /// `PATCH /projects/:id/notes/:noteId { title }` — the title, and deliberately never `content`.
    ///
    /// The endpoint accepts `content` too, but a note's body is a Yjs (CRDT) document. The web editor
    /// applies `yjs_state` whenever it exists and only falls back to `content`, and its autosave
    /// re-renders `content` from the merged Y.Doc; the service never writes `yjs_state` from a
    /// content PATCH. So a body written from here would be invisible in that editor and clobbered by
    /// the next web save. The title is a plain column outside the document — last write wins, like
    /// renaming a task — which makes it the one field a non-Yjs client can set safely.
    /// Body editing uses the separate collaborative document endpoint below.
    func renameProjectNote(projectId: String, noteId: String, title: String, completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        let body = try? JSONSerialization.data(withJSONObject: ["title": title])
        performToDoRequest(path: ToDoEndpoint.projectNote(id: projectId, noteId: noteId), method: "PATCH", body: body) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "renameProjectNote"))
        }
    }

    /// `DELETE /projects/:id/notes/:noteId` (204).
    func deleteProjectNote(projectId: String, noteId: String, completionHandler: @escaping (_ success: Bool) -> ()) {
        performToDoRequest(path: ToDoEndpoint.projectNote(id: projectId, noteId: noteId), method: "DELETE", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    func getPendingProjectInvitations(completionHandler: @escaping (_ projects: [Project]?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.pendingInvitations, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo([Project].self, from: data, statusCode: statusCode, call: "getPendingProjectInvitations"))
        }
    }

    func respondToProjectInvitation(projectId: String, accept: Bool, completionHandler: @escaping (_ success: Bool) -> ()) {
        let path = accept ? ToDoEndpoint.acceptInvitation(projectId: projectId) : ToDoEndpoint.declineInvitation(projectId: projectId)
        performToDoRequest(path: path, method: "POST", body: nil) { _, statusCode in
            completionHandler((200..<300).contains(statusCode))
        }
    }

    // MARK: Portfolio

    func getPortfolio(completionHandler: @escaping (_ portfolio: PortfolioResponse?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.portfolio, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(PortfolioResponse.self, from: data, statusCode: statusCode, call: "getPortfolio"))
        }
    }

    func getPortfolioSettings(completionHandler: @escaping (_ settings: PortfolioSettings?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.portfolioSettings, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(PortfolioSettings.self, from: data, statusCode: statusCode, call: "getPortfolioSettings"))
        }
    }

    func updatePortfolioSettings(_ settings: PortfolioSettings, completionHandler: @escaping (_ settings: PortfolioSettings?) -> ()) {
        let data = try? JSONEncoder().encode(settings)
        performToDoRequest(path: ToDoEndpoint.portfolioSettings, method: "PUT", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(PortfolioSettings.self, from: data, statusCode: statusCode, call: "updatePortfolioSettings"))
        }
    }

    /// `PUT /portfolio/busy-hours { source, days }` (backend #2363). Hands back the raw status code
    /// so the reporter can tell "endpoint not deployed yet" (404) from "never reached the server" (0).
    func reportPortfolioBusyHours(_ report: BusyHoursReport, completionHandler: @escaping (_ statusCode: Int) -> ()) {
        let data = try? JSONEncoder().encode(report)
        performToDoRequest(path: ToDoEndpoint.portfolioBusyHours, method: "PUT", body: data) { _, statusCode in
            completionHandler(statusCode)
        }
    }

    // MARK: User

    /// `PATCH /user/timezone { timezone }` — a named IANA zone (fixed offsets are rejected with 400).
    /// Raw status code back so the sync can tell "rejected" from "never reached the server" (0).
    func updateUserTimezone(_ identifier: String, completionHandler: @escaping (_ statusCode: Int) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["timezone": identifier])
        performToDoRequest(path: ToDoEndpoint.userTimezone, method: "PATCH", body: data) { _, statusCode in
            completionHandler(statusCode)
        }
    }

    // MARK: Plumbing

    /// Shared plumbing: refresh the Auth0 credential (like every other call in AllApi), attach the
    /// bearer token via `makeRequest`, run the request and hand back `(data, statusCode)` — `statusCode`
    /// is 0 when the request never reached the server. Non-2xx bodies are logged via `writeJsonInLog`.
    private func performToDoRequest(path: String, method: String, body: Data?, timeout: TimeInterval? = nil,
                                    expectedAccountID: String? = nil,
                                    logErrorBody: Bool = true,
                                    completionHandler: @escaping (_ data: Data?, _ statusCode: Int) -> ()) {
        addLog(text: "func call:- api todo \(method) \(LogPrivacy.url(path))")
        func accountMatches() -> Bool {
            guard let expected = expectedAccountID else { return true }
            return !expected.isEmpty && appdelegate?.user?.userId == expected
        }
        guard accountMatches() else { completionHandler(nil, 0); return }
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            guard accountMatches() else { completionHandler(nil, 0); return }
            let capturedCredentials = try? credentialsInfo.get()
            if let expected = expectedAccountID {
                guard let credentials = capturedCredentials,
                      AuthUser(from: credentials.accessToken)?.userId == expected else { completionHandler(nil, 0); return }
            }
            guard accountMatches() else { completionHandler(nil, 0); return }
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard accountMatches(), appdelegate!.credential != nil, let url = NSURL(string: "\(baseUrl)\(path)") else {
                completionHandler(nil, 0)
                return
            }
            let request = makeRequest(responsePathUrl: url)
            if let expected = expectedAccountID, let credentials = capturedCredentials {
                request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
                request.setValue(expected, forHTTPHeaderField: "x-focus-bear-user-id")
            }
            request.httpMethod = method
            if let timeout = timeout { request.timeoutInterval = timeout }
            if let body = body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard accountMatches() else { completionHandler(nil, 0); return }
                guard let httpResponse = response as? HTTPURLResponse else {
                    addLog(text: "api todo \(method) \(LogPrivacy.url(path)) error:- \(error?.localizedDescription ?? "no response")")
                    completionHandler(nil, 0)
                    return
                }
                if !(200..<300).contains(httpResponse.statusCode) {
                    addLog(text: "api todo \(method) \(LogPrivacy.url(path)) Api error:- statusCode is \(httpResponse.statusCode)")
                    if logErrorBody { self.logToDoErrorBody(data) }
                }
                completionHandler(data, httpResponse.statusCode)
            }
            guard accountMatches() else { completionHandler(nil, 0); return }
            task.resume()
        }
    }

    /// Whatever the server said, JSON or not. `writeJsonInLog` only understands a JSON object, so a
    /// `text/plain` rejection left the log saying a call failed and nothing about why — which is how
    /// a save that died on "Token missing or corrupted!" reached a debug report with no evidence
    /// (report 2026-09-16_15-14-36).
    private func logToDoErrorBody(_ data: Data?) {
        guard let data = data else { return }
        if let object = try? JSONSerialization.jsonObject(with: data), object is NSDictionary {
            writeJsonInLog(data: data)
            return
        }
        guard let reason = ToDoServerError.message(from: data) else { return }
        addLog(text: "api todo error body:- \(reason)")
    }

    /// The backend's reason for a non-2xx, nil for a success or a body without one.
    private static func toDoFailureMessage(data: Data?, statusCode: Int) -> String? {
        guard !(200..<300).contains(statusCode) else { return nil }
        return ToDoServerError.message(from: data)
    }

    private static func decodeToDo<T: Decodable>(_ type: T.Type, from data: Data?, statusCode: Int, call: String) -> T? {
        guard (200..<300).contains(statusCode), let data = data else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            addLog(text: "api todo \(call) decode error:- \(error)")
            return nil
        }
    }
}
