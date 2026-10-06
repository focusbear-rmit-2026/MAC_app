# Running the Mac-App CI on a spare Mac

This guide turns a spare Mac into a GitHub Actions runner for the Focus Bear Mac app: the unit tests
and, more importantly, the **UI tests**, which click and type in a real desktop and can't run on
GitHub's hosted machines. It assumes you know macOS and GitHub but not this repository. Allow an
afternoon; most of it is waiting for Xcode to download.

More detail on the UI tests themselves is in [`docs/ui-tests.md`](ui-tests.md).

## What the runner does

Two workflows run on self-hosted Macs. They find a runner by its **labels**:

| Workflow | File | `runs-on` labels | What it runs |
| --- | --- | --- | --- |
| Unit Tests | `.github/workflows/unit-tests.yml` | `self-hosted`, `macOS`, `ARM64`, `focusbear-mac-local` | Logic unit tests, on every PR touching the app |
| UI Tests | `.github/workflows/ui-tests.yml` | `self-hosted`, `macOS`, `focusbear-mac-ui` | XCUITest suite, on PRs labelled `ui-tests` / `full-ui-tests` or by hand |

`self-hosted`, `macOS` and `ARM64` are added automatically when you register a runner on an Apple
silicon Mac. You only choose the last one. **A spare Mac nobody uses should be `focusbear-mac-ui`**,
and it can also take `focusbear-mac-local` so it picks up unit tests too. One runner runs one job at
a time, so the two never overlap.

Never give `focusbear-mac-ui` to a Mac someone works on: the UI tests take over the mouse and
keyboard for up to an hour, and a Focus Bear running on that Mac breaks them (see Troubleshooting).

## 1. Hardware and macOS

- **Apple silicon** (M1 or later). The workflows and the bundled ONNX Runtime are arm64.
- **16 GB of memory or more**, and **at least 150 GB free disk**. Xcode takes about 40 GB, and each
  test build another 3–5 GB.
