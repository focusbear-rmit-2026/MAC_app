//
//  RelevanceModelDownloader.swift
//  Focus Bear
//
//  First-run download + cache of the relevance model artifacts (~34 MB) — they're not bundled so
//  they can be updated without an app release. Files land in Application Support/RelevanceModel/;
//  once all are present, RelevanceEnsembleModel loads from there. Until then the caller falls back to
//  the existing path. See RelevanceModel/README.
//

import Foundation

enum RelevanceModelArtifacts {

    static let activeVersion = "v2"
    // Existing client/backend relevance contract remains V1.
    // V2 is currently shadow-only.
    static let version = "v1"
    static let textcnn = "textcnn_cosine.onnx"
    static let minilm = "minilm_quantized.onnx"
    static let wordIndex = "tokenizer_word_index.json"
    static let vocab = "minilm_vocab.txt"

    static let baseURL = "https://pub-a0f25f0d306d4d63bbfc52aa624ae389.r2.dev"

    static var all: [String] {

        switch activeVersion {

        case "v1":
            return [
                "textcnn_cosine.onnx",
                "minilm_quantized.onnx",
                "tokenizer_word_index.json",
                "minilm_vocab.txt"
            ]

        case "v2":
            return [
                "minilm_fp32.onnx",
                "minilm_vocab.txt",
                "lr.onnx",
                "xgb.onnx",
                "xgb_tuned.onnx",
                "tfidf_goal.json",
                "tfidf_context.json"
            ]

        default:
            return []
        }
    }

    static func cacheDirectory() -> URL? {

        guard let base =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        return base
            .appendingPathComponent(
                "RelevanceModel",
                isDirectory: true
            )
            .appendingPathComponent(
                activeVersion,
                isDirectory: true
            )
    }

    static func bundledV2Directory() -> URL? {

        guard activeVersion == "v2",
              let resourceURL = Bundle.main.resourceURL
        else {
            return nil
        }

        let filesPresent = all.allSatisfy { file in

            let path =
                resourceURL.appendingPathComponent(file).path

            guard
                let attributes =
                    try? FileManager.default
                        .attributesOfItem(
                            atPath: path
                        ),

                let size =
                    attributes[.size]
                        as? NSNumber
            else {
                return false
            }

            return size.intValue > 0
        }

        return filesPresent ? resourceURL : nil
    }

    static func localURL(_ file: String) -> URL? {
        cacheDirectory()?
            .appendingPathComponent(file)
    }

    static var allPresent: Bool {

        guard let dir = cacheDirectory()
        else {
            return false
        }

        return all.allSatisfy { file in

            let path =
                dir.appendingPathComponent(file).path

            guard
                let attributes =
                    try? FileManager.default
                        .attributesOfItem(
                            atPath: path
                        ),

                let size =
                    attributes[.size]
                        as? NSNumber
            else {
                return false
            }

            return size.intValue > 0
        }
    }
}

final class RelevanceModelDownloader {
    static let shared = RelevanceModelDownloader()
    private let queue = DispatchQueue(label: "relevance.model.download")
    private var inFlight = false

    private init() {}

    /// Ensures all artifacts are cached, downloading any that are missing. `completion` runs with the
    /// cache directory once everything is present, or nil on failure / no network. Idempotent and
    /// safe to call on every relevance check — it no-ops when already present or already downloading.
    func ensureAvailable(completion: @escaping (URL?) -> Void) {

        if RelevanceModelArtifacts.activeVersion == "v2" {

            guard let directory =
                    RelevanceModelArtifacts.bundledV2Directory()
            else {
                addLog(
                    text:
                        "RelevanceModelDownloader: bundled V2 artifacts unavailable"
                )
                completion(nil)
                return
            }

            completion(directory)
            return
        }

        if RelevanceModelArtifacts.allPresent {
            completion(RelevanceModelArtifacts.cacheDirectory())
            return
        }

        queue.async { [weak self] in
            guard let self = self, !self.inFlight else { completion(nil); return }
            self.inFlight = true
            defer { self.inFlight = false }

            guard let dir = RelevanceModelArtifacts.cacheDirectory() else { completion(nil); return }

            do {
                try FileManager.default.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true
                )
            } catch {
                addLog(
                    text:
                        "RelevanceModelDownloader: can't create cache dir: \(error.localizedDescription)"
                )
                completion(nil)
                return
            }

            for file in RelevanceModelArtifacts.all {

                let dest =
                    dir.appendingPathComponent(file)

                if let size =
                    try? FileManager.default
                        .attributesOfItem(
                            atPath: dest.path
                        )[.size] as? Int,
                   size > 0 {

                    continue
                }

                guard let remote = URL(
                    string:
                        "\(RelevanceModelArtifacts.baseURL)/\(RelevanceModelArtifacts.activeVersion)/\(file)"
                ),
                self.downloadSync(
                    from: remote,
                    to: dest
                )
                else {
                    addLog(
                        text:
                            "RelevanceModelDownloader: failed to fetch \(file) — will retry next run."
                    )
                    completion(nil)
                    return
                }
            }

            addLog(
                text:
                    "RelevanceModelDownloader: all relevance artifacts cached at \(dir.path)"
            )

            completion(dir)
        }
    }

    /// Blocking download to a temp file then atomic move — runs on the private queue.
    private func downloadSync(from remote: URL, to dest: URL) -> Bool {
        let sem = DispatchSemaphore(value: 0)
        var ok = false

        let task =
            URLSession.shared.downloadTask(with: remote) {
                tmp, response, error in

                defer { sem.signal() }

                guard
                    let tmp = tmp,
                    error == nil,
                    let http = response as? HTTPURLResponse,
                    (200...299).contains(http.statusCode)
                else {
                    return
                }

                do {
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try FileManager.default.removeItem(at: dest)
                    }

                    try FileManager.default.moveItem(at: tmp, to: dest)
                    ok = true
                } catch {
                    addLog(
                        text:
                            "RelevanceModelDownloader: move failed: \(error.localizedDescription)"
                    )
                }
            }

        task.resume()
        sem.wait()

        return ok
    }
}
