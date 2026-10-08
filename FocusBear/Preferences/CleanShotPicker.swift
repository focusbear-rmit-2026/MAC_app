//
//  CleanShotPicker.swift
//  Focus Bear
//
//  "Choose from CleanShot" for the Report-a-Problem form: a modal that lists the screenshots CleanShot
//  has saved, newest first, and lets one be attached without going through the file picker — the shots
//  live in ~/Library/Application Support/CleanShot/media/media_<random>/, one file per opaque folder,
//  which is unnavigable by hand (report 2026-09-16_20-10-43).
//
//  The chosen file joins the SAME `screenshots: [URL]` array the file picker, the drop zone and
//  "Paste from clipboard" all fill, so the upload, the thumbnails strip and the Send path are the
//  existing ones — this screen only decides WHICH url, never what happens to it.
//
//  Everything above the view layer is pure and injected (`root`, `fileManager`, `now`): the tests scan
//  a fixture tree in a temp directory and never touch the real CleanShot folder.
//

import SwiftUI
import AppKit
import ImageIO

// MARK: - A screenshot in the library

/// Where a shot's date came from. Recorded rather than inferred so the fallback chain is testable, and
/// so a future reader can tell a parsed date from a stat'ed one without re-deriving the rules.
enum CleanShotDateSource: String, Equatable {
    /// Parsed out of `CleanShot 2026-09-16 at 20.09.16.png`.
    case fileName
    /// The file's creation date, used when the name is not one CleanShot wrote.
    case fileMetadata
    /// Neither was available. The shot is still listed — it just sorts last.
    case unknown
}

/// One file in the CleanShot library.
struct CleanShotShot: Equatable, Identifiable {
    let url: URL
    let date: Date
    let dateSource: CleanShotDateSource
    /// False for CleanShot's own `.cleanshot` documents. They are zip archives of an editable
    /// composition, not an image: attaching one would upload something no viewer can open. Such a row
    /// is listed but disabled, never silently dropped — a shot the user can see in CleanShot and not
    /// here reads as a bug in this list.
    let isAttachable: Bool

    var id: String { url.path }
    /// The name without its extension — `CleanShot 2026-09-16 at 20.09.16`.
    var displayName: String { url.deletingPathExtension().lastPathComponent }
}

// MARK: - Reading the library

