# Running locally (Debug)

> The rest of this README covers building a **Release** DMG for distribution. To just
> **run the app locally for development**, do the following. For the full background and
> troubleshooting (Xcode 26, Auth0, Sentry, etc.) see
> [`docs/local-development-setup-v2.md`](docs/local-development-setup-v2.md).

1. **Fetch Sparkle:** `./scripts/fetch-sparkle.sh` — downloads the official signed
   `Sparkle.framework` to the repo root (it is no longer committed to git).
   - *(Optional)* `./scripts/fetch-esptool.sh` — vendors the universal `esptool`
     binary the in-app Focus Button firmware flasher bundles. Only needed if you
     want the Flash Firmware button to work; builds skip it (with a warning) when
     absent. Release/CI builds should run it.
2. **Open the workspace**, not the project: `open FocusBear.xcworkspace` (Pods are
   committed; run `pod install` only if you change `Podfile`).
3. **Select the `Focus Bear` scheme and Run (⌘R).** Clean build folder (⇧⌘K) first if needed.

That's it — everything else is already configured in the project: the Run action builds
**Debug** (Release is for archiving/notarisation only), Debug signs **ad-hoc** ("Sign to
Run Locally"), the deployment target is **macOS 11**, and `SWIFT_ENABLE_EXPLICIT_MODULES`
is off for Xcode 26. Signing lives in `Config/*.xcconfig` — Release keeps the Developer-ID
identity, Debug is ad-hoc; to sign Debug with your own team copy
`Config/Local.xcconfig.example` → `Config/Local.xcconfig` (gitignored).

> **⚠️ Flask server binaries (`FocusBear/server` and `FocusBear/serverIntel`) — lead
> developer only.**  These pre-built, codesigned binaries must **not** be rebuilt by
> individual contributors.  `server` targets Apple Silicon (arm64) and is built on an
> M-Series Mac; `serverIntel` targets Intel (x86_64) and must be built on an Intel Mac
> (universal Python on M-Series does not produce a working Intel binary).  Both binaries
> must also be signed with the Focus Bear Developer-ID certificate before being committed.
> If a new build is required, contact lead developer.

---

## Replacing the installed app you actually use (`~/Applications/Focus Bear.app`)

Running from Xcode covers development. This is the separate procedure for updating the **installed
copy the machine's owner uses all day**, which is what `~/Applications/Focus Bear.app` is — it runs
through LaunchServices, holds the real TCC grants, and is what the debug reports come from.

**1. Build with a stable signature.** `Config/Local.xcconfig` must exist (gitignored, from
`Config/Local.xcconfig.example`). Without it the build is ad-hoc, every rebuild is a different app to
macOS, and the Accessibility/Calendar grants and Keychain access are reset:

```bash
xcodebuild -workspace FocusBear.xcworkspace -scheme "Focus Bear" \
  -configuration Debug -derivedDataPath build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
codesign -dvvv "build/Build/Products/Debug/Focus Bear.app" 2>&1 | grep Authority   # expect Apple Development
```

**2. Stage, back up, move.** Writing into an existing `~/Applications/*.app` is blocked:

```bash
STAGE=~/Applications/.FocusBear-staging; DEST=~/Applications/"Focus Bear.app"
rm -rf "$STAGE" && ditto "build/Build/Products/Debug/Focus Bear.app" "$STAGE"
rm -rf ~/Applications/.FocusBear-previous && mv "$DEST" ~/Applications/.FocusBear-previous
mv "$STAGE" "$DEST"
```

**3. Launch — through launchd, never from a shell.** `open -a` fails with
`_LSOpenURLsWithCompletionHandler ... error -600`, even with nothing running and after `lsregister -f`.
Either wait ~60s for the `com.focusbear.focusbearhelper` LaunchAgent (`KeepAlive = true`) to start it,
or start it through a one-shot LaunchAgent:

```bash
P=~/Library/LaunchAgents/com.focusbear.manual-start.plist
/usr/libexec/PlistBuddy -c "Add :Label string com.focusbear.manual-start" \
  -c "Add :ProgramArguments array" \
  -c "Add :ProgramArguments:0 string $HOME/Applications/Focus Bear.app/Contents/MacOS/Focus Bear" \
  -c "Add :RunAtLoad bool true" -c "Add :KeepAlive bool false" "$P"
launchctl bootstrap gui/$(id -u) "$P"
rm "$P"   # so it does not launch a second copy at next login; do NOT `launchctl bootout` it — that kills the app
```

**Why not `nohup …/MacOS/Focus Bear &`:** macOS attributes privacy (TCC) checks to a process's
*responsible* process, and for anything spawned from a shell that is the terminal app. If the terminal
is not itself granted Accessibility, the app reports `accessibility=false` and blocking is silently
**off** — however correct the app's own grant is. Launched by launchd, the app is its own responsible
process and its own grant applies.

**Never `open -a /Applications/Focus Bear.app`.** A stale copy there shares the bundle id
`com.App.EarnYourScreentime`; launching it starts a second FBHelper whose `KeepAlive` fights the real
instance (the app is replaced about every 60s) and strands embedded `server` processes.

**4. Verify the path, not just the process name:**

```bash
pgrep -fl "Focus Bear.app" | grep -v "Time Tracker"       # must be ~/Applications, + 2 server procs
lsof -nP -iTCP:50501 -sTCP:LISTEN                          # embedded Flask server
grep blockingOffReasons "$HOME/Library/Application Support/com.App.EarnYourScreentime/Logs/Debug_Logs.txt" | tail -1
```

The last line should end `accessibility=true`. If it says `accessibility=false → permissionsMissing`,
blocking is silently **off**.

### The keychain prompt is the tell: you are running the wrong copy

**"Focus Bear wants to use your confidential information stored in `com.App.EarnYourScreentime`"**
means an **ad-hoc** binary is running, because an ad-hoc ACL's designated requirement is a bare
`cdhash` (every build is a new app to macOS). A correctly installed build never shows it.

The usual cause is not the install — it is that **several bundles share the id
`com.App.EarnYourScreentime`**, and LaunchServices resolves the id to whichever was registered last.
CI building on this Mac registers its DerivedData product, so FBHelper then launches *that* ad-hoc
copy instead of `~/Applications`. Symptoms: the keychain prompt, `accessibility=false`, and an app
that reappears from a DerivedData path however many times you kill it.

Diagnose by comparing what is **running** with what you **installed** — never assume:

```bash
P=$(pgrep -x "Focus Bear"); RP=$(ps -o args= -p $P | sed 's|/Contents/MacOS/Focus Bear.*||')
codesign -dvvv "$RP" 2>&1 | grep -E "Authority=|Signature=adhoc"      # adhoc  → wrong copy
codesign -dvvv ~/Applications/"Focus Bear.app" 2>&1 | grep Authority  # Apple Development → yours
```

Fix by taking the impostors out of LaunchServices (this deletes nothing):

```bash
LSR=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
launchctl bootout gui/$(id -u)/com.focusbear.focusbearhelper      # stop the relauncher first
pkill -9 -f "Focus Bear.app/Contents/Resources/FBHelper"; pkill -9 -x "Focus Bear"
pkill -9 -f "Focus Bear.app/Contents/Resources/server"
"$LSR" -u ~/Library/Developer/Xcode/DerivedData/FocusBear-*/Build/Products/Debug/"Focus Bear.app"
"$LSR" -u ~/dev/Mac-App/build/Build/Products/Debug/"Focus Bear.app"
"$LSR" -u /Applications/"Focus Bear.app"
"$LSR" -f ~/Applications/"Focus Bear.app"
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.focusbear.focusbearhelper.plist  # relaunches the app
```

**If `accessibility=false` persists with the right build running, check how it was launched before
touching the grant.** A shell launch (above) produces exactly this, and re-granting does not fix it.
To see whether the grant itself matches the installed build, compare the TCC record's requirement with
the app's designated requirement:

```bash
sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
  "select auth_value, hex(csreq) from access where service='kTCCServiceAccessibility' and client='com.App.EarnYourScreentime'" \
  | awk -F'|' '{print "auth_value="$1; print $2}' | tail -1 | xxd -r -p > /tmp/fb.csreq
csreq -r /tmp/fb.csreq -t                                            # the requirement TCC stored
codesign -d -r- ~/Applications/"Focus Bear.app" 2>&1 | grep designated  # the build's own
```

`auth_value=2` with matching requirements means the grant is fine and the launch is the problem. Only
if they differ does it need re-granting by hand: System Settings → Privacy & Security → Accessibility →
select Focus Bear, remove it with **−**, then re-add `~/Applications/Focus Bear.app` and enable it.

### ⚠️ `xcodebuild test` terminates the running app

`Focus BearTests` is **app-hosted**: it launches the same bundle id from DerivedData, so macOS
terminates the copy the user is running. That test host is signed `CODE_SIGN_IDENTITY=-`, so it holds
no TCC grants and the log reads `accessibility=false` — blocking off — for as long as it is up.

**The GitHub Actions runner is this same Mac** (`actions.runner.Focus-Bear-Mac-App`), so *every push
that runs the unit-test workflow* does this too, not just local test runs.

A "Focus Bear" process running from
`~/Library/Developer/Xcode/DerivedData/FocusBear-*/Build/Products/Debug/Focus Bear.app` with
`-NSTreatUnknownArgumentsAsOpen NO` is a **test host**, not the app; it goes away when the run ends.
So prefer pushing and reading CI over running `xcodebuild test` locally while someone is using the
app, and before blaming a new build for a broken app, check `pgrep -fl xcodebuild`.

---

### 📆 Steps to Build and Create a Notarized DMG for macOS App

✅ 1. Build the App for Release

1. In Xcode, for each target:
   - Select Product > Scheme > Edit Scheme from the top menu.
   - In the left sidebar, select Run > Info.
   - Change Build Configuration to `Release`.
   - Uncheck Debug executable.
   - Click Close.

2. From the top menu bar, select Product > Archive to start the archiving process.

---

📁 2. Distribute and Notarize the App

1. Once the archive completes, the Archives window (Organizer) opens automatically.
   - If not, open it via Window > Organizer.
   - Select your app from the left dropdown if it's not auto-selected.

2. Select the latest archive and click Distribute from the right panel.

3. In the distribution dialog:
   - Choose Direct Distribution.
   - Click Distribute.

> The app is now uploaded to Apple’s notarization service.

4. Wait 1–2 minutes until the archive status changes from Processing to Ready to Distribute.
   - You will receive a notification once notarization is complete.

5. Once ready:
   - Click Distribute again.
   - Choose Direct Distribution.
   - Click Distribute.
   - Click Export and choose a destination folder.

> The `.app` file will be saved inside the selected folder.

---

💠 3. Create a DMG File

1. Create a folder named `DMGFolder` and include:
   - `Focus Bear.app`
   - Shortcut to Applications folder
   - `fb.tif` (background image)
   - `build.sh` (notarization script)

2. Open Disk Utility.

3. Go to File > New Image > Blank Image and configure:
   - Save As: Focus Bear.dmg
   - Where: Choose a save location
   - Name: Focus Bear.dmg
   - Size: 85 MB (larger than app size + buffer)
   - Leave other fields default
   - Click Save

4. Double-click Focus Bear.dmg to open it.

5. Drag the following into the opened DMG:
   - Focus Bear.app
   - Applications shortcut
   - fb.tif

6. Right-click inside the opened DMG and choose Show View Options:
   - Check Always open in icon view
   - Set Icon size to 108 x 108
   - Set Text size to 16
   - Select Picture under Background
   - Drag fb.tif to the "Drag image here" area
   - Close the window

---

👻 4. Hide Background Image

1. Open Terminal and run:

```bash
cd /Volumes/Focus\ Bear
mv fb.tif .fb.tif
```
Close terminal 

2. Arrange Focus Bear.app and Applications icons inside the opened DMG.

3. Close the DMG window and right-click on the desktop icon > Eject “Focus Bear”.

---

🔐 5. Compress and Finalize the DMG

1. Reopen Disk Utility.

2. Go to Images > Add Checksum...
   - Select Focus Bear.dmg
   - Click Checksum and then Close when done

3. Go to Images > Convert...
   - Select Focus Bear.dmg > Click Choose
   - Choose output location (preferably DMGFolder)
   - Click Convert

4. After conversion:
   - You will get Focus Bear converted.dmg
   - Delete the original Focus Bear.dmg
   - Rename Focus Bear converted.dmg to Focus Bear.dmg

---

✉️ 6. Notarize the Final DMG

1. Open Terminal, navigate to DMGFolder, and run:

```bash
cd path/to/DMGFolder
bash build.sh
```

2. Wait for terminal output confirming successful notarization.

---

📆 7. Rename DMG with Version (Optional)

Rename Focus Bear.dmg to something like Focus Bear 1.23.365.dmg based on the current app version.

---

End of instructions.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
