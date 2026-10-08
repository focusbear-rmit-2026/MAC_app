//
//  WiFiProfileMapping.swift
//  FocusBear
//
//  Created by Jose Vega on 2026-05-19.
//  Copyright © 2026 Focus Bear. All rights reserved.
//
//  Data model and persistence for WiFi → Focus Bear profile mappings.
//  Implements part of #1000 — Auto switch to WFH/office depending on wifi network.
//

import Foundation

// MARK: - WiFiProfileMapping

/// A single mapping from a Wi-Fi SSID to a Focus Bear profile name.
struct WiFiProfileMapping: Codable, Equatable, Identifiable {
    var id: String          // UUID string
    var ssid: String        // Wi-Fi network name (SSID)
    var profileName: String // Focus Bear profile to switch to when connected

    init(id: String = UUID().uuidString, ssid: String, profileName: String) {
        self.id = id
        self.ssid = ssid
        self.profileName = profileName
    }
}

// MARK: - Persistence

extension WiFiProfileMapping {

    // Use the shared constant from allUserdefaults.swift to avoid key duplication.
    private static let userDefaultsKey = kUserdefaultsWiFiProfileMappings

    /// Load all saved mappings from UserDefaults.
    static func loadAll() -> [WiFiProfileMapping] {
        guard
            let data = SensitiveDefaults.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode([WiFiProfileMapping].self, from: data)
        else {
            return []
        }
        return decoded
    }

    /// Persist the full list of mappings to UserDefaults.
    static func saveAll(_ mappings: [WiFiProfileMapping]) {
        guard let data = try? JSONEncoder().encode(mappings) else {
            addLog(text: "WiFiProfileMapping.saveAll: encoding failed")
            return
        }
        SensitiveDefaults.set(data, forKey: userDefaultsKey)
        addLog(text: "WiFiProfileMapping.saveAll: saved \(mappings.count) mapping(s)")
    }

    /// Add or update a mapping by SSID. Updates profileName if SSID already exists.
    static func upsert(_ mapping: WiFiProfileMapping) {
        var all = loadAll()
        if let idx = all.firstIndex(where: { $0.ssid == mapping.ssid }) {
            all[idx] = mapping
        } else {
            all.append(mapping)
        }
        saveAll(all)
    }

    /// Remove the mapping with the given id.
    static func remove(id: String) {
        var all = loadAll()
        all.removeAll { $0.id == id }
        saveAll(all)
    }
}
