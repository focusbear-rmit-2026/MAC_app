//
//  ORTBridge.mm
//  Focus Bear
//
//  Objective-C++ implementation over the ONNX Runtime C++ API. Compiled as ObjC++ (.mm);
//  the header search path points at RelevanceModel/onnxruntime/include and the app links
//  + embeds libonnxruntime.1.19.2.dylib (@rpath, resolved via the app's Frameworks runpath).
//

#import "ORTBridge.h"

#include <array>
#include "onnxruntime_cxx_api.h"

#include <memory>
#include <string>
#include <vector>

@implementation ORTBridge {
    std::unique_ptr<Ort::Env> _env;
    std::unique_ptr<Ort::Session> _session;
    Ort::AllocatorWithDefaultOptions _allocator;
    std::vector<std::string> _inputNames;
    std::vector<std::string> _outputNames;
}

+ (NSString *)runtimeVersion {
    return [NSString stringWithUTF8String:OrtGetApiBase()->GetVersionString()];
}

- (nullable instancetype)initWithModelPath:(NSString *)path {
    self = [super init];
    if (!self) { return nil; }
    try {
        _env = std::make_unique<Ort::Env>(ORT_LOGGING_LEVEL_WARNING, "focusbear-relevance");
        Ort::SessionOptions options;
        options.SetIntraOpNumThreads(1);
        options.SetGraphOptimizationLevel(GraphOptimizationLevel::ORT_ENABLE_ALL);
        _session = std::make_unique<Ort::Session>(*_env, path.fileSystemRepresentation, options);

        const size_t inCount = _session->GetInputCount();
        const size_t outCount = _session->GetOutputCount();
        for (size_t i = 0; i < inCount; i++) {
            _inputNames.push_back(_session->GetInputNameAllocated(i, _allocator).get());
        }
        for (size_t i = 0; i < outCount; i++) {
            _outputNames.push_back(_session->GetOutputNameAllocated(i, _allocator).get());
        }
    } catch (const std::exception &e) {
        NSLog(@"ORTBridge: failed to load model at %@: %s", path, e.what());
        return nil;
    }
    return self;
}

// Helper: run the session with the already-built Ort::Value inputs (ordered to match _inputNames)
// and return the first output as a flat float vector.
- (std::vector<float>)runFloatOutput:(std::vector<Ort::Value> &)inputs {
    std::vector<const char *> inNames;
    inNames.reserve(_inputNames.size());
    for (const auto &n : _inputNames) { inNames.push_back(n.c_str()); }
    std::vector<const char *> outNames;
    outNames.reserve(_outputNames.size());
    for (const auto &n : _outputNames) { outNames.push_back(n.c_str()); }

    auto outputs = _session->Run(Ort::RunOptions{nullptr},
                                 inNames.data(), inputs.data(), inputs.size(),
                                 outNames.data(), outNames.size());
    const float *data = outputs.front().GetTensorData<float>();
    const size_t count = outputs.front().GetTensorTypeAndShapeInfo().GetElementCount();
    return std::vector<float>(data, data + count);
}

- (nullable NSArray<NSNumber *> *)runMiniLMWithInputIds:(NSArray<NSNumber *> *)inputIds
                                          attentionMask:(NSArray<NSNumber *> *)attentionMask
                                                 seqLen:(NSInteger)seqLen {
    if ((NSInteger)inputIds.count != seqLen || (NSInteger)attentionMask.count != seqLen) { return nil; }
    try {
        std::vector<int64_t> ids(seqLen), mask(seqLen), types(seqLen, 0);
        for (NSInteger i = 0; i < seqLen; i++) {
            ids[i] = inputIds[i].longLongValue;
            mask[i] = attentionMask[i].longLongValue;
        }
        std::array<int64_t, 2> shape{1, (int64_t)seqLen};
        auto mem = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);

        // Build inputs in the exact order the model declares them (names vary: some MiniLM
        // exports omit token_type_ids).
        std::vector<Ort::Value> inputs;
        for (const auto &name : _inputNames) {
            if (name == "input_ids") {
                inputs.push_back(Ort::Value::CreateTensor<int64_t>(mem, ids.data(), ids.size(), shape.data(), shape.size()));
            } else if (name == "attention_mask") {
                inputs.push_back(Ort::Value::CreateTensor<int64_t>(mem, mask.data(), mask.size(), shape.data(), shape.size()));
            } else if (name == "token_type_ids") {
                inputs.push_back(Ort::Value::CreateTensor<int64_t>(mem, types.data(), types.size(), shape.data(), shape.size()));
            } else {
                NSLog(@"ORTBridge: unexpected MiniLM input '%s'", name.c_str());
                return nil;
            }
        }
        std::vector<float> out = [self runFloatOutput:inputs];
        NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:out.size()];
        for (float v : out) { [result addObject:@(v)]; }
        return result;
    } catch (const std::exception &e) {
        NSLog(@"ORTBridge: MiniLM run failed: %s", e.what());
        return nil;
    }
}

