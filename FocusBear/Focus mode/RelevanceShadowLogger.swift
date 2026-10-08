//
//  RelevanceShadowLogger.swift
//  FocusBear
//
//  Shadow-mode integration for the website-relevance model
//  (Focus-Bear-research/FocusBear-Distraction-Detection-Model#18): runs the model
//  alongside the existing AI URL check, purely for observation — it never affects
//  the real block/allow decision. Every check is logged to relevance-shadow.jsonl;
//  entries where the model's tier disagrees with the existing dProbability-derived
//  decision are what a future disagreement-rate analysis would read.
//
//  DEV-ONLY FOR NOW: the model's Python process (torch + sentence-transformers +
//  xgboost + sklearn) isn't bundled with the app yet — packaging it the way
//  FocusBear/server is (a signed, committed PyInstaller binary) is a separate,
//  sizeable follow-up given how much heavier this dependency set is. Point
//  FB_RELEVANCE_MODEL_PYTHON and FB_RELEVANCE_MODEL_SCRIPT at a local checkout's
//  venv + deployment/predict_server.py to exercise this; with either unset the
//  feature no-ops (logs once, does nothing further) rather than failing loudly for
//  everyone who doesn't have the model checked out.
//

import Foundation

/// One JSON request/response per line over stdin/stdout — see predict_server.py in
/// Focus-Bear-research/FocusBear-Distraction-Detection-Model (deployment/).
private struct RelevanceShadowRequest: Encodable {
    let focus_intention: String
    let tab_title: String
    let current_task: String
    let url: String
}

private struct RelevanceShadowResult: Decodable {
    let tier: Int?
    let label: String?
    let action: String?
    let confidence: Double?
    let cosine_similarity: Double?
    let confidence_gate_passed: Bool?
    let llm_fallback_required: Bool?
    let error: String?
    let latency_ms: Double?
}

/// Launches and owns the long-lived `predict_server.py` subprocess, and serializes
/// requests to it one at a time — the stdin/stdout protocol is strictly one response
/// per line, in request order, so a second request must never be written before the
/// first request's response has been read back.
final class RelevanceShadowService {

    static let shared = RelevanceShadowService()

    private let queue = DispatchQueue(
        label: "relevance.shadow.onnx",
        qos: .utility
    )

    private var model: RelevanceEnsembleModel?

