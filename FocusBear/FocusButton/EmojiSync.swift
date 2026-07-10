//
//  EmojiSync.swift
//  Focus Bear
//
//  Renders the emoji in the loaded habit names to small bitmaps and uploads them to the Focus Button
//  over the serial link. Firmware ≥ 1.7.0 (Focus-Button #29) caches these in flash and shows the
//  active habit's emoji as the centrepiece of the RUNNING ring. The device derives an emoji's key from
//  the first emoji sequence in the habit-name bytes, so no mapping table is exchanged — we just upload
//  every emoji that appears, keyed the same way.
//
//  Protocol (protocol.md "Emoji Bitmaps"):
//   • key = lowercase hex of every codepoint (incl. ZWJ 200d, VS16 fe0f, skin tones), joined by '-'.
//   • fmt=1 RGB565A8: full RGB565 (little-endian, row-major) plane then a full A8 alpha plane (w×h×3).
//   • GET|EMOJILIST → "EMOJILIST|<n>" then n × "EMOJI|<key>|<bytes>" — skip keys already cached.
//   • Upload SET|EMOJI|<key>|<w>|<h>|<fmt>|<idx>|<total>|<b64> in uniform ≤72-char base64 chunks,
//     waiting for each chunk's ACK|EMOJI before the next; final chunk answers ACK|EMOJI|<key>|DONE|<bytes>.
//   • ERROR|emoji_retry → resend the SAME chunk (bare newline first — a damaged line may have eaten the
//     terminator); other ERROR|emoji_* aborts the transfer device-side → restart from chunk 0.
//
//  The uploader is ACK-gated (lockstep): it never has more than one SET|EMOJI line in flight, so it must
//  NOT go through focusButtonService.sendCmd (whose 0.1 s no-response watchdog would inject STATUS mid
//  transfer). It writes via an injected raw-line sender instead, and focusButtonService routes the
//  device's EMOJILIST / EMOJI / ACK|EMOJI / ERROR|emoji_* lines back here.
//

import Foundation
import AppKit
import CoreText

final class EmojiSync {

    // Rendering + chunking constants (see protocol.md).
    // 110×110 RGB565A8 = 36,300 B = 673 ACK-gated chunks per icon. Over the flaky USB-CDC link that
    // NEVER completed (measured: 0 successful DONEs, transfers always desync + give up before the end).
    // 64×64 = 12,288 B ≈ 228 chunks (~3× shorter) so a transfer can actually finish; the device scales
    // it up for the ring. Drop further (48/32) if 64 still doesn't complete on-device.
    static let renderSize = 32
    static let pixelFormat = 1                  // RGB565A8
    static let base64ChunkMax = 72              // uniform chunk cap keeps the USB-CDC line-damage rate low
    static let maxChunkRetries = 5              // per-chunk ERROR|emoji_retry / timeout cap
    static let maxKeyRestarts = 5               // per-key ERROR|emoji_seq restart cap
    // ~14% of the device→Mac ACKs are genuinely LOST (156 timeouts even at a 6s timeout). The device got
    // the chunk (it answers emoji_seq to the resend), so the recovery is to ADVANCE on emoji_seq (see
    // handleError), not restart. With that, a moderate timeout just paces the resend-that-triggers-the-
    // advance; too long wastes time per lost ACK, too short races a slow-but-arriving ACK.
    static let ackTimeout: TimeInterval = 1.0   // no ACK within this → resend (→ emoji_seq → advance). Fast is
                                                // safe: advance-on-emoji_seq turns a resent-but-already-had chunk
                                                // into forward progress, so a false timeout on a slow ACK still works.
    static let listTimeout: TimeInterval = 2.0  // no full EMOJILIST within this → proceed with what we have
    static let maxKeyLength = 47                // device cap
    static let interChunkDelay: TimeInterval = 0.025   // pause after each ACK before the next chunk (cuts bursty loss)

    /// Device ERROR codes that belong to the emoji subsystem (routed here from focusButtonService). Not
    /// all start with "emoji" — invalid_emoji / no_mem / fs_error / fs_unavailable don't — so match the
    /// full set or the device-side aborts get mishandled as generic ACK timeouts.
    static func isEmojiErrorCode(_ code: String) -> Bool {
        code.hasPrefix("emoji") || ["invalid_emoji", "no_mem", "fs_error", "fs_unavailable"].contains(code)
    }

