# Focus Start design review — 10 September 2026

Compared the official Figma design contexts and inline screenshots for light frames `4:82474`, `4:82607`, `4:83077`, `4:83360`, `4:83590` and dark frames `4:89494`, `4:89628`, `4:90241`, `4:89864` in file `x0k5mDOy3fkoJ4EUFijDrE`. These references were retrieved with the official Figma plugin using Swift/SwiftUI context. Full source responses and reference images are preserved in `/private/tmp/figma-design-context-20260910` in the review workspace.

The code now uses scoped Figma color assets, including orange `#DE7400`, dark cards `#18181B`, black dark screen background, dark fields `#101014`, and cream dark speech bubbles. The bear follows the measured top of the expanded card, as shown by the changing position in duration, goal and blocking frames. Selected goals and tasks use compact rows with explicit edit/remove/add actions. Task score and duration badges use actual metadata. Project badges describe explicit importance; unknown importance stays absent and no old server allocator risk is fetched.

The user’s screenshot corrections take precedence over older Figma controls: Enable micro-breaks stays on the left with frequency on the right, light inputs are white, project defaults follow Day Plan order, task suggestions prioritize that project, and every block-list row has its own edit pencil. Block-list results have an explicit viewport for up to five actual rows, including an empty-result message; selected tasks retain their real queue IDs and order when searches open or close.

The following are calculated layout bounds using the actual constants and branch conditions, not live-render measurements. Form text keeps the existing minimum scale of 0.62. The illustration may scale to 0.55, keeping its speech text at least 11pt. At normal small widths the form fits without horizontal scrolling; below 448pt a horizontal scrollbar keeps the minimum-size controls reachable.

| Content width (pt) | Card width (pt) | Bear width (pt; 0 means hidden) | Horizontal overflow (pt) |
|---|---|---|---|
| 400 | 423.8 | 0.0 | 47.8 |
| 600 | 423.8 | 0.0 | 0.0 |
| 650 | 423.8 | 194.8 | 0.0 |
| 720 | 423.8 | 218.9 | 0.0 |
| 800 | 423.8 | 218.9 | 0.0 |
| 900 | 423.8 | 218.9 | 0.0 |
| 1100 | 435.1 | 224.7 | 0.0 |
| 1400 | 553.8 | 286.0 | 0.0 |
| 1728 | 683.5 | 353.0 | 0.0 |

Visual fixtures now instantiate the real advanced SwiftUI screen with deterministic project, task and block-list data. They capture duration controls, project search, selected project/tasks and block-list search at 650×1000pt and 1728×1400pt, in light and dark appearances (16 PNGs). The fixture injects read-only Day Plan ordering and strings, never calls work-choice loaders or controller actions, and does not write tasks or settings. It also asserts that hosting preserves the requested window dimensions. PNGs are XCTest attachments exported to the `focus-start-visual-evidence` artifact.

The user requested local validation to avoid hosted macOS costs. The unfinished hosted capture run `34436021992` was cancelled; it produced no screenshots. The workflow now targets the existing `self-hosted, macOS, ARM64, focusbear-mac-local` runner and uses its configured Xcode without changing the system selection. Visual tests require the explicit `FOCUS_START_VISUAL_QA=1` opt-in. Rendered evidence is pending the serialized local validation run; the reference images above remain Figma screenshots, not implementation captures.