- **A macOS version that Xcode 26.3 supports** (macOS Sequoia 15.6 or later when this was written;
  check Apple's Xcode release notes). CI currently builds with **Xcode 26.3 (17C529)**. Match the
  major version the team uses, or builds can behave differently from everyone's laptops.
- **Rosetta 2.** The app bundles a small x86_64 helper server, which needs it:
  `softwareupdate --install-rosetta --agree-to-license`
- A display, or an HDMI dummy plug if the Mac is headless. Some Macs give a headless login session
  no real screen, and the UI tests need one.

## 2. A dedicated macOS user

Create a **standard** user just for the runner (for example `ci`), and make these changes **while
logged in as that user**:

1. **Automatic login:** System Settings → Users & Groups → *Automatically log in as* → `ci`. (This is
   greyed out while FileVault is on. Turn FileVault off on a runner that holds no personal data, or
   the Mac will sit at the FileVault unlock screen after every restart.)
2. **Never lock and never sleep.** The UI tests need an unlocked screen the whole time:
   - System Settings → Lock Screen: *Start Screen Saver when inactive* **Never**, *Turn display off*
     **Never**, *Require password after screen saver begins or display is turned off* **Never**.
   - In Terminal (asks for an administrator password):
     `sudo pmset -a sleep 0 displaysleep 0 disksleep 0`
3. **Do Not Disturb on permanently:** Control Centre → Focus → Do Not Disturb. A notification banner
   over the app under test fails whatever test it lands on.
4. **Full Keyboard Access on:** System Settings → Keyboard → *Keyboard navigation* **on** (this is
   `AppleKeyboardUIMode`). The keyboard tests exist in two versions and the Mac's own setting
   decides which one runs. Our runner runs the "on" version, so the Tab order of every screen is
   tested. Set it once and leave it.
5. Install nothing else on this user: no Focus Bear, no screenshot tools (CleanShot and similar), no
   apps that open windows at login.

## 3. Xcode and tools

As the `ci` user:

1. Install **Xcode 26.3** from the App Store or developer.apple.com, open it once, and let it install
   its components.
2. `sudo xcode-select -s /Applications/Xcode.app` and `sudo xcodebuild -license accept`
3. Install [Homebrew](https://brew.sh), then `brew install cocoapods git python@3`
4. Let UI tests run without a password prompt every time:
   ```bash
   sudo automationmodetool enable-automationmode-without-authentication
   sudo DevToolsSecurity -enable
   ```
   `automationmodetool` on its own should now say it doesn't require authentication.

## 4. The GitHub Actions runner, as a LaunchAgent

The runner has to live **inside the logged-in `ci` session**, because only processes there can open
windows and receive clicks. That means a **LaunchAgent**, never a LaunchDaemon: a daemon runs outside
any login session, and every UI test would fail to connect to the window server.

1. Ask a Focus-Bear GitHub admin to open **Mac-App → Settings → Actions → Runners → New self-hosted
   runner → macOS / ARM64**. The page shows download commands and a one-time registration token. The
   token expires in an hour, so don't save it anywhere.
2. As `ci`, in Terminal, follow the page's *Download* steps into `~/actions-runner`, then configure:
   ```bash
   cd ~/actions-runner
   ./config.sh --url https://github.com/Focus-Bear/Mac-App --token <token from the page> \
     --name spare-mac-ui --labels focusbear-mac-ui,focusbear-mac-local --work _work
   ```
   Drop `,focusbear-mac-local` if this Mac should only take UI tests.
3. Install it as a service, **run as `ci`, without sudo**. Without sudo, `svc.sh` makes a
   LaunchAgent; with sudo it makes a daemon:
   ```bash
   ./svc.sh install
   ./svc.sh start
   ./svc.sh status        # should say "Started" and name ~/Library/LaunchAgents/actions.runner…plist
   ```
4. Check it isn't a daemon: `ls /Library/LaunchDaemons | grep actions.runner` should print nothing.
5. The runner shows as **Idle** on the Runners page.

Don't install `scripts/local-runner/xcodebuild` (the PATH wrapper described in its README) on a Mac
that takes UI tests. It only allows the unit-test scheme and would block the UI-test job.

## 5. Permissions (one-time clicks)

macOS asks some questions once, and a runner can't answer them. Do a first run **by hand, sitting
at the Mac, logged in as `ci`**:

```bash
git clone https://github.com/Focus-Bear/Mac-App.git ~/mac-app-setup && cd ~/mac-app-setup
git checkout main-human-verified   # or the branch with the UI tests, until they merge
./scripts/fetch-sparkle.sh && ./scripts/fetch-onnxruntime.sh
./scripts/run-ui-tests.sh --plan smoke
```

Say **Allow** or **OK** to everything it asks:

- **"Xcode Helper" / "Focus BearUITests-Runner" wants to control this computer** →
  System Settings → Privacy & Security → **Accessibility**: turn on what it lists.
- **Automation**: when *Focus Bear (UI Test)* asks to control **Safari** or **System Events**,
  answer **Allow**. The blocking tests need this. You can check under Privacy & Security → Automation.
- If Terminal or `sshd-keygen-wrapper` (a run over SSH) asks for Accessibility, allow that too.

The app under test is called **Focus Bear (UI Test)**, shows a TEST icon, and has its own bundle id,
`com.App.EarnYourScreentime.uitests`. It can't touch a real Focus Bear's settings or login.

If a later CI run fails with `The test runner failed to initialize for UI testing`, a prompt is
waiting on the screen. Log in to the Mac (Screen Sharing is fine), answer it, and re-run.

## 6. Signing (only needed for the blocking tests)

Out of the box, CI builds the test app **ad hoc**: unsigned, with no certificates needed. Everything
runs except the blocking tests, which skip with a warning. macOS ties the Accessibility and Automation
grants above to the app's signature. An ad-hoc build is a different app every time, so the grants
would be lost on each build.

To run the blocking tests too:

1. A member of the Focus Bear Apple Developer team (**team ID `TCUD568B3U`**) creates an **Apple
   Development** certificate for the runner. Either they add a CI Apple ID to the team, or they create
   the certificate in Xcode → Settings → Accounts → Manage Certificates and export it as a `.p12`.
   No provisioning profile is needed: the test build uses its own bundle id and no restricted
   entitlements.
2. Install it in the **`ci` user's login keychain**: double-click the `.p12` and enter its password
   when asked. Don't write that password anywhere. Then delete the `.p12` file.
3. Let `codesign` use the key without a prompt, by running this once, interactively, as `ci`:
   `security set-key-partition-list -S apple-tool:,apple: -s login.keychain`
   It asks for the `ci` login password. Type it in; don't put it in a script.
4. In GitHub → Mac-App → Settings → Secrets and variables → Actions → **Variables** (not secrets:
   these are names, not passwords), set:
   - `UI_TESTS_CODE_SIGN_IDENTITY`: the certificate's full name, e.g.
     `Apple Development: CI Runner (ABCDE12345)`. `security find-identity -v -p codesigning` lists it.
   - `UI_TESTS_DEVELOPMENT_TEAM`: `TCUD568B3U`
5. Run the smoke plan by hand once more (step 5 above) with the same identity, and re-grant
   Accessibility and Automation to the newly signed *Focus Bear (UI Test)*. From now on the grants
   survive rebuilds.

## 7. Test accounts and other secrets

The UI tests sign in to a real Focus Bear account:

- **With no secrets set**, each run signs up a fresh `internaltest+macuitest<timestamp>…@focusbear.io`
  account. It works, but leaves a new account behind every run.
- **To reuse one account** (recommended), add **repository secrets** in GitHub → Settings → Secrets and
  variables → Actions → **Secrets**: `FOCUSBEAR_UITEST_EMAIL` and `FOCUSBEAR_UITEST_PASSWORD`. Ask
  Jeremy for the test account, or for the QA account if the team wants that one used.

Rules for credentials:

- They live **only** in GitHub secrets. Never put them in this doc, a script, a shell profile, a
  `.env` file or a note on the Mac.
- The workflow hands them to the test run as environment variables. The app keeps only the
  sign-in token it gets back, in its own Application Support folder, readable only by `ci`; it never
  stores the password.
- If a password might have leaked, change it on the account and update the secret.

## 8. Keeping the disk clear

Every UI-test run builds into `~/actions-runner/_work/Mac-App/Mac-App/build-ui` (3–5 GB) and writes
a result bundle. Xcode's own caches grow too. When the disk fills, builds fail with odd errors.

- Once a week, **while the runner is idle** (the Runners page says *Idle*):
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData/*
  rm -rf ~/actions-runner/_work/Mac-App/Mac-App/build-ui ~/actions-runner/_work/Mac-App/Mac-App/*.xcresult
  rm -rf ~/actions-runner/_work/_temp/*
  ```
  Each job then does one slower, full build. Nothing else is lost.
- If you check the repository out elsewhere on the Mac (as in step 5), remove it when done, and run
  `git worktree prune` in any clone you keep. Stale git worktrees each carry their own multi-GB
  build folder.
- Keep at least 30 GB free: `df -h /`.
- Don't delete anything while a job is running: the build folder belongs to that job.

## 9. Checking it works

1. **Unit tests** (if you gave it `focusbear-mac-local`): any PR that touches `FocusBear/**` starts
   *Unit Tests*. It should run on your Mac and go green.
2. **UI tests by hand:** GitHub → Actions → **UI Tests** → *Run workflow* → plan `smoke`. It takes a few
   minutes. Watch the Mac: a *Focus Bear (UI Test)* window opens and gets clicked through.
3. **On a pull request:** add the label **`ui-tests`** to a PR. The job runs Smoke plus only the tests
   for the parts of the app the PR changed. Open the run and read its **summary**: *"UI tests for
   this change"* lists every test chosen and the changed file that chose it. If everything ran, it
   says why (shared code, a file the map doesn't know, and so on).
4. **The whole suite:** label a PR **`full-ui-tests`** instead. The summary says the whole Regression
   plan runs. Expect around 40 minutes.
5. Each run uploads **ui-test-results** (the result bundle, screenshots and the xcodebuild log).
   Download it from the run page when something fails, and open the `.xcresult` in Xcode.

## 10. Troubleshooting

These are the traps we actually hit.

**Every test fails, or the run never starts: the screen is locked or asleep.** The UI tests need an
unlocked, awake screen. Recheck step 2 (lock screen settings and `pmset`). A Mac that restarted for
an update and is waiting at the FileVault or login window counts as locked too.

**"covered by …" failures, or accessibility contrast checks failing everywhere: something is on top
of the app.** Before each click the suite checks that nothing covers the app under test.
- Notification banners (`UserNotificationCenter`): turn on Do Not Disturb (step 2).
- Screenshot and overlay tools like **CleanShot X** keep invisible full-screen windows up. The suite
  ignores those, but their pop-ups still cover things. Don't install them on the runner.
- **A real Focus Bear on the runner** is the worst case. Its full-screen routine and focus-session
  "shield" windows sit above everything, so every screenshot the accessibility audit takes shows the
  shield, not the app. The workflow refuses to start if it sees Focus Bear running. Don't install it
  on the runner at all.

**Every run spends minutes "building" even when nothing changed.** That's normal: `xcodebuild test`
rechecks every dependency, re-signs, and re-registers the app each time. Don't cancel it. Never run
two builds into the same `build-ui` folder at once: the second fails with a locked build database.

**A job dies halfway with the test app gone: something killed it by name.** `killall "Focus Bear"` or
`pkill -f "Focus Bear.app"` also match the test app and the unit tests' host app, which are called
Focus Bear too. Never kill by name on the runner. If you must stop something, find its exact PID
(`ps -ax | grep …`) and check its path first.

**The build fails with "… is only available in macOS 12.0 or newer" (or 14.0): code, not the
runner.** The app still supports **macOS 11**, so every newer API needs an `if #available(macOS …)`
check. That's a bug in the PR. It fails on everyone's machine, not just this one. (Also: the
workflows pass `SWIFT_ENABLE_EXPLICIT_MODULES=NO`, which Xcode 26 needs for the CocoaPods modules. If
you build by hand and get `Unable to find module dependency: 'CTweetNacl'`, add it.)

**"The test runner failed to initialize for UI testing": a permission prompt is waiting.** See step 5.
Log in, answer it, re-run.

**The runner is Offline on GitHub.** Usually the `ci` user got logged out, or the Mac restarted without
auto-login. Log in as `ci`. The LaunchAgent starts the runner by itself (`~/actions-runner/svc.sh
status` to check).
