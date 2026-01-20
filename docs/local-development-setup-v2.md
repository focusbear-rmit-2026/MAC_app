# Local Development Setup — Focus Bear macOS App (V2)
- This document records **all issues encountered while setting up and building the V2 branch locally**, along with the **final confirmed fixes** that resulted in a successful build and app launch.
- The goal is to help future contributors avoid the same blockers and understand why these issues occurred.

---

## Environment
- **macOS:** Tahoe 26.2 (Build 25C56)
- **Xcode:** 26.2
- **Chip:** Apple Silicon (arm64, Apple M2)
- **Homebrew Ruby:** 4.0.0
- **CocoaPods:** 1.16.2 
- **macOS Deployment Target (Xcode):** 11
- **Build Mode Used:** Debug (local development)

---

## Initial Clone & Setup
```bash
mkdir -p ~/Desktop/FocusBear
cd ~/Desktop/FocusBear

git clone https://github.com/Focus-Bear/Mac-App.git FocusBear-MacApp-V2
cd FocusBear-MacApp-V2

pod install
open FocusBear.xcworkspace
```
- Always open the .xcworkspace, not the .xcodeproj.

---

## Issue 1: TweetNacl build errors (Data is only available in macOS 10.10 or newer)
### Error Messages
```text
Pods/TweetNacl/Sources/TweetNacl/TweetNacl.swift:22:35
'Data' is only available in macOS 10.10 or newer
```

### Root Causes
- V2 dependencies (Auth0 / PusherTweetNacl) implicitly require a higher macOS deployment target
- Building under macOS 10.15 caused Swift stdlib availability conflicts

### Resolution
- Resolved implicitly by raising the app deployment target to macOS 11 (see Issue 5 — this error disappears once the target is updated)
- No direct changes were made to TweetNacl or Podfile for this issue.

### Screenshots
- Terminal or Xcode build output showing TweetNacl compile failure

<img width="1234" height="619" alt="Image" src="https://github.com/user-attachments/assets/abc38fc6-3c15-4ae6-ad5f-1a0eae42a51a" />

---

## Issue 2: Sentry build failures (duplicate interface / module emit failure)
### Error Messages
```text
duplicate interface definition for class 'SentryEnvelopeItemHeader'
could not build Objective-C module 'Sentry'
```

### Root Causes
- Corrupted pod build artifacts
- Xcode cached precompiled modules conflicting with rebuilt Pods

### Resolution
- Hard reset Pods + Xcode caches
```text
osascript -e 'tell application "Xcode" to quit'
killall -9 Xcode 2>/dev/null || true
killall -9 com.apple.dt.Xcode.BuildService 2>/dev/null || true
killall -9 SourceKitService 2>/dev/null || true

rm -rf ~/Library/Developer/Xcode/DerivedData/SwiftExplicitPrecompiledModules
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/FocusBear-*

rm -rf Pods Podfile.lock
pod install

open FocusBear.xcworkspace
```

### Verification
- `pod install` completes cleanly
- Sentry target builds without errors

### Screenshots
- FocusBear V2 Debug Log — Sentry Interface Duplication & Precompiled Module Errors

<img width="293" height="296" alt="Image" src="https://github.com/user-attachments/assets/d1e116f0-5558-4f04-ba66-8f40547bfdfb" />

---

## Issue 3: No such module 'Sparkle'
### Error messages
```text
FocusBear/AppDelegate.swift:12:8
No such module 'Sparkle'
```

### Root Causes
- `Sparkle.framework` existed but **top-level framework structure was broken**
- `Headers`, `Modules`, `Resources`, etc. were **files instead of symlinks**
-  Confirmed via: `ls -la Sparkle.framework`

### Resolution
- Recreated the Sparkle framework symlink structure correctly.
```bash
# From the repository root
cd Sparkle.framework

rm -f Headers Modules PrivateHeaders Resources Sparkle Versions/Current
ln -s A Versions/Current
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/Modules Modules
ln -s Versions/Current/PrivateHeaders PrivateHeaders
ln -s Versions/Current/Resources Resources
ln -s Versions/Current/Sparkle Sparkle
```
- Then cleared derived data and reopened Xcode:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
open FocusBear.xcworkspace
```

### Verification
**Command executed**
```bash
ls -la Sparkle.framework
```

**Expected result**
- Symlinks are present and correctly pointing to Versions/Current/*
- Framework structure resolves to the active Sparkle version

### Outcome
- `import Sparkle` resolved correctly.
- Sparkle-related build errors disappeared.

### Screenshots
- FocusBear V2 Build Error — No Such Module ‘Sparkle’ in AppDelegate

<img width="231" height="73" alt="Image" src="https://github.com/user-attachments/assets/bd8044ad-812b-43bd-8312-47d516f2f6e1" />

- Sparkle Framework State — After Fix

<img width="724" height="195" alt="Image" src="https://github.com/user-attachments/assets/b6acec79-9e29-42a5-bb43-2e625e49aa8f" />

---

## Issue 4: Missing Swift Package products (Auth0, Swifter)
### Error messages
```text
Missing package product 'Auth0'
Missing package product 'Swifter'
```

### Root causes
- SwiftPM cache corruption
- Repo referencing non-existent Auth0 tag
- Package graph failing silently until build time
- Confirmed via: 
```text
git ls-remote --tags https://github.com/auth0/Auth0.swift.git | awk -F/ '{print $3}' | sort -V | tail -n 30