    private let sendLine: (String) -> Void
    private let logIt: (String) -> Void

    /// Upload progress for UI (Add-ons screen): (done, total) where total is the number of missing emoji
    /// to upload this run. Fires (n, total) as each starts and (total, total) when the run completes;
    /// not fired when nothing needs uploading (everything already cached).
    // Progress = (icons on the device now, total wanted). "done" counts real completions + already-cached,
    // not upload attempts, so the UI shows how many icons are actually synced.
    var onProgress: ((_ done: Int, _ total: Int) -> Void)?
    private var totalToUpload = 0
    private var completedThisRun = 0
    private var cachedWantedCount = 0   // wanted keys already on the device this pass (not all cached emoji)
    private var retryPasses = 0
    private var generation = 0   // bumped per syncEmojis; guards a queued auto-retry against being superseded
    static let maxRetryPasses = 40   // keep chipping across passes; it also stops early once a pass makes no progress

    init(send: @escaping (String) -> Void, log: @escaping (String) -> Void) {
        self.sendLine = send
        self.logIt = log
    }

    // MARK: - State

    private var wantedKeys: [String] = []       // ordered unique keys for the current habit set
    private var cachedKeys = Set<String>()      // keys the device already has (from EMOJILIST)
    private var uploadQueue: [String] = []       // keys still to upload this run

    private enum Phase { case idle, listing, uploading }
    private var phase: Phase = .idle
    private var expectedListCount = 0
    private var listReceived = 0
    private var listTimer: Timer?

    private struct Transfer {
        let key: String
        let chunks: [String]
        let width: Int
        let height: Int
        var idx = 0
        var chunkRetries = 0
        var keyRestarts = 0
    }
    private var current: Transfer?
    private var ackTimer: Timer?

    // MARK: - Entry point

    /// Kick off an emoji sync for the given habit names. Cancels any in-progress run (a new routine's
    /// habit list supersedes the old one). Queries the device's cached set first, then uploads the
    /// missing ones one at a time.
    func syncEmojis(fromHabitNames names: [String]) {
        // listTimer/ackTimer are scheduled on the current run loop; sendHabits may call this off-main
        // (where a scheduled Timer silently never fires). Hop to main, mirroring sendRawLine.
        guard Thread.isMainThread else { DispatchQueue.main.async { [weak self] in self?.syncEmojis(fromHabitNames: names) }; return }
        let keys = EmojiSync.uniqueEmojiKeys(in: names)
        guard !keys.isEmpty else { logIt("EmojiSync: no emoji in habit names — nothing to sync"); return }
        cancel()
        generation += 1
        wantedKeys = keys
        retryPasses = 0
        logIt("EmojiSync: syncing \(keys.count) emoji: \(keys.joined(separator: ", "))")
        beginPass()
    }

    /// One query→upload pass: re-read the device's cached set (authoritative — it grows as icons land)
    /// and upload what's still missing. The lossy link may not finish them all in one pass; the
    /// pass-complete handler auto-retries the rest so it converges without reopening the screen.
    private func beginPass() {
        cachedKeys.removeAll()
        expectedListCount = 0
        listReceived = 0
        completedThisRun = 0
        phase = .listing
        sendLine("GET|EMOJILIST")
        armListTimer()
    }

    /// Stop any in-progress sync (called on disconnect, or when a new sync supersedes this one).
    func cancel() {
        phase = .idle
        current = nil
        uploadQueue.removeAll()
        listTimer?.invalidate(); listTimer = nil
        ackTimer?.invalidate(); ackTimer = nil
    }

    // MARK: - Device line routing (called by focusButtonService.handleLine)

    /// `parts` is the pipe-split, timestamp-stripped device line. Handles EMOJILIST / EMOJI / ACK|EMOJI
    /// / ERROR|emoji_* (and ERROR|fs_unavailable). Ignored when idle.
    func handleDeviceLine(_ parts: [String]) {
        guard phase != .idle, let head = parts.first?.uppercased() else { return }
        switch head {
        case "EMOJILIST":
            if parts.count >= 2, let n = Int(parts[1]) {
                expectedListCount = n
                listReceived = 0
                if n == 0 { finishListing() }
            }
        case "EMOJI":
            // During the list phase this is a cached key; ignore stray EMOJI lines otherwise.
            if phase == .listing, parts.count >= 2 {
                cachedKeys.insert(parts[1])
                listReceived += 1
                if listReceived >= expectedListCount { finishListing() }
            }
        case "ACK":
            if parts.count >= 3, parts[1].uppercased() == "EMOJI" { handleAck(parts) }
        case "ERROR":
            if parts.count >= 2 { handleError(parts[1].lowercased()) }
        default:
            break
        }
    }

