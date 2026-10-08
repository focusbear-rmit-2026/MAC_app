# Classroom mode: school and home blocking schedules

Planning draft · 8 September 2026 · No implementation changes

Build two separately owned schedules: a school master assigned to students, and a home schedule editable by parents through a new accountability-buddy permission. Enforce the school policy independently of personal focus sessions. Extend the safety-model project into a category classification service, with the school policy deciding which results block access.

Confirmed scope: support both macOS and Windows enforcement, with the mobile app used by parents to approve unlocking settings edits. Students cannot edit settings; settings are locked by default and require parent authority. Parents and schools can review attempted-access violations, and students can appeal a safety-model block to a strict LLM. Email parent-authorised changes, including changes made through a potentially compromised parent account; school-initiated changes do not send these emails.

Enforce website policies through Focus Bear's existing supported browser/app blocking mechanisms. Network filtering is out of scope, including traffic interception, DNS/VPN enforcement and network or browser-runtime inspection. Category enrichment may consume existing provider verdicts about URLs; this feature does not build those providers' detection mechanisms.

## 1. Product behaviour

### School master schedule

- School administrators create named master schedules and assign students directly or through school cohorts/classes. Start with one effective school master per student; show conflicting assignments and require an explicit resolution before publishing.
- A master contains weekly time windows, the school's IANA time zone, selected blocked categories, website allowlist exceptions, and excluded dates/date ranges such as holidays or pupil-free days.
- Editing a master updates its assignments through a new published revision and records the change in policy history. School-initiated changes do not generate parent change emails. Do not copy mutable school settings into each student's personal focus mode.
- Preview affected students, category changes, exception dates and next active periods before publishing. Keep revision history and offer rollback by publishing a new revision.
- Students and parents can inspect the school schedule and request an exception. Only a school administrator, or a staff member explicitly delegated this permission, can change it or remove its assignment.
- After school-managed enrolment is established, recurring windows activate automatically without a daily join/decline prompt. Preserve the existing invitation flow for ad hoc teacher sessions.

### Home / out-of-hours schedule

- Create a separate schedule per student from a school-provided starter template. Subsequent school template changes do not silently overwrite family edits.
- Parents accept a verified invitation as a **managing accountability buddy** for that child. Their capabilities cover the child's home policy and an explicit set of parent-manageable app settings. School policy, school assignment and supervision grants remain separately protected.
- Parents can change home times, selected categories and allowlist, and enable or disable the home schedule. Students cannot edit the home policy or other settings. Settings remain locked by default on both desktops, including general settings that could weaken blocking; a student account has no independent write permission.
- Parents use the mobile app to approve a scoped, short-lived settings-edit session on the child's Mac or Windows device. They may also edit through an authenticated parent management screen. The mobile approval workflow below defines how a desktop change becomes parent-authorised without granting the student a reusable settings unlock.
- Email every committed parent-authorised change to all accepted parent managers, including the acting parent. This also alerts a parent if someone has gained control of their account.
- Home windows apply only when the school schedule is inactive. Their own recurrence determines coverage during evenings, weekends and excluded school dates; excluding a school holiday does not itself turn on 24-hour home blocking.
- Persist a separate IANA time zone for the home schedule, initially copied from the school's zone. A parent manager can change the home zone with an audit/email notice; a device's travel or time-zone setting does not change either policy. Students cannot move either schedule by changing their device clock.
- Show a calendar preview of the combined school and home timetable, including unprotected periods. If a parent extends a home window into school hours, the overlapping portion has no effect on the school policy.
- Students cannot remove parent managers, demote their role, change their email recipients, or disable the mandatory change notifications. Provide an authorised relationship-removal/recovery process.

### Roles and boundaries

| Action | School policy administrator | Parent manager | Student | Existing ordinary buddy |
| --- | --- | --- | --- | --- |
| Create/publish school master; edit holidays/categories/allowlist | Yes, within own school | No | No | No |
| Assign/reassign school students | Yes, within own school | No | No | No |
| View assigned school policy | Yes | Own linked children | Own policy | No new access |
| Edit home policy / parent-manageable app settings | Seed template; no ongoing home edit right by default | Own linked children | No | No |
| Approve desktop settings-edit session in mobile app | No implicit parent authority | Own linked children, scoped and expiring | Request only | No |
| Receive parent-authorised change emails | No by default | All accepted parent managers, including acting parent | No new entitlement | No new entitlement |
| View school-initiated change history | Own school policies | Assigned school policy | Own assigned policy | No new entitlement |
| Grant/remove parent management | Verified school enrolment or authorised recovery flow | Governed relationship workflow | Cannot self-remove supervision | Cannot self-promote |
| Approve a manual exception to school policy | Explicit school permission | No | Request only | No |
| Appeal safety-model block to strict LLM | Review audit/outcome | Review child's audit/outcome | Submit educational justification; no self-approval | No new entitlement |
| View attempted-access violations and appeal outcomes | Enrolled students, authorised school role | Own linked children | Own block/appeal result | No new entitlement |

Being a teacher, a billing administrator, or an ordinary buddy must not implicitly grant either new policy-edit permission. Invitations alone confer no access; grants are directional, child-specific, revocable and checked server-side on every operation. Activation of parent-managed home settings requires at least one accepted parent manager; show incomplete onboarding explicitly.

### Parent approval from the mobile app

