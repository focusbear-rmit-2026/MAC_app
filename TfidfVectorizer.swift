//
//  TfidfVectorizer.swift
//  FocusBear
//
//  Created by Mac on 6/10/2026.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

//
//  TfidfVectorizer.swift
//  Focus Bear
//
//  Native equivalent of the fitted sklearn TfidfVectorizer used
//  by the Focus Bear ensemble model.
//

import Foundation

final class TfidfVectorizer {

    private struct Config: Decodable {
        let feature_count: Int
        let features: [String]
        let idf: [Double]

        let lowercase: Bool
        let token_pattern: String
        let ngram_range: [Int]

        let norm: String?
        let use_idf: Bool
        let smooth_idf: Bool
        let sublinear_tf: Bool
        let binary: Bool
    }

    private let features: [String]
    private let vocabulary: [String: Int]
    private let idf: [Float]

    private let lowercase: Bool
    private let sublinearTF: Bool

    let featureCount: Int


    // MARK: - Init

    init?(configURL: URL) {

        guard let data = try? Data(
            contentsOf: configURL
        ) else {
            return nil
        }

        guard let config = try? JSONDecoder().decode(
            Config.self,
            from: data
        ) else {
            return nil
        }

        guard
            config.features.count == config.feature_count,
            config.idf.count == config.feature_count
        else {
            return nil
        }

        self.features = config.features

        self.idf = config.idf.map {
            Float($0)
        }

        self.lowercase = config.lowercase
        self.sublinearTF = config.sublinear_tf

        self.featureCount = config.feature_count


        var map: [String: Int] = [:]

        map.reserveCapacity(
            config.features.count
        )

        for (
            index,
            feature
        ) in config.features.enumerated() {

            map[feature] = index
        }

        self.vocabulary = map
    }


    // MARK: - Transform

    func transform(_ input: String) -> [Float] {

        var text = input

        if lowercase {
            text = text.lowercased()
        }

        let tokens = tokenize(text)

        if tokens.isEmpty {
            return [Float](
                repeating: 0,
                count: featureCount
            )
        }


        // sklearn ngram_range = (1, 2)
        var terms = tokens


        if tokens.count >= 2 {

            for index in 0..<(tokens.count - 1) {

                let bigram =
                    tokens[index]
                    + " "
                    + tokens[index + 1]

                terms.append(bigram)
            }
        }


        // Count term frequencies

        var counts: [String: Int] = [:]

        for term in terms {
            counts[term, default: 0] += 1
        }


        var vector = [Float](
            repeating: 0,
            count: featureCount
        )


        // TF * IDF

        for (
            term,
            count
        ) in counts {

            guard let index = vocabulary[term] else {
                continue
            }


            let tf: Float

            if sublinearTF {

                tf =
                    1.0
                    + log(Float(count))

            } else {

                tf = Float(count)
            }


            vector[index] =
                tf
                * idf[index]
        }


        // sklearn norm="l2"

        var normSquared: Float = 0

        for value in vector {
            normSquared += value * value
        }


        let norm = sqrt(normSquared)

        if norm > 0 {

            for index in vector.indices {
                vector[index] /= norm
            }
        }


        return vector
    }


    // MARK: - Tokenization

    private func tokenize(
        _ text: String
    ) -> [String] {

        // sklearn:
        //
        // (?u)\b\w\w+\b
        //
        // Meaning:
        // word tokens containing at least 2 characters.

        guard let regex = try? NSRegularExpression(
            pattern: #"\b\w\w+\b"#,
            options: []
        ) else {
            return []
        }


        let range = NSRange(
            text.startIndex..<text.endIndex,
            in: text
        )


        let matches = regex.matches(
            in: text,
            options: [],
            range: range
        )


        return matches.compactMap { match in

            guard let swiftRange = Range(
                match.range,
                in: text
            ) else {
                return nil
            }

            return String(
                text[swiftRange]
            )
        }
    }
}