    // MARK: - Listing → upload

    private func armListTimer() {
        listTimer?.invalidate()
        listTimer = Timer.scheduledTimer(withTimeInterval: EmojiSync.listTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.phase == .listing else { return }
            self.logIt("EmojiSync: EMOJILIST timed out — proceeding with \(self.cachedKeys.count) cached")
            self.finishListing()
        }
    }

    private func finishListing() {
        listTimer?.invalidate(); listTimer = nil
        uploadQueue = wantedKeys.filter { !cachedKeys.contains($0) }
        totalToUpload = uploadQueue.count
        completedThisRun = 0
        // Count only the WANTED keys already on the device — NOT cachedKeys.count, which is every emoji
        // cached (habit icons too). For a small pool (e.g. 3 focus emoji) the device may have far more
        // cached, which wrongly showed "up to date" instantly even when a pool emoji hadn't uploaded.
        cachedWantedCount = wantedKeys.filter { cachedKeys.contains($0) }.count
        logIt("EmojiSync: \(cachedWantedCount)/\(wantedKeys.count) wanted already cached, \(uploadQueue.count) to upload")
        onProgress?(cachedWantedCount, wantedKeys.count)
        phase = .uploading
        startNextUpload()
    }

    private func startNextUpload() {
        current = nil
        ackTimer?.invalidate(); ackTimer = nil
        guard !uploadQueue.isEmpty else {
            let synced = cachedWantedCount + completedThisRun
            logIt("EmojiSync: pass done — \(completedThisRun) uploaded, \(synced)/\(wantedKeys.count) on device")
            onProgress?(synced, wantedKeys.count)
            phase = .idle
            // Auto-retry the still-missing icons in the background (the link drops chunks, so a pass often
            // can't finish them all) until complete, no progress was made, or the cap is hit — no need to
            // keep reopening the Focus Button screen.
            if synced < wantedKeys.count && completedThisRun > 0 && retryPasses < EmojiSync.maxRetryPasses {
                retryPasses += 1
                let g = generation
                logIt("EmojiSync: auto-retry pass \(retryPasses)/\(EmojiSync.maxRetryPasses) for \(wantedKeys.count - synced) missing")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self = self, self.generation == g, self.phase == .idle else { return }
                    self.beginPass()
                }
            }
            return
        }
        let key = uploadQueue.removeFirst()
        guard let emoji = EmojiSync.emoji(forKey: key),
              let bitmap = EmojiSync.renderRGB565A8(emoji: emoji, size: EmojiSync.renderSize) else {
            logIt("EmojiSync: could not render \(key) — skipping")
            startNextUpload()
            return
        }
        var data = bitmap.rgb565
        data.append(contentsOf: bitmap.alpha)
        let b64 = Data(data).base64EncodedString()
        let chunks = EmojiSync.split(b64, max: EmojiSync.base64ChunkMax)
        logIt("EmojiSync: uploading \(key) — \(data.count) bytes, \(chunks.count) chunks")
        current = Transfer(key: key, chunks: chunks, width: EmojiSync.renderSize, height: EmojiSync.renderSize)
        sendCurrentChunk()
    }

    private func sendCurrentChunk(bareNewlineFirst: Bool = false) {
        guard let t = current else { return }
        if bareNewlineFirst { sendLine("") }   // clear any leftover partial line before the resend
        let line = "SET|EMOJI|\(t.key)|\(t.width)|\(t.height)|\(EmojiSync.pixelFormat)|\(t.idx)|\(t.chunks.count)|\(t.chunks[t.idx])"
        sendLine(line)
        armAckTimer()
    }

    private func armAckTimer() {
        ackTimer?.invalidate()
        ackTimer = Timer.scheduledTimer(withTimeInterval: EmojiSync.ackTimeout, repeats: false) { [weak self] _ in
            guard let self = self, self.current != nil else { return }
            self.logIt("EmojiSync: ACK timeout on \(self.current!.key) chunk \(self.current!.idx)")
            self.retryCurrentChunk()
        }
    }

    // MARK: - ACK / ERROR handling

    private func handleAck(_ parts: [String]) {
        // ACK|EMOJI|<key>|<idx>  or  ACK|EMOJI|<key>|DONE|<bytes>
        guard var t = current, parts.count >= 4, parts[2] == t.key else { return }
        ackTimer?.invalidate(); ackTimer = nil
        if parts[3].uppercased() == "DONE" {
            logIt("EmojiSync: \(t.key) done (\(parts.count >= 5 ? parts[4] : "?") bytes)")
            completedThisRun += 1
            onProgress?(cachedWantedCount + completedThisRun, wantedKeys.count)
            startNextUpload()
            return
        }
        guard let ackedIdx = Int(parts[3]), ackedIdx == t.idx else { return }   // ignore stale/dup acks
        t.idx += 1
        t.chunkRetries = 0
        current = t
        if t.idx < t.chunks.count {
            // Small pause after each ACK before the next chunk: back-to-back serial lines are where the
            // bursty USB-CDC byte loss lived; ~15 ms measurably cuts retries (HITL client uses 20 ms).
            let sending = t
            DispatchQueue.main.asyncAfter(deadline: .now() + EmojiSync.interChunkDelay) { [weak self] in
                guard let self = self, let cur = self.current, cur.key == sending.key, cur.idx == sending.idx else { return }
                self.sendCurrentChunk()
            }
        }
        // else: the last chunk was just acked as an intermediate (shouldn't happen — final answers DONE);
        // wait for DONE. A timeout would retry it, which is safe.
    }

    private func handleError(_ code: String) {
        // Phase-independent: the device can report no emoji partition during the LISTING phase (before any
        // transfer starts, so current == nil) — handle it before the guard or it's silently dropped and
        // the list phase just times out.
        if code == "fs_unavailable" {
            logIt("EmojiSync: device has no emoji partition (fs_unavailable) — stopping")
            cancel()
            return
        }
        guard current != nil else { return }
        switch code {
        case "emoji_retry":
            retryCurrentChunk()
        case "emoji_seq":
            advanceAfterSeq()
        default:
            // Malformed-input errors (invalid_emoji, emoji_too_big, …) are our bug and would just loop,
            // so skip the key.
            abortCurrentKey(reason: code)
        }
    }

    private func retryCurrentChunk() {
        guard var t = current else { return }
        t.chunkRetries += 1
        if t.chunkRetries > EmojiSync.maxChunkRetries {
            abortCurrentKey(reason: "too many chunk retries")
            return
        }
        current = t
        logIt("EmojiSync: retry \(t.key) chunk \(t.idx) (\(t.chunkRetries)/\(EmojiSync.maxChunkRetries))")
        sendCurrentChunk(bareNewlineFirst: true)
    }

    private func advanceAfterSeq() {
        guard var t = current else { return }
        ackTimer?.invalidate(); ackTimer = nil
        // emoji_seq after our (re)send means the device already HAS that chunk (its ACK was lost) and
        // wants the next one. Advance rather than restart-from-0 (which just re-loses ACKs and never
        // finishes). idx only moves forward, so this always terminates; if a guess is ever wrong the
        // upload simply never reaches a valid DONE and the icon retries next sync — never a corrupt image.
        t.keyRestarts += 1
        guard t.keyRestarts <= t.chunks.count * 3 else { abortCurrentKey(reason: "emoji_seq loop"); return }
        if t.idx + 1 < t.chunks.count {
            t.idx += 1
        } else {
            t.idx = t.chunks.count - 1   // stay on the last chunk; resend to prompt a (possibly lost) DONE
        }
        t.chunkRetries = 0
        current = t
        sendCurrentChunk()
    }

    private func abortCurrentKey(reason: String) {
        ackTimer?.invalidate(); ackTimer = nil
        if let key = current?.key { logIt("EmojiSync: giving up on \(key) (\(reason))") }
        startNextUpload()
    }
}

