# Managed school and home blocking on macOS

The app consumes the published school/home policies from backend PR [2370](https://github.com/Focus-Bear/backend/pull/2370). Managed website enforcement runs independently of focus sessions, habits, breaks, personal schedules, teacher sessions and ordinary buddy unlocks. A managed allow continues through the existing personal/teacher restrictions. This uses observed browser URLs and redirects; network filtering is outside this feature.

## Student settings and safety visibility

The SwiftUI policy inspector shows school and parent ownership, the active schedule, selected category labels, unknown/unavailable behavior, time zones, recurring windows, allowed website exceptions, excluded dates and synchronization status. Categories are identified as configured restrictions; the screen does not claim that every category has complete classifier coverage. Empty category selections disable category blocking, including the fallback rules, matching the backend.

Managed students cannot mutate legacy personal block lists or general blocking settings. The home editor requests a device-bound, expiring parent approval for the nine home-policy fields. Editing prepares a separate draft; submitting sends the exact proposal for the parent's final server-side confirmation. It cannot change the school policy or locally unlock settings. Parents can use the dashboard approval inbox. The mobile parent approval workflow remains a separate launch dependency.

The Figma plugin is connected, and the newer overall-session design file is accessible. The requested [older block-list design](https://www.figma.com/design/ULUYn4BTeP7siyAGFAEkq4/Sid-Focus-Bear-Design?node-id=5436-95408) denies edit access through the connection, so the complete personal SwiftUI block-list replacement remains pending access to that file. The reusable managed inspector/editor are functional interim components; this change does not claim to implement that unseen design. Unmanaged accounts retain the existing personal block-list layout until the design is available.

## Offline behavior and reporting

Snapshots use authenticated HTTPS and local OS-protected storage. They are not server-signed policy documents. The backend supplies schema version, server time, a stable snapshot identifier and an offline expiry. Its 24-hour lease is a development default; the school must explicitly configure the lease and recovery behavior before rollout.

The running app anchors schedule time to trusted server time plus monotonic elapsed time. A process restart, clock uncertainty, expired lease or unverifiable cache enters visible recovery until the server supplies fresh trusted time. Recovery keeps settings locked and permits only the documented essential Focus Bear sign-in/help hosts. The app does not trust a changed wall clock to disable school hours. In-process offline checks use valid classification cache where available, otherwise the published unavailable-result rule.

Blocked-attempt reports queue durably with domain and exact-resource hash, without raw URLs or page bodies. The queue is bounded and has an explicit unsynced/lost reporting state. Correlated upload results distinguish accepted events from terminal rejections; one old assignment cannot poison the remaining queue. Reports are observations by the running app, not proof that content was viewed.

Device receipts distinguish applied policy revisions from connectivity and permission health. They are explicitly device-reported. Strict appeals use the backend's existing classifier and dedicated review service. Any approved revisit requires fresh server verification; no portable offline appeal override is cached.

## Validation and dependencies

- `ManagedPolicyTests` uses the same 55 policy and 21 URL conformance cases as the backend and Windows, plus wire decoding, device/revision/expiry binding and recovery host checks.
- `ManagedHomeDraftTests` verifies exact payload preservation, separate drafts, recurrence/date validation and safe exception editing.
- `scripts/check-managed-blocking-translations.py` checks English/Spanish keys, placeholders and literal string references. Shared remote copy is in assets PR [453](https://github.com/Focus-Bear/assets/pull/453); the existing config/assets gate requires that companion to land.
- Full compilation and tests run in GitHub Actions on the configured self-hosted Mac runner, as requested by the user. Validation jobs are coordinated serially; the DEBUG logic host loads bundled configuration without starting the normal auth/UI session. Docker and local database servers are not required.

Safari and compatible Chromium browsers use the existing serialized AppleScript bridge, with a window/tab/URL check in the same script as navigation. Firefox requires the bundled extension version 1.1 (managed navigation protocol 2): the app checks recent capabilities and waits for the extension to acknowledge conditional navigation. Older extensions report missing capability. The local Firefox bridge binds to loopback and rejects ordinary website origins. SigmaOS reports unsupported managed enforcement because its address-bar automation cannot provide the required conditional navigation guarantee. Missing permissions and failed redirects are visible in device health.

The native PR is a draft until full validation, the Figma replacement, and supported-browser/permission/manual acceptance checks are complete. Backend/model deployment, production migrations, provider coverage validation and rollout approval are separate from creating these PRs. Windows implementation is tracked in [Windows PR 1522](https://github.com/Focus-Bear/windows-app-v2/pull/1522).
