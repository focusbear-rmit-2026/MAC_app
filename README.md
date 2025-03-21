## BLOCKED PAGE PARAMETERS Details (macOS app)

### Example URL (Always-Blocked)

```
file:///Users/prashant/Library/Application%20Support/com.App.EarnYourScreentime/focus-block.html?old_url=https%3A%2F%2Fwww.facebook.com%2F&block_type=always-blocked&block_mode=cuddly&encouraging_info=%7B%0A%20%20%22long_term_goals%22%20%3A%20%5B%0A%20%20%20%20%22Meditate%20consistently%22%0A%20%20%5D,%0A%20%20%22focused_time%22%20%3A%201799.992%0A%7D&version=1.20.351
```

### Common Parameters

- `&version=1.20.351`
- `&encouraging_info`
- `&old_url`

### Always-Blocked URL Parameters

- `&block_type=always-blocked`
- `&block_mode="cuddly" / "grizzly"`
- If `shouldShowTour`:
  - `&show_tour=true`
- If `isRunningAppFullScreen` || `isStageManagerEnabled`:
  - `&confirm_ai_distracting_url=true`

### Focus Mode Parameters

- `&focus_mode_end_time=Time`
- `&focus_mode=focusMode`
- `&focus_mode_intention=intention`
- If `currentFocusModeStrictness != .SUPER_STRICT`:
  - `&cuddly_bear_mode=true`
  - `&reason=AIREASON`

### Focus Mode + Always-Blocked URL

- `&focus_mode_end_time=Time`
- `&focus_mode=focusMode`
- `&focus_mode_intention=intention`
- If `currentFocusModeStrictness != .SUPER_STRICT`:
  - `&cuddly_bear_mode=true`
  - `&reason="xx"`

### When Habit is Running

- `&block_type="morning-habit" / "evening-habit" / "special-activity"`

### When Habit with Focus Mode is Running

- `&block_type="morning-habit" / "evening-habit" / "special-activity"`
- If `settings.cuddly_mode` is enabled:
  - `&cuddly_bear_mode=true`
  - `&reason=AIREASON`

### When Habit with Focus Mode is Running and URL is Always-Blocked

- If `isCurrentUrlAllowedInFocusMode`:
  - If `isAnyAllowedFocusModeActivityRunning(habit_focusmode) == true`:
    - `&block_type="morning-habit" / "evening-habit" / "special-activity"`
    - `&block_mode="cuddly" / "grizzly"`
    - If `currentFocusModeStrictness != .SUPER_STRICT`:
      - `&cuddly_bear_mode=true`
      - `&reason="xx"`
  - Else (Normal Focus Mode Running):
    - `&focus_mode_end_time=Time`
    - `&focus_mode=focusMode`
    - `&focus_mode_intention=intention`
    - If `currentFocusModeStrictness != .SUPER_STRICT`:
      - `&cuddly_bear_mode=true`
      - `&reason="xx"`
- Else:
  - `&block_type=always-blocked`
  - `&block_mode="cuddly" / "grizzly"`
  - If `shouldShowTour`:
    - `&show_tour=true`
   
Other documentation can follow below.
