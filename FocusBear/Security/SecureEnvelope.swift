//
//  SecureEnvelope.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import CryptoKit
import Foundation

enum SecureEnvelopeError: Error, Equatable {
    case notAnEnvelope
    case unsupportedFormat(UInt8)
    case truncated
    /// Sealed with a different data key than the one this launch holds (the keychain item was
    /// recreated, or the file came from another account or install).
    case wrongKey(found: String, expected: String)
    case authenticationFailed
}

/// The on-disk format of one sealed value.
///
///     "FBS2" | format (1 byte) | key-id length (1 byte) | key id (UTF-8) | AES-GCM nonce ‖ ciphertext ‖ tag
///
/// The key id is a fingerprint of the data key (`DataKeyFingerprint`), so a file sealed with another
/// key is recognised before decryption is even attempted. The header, the bundle id and the slot
/// (which includes the account scope) are authenticated data: a file copied to another slot, another
/// account's folder or another build's folder fails to open instead of decrypting into the wrong place.
enum SecureEnvelope {
    static let magic = Data("FBS2".utf8)
    static let formatVersion: UInt8 = 1
    private static let maximumKeyIdLength = Int(UInt8.max)
    private static let separator = Data([0])

    static func seal(_ plaintext: Data, keyId: String, key: SymmetricKey, bundleId: String, slot: String) throws -> Data {
        let header = try makeHeader(keyId: keyId)
        let box = try AES.GCM.seal(plaintext, using: key,
                                   authenticating: authenticatedData(header: header, bundleId: bundleId, slot: slot))
        guard let combined = box.combined else { throw SecureEnvelopeError.authenticationFailed }
        return header + combined
    }

    static func open(_ envelope: Data, keyId: String, key: SymmetricKey, bundleId: String, slot: String) throws -> Data {
        let parsed = try parseHeader(envelope)
        guard parsed.keyId == keyId else { throw SecureEnvelopeError.wrongKey(found: parsed.keyId, expected: keyId) }
        do {
            let box = try AES.GCM.SealedBox(combined: parsed.body)
            return try AES.GCM.open(box, using: key,
                                    authenticating: authenticatedData(header: parsed.header, bundleId: bundleId, slot: slot))
        } catch {
            throw SecureEnvelopeError.authenticationFailed
        }
    }

    static func isEnvelope(_ data: Data) -> Bool {
        data.starts(with: magic)
    }

    private static func makeHeader(keyId: String) throws -> Data {
        let id = Data(keyId.utf8)
        guard !id.isEmpty, id.count <= maximumKeyIdLength else { throw SecureEnvelopeError.notAnEnvelope }
        return magic + Data([formatVersion, UInt8(id.count)]) + id
    }

    private static func parseHeader(_ envelope: Data) throws -> (header: Data, keyId: String, body: Data) {
        let bytes = Data(envelope)
        let fixedLength = magic.count + 2
        guard bytes.count >= fixedLength else { throw SecureEnvelopeError.truncated }
        guard bytes.prefix(magic.count) == magic else { throw SecureEnvelopeError.notAnEnvelope }
        let format = bytes[magic.count]
        guard format == formatVersion else { throw SecureEnvelopeError.unsupportedFormat(format) }
        let idLength = Int(bytes[magic.count + 1])
        let headerLength = fixedLength + idLength
        guard idLength > 0, bytes.count > headerLength else { throw SecureEnvelopeError.truncated }
        guard let keyId = String(data: bytes.subdata(in: fixedLength..<headerLength), encoding: .utf8) else {
            throw SecureEnvelopeError.notAnEnvelope
        }
        return (Data(bytes.prefix(headerLength)), keyId, Data(bytes.suffix(from: headerLength)))
    }

    private static func authenticatedData(header: Data, bundleId: String, slot: String) -> Data {
        header + Data(bundleId.utf8) + separator + Data(slot.utf8)
    }
}
