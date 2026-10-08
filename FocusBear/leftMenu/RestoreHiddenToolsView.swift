//
//  RestoreHiddenToolsView.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import SwiftUI

/// Popover shown from the TOOLS gear icon, listing rows the user hid via the hover ✕ so they
/// can bring them back.
struct RestoreHiddenToolsView: View {
    @SwiftUI.State private var hidden: [ToolID] = ToolVisibilityStore.hiddenTools()
    let onRestore: (ToolID) -> Void

    // Config-driven i18n (leftMenuVcInfo block), with English fallbacks.
    private var titleText: String { leftMenuConfigString("restoreHiddenToolsTitle") ?? "Hidden tools" }
    private var emptyText: String { leftMenuConfigString("restoreHiddenToolsEmpty") ?? "Nothing hidden — hover a tool and click ✕ to hide it." }
    private var restoreText: String { leftMenuConfigString("restoreButton") ?? "Restore" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleText)
                .font(.headline)
            if hidden.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                SwiftUI.ForEach(hidden, id: \.self) { (tool: ToolID) in
                    HStack {
                        Text(tool.displayName)
                        Spacer()
                        SwiftUI.Button(restoreText) {
                            ToolVisibilityStore.restore(tool)
                            onRestore(tool)
                            hidden = ToolVisibilityStore.hiddenTools()
                        }
                        .accessibilityIdentifier(UITestContract.Identifier.OnboardingRegression.restoreToolPrefix + tool.rawValue)
                    }
                }
            }
        }
        .padding(14)
        .frame(minWidth: 220)
    }
}
