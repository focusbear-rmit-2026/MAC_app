//
//  SecureMerge.swift
//  FocusBear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// Combines two versions of a local-only value so neither side's entries are lost.
///
/// Used when a write made while the data key was unavailable (so the writer could not see the sealed
/// value) meets the sealed value once the key is back, and when plaintext an older build wrote meets a
/// sealed copy. The incoming side wins wherever both have the same entry; entries only the base has
/// are kept. The cost of that bias is that an entry deleted while the key was unavailable can come
/// back — preferred to losing an unsent edit.
enum SecureMerge {
    private static let identifierField = "id"

    static func union(base: Any, incoming: Any) -> Any {
        if let baseData = base as? Data, let incomingData = incoming as? Data {
            return unionJSON(baseData, incomingData) ?? incoming
        }
        return unionObjects(base, incoming)
    }

    /// Both sides decoded as JSON, merged, and encoded again; nil when either side isn't JSON.
    private static func unionJSON(_ base: Data, _ incoming: Data) -> Data? {
        guard let baseObject = try? JSONSerialization.jsonObject(with: base),
              let incomingObject = try? JSONSerialization.jsonObject(with: incoming) else { return nil }
        let merged = unionObjects(baseObject, incomingObject)
        guard JSONSerialization.isValidJSONObject(merged) else { return nil }
        return try? JSONSerialization.data(withJSONObject: merged)
    }

    static func unionObjects(_ base: Any, _ incoming: Any) -> Any {
        if let baseMap = base as? [String: Any], let incomingMap = incoming as? [String: Any] {
            return baseMap.merging(incomingMap) { baseEntry, incomingEntry in unionObjects(baseEntry, incomingEntry) }
        }
        if let baseList = base as? [Any], let incomingList = incoming as? [Any] {
            return unionLists(baseList, incomingList)
        }
        return incoming
    }

    /// Lists of records with an `id` merge by id (incoming record wins); other lists keep every
    /// incoming element plus the base elements the incoming side doesn't have.
    private static func unionLists(_ base: [Any], _ incoming: [Any]) -> [Any] {
        let incomingIds = incoming.compactMap(identifier(of:))
        if incomingIds.count == incoming.count, base.allSatisfy({ identifier(of: $0) != nil }) {
            let known = Set(incomingIds)
            return incoming + base.filter { !known.contains(identifier(of: $0)!) }
        }
        return incoming + base.filter { element in !incoming.contains { ($0 as AnyObject).isEqual(element) } }
    }

    private static func identifier(of element: Any) -> String? {
        guard let record = element as? [String: Any], let id = record[identifierField] else { return nil }
        if let text = id as? String { return text }
        if let number = id as? NSNumber { return number.stringValue }
        return nil
    }
}
