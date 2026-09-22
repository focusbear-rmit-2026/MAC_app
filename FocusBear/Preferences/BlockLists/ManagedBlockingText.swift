import Foundation

/// Shared config copy for managed safety. Fallbacks also work before a remote config refresh.
enum ManagedBlockingText {
    static func value(_ key: String, fallback: String) -> String {
        guard let section = configjson["managedBlockingInfo"] as? NSDictionary,
              let text = section[key] as? String, !text.isEmpty else { return fallback }
        return text
    }

    static func category(_ id: String) -> String {
        if let section = configjson["managedBlockingInfo"] as? NSDictionary,
           let categories = section["categories"] as? NSDictionary,
           let label = categories[id] as? String, !label.isEmpty {
            return label
        }
        // These are registry labels, not a claim that every category has an available provider.
        return categoryLabels[id] ?? id
    }

    static let categoryLabels: [String: String] = [
        "adult": "Adult", "auctions": "Auctions",
        "browser_runtime_attack": "Browser Runtime Attack",
        "command_and_control": "Command and Control",
        "compromised_website": "Compromised Website",
        "copyright_infringement": "Copyright Infringement",
        "cryptocurrency": "Cryptocurrency", "dating": "Dating",
        "dynamic_dns": "Dynamic DNS", "encrypted_dns": "Encrypted DNS",
        "extremism": "Extremism", "gambling": "Gambling", "games": "Games",
        "grayware": "Grayware", "hacking": "Hacking", "high_risk": "High Risk",
        "insufficient_content": "Insufficient Content", "internet_portals": "Internet Portals",
        "malware": "Malware", "medium_risk": "Medium Risk",
        "newly_registered_domains": "Newly Registered Domains", "not_resolved": "Not-Resolved",
        "parked": "Parked", "peer_to_peer": "Peer-to-peer", "phishing": "Phishing",
        "private_ip_addresses": "Private IP Addresses",
        "proxy_avoidance_and_anonymizers": "Proxy Avoidance and Anonymizers",
        "questionable": "Questionable", "ransomware": "Ransomware",
        "real_time_detection": "Real-time Detection", "remote_access": "Remote Access",
        "scanning_activity": "Scanning Activity", "shareware_and_freeware": "Shareware and Freeware",
        "social_networking": "Social Networking", "streaming_media": "Streaming Media",
        "unknown": "Unknown", "weapons": "Weapons", "web_advertisements": "Web Advertisements",
        "web_based_email": "Web-based Email"
    ]
}
