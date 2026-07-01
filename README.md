# Running locally (Debug)

> The rest of this README covers building a **Release** DMG for distribution. To just
> **run the app locally for development**, do the following. For the full background and
> troubleshooting (Xcode 26, Auth0, Sentry, etc.) see
> [`docs/local-development-setup-v2.md`](docs/local-development-setup-v2.md).

1. **Fetch Sparkle:** `./scripts/fetch-sparkle.sh` — downloads the official signed
   `Sparkle.framework` to the repo root (it is no longer committed to git).
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