1. The locked desktop settings screen can request parent assistance. The server creates a pending request bound to the child, desktop device, current settings/policy revisions and allowed settings scope; the request grants no edit rights.
2. Notify accepted parent managers in the mobile app. The parent authenticates, sees the child, requesting device and scope, and approves or rejects. Notification payloads/deep links only open the request; they are not authorisation tokens.
3. Approval opens an expiring, parent-authorised settings editor on the requesting desktop. The student's normal credentials still cannot save settings. Recommended default: one edit transaction, a five-minute session, and a final before/after confirmation on the parent's phone to authorise the exact save. This allows assistance on the desktop without treating whoever is at the keyboard as the parent.
4. The server binds the approved diff, parent identity, device, scope and expected revision into a single-use commit authorisation. It rechecks the active parent grant and revision at save, records the approving parent separately from the submitting desktop account, commits the audit/email intent, and relocks settings after save or expiry.
5. Rejection, timeout, revocation, stale revision, replay or connectivity loss cannot unlock settings or apply an unapproved change. The session never permits school-policy edits, supervision removal, unrelated account changes or a global pause of blocking. A direct parent edit uses the same authorisation, audit and email service.

## 2. Current implementation and implications

Local repositories are on different branches. Observations below describe inspected code, not verified production deployment. Pin the common release baseline before implementation.

| Area | Observed implementation | Planning implication |
| --- | --- | --- |
| Mac classroom sessions | Teacher invite/join, versioned allowlist updates, heartbeats and current-session recovery exist in `teacherSessionManager.swift`. | Reuse enrolment/session integration and status patterns; recurring assignment is a separate lifecycle. |
| Mac personal schedules | A schedule references a personal focus mode, uses `Calendar.current`, and has no school owner, policy revision or holiday exclusions. | Introduce a dedicated managed-policy model and school time zone. |
| Mac activation | Personal schedules wait for routines, breaks and focus sessions to finish, then start the first matching schedule. | School enforcement must run as a separate active-policy layer, including during those activities. |
| Mac URL blocking | Foreground-tab polling and redirects, with personal unlocks, AI toggles and several early allow paths. | Route every supported enforcement path through a managed-policy check before personal allow/unlock decisions. |
| Windows classroom and personal schedules | Teacher sessions, versioned updates and recovery exist; personal schedules skip focus/habit/break states and use local times/first match. | Add a Windows managed evaluator alongside Mac; compose with existing teacher sessions and bypass no school rules through personal schedule state. |
| Windows blocking and appeals | Browser/app dispatch, generic buddy unlocks and a personal “Convince AI” flow exist. | Integrate managed checks before shortcuts; add scoped mobile-approved settings sessions, category decisions, violation upload and the strict safety appeal. |
| Parent mobile app | Self-account schedule/settings APIs, a local friction-password gate and push transport exist; no human buddy approval flow was found in the inspected source. | Build linked-child management, a request inbox, mobile approval/final-diff confirmation and violation history as an explicit mobile workstream. |
| Backend school foundation | Local `origin/main` has school hierarchy and school roles. Existing school session windows govern when teachers may start sessions. | Reuse organisation membership; those windows are not a recurring school blocking engine. |
| Accountability | Existing human buddy invitation/unlock flow has no home-settings management grant; approval can open a generic local unlock window. | Add a scoped capability and child-policy API; ordinary unlocks must not bypass managed policies. |
| Safety model | Four-category prototype: pornography, violence, drugs, crime; rules/domain lists plus optional semantics. | All 39 requested labels need an explicit coverage and evidence plan. |

The classifier currently treats absence of a signal as `allow`. Trusted hosts can also bypass content checks; its suffix comparison accepts lookalike hosts such as `evilwikipedia.org`. Fix this before school use. The bundled rule-only evaluation on 4,737 domains produced precision 0.922 and recall 0.091; this is a limitation of that particular corpus/configuration, not a production accuracy estimate. The optional semantic test was skipped in the inspected environment.

## 3. Schedule and policy evaluation

Use a deterministic evaluator with the same contract and shared test fixtures across backend and clients:

1. Resolve authenticated enrolment, current assignment and published policy revisions.
2. Evaluate school recurrence in the school-owned time zone, using half-open windows `[start, end)`. Support overnight windows and reject accidental zero-duration windows; represent all-day explicitly.
3. Suppress school enforcement on excluded **local calendar dates**, including the portion of an overnight window that falls on an excluded date. Store dates as dates, not UTC midnight timestamps. End dates entered in the UI are inclusive.
4. When school policy is active, evaluate it; otherwise evaluate the student's home windows in the persisted home time zone. Apply the same window/DST/date-boundary rules to each policy's own zone. Personal focus restrictions and ad hoc teacher sessions may add restrictions on top.
5. Normalise the URL and evaluate allowlist exceptions belonging to each active policy. An exception overrides that policy's selected category restrictions only; it cannot override another independently active policy.
6. Classify the resource and compute a provisional denial if any detected category is selected by an applicable policy. Multi-category sites match any selected blocking category. Apply the owner's explicit unknown/unavailable-result behaviour without yet enforcing or logging a violation.
7. Apply any valid, server-issued LLM appeal exception for this student, resource, category and policy revision. It can waive the reviewed safety/category denial for a justified educational use, but does not edit settings or waive other categories/policies outside its scope.
8. Combine applicable decisions and enforce any remaining block. Only a final managed-category denial records an attempted-access violation and offers the strict safety appeal; a valid approved revisit does not create another violation for the waived denial. Return the controlling policy, revision, matched category/exception/appeal, explanation and next transition. The original appealed denial stays linked to its corrected outcome.