/// Finding CleanShot's screenshots and deciding what each one is.
enum CleanShotLibrary {
    static let applicationSupportFolder = "CleanShot"
    static let mediaFolder = "media"
    /// CleanShot's own editable document. A zip, not a picture — see `CleanShotShot.isAttachable`.
    static let editableExtension = "cleanshot"
    /// What the report form already accepts. Kept in step with `ReportProblemForm.imageExts`: a file
    /// this list admits but that one rejects would be attached here and dropped on paste/drop.
    static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "gif", "tiff", "bmp"]

    /// `CleanShot 2026-09-16 at 20.09.16` — note the DOTS in the time; a colon is not legal in a
    /// filename, so CleanShot substitutes them.
    static let fileNameDateFormat = "'CleanShot' yyyy-MM-dd 'at' HH.mm.ss"

    /// The real library, or nil when CleanShot is not installed / has never saved anything. Nil is what
    /// hides the button — no point offering a folder that does not exist.
    ///
    /// Resolved once per launch, because the caller is a SwiftUI view that is rebuilt on every
    /// keystroke in the feedback field and this would otherwise `stat` CleanShot's container each time.
    /// The cost of caching is that installing CleanShot mid-session does not light the button up until
    /// the next launch, which is a fair trade for a convenience affordance.
    static let defaultRoot: URL? = findDefaultRoot()

    private static func findDefaultRoot() -> URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                                     in: .userDomainMask).first else { return nil }
        let root = support.appendingPathComponent(applicationSupportFolder, isDirectory: true)
            .appendingPathComponent(mediaFolder, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue else { return nil }
        return root
    }

    /// The date encoded in a CleanShot filename, or nil for a name in any other shape.
    ///
    /// Fixed `en_US_POSIX` locale and the current time zone: the digits CleanShot writes are always
    /// Western Arabic and always local wall-clock time, so a Mac set to a Japanese calendar or an
    /// Arabic locale must not reinterpret them. `date(from:)` returns nil for anything that does not
    /// match the pattern exactly, which is what makes this safe to try first.
    static func date(fromFileName name: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = fileNameDateFormat
        return formatter.date(from: (name as NSString).deletingPathExtension)
    }

    /// One file's entry, or nil when the file is not something this list should show at all.
    ///
    /// **The filename is preferred over the file's creation date**, with the creation date as the
    /// fallback. The name is CleanShot's own record of when the shot was TAKEN; the creation date is
    /// the filesystem's record of when this copy appeared, and those part company the moment the
    /// library is synced, restored from a backup or copied to a new Mac — at which point the list would
    /// sort in an order that contradicts the names printed in its own rows.
    ///
    /// The usual objection to parsing names is that the parse might be wrong, but this one cannot be
    /// *quietly* wrong: the pattern either matches — and then it yields the very date the row
    /// displays — or it does not, and we fall straight through to metadata. (`DateFormatter` is lenient
    /// about which punctuation separates the time's numeric groups, so `20:09:16` parses as readily as
    /// `20.09.16`; both give the same instant, so the leniency costs nothing.) A file is never dropped
    /// for having a name this does not recognise.
    static func shot(at url: URL, creationDate: Date?) -> CleanShotShot? {
        let ext = url.pathExtension.lowercased()
        let isEditable = ext == editableExtension
        guard isEditable || imageExtensions.contains(ext) else { return nil }
        if let named = date(fromFileName: url.lastPathComponent) {
            return CleanShotShot(url: url, date: named, dateSource: .fileName, isAttachable: !isEditable)
        }
        if let created = creationDate {
            return CleanShotShot(url: url, date: created, dateSource: .fileMetadata, isAttachable: !isEditable)
        }
        return CleanShotShot(url: url, date: .distantPast, dateSource: .unknown, isAttachable: !isEditable)
    }

    /// Every shot under `root`, newest first.
    ///
    /// The library is ~240 opaque one-file folders, so this walks the tree rather than assuming the
    /// shape. `creationDateKey` is prefetched by the enumerator, which turns 230 separate `stat` calls
    /// into one pass — and the whole thing runs off the main thread (see `CleanShotPickerModel.load`).
    /// Empty folders exist in a real library; they simply contribute nothing.
    static func scan(root: URL, fileManager: FileManager = .default) -> [CleanShotShot] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .creationDateKey]
        guard let walker = fileManager.enumerator(at: root, includingPropertiesForKeys: keys,
                                                  options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        var found: [CleanShotShot] = []
        for case let url as URL in walker {
            let values = try? url.resourceValues(forKeys: Set(keys))
            guard values?.isRegularFile == true else { continue }
            guard let shot = shot(at: url, creationDate: values?.creationDate) else { continue }
            found.append(shot)
        }
        return sorted(found)
    }

    /// Newest first, with the path as the tie-break so the order is stable across scans rather than
    /// depending on the order the enumerator happened to walk the folders in.
    static func sorted(_ shots: [CleanShotShot]) -> [CleanShotShot] {
        shots.sorted { left, right in
            if left.date != right.date { return left.date > right.date }
            return left.url.path < right.url.path
        }
    }
}

// MARK: - The "already processed" log

/// Splitting and joining one CSV line, RFC 4180 style.
///
/// Home directories and screenshot names can legitimately contain a comma or a quote, and a field that
/// swallowed the rest of the line would silently mark the wrong file. Small enough to keep here rather
/// than take a dependency for one two-column file.
enum CleanShotCSV {
    static let separator: Character = ","
    static let quote: Character = "\""

    static func fields(in line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var isQuoted = false
        var index = line.startIndex
        while index < line.endIndex {
            let character = line[index]
            // Advanced up front, so every branch below is looking at the character AFTER this one and
            // no branch can forget to move on — an earlier version did, and hung the parser forever on
            // the first quoted field it met.
            index = line.index(after: index)
            if isQuoted {
                if character == quote {
                    // "" inside a quoted field is one literal quote.
                    if index < line.endIndex, line[index] == quote {
                        current.append(quote)
                        index = line.index(after: index)
                    } else {
                        isQuoted = false
                    }
                } else {
                    current.append(character)
                }
            } else if character == quote {
                isQuoted = true
            } else if character == separator {
                fields.append(current); current = ""
            } else {
                current.append(character)
            }
        }
        fields.append(current)
        return fields
    }

