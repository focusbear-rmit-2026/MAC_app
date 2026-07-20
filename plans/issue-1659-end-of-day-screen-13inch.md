# PLAN: End of Day Screen Looks Bad on 13 Inch MacBook

**Issue:** Focus-Bear/Mac-App#1659  
**Labels:** good first issue  
**Branch:** `plan/issue-1659`

## Context

On a 13-inch MacBook, the end-of-focus-session summary screen has a layout issue where the **time of day label overlaps the focus mode name**. The screen is `focusSummaryVc` (and possibly `focusCompletedVc`), which already has one width-based adjustment at `view.frame.width < 1100` — but this threshold doesn't account for smaller MacBook windows.

A 13-inch MacBook typically renders the app window at around 1280px logical width, which is above the 1100px threshold but still too narrow for the current label layout.

## Root Cause (Hypothesis)

In `FocusBear/Focus mode/focusSummaryVc.swift`, the `widthScrollViewFocusSummary` constraint is set to 900 or 1000 based on a `< 1100` check. However, the labels for time and focus mode name are likely positioned in a horizontal stack or with overlapping frames in the storyboard, with no adaptive sizing for the 1280–1400px window range.

The fix is likely one or more of:
1. Adjusting the width breakpoint to cover 13-inch screens (~1280px)
2. Setting the two labels to stack vertically when horizontal space is insufficient
3. Reducing font size or truncating the focus mode name at shorter widths

## Files to Modify

| File | Change |
|------|--------|
| `FocusBear/Focus mode/focusSummaryVc.swift` | Add additional layout adjustment for narrow widths (1100–1400px range) |
| `FocusBear/Focus mode/focusCompletedVc.swift` | Check if same overlap occurs here; apply same fix pattern if needed |
| Storyboard / XIB for `focusSummaryVc` | Adjust Auto Layout constraints: set label line break to truncate tail or use a vertical stack for time + focus mode name on small widths |

## Proposed Fix Approach

### Option A — Code-Based (Preferred for Quick Fix)

In `focusSummaryVc.viewDidAppear` / `viewDidLayout`:
```swift
let windowWidth = self.view.frame.width
if windowWidth < 1300 {
    // Reduce scroll view width further so labels don't crowd
    widthScrollViewFocusSummary.constant = 800
} else if windowWidth < 1100 {
    widthScrollViewFocusSummary.constant = 900
} else {
    widthScrollViewFocusSummary.constant = 1000
}
```

Also ensure that `lblTitle` (focus mode name) and any time-of-day label use `.truncatingTail` line break mode and their constraints don't allow horizontal overflow.

### Option B — Storyboard-Based

In the storyboard/XIB:
- Convert the horizontal arrangement of "time" and "focus mode name" into an `NSStackView` with `.fillEqually` or `.fillProportionally` distribution
- Set minimum width constraints to prevent overlap
- Enable `lineBreakMode = .byTruncatingTail` on the focus mode name label

## Acceptance Criteria

- [ ] On a 13-inch MacBook (window width ~1280px), no labels overlap on the end-of-day/focus summary screen
- [ ] On larger screens (1440px+), existing layout is unchanged
- [ ] Focus mode name truncates gracefully if the name is long
- [ ] Time of day is always fully readable
- [ ] Fix tested at window widths: 1280, 1440, 1680, 1920px

## Notes

- This is a **good first issue** — the fix is isolated to layout constraints and a small code change in one VC
- No backend changes required
- No new dependencies