    private init() {}
    fileprivate func predict(
        focusIntention: String,
        tabTitle: String,
        currentTask: String,
        url: String,
        completion: @escaping (RelevanceShadowResult?) -> Void
    ) {

        RelevanceModelDownloader.shared.ensureAvailable {
            [weak self] directory in

            guard let self = self else {
                completion(nil)
                return
            }

            guard let directory = directory else {
                print("V2 MODEL: files unavailable")
                completion(nil)
                return
            }

            self.queue.async {

                if self.model == nil {

                    self.model = RelevanceEnsembleModel(
                        modelDirectory: directory
                    )
                }

                guard let model = self.model else {
                    print("V2 MODEL: failed to load")
                    completion(nil)
                    return
                }

                let start = CFAbsoluteTimeGetCurrent()

                guard let prediction = model.predict(
                    focusIntention: focusIntention,
                    tabTitle: tabTitle,
                    currentTask: currentTask,
                    urlKeywords: "",
                    url: url
                ) else {
                    print("V2 MODEL: prediction failed")
                    completion(nil)
                    return
                }

                let latencyMs =
                (
                    CFAbsoluteTimeGetCurrent()
                    - start
                ) * 1000


                let tier = prediction.tier

                let label: String
                let action: String

                switch tier {

                case 0:
                    label =
                    "Definitely Not Relevant"

                    action =
                    "block"

                case 1:
                    label =
                    "Maybe Relevant"

                    action =
                    "caution"

                case 2:
                    label =
                    "Likely Relevant"

                    action =
                    "allow"

                default:
                    completion(nil)
                    return
                }


                let confidenceGatePassed =
                prediction.confidence >= 0.70


                print(
                    String(
                        format:
                            "### V2 ENSEMBLE: tier=%d confidence=%.4f cosine=%.4f latency=%.2fms ###",
                        tier,
                        prediction.confidence,
                        prediction.cosine,
                        latencyMs
                    )
                )


                let result =
                RelevanceShadowResult(
                    tier: tier,
                    label: label,
                    action: action,
                    confidence:
                        Double(
                            prediction.confidence
                        ),
                    cosine_similarity:
                        Double(
                            prediction.cosine
                        ),
                    confidence_gate_passed:
                        confidenceGatePassed,
                    llm_fallback_required:
                        !confidenceGatePassed,
                    error: nil,
                    latency_ms: latencyMs
                )

                completion(result)
            }
        }
    }
}
    // MARK: - Comparison + JSONL logging

    let kRelevanceShadowLogFileName = "relevance-shadow.jsonl"

    private let relevanceShadowJsonlURL: URL? =
    applicationSupportURL?.appendingPathComponent(kRelevanceShadowLogFileName)
    private var relevanceShadowLogger: CSVLogger?
    private let relevanceComparisonCsvURL: URL? =
    applicationSupportURL?.appendingPathComponent("relevance-comparison.csv")

    private var relevanceComparisonLogger: CSVLogger?

    private let relevanceComparisonQueue = DispatchQueue(
        label: "relevance.comparison.csv"
    )

    /// Runs the shadow model against the same signal the existing AI URL check just used,
    /// and appends one JSONL entry recording whether they agree. Purely observational —
    /// this never influences `existingProbability` or any blocking decision. Safe to call
    /// on the main thread: the actual model call and file write both happen off it.
    func logRelevanceShadowCheck(
        focusIntention: String,
        tabTitle: String,
        currentTask: String,
        url: String,
        existingProbability: Double,
        backendReason: String
    ) {
        print("### ONNX SHADOW CHECK CALLED ###")

        let backendDecision =
        existingProbability >= 0.70 ? "allow" : "block"

        RelevanceShadowService.shared.predict(
            focusIntention: focusIntention,
            tabTitle: tabTitle,
            currentTask: currentTask,
            url: url
        ) { result in

            var entry: [String: Any] = [
                "timestamp": getStringFromDate(
                    date: Date(),
                    dateFormat: "yyyy-MM-dd HH:mm:ss"
                ),
                "focus_intention": focusIntention,
                "current_task": currentTask,
                "tab_title": tabTitle,
                "url": url,

                "existing_probability": existingProbability,
                "existing_decision": backendDecision,
                "backend_reason": backendReason
            ]

            guard let result = result,
                  result.error == nil else {

                entry["agreement"] = "unavailable"

                appendRelevanceShadowEntry(entry)

                appendRelevanceComparisonCsv(
                    focusIntention: focusIntention,
                    tabTitle: tabTitle,
                    currentTask: currentTask,
                    url: url,
                    backendProbability: existingProbability,
                    backendReason: backendReason,
                    backendDecision: backendDecision,
                    result: nil
                )

                return
            }

            entry["model_tier"] = result.tier
            entry["model_label"] = result.label
            entry["model_action"] = result.action
            entry["model_confidence"] = result.confidence
            entry["model_cosine"] = result.cosine_similarity
            entry["model_confidence_gate_passed"] =
            result.confidence_gate_passed

            let onnxDecision = result.action

            let agreement: String

            if onnxDecision == "caution" {
                agreement = "caution"
            } else {
                agreement =
                onnxDecision == backendDecision
                ? "agree"
                : "disagree"
            }

            entry["agreement"] = agreement

            appendRelevanceShadowEntry(entry)

            appendRelevanceComparisonCsv(
                focusIntention: focusIntention,
                tabTitle: tabTitle,
                currentTask: currentTask,
                url: url,
                backendProbability: existingProbability,
                backendReason: backendReason,
                backendDecision: backendDecision,
                result: result
            )
        }
    }
    private func appendRelevanceShadowEntry(_ entry: [String: Any]) {
        guard let url = relevanceShadowJsonlURL,
              let data = try? JSONSerialization.data(withJSONObject: entry, options: [.sortedKeys]),
              let line = String(data: data, encoding: .utf8) else { return }
        if relevanceShadowLogger == nil {
            relevanceShadowLogger = CSVLogger(fileURL: url)
        }
        relevanceShadowLogger?.append(line: line + "\n")
    }
    private func appendRelevanceComparisonCsv(
        focusIntention: String,
        tabTitle: String,
        currentTask: String,
        url: String,
        backendProbability: Double,
        backendReason: String,
        backendDecision: String,
        result: RelevanceShadowResult?
    ) {

        relevanceComparisonQueue.async {

            guard let fileURL = relevanceComparisonCsvURL else {
                return
            }

            let fileManager = FileManager.default

            var needsHeader = true

            if fileManager.fileExists(atPath: fileURL.path),
               let attributes = try? fileManager.attributesOfItem(
                atPath: fileURL.path
               ),
               let fileSize = attributes[.size] as? NSNumber {

                needsHeader = fileSize.intValue == 0
            }

            if relevanceComparisonLogger == nil {
                relevanceComparisonLogger =
                CSVLogger(fileURL: fileURL)
            }

            if needsHeader {

                let header = [
                    "Timestamp",
                    "URL",
                    "TabTitle",
                    "FocusIntention",
                    "CurrentTask",
                    "BackendProbability",
                    "BackendReason",
                    "BackendDecision",
                    "ONNXCosine",
                    "ONNXConfidence",
                    "ONNXLabel",
                    "ONNXDecision",
                    "ONNXLatencyMs",
                    "Agreement"
                ].joined(separator: ",")

                relevanceComparisonLogger?
                    .append(line: header + "\n")
            }

            let onnxCosine: String
            let onnxConfidence: String
            let onnxLabel: String
            let onnxDecision: String
            let agreement: String
            let onnxLatencyMs: String

            if let result = result,
               let cosine = result.cosine_similarity,
               let confidence = result.confidence,
               let label = result.label,
               let action = result.action {

                onnxCosine = String(
                    format: "%.6f",
                    cosine
                )

                onnxConfidence = String(
                    format: "%.6f",
                    confidence
                )

                onnxLabel = label
                onnxDecision = action
                onnxLatencyMs = result.latency_ms.map {
                    String(format: "%.2f", $0)
                } ?? ""

                if onnxDecision == "caution" {
                    agreement = "caution"
                } else {
                    agreement =
                    backendDecision == onnxDecision
                    ? "agree"
                    : "disagree"
                }

            } else {

                onnxCosine = ""
                onnxConfidence = ""
                onnxLabel = ""
                onnxDecision = ""
                onnxLatencyMs = ""
                agreement = "unavailable"
            }

            let values = [
                getStringFromDate(
                    date: Date(),
                    dateFormat: "yyyy-MM-dd HH:mm:ss"
                ),
                url,
                tabTitle,
                focusIntention,
                currentTask,
                String(format: "%.6f", backendProbability),
                backendReason,
                backendDecision,
                onnxCosine,
                onnxConfidence,
                onnxLabel,
                onnxDecision,
                onnxLatencyMs,
                agreement
            ]

            let csvLine = values
                .map { csvEscape($0) }
                .joined(separator: ",")

            relevanceComparisonLogger?
                .append(line: csvLine + "\n")
        }
    }

    private func csvEscape(_ value: String) -> String {

        let escaped =
        value.replacingOccurrences(
            of: "\"",
            with: "\"\""
        )

        return "\"\(escaped)\""
    }