    static func line(from fields: [String]) -> String {
        fields.map(quoted).joined(separator: String(separator))
    }

    /// Always quoted. A path is user data; quoting it unconditionally means the writer has no rule that
    /// can be got wrong, and the reader above copes either way.
    private static func quoted(_ field: String) -> String {
        let escaped = field.replacingOccurrences(of: String(quote), with: "\(quote)\(quote)")
        return "\(quote)\(escaped)\(quote)"
    }
}

/// Which shots the user has ticked off, as it lives on disk.
///
/// **Keyed on the full path.** The filename alone is not unique — the library is 240 folders of
/// identically-shaped names — and the containing folder name (`media_H3iGnn7LLs`) means nothing on its
/// own. The path is stable for as long as CleanShot keeps the file where it put it; if CleanShot ever
/// moves one, its mark is lost and the shot reappears unticked, which is the harmless direction to
/// fail in for a convenience feature.
///
/// The timestamp is carried VERBATIM rather than parsed into a `Date`. Rewriting the file must never
/// destroy a value this version did not understand — a hand-edited note, or a format a later version
/// writes — and nothing in the app reads it back; it is there so the CSV means something when the user
/// opens it.
struct CleanShotProcessedLog: Equatable {
    static let empty = CleanShotProcessedLog(marks: [:])
    static let pathColumn = "path"
    static let markedAtColumn = "processed_at"
    static var header: String { CleanShotCSV.line(from: [pathColumn, markedAtColumn]) }

    /// path → the timestamp recorded for it.
    private(set) var marks: [String: String]

    func isProcessed(_ path: String) -> Bool { marks[path] != nil }

    mutating func mark(_ path: String, at date: Date) {
        marks[path] = Self.timestampFormatter.string(from: date)
    }

    mutating func unmark(_ path: String) { marks[path] = nil }

    /// Reads whatever is there, and never fails.
    ///
    /// A truncated write, a line the user edited by hand, a file that is not CSV at all: each bad line
    /// is skipped and the rest still counts. The worst outcome is "nothing is marked processed", which
    /// costs the user a few ticks — a picker that refused to open because its bookkeeping file was
    /// malformed would cost them the feature.
    static func parse(_ text: String) -> CleanShotProcessedLog {
        var marks: [String: String] = [:]
        for line in text.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
            let fields = CleanShotCSV.fields(in: String(line))
            guard let path = fields.first.map({ $0.trimmingCharacters(in: .whitespaces) }),
                  !path.isEmpty, path != pathColumn else { continue }
            marks[path] = fields.count > 1 ? fields[1] : ""
        }
        return CleanShotProcessedLog(marks: marks)
    }

    /// Sorted by path so a diff of the file is readable and two runs produce identical bytes.
    func serialised() -> String {
        let body = marks.keys.sorted().map { CleanShotCSV.line(from: [$0, marks[$0] ?? ""]) }
        return ([Self.header] + body).joined(separator: "\n") + "\n"
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }()
}

/// The log's home on disk.
///
/// The product owner asked for the CSV to live "in the folder", so it does: alongside the `media_*`
/// folders inside CleanShot's own Application Support container. That is another app's container, and
/// the risk is real — CleanShot may prune, sync or rewrite that tree, and an update could take the file
/// with it. It is recorded in the review notes; the failure is soft (marks are lost, the picker still
/// works), and keeping the state next to the screenshots is exactly what was asked for. The name is
/// deliberately ours so it cannot be mistaken for something CleanShot wrote.
enum CleanShotProcessedFile {
    static let fileName = "focusbear-processed.csv"

    static func url(in root: URL) -> URL { root.appendingPathComponent(fileName) }

    static func load(from root: URL) -> CleanShotProcessedLog {
        guard let text = try? String(contentsOf: url(in: root), encoding: .utf8) else { return .empty }
        return CleanShotProcessedLog.parse(text)
    }

