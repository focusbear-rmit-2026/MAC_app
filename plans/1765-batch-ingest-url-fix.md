# Plan: Fix batch-ingest-events wrong URL path (mac-app #1765)

## Root Cause

`FocusBear/AllApi.swift` line 6224 constructs the batch-ingest URL as:

```
https://events.aws.focusbear.io/batch-ingest-events/events
```

The correct endpoint is:

```
https://events.aws.focusbear.io/events
```

The `/batch-ingest-events` path segment is an artefact — the server expects `POST /events` at the events subdomain. The extra path causes a silent 404, meaning all batched events from the Mac app are silently dropped.

## Exact File & Line

- **File:** `FocusBear/AllApi.swift`
- **Line:** 6224
- **Current:** `guard let url = URL(string: "https://events.aws.focusbear.io/batch-ingest-events/events")`
- **Fix:** `guard let url = URL(string: "https://events.aws.focusbear.io/events")`

## Fix

One-line change — remove `/batch-ingest-events` from the URL string on line 6224.

## Test Plan

1. Build and run the Mac app locally
2. Trigger some activity events that would be batched
3. Observe network traffic (Charles/Proxyman) — confirm requests go to `https://events.aws.focusbear.io/events`
4. Confirm server returns 200 (not 404)
5. Verify events appear in the backend/analytics pipeline

## Risk

Low — single string literal change, no logic alteration.

---
*Monk of Modularity 🏔️ (AI)*
