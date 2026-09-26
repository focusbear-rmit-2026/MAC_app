
# v3.32.488
Habits UI improvements #1819 (Show habit list if habits are postponed #1749) 
All days will be default checked when creating a new blockign schedule 
Focus session micro breaks on off setting persisted and synced

# v3.32.489
Do Not Distueb feature while in focus sessions implemented 
Minor enhancements in the Focus Button focus events (Set habits still not working) 
Fixed Auto start focus mode feature not working
Added feature to let people edit habits at the start of their routine

# v3.32.490
Fix for Focus mode end time - actual duration to be stored and also the end time if current time is more than 24 hrs + end time, cancel it, else resume it 
Remove check box from advanced for specific focus modes 
Browser tab limiter fails to block user after exceeding set limit 
Enhancement: Block notifications in Deep Work + Block super distracting sites 
Minor enhancement in DND functionality 
Fix for: if Mac goes to sleep during allowed app activity, it forgets that it's in an allowed app activity

# v3.32.491
Bug Fixed: All Core Features Disabled After Reinstall ("Disabled because your all-day summary is visible") 
Meeting detection false positive due to dictation Fixed 
Remove 15 second countdown if you skip and choose "Can't do it" unless the user has selected high friction #311 (failed case addressed, popup shown for timer where required like skipping from list of habits while postponed) 
Focus session is not triggered automatically (work done for apps, it was for URLs only, text in settings adjusted) 
Enhanced Identify the chat title with Claude and pass that to FBTT and AI (tab title for API now added to app name "claude - tab title") 


# v3.33.492
Focus sessions now start automatically at their scheduled time, instead of waiting for a manual start.
Blocked-app notifications now appear in Deep Work and "block super-distracting sites" mode, so you're told when an app is blocked.
Fixed the "I don't have time for all these habits" option not responding during morning and evening routines.
Onboarding wording and flow improvements.


# v3.33.493
Wind Down: clearer messaging when a computer shutoff is aborted ("your computer is now accessible again").
You can now change your email address from the "Report a problem" tab in Help.
Fixed the to-do list sometimes not loading all of your tasks.
Fixed a crash when editing habits while in full-screen mode.
The strictness-level selector now explains each level in more detail.
The focus countdown timer now stays hidden for the first 30 seconds of a session.


# v3.33.494
Fixed the active routine screen going blank and unresponsive after switching to another tab and back.
Fixed "Uncancel my evening routine" wrongly appearing in the morning-routine flow, and added clearer feedback when you restore it.
Added a loading indicator so the routine-suggestion view finishes loading before it moves on.
Fixed views not rendering correctly after the app was minimized (e.g. when Alt-clicking another app).
Updated Focus Button firmware support (matching the Windows app) so it works reliably with habits.


# v3.33.495
New break reminder with a press-and-hold "postpone" control, so a long postpone can't be picked by accident.
Fixed the postpone buttons not always registering clicks, plus a related break-timer glitch.
Fixed "Tools" in the menu not opening.
Behind-the-scenes: app blocking and Focus Button connection now run off the main thread so the app stays responsive.


# v3.33.496
Focus Button: more reliable connecting/signalling, and it now stops the device when a running habit is skipped or postponed.
You're no longer logged out unexpectedly — access-token renewal is handled automatically.

# v3.33.497
Fixed the evening-routine reminder reappearing shortly after you dismissed it.
Broader blocking/validation coverage behind the scenes to catch more edge cases (no visible change).

# v3.34.498
New Schedule view — see your habits and calendar on one timetable.
Day Plan is now a single task list with a time-boxed clock badge.
Kept your typed focus goal when switching block lists, and Focus Bear now remembers your last block list.
Fixed offline activity completions being lost after the first re-sync.
Fixed a couple of crashes in the habit-start flow.

# v3.34.499
Focus Button: forwards Late No More notifications (with a beep on audio alerts), adds firmware version + update check and a Flash Firmware button, and re-syncs the habit countdown to the device so it can't drift.
Break windows are taller with a reworded end message, and the break interval only resets on a real break or postpone.
Signal the Focus Button when a session is started from your phone.


# v3.34.500
Per-schedule emoji — custom blocking schedules now show the emoji you set on the backend.
Focus Button auto-reconnects after an accidental disconnect, so Late No More and habit signals keep working.
Fixed a crash when finishing a habit, and cleared leftover "postponed routine" state on completion.
Postponing now always requires your password when a full-screen routine is showing (no grace-period gap).


# v3.34.501
Blocking schedules redesigned — a cleaner list, calendar, presets and editor.
New Office Mode settings — a direct toggle plus automatic switching based on your Wi-Fi network.
New inline focus starter in the menu — set duration, intention and block list without leaving the menu.
Fixed an AppleScript crash caused by overlapping browser scripts.