    /// Atomic, so a crash mid-write leaves the previous file rather than half of a new one — the very
    /// corruption `parse` is written to survive is then something that essentially cannot happen to us.
    @discardableResult
    static func save(_ log: CleanShotProcessedLog, to root: URL) -> Bool {
        do {
            try log.serialised().write(to: url(in: root), atomically: true, encoding: .utf8)
            return true
        } catch {
            addLog(text: "CleanShot processed log save failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Loading a screenshot to look at

/// Decoding one screenshot big enough to actually recognise.
///
/// `NSImage(contentsOf:)` decodes the whole capture — a Retina screenshot is several million pixels —
/// and this app has beachballed from main-thread work more than once, so every decode here is
/// subsampled by `CGImageSourceCreateThumbnailAtIndex` and runs on a background queue. "Thumbnail" is
/// the API's name, not the size: `maximumPixelSize` is set large enough to fill a generous sheet on a
/// Retina display. That is the whole point of the carousel — the grid's 44pt rows were too small to
/// tell two screenshots apart, which is exactly what was reported.
enum CleanShotImageLoader {
    /// Enough to fill a large sheet at 2x without decoding the full capture. A bigger screenshot is
    /// subsampled down to this; a smaller one is decoded at its own size and never enlarged, because an
    /// upscaled screenshot is just a blurry one (see `ImagePreviewSizing.maximumScale`).
    static let maximumPixelSize = 2400
    static let cornerRadius: CGFloat = 4

    /// Bounded on purpose. Each decoded image can be tens of megabytes and the carousel only ever wants
    /// the current shot and its immediate neighbours; `NSCache` also drops its contents under memory
    /// pressure.
    private static let cache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 8
        return cache
    }()

    /// Decodes off the main thread and answers on it. A file that cannot be read as an image — a
    /// `.cleanshot` zip, a shot deleted since the scan — answers nil, and the caller shows a
    /// placeholder rather than an empty frame.
    static func load(_ url: URL, completion: @escaping (NSImage?) -> Void) {
        if let cached = cache.object(forKey: url.path as NSString) { completion(cached); return }
        DispatchQueue.global(qos: .userInitiated).async {
            let image = make(url)
            if let image = image { cache.setObject(image, forKey: url.path as NSString) }
            DispatchQueue.main.async { completion(image) }
        }
    }

    /// Warms the cache without wanting the result — used for the shots either side of the current one,
    /// so stepping through does not wait on a decode each time. At `.utility` so it cannot compete with
    /// the decode the user is actually waiting for.
    static func prefetch(_ url: URL) {
        guard cache.object(forKey: url.path as NSString) == nil else { return }
        DispatchQueue.global(qos: .utility).async {
            guard let image = make(url) else { return }
            cache.setObject(image, forKey: url.path as NSString)
        }
    }

    /// The decoded image, sized in pixels.
    ///
    /// Its size is the DECODED size, not the original capture's. That under-reports for a screenshot
    /// larger than `maximumPixelSize` — harmless here, because the sheet's picture box is always far
    /// smaller than 2400pt, so the box decides the fit in every real case.
    static func make(_ url: URL) -> NSImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
    }
}

// MARK: - Strings

/// Overridable from `config.json` under `cleanShotPicker`, exactly like `LocalReportStatusStrings`:
/// the English ships in code so the picker works before any config arrives, and a translation can
/// replace any key without an app release.
struct CleanShotPickerStrings {
    /// Built once. `init` reads and parses `config.json` off disk, and the view holding these is
    /// rebuilt on every keystroke in the report form's text editor.
    static let shared = CleanShotPickerStrings()

    static let defaults = [
        "title": "Choose from CleanShot",
        "chooseFromCleanShot": "Choose from CleanShot",
        // Its neighbour on the report form. Brought in here because this change moves that line into a
        // row with the CleanShot button, and leaving one of the pair hardcoded while its twin is
        // translatable is the sort of split that never gets tidied up later.
        "pasteFromClipboard": "Paste from clipboard",
        "hideProcessed": "Hide processed",
        "processed": "Processed",
        "markProcessed": "Mark as processed, and show the next one",
        "loading": "Reading your CleanShot folder…",
        "empty": "No screenshots in your CleanShot folder yet.",
        // Reworded for the carousel: "Hide processed" now starts ticked, so an empty screen needs to
        // name the filter causing it and point at the tick that undoes it.
        "allProcessed": "Every screenshot is marked processed. Untick “Hide processed” to see them again.",
        "notAnImage": "CleanShot document — open it in CleanShot and export an image first.",
        "previewUnavailable": "This screenshot couldn't be opened.",
        "markFailed": "Couldn't save the processed list. Your marks may not stick.",
        "position": "<INDEX> of <COUNT>",
        "previous": "Previous screenshot (←)",
        "next": "Next screenshot (→)",
        "attach": "Attach",
        "cancel": "Cancel",
    ]
    let values: [String: String]

    init() {
        var values = Self.defaults
        let resource = BundledConfigLanguage.current()
        if let url = Bundle.main.url(forResource: resource, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let bundled = config["cleanShotPicker"] as? [String: String] { values.merge(bundled) { _, new in new } }
        if let remote = configjson["cleanShotPicker"] as? [String: String] { values.merge(remote) { _, new in new } }
        self.values = values
    }

    subscript(_ key: String) -> String { values[key] ?? Self.defaults[key] ?? "" }
}

// MARK: - Model

/// What the modal shows, and the two jobs it does: scan the folder, and keep the processed log.
@available(macOS 11.0, *)
final class CleanShotPickerModel: ObservableObject {
    @Published private(set) var shots: [CleanShotShot] = []
    @Published private(set) var isLoading = true
    @Published private(set) var log: CleanShotProcessedLog = .empty
    @Published private(set) var didFailToSave = false
    /// **On** by default, as asked: the point of ticking shots off is not to be shown them again. The
    /// risk of defaulting a filter on is an empty screen that reads as breakage, so the carousel says
    /// in as many words when everything is hidden because it is all processed, and the tick that
    /// reverses it is on the same row.
    @Published var hidesProcessed = true {
        didSet { repairSelection() }
    }

    /// Which shot the carousel is showing, by id rather than by index.
    ///
    /// An index into `visibleShots` would be a bug waiting to happen: the list is filtered, and it
    /// changes under the selection every time a shot is marked processed. An id survives that, and
    /// `repairSelection` is the one place that decides what to do when it no longer resolves.
    @Published private(set) var currentID: String?

    private let root: URL
    private let now: () -> Date

    init(root: URL, now: @escaping () -> Date = Date.init) {
        self.root = root
        self.now = now
    }

    /// The whole of the disk work — 236 folders and a CSV — on a background queue. The modal paints its
    /// spinner immediately and fills in when this lands.
    func load() {
        isLoading = true
        let root = self.root
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let found = CleanShotLibrary.scan(root: root)
            let log = CleanShotProcessedFile.load(from: root)
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.shots = found
                self.log = log
                self.isLoading = false
                self.repairSelection()
            }
        }
    }

    var visibleShots: [CleanShotShot] {
        guard hidesProcessed else { return shots }
        return shots.filter { !log.isProcessed($0.id) }
    }

    func isProcessed(_ shot: CleanShotShot) -> Bool { log.isProcessed(shot.id) }

    // MARK: Where the carousel is

    var currentIndex: Int? { visibleShots.firstIndex { $0.id == currentID } }
    var current: CleanShotShot? { currentIndex.map { visibleShots[$0] } }
    /// 1-based, for "7 of 42". Nil when there is nothing to show.
    var currentPosition: Int? { currentIndex.map { $0 + 1 } }

    var canGoPrevious: Bool { (currentIndex ?? 0) > 0 }
    var canGoNext: Bool {
        guard let index = currentIndex else { return false }
        return index + 1 < visibleShots.count
    }

    func goPrevious() { step(by: -1) }
    func goNext() { step(by: 1) }

    private func step(by offset: Int) {
        guard let index = currentIndex else { return }
        let target = index + offset
        guard visibleShots.indices.contains(target) else { return }
        currentID = visibleShots[target].id
    }

    func show(_ shot: CleanShotShot) { currentID = shot.id }

    /// Puts the selection back on something real. Called whenever the visible list changes underneath
    /// it — a finished scan, the filter being toggled, a shot being marked. Keeps the current shot if
    /// it is still visible, otherwise takes whatever now sits at `preferredIndex` (the slot the old one
    /// vacated), and falls back to the first shot.
    private func repairSelection(preferredIndex: Int? = nil) {
        let list = visibleShots
        guard !list.isEmpty else { currentID = nil; return }
        if let currentID = currentID, list.contains(where: { $0.id == currentID }) { return }
        let index = min(max(preferredIndex ?? 0, 0), list.count - 1)
        currentID = list[index].id
    }

    // MARK: Marking

    /// Marking is a toggle — the same tick unmarks a shot ticked by mistake.
    func toggleProcessed(_ shot: CleanShotShot) {
        var updated = log
        if updated.isProcessed(shot.id) { updated.unmark(shot.id) } else { updated.mark(shot.id, at: now()) }
        log = updated
        // The tick moves whether or not the file can be written — the state the user just expressed is
        // never rolled back under them — and a failed write says so instead of going quiet.
        didFailToSave = !CleanShotProcessedFile.save(updated, to: root)
    }

    /// Tick the shot on screen, and move on.
    ///
    /// **Marking advances; unmarking stays put.** Ticking means "done with this one", and making the
    /// user then press → every single time is the whole reason a carousel could feel worse than a grid.
    /// Unticking means "that was a mistake", where jumping away would hide the correction being made.
    ///
    /// At the end of the list there is nowhere to advance to, so it stays on the last shot — and when
    /// the filter is on, the marked shot vanishes and the slot it left is taken by the one after it,
    /// which is the same movement by another route.
    func toggleProcessedOnCurrent() {
        guard let shot = current, let index = currentIndex else { return }
        let wasProcessed = isProcessed(shot)
        toggleProcessed(shot)
        guard !wasProcessed else { repairSelection(preferredIndex: index); return }
        if visibleShots.contains(where: { $0.id == shot.id }) {
            // Still listed (the filter is off), so advancing is an explicit step.
            currentID = visibleShots[min(index + 1, visibleShots.count - 1)].id
        } else {
            // Filtered away: whatever now occupies that slot is the next shot.
            currentID = nil
            repairSelection(preferredIndex: index)
        }
    }
}

// MARK: - The modal

/// One screenshot at a time, as large as the sheet allows.
///
/// It started as a grid of 44pt thumbnails, which was the wrong shape for the job: "the images are too
/// small… carousel style UI would be better where it shows one image at a time very large". Telling two
/// screenshots apart is the entire task, and a thumbnail cannot do it.
///
/// Navigation is by ← and → as well as the buttons, Return attaches the shot on screen and Escape
/// closes. A carousel that answered only to clicking small arrows would be a worse grid.
@available(macOS 11.0, *)
struct CleanShotPickerSheet: View {
    /// Owned here, not handed in: SwiftUI re-runs a `.sheet`'s content closure when the presenting view
    /// changes, and a model built in that closure would be replaced mid-use — throwing away the scan
    /// and the marks with it. `StateObject` builds it exactly once for the life of the sheet.
    @StateObject private var model: CleanShotPickerModel
    let strings: CleanShotPickerStrings
    /// The chosen file, handed to the host to put in the very same `screenshots` array the file picker
    /// and the paste button fill.
    let onChoose: (URL) -> Void
    let onClose: () -> Void