A teacher-session unlock changes that session only. Personal allowed URLs, buddy unlock codes, breaks, snooze and home edits cannot waive a school category decision. School-authorised manual exceptions and the dedicated strict LLM appeal are the explicit routes to an exception; the existing generic relevance chat does not grant one. During home windows, parent-initiated pauses or overrides require parent authorisation, a server commit and a parent notice. LLM appeal exceptions are separately logged automated decisions; they do not unlock settings or trigger parent-change emails.

Example: the school blocks Games and Social Networking Monday–Friday 08:30–15:30, with an approved learning site excepted. At 10:00 a parent allowing a social site in the home schedule has no effect. At 15:30 the configured home schedule applies. On an excluded holiday, the school schedule is inactive and the home recurrence determines coverage.

### URL exception contract

- Support exact host and exact URL/path-prefix entries with an explicit “include subdomains” choice. Match parsed host/path components with boundaries; never use raw substring or unrestricted suffix matching.
- Canonicalise scheme, IDNs, ports, trailing dots and IP literals; preserve path/query distinctions where they affect classification. Recheck redirect destinations and navigation changes.
- Store author, reason and optional expiry. Preview the categories an exception will bypass, including any threat categories. Make school decisions explicit instead of embedding a global trusted-host override in the classifier.
- Keep required application recovery/block-page access narrowly scoped. Localhost, private networks, school intranets and identity providers need deliberate handling when Private IP Addresses, Web-based Email or Unknown is blocked.

## 4. Safety-model expansion and the 39 requested categories

Preserve every supplied display label and introduce stable internal IDs in a versioned registry. Category selection is school-configurable; do not silently enable every label or substitute the existing four labels. Offer editable presets once the school validates them against its learning resources.

