import Foundation

/// Stable draft IDs make a retry an upsert of the same task, including after an unknown response.
enum BrainDumpTaskPayload {
    static func body(for task: BrainDumpTask, today: String) -> [String: Any]? {
        let duration = task.estimatedMinutes.multipliedReportingOverflow(by: 60)
        guard !task.task_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              task.estimatedMinutes > 0, !duration.overflow,
              duration.partialValue <= Int(Int32.max) else { return nil }
        let subtasks = task.subtasks.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        var body: [String: Any] = [
            "id": task.id.lowercased(), "title": task.task_name, "details": "", "objective": "",
            "tags": [], "due_date": task.due_date ?? today, "duration": duration.partialValue,
            "eisenhower_quadrant": EisenhowerQuadrant.doIt.rawValue,
            "subtasks": subtasks.map { ["name": $0, "is_completed": false] as [String: Any] },
            "status": ToDoStatus.notStarted.rawValue
        ]
        // Omission invokes the backend's default of 1. Explicit null keeps a suggestion unrated.
        body["outcome"] = task.outcome.map { $0 as Any } ?? NSNull()
        body["perspiration_level"] = task.perspiration_level.map { $0 as Any } ?? NSNull()
        return body
    }
}

/// Sequential, explicit saves stop at the first unconfirmed response. Only confirmed IDs are removed
/// from the review draft. The owner supplies the account/generation check and the existing API write.
final class BrainDumpTaskWriter {
    enum Result: Equatable { case complete, failed(confirmedCount: Int), superseded }
    private let tasks: [BrainDumpTask]
    private let isCurrent: () -> Bool
    private let write: (BrainDumpTask, @escaping (Bool) -> Void) -> Void
    private let didSave: (String) -> Void
    private let completion: (Result) -> Void
    private var index = 0
    private var awaitingResponse = false
    private var finished = false

    init(tasks: [BrainDumpTask], isCurrent: @escaping () -> Bool,
         write: @escaping (BrainDumpTask, @escaping (Bool) -> Void) -> Void,
         didSave: @escaping (String) -> Void, completion: @escaping (Result) -> Void) {
        self.tasks = tasks; self.isCurrent = isCurrent; self.write = write
        self.didSave = didSave; self.completion = completion
    }

    func start() { advance() }
    func cancel() { finish(.superseded) }

    private func advance() {
        guard !finished, !awaitingResponse else { return }
        guard isCurrent() else { finish(.superseded); return }
        guard index < tasks.count else { finish(.complete); return }
        let requestIndex = index
        let task = tasks[index]
        awaitingResponse = true
        write(task) { [self] confirmed in
            guard !finished, awaitingResponse, index == requestIndex else { return }
            awaitingResponse = false
            guard isCurrent() else { finish(.superseded); return }
            guard confirmed else { finish(.failed(confirmedCount: index)); return }
            didSave(task.id)
            index += 1
            advance()
        }
    }

    private func finish(_ result: Result) {
        guard !finished else { return }
        finished = true
        completion(result)
    }
}