    init(root: URL, strings: CleanShotPickerStrings, onChoose: @escaping (URL) -> Void,
         onClose: @escaping () -> Void) {
        _model = StateObject(wrappedValue: CleanShotPickerModel(root: root))
        self.strings = strings
        self.onChoose = onChoose
        self.onClose = onClose
    }

    private static let padding: CGFloat = 16
    private static let spacing: CGFloat = 10
    private static let controlSpacing: CGFloat = 12
    private static let titleRowHeight: CGFloat = 20
    private static let captionRowHeight: CGFloat = 34
    private static let footerRowHeight: CGFloat = 28
    private static let dividerHeight: CGFloat = 1
    private static let captionFontSize: CGFloat = 12
    private static let detailFontSize: CGFloat = 11
    private static let arrowGlyphSize: CGFloat = 15

    /// Everything in the sheet that is NOT the picture: the title row, the caption, the footer, the two
    /// dividers, the spacing between the five, and the padding around the lot. Derived from the same
    /// metrics the layout uses so the two cannot drift apart. Internal so a test can assert the sheet
    /// actually reserves it — chrome pushed off the edge is a bug this app has shipped before.
    static var chromeHeight: CGFloat {
        padding * 2 + titleRowHeight + captionRowHeight + footerRowHeight
            + dividerHeight * 2 + spacing * 4
    }