- (nullable NSArray<NSNumber *> *)runTextCNNWithTokenIds:(NSArray<NSNumber *> *)tokenIds
                                                  cosine:(float)cosine {
    if (tokenIds.count != 100) { return nil; }
    try {
        std::vector<int32_t> tokens(100);
        for (NSInteger i = 0; i < 100; i++) { tokens[i] = tokenIds[i].intValue; }
        float cosBuf[1] = { cosine };
        std::array<int64_t, 2> textShape{1, 100};
        std::array<int64_t, 2> cosShape{1, 1};
        auto mem = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);

        std::vector<Ort::Value> inputs;
        for (const auto &name : _inputNames) {
            if (name == "text_input") {
                inputs.push_back(Ort::Value::CreateTensor<int32_t>(mem, tokens.data(), tokens.size(), textShape.data(), textShape.size()));
            } else if (name == "cosine_input") {
                inputs.push_back(Ort::Value::CreateTensor<float>(mem, cosBuf, 1, cosShape.data(), cosShape.size()));
            } else {
                NSLog(@"ORTBridge: unexpected TextCNN input '%s'", name.c_str());
                return nil;
            }
        }
        std::vector<float> out = [self runFloatOutput:inputs];
        NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:out.size()];
        for (float v : out) { [result addObject:@(v)]; }
        return result;
    } catch (const std::exception &e) {
        NSLog(@"ORTBridge: TextCNN run failed: %s", e.what());
        return nil;
    }
}
- (nullable NSArray<NSNumber *> *)runClassifierWithFeatures:
    (NSArray<NSNumber *> *)features {

    // The production ensemble was trained with exactly 6313 features.
    if (features.count != 6313) {
        NSLog(
            @"ORTBridge: classifier expected 6313 features, got %lu",
            (unsigned long)features.count
        );
        return nil;
    }

    try {
        // Convert NSArray<NSNumber *> -> contiguous float buffer.
        std::vector<float> featureBuffer(6313);

        for (NSInteger i = 0; i < 6313; i++) {
            featureBuffer[i] = features[i].floatValue;
        }

        // Classifier input shape = [1, 6313]
        std::array<int64_t, 2> shape{
            1,
            6313
        };

        auto mem = Ort::MemoryInfo::CreateCpu(
            OrtArenaAllocator,
            OrtMemTypeDefault
        );

        // All three exported classifiers have one float input.
        if (_inputNames.size() != 1) {
            NSLog(
                @"ORTBridge: classifier expected 1 input, got %lu",
                (unsigned long)_inputNames.size()
            );
            return nil;
        }

        std::vector<Ort::Value> inputs;

        inputs.push_back(
            Ort::Value::CreateTensor<float>(
                mem,
                featureBuffer.data(),
                featureBuffer.size(),
                shape.data(),
                shape.size()
            )
        );

        // Build ONNX input/output name arrays.
        std::vector<const char *> inNames;
        inNames.reserve(_inputNames.size());

        for (const auto &name : _inputNames) {
            inNames.push_back(name.c_str());
        }

        std::vector<const char *> outNames;
        outNames.reserve(_outputNames.size());

        for (const auto &name : _outputNames) {
            outNames.push_back(name.c_str());
        }

        // Run classifier.
        auto outputs = _session->Run(
            Ort::RunOptions{nullptr},
            inNames.data(),
            inputs.data(),
            inputs.size(),
            outNames.data(),
            outNames.size()
        );

        // Our exported sklearn/XGBoost models return:
        //
        // output 0 -> predicted class label (int64)
        // output 1 -> probabilities [P(Tier0), P(Tier1), P(Tier2)]
        //
        // Find the float tensor containing exactly 3 values instead
        // of assuming a particular output index.
        for (auto &output : outputs) {

            if (!output.IsTensor()) {
                continue;
            }

            auto info =
                output.GetTensorTypeAndShapeInfo();

            const auto elementType =
                info.GetElementType();

            const size_t count =
                info.GetElementCount();

            if (
                elementType ==
                    ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT
                &&
                count == 3
            ) {

                const float *data =
                    output.GetTensorData<float>();

                NSMutableArray<NSNumber *> *result =
                    [NSMutableArray arrayWithCapacity:3];

                for (size_t i = 0; i < 3; i++) {
                    [result addObject:@(data[i])];
                }

                return result;
            }
        }

        NSLog(
            @"ORTBridge: classifier probability output not found"
        );

        return nil;

    } catch (const std::exception &e) {

        NSLog(
            @"ORTBridge: classifier run failed: %s",
            e.what()
        );

        return nil;
    }
}

@end