// MARK: - Emoji extraction + key derivation

extension EmojiSync {

    /// Ordered, de-duplicated emoji keys across the given habit names. Each name contributes its first
    /// emoji sequence (the one the device keys off), matching the firmware's own derivation.
    static func uniqueEmojiKeys(in names: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for name in names {
            guard let key = firstEmojiKey(in: name), !seen.contains(key) else { continue }
            seen.insert(key)
            out.append(key)
        }
        return out
    }

    /// The key for the first emoji sequence in `name`, or nil if it has none. One grapheme cluster is
    /// one sequence (Swift groups ZWJ / VS16 / skin-tone runs into a single `Character`).
    static func firstEmojiKey(in name: String) -> String? {
        for ch in name {
            let scalars = Array(ch.unicodeScalars)
            guard let first = scalars.first, isEmojiBase(first) else { continue }
            let key = scalars.map { String($0.value, radix: 16) }.joined(separator: "-")
            return key.count <= maxKeyLength ? key : nil
        }
        return nil
    }

    /// Whether `s` starts an emoji sequence the device recognises (keep in sync with protocol.md).
    static func isEmojiBase(_ s: Unicode.Scalar) -> Bool {
        let v = s.value
        return (0x1F000...0x1FAFF).contains(v)
            || (0x2600...0x27BF).contains(v)
            || (0x2B00...0x2BFF).contains(v)
            || (0x231A...0x23FA).contains(v)
    }