    /// The screen the sheet appears on. `NSScreen.main` is nil in a headless/unit context, so fall back
    /// to the widest attached screen before resorting to the minimum — the old square fallback is what
    /// produced a uselessly narrow sheet elsewhere in this app.
    static var availableScreen: CGSize {
        NSScreen.main?.visibleFrame.size
            ?? NSScreen.screens.map(\.visibleFrame.size).max(by: { $0.width < $1.width })
            ?? CGSize(width: ImagePreviewSizing.minimumSide, height: ImagePreviewSizing.minimumSide)
    }

    /// An EXACT size, never a minimum plus an ideal. `NSHostingController` turns a SwiftUI `minHeight`
    /// into a REQUIRED constraint and an `idealHeight` into a low-priority preference, so a view asking
    /// for `minHeight: 320, idealHeight: 700` is presented 320 points tall with its chrome hanging off
    /// the edges — measured on this app's own sheets more than once. `ImagePreviewSizing.sheetSize` is
    /// the shared answer to that, and this screen uses it rather than a constant of its own: a fixed
    /// 520×460 was the other half of "the images are too small".
    static var preferredSheetSize: CGSize {
        ImagePreviewSizing.sheetSize(available: availableScreen, chromeHeight: chromeHeight)
    }

    /// What is left for the picture once the chrome has taken its share.
    private var pictureBox: CGSize {
        ImagePreviewSizing.documentBox(available: Self.availableScreen, chromeHeight: Self.chromeHeight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Self.spacing) {
            titleRow
            Divider()
            picture
            caption
            Divider()
            footer
        }
        .padding(Self.padding)
        .frame(width: Self.preferredSheetSize.width, height: Self.preferredSheetSize.height)
        .onAppear { model.load() }
        // Decoded only for the shots either side of the one on screen, and only once it changes — so
        // stepping through is smooth without ever decoding the whole library.
        .onChange(of: model.currentID) { _ in prefetchNeighbours() }
    }

