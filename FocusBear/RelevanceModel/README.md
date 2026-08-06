# Relevance model — native ONNX runtime (shadow mode)

Runs the website-relevance model **natively via ONNX Runtime** (no Python subprocess), for the
observe-only relevance shadow mode (`Focus mode/RelevanceShadowLogger.swift`). Replaces the
dev-only `predict_server.py` path so shadow logging works for every user.

## Two models, chained
1. **MiniLM** (`all-MiniLM-L6-v2`, int8-quantized) → sentence embeddings; we mean-pool + L2-normalize
   in Swift and take the cosine of (focus intention, tab title).
2. **TextCNN** (`textcnn_cosine.onnx`) → takes the Keras-tokenized text + that cosine scalar → 2-class
   relevance. Reproduces the trained model exactly (Keras↔ONNX parity 6e-8); int8 pipeline accuracy
   86.05% vs 86.32% fp32/Keras on the held-out test set.

## ONNX Runtime version — **pinned to 1.19.2**
The app deploys to **macOS 11**. The `onnxruntime-*` CocoaPods and ORT ≥ 1.20 require macOS 13/14;
**1.19.2 is the newest official ORT that targets macOS 11.0**. So we direct-link its arm64 dylib
(install name `@rpath/…`, resolved via the app's `@executable_path/../Frameworks` runpath),
embedded + code-signed on copy — no CocoaPod, no `pod install`.

## What's committed vs fetched vs downloaded
- **Committed:** `ORTBridge.{h,mm}` (ObjC++ wrapper over the ORT C++ API) + the Swift layer.
- **Fetched at build time** (not committed — large binary, like `Sparkle.framework`):
  `onnxruntime/{lib,include}` via `scripts/fetch-onnxruntime.sh` (pinned + SHA-256 verified).
  **Run `./scripts/fetch-onnxruntime.sh` once after cloning.**
- **Downloaded on first run** (not committed — ~34 MB, updatable without an app release):
  the model artifacts (`textcnn_cosine.onnx`, `minilm_quantized.onnx`, `tokenizer_word_index.json`,
  `minilm_vocab.txt`), cached under Application Support. Python path is the fallback until they land.

Full inference/preprocessing contract: see the artifacts' `ARTIFACTS_README.md` in the model repo.
