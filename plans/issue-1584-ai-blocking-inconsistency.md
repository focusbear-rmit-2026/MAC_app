# Plan: AI Blocking Works Inconsistently Across Daily Blocks and Focus Blocks (Fixes #1584)

**Issue:** #1584 — AI blocking activates ~50% of the time regardless of block type  
**Repo:** Focus-Bear/Mac-App  
**Filed by:** Monk of Modularity 🧘  
**Status:** Planning

---

## Problem Summary

AI-based URL blocking (the "cuddly mode" that uses OpenAI to decide if a site is relevant to the user's focus) activates approximately 50% of the time. The failure rate is the same for both **daily blocking schedules** (`customBlockingSchedule` with `isAIBlockingEnabled = true`) and **focus blocks** (`currentRunningFocusType["is_ai_enabled"] = true`). This points to a **non-deterministic code path** shared by both block types rather than a bug in one type's configuration logic.

---

## Current `isAIBlockingEnabled()` Logic

```swift
// SettingsManager.swift
func isAIBlockingEnabled() -> Bool {
    if customBlockingScheduleManagerObj.isAnyCustomScheduleOn {
        return customBlockingScheduleManagerObj.isAIBlockingEnabled()
    }
    if isFocusModeOnOrPaused() {
        if let isAiEnabled = currentRunningFocusType["is_ai_enabled"] as? Bool {
            if !isAiEnabled {
                return false
            }
        }
    }
    return isAiCheckUrlEnabled
}
```

The function has three exit paths:
1. **Custom schedule active** → delegates to `customBlockingScheduleManager.isAIBlockingEnabled()`, which iterates `arrBlockingSchedule` and returns the first `.on` schedule's `isAIBlockingEnabled` flag
2. **Focus mode on/paused** → returns `false` only if the focus type explicitly has `is_ai_enabled = false`; otherwise falls through to…
3. **Global setting** → returns `isAiCheckUrlEnabled` (user's global AI toggle)

### Key Race Condition Hypothesis

The `~50%` activation rate is a classic symptom of a **race condition or ordering issue**. Candidates:

| Candidate | Why 50%? |
|---|---|
| `customBlockingScheduleManagerObj.isAnyCustomScheduleOn` is read on the main thread, but mutated from a background timer | Non-atomic read/write → sometimes stale |
| `arrBlockingSchedule` is mutated (schedule loaded from API) while `isAIBlockingEnabled()` is iterating it | Array mutation mid-iteration → sometimes hits wrong schedule or crashes silently |
| `currentRunningFocusType["is_ai_enabled"]` is populated asynchronously after the URL check begins | URL is checked before the focus type finishes loading → falls through to global setting, which may be off |
| The URL check fires on a background thread that captures a stale copy of `isAnyCustomScheduleOn` | Swift global `var` (non-actor-isolated) race |

---

## Investigation Plan

### Step 1 — Add Logging to `isAIBlockingEnabled()`

Before fixing, instrument the function to understand when it returns false unexpectedly:

```swift
func isAIBlockingEnabled() -> Bool {
    let customScheduleOn = customBlockingScheduleManagerObj.isAnyCustomScheduleOn
    let focusModeOn = isFocusModeOnOrPaused()
    
    addLog(text: "isAIBlockingEnabled: customScheduleOn=\(customScheduleOn), focusModeOn=\(focusModeOn), isAiCheckUrlEnabled=\(isAiCheckUrlEnabled)")
    
    if customScheduleOn {
        let result = customBlockingScheduleManagerObj.isAIBlockingEnabled()
        addLog(text: "isAIBlockingEnabled: custom schedule path → \(result)")
        return result
    }
    if focusModeOn {
        let isAiEnabled = currentRunningFocusType["is_ai_enabled"] as? Bool
        addLog(text: "isAIBlockingEnabled: focus mode path → is_ai_enabled=\(String(describing: isAiEnabled))")
        if let isAiEnabled, !isAiEnabled { return false }
    }
    addLog(text: "isAIBlockingEnabled: global setting path → \(isAiCheckUrlEnabled)")
    return isAiCheckUrlEnabled
}
```

Deploy a debug build and reproduce the 50% failure. Check logs for which path is taken on failing calls.

### Step 2 — Check Thread Safety

In `customBlockingScheduleData.swift`:

```swift
class customBlockingScheduleManager {
    var isAnyCustomScheduleOn = false  // ← non-thread-safe plain var
    var arrBlockingSchedule = [customBlockingSchedule]()  // ← non-thread-safe array
    
    func isAIBlockingEnabled() -> Bool {
        if isAnyCustomScheduleOn {
            for schedule in arrBlockingSchedule {  // ← if arrBlockingSchedule is mutated here, undefined behaviour
                if schedule.state == .on {
                    return schedule.isAIBlockingEnabled
                }
            }
        }
        return false
    }
}
```

Check whether `arrBlockingSchedule` is ever written from a different thread than it's read.

Also check `focusModeData.swift` for `currentRunningFocusType` — it's a global `var` updated when a focus session starts. If a URL check fires between the focus session starting and `currentRunningFocusType` being populated, `is_ai_enabled` will be nil and the check will fall through to `isAiCheckUrlEnabled`.

### Step 3 — Check the URL Check Call Site

Find where `isAIBlockingEnabled()` is called relative to the URL navigation event. There may be a timing window where the browser navigation event fires before the blocking state is fully initialised.

Likely locations to check:
- `AppBlockingHelper.swift` — app-level blocking
- `allBrowsers.swift` → `getActiveTabUrlForBlocking()` → block URL logic
- `customBlockingScheduleData.swift` → schedule activation path

---

## Fix Plan

### Fix A — Make `customBlockingScheduleManager` Thread-Safe

Wrap all reads and writes to `isAnyCustomScheduleOn` and `arrBlockingSchedule` in a serial `DispatchQueue`:

```swift
class customBlockingScheduleManager {
    private let queue = DispatchQueue(label: "com.focusbear.blockingScheduleManager")
    private var _isAnyCustomScheduleOn = false
    private var _arrBlockingSchedule = [customBlockingSchedule]()
    
    var isAnyCustomScheduleOn: Bool {
        queue.sync { _isAnyCustomScheduleOn }
    }
    
    func setScheduleOn(_ on: Bool) {
        queue.sync { _isAnyCustomScheduleOn = on }
    }
    
    func isAIBlockingEnabled() -> Bool {
        queue.sync {
            guard _isAnyCustomScheduleOn else { return false }
            return _arrBlockingSchedule.first(where: { $0.state == .on })?.isAIBlockingEnabled ?? false
        }
    }
}
```

### Fix B — Guard Against Stale `currentRunningFocusType`

In `SettingsManager.isAIBlockingEnabled()`, add a guard that checks whether the focus type has finished loading before reading `is_ai_enabled`:

```swift
if isFocusModeOnOrPaused() {
    guard !currentRunningFocusType.isEmpty else {
        // Focus type still loading — default to safe (AI off) rather than falling through
        addLog(text: "isAIBlockingEnabled: focus type not yet loaded — returning false to be safe")
        return false
    }
    // ... existing is_ai_enabled check
}
```

### Fix C — Make Custom Schedule State Consistent at URL-Check Time

Ensure that when a custom schedule activates, all state variables are set atomically before the URL-check timer begins firing. In the activation path of `customBlockingScheduleManager`, ensure `isAnyCustomScheduleOn = true` is set **after** `arrBlockingSchedule` is fully populated.

---

## Files to Change

| File | Change |
|---|---|
| `FocusBear/SettingsManager.swift` | Add logging to `isAIBlockingEnabled()`; add guard for empty `currentRunningFocusType` |
| `FocusBear/Focus mode/customBlockingScheduleData.swift` | Add thread-safety wrapper (`DispatchQueue`) around `isAnyCustomScheduleOn` and `arrBlockingSchedule`; fix ordering in activation path |
| `FocusBear/Focus mode/focusModeData.swift` | Add guard on `currentRunningFocusType` population; ensure `is_ai_enabled` is set before URL monitoring starts |
| `FocusBearTests/AppBlockingTests.swift` | Add tests: AI enabled + custom schedule on/off; AI enabled + focus mode starting (race condition simulation) |

---

## Edge Cases

- **Schedule paused (not off):** `isAnyCustomSchedulePaused = true` — should AI still apply? Check whether pausing a schedule should disable AI blocking too.
- **Focus mode transition:** User starts/ends a focus session rapidly. State can be in a transient half-initialised state.
- **Two overlapping schedules:** `isAIBlockingEnabled()` in the manager returns the first `.on` schedule. What if there are two `.on` schedules with different AI settings? Use explicit priority ordering or `AND` the settings.
- **First launch / cold start:** `isAnyCustomScheduleOn` defaults to `false`. Ensure this default doesn't cause a schedule to be skipped when the app launches mid-schedule.
- **App resume from sleep:** `checkNaturalBreakFromIdleTimeAfterScreenUnlocked()` is called on wake. Ensure schedule state is re-evaluated before URL checks resume.

---

## Testing Approach

1. **Unit tests** in `FocusBearTests/AppBlockingTests.swift`:
   - Test `isAIBlockingEnabled()` with `isAnyCustomScheduleOn = true` + `isAIBlockingEnabled = true` → must return `true` 100% of calls
   - Test with focus mode `is_ai_enabled = false` → must return `false`
   - Test with focus mode `is_ai_enabled = nil` (loading) → must not return `true` unexpectedly
2. **Stress test:** Call `isAIBlockingEnabled()` 1000 times from concurrent threads while a schedule is being mutated on another thread → verify no data race with Thread Sanitizer (TSan)

---

*Monk of Modularity 🧘 — plan drafted for Codebeard implementation.*