    private var titleRow: some View {
        HStack(spacing: Self.controlSpacing) {
            Text(strings["title"]).font(.headline)
            Spacer(minLength: 0)
            // With only one shot visible there is no other way to tell where you are or how much is
            // left — a scrollbar used to say that implicitly.
            if let position = model.currentPosition {
                Text(positionLabel(position, of: model.visibleShots.count))
                    .font(.system(size: Self.detailFontSize)).foregroundColor(.secondary)
            }
        }
        .frame(height: Self.titleRowHeight)
    }

    /// `<INDEX> of <COUNT>`, filled in the way the rest of this app's config strings are.
    private func positionLabel(_ index: Int, of count: Int) -> String {
        strings["position"]
            .replacingOccurrences(of: "<INDEX>", with: "\(index)")
            .replacingOccurrences(of: "<COUNT>", with: "\(count)")
    }

    @ViewBuilder
    private var picture: some View {
        if model.isLoading {
            centred { HStack(spacing: 8) { ProgressView().scaleEffect(0.5); Text(strings["loading"]) } }
        } else if model.shots.isEmpty {
            centred { Text(strings["empty"]) }
        } else if let shot = model.current {
            // `.id` belongs HERE, not inside that view: SwiftUI ties a child's `@State` to its identity
            // in the PARENT's hierarchy, so a modifier applied inside the child's own body would not
            // reset it — and the previous screenshot would sit under the new caption.
            CleanShotLargeImageView(shot: shot, box: pictureBox, strings: strings)
                .id(shot.id)
                .frame(width: pictureBox.width, height: pictureBox.height)
        } else {
            // Everything is filtered away. Say why, rather than showing an empty frame that reads as a
            // broken screen — this is the risk of having "Hide processed" ticked by default.
            centred { Text(strings["allProcessed"]) }
        }
    }

    private func centred<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack {
            Spacer()
            content().font(.system(size: Self.captionFontSize)).foregroundColor(.secondary)
            Spacer()
        }
        .frame(width: pictureBox.width, height: pictureBox.height)
    }