    /// Reconstruct the emoji string from a `1f9d1-200d-1f4bb` key (for rendering).
    static func emoji(forKey key: String) -> String? {
        var s = ""
        for hex in key.split(separator: "-") {
            guard let v = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(v) else { return nil }
            s.unicodeScalars.append(scalar)
        }
        return s.isEmpty ? nil : s
    }
}

// MARK: - Rendering + chunking

extension EmojiSync {

    /// Render `emoji` at `size`×`size` into RGB565A8: a little-endian RGB565 plane (row-major, top-left
    /// origin) followed by an A8 alpha plane. RGB is un-premultiplied so the device can composite it over
    /// the user-configurable ring background.
    static func renderRGB565A8(emoji: String, size: Int) -> (rgb565: [UInt8], alpha: [UInt8])? {
        let w = size, h = size
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = buf.withUnsafeMutableBytes({ ptr -> CGContext? in
            CGContext(data: ptr.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                      space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        }) else { return nil }

        ctx.clear(CGRect(x: 0, y: 0, width: w, height: h))
        let font = CTFontCreateWithName("AppleColorEmoji" as CFString, CGFloat(size) * 0.82, nil)
        let attr = NSAttributedString(string: emoji, attributes: [.font: font as Any])
        let ctLine = CTLineCreateWithAttributedString(attr)
        let bounds = CTLineGetImageBounds(ctLine, ctx)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        ctx.textPosition = CGPoint(x: (CGFloat(w) - bounds.width) / 2 - bounds.minX,
                                   y: (CGFloat(h) - bounds.height) / 2 - bounds.minY)
        CTLineDraw(ctLine, ctx)

        var rgb = [UInt8](repeating: 0, count: w * h * 2)
        var alpha = [UInt8](repeating: 0, count: w * h)
        for row in 0..<h {
            let srcRow = h - 1 - row   // CGContext origin is bottom-left; device rows are top-to-bottom
            for col in 0..<w {
                let i = (srcRow * w + col) * 4
                let a = buf[i + 3]
                var r = buf[i], g = buf[i + 1], b = buf[i + 2]
                if a > 0 && a < 255 {   // un-premultiply
                    r = UInt8(min(255, Int(r) * 255 / Int(a)))
                    g = UInt8(min(255, Int(g) * 255 / Int(a)))
                    b = UInt8(min(255, Int(b) * 255 / Int(a)))
                }
                let v = (UInt16(r & 0xF8) << 8) | (UInt16(g & 0xFC) << 3) | (UInt16(b) >> 3)
                let o = (row * w + col) * 2
                rgb[o] = UInt8(v & 0xFF)          // little-endian
                rgb[o + 1] = UInt8(v >> 8)
                alpha[row * w + col] = a
            }
        }
        return (rgb, alpha)
    }

    /// Split a base64 string into uniform chunks of at most `max` characters (only the last is shorter).
    static func split(_ s: String, max: Int) -> [String] {
        guard max > 0, !s.isEmpty else { return s.isEmpty ? [] : [s] }
        var chunks: [String] = []
        var i = s.startIndex
        while i < s.endIndex {
            let j = s.index(i, offsetBy: max, limitedBy: s.endIndex) ?? s.endIndex
            chunks.append(String(s[i..<j]))
            i = j
        }
        return chunks
    }
}
