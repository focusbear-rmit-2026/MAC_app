//
//  InstalledApps.swift
//  Focus Bear
//
//  The one place the app enumerates the applications installed on this Mac. The list feeds the
//  Edit Habits webview (`installedApps` — the web's allowed-app suggestions) and the Day Plan habit
//  editor's allowed-apps typeahead. Enumeration walks the standard app folders one level deep (so
//  "Utilities" and vendor sub-folders are included) plus whatever is running right now, so an app
//  launched from an unusual location still shows up.
//

import AppKit

struct InstalledApp: Hashable, Identifiable {
    /// The `.app` bundle's filename without the extension — the identifier stored in a habit's
    /// `allowed_apps`. It's what the web dashboard suggests and saves, and what the routine player
    /// compares the frontmost app's bundle URL against (AppDelegate's allowed-app check).
    let name: String
    let url: URL

    var id: String { name }

    func matches(_ query: String) -> Bool {
        name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    func hasPrefix(_ query: String) -> Bool {
        name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive, .anchored]) != nil
    }
}

final class InstalledApps {
    static let shared = InstalledApps()

    static let appExtension = "app"
    /// Standard app locations; each is scanned one folder deep, which covers `Utilities` and vendor folders.
    static let searchDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    private let queue = DispatchQueue(label: "io.focusbear.installed-apps", qos: .userInitiated)
    private var cache: [InstalledApp]?
    private var iconCache: [String: NSImage] = [:]
    private var displayNameCache: [String: String?] = [:]
    private var pendingCallbacks: [([InstalledApp]) -> Void] = []
    private var isLoading = false

    /// Cached apps sorted by name, enumerating synchronously on the first call. Used by the webview
    /// loaders, which need the list before the page is handed its settings.
    func apps() -> [InstalledApp] {
        if let cached = cache { return cached }
        let loaded = Self.enumerate()
        cache = loaded
        return loaded
    }

    /// The `allowed_apps` identifiers of every installed app (the web's `installedApps` suggestions).
    func names() -> [String] { apps().map(\.name) }

    /// Loads off the main thread (once) and delivers on the main thread; later calls get the cache.
    func load(completion: @escaping ([InstalledApp]) -> Void) {
        if let cached = cache { completion(cached); return }
        pendingCallbacks.append(completion)
        guard !isLoading else { return }
        isLoading = true
        queue.async {
            let loaded = Self.enumerate()
            DispatchQueue.main.async {
                self.cache = loaded
                self.isLoading = false
                let callbacks = self.pendingCallbacks
                self.pendingCallbacks = []
                callbacks.forEach { $0(loaded) }
            }
        }
    }

    /// The Finder icon for an app; cached because the typeahead re-renders while typing.
    func icon(for app: InstalledApp) -> NSImage {
        if let cached = iconCache[app.name] { return cached }
        let icon = NSWorkspace.shared.icon(forFile: app.url.path)
        iconCache[app.name] = icon
        return icon
    }

    /// `CFBundleDisplayName`/`CFBundleName` when it differs from the filename (e.g. "Visual Studio Code"
    /// → "Code"). Read lazily per row: opening every bundle's Info.plist up front made enumeration
    /// ~20× slower, and only the handful of suggested rows ever need it.
    func distinctDisplayName(for app: InstalledApp) -> String? {
        if let cached = displayNameCache[app.name] { return cached }
        let bundle = Bundle(url: app.url)
        let declared = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
        let distinct = declared == app.name ? nil : declared
        displayNameCache[app.name] = distinct
        return distinct
    }

    // MARK: - Enumeration

    static func enumerate() -> [InstalledApp] {
        var bundleURLs = searchDirectories.flatMap(appBundles(in:))
        bundleURLs += NSWorkspace.shared.runningApplications.compactMap { runningApp in
            // Background helpers (menu-bar agents, XPC services) aren't apps a user would allow.
            runningApp.activationPolicy == .regular ? runningApp.bundleURL : nil
        }
        // Dedupe by name: it's the identifier that gets stored, so two copies of an app are one entry.
        var seen = Set<String>()
        return bundleURLs.compactMap(app(at:)).filter { seen.insert($0.name.lowercased()).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func appBundles(in directory: URL) -> [URL] {
        let entries = contents(of: directory)
        let nested = entries.filter { !isAppBundle($0) && isDirectory($0) }.flatMap { contents(of: $0) }
        return (entries + nested).filter(isAppBundle)
    }

    private static func contents(of directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey],
                                                      options: .skipsHiddenFiles)) ?? []
    }

    private static func isAppBundle(_ url: URL) -> Bool { url.pathExtension == appExtension }

    private static func isDirectory(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    private static func app(at url: URL) -> InstalledApp? {
        guard isAppBundle(url) else { return nil }
        let name = url.deletingPathExtension().lastPathComponent
        return name.isEmpty ? nil : InstalledApp(name: name, url: url)
    }
}
