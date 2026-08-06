//
//  BertWordPieceTokenizer.swift
//  Focus Bear
//
//  BERT-uncased WordPiece tokenizer for the MiniLM encoder, driven by `vocab.txt`. Reproduces
//  HuggingFace `BertTokenizer(do_lower_case=true)`: BasicTokenizer (clean text, pad CJK, split on
//  whitespace + punctuation, lowercase + strip accents) then greedy WordPiece with `##`
//  continuations. Emits `[CLS] … [SEP]` ids + attention mask, capped at `maxLen`.
//

import Foundation

struct BertWordPieceTokenizer {
    private let vocab: [String: Int]
    private let unkId: Int
    private let clsId: Int
    private let sepId: Int
    private let maxLen: Int
    private let maxCharsPerWord = 100

    struct Encoding {
        let inputIds: [Int]
        let attentionMask: [Int]
    }

    init?(vocabURL: URL, maxLen: Int = 256) {
        guard let text = try? String(contentsOf: vocabURL, encoding: .utf8) else { return nil }
        var v: [String: Int] = [:]
        // vocab.txt: one token per line, line number == id.
        for (i, line) in text.components(separatedBy: "\n").enumerated() {
            let tok = line.hasSuffix("\r") ? String(line.dropLast()) : line
            if v[tok] == nil { v[tok] = i }
        }
        guard let unk = v["[UNK]"], let cls = v["[CLS]"], let sep = v["[SEP]"] else { return nil }
        vocab = v; unkId = unk; clsId = cls; sepId = sep; self.maxLen = maxLen
    }

    func encode(_ text: String) -> Encoding {
        var pieces: [String] = []
        for token in basicTokenize(text) {
            pieces.append(contentsOf: wordpiece(token))
        }
        // [CLS] + pieces + [SEP], truncating pieces to keep the two special tokens.
        let capped = pieces.count > maxLen - 2 ? Array(pieces.prefix(maxLen - 2)) : pieces
        var ids: [Int] = [clsId]
        for p in capped { ids.append(vocab[p] ?? unkId) }
        ids.append(sepId)
        return Encoding(inputIds: ids, attentionMask: Array(repeating: 1, count: ids.count))
    }

    // MARK: - BasicTokenizer

    private func basicTokenize(_ text: String) -> [String] {
        let cleaned = cleanAndPadCJK(text)
        var output: [String] = []
        for token in cleaned.split(whereSeparator: { $0 == " " }) {
            let lowered = stripAccents(String(token).lowercased())
            output.append(contentsOf: splitOnPunctuation(lowered))
        }
        return output
    }

    private func cleanAndPadCJK(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for s in text.unicodeScalars {
            let cp = s.value
            if cp == 0 || cp == 0xFFFD || isControl(s) { continue }
            if isWhitespace(s) { out.append(" "); continue }
            if isCJK(cp) {
                out.append(" "); out.append(s); out.append(" ")
            } else {
                out.append(s)
            }
        }
        return String(out)
    }

    private func stripAccents(_ s: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in s.decomposedStringWithCanonicalMapping.unicodeScalars {
            if scalar.properties.generalCategory == .nonspacingMark { continue }
            out.append(scalar)
        }
        return String(out)
    }

    private func splitOnPunctuation(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for ch in text {
            if isPunctuation(ch) {
                if !current.isEmpty { result.append(current); current = "" }
                result.append(String(ch))
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    // MARK: - WordPiece (greedy longest-match)

    private func wordpiece(_ token: String) -> [String] {
        let chars = Array(token.unicodeScalars)
        if chars.count > maxCharsPerWord { return ["[UNK]"] }
        var subTokens: [String] = []
        var start = 0
        while start < chars.count {
            var end = chars.count
            var cur: String? = nil
            while start < end {
                var substr = String(String.UnicodeScalarView(chars[start..<end]))
                if start > 0 { substr = "##" + substr }
                if vocab[substr] != nil { cur = substr; break }
                end -= 1
            }
            if cur == nil { return ["[UNK]"] }
            subTokens.append(cur!)
            start = end
        }
        return subTokens
    }

    // MARK: - Char classification (mirrors HF BERT helpers)

    private func isWhitespace(_ s: Unicode.Scalar) -> Bool {
        if s == " " || s == "\t" || s == "\n" || s == "\r" { return true }
        return s.properties.generalCategory == .spaceSeparator
    }

    private func isControl(_ s: Unicode.Scalar) -> Bool {
        if s == "\t" || s == "\n" || s == "\r" { return false }
        switch s.properties.generalCategory {
        case .control, .format, .lineSeparator, .paragraphSeparator, .privateUse, .surrogate, .unassigned:
            return true
        default:
            return false
        }
    }

    private func isPunctuation(_ ch: Character) -> Bool {
        guard let s = ch.unicodeScalars.first else { return false }
        let cp = s.value
        if (cp >= 33 && cp <= 47) || (cp >= 58 && cp <= 64) ||
           (cp >= 91 && cp <= 96) || (cp >= 123 && cp <= 126) { return true }
        switch s.properties.generalCategory {
        case .connectorPunctuation, .dashPunctuation, .openPunctuation, .closePunctuation,
             .initialPunctuation, .finalPunctuation, .otherPunctuation:
            return true
        default:
            return false
        }
    }

    private func isCJK(_ cp: UInt32) -> Bool {
        return (cp >= 0x4E00 && cp <= 0x9FFF) || (cp >= 0x3400 && cp <= 0x4DBF) ||
               (cp >= 0x20000 && cp <= 0x2A6DF) || (cp >= 0x2A700 && cp <= 0x2B73F) ||
               (cp >= 0x2B740 && cp <= 0x2B81F) || (cp >= 0x2B820 && cp <= 0x2CEAF) ||
               (cp >= 0xF900 && cp <= 0xFAFF) || (cp >= 0x2F800 && cp <= 0x2FA1F)
    }
}
