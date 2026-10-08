# Isolated logic tests

The logic suite uses an app host. A shipping bundle identifier would make `UserDefaults.standard`
point at the developer's normal preferences, even when app startup is suppressed. Always build the
canonical `.logictests` host and verify its artifacts before running tests. The host also uses a
separate shared-helper suite and registers no URL handlers. Its startup guard rejects mismatched
test flags and bundle identifiers before AppKit loads the storyboard.

On the shared development Mac, first run `~/focusbear-handover/machine-ok-coord.sh` and proceed only
when it exits successfully. Use a dedicated derived-data directory; never reuse the installed app's
build products for tests.

```bash
set -euo pipefail
LOGIC_DERIVED_DATA="$(mktemp -d /tmp/focusbear-logic-tests.XXXXXX)"
xcodebuild build-for-testing \
  -workspace FocusBear.xcworkspace -scheme 'Focus Bear' -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath "$LOGIC_DERIVED_DATA" \
  FB_BUNDLE_ID_SUFFIX=.logictests CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION=YES
LOGIC_TEST_MANIFEST="$(python3 scripts/verify-logic-test-host.py \
  --products-directory "$LOGIC_DERIVED_DATA/Build/Products")" || exit 1
xcodebuild test-without-building -xctestrun "$LOGIC_TEST_MANIFEST" \
  -destination 'platform=macOS' -parallel-testing-enabled NO \
  -only-testing:'Focus BearTests/LogicTestHostTests'
```

Add selectors for the logic suites being changed. The CI workflow contains the full curated list. Its trusted runner additionally requires a
build-capable `test` action after artifact verification, using the same explicit isolated build
settings and derived-data directory; do not bypass that runner guard.
The preflight rejects shipping IDs, URL handlers, unexpected host paths, missing logic-host flags,
UI test bundles and ambiguous manifests. Do not bypass a refusal or launch the test app manually.
Ordinary Xcode Test without the isolated build setting is intentionally refused at startup.

The artifact verifier and stripping script have pure fixture tests that do not launch the app:

```bash
python3 scripts/test-logic-test-host-isolation.py
```

UI tests have a different identity and account-isolation workflow; see [ui-tests.md](ui-tests.md).

CI limits both build actions to two concurrent Xcode jobs. Before either action, the capacity gate
waits for at least 20% free memory, a one-minute load below 20, and no existing `xcodebuild` process.
Unavailable or malformed probes refuse to proceed. It polls every 30 seconds for up to 10 minutes;
if capacity never becomes available, the step fails without starting the build. Each probe has a
10-second timeout, so an in-flight probe may finish shortly after the overall wait deadline.
This reduces contention on the shared Mac but is not a reservation against other agents starting work.
The gate's synthetic tests use mocked commands: `python3 scripts/test-build-capacity.py`.
