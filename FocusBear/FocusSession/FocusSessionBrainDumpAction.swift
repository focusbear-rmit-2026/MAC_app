import SwiftUI

/// The same conversion and editable review sheet as the to-do list, presented over the session.
/// The original note remains intact; generating suggestions does not create tasks until review.
struct FocusSessionBrainDumpAction: SwiftUI.View {
    let text: String
    let scale: FocusSessionScale
    @SwiftUI.StateObject private var tasks = ToDoStore(strings: ToDoStrings.load())

    var body: some SwiftUI.View {
        SwiftUI.Button {
            tasks.resetBrainDump()
            tasks.brainDumpText = text
            tasks.isBrainDumpVisible = true
            tasks.convertBrainDump(force: false)
        } label: {
            Label(tasks.strings[.createTasksUsingAI], systemImage: "sparkles")
                .font(scale.font(FocusSessionLayout.rowTitleFont, .medium))
                .foregroundColor(.white)
                .padding(.vertical, scale.pt(FocusSessionLayout.rowGap))
                .frame(maxWidth: .infinity)
                .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? FocusSessionPalette.secondaryText : FocusSessionPalette.accent)
                .cornerRadius(scale.pt(FocusSessionLayout.taskCardCornerRadius))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .sheet(isPresented: $tasks.isBrainDumpVisible, onDismiss: { tasks.resetBrainDump() }) {
            ToDoBrainDumpSheet(store: tasks)
        }
    }
}
