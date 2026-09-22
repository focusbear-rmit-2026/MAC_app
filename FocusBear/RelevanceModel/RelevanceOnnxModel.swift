//
//  RelevanceOnnxModel.swift
//  Focus Bear
//
//  Orchestrates the native relevance pipeline: MiniLM (int8) encodes the focus intention and tab
//  title -> masked mean-pool + L2-normalize -> cosine; that cosine + the Keras-tokenized text feed
//  the TextCNN classifier. Reproduces the trained model (Python parity verified). Runs on ORTBridge
//  (ONNX Runtime 1.19.2). See RelevanceModel/README.
//

import Foundation

final class RelevanceOnnxModel {
    private let minilm: ORTBridge
    private let textcnn: ORTBridge
    private let wordpiece: BertWordPieceTokenizer
    private let keras: KerasTextTokenizer
    private let embedDim = 384

    struct Prediction {
        let isRelevant: Bool
        let confidence: Float
        let cosine: Float
    }

    /// All four artifacts must be present (see RelevanceModelDownloader). Returns nil if any model
    /// or tokenizer fails to load.
    init?(minilmPath: String, textcnnPath: String, vocabURL: URL, wordIndexURL: URL) {
        guard let m = ORTBridge(modelPath: minilmPath),
              let t = ORTBridge(modelPath: textcnnPath),
              let wp = BertWordPieceTokenizer(vocabURL: vocabURL),
              let k = KerasTextTokenizer(wordIndexURL: wordIndexURL) else {
            return nil
        }
        minilm = m; textcnn = t; wordpiece = wp; keras = k
    }

    func predict(focusIntention: String, tabTitle: String) -> Prediction? {
        guard let ef = embed(focusIntention), let et = embed(tabTitle) else { return nil }
        let cosine = dot(ef, et)
        let tokens = keras.tokenize(focusIntention + " " + tabTitle).map { NSNumber(value: $0) }
        guard let probs = textcnn.runTextCNN(withTokenIds: tokens, cosine: cosine), probs.count == 2 else {
            return nil
        }
        let pNotRelevant = probs[0].floatValue
        let pRelevant = probs[1].floatValue
        return Prediction(isRelevant: pRelevant >= pNotRelevant,
                          confidence: max(pNotRelevant, pRelevant),
                          cosine: cosine)
    }

    /// SBERT sentence embedding: run MiniLM, mean-pool over tokens weighted by the attention mask,
    /// then L2-normalize (matches `sentence-transformers/all-MiniLM-L6-v2`).
    private func embed(_ sentence: String) -> [Float]? {
        let enc = wordpiece.encode(sentence)
        let seqLen = enc.inputIds.count
        let ids = enc.inputIds.map { NSNumber(value: $0) }
        let mask = enc.attentionMask.map { NSNumber(value: $0) }
        guard let hidden = minilm.runMiniLM(withInputIds: ids, attentionMask: mask, seqLen: seqLen),
              hidden.count == seqLen * embedDim else {
            return nil
        }

        var mean = [Float](repeating: 0, count: embedDim)
        var maskSum: Float = 0
        for t in 0..<seqLen {
            let m = Float(enc.attentionMask[t])
            maskSum += m
            let base = t * embedDim
            for j in 0..<embedDim { mean[j] += hidden[base + j].floatValue * m }
        }
        let denom = max(maskSum, 1e-9)
        var norm: Float = 0
        for j in 0..<embedDim { mean[j] /= denom; norm += mean[j] * mean[j] }
        norm = norm.squareRoot()
        if norm > 0 { for j in 0..<embedDim { mean[j] /= norm } }
        return mean
    }

    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        var sum: Float = 0
        for i in 0..<min(a.count, b.count) { sum += a[i] * b[i] }
        return sum
    }
}
