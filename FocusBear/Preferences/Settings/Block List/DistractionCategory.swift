//
//  DistractionCategory.swift
//  Focus Bear
//
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Foundation

/// The single distraction-category taxonomy shared by onboarding (the block-URLs outline tree)
/// and the block-list screen.
///
/// The raw values are the **wire format**: they are persisted in UserDefaults and round-trip to the
/// backend's `focus_mode.categories` column, so they must never be renamed. Only the human-readable
/// `displayName` changes between languages.
enum DistractionCategory: String, CaseIterable, Codable {
    case socialMedia = "social_media"
    case news = "news"
    case video = "video"
    case gaming = "gaming"
    case dating = "dating"
    case realEstate = "real_estate"
    case porn = "porn"
    case gambling = "gambling"
    case other = "other"

    /// `other` is the catch-all for anything the catalog can't place; it is never a suggestion source
    /// and always sorts last.
    static let fallback: DistractionCategory = .other

    /// Categories offered as filters on the block-list screen, in display order (`other` last).
    static var orderedForFiltering: [DistractionCategory] {
        allCases.filter { $0 != .fallback } + [.fallback]
    }

    /// The subset onboarding's outline tree has always shown. Onboarding keeps exactly the categories
    /// it shipped with — adding `porn`/`gambling`/`gaming` to a first-run screen is a product change
    /// nobody asked for — but both screens now read one taxonomy instead of two copies.
    var appearsInOnboarding: Bool {
        switch self {
        case .socialMedia, .news, .video, .dating, .realEstate: return true
        case .gaming, .porn, .gambling, .other: return false
        }
    }
}

// MARK: - Display names

extension DistractionCategory {
    /// config.json block holding this category's translated display name, and the key within it.
    ///
    /// The five onboarding categories keep reading their long-standing `onboardingBlockedUrlsInfo`
    /// keys so existing translations (and onboarding itself) are untouched; the categories the
    /// block-list screen adds live in the new `blockListViewInfo` block.
    private var nameSource: (block: String, key: String, fallback: String) {
        switch self {
        case .socialMedia: return (ConfigBlock.onboardingBlockedUrls, "categorySocialMedia", "Social Media")
        case .news:        return (ConfigBlock.onboardingBlockedUrls, "categoryNews", "News")
        case .video:       return (ConfigBlock.onboardingBlockedUrls, "categoryStreamingServices", "Streaming services")
        case .dating:      return (ConfigBlock.onboardingBlockedUrls, "categoryDating", "Dating")
        case .realEstate:  return (ConfigBlock.onboardingBlockedUrls, "categoryRealEstate", "Real estate")
        case .other:       return (ConfigBlock.onboardingBlockedUrls, "categoryOthers", "Others")
        case .gaming:      return (ConfigBlock.blockList, "categoryGaming", "Gaming")
        case .porn:        return (ConfigBlock.blockList, "categoryPorn", "Adult")
        case .gambling:    return (ConfigBlock.blockList, "categoryGambling", "Gambling")
        }
    }

    private enum ConfigBlock {
        static let onboardingBlockedUrls = "onboardingBlockedUrlsInfo"
        static let blockList = "blockListViewInfo"
    }

    var displayName: String {
        let source = nameSource
        let block = configjson.value(forKey: source.block) as? NSDictionary
        let value = block?.value(forKey: source.key) as? String
        // An empty string in the downloaded config must render as the English fallback, never as a
        // blank pill (same rule as ScheduleText.t).
        return (value?.isEmpty == false) ? value! : source.fallback
    }
}

// MARK: - Catalog

/// The seed domains behind each category: what onboarding offers as pre-ticked suggestions, and what
/// the block-list screen uses to classify an entry the user never categorised by hand.
enum DistractionCategoryCatalog {

    /// URL fragments that were previously hard-coded inside `onboardingBlockedUrlsVc`. Onboarding now
    /// builds its outline from this table, so the two screens cannot drift apart.
    static func seedEntries(for category: DistractionCategory) -> [String] {
        switch category {
        case .socialMedia:
            return ["facebook.com", "x.com", "instagram.com", "tiktok.com", "youtube.com",
                    "reddit.com", "www.linkedin.com/feed/"]
        case .news:
            return ["bbc.com", "cnn.com", "theguardian.com", "abc.net.au", "news", "nytimes.com",
                    "news.com.au", "smh.com.au", "foxnews.com"]
        case .video:
            return ["netflix", "disney", "hulu"]
        case .dating:
            return ["tinder.com", "bumble.com", "hinge.co", "match.com", "okcupid.com", "pof.com",
                    "eharmony.com", "grindr.com"]
        case .realEstate:
            return ["realestate.com.au", "domain.com.au", "zillow.com", "realtor.com", "rightmove.co.uk"]
        case .gaming:
            return ["twitch.tv", "steampowered.com", "roblox.com", "epicgames.com", "chess.com"]
        case .porn, .gambling:
            // Deliberately empty: these categories exist so a user can file an entry under them, but
            // Focus Bear does not ship a list of adult or betting domains.
            return []
        case .other:
            return []
        }
    }

    /// The seed onboarding drops for students, who legitimately study on YouTube.
    static let studentExcludedSeed = "youtube.com"

    /// Shortest entry worth matching against the seed table by substring.
    private static let minimumMatchLength = 3

    /// Best-effort category for a blocked entry the user has not filed by hand.
    ///
    /// Matching is substring-based in both directions because a block entry may be a bare keyword
    /// ("netflix") or a full URL ("www.instagram.com/explore"), and the seeds are a mix of both.
    static func inferredCategory(for entry: String) -> DistractionCategory? {
        let needle = entry.lowercased()
        // A one- or two-character entry would match half the catalog by substring; leave it uncategorised.
        guard needle.count >= minimumMatchLength else { return nil }
        for category in DistractionCategory.orderedForFiltering where category != .other {
            for seed in seedEntries(for: category) {
                let seedLower = seed.lowercased()
                if needle.contains(seedLower) || seedLower.contains(needle) {
                    return category
                }
            }
        }
        return nil
    }
}