git ls-remote --tags https://github.com/auth0/Auth0.swift.git | grep -E "refs/tags/2\.9\.2$" || echo "2.9.2 tag does NOT exist"
# → tag does NOT exist
```

### Resolution
- Reset all SwiftPM caches
- Pin Auth0 to an existing version
- Resolve packages again
```text
osascript -e 'tell application "Xcode" to quit'
rm -rf ~/Library/Developer/Xcode/SourcePackages
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Developer/Xcode/ModuleCache.noindex
rm -rf FocusBear.xcworkspace/xcshareddata/swiftpm

open FocusBear.xcworkspace
```

In **Xcode**:
- File → Packages → Reset Package Caches
- File → Packages → Resolve Package Versions
- Set Auth0 to a real tag (e.g 2.8.1 or 2.9.0)

### Verification
- Auth0 and Swifter appear non-red in Package Dependencies
- Build proceeds past package resolution

### Screenshots
- Xcode Build Error: Missing Package Products (Auth0, Swifter)

<img width="296" height="124" alt="Image" src="https://github.com/user-attachments/assets/450d70bc-6b2b-4b1d-8ac2-ef44ec6a6757" />

- Xcode Package Dependencies (Auth0 & Swifter) — Current Settings

<img width="2048" height="672" alt="Image" src="https://github.com/user-attachments/assets/b477967c-cb74-4048-aed8-d4caaed1a7bc" />

- Terminal Verification: Auth0 Tag 2.9.2 Does Not Exist

<img width="1023" height="74" alt="Image" src="https://github.com/user-attachments/assets/c52df8ad-35a6-4f88-afb2-148d027b04a3" />

- Swift Package Resolution Reset and Auth0 Version Correction

<img width="972" height="254" alt="Image" src="https://github.com/user-attachments/assets/099954d6-a731-4d20-830c-ac9cc6a1ddf7" />

---

## Issue 5: Auth0 minimum deployment target mismatch (BLOCKING)
### Error messages
```text
Compiling for macOS 10.15,
but module 'Auth0' has a minimum deployment target of macOS 11.0
```

### Root causes
- Auth0 versions compatible with V2 require macOS 11+ regardless of Swift version.
- V2 cannot be built reliably on macOS 10.15

### Resolution
- Set V2 deployment target to macOS 11

**Xcode Steps**
- Select Focus Bear target
- Build Settings
- Set macOS Deployment Target → 11.0
- Clean build folder
- Build & Run (Debug)

### Verification
- Build succeeds
- App launches successfully
- **This is the final fix that unblocked V2 completely**

### Screenshots
- Build Successful After Aligning Deployment Target to macOS 11.0 Across Project and Targets

<img width="1266" height="768" alt="Image" src="https://github.com/user-attachments/assets/c0706206-e457-483c-8519-80eb317cb46e" />

---

## Final Working State
- Xcode 26.2
- Builds reliably from Xcode UI (CLI builds may depend on local cache state)
- SWIFT_ENABLE_EXPLICIT_MODULES = NO
- Sparkle framework symlinks fixed
- Auth0 + Swifter resolved
- App builds and launches successfully in Debug mode
- No TweetNacl / Sentry / Sparkle errors

### Required Conditions
- Deployment Target: macOS 11
- Workspace: FocusBear.xcworkspace
- Pods: Installed cleanly
- Sparkle: Correct symlink structure

---

## Notes for Future Contributors
- If you see `Unable to find module dependency: CTrueTime on Xcode 26`, check explicit module settings first.
- Do not attempt to fix this by downgrading TrueTime or editing module maps.
- Sparkle issues are usually filesystem-related, not CocoaPods-related. If Sparkle fails → verify framework symlinks. 
- If you hit Auth0 / TweetNacl errors → check deployment target first. 
- If Swift packages go red → reset caches fully (do not partially clean).

---

## Next Steps
- Continue development on Xcode 26 with the above settings.
- No need to switch Xcode versions unless explicit modules are required later.
- Packaging and notarisation can be handled separately once development stabilises.