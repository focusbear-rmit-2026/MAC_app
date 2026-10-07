//
//  RelevanceEnsembleModel.swift
//  FocusBear
//
//  Created by Mac on 6/10/2026.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

final class RelevanceEnsembleModel {

    private let minilm: ORTBridge

    private let lr: ORTBridge
    private let xgb: ORTBridge
    private let xgbTuned: ORTBridge

    private let wordpiece: BertWordPieceTokenizer

    private let goalTfidf: TfidfVectorizer
    private let contextTfidf: TfidfVectorizer

    private let embedDim = 384
    private let feedKeywords = [
        "feed",
        "home",
        "timeline",
        "messages",
        "inbox",
        "notifications",
        "trending",
        "dashboard",
        "news feed",
        "social"
    ]

    struct Prediction {
        let tier: Int
        let confidence: Float
        let probabilities: [Float]
        let cosine: Float
    }
    init?(modelDirectory: URL) {

        let minilmURL =
            modelDirectory.appendingPathComponent(
                "minilm_fp32.onnx"
            )

        let vocabURL =
            modelDirectory.appendingPathComponent(
                "minilm_vocab.txt"
            )

        let lrURL =
            modelDirectory.appendingPathComponent(
                "lr.onnx"
            )

        let xgbURL =
            modelDirectory.appendingPathComponent(
                "xgb.onnx"
            )

        let xgbTunedURL =
            modelDirectory.appendingPathComponent(
                "xgb_tuned.onnx"
            )

        let goalTfidfURL =
            modelDirectory.appendingPathComponent(
                "tfidf_goal.json"
            )

        let contextTfidfURL =
            modelDirectory.appendingPathComponent(
                "tfidf_context.json"
            )

        guard
            let minilmModel =
                ORTBridge(modelPath: minilmURL.path),

            let lrModel =
                ORTBridge(modelPath: lrURL.path),

            let xgbModel =
                ORTBridge(modelPath: xgbURL.path),

            let xgbTunedModel =
                ORTBridge(modelPath: xgbTunedURL.path),

            let tokenizer =
                BertWordPieceTokenizer(
                    vocabURL: vocabURL
                ),

            let goalVectorizer =
                TfidfVectorizer(
                    configURL: goalTfidfURL
                ),

            let contextVectorizer =
                TfidfVectorizer(
                    configURL: contextTfidfURL
                )

        else {
            return nil
        }

        minilm = minilmModel

        lr = lrModel
        xgb = xgbModel
        xgbTuned = xgbTunedModel

        wordpiece = tokenizer

        goalTfidf = goalVectorizer
        contextTfidf = contextVectorizer
    }
    func predictFromFeatures(
        _ features: [Float],
        cosine: Float
    ) -> Prediction? {

        guard features.count == 6313 else {
            print(
                "RelevanceEnsembleModel: expected 6313 features, got \(features.count)"
            )
            return nil
        }

        // Logistic Regression expects normal dense zeros.
        let lrNumbers = features.map {
            NSNumber(value: $0)
        }

        // Python sends a scipy sparse matrix into XGBoost.
        // Missing sparse entries must therefore become NaN,
        // not ordinary 0.0, to reproduce the same tree paths.
        let xgbNumbers = features.map { value in
            if value == 0 {
                return NSNumber(value: Float.nan)
            } else {
                return NSNumber(value: value)
            }
        }

        guard
            let lrProbabilities =
                lr.runClassifier(withFeatures: lrNumbers),


            let xgbProbabilities =
                xgb.runClassifier(withFeatures: xgbNumbers),


            let tunedProbabilities =
                xgbTuned.runClassifier(withFeatures: xgbNumbers),

            lrProbabilities.count == 3,
            xgbProbabilities.count == 3,
            tunedProbabilities.count == 3



        else {
            print(
                "RelevanceEnsembleModel: classifier inference failed"
            )
            return nil
        }
        print(
            "V2 DEBUG LR PROBS:",
            lrProbabilities.map { $0.floatValue }
        )

        print(
            "V2 DEBUG XGB PROBS:",
            xgbProbabilities.map { $0.floatValue }
        )

        print(
            "V2 DEBUG XGB TUNED PROBS:",
            tunedProbabilities.map { $0.floatValue }
        )

        var finalProbabilities =
            [Float](repeating: 0, count: 3)

        for i in 0..<3 {

            let lrP =
                lrProbabilities[i].floatValue

            let xgbP =
                xgbProbabilities[i].floatValue

            let tunedP =
                tunedProbabilities[i].floatValue

            // Original sklearn VotingClassifier weights:
            // LR : XGB : XGB Tuned = 1 : 2 : 2
            finalProbabilities[i] =
                (
                    lrP +
                    (2.0 * xgbP) +
                    (2.0 * tunedP)
                ) / 5.0
        }

        guard let best =
            finalProbabilities.enumerated().max(
                by: { $0.element < $1.element }
            )
        else {
            return nil
        }

        return Prediction(
            tier: best.offset,
            confidence: best.element,
            probabilities: finalProbabilities,
            cosine: cosine
        )
    }