    @ViewBuilder
    private var caption: some View {
        HStack(spacing: Self.controlSpacing) {
            if let shot = model.current {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: shot.displayName)
                        .font(.system(size: Self.captionFontSize, weight: .semibold)).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(shot.date, style: .date)
                        Text(shot.date, style: .time)
                        if !shot.isAttachable { Text(strings["notAnImage"]).lineLimit(1) }
                    }
                    .font(.system(size: Self.detailFontSize)).foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
                Toggle(isOn: Binding(get: { model.isProcessed(shot) },
                                     set: { _ in model.toggleProcessedOnCurrent() })) {
                    Text(strings["processed"]).font(.system(size: Self.detailFontSize))
                }
                .toggleStyle(CheckboxToggleStyle())
                .help(strings["markProcessed"])
            } else {
                Spacer(minLength: 0)
            }
        }
        .frame(height: Self.captionRowHeight)
    }

    private var footer: some View {
        HStack(spacing: Self.controlSpacing) {
            arrow(symbol: "chevron.left", label: strings["previous"], key: .leftArrow,
                  enabled: model.canGoPrevious, action: model.goPrevious)
            arrow(symbol: "chevron.right", label: strings["next"], key: .rightArrow,
                  enabled: model.canGoNext, action: model.goNext)
            Toggle(isOn: $model.hidesProcessed) {
                Text(strings["hideProcessed"]).font(.system(size: Self.detailFontSize))
            }
            .toggleStyle(CheckboxToggleStyle())
            if model.didFailToSave {
                Text(strings["markFailed"])
                    .font(.system(size: Self.detailFontSize)).foregroundColor(.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
            SwiftUI.Button(action: onClose) { Text(strings["cancel"]) }
                .keyboardShortcut(.cancelAction)
            SwiftUI.Button(action: chooseCurrent) { Text(strings["attach"]) }
                .keyboardShortcut(.defaultAction)
                .disabled(model.current?.isAttachable != true)
        }
        .frame(height: Self.footerRowHeight)
    }

    /// A step button that is also the keyboard shortcut, so the two can never disagree about when
    /// stepping is allowed.
    private func arrow(symbol: String, label: String, key: KeyEquivalent, enabled: Bool,
                       action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            Image(systemName: symbol).font(.system(size: Self.arrowGlyphSize))
        }
        .buttonStyle(PlainButtonStyle())
        .pointingHandCursor()
        .keyboardShortcut(key, modifiers: [])
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .help(label)
        .accessibilityLabel(Text(label))
    }

    private func chooseCurrent() {
        guard let shot = model.current, shot.isAttachable else { return }
        onChoose(shot.url)
        onClose()
    }

    /// One either side, no further. Enough that stepping feels immediate; not so much that opening the
    /// sheet decodes a library.
    private func prefetchNeighbours() {
        guard let index = model.currentIndex else { return }
        for neighbour in [index - 1, index + 1] where model.visibleShots.indices.contains(neighbour) {
            let shot = model.visibleShots[neighbour]
            guard shot.isAttachable else { continue }
            CleanShotImageLoader.prefetch(shot.url)
        }
    }
}

/// The screenshot itself, fitted to the space the sheet has for it.
///
/// Keyed by the shot's id so SwiftUI rebuilds it — and re-runs its load — when the carousel moves,
/// rather than leaving the previous picture on screen under a new caption.
@available(macOS 11.0, *)
struct CleanShotLargeImageView: View {
    let shot: CleanShotShot
    let box: CGSize
    let strings: CleanShotPickerStrings

    @SwiftUI.State private var image: NSImage?
    @SwiftUI.State private var didFail = false

    var body: some View {
        Group {
            if let image = image {
                // Fitted whole, not filled: the job is recognising which screenshot this is, and a
                // cropped picture defeats that.
                let size = ImagePreviewSizing.fit(image: image.size, within: box)
                Image(nsImage: image)
                    .resizable()
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(CleanShotImageLoader.cornerRadius)
                    .accessibilityLabel(Text(verbatim: shot.displayName))
            } else if didFail || !shot.isAttachable {
                // A `.cleanshot` has no image to show. It is still listed — hiding it would mean a shot
                // the user can see in CleanShot is missing here — so it gets an explanation instead.
                placeholder(shot.isAttachable ? strings["previewUnavailable"] : strings["notAnImage"])
            } else {
                ProgressView()
            }
        }
        .frame(width: box.width, height: box.height)
        .onAppear(perform: load)
    }

    private func placeholder(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "doc").font(.system(size: 28)).foregroundColor(.secondary)
            Text(message).font(.system(size: 12)).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func load() {
        guard image == nil, !didFail, shot.isAttachable else { return }
        CleanShotImageLoader.load(shot.url) { loaded in
            guard let loaded = loaded else { didFail = true; return }
            image = loaded
        }
    }
}
