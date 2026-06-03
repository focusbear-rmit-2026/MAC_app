//
//  ClaudeTitleReader.swift
//  FocusBear
//
//  Created by Manish Jain on 02/06/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import Cocoa
import ApplicationServices

final class claudeTitleReader {

    static let shared = claudeTitleReader()

    private init() {}

    func chatTitle(for runningApp: NSRunningApplication) -> String? {
        let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)

        var windowRef: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowRef
        )

        guard result == .success else {
            return nil
        }
        let window = windowRef as! AXUIElement
        return conversationTitle(from: window)
    }

    private func conversationTitle(from window: AXUIElement) -> String? {
        var texts: [String] = []

        func collectTexts(_ element: AXUIElement) {
            var roleRef: CFTypeRef?

            if AXUIElementCopyAttributeValue(
                element,
                kAXRoleAttribute as CFString,
                &roleRef
            ) == .success,
               let role = roleRef as? String,
               role == kAXStaticTextRole {

                var valueRef: CFTypeRef?

                if AXUIElementCopyAttributeValue(
                    element,
                    kAXValueAttribute as CFString,
                    &valueRef
                ) == .success,
                   let value = valueRef as? String,
                   !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {

                    texts.append(value)
                }
            }

            var childrenRef: CFTypeRef?

            if AXUIElementCopyAttributeValue(
                element,
                kAXChildrenAttribute as CFString,
                &childrenRef
            ) == .success,
               let children = childrenRef as? [AXUIElement] {

                children.forEach(collectTexts)
            }
        }

        collectTexts(window)

        guard texts.count > 3 else {
            return nil
        }

        // Based on Claude's current accessibility hierarchy,
        // the active conversation title is the 4th AXStaticText element.
        return texts[3]
    }
}
