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

@end
