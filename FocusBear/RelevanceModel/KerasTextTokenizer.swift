//
//  KerasTextTokenizer.swift
//  Focus Bear
//
//  Reproduces Keras `Tokenizer.texts_to_sequences` + `pad_sequences(padding='post')` for the
//  TextCNN text branch, driven by the exported `word_index` map. Matches the Python reference
//  exactly (see RelevanceModel/README): lowercase, replace the Keras default filter chars with
//  spaces, split on space, map to ids (OOV or id >= maxVocab -> OOV), post-pad/truncate to 100.
//

import Foundation

struct KerasTextTokenizer {
    private let wordIndex: [String: Int]
    private let oovIndex: Int
    private let maxVocab = 20000
    private let maxLen = 100

    /// Keras default `filters` (each replaced by a space) plus tab/newline. Note: no apostrophe.
    private static let filters: Set<Character> = Set("!\"#$%&()*+,-./:;<=>?@[\\]^_`{|}~\t\n")

    init?(wordIndexURL: URL) {
        guard let data = try? Data(contentsOf: wordIndexURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            return nil
        }
        wordIndex = obj
        oovIndex = obj["<OOV>"] ?? 1
    }

    /// Exactly `maxLen` int32 ids, post-padded with 0.
    func tokenize(_ text: String) -> [Int32] {
        var ids: [Int32] = []
        for word in split(text) {
            if let i = wordIndex[word], i < maxVocab {
                ids.append(Int32(i))
            } else {
                ids.append(Int32(oovIndex))
            }
            if ids.count == maxLen { break }
        }
        if ids.count < maxLen {
            ids.append(contentsOf: repeatElement(0, count: maxLen - ids.count))
        }
        return ids
    }

    private func split(_ text: String) -> [String] {
        let cleaned = String(text.lowercased().map { Self.filters.contains($0) ? " " : $0 })
        return cleaned.split(separator: " ").map(String.init)
    }
}
