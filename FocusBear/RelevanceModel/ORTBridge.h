//
//  ORTBridge.h
//  Focus Bear
//
//  Thin Objective-C++ wrapper over the ONNX Runtime C++ API so Swift can run the two
//  relevance shadow-mode models (MiniLM encoder + TextCNN classifier) without touching
//  C++. One ORTBridge instance owns one loaded model + session. See
//  RelevanceModel/ARTIFACTS contract; runtime is ORT 1.19.2 (macOS-11 compatible).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ORTBridge : NSObject

/// The linked ONNX Runtime version string (e.g. "1.19.2"). Cheap call that proves the
/// dylib links and loads at runtime.
+ (NSString *)runtimeVersion;

/// Loads an ONNX model from `path`. Returns nil if the file is missing or can't be parsed.
- (nullable instancetype)initWithModelPath:(NSString *)path;

/// Runs the MiniLM encoder for one sentence. `inputIds` / `attentionMask` are length-`seqLen`
/// token arrays (int64). token_type_ids are supplied as zeros internally. Returns the flattened
/// `last_hidden_state` (`seqLen * 384` floats) for the caller to mean-pool + L2-normalize in
/// Swift, or nil on failure.
- (nullable NSArray<NSNumber *> *)runMiniLMWithInputIds:(NSArray<NSNumber *> *)inputIds
                                          attentionMask:(NSArray<NSNumber *> *)attentionMask
                                                 seqLen:(NSInteger)seqLen;

/// Runs the TextCNN classifier. `tokenIds` must be exactly 100 int32 ids (post-padded);
/// `cosine` is the MiniLM cosine scalar. Returns the 2 softmax probabilities
/// `[P(NotRelevant), P(Relevant)]`, or nil on failure.
- (nullable NSArray<NSNumber *> *)runTextCNNWithTokenIds:(NSArray<NSNumber *> *)tokenIds
                                                  cosine:(float)cosine;
/// Runs one ensemble classifier (LR / XGB / tuned XGB).
/// `features` must contain exactly 6313 float values.
/// Returns the three class probabilities:
/// [P(Tier0), P(Tier1), P(Tier2)]
/// or nil on failure.
- (nullable NSArray<NSNumber *> *)runClassifierWithFeatures:
    (NSArray<NSNumber *> *)features;

@end

NS_ASSUME_NONNULL_END
