# Uploading debug symbols (dSYMs) to Sentry

Crash and **App Hang** reports from the `focus-bear-macos` Sentry project are only
useful if their main-thread stacks are **symbolicated**. Without the matching
dSYMs, every in-app frame shows as `<anonymous>` and we can't tell which call
site trapped or which work is blocking the main run loop. This is the root cause
of [#1954](https://github.com/Focus-Bear/Mac-App/issues/1954) (crashes) and
[#1955](https://github.com/Focus-Bear/Mac-App/issues/1955) (App Hangs) — one
dSYM upload per release fixes both.

## How it works in this repo

`scripts/upload-dsyms.sh` wraps `sentry-cli debug-files upload`. It runs two ways:

1. **Automatically on every Release build.** A Run Script build phase named
   **`[Sentry] Upload Debug Symbols`** on the `Focus Bear` target calls the
   script. It only uploads for the `Release` configuration (i.e. Archive), using
   Xcode's `$DWARF_DSYM_FOLDER_PATH`. Debug builds are a fast no-op, so local
   development is unaffected. On a Release build a missing token or missing
   `sentry-cli` **fails the build** — that is what makes the upload mandatory
   rather than something a human can forget.

2. **Manually, to back-fill an already-shipped build.** Point the script at an
   `.xcarchive`, a dSYMs folder, a `.app`, or a `.dSYM`.

## One-time setup

Install `sentry-cli`:

```bash
brew install getsentry/tools/sentry-cli   # or: npm install -g @sentry/cli
```

Provide credentials via **environment variables** (never commit a token):

| Variable            | Required | Default            |
| ------------------- | -------- | ------------------ |
| `SENTRY_AUTH_TOKEN` | yes      | —                  |
| `SENTRY_ORG`        | no       | `focus-bear`       |
| `SENTRY_PROJECT`    | no       | `focus-bear-macos` |

Create the token at
`https://focus-bear.sentry.io/settings/account/api/auth-tokens/` with the
`project:releases` and `project:write` scopes. For local Archive builds, export
it in your shell profile (or a gitignored file Xcode inherits); in CI, store it
as a secret. Verify uploads at
`https://focus-bear.sentry.io/settings/projects/focus-bear-macos/debug-symbols/`.

## Back-filling the existing hangs / crashes

The ~25 open App Hangs and crash `FOCUS-BEAR-MACOS-Q8` came from builds shipped
before this mechanism existed. Symbolicate them by uploading the dSYMs from
their archives (Xcode keeps them under `~/Library/Developer/Xcode/Archives/`):

```bash
export SENTRY_AUTH_TOKEN=...   # token from the setup step above
./scripts/upload-dsyms.sh "~/Library/Developer/Xcode/Archives/2026-06-18/Focus Bear 2.29 460.xcarchive"
```

`sentry-cli debug-files upload` matches dSYMs to events by build UUID, so it's
safe to upload every archive you still have; Sentry re-symbolicates existing
events once the matching dSYM lands. Confirm builds `2.29+460` onward are
covered (per #1954).

## App Hang Tracking notes

App Hang Tracking is on by **default** in the Sentry Cocoa SDK — it is not
configured explicitly at the `SentrySDK.start` call in
`FocusBear/AppDelegate.swift` (~line 193), and `enableSwizzling = false` does
**not** disable it. A watchdog pings the main run loop and captures the
main-thread stack if it doesn't respond within `appHangTimeoutInterval`
(default `2.0` seconds). If 2 s proves too noisy once stacks are readable, raise
it, e.g.:

```swift
options.appHangTimeoutInterval = 3.0
```

## Security note

A Sentry auth token was historically committed at
`Certificates/Upload sentry files using sentry cli.rtfd`, and `Certificates/` is
not gitignored. That token must be **rotated** and removed from history, and the
directory gitignored. Use the environment variables above instead — never paste
a token into a committed file.
