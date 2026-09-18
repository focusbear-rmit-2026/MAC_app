# Mac Relevance Classifier Integration

## Purpose

This document explains the changes made to the Focus Bear Mac application to integrate the local ONNX relevance classifier in shadow mode, compare it with the existing backend AI relevance decision, and collect disagreement data for model improvement.

The long-term project goal is to reduce and eventually remove the normal dependency on the existing LLM/backend relevance check by validating a local classifier that can make relevance decisions on-device.

---

## 1. Initial State

When we started, the Mac application already had the existing backend AI relevance flow working.

The live flow was:

```text
Browser Activity
      ↓
Focus Bear Mac URL Processing
      ↓
Backend AI Relevance Check
      ↓
Probability + Reason
      ↓
Existing Allow / Block Logic
```

The native ONNX model code existed in a separate Git branch, but it was not wired into the live Mac relevance flow.

A separate shadow-mode branch also existed, but its shadow implementation was designed around an external Python prediction process.

So the main integration task was:

```text
Existing Mac relevance flow
        +
Native ONNX model
        +
Shadow comparison logic
        ↓
Working Mac shadow-mode comparison
```

---

## 2. Existing Code We Reused

The native ONNX implementation was brought from the existing ONNX branch:

```text
origin/feat/relevance-onnx-native
```

The shadow logger was brought from the separate shadow-mode branch:

```text
origin/feat/relevance-shadow-mode
```

The main ONNX files used are under:

```text
FocusBear/RelevanceModel/
```

and include:

```text
RelevanceOnnxModel.swift
RelevanceModelDownloader.swift
ORTBridge.h
ORTBridge.mm
BertWordPieceTokenizer.swift
KerasTextTokenizer.swift
```

The shadow logger used for the integration is:

```text
FocusBear/Focus mode/RelevanceShadowLogger.swift
```

---

# Files Changed

## 3. `RelevanceShadowLogger.swift`

### Why this file was changed

The shadow-mode file existed in another branch, but it was not connected to the native ONNX model in our working branch.

The previous shadow implementation was intended to work with an external Python classifier process.

We brought the file into the ONNX working branch and rewired it to call the native ONNX model directly.

### Before

The shadow implementation depended on the external prediction service / Python flow.

Conceptually:

```text
Mac App
   ↓
Shadow Logger
   ↓
Python Prediction Process
   ↓
Classifier Result
```

### After

The shadow logger now calls the native ONNX model directly:

```swift
let prediction = model.predict(
    focusIntention: focusIntention,
    tabTitle: tabTitle
)
```

The new flow is:

```text
Mac App
   ↓
Shadow Logger
   ↓
Native RelevanceOnnxModel
   ↓
Classifier Result
```

---

## 4. ONNX Prediction Handling

The native model returns:

```swift
struct Prediction {
    let isRelevant: Bool
    let confidence: Float
    let cosine: Float
}
```

Inside `RelevanceOnnxModel.swift`, the TextCNN returns two probabilities:

```swift
let pNotRelevant = probs[0].floatValue
let pRelevant = probs[1].floatValue
```

The predicted class is selected using:

```swift
isRelevant: pRelevant >= pNotRelevant
```

and confidence is:

```swift
confidence: max(pNotRelevant, pRelevant)
```

So:

```text
Model output probabilities
        ↓
Relevant / Not Relevant prediction
        +
Confidence
```

Cosine similarity is used as a model feature and is also logged for analysis.

---

## 5. Relevant / Not Relevant Label

### Before

The native classifier exposed the Boolean result:

```swift
prediction.isRelevant
```

### Updated code

We converted the Boolean into a readable label for logging:

```swift
let label = prediction.isRelevant
    ? "relevant"
    : "not_relevant"
```

This label is written into the shadow/comparison output.

---

## 6. Allow / Caution / Block Mapping

### Before

The shadow integration initially mapped the classifier result directly:

```swift
let action = prediction.isRelevant
    ? "allow"
    : "block"
```

This meant that even a low-confidence prediction became a hard Allow or Block decision.

### After

We added a confidence-based caution state:

```swift
let tier: Int
let action: String

if prediction.confidence < 0.70 {
    tier = 1
    action = "caution"
} else if prediction.isRelevant {
    tier = 2
    action = "allow"
} else {
    tier = 0
    action = "block"
}
```

