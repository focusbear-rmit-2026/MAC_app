//
//  RelevanceShadowNativeModel.swift
//  Focus Bear
//
//  App-wide native relevance model for shadow mode. On first use it downloads the artifacts
//  (RelevanceModelDownloader) and loads the ONNX pipeline (RelevanceOnnxModel), then serves
//  predictions off a serial background queue. Replaces the dev-only Python predict_server path, so
//  shadow logging produces a real prediction for every user. Observe-only; never affects blocking.
//

import Foundation

final class RelevanceShadowNativeModel {
    static let shared = RelevanceShadowNativeModel()

    private let queue = DispatchQueue(label: "relevance.shadow.native")
    private var model: RelevanceOnnxModel?
    private var loading = false

    private init() {}

    /// Proactively download + load the model (from cache if already fetched) so it's ready before the
    /// first focus-mode URL check, instead of the first check returning `unavailable` while it loads.
    func warmUp() {
        queue.async { [weak self] in self?.loadIfNeeded() }
    }

    /// Kick off download + load if not already done/underway. Runs on the private queue.
    private func loadIfNeeded() {
        guard model == nil, !loading else { return }
        loading = true
        RelevanceModelDownloader.shared.ensureAvailable { [weak self] dir in
            guard let self = self else { return }
            self.queue.async {
                self.loading = false
                guard self.model == nil, let dir = dir else { return }
                self.model = RelevanceOnnxModel(
                    minilmPath: dir.appendingPathComponent(RelevanceModelArtifacts.minilm).path,
                    textcnnPath: dir.appendingPathComponent(RelevanceModelArtifacts.textcnn).path,
                    vocabURL: dir.appendingPathComponent(RelevanceModelArtifacts.vocab),
                    wordIndexURL: dir.appendingPathComponent(RelevanceModelArtifacts.wordIndex))
                if self.model != nil {
                    addLog(text: "RelevanceShadowNativeModel: loaded (ONNX Runtime \(ORTBridge.runtimeVersion()))")
                }
            }
        }
    }

    /// Predict off the background queue. `completion` runs with the prediction, or nil if the model
    /// isn't loaded yet (in which case a load is kicked off for subsequent checks). Never blocks the
    /// caller's thread.
    func predict(focusIntention: String, tabTitle: String,
                 completion: @escaping (RelevanceOnnxModel.Prediction?) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { completion(nil); return }
            guard let model = self.model else {
                self.loadIfNeeded()
                completion(nil)
                return
            }
            completion(model.predict(focusIntention: focusIntention, tabTitle: tabTitle))
        }
    }
}