    private func buildFeatures(
        focusIntention: String,
        tabTitle: String,
        currentTask: String = "",
        urlKeywords: String = "",
        url: String = ""
    ) -> ([Float], Float)? {

        // Same as Python:
        // user_goal = (focus_intention + " " + current_task).strip()
        let userGoal = (
            focusIntention + " " + currentTask
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Same as Python:
        // website_context = (tab_title + " " + url_keywords).strip()
        let websiteContext = (
            tabTitle + " " + urlKeywords
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let goalEmbedding = embed(userGoal),
            let contextEmbedding = embed(websiteContext)
        else {
            return nil
        }

        let goalVector = goalTfidf.transform(userGoal)
        let contextVector = contextTfidf.transform(websiteContext)

        let cosine = dot(
            goalEmbedding,
            contextEmbedding
        )
        print("V2 DEBUG COSINE:", cosine)

        print(
            "V2 DEBUG GOAL TFIDF SUM:",
            goalVector.reduce(0, +)
        )

        print(
            "V2 DEBUG CONTEXT TFIDF SUM:",
            contextVector.reduce(0, +)
        )

        print(
            "V2 DEBUG GOAL TFIDF NONZERO:",
            goalVector.filter { $0 != 0 }.count
        )

        print(
            "V2 DEBUG CONTEXT TFIDF NONZERO:",
            contextVector.filter { $0 != 0 }.count
        )

        print(
            "V2 DEBUG GOAL EMB FIRST5:",
            Array(goalEmbedding.prefix(5))
        )

        print(
            "V2 DEBUG CONTEXT EMB FIRST5:",
            Array(contextEmbedding.prefix(5))
        )

        let metadata = urlMetadata(
            url: url,
            tabTitle: tabTitle
        )

        let goalWords = Set(
            userGoal
                .lowercased()
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
        )

        let contextWords = Set(
            websiteContext
                .lowercased()
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
        )

        let intersection =
            goalWords.intersection(contextWords)

        let overlap =
            Float(intersection.count) /
            Float(max(goalWords.count, 1))

        let goalLength =
            Float(
                userGoal
                    .split(whereSeparator: { $0.isWhitespace })
                    .count
            )

        let contextLength =
            Float(
                websiteContext
                    .split(whereSeparator: { $0.isWhitespace })
                    .count
            )

        let isFeed = metadata[4]

        var features: [Float] = []

        features.reserveCapacity(6313)

        // 533
        features.append(contentsOf: goalVector)

        // 5000
        features.append(contentsOf: contextVector)

        // cosine
        features.append(cosine)

        // 6 URL/title features
        features.append(contentsOf: metadata)

        // overlap
        features.append(overlap)

        // goal_len
        features.append(goalLength)

        // context_len
        features.append(contextLength)

        // cosine * overlap
        features.append(cosine * overlap)

        // cosine * is_feed
        features.append(cosine * isFeed)

        // 384 goal embedding
        features.append(contentsOf: goalEmbedding)

        // 384 context embedding
        features.append(contentsOf: contextEmbedding)

        guard features.count == 6313 else {
            print(
                "RelevanceEnsembleModel: built \(features.count) features, expected 6313"
            )
            return nil
        }

        return (features, cosine)
    }
    func predict(
        focusIntention: String,
        tabTitle: String,
        currentTask: String = "",
        urlKeywords: String = "",
        url: String = ""
    ) -> Prediction? {

        let cleanFocus = focusIntention
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanTitle = tabTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Same validation as the Python predictor:
        // at least focus intention or tab title must exist.
        guard !cleanFocus.isEmpty || !cleanTitle.isEmpty else {
            return nil
        }

        guard let result = buildFeatures(
            focusIntention: focusIntention,
            tabTitle: tabTitle,
            currentTask: currentTask,
            urlKeywords: urlKeywords,
            url: url
        ) else {
            return nil
        }

        let (features, cosine) = result

        return predictFromFeatures(
            features,
            cosine: cosine
        )

    }
    private func urlMetadata(
        url: String,
        tabTitle: String
    ) -> [Float] {

        let trimmed =
            url.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        var pathDepth: Float = 0
        var urlLength: Float = 0
        var hasSubdomain: Float = 0
        var hasQuery: Float = 0

        // Python returns four zeros when URL is empty.
        if !trimmed.isEmpty {

            var normalized = url

            if !normalized.hasPrefix("http") {
                normalized = "https://" + normalized
            }

            if let components =
                URLComponents(string: normalized) {

                let pathParts =
                    components.path
                        .split(separator: "/")

                pathDepth =
                    Float(pathParts.count)

                urlLength =
                    Float(normalized.count)

                if let host = components.host {

                    let parts =
                        host.split(
                            separator: ".",
                            omittingEmptySubsequences: false
                        )

                    if parts.count > 2 {

                        let first =
                            String(parts[0])

                        if first != "www" &&
                            !first.isEmpty {

                            hasSubdomain = 1
                        }
                    }
                }

                if let query =
                    components.percentEncodedQuery,
                   !query.isEmpty {

                    hasQuery = 1
                }
            }
        }

        let lowerTitle =
            tabTitle.lowercased()

        let isFeed: Float =
            feedKeywords.contains {
                lowerTitle.contains($0)
            } ? 1 : 0

        let tabTitleMissing: Float =
            tabTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty ? 1 : 0

        return [
            pathDepth,
            urlLength,
            hasSubdomain,
            hasQuery,
            isFeed,
            tabTitleMissing
        ]
    }
    private func embed(_ sentence: String) -> [Float]? {

        let encoded = wordpiece.encode(sentence)

        let seqLen = encoded.inputIds.count

        let ids = encoded.inputIds.map {
            NSNumber(value: $0)
        }

        let mask = encoded.attentionMask.map {
            NSNumber(value: $0)
        }

        guard let hidden = minilm.runMiniLM(
            withInputIds: ids,
            attentionMask: mask,
            seqLen: seqLen
        ),
        hidden.count == seqLen * embedDim
        else {
            return nil
        }

        var mean = [Float](
            repeating: 0,
            count: embedDim
        )

        var maskSum: Float = 0

        for token in 0..<seqLen {

            let maskValue =
                Float(encoded.attentionMask[token])

            maskSum += maskValue

            let base = token * embedDim

            for j in 0..<embedDim {
                mean[j] +=
                    hidden[base + j].floatValue *
                    maskValue
            }
        }

        let denominator = max(maskSum, 1e-9)

        var norm: Float = 0

        for j in 0..<embedDim {
            mean[j] /= denominator
            norm += mean[j] * mean[j]
        }

        norm = norm.squareRoot()

        if norm > 0 {
            for j in 0..<embedDim {
                mean[j] /= norm
            }
        }

        return mean
    }

    private func dot(
        _ a: [Float],
        _ b: [Float]
    ) -> Float {

        guard a.count == b.count else {
            return 0
        }

        var result: Float = 0

        for i in 0..<a.count {
            result += a[i] * b[i]
        }

        return result
    }

}