# v3.35.502
- fix(fullscreen): minimise behaviour — release secondary monitors + don't skip postpone on a stale allowed-activity flag#2050
- fix(ui): taller small window so the habit-finished screen isn't clipped#2051
- feat(day-plan): Show dismissed events (strikethrough + eyes to restore)#2049
- [Tested By Human] Display leaderboard username in Account settings (Clean #1745 PR Version)#1856
- Reconcile mega → main: land the stranded Day Plan / voice / password fixes (+ pointer-model task-sync) #2042
- fix(perf): cap AppleScript wait on the main thread so it can't freeze the UI (7s → ~1.2s) #2045
- chore: delete dead thirdVc.swift (4,500-line duplicate)#2030
- fix(security): stop logging tokens/PII; notarization creds from env vars#2029 
- fix(routines): weekend/weekday scheduling never handled Sunday#2027
- docs: ARCHITECTURE.md + TECH_DEBT.md from full-codebase audit#2026
- ci: run ScheduleKitTests in the unit-test workflow#2032
- fix(focus-button): open the menu in listening state on a device mic press#2025
- fix: sharp Bear-Small icon (add 2x/3x retina) — #2015#2018
- fix(build): signing/scheme hygiene — xcconfig-respecting DEVELOPMENT_TEAM, derived App Group prefix, Debug test action#2017
- fix(dayplan): keep Custom Routines panel available in full-screen#2006
- feat(focus-button): manual Disconnect + external command channel (#1947)#2008
- fix: browser-detection AppleScript freezing the main thread (blank Day Plan / AppHang / crash)#2009
- fix(dayplan): stop midnight rollover recursing until the stack overflows (crash)#2001
- feat(dayplan): collapse deep-work sessions into an accordion#2002
- WIP feat(dayplan): keep morning routine visible when done — hand-off for review (#2005)#2012


# v3.35.503
- fix(postpone): AskPostpone invisible on SwiftUI screens — present as sheet#2048
- fix(#1330): remove the red border box on the deactivated menu-bar sta…#2058
- fix(onboarding+menu): fix Accessibility "Open settings" link layout; …#2061
- fix(#2054): Day Plan Play/Skip/Done work in postponed Focus Summary +…#2062 (Fixes:Play, Skip, and Done buttons are unresponsive in the Day Plan during a postponed Focus Summary #2054)
- feat(day-plan): confirm before cancelling the routine from the ✕ (skip routine for today)#2063 (Fixes: When habits are postponed and the user clicks Skip Habits from the Day Plan view, the Choose Habits panel is displayed, but it contains 0 habits.#2046)
- fix(day-plan): completed morning renders read-only (dead Play/Skip/Done when morning done, pre-shutoff)2064
- fix(day-plan): cancel from ✕ closes the window again for an in-progress routine #2066
- fix(#2013): menu bar stops showing a morning habit after the routine is completed #2067 (Fixes: Menu bar still shows the next Morning Routine habit after the routine is completed #2013)


# v3.35.504
- fix(appointment-reminder): ignore stale event-about-to-start triggers#2074
- fix(day-plan): fall back to showHabitState() when no branch matches#2076
- feat(focus-button): firmware version + update check, always-visible icon sync status, hide buy pitch when connected#2073
- fix(day-plan): Return in task-details modal no longer starts the next habit#2072
- fix(webview): show loading spinner while Todo List/Stats dashboards load#2071
- fix(focus-modes): default new block lists to auto-suggest starting focus mode#2069
- fix(focus-mode): gate app auto-suggest on isAllowedAllApps, not the URL allowlist flag#2077
- fix(dayplan-mockup): resolve Auto Layout ambiguity that left card titles blank#2068
- [READY-FOR-REVIEW] feat: Refactor Brain Dump to always use webview notes URL#1851


# v3.35.505
- feat: Teacher Mode — join-prompted, teacher-locked class focus sessions#1987
- feat(time-tracker): move the Enable toggle from Add-Ons into the Time Tracker view (#2080)#2082
- Focus-Bear/Mac-App] [Tested By Human] test: add unit tests for customBlockingSchedule logic (PR #1882)


# v3.35.506
- fix(teacher-mode): don't let URL blocking wait for the next app-switch event#2092
- feat(teacher): suppress and defer routines/breaks while a class session#2095
- feat(teacher): auto-open a URL on the block page once the teacher unlocks#2096
- feat(teacher): auto-resume the postponed routine when the class session ends#2097
- feat(focus-mode): glowing screen-edge border while a focus session runs#2089


# v3.35.507
- perf(dayplan): skip full re-render while the schedule host's view is hidden#2099
- fix(menu): remove collapsible MAIN section label from sidebar#2084
- feat(menu): hover-to-hide TOOLS rows, gear icon to restore#2085
- feat(focus-music): prompt to play music right after a focus session starts#2088
- fix(focus-music): sync the remembered prompt choice to the server immediately#2101
- fix(latenomore): honour postpone-after-cutoff password rule on all shutoff unlock buttons#2087
- fix(latenomore): honour postpone (not skip) password settings in the appointment popup#2100
- fix(strictness): show the missing Postpone password checkboxes (+ info buttons, scroll-to-top)#2102
- fix(focus-button): line buffering, usbserial, and dynamic focus goals#2057


# v3.35.508
- fix(day-plan): Done button not restored after cancelling the password prompt#2104
- fix(menu): refresh the MenuView Day Plan on routine cancel/uncancel#2105       
- feat(menu): show trial / expired subscription status in the MenuView popover#2108
- [READY-FOR-REVIEW] Talking clock feature (#1674)#1771
- fix(talking-clock): sync settings to account, native back bar, toggle layout + cross-account leak#2110



# v3.35.509
- Released update for 508 / Release notes shared with Beverly
- fix: browser-tab AppleScript freezing main thread at routine start (beachball)#2111
- fix(security): use UTF-16 length for NSMakeRange in tag editors#2109
- fix(dayplan): reserve real scroll headroom so the last task's action buttons are reachable#2107
- fix(latenomore): auto-close the appointment popup at meeting end time#2106
- [READY FOR HUMAN REVIEW] End of day screen looks bad on 13 inch MacBook#1714 (Fixes: End of day screen looks bad on 13 inch macbook #1659)
- fix(distracting-time): measure actual time on super-distracting sites via poll (#1302)#2119


# v3.35.510
FEATURES SHIPPED
----------------
- Focus Music rewrite (#2086)
  SwiftUI rewrite, Spotify links section, YouTube Music support, unified
  "Now Playing" card. Resolved a large merge with main, including porting a
  "resume last played / stop prompt-started music" feature that the rewrite
  had dropped.

- To Do Player rewrite (#2113)
  SwiftUI rewrite with a now-playing focus-music bar; real Spotify/YouTube
  track names via oEmbed instead of raw URLs.

- Cross-device pause/resume sync (#2131)
  Mac now sends pause/resume to the backend and reacts to focus-mode-paused
  and focus-mode-resumed from other devices; also reads session strictness
  and already-paused state. Items 1-3 of FOCUS_SESSION_SYNC.md section 6.

- Talking Clock settings (#2110)
  Reused the native storyboard back bar, switch-style toggles, aligned
  quiet-hours fields, and made the settings sync to the user's account
  (they were device-local). Also fixed a cross-account leak on logout.

- Accurate distracting-site time (#2119, issue #1302)
  Replaced "count the time you asked for" with a stopwatch that credits the
  real elapsed time measured from the URL poll.


BUG FIXES
---------
- Launch freeze (#2126)
  Reviewed the Keychain canRenew() fix and removed a redundant background
  dispatch - that code was already off the main thread.

- Skip-habit button order (#2127, issue #1177)
  Primary button moved to the right on two screens.

- Focus-completed crash hardening (#2128, issue #1948)
  loadView() changed to .view. Flagged honestly as unreproduced, not a
  confirmed fix.

- Day Plan tab not selected (#2130)
  Menu "View full day plan" now highlights the Day Plan sidebar row.

- Five fixes found during testing of #2086:
    * Add-only link validation - no phantom warnings, no focus jumping
      between the URL fields
    * Animated wave GIF restored, at its correct size
    * Hand cursor and full-area clicks on all buttons
    * No music prompt or hijack when something is already playing



# v3.35.511
Spotify playback (fix/spotify-play-off-main-thread)
	•	Diagnosed why Spotify didn't play on the first launch: a cold-launch race — a still-loading Spotify silently accepts play track without acting on it.
	•	Fixed by looping the AppleScript until Spotify is actually playing (re-issuing play track, off-main, 35s timeout). Verified via /tmp log it was a timing race, not a permission error. Committed + pushed (b76a770).
Meeting-app AppHang (fix/meeting-app-detect-main-thread-hang, PR #2133)
	•	Reworked the fix to a single utility-queue block (removed the redundant global→global double-dispatch); the blocking NSRunningApplication.bundleURL LaunchServices reads now run off-main in one hop. Confirmed reading runningApplications off-main is safe. Amended + force-pushed (45b522c).
Sync-error copy (fix/sync-error-copy, PR #2122)
	•	Found local config-es.json still had the old Spanish wording; updated it to match the new English, copied verbatim from the assets repo. Confirmed all four sources (local + assets, EN + ES) now consistent. Committed + pushed (c9f9b9f).
Brain-dump webview bridge (feat/braindump-webview-user-specific-sync, PR #2142)
	•	Wired the two-way bridge (send_brain_dump_content receive + syncWithDevices({ brainDump }) push) so the brain dump becomes user-specific. Committed + pushed (7839735).
	•	Via a JS probe, proved the Mac side is fully wired but the /webview/notes bundle never posts send_brain_dump_content — a web-side gap.

# v3.35.512
New:
Pause and resume a focus session right from the menu bar — not just stop it.
Pause and play your focus music using your Mac's play/pause key.
Calendar events in your Day Plan now show who's accepted, declined, or is tentative.
Snooze Day Plan tasks to earlier days, and pick a #project straight from the keyboard as you type.
Improvements & fixes:
Skip and Postpone now work correctly for a habit running in the background.
If you've had breaks switched off for a couple of days, Focus Bear now checks in to help you set a break frequency that suits you.
AI-suggested tasks no longer show up as duplicates.
The Day Plan no longer briefly shows out-of-date task status when it first loads.
Fixed the focus-icon sync spinner getting stuck.
Fixed a couple of crashes that could happen with network changes and when your Mac went to sleep.


# v3.35.513
New:
Learn your shortcuts: when you open something from the menu that has a keyboard shortcut (Focus Music, Brain Dump, To-Do Player), a quick tip now shows you the shortcut to use next time.
Routine window, your way: if you move the routine window aside while a routine is running, Focus Bear now asks whether you'd like to postpone — instead of silently snapping it back.
Focus Button: default focus icons now sync automatically the first time you connect, so a focus session shows an icon with no setup needed.
Improvements & fixes:
Break activity videos no longer play sound into your meetings.
Connecting your calendar when no calendar account is set up now explains what to do, instead of appearing to do nothing.
A single bad custom blocking schedule no longer causes all of your blocking schedules to disappear.
Hiding Deep Work blocks in your Day Plan now also hides their break slots, for a cleaner plan.
The breaks menu message now wraps onto a second line instead of getting cut off.
Fixed a rare startup crash related to focus modes.


# v3.35.514
Break videos resume after meetings — if a meeting is detected during a break, your break video now automatically resumes once the meeting ends, instead of staying paused for the rest of the break.
Reliable sync after sleep — real-time sync (habits/focus sessions started on your other devices) now reconnects properly after your Mac wakes from sleep, and a related crash on sleep or network drop has been fixed.
Focus Music playlist names — YouTube playlists that used to show a generic "YouTube playlist" label (auto-mixes and some unlisted playlists) now display their real title.
Custom blocking schedules — fixed a rare crash when starting or deleting a schedule, and the pause countdown now stops cleanly when you dismiss it.
Better crash diagnostics (behind the scenes) — crash and app-hang reports now include the info needed to pinpoint the cause, so we can fix issues faster (no visible change for you).
Analytics reliability (behind the scenes) — corrected where usage events are sent so they record correctly (no visible change for you).

# v3.35.515
Day Plan stays in sync across devices — tasks you complete on your phone or another computer now update right away in the "Tasks for today" panel, without switching days and back.
Clearer menu buttons — every button in the redesigned menu now shows a hand pointer on hover, so it's obvious what's clickable.
Fewer freezes — fixed a hang caused by custom routines building up unbounded state.



# v3.35.516
Unlock Computer fix — the Habits screen no longer shows up blank after you unlock your computer from the Wind Down screen.
Evening routine on the Day Plan — once you've finished your evening routine, the Day Plan now shows it properly: completed habits crossed off, with a quick "Complete" option for any you still want to tick off.
Calendar & mic permissions — "Grant access" for your calendar now works in the installed app (previously it did nothing), and microphone access is fixed too.
Hold-to-set evening postpone — postponing your evening routine now uses a press-and-hold control: the longer you hold, the longer the postpone, so a long one can't be picked by accident.
Smarter Focus Mode prompts — Focus Bear won't suggest starting Focus Mode when a super-strict blocking schedule is already running.
"Habits postponed until…" in the menu — the Day Plan menu now shows the time your habits are postponed until (available in English and Spanish).
Tidier habit controls — removed action buttons that could appear on a habit when there was nothing to act on.




# v3.35.517

Day Plan tasks sync across your devices — tasks you add, plan onto your schedule, or rename in "Tasks for today" now show up on your other devices (and a rename made elsewhere updates here too).
Evening routine updates instantly — uncancelling your evening routine now refreshes the Day Plan right away, without closing and reopening the menu.
Office Mode stays on — it no longer silently switches itself back off when you have no office-friendly break activities; instead it offers to add one.
Clearer focus-session info during "block super-distracting sites" — the message now correctly reads "AI not applicable," and your focus score shows in the menu and To-Do Player, not just the nudge.
Keyboard-shortcut tips — using the Advanced focus button now shows its shortcut tip, and these tips appear on top of the menu instead of behind it.
Tidier Day Plan header — the "+ Add event" button and date arrows no longer overlap the Habit Player / Day Plan tabs.


# v3.35.518
Brain Dump opens reliably from the menu — opening Brain Dump from the menu right after launching the app no longer shows a blank page; it now loads correctly the first time.
Cleaner "Start a break now" in the menu — the menu only shows "Start a break now" when a break can actually be started. It now stays hidden during routines, shut-off time, or when there are no break activities, instead of always appearing.
Clearer keyboard-shortcut label — the "Start focus session" shortcut is now labeled "Open Focus Session", since pressing it opens the Start Focus screen rather than immediately starting a session (matches the other "Open …" shortcut labels).
Focus Summary no longer keeps reappearing — if you cancel your evening routine from the Day Plan, the Focus Summary is now marked as done too, so it won't pop up again and again (even after you've postponed it).
Menu Day Plan shows the right habits and updates live — during a routine the menu now shows your current habit and the next one correctly (no more showing the same habit twice, and no stray "Start" button). When you're between routines it shows when your next routine starts (e.g. "🌅 Morning routine starts at 7:00 AM"), and the Day Plan now refreshes on its own as you postpone, resume, or start habits — no need to close and reopen the menu.


# v3.35.519
Your Focus Goal is always visible in the menu — the menu's focus-session card now always shows the "Focus Goal:" label (and lets you set/edit it, even when it's empty), and clearly labels the current focus mode as "Focus: <mode>" so you can see at a glance what's running. (#2206)
Focus Bear's own dashboard no longer gets blocked — during a focus session, dashboard.focusbear.io (and other focusbear.io pages) are always allowed instead of occasionally being blocked. (#2210)
A focus session ending during a meeting now asks you first — instead of silently extending itself when you're in a meeting, Focus Bear shows the end-of-session warning so you stay in control of whether it continues. (#2208)
Meetings are detected on Bluetooth headphones and in the browser — meeting detection (which keeps the Talking Clock quiet and can auto-start meeting mode) now works for browser-based calls like Google Meet and when your mic is a Bluetooth/USB headset — not just native apps with the built-in mic. (#2202)


# v3.35.520
See what a sidebar icon is when the menu is collapsed — when you shrink the left sidebar to its narrow, icon-only view, hovering an item now shows its name as a tooltip, so you can tell what each icon does without expanding the menu. (Disabled items still show their "why it's disabled" tooltip, unchanged.)
Class focus sessions show the teacher's checklist — when a student joins a class focus session, the To-Do player now hands off to the teacher/class checklist instead of the student's personal tasks. Personal tasks are safely restored when the session ends, and edits during class don't touch them.
Day Plan task text stays readable while editing — editing a task in the Day Plan no longer makes its text hard to read; it now stays legible the whole time you're typing.
Extending a focus session keeps your routine covered — if you extend a focus session from the completion screen while a routine was postponed, your habits are re-postponed to match — so they no longer pop up and interrupt you seconds after you extend.


# v3.35.521
Day Plan:
Snoozing a task now also updates its due date — pushing a to-do to a later day moves its actual deadline, not just where it sits in your plan.
Added a "Hide habits" setting to declutter the Day Plan down to just your calendar events.
Habit sections now expand and collapse independently — opening or closing one routine section no longer affects another.
Selected tasks are now easy to read — a highlighted task's text stays legible in both light and dark mode.
Focus:
Your focus summary now reliably reappears after a short (1-minute) break, even when a full-screen app is in front.
Brain Dump:
Brain Dump notes are now tied to your account — notes stay correctly associated with the right user on shared devices.
Reliability:
Fixed a crash that could happen when your disk was full — the app now keeps running instead of quitting unexpectedly.
Removed a brief freeze/hang in the Day Plan's date bar.
Behind the scenes:
Added anonymous usage analytics for key Day Plan actions to help us improve the feature (no user-visible change).




# v3.35.522
Focus Mode:
App-block notifications now show reliably — when a blocked app is caught during Focus Mode, you get a clear notification in the top-right (the old system notification had stopped appearing dependably). During a teacher/class session it includes a "Request unlock" button that opens the request pre-filled with the app's name.
Day Plan:
Snoozing a task no longer duplicates it or loses its project — the task moves cleanly to the new day, keeps its project, and any leftover duplicates from the old bug are automatically cleaned up.
Buttons show the pointing-hand cursor on hover, so it's clearer what's clickable.
Habits / Postpone:
Removed the "Deactivate Focus Bear for 4 hours" option from the postpone dialog — it was too easy an escape hatch. Postpone and Resume Habits remain.

# v3.35.523
Focus Sessions:
Focus Mode now remembers your last duration — each focus mode defaults to the length you last used it for (kept even after restarting the app). Switching modes or starting from the menu picks up each mode's own last duration, and a new mode starts from your most recent one (or 20 min if you've never run a session).
Onboarding:
Bigger, clearer time fields when setting up your first blocking schedule — the From/Till time pickers and their up/down arrows are larger and easier to tap, and the schedule now sensibly defaults to now → one hour later.
Menu & sidebar polish:
Fixed a stray "xx" showing before "Focus Alignment score" in the menu (a placeholder that could leak through under heavy memory load).
The ✕ "hide" button on an active Tools sidebar item is now clearly visible — it no longer washes out against the highlighted row.
AuDHD:
AuDHD results now open in a proper full-screen view from the deep link.

# v3.35.524
Blocking now works even when an app is fullscreen. Previously, apps like Google Chrome, Calendar, Apple TV and others could keep running in fullscreen and slip past Focus Mode / Teacher Mode blocking. Focus Bear now reliably pulls a blocked app out of fullscreen so the block actually takes effect — closing a loophole where a distracting app (or a student in a class session) could stay in fullscreen to avoid being blocked.
Allowed apps are left alone in fullscreen. As part of the above fix, we made sure apps you're allowed to use are no longer briefly yanked out of fullscreen. If an app is permitted in your current session, it stays exactly as it is.
AuDHD assessment results load correctly. Fixed the results page so it opens against the right address and is recognised as coming from the Focus Bear app.

# v3.35.525
Teacher / Class sessions
Only teacher-approved apps are allowed in class. During a teacher-led class focus session, your personal "Always Allowed Apps" list no longer applies — only the apps your teacher allows are usable, so the session's blocking can't be sidestepped.
Allowed apps match more reliably. If your teacher allows an app like "Chrome", it now correctly permits "Google Chrome" (and similar name variations), so approved apps aren't blocked by mistake.
Rejoin a class session you dismissed. If you decline or close the "join class session" prompt while the session is still running, a "A class focus session is running — Join session" option now appears in the menu bar so you can join at any time.
The app can't be quit to escape a class session. Trying to quit during an active class session now shows the "controlled by your teacher" message (with Request unlock) instead of closing the app.
Fixes
Micro Break: Office Mode / WFH toggle is now clickable. Fixed the Office Mode / WFH Mode buttons on the break screen not responding to clicks on macOS Tahoe.
Spanish translations restored on the focus-complete screen. Fixed Spanish text (session rating, next-goal prompts, and the achievement/more-stats/continue-break buttons) that was showing in English.

# v3.35.526
Day Plan:
Overdue & due-today to-dos show up automatically. Today's Day Plan now surfaces to-dos that are due today or overdue — even if you never planned them — so nothing due slips off your radar. (Tasks you've scheduled for a later day stay put.)
Checklists now sync across your devices. Sub-tasks you add to a Day Plan task are saved to the underlying to-do, so they show up on the web and mobile apps too (and sub-tasks added elsewhere appear on your Mac).
Cleaner task editing. The #project autocomplete suggestions size correctly, and text stays legible while you're editing a task.
Focus:
Accurate focus-session times. Fixed sessions occasionally logging huge, wrong durations (e.g. 18+ hours) after the Mac was quit or asleep overnight — recorded time is now capped at the session's scheduled length.
Focus music:
Pause YouTube tracks from the menu. You can now pause a YouTube Music track straight from the menu bar (and with the media/hardware key), not just from the player.
Menu:
No more cut-off menu. Fixed the menu clipping its content — the bottom of "Focus Tools" and the top of the microphone/voice icons are fully visible again.
Talking clock:
Rounder time announcements. The spoken time now rounds to the nearest 15 minutes for a cleaner announcement.



# v3.35.527

Routines & Day Plan:
After you finish your morning routine, Focus Bear now takes you straight to your Day Plan for the day instead of showing a "stay focused" message and closing the window (which felt like the app was quitting). (#2293)
The Day Plan's free-time estimate is now realistic — it counts only the time still ahead of you today (up to your evening routine), instead of treating the whole day as free. No more "7h 40m free" on an afternoon full of meetings. (#2294)
Fixed a "Save" button that showed no text on the Create new project prompt — and hardened every Day Plan label against ever appearing blank. (#2294)
Fixed duplicate tasks appearing when you snooze a Day Plan task to a later day (or a snoozed task rolls over) — the task no longer lingers as a copy on both the old and the new day. (#2292)
Class sessions (for students):
When your teacher ends a class session, your personal tasks now come back right away in the Todo Player — previously you had to switch tabs or restart the app to see them again. (#2296)
Focus sessions:
A focus session you start from "Block everything else" during a meeting now shows the normal end-of-session warning (with the option to extend or finish), just like any other focus session. (#2295)
Focus Button:
Fixed the Focus Button getting stuck on "Firmware: unknown" with a spinner that never finished and habit icons that never appeared. It now recovers the firmware version reliably and always shows a clear icon-sync status. (#2291)
Reliability:
Fixed a case where a calendar meeting reminder could pull you out of your locked evening routine past the cut-off time without the password. (#2290)
Several stability fixes for freezes and crashes reported from the field — a hang from the Focus Button, a brief freeze at launch on some Wi-Fi setups, and a crash when starting an incomplete morning habit. (#2289)


# v3.35.528

Sign-in screen:
Fixed left-menu tabs being clickable while logged out. On the login screen, the Todo List, Focus Button, Time Tracker and Late No More tabs could still be opened — which took you off the login screen with no way back. They're now disabled until you sign in. (#2297)

Focus:
"Report Bad AI decision" now unblocks the site. When you report the AI for wrongly blocking an app or website, that exact app/site is now allowed for the rest of your focus session — instead of being blocked again moments later. (#2302)


# v3.35.529

Onboarding:
Distraction blocking now comes first — new users set up blocked websites and apps before building habits, and within that step you now review blocked sites and apps before your allowed sites. (#2304)
Breaks are on by default for new users — an hourly (60-minute) break out of the box — and more categories are blocked by default (dating, news, real estate). (#2304)

Breaks:
When breaks are turned off, the Micro Break screen now lets you pick how often you'd like a break and turn them back on right there, instead of a plain "enable" button. (#2304)

Reliability:
Fixed an app freeze caused by the Day Plan re-reading your calendar every 30 seconds — it now only re-reads when your calendar actually changes, so the Day Plan stays responsive (meetings still update whenever the calendar changes). (#2305)


# v3.35.530

Onboarding:
The account screen now explains that Focus Bear signs you in through Auth0 (our secure login partner), so the system "…wants to use auth0.com to Sign In" prompt no longer comes as a surprise. (#2321)
Browser permissions are now set up one browser at a time, with an "I don't use this" option to skip browsers you don't have — instead of being prompted for every browser at once. (#2321)
Signing up with Google no longer shows the sign-in prompt twice. (#2323)
After finishing onboarding you now land on the focus screen, instead of the window just closing to nothing. (#2322)
The "create a blocking schedule" step now uses the same editor as the in-app settings, so it looks and behaves consistently. (#2316)

Breaks:
Fixed breaks silently stopping during long focus or work sessions — your next break now keeps its place across pauses, screen locks and app switches, so it always arrives on time. (#2309)
Postponing your routine no longer turns your breaks off — if you've chosen to keep breaks while postponed, they stay on. (#2312)

Habits:
You can now open Settings and Edit Habits during an active routine, without having to end it first. (#2313)

Reliability:
Fixed website blocking not working on Apple-Silicon Macs without Rosetta installed, where the block page could get stuck in a crash loop. (#2320)
Fixed a crash when starting your morning habits. (#2324)
Fixed a crash that could happen during a live session when the network connection dropped and reconnected. (#2308)

Behind the scenes:
Added analytics for when the AuDHD results popup is closed, to better understand how the feature is used. (#2314)


# v3.35.531

Website & app blocking:
Fixed blocking not working in Google Chrome while you're on a browser video call (e.g. Google Meet). Chrome opens a separate window for the call, and Focus Bear was reading that window instead of your real tab — it now blocks the correct tab (and shows the block popup over the right window). (#2331)
Fixed the macOS "…wants to control [browser]" permission prompt popping up and disappearing in a loop when you switched to a browser you hadn't granted yet — it now appears once and stays until you respond, then remembers your choice. (#2330, #2334)
Fixed a "Choose Application" window that could appear on startup for some users (most often with Firefox in front). (#2333)

Onboarding:
Fixed a crash that could happen if you opened the Day Plan right after finishing onboarding. "Start using Focus Bear" now shows a brief loader while the app finishes setting up, then lands you on the focus screen. (#2329)

Other:
The "Send" button on the Report a Problem screen is now a clearer, larger orange button. (#2332)
Blocking-schedule start and end times can now be set in finer 5-minute steps. (#2332)


# v3.35.532

Onboarding:
Reordered the onboarding flow so setting up your habits now comes after granting permissions, giving a more natural order. (#2337)
Simplified the browser-permissions step: every browser you haven't granted shows its own "Request Permission" button and you can proceed at any time (the per-browser "I don't use this" toggle has been removed). (#2339)
Hid the Back button on a couple of onboarding screens where going back no longer made sense. (#2347)

Permissions:
Fixed Firefox permission not being detected during onboarding after you install the Focus Bear extension — it's now recognised as granted. (#2340)
Fixed the macOS "System Events" permission prompt popping up and disappearing in a loop after onboarding when you switched to a browser — it now appears once and stays until you respond. (#2346)

Focus sessions:
Fixed the +/- buttons on the menu's focus-duration picker snapping back to the saved duration instead of keeping your adjustment. (#2341)
Fixed the blocked-site "set intention" screen staying on screen after you stop a focus session (and lingering when you switched tabs). (#2343)
Fixed the Todo Player opening blank — and not showing the focus mode's saved task — when starting a focus session from the menu. (#2344)
Removed the "Do you want to use Focus Bear for your to do list?" prompt when starting a focus session; the To Do player is now simply enabled. (#2345)

AuDHD test:
If you come from the web AuDHD test, your results now open automatically on first launch (recovered from a code on your clipboard), so a fresh install no longer loses them. (#2336)

Behind the scenes:
Fixed a developer-only "priority inversion" warning in the AppleScript layer (no change to how the app behaves). (#2342)


# v3.35.533

Account:
You can now edit your leaderboard username right from the Accounts screen — tap the edit icon, change it, and Update (or Undo to cancel). Previously it was read-only and could only be changed in the web app. (#2360)

Reliability:
Reduced UI freezes ("app not responding") by capping how long the app will wait on browser/AppleScript checks in a single pass, so slow or unresponsive browsers can no longer lock up the interface. (#2361)

Behind the scenes:
The AI Blocking Logs debug panel now keeps its history across app restarts (last 50 entries), instead of being wiped every time — and each account's logs are kept separate. (#2319)
AuDHD web-quiz results now link the quiz identity into analytics when opened from the results deep link, for better funnel tracking. (#2326)


# v3.35.534

Menu:
The Tools section in the sidebar now starts collapsed for a tidier menu — expand it when you need a tool, and it opens automatically if you're already using one. (#2352)
Fixed the menu-bar popover not appearing when another app was in full-screen — it now shows on top of the full-screen space. (#2287)

Blocking:
Simplified the Blocking screen: "Super Distracting Sites" and "Super Distracting Apps" are no longer listed there, and "Always Allowed Apps" now appears only in Geek Mode. (#2352)

Reliability:
Fixed a rare crash when quitting the app. (#2318)


# v3.35.535

Day Plan:
Snoozing a task now offers "Choose a good time for me" — Focus Bear reschedules it to the next weekday that has enough free time, spreading tasks out instead of piling them onto an already-busy day. (#2368)

Teacher mode:
Asking your teacher to unlock an app or website now requires a reason, so the teacher has context to decide. (#2372)

Website & app blocking:
Fixed distracting sites not being blocked the first time you open a browser after a focus session or class session starts — blocking used to only kick in after you left the browser and came back. (#2373)

Reliability:
Reduced freezes/beachballs by capping how long the app waits while reading a browser or app window title, so a slow or unresponsive app can no longer stall the interface. (#2366)


# v3.35.536

Day Plan:
Editing a repeating calendar event now asks whether to change just that event or the whole series — and applies the change to the exact occurrence you picked (previously a later occurrence could be missed or the whole series accidentally shifted). (#2375)

Teacher mode:
New class-session (PACT) invite screen — see what you're allowed to use and when the session ends, then "Activate the PACT", or decline with a reason via a deliberate press-and-hold. (#2377)

Reliability:
Fixed UI freezes when switching apps during a focus or class session, by moving the full-screen-exit check off the main thread. (#2379)


# v3.35.537

Automation:
Focus Bear now supports AppleScript, so you can automate it from the Script Editor, Shortcuts, or other Mac tools. You can start a focus session by name (with an optional intention and length), and view or manage today's Day Plan tasks — create tasks, read and edit their details, mark them complete, and check which tasks you've changed yourself. (#2382)


# v3.35.538

Day Plan:
Habits that don't fit before a whole-day calendar event are now grouped under "Not enough time today" (with a realistic time range) instead of quietly overflowing your schedule. (#2396)

Meetings:
Zoho meetings are now detected — and the default Zoho link in the Meetings block list was corrected — so a Zoho call is recognised and micro-breaks stay paused during it. (#2394)

Breaks:
Longer break lengths now read as "3 min 10 sec" instead of a large raw seconds count. (#2400)

Log quantity:
Pressing Return/Enter in a log-quantity prompt now always saves it, via the OK button. (#2404)

Reliability:
Fixed a crash when tapping OK on a log-quantity prompt that had no questions. (#2395)
Fixed a crash when cancelling or submitting a log-quantity prompt. (#2407)


# v3.35.539

Day Plan:
Assigning a #project to a task now syncs to the backend (creating the project if it's new), so the project shows up on web and mobile too. (#2392)
You can now edit a calendar event you don't own from within the Day Plan — the change (e.g. a renamed title) shows only on your Day Plan and never touches the shared calendar. (#2403)

Postpone:
Cancelling a postpone now keeps the Postpone button instead of losing it, the password gate is re-checked at confirm time (Late No More), and stopping a focus session you started by postponing your routine now returns you to that routine. (#2398)

Reliability:
Fixed the time-of-day clock on the full-screen habit player freezing — it now keeps ticking. (#2410)


# v3.35.540

Notes:
The Notes screen (formerly Brain Dump) is now a fast native view instead of an embedded web page, with search, tags, and a rich-text editor for bold/italic/underline and lists. (#2390)

Day Plan:
When a habit won't fit before an upcoming meeting, a shorter later habit is now slotted into that gap instead of leaving it as empty deep-work time. (#2417)
The task picker now searches the backend when your cached task list has no match, so you can find any to-do. (#2413)

Focus Music:
Play/pause from the keyboard media key or Control Center now behaves correctly — a system pause (sleep, headphones unplugged) no longer resumes your music — and no longer stalls or crashes. (#2422)

Focus mode:
The focus-complete screen now shows a varied congratulatory message instead of always saying "You are doing well!". (#2420)

Reliability:
Fixed a freeze when starting a routine — the Visualize step now loads without blocking the routine screen. (#2421)


# v3.35.541

To-Do List:
The To-Do List and Projects are now a fast native screen instead of an embedded web page — with a task editor (TOP score, due date, duration, tags, assignee, subtasks, comments and reactions), a projects portfolio with per-project boards, members and notes, natural-language due dates, and an Eisenhower matrix view. (#2416)

Stats:
The Stats screen is now native too, with Streak, Progress, Your Goals, Pep Talk, Leaderboard, Habit Stats, Productivity and Focus Log tabs — plus a native pep talk on the routine-start screen. (#2415)

Menu:
You can now add a task straight to today's Day Plan from the menu bar — a compact "+ Add task" row expands into a one-line composer (type "#project", "*priority" and a duration like "30m" inline). (#2428)


# v3.35.542

Day Plan:
You can now edit your habits and routine start time straight from the Day Plan — an Edit (pencil) button on a habit opens the full habit editor, and the routine's "…" menu lets you change when it starts. Changes preview instantly; a banner then lets you save and restart to sync them. (#2412)

Blocking Schedules:
A blocking schedule you add, edit, or delete on mobile or Windows now updates on your Mac in real time, and the Blocking Schedules screen refreshes live while it's open. (#2454)


# v3.35.543

Blocking:
"Use AI to decide what to block" is now a per-block-list setting — turn it on or off for each block list under Focus Preferences → Advanced, instead of on individual schedules. When an app is blocked, the notification now also offers an "Oops, I actually need it" button to let yourself through. (#2402)
The frosted overlay over a blocked app or site now properly hides what's behind it, instead of leaving the content readable. (#2441)

Day Plan:
Fixed the event editor showing — and, on Save, moving the event to — the wrong calendar for events in a read-only calendar (e.g. a subscribed timetable or holiday calendar). It now shows the event's real calendar and won't move it. (#2436)
Fixed pressing Play on a different habit doing nothing while another habit was paused — it now switches to the habit you tapped and keeps the paused one ready to resume. (#2453)

Reliability:
Fixed a crash on launch that could occur when a routine's start or shut-off time was missing. (#2457)


# v3.35.544

Day Plan:
The ✕ on a calendar event is now a clear "🙈 Hide" button (and "👀 Show" to bring it back), so it no longer looks like it will delete the event from your calendar. (#2448)

Blocking Schedules:
Fixed a blocking schedule created during onboarding not being saved when you already had a block list set up (e.g. from mobile) — it now saves and shows up in your Blocking Schedules list. (#2514)

Sidebar:
Fixed sidebar icons being unresponsive while the sidebar is collapsed — the first click is no longer swallowed by the hover tooltip. (#2515)

Onboarding:
On a fresh install, your gated AuDHD quiz results now show first (when detected) before the welcome and onboarding flow. (#2526)

Reliability:
Fixed a potential crash when showing the main window. (#2522)


# v3.36.545

Start a focus session — redesigned:
The Start Focus Session screen has been rebuilt. A clean "simple" view lets you just set your session length on a dial and go, while an "Extra powerful options" link opens the full advanced setup (block list, focus goal and the rest) whenever you want more control. (#2569)

AI accountability buddy:
When you postpone your habits, Focus Bear can now ask what you'd like to do instead and have an AI accountability buddy check whether it's a genuine reason to be on the computer. If it is, it starts a super-strict focus session that allows only the apps and websites you need for that goal and blocks everything else; if not, you get a gentle explanation and some alternatives. (The AI checks run on our server over your existing secure sign-in.) (#2569)

Notes:
The Notes screen is now native instead of a web view — a Brain Dump card to capture thoughts fast, search and new-note controls, and an infinite-scrolling list with a create/edit sheet. Your project notes now show up alongside your personal ones. (#2569)

Plan ahead (To-Do forecast):
A new forecast looks at your projects, tasks, meetings, habits and self-care time over a horizon you choose and tells you how likely you are to finish everything in time. You can generate a suggested plan, review the proposed changes, and apply only the ones you pick — or use "Fix" on a single day to reschedule just that day. (#2569)

Main window:
Fixed the main content area showing blank after re-opening the app from the Dock — it now restores your last view, or opens on Start Focus Session at the correct size when there isn't one. (#2569)

Turn everything off:
"Turn everything off until tomorrow" now fully quits Focus Bear and automatically relaunches it at your next routine start time, instead of leaving it running in the background. Also fixed the loading spinner and the "To uninstall…" hint overflowing in that dialog. (#2569)
Fixed the quit window's controls staying greyed-out/busy when you reopened it after pausing something. (#2569)

Blocking:
The "AI is deciding what to block" popup now has a standard close button in the title bar — closing it blocks the app or page, as the buttons inside do — and every button in the popup shows the pointer cursor on hover. (#2569)
Fixed an overlapping/duplicate checkbox on the advanced focus-mode settings screen. (#2569)

Windows & popups:
Fixed switching to another app and back — or closing a popup — unexpectedly bringing the main window to the front. (#2569)

Settings:
The "AI accountability buddy when postponing habits" setting now syncs across your devices and is saved per account (so it no longer carries over between accounts), and it now appears when you search Settings. (#2569)

Day Plan:
"Make today fit" sheet: fixed the title and Done button alignment, and the Done button now matches the app's orange style. (#2569)
Reschedule-plan sheet: fixed the layout while it's still loading, and added the pointer cursor to the Close and Select-all controls. (#2569)

Onboarding:
AuDHD retest results now continue from where you left off, so any remaining questions show before the result. (#2569)

Reliability:
Fixed a spurious "Please log in again" prompt on launch — background sync now starts only after you're signed in. (#2569)


# v3.36.546

Focus Music:
The play/pause control now correctly switches to "Play" when you pause music during a focus session. (#2608)
Music you start from the focus session's own controls now stops automatically when the session ends, instead of playing on afterwards. (#2609)

Start a focus session:
The session-length slider is now fine-grained — pick any number of minutes (like 17 or 19), not just multiples of five. The +/- buttons still step by 5. (#2612)
The "AI off" tag next to a block list is now higher-contrast and easier to read. (#2608)

Block Lists:
The pencil on each block list now opens that list in the editor (instead of always the default one), the editor opens as a sheet, each row shows its real apps/websites count, and name or content edits show as soon as you return. (#2610)

Blocking Schedules:
Fixed the back arrow not closing the block-list editor when it was opened from a blocking schedule. (#2595)
A blocking schedule now opens the block list you chose to edit, and a renamed block list updates on the schedule. (#2610)

Onboarding:
Setting up distraction blocking no longer skips the blocking-schedule and permission steps, and there's a new quick-start presets step when you create your first blocking schedule. (#2601)

Notes & To-Do:
Removed the duplicate close buttons in Notes and the To-Do list — the window's own close control is used instead — and stopped the "Show brain dump" button from running off the right edge. (#2611)

Reliability:
Fixed a hang (and automatic relaunch) caused by the menu-bar popup repeatedly resizing itself. (#2592)


# v3.36.547

Routine:
The morning/evening pep talk now shows once per routine start, and reliably appears on the "Get Focused" screen instead of sometimes being skipped. (#2617)
Fixed the routine screen showing an endless loader and going unresponsive after clearing app data and signing back in with an existing account whose routine was already done for the day. (#2623)
The AI accountability buddy no longer asks you for a postpone reason again after it has already approved one. (#2617)

Settings:
The "AI accountability buddy when postponing habits" setting now shows a "New" tag. (#2626)
Editing habits, routine timings and custom routines now asks for your settings password when your strictness settings require it — previously only routine timing did. (#2617)

AI accountability buddy:
The buddy now receives your calendar, so it can see your meetings instead of claiming it can't. (#2617)

Start a focus session:
You can now click the session length and type an exact number of minutes, not just use +/−. (#2617)
The screen no longer says "No matching unfinished tasks" before your tasks have finished loading. (#2617)

Projects & To-Do:
A project card with no expected completion date now explains why (add estimates, or the work doesn't fit the planning horizon) instead of showing a blank. (#2617)
Reschedule plan: projects at risk now appear at the top, and fixed-date work due within the next two weeks is surfaced higher instead of buried at the bottom. (#2617)

Focus & Blocking:
A blocking schedule no longer starts with tasks left over from a previous focus session. (#2617)

Full screen:
On a multi-monitor setup, the full-screen window now sizes to the display it's actually on, so it no longer becomes too tall and cuts off the bottom of the screen. (#2617)

Reliability:
Fixed occasional app hangs when your Wi-Fi network changed or when using "Use current network" in Office Mode settings (the Wi-Fi lookup now runs off the main thread). (#2617)
Behind-the-scenes: removed unnecessary Focus Button connection traffic, and added more detailed logging to help diagnose the "Exit full screen did nothing" report. (#2617)


# v3.36.548

Routine:
The morning/evening pep talk no longer goes missing after relaunching straight into a routine whose "Get Focused" screen had already shown earlier that day. (#2634)
On a shared Mac, the "Get Focused" screen (and its pep talk) now shows for each account — previously, once one account had seen it for the day, another account signing in on the same computer wouldn't. (#2652)

Start a focus session:
"Add tasks to focus on" no longer shows "No matching unfinished tasks" for people with a long history of completed tasks — it now asks the server for unfinished tasks so the list is never empty. (#2650)
You can now click anywhere on the "Focus Goal" row to expand it, not just the small arrow, and an empty goal shows a hint of what to type. (#2630)

Day Plan:
Event titles now sit at the top of their block (like Google Calendar) instead of floating in the middle of a tall meeting or deep-work block. (#2629)
Setting a task's importance in the Day Plan (for example typing "!5") now saves to the to-do and sticks, instead of reverting on the next refresh. (#2639)

Projects & To-Do:
A project whose work runs past your planning horizon now shows "Expected completion: after <date>" instead of a "doesn't fit within the planning horizon" message. (#2635)

AI accountability buddy:
A "focus mode finished" signal from another device no longer ends a focus session you started by postponing through the AI buddy. (#2640)

Focus & Blocking:
When checking whether the app you're using is relevant to your focus, the Claude chat title now ignores hidden screen-reader-only text, so the AI sees the real conversation title. (#2642)

Full screen:
When a habit auto-skips because its cutoff time passed, the routine now stays in full screen (like a manual skip) instead of dropping to a small window that could get stranded off-screen. (#2628)

Behind-the-scenes:
Rendering a developer mockup no longer repoints the installed app's background helper at the dev build. (#2631)
The CI test host no longer reads the login keychain, so automated runs stop triggering repeated keychain/certificate prompts. (#2641)
The reschedule tests no longer read or write the developer's real preferences and Day Plan, fixing spurious failures on shared machines. (#2633)
