//
//  FocusSessionApi.swift
//  Focus Bear
//
//  Exact task lookup and an adapter to the shared, account-bound to-do writer. PUT merges supplied
//  fields but creates a missing ID, so edits require a fresh existing-record snapshot first.
//

import Foundation

extension AllApi {

    /// Resolve the exact queued task. Older backends return a partial by-ID projection; today's
    /// Day Plan has the complete row, including its version, for planned tasks. Both reads remain
    /// account-bound and must independently establish the exact existing record before an edit.
    func getFocusSessionTask(id: String, completion: @escaping ([String: Any]?) -> Void) {
        getFocusSessionTaskResult(id: id) { completion(try? $0.get()) }
    }

    func getFocusSessionTaskResult(id: String, completion: @escaping (Result<[String: Any], FocusSessionTaskLookup.Failure>) -> Void) {
        guard let account = appdelegate?.user?.userId, !account.isEmpty else { completion(.failure(.unavailable)); return }
        FocusSessionTaskLookup.loadResult(id: id, day: DayPlanSync.shared.dayString(Date()),
                                   accountIsCurrent: { appdelegate?.user?.userId == account },
                                   read: { path, callback in
            self.getTaskSnapshotData(path: path, expectedAccountID: account, completion: callback)
        }, diagnostic: { addLog(text: $0) }, completion: completion)
    }

    /// `PUT /to-do` — upsert. Include `id` in `body` to update an existing to-do, omit it to create.
    /// Calls back with the saved row so the caller can pick up server-assigned fields (`id`,
    /// `top_score`).
    func upsertToDo(body: [String: Any], completionHandler: @escaping (_ result: Bool, _ jsonResult: NSDictionary?) -> ()) {
        guard let account = appdelegate?.user?.userId, !account.isEmpty else { completionHandler(false, nil); return }
        upsertToDo(body, expectedAccountID: account) { task, status, _ in
            if let expectedID = body["id"] as? String, task?.id != expectedID {
                completionHandler(false, nil); return
            }
            let json = task.flatMap { try? JSONEncoder().encode($0) }
                .flatMap { try? JSONSerialization.jsonObject(with: $0) as? NSDictionary }
            completionHandler((200..<300).contains(status) && task != nil, json)
        }
    }
}

/// An injected reader keeps compatibility and delayed-response behavior testable without auth,
/// networking or session globals. Never combine incomplete rows from different response versions.
enum FocusSessionTaskLookup {
    enum Failure: Error { case unavailable, incompleteServerSnapshot }
    typealias Read = (_ path: String, _ completion: @escaping (Data?, Int) -> Void) -> Void

    static func load(id: String, day: String, accountIsCurrent: @escaping () -> Bool,
                     read: @escaping Read, diagnostic: @escaping (String) -> Void = { _ in },
                     completion: @escaping ([String: Any]?) -> Void) {
        loadResult(id: id, day: day, accountIsCurrent: accountIsCurrent, read: read,
                   diagnostic: diagnostic) { completion(try? $0.get()) }
    }

    static func loadResult(id: String, day: String, accountIsCurrent: @escaping () -> Bool,
                           read: @escaping Read, diagnostic: @escaping (String) -> Void = { _ in },
                           completion: @escaping (Result<[String: Any], Failure>) -> Void) {
        guard UUID(uuidString: id) != nil, accountIsCurrent() else { completion(.failure(.unavailable)); return }
        read("/to-do/by-ids?ids=\(id)") { data, status in
            guard accountIsCurrent(), let rows = json(data, status: status) as? [[String: Any]],
                  let row = rows.first(where: { $0["id"] as? String == id }) else {
                diagnostic("focus task lookup: stage=by-id status=\(status) matchingRow=false")
                completion(.failure(.unavailable)); return
            }
            diagnose(row, stage: "by-id", id: id, diagnostic: diagnostic)
            if FocusSessionTaskSnapshot.isEditable(row, id: id) { completion(.success(row)); return }
            // The legacy by-ID route confirms the row exists but omits editable fields. Unlike
            // title search or project-task lists, Day Plan returns a complete entity snapshot.
            guard accountIsCurrent() else { completion(.failure(.unavailable)); return }
            read("/day-plan/day/\(day)") { data, status in
                guard accountIsCurrent(), let payload = json(data, status: status) as? [String: Any],
                      payload["day"] as? String == day,
                      let tasks = payload["tasks"] as? [[String: Any]] else {
                    diagnostic("focus task lookup: stage=day-plan status=\(status) validDayPayload=false")
                    completion(.failure(.unavailable)); return
                }
                guard let full = tasks.first(where: { $0["id"] as? String == id }) else {
                    diagnostic("focus task lookup: stage=day-plan rows=\(tasks.count) matchingRow=false")
                    completion(.failure(.incompleteServerSnapshot)); return
                }
                diagnose(full, stage: "day-plan", id: id, diagnostic: diagnostic)
                guard FocusSessionTaskSnapshot.isEditable(full, id: id) else { completion(.failure(.incompleteServerSnapshot)); return }
                completion(.success(full))
            }
        }
    }

    /// Log only schema names/counts, never a task ID, title, body, or server response.
    private static func diagnose(_ row: [String: Any], stage: String, id: String, diagnostic: (String) -> Void) {
        let missing = FocusSessionTaskSnapshot.requiredKeys.subtracting(row.keys).sorted().joined(separator: ",")
        diagnostic("focus task lookup: stage=\(stage) matchingRow=true editable=\(FocusSessionTaskSnapshot.isEditable(row, id: id)) missingKeys=[\(missing)] validSubtasks=\(FocusSessionSubtasks.decode(row) != nil)")
    }

    private static func json(_ data: Data?, status: Int) -> Any? {
        guard (200..<300).contains(status), let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }
}
