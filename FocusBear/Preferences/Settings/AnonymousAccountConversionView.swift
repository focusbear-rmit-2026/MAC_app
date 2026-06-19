//
//  AnonymousAccountConversionView.swift
//  Focus Bear
//
//  Issue #1850: Anonymous (guest) users on macOS had no visible way to sign up /
//  convert their anonymous account into a registered one. This adds a SwiftUI card
//  shown in Settings > Account for guest users, plus a form sheet that collects a
//  real email + password and calls the cross-platform backend endpoint
//  POST /auth/convert-guest (which sets the new credentials on the SAME account, so
//  the user's data is preserved server-side).
//
//  A "guest" is a real backend account created with a generated email. The mobile app
//  (`createGuestEmail()` in useIsGuestAccount.ts) generates:
//    - prod: anonymoususer+<uuid>@focusbear.com
//    - dev:  internaltest+<uuid>@focusbear.io
//  so the email prefix is the cross-platform source of truth for "is this a guest".
//

import SwiftUI

/// Returns true when the currently logged-in account is an anonymous / guest account.
/// Detection matches the mobile app + backend guest-email patterns.
func isCurrentUserGuestAccount() -> Bool {
    let email = currentUserEmail
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
    guard !email.isEmpty else { return false }
    return email.hasPrefix("anonymoususer+") || email.hasPrefix("internaltest+")
}

private let fbAccent = Color(red: 232 / 255, green: 136 / 255, blue: 0 / 255)
private let fbAccentBackground = Color(red: 255 / 255, green: 228 / 255, blue: 198 / 255)

/// A card prompting guest users to create a real account so their progress is saved.
/// `onCreateAccount` is invoked when the button is tapped (opens the form sheet).
struct AnonymousAccountConversionView: View {
    var onCreateAccount: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(fbAccent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("You're using a guest account")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Create an account to save your progress and settings, and keep them if you change or reinstall on another device.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            SwiftUI.Button(action: onCreateAccount) {
                Text("Create account")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(fbAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(fbAccentBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(fbAccent, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create an account")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(fbAccent.opacity(0.4), lineWidth: 1))
        )
    }
}

/// Form sheet collecting the real email + password for converting a guest account.
/// `submit` performs the network call and reports back an optional error message
/// (nil == success). `onSuccess` is called after a successful conversion; `onCancel`
/// dismisses without changes.
struct AnonymousAccountConversionFormView: View {
    var submit: (_ email: String, _ password: String, _ completion: @escaping (_ errorMessage: String?) -> Void) -> Void
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @SwiftUI.State private var email = ""
    @SwiftUI.State private var password = ""
    @SwiftUI.State private var isSubmitting = false
    @SwiftUI.State private var errorMessage: String?

    private var canSubmit: Bool {
        !isSubmitting && email.contains("@") && password.count >= 8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Create your account")
                .font(.system(size: 16, weight: .semibold))
            Text("Add an email and password to turn your guest account into a permanent one. Your current settings and progress are kept.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                SecureField("Password (min 8 characters)", text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                SwiftUI.Button("Cancel", action: onCancel)
                    .disabled(isSubmitting)
                SwiftUI.Button(action: performSubmit) {
                    if isSubmitting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Create account")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func performSubmit() {
        errorMessage = nil
        isSubmitting = true
        submit(email.trimmingCharacters(in: .whitespacesAndNewlines), password) { error in
            isSubmitting = false
            if let error {
                errorMessage = error
            } else {
                onSuccess()
            }
        }
    }
}
