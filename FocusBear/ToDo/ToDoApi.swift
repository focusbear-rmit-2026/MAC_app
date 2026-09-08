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

    var path: String {
        var items = ["page=\(page)", "take=\(take)", "order=DESC", "sort_mode=\(sortMode.rawValue)"]
        if let status = status { items.append("status=\(status.rawValue)") }
        if let projectId = projectId, !projectId.isEmpty { items.append("project_id=\(projectId)") }
        if let syncedProjectId = syncedProjectId, !syncedProjectId.isEmpty { items.append("synced_project_id=\(syncedProjectId)") }
        return "\(ToDoEndpoint.toDo)?\(items.joined(separator: "&"))"
    }
}

extension AllApi {

    // MARK: To-dos

    func getToDoPage(_ query: ToDoListQuery, completionHandler: @escaping (_ page: ToDoPage?) -> ()) {
        performToDoRequest(path: query.path, method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoPage.self, from: data, statusCode: statusCode, call: "getToDoPage"))
        }
    }

    /// `GET /to-do/search?title=&take=` — the backend ranks in memory (exact → prefix → word → substring)
    /// and ignores every other filter; the caller filters client-side like the web.
    func searchToDoTasks(title: String, completionHandler: @escaping (_ tasks: [ToDoTask]?) -> ()) {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let path = "\(ToDoEndpoint.search)?title=\(encoded)&take=\(ToDoPaging.searchTake)"
        performToDoRequest(path: path, method: "GET", body: nil) { data, statusCode in
            // Lenient like ToDoPage: one row the client can't decode is dropped, not the whole result —
            // otherwise a single bad search hit makes search look empty.
            let rows = AllApi.decodeToDo([LenientRow<ToDoTask>].self, from: data, statusCode: statusCode, call: "searchToDoTasks")
            completionHandler(rows?.compactMap { $0.value })
        }
    }

    /// `PUT /to-do` — the only to-do write endpoint (upsert: no id = create). Returns the saved task;
    /// on a non-2xx, the server's own reason (`ToDoServerError`) so the toast can show it.
    func upsertToDo(_ body: [String: Any], completionHandler: @escaping (_ task: ToDoTask?, _ statusCode: Int, _ serverMessage: String?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.toDo, method: "PUT", body: data) { data, statusCode in
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
    func convertBrainDumpToTasks(contents: String, timeout: TimeInterval,
                                 completionHandler: @escaping (_ tasks: [BrainDumpTask]?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["contents": contents])
        performToDoRequest(path: ToDoEndpoint.convertBrainDump, method: "POST", body: data, timeout: timeout) { data, statusCode in
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

    // MARK: Comments / reactions

    func getToDoComments(taskId: String, completionHandler: @escaping (_ comments: [ToDoComment]?) -> ()) {
        performToDoRequest(path: "\(ToDoEndpoint.comments(taskId: taskId))?page=1&take=50", method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ToDoCommentsPage.self, from: data, statusCode: statusCode, call: "getToDoComments")?.data)
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

    /// `GET /projects?page=&take=&order=DESC[&search=][&status=]` (status omitted = active, the server default).
    func getProjectsPage(page: Int, take: Int, search: String?, status: ProjectLifecycleStatus,
                         completionHandler: @escaping (_ page: ProjectsPage?) -> ()) {
        var items = ["page=\(page)", "take=\(take)", "order=DESC"]
        if let search = search?.trimmingCharacters(in: .whitespaces), !search.isEmpty {
            items.append("search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)")
        }
        if status != .active { items.append("status=\(status.rawValue)") }
        performToDoRequest(path: "\(ToDoEndpoint.projects)?\(items.joined(separator: "&"))", method: "GET", body: nil) { data, statusCode in
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
    func createToDoProject(name: String, dueDate: Date?, completionHandler: @escaping (_ project: Project?, _ serverMessage: String?) -> ()) {
        var body: [String: Any] = ["name": name, "description": ""]
        if let dueDate = dueDate { body["due_date"] = ToDoDates.ymd(dueDate) }
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.projects, method: "POST", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(Project.self, from: data, statusCode: statusCode, call: "createToDoProject"),
                              AllApi.toDoFailureMessage(data: data, statusCode: statusCode))
        }
    }

    /// `PUT /projects/:id` with a partial body (e.g. `{ due_date }`, `{ status }`).
    func updateProject(id: String, body: [String: Any], completionHandler: @escaping (_ project: Project?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: body)
        performToDoRequest(path: ToDoEndpoint.project(id: id), method: "PUT", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(Project.self, from: data, statusCode: statusCode, call: "updateProject"))
        }
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
    func getProjectNotes(projectId: String, completionHandler: @escaping (_ notes: [ProjectNote]?) -> ()) {
        performToDoRequest(path: "\(ToDoEndpoint.projectNotes(id: projectId))?page=\(ToDoPaging.firstPage)&take=\(ToDoPaging.projectNotesTake)&order=DESC", method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNotesPage.self, from: data, statusCode: statusCode, call: "getProjectNotes")?.data)
        }
    }

    /// `GET /projects/:id/notes/:noteId` — one note including its ProseMirror `content`.
    func getProjectNote(projectId: String, noteId: String, completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        performToDoRequest(path: ToDoEndpoint.projectNote(id: projectId, noteId: noteId), method: "GET", body: nil) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "getProjectNote"))
        }
    }

    /// `POST /projects/:id/notes { title }`.
    func createProjectNote(projectId: String, title: String, completionHandler: @escaping (_ note: ProjectNote?) -> ()) {
        let data = try? JSONSerialization.data(withJSONObject: ["title": title])
        performToDoRequest(path: ToDoEndpoint.projectNotes(id: projectId), method: "POST", body: data) { data, statusCode in
            completionHandler(AllApi.decodeToDo(ProjectNote.self, from: data, statusCode: statusCode, call: "createProjectNote"))
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

    // MARK: Plumbing

    /// Shared plumbing: refresh the Auth0 credential (like every other call in AllApi), attach the
    /// bearer token via `makeRequest`, run the request and hand back `(data, statusCode)` — `statusCode`
    /// is 0 when the request never reached the server. Non-2xx bodies are logged via `writeJsonInLog`.
    private func performToDoRequest(path: String, method: String, body: Data?, timeout: TimeInterval? = nil,
                                    completionHandler: @escaping (_ data: Data?, _ statusCode: Int) -> ()) {
        addLog(text: "func call:- api todo \(method) \(path)")
        appdelegate!.credentialsManager.credentials { credentialsInfo in
            appdelegate!.setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: false)
            guard appdelegate!.credential != nil, let url = NSURL(string: "\(baseUrl)\(path)") else {
                completionHandler(nil, 0)
                return
            }
            let request = makeRequest(responsePathUrl: url)
            request.httpMethod = method
            if let timeout = timeout { request.timeoutInterval = timeout }
            if let body = body {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = body
            }
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    addLog(text: "api todo \(method) \(path) error:- \(error?.localizedDescription ?? "no response")")
                    completionHandler(nil, 0)
                    return
                }
                if !(200..<300).contains(httpResponse.statusCode) {
                    addLog(text: "api todo \(method) \(path) Api error:- statusCode is \(httpResponse.statusCode)")
                    self.writeJsonInLog(data: data)
                }
                completionHandler(data, httpResponse.statusCode)
            }
            task.resume()
        }
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