The current Mac integration mapping is:

```text
Tier 0 → Block
Tier 1 → Caution
Tier 2 → Allow
```

The `0.70` threshold is applied to classifier confidence.

It is not a cosine-similarity threshold.

---

## 7. `focusModeData.swift`

### Why this file was changed

The existing Mac relevance flow already received the backend AI result, but it did not run the native ONNX classifier for comparison.

### Before

The flow ended with the existing backend relevance result:

```text
Backend AI
   ↓
Probability + Reason
   ↓
Existing Focus Bear blocking logic
```

### After

We added a call to the shadow logger after the backend result is received:

```swift
logRelevanceShadowCheck(
    focusIntention: whatToAchieveInFocusBlock,
    tabTitle: tab_title,
    currentTask: currentTaskName,
    url: url,
    existingProbability: dProbability,
    backendReason: reason
)
```

This means the same browsing event can now be evaluated by both systems:

```text
                    ┌── Existing Backend AI
Browser Activity ───┤
                    └── Native ONNX Classifier
                              ↓
                       Comparison Logger
```

The existing backend result still controls the real block/allow behaviour.

The ONNX result is shadow-only at this stage.

---

## 8. Backend Decision Mapping

The existing backend probability is converted into a decision using:

```swift
let backendDecision =
    existingProbability >= 0.70 ? "allow" : "block"
```

This backend result is compared with the ONNX action.

---

## 9. Agreement / Disagreement / Caution

### Before

Agreement was a direct string comparison:

```swift
let agreement =
    onnxDecision == backendDecision
    ? "agree"
    : "disagree"
```

This would treat every low-confidence ONNX result as a normal disagreement.

### After

We updated the comparison so caution is handled separately:

```swift
if onnxDecision == "caution" {
    agreement = "caution"
} else {
    agreement =
        backendDecision == onnxDecision
        ? "agree"
        : "disagree"
}
```

The comparison now behaves as:

```text
Backend Allow + ONNX Allow   → Agree
Backend Block + ONNX Block   → Agree
Backend Allow + ONNX Block   → Disagree
Backend Block + ONNX Allow   → Disagree
ONNX low confidence          → Caution
```

---

## 10. New Comparison CSV made for data check(Can/will be removed)

We added a new runtime comparison file:

```text
relevance-comparison.csv
```

It is created under:

```text
~/Library/Application Support/com.App.EarnYourScreentime/
```

The CSV records:

```text
Timestamp
URL
TabTitle
FocusIntention
CurrentTask
BackendProbability
BackendReason
BackendDecision
ONNXCosine
ONNXConfidence
ONNXLabel
ONNXDecision
Agreement
```

This file was added so backend AI and ONNX results can be reviewed together on the same browsing event.

---

## 11. Existing Logs

The new comparison CSV does not replace the existing Focus Bear AI log.

The files have different purposes:

```text
focusAIDecisions.csv
→ Existing Focus Bear backend AI decision log

relevance-shadow.jsonl
→ Detailed shadow-mode comparison/debug log

relevance-comparison.csv
→ Backend vs ONNX comparison dataset added for this integration
```

---

---

## 14. Files Added / Modified Summary

### Added / brought into the working branch

```text
FocusBear/Focus mode/RelevanceShadowLogger.swift
```

Main updates made in this file:

```text
Replaced Python shadow prediction path with native ONNX prediction
Added readable relevant / not_relevant label
Added confidence handling
Added Allow / Caution / Block mapping
Added Tier 0 / 1 / 2 mapping
Added backend vs ONNX comparison
Added caution-aware agreement logic
Added relevance-comparison.csv logging
Retained relevance-shadow.jsonl logging
```

### Modified

```text
FocusBear/Focus mode/focusModeData.swift
```

Main update:

```text
Added logRelevanceShadowCheck(...)
after the existing backend AI relevance result
```

### Existing native model files used

```text
FocusBear/RelevanceModel/RelevanceOnnxModel.swift
FocusBear/RelevanceModel/RelevanceModelDownloader.swift
FocusBear/RelevanceModel/ORTBridge.h
FocusBear/RelevanceModel/ORTBridge.mm
FocusBear/RelevanceModel/BertWordPieceTokenizer.swift
FocusBear/RelevanceModel/KerasTextTokenizer.swift
```

---
