# Plan: Talking Clock Feature (#1674)

**Issue:** https://github.com/Focus-Bear/Mac-App/issues/1674
**Author:** Monk of Modularity 🧘 (AI agent)
**Status:** Ready for Codebeard

## Summary

Add a "Talking Clock" feature that announces the current time via audio at configurable intervals. Requested by an ADHD coach — helps users stay time-aware without constantly checking the clock.

**Note:** A previous attempt by Devin (PR #1675) crashed when opening the settings page. This plan takes a simpler, more robust approach.

## Requirements (from issue)

1. Audio readout: "The time is now 12:30pm" at configurable intervals
2. Settings to enable/disable (disabled by default)
3. Configurable frequency (e.g., every 15, 30, 60 minutes)
4. Configurable quiet hours (times when it won't run)
5. Must NOT trigger during meetings

## Existing Patterns

- **TTS:** The app already uses macOS `say` command via `Process` in `globalFile.swift` (line ~634): `task.arguments = ["-c", "say \"\(text)\""]`. Follow this same pattern.
- **Settings storage:** `SettingsManager.swift` stores settings as properties and syncs to UserDefaults. Add new properties there.
- **Settings UI:** Settings pages live in `FocusBear/Preferences/Settings/`. The "advanced" subfolder contains add-on features like meeting detection.
- **Meeting detection:** `SettingsManagerObject.isMeetingDetectionEnabled` and the meeting-related focus mode logic in `AppDelegate.swift` can be checked to suppress clock announcements.
- **Timer pattern:** The app uses `Timer.scheduledTimer` extensively (see `habitsVc.swift` date timer pattern).

## Implementation Steps

### Step 1: Add Settings Properties to `SettingsManager.swift`

Add the following properties:

```swift
var isTalkingClockEnabled = false
var talkingClockIntervalMinutes = 30  // 15, 30, 60 options
var talkingClockQuietStartHour = 22   // 10 PM
var talkingClockQuietStartMinute = 0
var talkingClockQuietEndHour = 8      // 8 AM
var talkingClockQuietEndMinute = 0
var talkingClockSuppressDuringMeetings = true
```

Add corresponding UserDefaults keys in `allUserdefaults.swift`:

```swift
var kUserdefaultsTalkingClockEnabled = "kUserdefaultsTalkingClockEnabled"
var kUserdefaultsTalkingClockInterval = "kUserdefaultsTalkingClockInterval"
var kUserdefaultsTalkingClockQuietStart = "kUserdefaultsTalkingClockQuietStart"
var kUserdefaultsTalkingClockQuietEnd = "kUserdefaultsTalkingClockQuietEnd"
var kUserdefaultsTalkingClockSuppressMeetings = "kUserdefaultsTalkingClockSuppressMeetings"
```

Add load/save logic following the existing pattern in SettingsManager (see `saveAllSettingsInUserDefaults()` and the JSON parsing sections).

### Step 2: Create `TalkingClockManager.swift`

Create a new file `FocusBear/TalkingClockManager.swift`:

```swift
class TalkingClockManager {
    static let shared = TalkingClockManager()
    private var timer: Timer?

    func start() {
        stop()
        guard SettingsManagerObject.isTalkingClockEnabled else { return }
        let interval = TimeInterval(SettingsManagerObject.talkingClockIntervalMinutes * 60)
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(announceTime), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc func announceTime() {
        guard SettingsManagerObject.isTalkingClockEnabled else { stop(); return }
        guard !isInQuietHours() else { return }
        guard !shouldSuppressForMeeting() else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: Date())
        let text = "The time is now \(timeString)"

        let task = Process()
        task.arguments = ["-c", "say \"\(text)\""]
        task.launchPath = "/bin/zsh"
        task.standardInput = nil
        task.launch()
    }

    private func isInQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        let quietStart = SettingsManagerObject.talkingClockQuietStartHour * 60 + SettingsManagerObject.talkingClockQuietStartMinute
        let quietEnd = SettingsManagerObject.talkingClockQuietEndHour * 60 + SettingsManagerObject.talkingClockQuietEndMinute

        if quietStart <= quietEnd {
            return currentMinutes >= quietStart && currentMinutes < quietEnd
        } else {
            // Wraps midnight (e.g., 22:00 - 08:00)
            return currentMinutes >= quietStart || currentMinutes < quietEnd
        }
    }

    private func shouldSuppressForMeeting() -> Bool {
        guard SettingsManagerObject.talkingClockSuppressDuringMeetings else { return false }
        // Check if the current focus mode is the "Meetings" focus type
        // Use the same meeting detection as AppDelegate.swift
        return isMeetingsFocusStartedAutomatically
    }
}
```

### Step 3: Create Settings UI — `talkingClockSettingsVc.swift`

Create `FocusBear/Preferences/Settings/advanced/talkingClockSettingsVc.swift`:

- Toggle: Enable/Disable talking clock
- Popup button: Interval selection (15 min, 30 min, 60 min)
- Time pickers or hour/minute fields: Quiet hours start and end
- Checkbox: "Suppress during meetings" (default on)
- Wire up to SettingsManager, restart TalkingClockManager on changes

Create a corresponding `.xib` file or add to the existing advanced settings storyboard scene.

### Step 4: Add to Settings Sidebar

In `settingsSideBarVc.swift`, add a "Talking Clock" entry under the Advanced section so users can navigate to it.

### Step 5: Start/Stop in AppDelegate

In `AppDelegate.swift`:
- Call `TalkingClockManager.shared.start()` after settings are loaded (in `applicationDidFinishLaunching` or after login)
- Call `TalkingClockManager.shared.stop()` on app quit
- Restart the timer when settings change (interval, enable/disable)

### Step 6: Sync with Backend Settings JSON

If the backend settings JSON includes talking clock config, parse it in SettingsManager alongside existing settings. The configjson pattern (`configjson.value(forKey:)`) should include localizable strings for the UI.

## Files to Modify

| File | Change |
|------|--------|
| `FocusBear/SettingsManager.swift` | Add talking clock properties, load/save |
| `FocusBear/allUserdefaults.swift` | Add UserDefaults keys |
| `FocusBear/TalkingClockManager.swift` | **NEW** — Timer + TTS logic |
| `FocusBear/Preferences/Settings/advanced/talkingClockSettingsVc.swift` | **NEW** — Settings UI |
| `FocusBear/Preferences/Settings/settingsSideBarVc.swift` | Add sidebar entry |
| `FocusBear/AppDelegate.swift` | Start/stop manager |
| Storyboard/XIB | Add settings view scene |

## Edge Cases

- **Interval alignment:** Consider aligning announcements to clock boundaries (e.g., announce at :00 and :30, not 17 minutes after enabling)
- **System audio:** The `say` command uses system audio; if the user has audio muted, it's silent — this is expected behavior
- **Multiple timers:** Ensure `start()` always calls `stop()` first to avoid duplicate timers
- **App sleep/wake:** Timer may drift after sleep; consider re-syncing on `NSWorkspace.didWakeNotification`

## Testing

1. Enable talking clock → verify announcement at next interval
2. Set quiet hours → verify no announcement during quiet period
3. Start a meeting focus mode → verify no announcement
4. Change interval → verify timer resets
5. Disable → verify no more announcements
6. Verify settings page does NOT crash (Devin's bug)