The labels correspond to content, threat, risk and operational categories in the [Palo Alto Networks URL category documentation](https://docs.paloaltonetworks.com/advanced-url-filtering/administration/url-filtering-basics/url-categories). Browser Runtime Attack and Real-time Detection describe the external source's detection provenance; this feature consumes available URL verdicts for those labels. Not-Resolved describes a category lookup failure rather than DNS NXDOMAIN. Exact compatibility requires documented definitions and suitable evidence sources; this plan does not assume a licensed provider or API is available. A label without an available source remains explicitly unsupported rather than becoming a network-filtering workstream.

The following is the required capability inventory, not a claim of current support:

| Requested label | Proposed stable ID | Evidence needed |
| --- | --- | --- |
| Adult | `adult` | Domain/page classification; adapt existing pornography signals and validate scope |
| Auctions | `auctions` | Site-purpose/category data |
| Browser Runtime Attack | `browser_runtime_attack` | Existing provider URL verdict with documented runtime-detection provenance |
| Command and Control | `command_and_control` | Current URL/domain threat intelligence |
| Compromised Website | `compromised_website` | Current URL/domain compromise intelligence or provider verdict |
| Copyright Infringement | `copyright_infringement` | Curated/provider category evidence with review process |
| Cryptocurrency | `cryptocurrency` | Site-purpose classification; distinguish services from educational discussion |
| Dating | `dating` | Site-purpose/category data |
| Dynamic DNS | `dynamic_dns` | Dynamic DNS service/domain data |
| Encrypted DNS | `encrypted_dns` | Known resolver website/endpoint categories for URLs observed by Focus Bear |
| Extremism | `extremism` | Curated/page classification with educational-context evaluation |
| Gambling | `gambling` | Site-purpose/page classification |
| Games | `games` | Site-purpose/page classification |
| Grayware | `grayware` | Reputation / security intelligence |
| Hacking | `hacking` | Defined site-purpose classification; educational security negatives |
| High Risk | `high_risk` | Documented provider/risk scoring with freshness |
| Insufficient Content | `insufficient_content` | Page/metadata inspection with explicit criteria |
| Internet Portals | `internet_portals` | Site-purpose/category data |
| Malware | `malware` | URL/domain threat intelligence or provider verdict |
| Medium Risk | `medium_risk` | Documented provider/risk scoring with freshness |
| Newly Registered Domains | `newly_registered_domains` | Registration data and documented age threshold |
| Not-Resolved | `not_resolved` | Category lookup unavailable after cache miss; separate from DNS resolution errors |
| Parked | `parked` | Domain/page classification |
| Peer-to-peer | `peer_to_peer` | Site-purpose/category data for peer-to-peer service websites |
| Phishing | `phishing` | Threat feeds / phishing detection |
| Private IP Addresses | `private_ip_addresses` | Parsed IP/host/address-scope rules with IPv4/IPv6 and intranet definitions |
| Proxy Avoidance and Anonymizers | `proxy_avoidance_and_anonymizers` | Service/domain categories for proxy and anonymizer websites |
| Questionable | `questionable` | Explicit rubric and labelled page/domain data |
| Ransomware | `ransomware` | Current URL/domain threat intelligence or provider verdict |
| Real-time Detection | `real_time_detection` | Existing provider URL verdict with documented inline-detection provenance |
| Remote Access | `remote_access` | Service/domain categories for remote-access websites |
| Scanning Activity | `scanning_activity` | Existing provider URL/domain threat-intelligence verdict |
| Shareware and Freeware | `shareware_and_freeware` | Site-purpose/category data |
| Social Networking | `social_networking` | Site-purpose/page classification |
| Streaming Media | `streaming_media` | Site-purpose/page classification |
| Unknown | `unknown` | Successful classification attempt with no known category; distinct from unavailability |
| Weapons | `weapons` | Domain/page classification with educational-context evaluation |
| Web Advertisements | `web_advertisements` | Ad domain/URL categories for navigations observed by Focus Bear |
| Web-based Email | `web_based_email` | Service/domain/page categories |

### Classification contract

- Separate **classification** from **policy enforcement**. Category results must not contain a universal “school-safe” verdict. Existing personal relevance behaviour can use a compatibility adapter.
- Return `taxonomy_version`, model/feed versions, normalised resource key, multiple category IDs, per-category evidence/source and calibrated confidence where meaningful, `observed_at`, `expires_at`, and classification status.
- Model `classified`, `unknown`, `unavailable` and `unsupported` separately. Track which requested capabilities were actually evaluated so partial coverage cannot be mistaken for complete classification. Never convert service errors or unsupported categories into “safe”.
- Keep policy decisions keyed to assignment/policy revision separately from reusable classification caches. Include URL granularity, content identity, taxonomy and model/feed versions in cache keys as appropriate. A new holiday, allowlist, category selection or revocation invalidates decisions immediately.
- Use the new safety-model repository for the shared classification pipeline: local rules/cache and optional packaged model, backend category/threat enrichment, then constrained classification review where needed. Add the strict student-initiated LLM appeal below to correct a false classification or approve a narrowly justified educational use. Keep it distinct from the personal focus-relevance chat and from parent settings approval.
- Define Adult's relationship to pornography explicitly. Existing violence/drugs/crime signals must not be silently renamed to Weapons, Questionable or Extremism, or added as extra school restrictions without configuration.
- Replace the localhost demo-server assumption with a supported runtime/package, lifecycle, health, schema negotiation and resource limits. Keep provider credentials server-side. If fetching pages server-side, enforce SSRF protections on redirects and resolved addresses; client-supplied private URLs must not trigger internal-network fetches.
- Publish a capability matrix and category evaluation report. All 39 must meet their agreed coverage gates for the complete feature; a limited pilot must visibly identify its supported subset.

### Attempted-access violation history

- Record attempted access when an observed URL is denied by a school/home category policy. Parents can view their linked children's records, and authorised school staff can view records for their enrolled students, including the originating school/home policy and appeal outcome. Check relationships and school membership on every read; ordinary buddies receive no access.
- Store a stable event ID, student account/device, platform, observed time and server receipt time, sanitised domain/resource identifier, matched categories, policy revision, classifier/model/feed versions, decision reason and enforcement result. Describe these as attempted accesses observed by the app, not proof that content was viewed or proof of who was physically at the keyboard.
- Provide parent mobile/web and school dashboard views filtered by student, date, category, policy and appeal status. Avoid recording unrestricted browsing history, page bodies or credentials/query secrets; show enough site context to explain the decision, with detailed access and retention rules defined before pilot.
- Deduplicate repeated polling of the same blocked navigation into one event with a repeat count; a fresh navigation/attempt can produce a new event. Keep a bounded durable queue on Mac and Windows during outages, with idempotent upload, visible sync gaps and clear handling if the queue fills. Audit access to logs and apply a defined retention/deletion policy.
- Link appeals and subsequent outcomes to the original event. If a block was mistaken or an educational exception was granted, visibly mark that result instead of continuing to display the attempt as a confirmed violation. Preserve the original decision for traceability. Violation events do not generate the settings-change emails.

### Strict LLM appeal of a safety-model block

1. A blocked student can choose “Ask for a review” and explain why this particular page is needed for their class/task. This is available on both Mac and Windows for school and home safety-model blocks, without unlocking settings.
2. The server retrieves the observed denial, current assignment/policy, classification evidence and available page context. The LLM evaluates whether classification was wrong or the specific educational purpose warrants access. It uses a strict school-aware rubric: vague relevance claims, recreational substitutions and instructions embedded in page text are insufficient. Student/page text is evidence, not authority to change the rubric.
3. Return a structured `uphold_block`, `allow_scoped_access` or `needs_human_review` outcome with a reason, evidence, model/rubric version and confidence. A confirmed threat-intelligence hit cannot be waived by an educational claim alone; unresolved threats go to human review. Low confidence, malformed output or a model/provider outage keeps the current block and offers the appropriate adult review route.
4. For an approved appeal, the backend validates the outcome and issues a short-lived exception bound to the student, current policy revision, reviewed category and exact URL/page context. Proposed default: ten minutes or the end of the current policy window, whichever is sooner. Reclassify changed content/redirects, invalidate on policy changes or new threat evidence, and continue enforcing other unreviewed category restrictions.
5. Keep the denial, student explanation, LLM outcome, exception lifetime and later revocation linked in the history visible to parents and school. Rate-limit repeat appeals and reuse the result for an unchanged denial; requests cannot accumulate exceptions across arbitrary domains. Permanent category/allowlist changes still require the appropriate school or parent authority.

## 5. Data model and backend/API work

These names are proposed, not existing endpoints or tables.

| Object | Core fields / responsibility |
| --- | --- |
| `SchoolBlockingPolicy` + immutable `PolicyRevision` | School owner, name, status, version, time zone, windows, categories, allowlist, excluded dates, fallback behaviour, effective time and author |
| `PolicyAssignment` | School membership/student, policy, source cohort or direct assignment, validity dates, version; deterministic conflict prevention |
| `HomeBlockingPolicy` | Student owner, template origin, revision, IANA time zone, recurrence, categories, allowlist, enabled state; separate from the master |
| `BuddyManagementGrant` | Child, accepted buddy/parent account, home-policy/app-settings capability scope, inviter/verifier, status, grant/revoke timestamps and notification entitlement |
| `SettingsEditRequest` + `ParentEditSession` | Child, requesting desktop/device, approving parent/grant version, permitted fields, base revision, nonce, expiry, approved diff hash, consumed/revoked state; no student role elevation |
| `ManagedAppSettings` | Child and revision; explicit parent-managed settings schema, default lock, authorisation and references to settings that can weaken blocking |
| `PolicyChangeEvent` | Immutable authenticated actor/authority, submitting account/device, subject, scope, before/after diff, revision, timestamp, reason and idempotency key; server-derived parent/school/system origin |
| `NotificationOutbox` | Change event + recipient account + template/version + delivery state, attempts and deduplication key |
| `DevicePolicyReceipt` | Device/user, supported schema/taxonomy/capabilities, applied assignment and policy versions, last sync, app blocking health |
| `ViolationEvent` | Student/device/platform, event/receipt timestamps, sanitised resource, matched categories/policies, classifier version, block result, repeat count and sync state |
| `SafetyAppeal` + `AppealException` | Original violation/denial, student explanation, evidence, model/rubric version, decision/reason, reviewed category/policy, resource scope, expiry and revocation |

API work:

- Add school-scoped policy draft/preview/publish/history/rollback and bulk assignment operations, enforcing tenant membership and the dedicated permission on every request.
- Add child-scoped home-policy and managed-app-settings APIs plus managing-buddy invitation/acceptance/revocation flows. Student writes are denied across new and legacy routes. Reuse authentication and invitations where compatible; accepting a normal buddy invite must not grant management.
- Add settings-edit request/status/inbox, mobile approve/reject, final-diff authorisation and scoped commit/revoke endpoints. Validate parent identity, active grant, child/device binding, allowed fields, revision, nonce and expiry server-side. Do not reuse the existing shared friction password or generic buddy unlock deadline as parent authorisation.
- Add an effective-policy snapshot endpoint for each authenticated device and version-change notifications. Push triggers a fetch; it is not the sole source of truth. Refetch on launch, wake, reconnect and periodic reconciliation.
- Require expected revision (`If-Match` or equivalent) on edits; reject stale writes with a visible conflict. Use idempotency for mutations, including bulk publication and email events.
- Route all school/home-policy and managed-settings mutations from web, Mac, Windows and mobile through the same authoriser and audit transaction. Enqueue email intent only for committed parent-authorised changes; derive origin from authenticated authority, never a caller-supplied “school change” flag. Audit create, delete/disable, category/allowlist/timing/exclusion changes, assignments, restore, supported overrides and permission/recipient changes. Changes to referenced shared lists must produce affected-policy events too, or those lists must be revision-pinned.
- Keep managed policy out of legacy general-settings JSON writes and personal schedule endpoints. Old clients must not overwrite/delete school assignments or remove policies because a personal focus-mode ID is missing.
- Define enrolment, cohort moves, school departure, parent replacement and account recovery transitions. Removing an assignment is authorised and audited; parent access does not reveal other students or unrelated child data.
- Add idempotent violation ingestion and access-controlled history queries for parent mobile/web and school dashboard. Link denied events and appeals; validate event structure and enrolment/device claims and expose incomplete offline evidence without treating client logs as tamper-proof.
- Add student appeal/create/status endpoints and a strict server-side review service. Validate the actual denial and current policy independently of client input, audit the structured result, issue/revoke scoped exceptions, and reconcile them on both desktops. No appeal grants settings-write privileges.

### Parent emails

Every committed **parent-authorised** home-policy, managed-settings or permitted supervision/recipient change creates an immutable event and recipient-specific email intent **in the same database transaction**. Send to every accepted parent manager, including the parent who authorised it. A change committed through a mobile-approved desktop session is parent-authorised and follows the same path. Do not rely on the student device to send or report the edit.

Email contains child, authorising parent, submitting device/session, local time/time zone, changed fields with before/after values, effective time, and an authenticated link to inspect/revert or report an unrecognised change. It contains no browsing history or raw page content. Example: “Alex's home schedule was changed using Sam's parent account at 17:42: Games changed from blocked to allowed.” Record authenticated authority rather than claiming to know who physically used the account.

Deduplicate on event + recipient; retry transient failures, retain permanent failure status and surface it to authorised adults. Track provider acceptance separately from delivery/bounce status. A committed change survives a mail-provider outage and its notice stays queued. Distinct parent-authorised edits remain individually notified; duplicate sync requests and no-op saves create no duplicate edit notices. A parent account cannot suppress its own change notice. Handle recipient/grant changes separately from ordinary settings edits, notifying the appropriate previously verified and new authorised recipients without exposing later child data to revoked accounts.

School-initiated policy, assignment and administrative changes remain auditable and sync normally, but create **no parent change emails**. Rejected/expired edit requests, successful unlock approval without a save, violation logs and LLM appeal decisions are recorded in their respective histories rather than generating these change emails. An edit made through a compromised parent account still creates a parent-authorised event and email; this is a core purpose of the notification. No emails are sent as part of this planning task.

## 6. Focus Bear enforcement and offline operation

Ship macOS and Windows support together for this enhancement. Each app needs a managed-policy store, deterministic evaluator and category-client interface outside the personal schedule state machine. Share schemas and conformance fixtures while using platform-appropriate persistence and blocking mechanisms. Both show school/home schedules as read-only in student mode, locked settings, a mobile parent-approval request, violation/appeal status and the correct adult review route.

On Mac, integrate before existing allow/unlock/AI early returns in browser, Firefox bridge, habit, background, teacher and personal-session flows. On Windows, integrate with `ProcessBrowserURLs`, foreground app handling, `BlockingScheduleManager`, `TeacherSessionManager`, Pusher/API clients and the settings/tray controls. Preserve platform-specific app identifiers, and keep global buddy unlock deadlines and personal temporary URL allows from bypassing managed decisions. Adapt existing appeal UI to the new strict service and server-issued exception contract.

Keep enforcement active across focus mode changes, breaks, sleep/wake, auth expiry and midnight on both platforms. Schedule exact transition timers plus reconciliation; do not depend on opportunistic personal-session polling to start school policy. Map school/home IANA zones consistently on Windows and Mac, testing identical UTC instants against shared DST/holiday fixtures.

Persist an authenticated, integrity-protected last-known policy snapshot and evaluate its recurrence locally. Pusher disconnects and expired login credentials must not remove it. Parent edits take effect only after server commit; offline drafts cannot change enforcement or bypass mobile confirmation. Local classification caches/feed snapshots support available offline categories. Queue violation records durably; new LLM appeals and parent approvals require the service, while already-issued unexpired appeal exceptions retain only their explicitly permitted lifetime.

Recommended failure behaviour during active school windows: retain the last valid policy; use valid classification cache and explicit school exceptions; treat uncached classification during a provider outage as `not_resolved`, with a school-configured action (recommend block while the school schedule is active). A successful unrecognised lookup is `unknown`, using its independent category setting. Partial or unsupported capabilities show degraded status and follow the published fallback, never silently allow.

Before pilot, set a bounded offline policy/assignment lease and its recovery behaviour with the school. Account removal/revocation cannot propagate instantly to an offline device. Expiry must enter an explicit recovery state with essential access and visible status, not silently disable school control or impose an undocumented indefinite lock. Reconcile time against server/trusted time and detect device time-zone/clock changes.

The release uses Focus Bear's existing supported browser/app blocking mechanisms. On Mac, foreground-tab polling redirects blocked sites and can act after a page begins loading. The category inventory applies to observed website URLs: threat categories use available model/provider evidence, and Web Advertisements covers observed ad-site navigations. Network filtering, tunnel/protocol controls, embedded-ad subresource filtering and runtime exploit prevention are outside this enhancement.

- Pilot the app enforcement paths: document supported browsers, show unhealthy/revoked permissions or app disconnects, and report policy application separately from connection status. An offline app can still enforce its cached policy; a disconnected device's current enforcement state is unverified by the server.
- School ownership and parent permissions are enforced in the backend and app policy evaluator. Adding device management or protection outside the running app is not a workstream or launch dependency for this enhancement.
- Mac and Windows must pass the same policy, parent-approval, violation logging and LLM-appeal acceptance suite before rollout. Mobile parent approval and parent history are launch requirements. Student-side mobile blocking is separate from the required mobile parent workflow and is not implied by this desktop enhancement.

## 7. Delivery sequence

| Work package | Deliverable / exit gate | Dependencies |
| --- | --- | --- |
| 1. Baseline and category coverage | Align backend, Mac, Windows and mobile baselines; define parent-manageable fields, enrolment authority, taxonomy/provider coverage, violation data fields and strict appeal rubric. Produce cost/latency and category coverage evidence. | None |
| 2. Policy foundation | Schema, school permissions, assignment conflicts, time-zone/holiday evaluator, versioned snapshots, audit and capability negotiation. | 1's product contract |
| 3. Safety pipeline and appeals | Fix trust matching, separate classifications/decisions, add 39-category sources, cache/fallback/version contracts, strict student appeal API and scoped exceptions; evaluate false blocks and appeal abuse. | 1's category-source decisions; can run alongside 2 |
| 4. Parent management and notices | Parent-only settings authorisation, scoped requests/sessions, approved-diff commits, concurrency protection and parent-origin email outbox. School-origin events remain audit-only. | 2 |
| 5. Parent mobile workflow | Linked children/devices, managing-buddy onboarding, typed notifications/deep links, persistent approval inbox, reject/approve/final-diff flow and child violation/appeal history. | 2–4 contracts; can develop in parallel |
| 6. School/parent dashboard and history | Master editor, assignment, holiday/calendar preview, URL decision tester, parent-authorised home/settings editor, change history and violation/appeal views. | 2–4 contracts; can develop in parallel |
| 7. Mac integration | Managed policy layer, locked student settings, parent desktop editor, existing blocking-path integration, strict appeal UI, durable violations and policy reconciliation. | 2–5 contracts |
| 8. Windows integration | Equivalent managed policy layer and settings/approval controls, browser/app/teacher integration, strict appeal UI, durable violations and policy reconciliation. | 2–5 contracts; parallel with 7 |
| 9. Pilot and rollout | Both desktops plus mobile parent workflow pass conformance; review educational false positives/appeals, parent-only emails and parent/school violation visibility; staged cohorts and versioned rollback. | 3–8 acceptance gates |

Track backend, dashboard, safety-model, parent mobile, Mac and Windows as separate workstreams under one feature epic. Estimate delivery after confirming category-source coverage and the mobile approval/strict appeal contracts. The rollout must preserve ordinary personal schedules and ordinary buddy permissions. Migrating an existing buddy to manager requires an explicit verified grant.

## 8. Acceptance tests and rollout gates

1. School admin publishes once; assigned Mac and Windows devices fetch and acknowledge the revision. An unassigned student and another school cannot read or mutate it.
2. Student/parent attempts through UI and direct legacy/new APIs cannot edit/delete/disable school policy, change its clock basis, or self-issue an exception. Only authorised school edits or validated scoped LLM decisions can change the applicable school outcome.
3. Student settings are locked by default on both desktops, and student direct API writes fail even with a local password or ordinary buddy unlock. A verified parent can edit only the linked child's home policy and explicitly parent-manageable settings.
4. Each committed parent-authorised edit creates one auditable event and one notice per authorised parent, including the actor. Verify direct parent and mobile-approved desktop edits, compromised-parent-account simulation, retries, temporary overrides, deletion/restore and protected recipient changes. School edits/assignments create audit events and **zero** parent change emails; no-op saves, denied student writes, violations and LLM outcomes also create zero change emails.
5. Recurrence handles DST transitions, overnight windows, excluded dates and inclusive holiday ranges, start/end boundaries, school/home transitions and no active home window. Device time-zone changes move neither policy; a parent home-zone edit affects only home recurrence and produces a notice.
6. On both desktops, school blocking survives personal focus changes, teacher sessions ending, breaks, snooze, personal allowlists, ordinary buddy unlocks, generic AI-chat allows, auth expiry, sleep/restart and network loss within app enforcement limits. Opening a parent editor does not pause blocking.
7. School exceptions work at the intended host/path/subdomain scope, expire correctly, and do not bypass other active policy layers. Test lookalike domains, IDNs, IPv6, redirects and private intranet resources.
8. Maintain labelled examples and educational false-positive examples for **each of the 39 categories**; measure per-category precision/recall, multi-label attribution, unseen domains, multilingual pages, freshness, latency and source coverage. Known-domain lookup success is not evidence of unseen-domain accuracy.
9. Distinguish Unknown, Not-Resolved, insufficient content and unsupported source coverage; test service timeout, model unavailable, stale feeds and partial responses. Confirm the configured recovery access works.
10. Concurrent edits conflict visibly; stale pushes are ignored; missed pushes reconcile; rollback publishes a new revision and re-evaluates caches. School departure and grant revocation propagate and stop unauthorised access.
11. School admins can see applied versus pending policy versions and enforcement health per supported device. Measure propagation delay and classification latency before setting supported service targets.
12. Parent mobile inbox/push routes to the correct child/device and requires authentication. Wrong parent, device or scope, expired/revoked session, replay, altered approved diff and stale revision are rejected. Successful final-diff approval permits exactly one save; settings relock on save/cancel/expiry. Push failure is recoverable through the request inbox.
13. Both desktops record category-denied attempts visible to the linked parent and authorised school staff. Validate school/child isolation, minimised fields, polling deduplication, fresh repeated attempts, bounded offline queue/replay and retention. Successful appeals mark the original record as overturned or educationally excepted; they do not erase the attempt or imply confirmed wrongdoing.
14. A student can appeal a school or home safety block on either desktop with an educational justification. Test a genuine false positive and a necessary educational use obtaining scoped access, unconvincing/adversarial claims remaining blocked, threat evidence and uncertainty requiring review, and service errors preserving the block. Check resource/category scope, expiry, changed page/redirect, policy revision, repeat-rate limits and parent/school visibility; no appeal unlocks settings.

## 9. Product decisions to confirm before implementation

- Confirm the desired category definitions/provider compatibility, selected default categories, home starter hours, and school-approved unknown/outage/lease-expiry behaviour. Defaults are editable policy choices rather than classifier assumptions.
- Confirm who establishes/removes school enrolment and verifies parent management, and whether teachers receive delegated master-policy permissions.
- Confirm the parent-manageable general-settings schema, settings-session lifetime/final-diff UX, violation retention/detail access and strict LLM rubric/exception duration. Parent-only editing, mobile approval, Mac and Windows support, violation visibility, student LLM escalation and parent-only change emails are settled requirements.

These decisions do not prevent planning the shared architecture; they gate the relevant implementation and launch behaviour.

## 10. Evidence and review scope

Source permalinks were checked against local git objects. Opening them requires access to the corresponding GitHub repositories, including `Focus-Bear-research/FocusBear-Distraction-Detection-Model`; remote accessibility of the research repository was not verified.

- Windows checkout `9a54486f`: [teacher sessions](https://github.com/Focus-Bear/windows-app-v2/blob/9a54486fce507813b3c6c84342e79fe639261a55/Focus/TeacherSessionManager.cs#L343), [personal schedule activation/time handling](https://github.com/Focus-Bear/windows-app-v2/blob/9a54486fce507813b3c6c84342e79fe639261a55/Services/BlockingScheduleManager.cs#L301), [browser dispatch](https://github.com/Focus-Bear/windows-app-v2/blob/9a54486fce507813b3c6c84342e79fe639261a55/Utils/ProcessBrowserURLs.cs#L56), [existing Convince AI flow](https://github.com/Focus-Bear/windows-app-v2/blob/9a54486fce507813b3c6c84342e79fe639261a55/Focus/GentleBlock.xaml.cs#L759), and [generic buddy unlock](https://github.com/Focus-Bear/windows-app-v2/blob/9a54486fce507813b3c6c84342e79fe639261a55/AccountabilityBuddy/AccountabilityBuddyManager.cs#L74). These are integration points, not an implementation of the new policy or strict safety-appeal contract.
- Mobile checkout `b7fa6266`: [self-account API routes](https://github.com/Focus-Bear/mobile-app/blob/b7fa62666de3fa01ff74ddd1c8eb8aa694e00f0e/src/utils/ApiUrls.js#L3), [authenticated requests](https://github.com/Focus-Bear/mobile-app/blob/b7fa62666de3fa01ff74ddd1c8eb8aa694e00f0e/src/utils/ApiMethod.js#L8), [existing local password gate](https://github.com/Focus-Bear/mobile-app/blob/b7fa62666de3fa01ff74ddd1c8eb8aa694e00f0e/src/modals/VerifyPasswordModal.js#L101), [push handling](https://github.com/Focus-Bear/mobile-app/blob/b7fa62666de3fa01ff74ddd1c8eb8aa694e00f0e/src/utils/PusherMethods.js#L158), and [deep-link routes](https://github.com/Focus-Bear/mobile-app/blob/b7fa62666de3fa01ff74ddd1c8eb8aa694e00f0e/src/navigation/deepLinkConfig.ts#L25). The inspected `src` tree did not contain a human-buddy mobile approval workflow; the cited files were unchanged despite unrelated working-tree changes.

- Mac checkout `e10be56c`: [teacher session lifecycle](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/Focus%20mode/teacherSessionManager.swift#L8), [policy-free personal schedule model](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/Focus%20mode/customBlockingScheduleData.swift#L27), [activation exclusions](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/Focus%20mode/customBlockingScheduleData.swift#L593), [personal URL gate/unlocks](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/Focus%20mode/focusTimerManager.swift#L50), [AI/snooze switches](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/SettingsManager.swift#L1845), [blocking architecture](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/ARCHITECTURE.md#L220).
- Safety-model checkout `2521b60`: [prototype contract](https://github.com/Focus-Bear-research/FocusBear-Distraction-Detection-Model/blob/2521b60ba2b6be60656b761642c437435904499f/safety_model/README.md#L85), [trust matching](https://github.com/Focus-Bear-research/FocusBear-Distraction-Detection-Model/blob/2521b60ba2b6be60656b761642c437435904499f/safety_model/classifier.py#L174), [classification](https://github.com/Focus-Bear-research/FocusBear-Distraction-Detection-Model/blob/2521b60ba2b6be60656b761642c437435904499f/safety_model/classifier.py#L233), [evaluation](https://github.com/Focus-Bear-research/FocusBear-Distraction-Detection-Model/blob/2521b60ba2b6be60656b761642c437435904499f/safety_model/eval/evaluate.py#L48). Read-only review ran the bundled 14-test suite: 13 passed, one optional semantic test skipped; reproduced the lookalike trusted-host allow and rule-only corpus metrics above.
- Buddy implementation: [Mac buddy data](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/AccountabilityBuddy/buddyData.swift#L9), [generic unlock handling](https://github.com/Focus-Bear/Mac-App/blob/e10be56cff1857cd55fdacc31c8fc79dd0ad33ff/FocusBear/AccountabilityBuddy/createUnlockRequestVc.swift#L105), [backend relationship](https://github.com/Focus-Bear/backend/blob/ef42149d9e3ba39d8d2397a89cd31d8f8efe5788/apps/api-server/src/modules/accountability-buddy/entities/accountability-buddy.entity.ts#L14), [existing email service](https://github.com/Focus-Bear/backend/blob/ef42149d9e3ba39d8d2397a89cd31d8f8efe5788/apps/api-server/src/modules/accountability-buddy/services/accountability-email.service.ts#L13), [settings refresh consumer](https://github.com/Focus-Bear/backend/blob/ef42149d9e3ba39d8d2397a89cd31d8f8efe5788/apps/api-server/src/modules/user/consumers/settings-notification.consumer.ts#L49). Mac evidence is pinned to `e10be56c`; backend buddy evidence is pinned to the inspected checkout `ef42149d9`.
- Backend local `origin/main` `ec7694913` and web local `origin/main` `f8be3ecc6` were inspected for newer classroom capabilities because their working checkouts are older. Commit-pinned references: backend [school/class hierarchy](https://github.com/Focus-Bear/backend/blob/ec7694913ea53b4dd6a513b9317be021b36444e0/apps/api-server/src/modules/team/entities/team.entity.ts#L76), [teacher start window](https://github.com/Focus-Bear/backend/blob/ec7694913ea53b4dd6a513b9317be021b36444e0/apps/api-server/src/modules/class-session/services/class-session/class-session.service.ts#L1794), and [personal schedule](https://github.com/Focus-Bear/backend/blob/ec7694913ea53b4dd6a513b9317be021b36444e0/apps/api-server/src/modules/focus-mode/entities/blocking-schedule.entity.ts#L25); dashboard [school overview](https://github.com/Focus-Bear/web_dashboard/blob/f8be3ecc6b3b6ee155f7d7775ddb5b64d768e887/src/dashboard/team/teamMembers/index.tsx#L17), [roster](https://github.com/Focus-Bear/web_dashboard/blob/f8be3ecc6b3b6ee155f7d7775ddb5b64d768e887/src/dashboard/class/members/ClassMembersSection.tsx#L69), and [relevance setting](https://github.com/Focus-Bear/web_dashboard/blob/f8be3ecc6b3b6ee155f7d7775ddb5b64d768e887/src/dashboard/class/session/AiBlockingToggle.tsx#L11). Reuse school/class/roster UI and identity, while adding a dedicated policy editor. Implementation must verify the deployed/common branch and preserve existing local work.
- [Official category definitions](https://docs.paloaltonetworks.com/advanced-url-filtering/administration/url-filtering-basics/url-categories) were checked to clarify operational category semantics; no provider purchase, integration availability or equivalence is assumed.

This deliverable changes documentation only. It does not implement policies, grant permissions, alter any external account or send notifications.
