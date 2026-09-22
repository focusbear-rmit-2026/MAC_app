//
//  CleanShotPickerTests.swift
//  Focus BearTests
//
//  The pure half of "Choose from CleanShot": which files are listed, where each one's date comes from,
//  the order they end up in, and the processed-log CSV surviving whatever is in the file.
//
//  Every test builds its own library in a temp directory. Nothing here reads the real
//  ~/Library/Application Support/CleanShot — a test that did would pass or fail depending on what the
//  developer happened to have screenshotted that morning.
//

import XCTest
@testable import Focus_Bear

final class CleanShotPickerTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("cleanshot-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
        root = nil
        try super.tearDownWithError()
    }

    /// One `media_<random>/<name>` file, the shape CleanShot actually writes.
    @discardableResult
    private func makeShot(_ name: String, folder: String = UUID().uuidString) throws -> URL {
        let directory = root.appendingPathComponent("media_\(folder)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data("not really a png".utf8).write(to: url)
        return url
    }

    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: iso)!
    }

    // MARK: - Date extraction

    func testParsesTheDateOutOfACleanShotFileName() {
        let parsed = CleanShotLibrary.date(fromFileName: "CleanShot 2026-09-16 at 20.09.16.png")
        XCTAssertEqual(parsed, date("2026-09-16 20:09:16"))
    }

    /// The time uses dots, because a colon is not legal in a filename. `DateFormatter` turns out to be
    /// lenient about which punctuation separates the numeric groups, so the colon spelling parses too —
    /// to the very same instant. Pinned here because it is the behaviour, not the behaviour I first
    /// assumed: the leniency is harmless (the date is identical either way), and a test asserting the
    /// stricter rule would be asserting something the framework does not promise.
    func testTheTimeSeparatorIsMatchedLeniently() {
        let dotted = CleanShotLibrary.date(fromFileName: "CleanShot 2026-09-16 at 20.09.16.png")
        XCTAssertEqual(dotted, date("2026-09-16 20:09:16"))
        XCTAssertEqual(CleanShotLibrary.date(fromFileName: "CleanShot 2026-09-16 at 20:09:16.png"), dotted)
    }

    func testRejectsNamesThatAreNotCleanShots() {
        XCTAssertNil(CleanShotLibrary.date(fromFileName: "Screenshot 2026-09-16 at 20.09.16.png"))
        XCTAssertNil(CleanShotLibrary.date(fromFileName: "holiday.png"))
        XCTAssertNil(CleanShotLibrary.date(fromFileName: ""))
        // A duplicate suffix is the realistic near-miss: still a CleanShot, still must be listed.
        XCTAssertNil(CleanShotLibrary.date(fromFileName: "CleanShot 2026-09-16 at 20.09.16 (1).png"))
    }

    func testPrefersTheFileNameOverTheCreationDate() throws {
        let url = try makeShot("CleanShot 2026-09-16 at 20.09.16.png")
        let shot = CleanShotLibrary.shot(at: url, creationDate: date("2020-01-01 00:00:00"))
        XCTAssertEqual(shot?.date, date("2026-09-16 20:09:16"))
        XCTAssertEqual(shot?.dateSource, .fileName)
    }

    func testFallsBackToTheCreationDateWhenTheNameIsUnparseable() throws {
        let created = date("2026-05-04 09:30:00")
        let url = try makeShot("renamed-by-hand.png")
        let shot = CleanShotLibrary.shot(at: url, creationDate: created)
        XCTAssertEqual(shot?.date, created)
        XCTAssertEqual(shot?.dateSource, .fileMetadata)
    }

    /// Neither source available must still produce a row. Dropping the file would hide a screenshot the
    /// user can plainly see in CleanShot.
    func testKeepsAShotWithNoUsableDateAtAll() throws {
        let url = try makeShot("renamed-by-hand.png")
        let shot = CleanShotLibrary.shot(at: url, creationDate: nil)
        XCTAssertEqual(shot?.dateSource, .unknown)
        XCTAssertEqual(shot?.date, .distantPast)
        XCTAssertEqual(shot?.isAttachable, true)
    }

    // MARK: - What counts as a shot

    func testCleanShotDocumentsAreListedButNotAttachable() throws {
        let url = try makeShot("CleanShot 2026-09-16 at 13.19.41.cleanshot")
        let shot = CleanShotLibrary.shot(at: url, creationDate: nil)
        XCTAssertNotNil(shot, "a .cleanshot must appear in the list rather than vanish from it")
        XCTAssertEqual(shot?.isAttachable, false)
        XCTAssertEqual(shot?.dateSource, .fileName)
    }

    func testIgnoresFilesThatAreNotImagesAtAll() throws {
        let url = try makeShot("focusbear-processed.csv")
        XCTAssertNil(CleanShotLibrary.shot(at: url, creationDate: nil))
    }

    func testExtensionMatchingIsCaseInsensitive() throws {
        let url = try makeShot("CleanShot 2026-09-16 at 20.09.16.PNG")
        XCTAssertEqual(CleanShotLibrary.shot(at: url, creationDate: nil)?.isAttachable, true)
    }

    // MARK: - Scanning

    func testScanWalksTheOpaqueFoldersAndSortsNewestFirst() throws {
        try makeShot("CleanShot 2026-09-14 at 08.00.00.png", folder: "aaa")
        try makeShot("CleanShot 2026-09-16 at 20.09.16.png", folder: "bbb")
        try makeShot("CleanShot 2026-09-15 at 12.00.00.png", folder: "ccc")

        let shots = CleanShotLibrary.scan(root: root)

        XCTAssertEqual(shots.map(\.displayName), ["CleanShot 2026-09-16 at 20.09.16",
                                                  "CleanShot 2026-09-15 at 12.00.00",
                                                  "CleanShot 2026-09-14 at 08.00.00"])
    }

    /// A real library has empty `media_*` folders, and the CSV this feature writes sits among them.
    /// Neither may appear as a screenshot.
    func testScanSkipsEmptyFoldersAndItsOwnLog() throws {
        try FileManager.default.createDirectory(at: root.appendingPathComponent("media_empty"),
                                                withIntermediateDirectories: true)
        try Data("path,processed_at\n".utf8).write(to: CleanShotProcessedFile.url(in: root))
        try makeShot("CleanShot 2026-09-16 at 20.09.16.png")

        XCTAssertEqual(CleanShotLibrary.scan(root: root).count, 1)
    }

    func testScanOfAMissingFolderIsEmptyRatherThanAFailure() {
        XCTAssertTrue(CleanShotLibrary.scan(root: root.appendingPathComponent("nope")).isEmpty)
    }

    /// Two shots with the same timestamp must not swap places between scans.
    func testSortIsStableForIdenticalDates() {
        let stamp = date("2026-09-16 20:09:16")
        let make: (String) -> CleanShotShot = { path in
            CleanShotShot(url: URL(fileURLWithPath: path), date: stamp, dateSource: .fileName,
                          isAttachable: true)
        }
        let sorted = CleanShotLibrary.sorted([make("/b.png"), make("/a.png")])
        XCTAssertEqual(sorted.map { $0.url.path }, ["/a.png", "/b.png"])
    }

    /// Shots with no date sort last rather than jumping to the top of the list.
    func testUndatedShotsSortLast() {
        let dated = CleanShotShot(url: URL(fileURLWithPath: "/dated.png"), date: date("2020-01-01 00:00:00"),
                                  dateSource: .fileMetadata, isAttachable: true)
        let undated = CleanShotShot(url: URL(fileURLWithPath: "/undated.png"), date: .distantPast,
                                    dateSource: .unknown, isAttachable: true)
        XCTAssertEqual(CleanShotLibrary.sorted([undated, dated]).map { $0.url.path },
                       ["/dated.png", "/undated.png"])
    }

    // MARK: - The processed log

    func testMarkingRoundTripsThroughTheFile() {
        var log = CleanShotProcessedLog.empty
        log.mark("/Users/someone/CleanShot 2026-09-16 at 20.09.16.png", at: date("2026-09-16 20:15:00"))
        XCTAssertTrue(CleanShotProcessedFile.save(log, to: root))

        let reloaded = CleanShotProcessedFile.load(from: root)
        XCTAssertTrue(reloaded.isProcessed("/Users/someone/CleanShot 2026-09-16 at 20.09.16.png"))
        XCTAssertFalse(reloaded.isProcessed("/Users/someone/other.png"))
    }

    func testUnmarkingRemovesTheRow() {
        var log = CleanShotProcessedLog.empty
        log.mark("/a.png", at: Date())
        log.unmark("/a.png")
        CleanShotProcessedFile.save(log, to: root)
        XCTAssertFalse(CleanShotProcessedFile.load(from: root).isProcessed("/a.png"))
    }

    /// Paths are keyed in full, because the names collide: the library is hundreds of folders of
    /// identically-shaped filenames.
    func testMarksAreKeyedOnTheFullPathNotTheFileName() {
        var log = CleanShotProcessedLog.empty
        let name = "CleanShot 2026-09-16 at 20.09.16.png"
        log.mark("/media_aaa/\(name)", at: Date())
        XCTAssertTrue(log.isProcessed("/media_aaa/\(name)"))
        XCTAssertFalse(log.isProcessed("/media_bbb/\(name)"),
                       "the same filename in another folder is a different screenshot")
    }

    /// A comma or a quote in the path must survive the trip, or the wrong file gets marked.
    func testAwkwardPathsSurviveTheCSV() {
        var log = CleanShotProcessedLog.empty
        let awkward = #"/Users/a,b/My "best" shots/CleanShot 2026-09-16 at 20.09.16.png"#
        log.mark(awkward, at: Date())
        XCTAssertTrue(CleanShotProcessedLog.parse(log.serialised()).isProcessed(awkward))
    }

    func testTheHeaderRowIsNotReadBackAsAPath() {
        let log = CleanShotProcessedLog.parse(CleanShotProcessedLog.header + "\n")
        XCTAssertTrue(log.marks.isEmpty)
    }

    /// The whole point of the tolerance: a half-written or hand-mangled file degrades to "nothing is
    /// marked", or to whatever lines still make sense — it never throws and never blocks the picker.
    func testAMalformedFileDegradesInsteadOfFailing() throws {
        let rubbish = """
        path,processed_at
        \"/good.png\",2026-09-16T20:15:00+10:00

        ,2026-09-16T20:15:00+10:00
        \"/truncated.png
        not,csv,at,all,really
        """
        try Data(rubbish.utf8).write(to: CleanShotProcessedFile.url(in: root))

        let log = CleanShotProcessedFile.load(from: root)

        XCTAssertTrue(log.isProcessed("/good.png"), "a readable line still counts")
        XCTAssertFalse(log.isProcessed(""), "a row with no path is dropped, not stored under an empty key")
        XCTAssertFalse(log.isProcessed("/missing.png"))
    }

    func testAFileThatIsNotCSVAtAllReadsAsNothingMarked() throws {
        try Data([0xFF, 0xFE, 0x00, 0x01]).write(to: CleanShotProcessedFile.url(in: root))
        XCTAssertTrue(CleanShotProcessedFile.load(from: root).marks.isEmpty)
    }

    func testAMissingFileReadsAsNothingMarked() {
        XCTAssertTrue(CleanShotProcessedFile.load(from: root).marks.isEmpty)
    }

    /// A timestamp this version cannot read must not be destroyed by the next save.
    func testAnUnrecognisedTimestampIsPreservedVerbatim() {
        let log = CleanShotProcessedLog.parse("\"/a.png\",sometime last Tuesday\n")
        XCTAssertTrue(log.serialised().contains("sometime last Tuesday"))
    }

    func testSerialisationIsDeterministic() {
        var log = CleanShotProcessedLog.empty
        log.mark("/b.png", at: date("2026-09-16 20:15:00"))
        log.mark("/a.png", at: date("2026-09-16 20:15:00"))
        XCTAssertEqual(log.serialised(), CleanShotProcessedLog.parse(log.serialised()).serialised())
        XCTAssertTrue(log.serialised().hasPrefix(CleanShotProcessedLog.header))
    }

    // MARK: - CSV primitives

    func testCSVFieldSplitting() {
        XCTAssertEqual(CleanShotCSV.fields(in: "a,b"), ["a", "b"])
        XCTAssertEqual(CleanShotCSV.fields(in: "\"a,b\",c"), ["a,b", "c"])
        XCTAssertEqual(CleanShotCSV.fields(in: "\"a\"\"b\",c"), ["a\"b", "c"])
        XCTAssertEqual(CleanShotCSV.fields(in: ""), [""])
        XCTAssertEqual(CleanShotCSV.fields(in: ","), ["", ""])
    }

    /// A quote that is never closed must still terminate. The first draft of the splitter advanced its
    /// index only inside some branches, so the very first quoted field — and this file is written with
    /// every field quoted — spun forever and hung the test host. A timeout would be too slow to be
    /// useful here; the assertion simply cannot be reached if the parser does not return.
    func testUnterminatedQuoteTerminates() {
        XCTAssertEqual(CleanShotCSV.fields(in: "\"/truncated.png"), ["/truncated.png"])
        XCTAssertEqual(CleanShotCSV.fields(in: "\""), [""])
        XCTAssertEqual(CleanShotCSV.fields(in: "\"\""), [""])
    }

    // MARK: - Model behaviour

    /// Builds a library of `names` and runs the scan to completion.
    ///
    /// The scan is deliberately off the main thread, so this spins the run loop until it lands rather
    /// than sleeping for a guessed interval.
    @available(macOS 11.0, *)
    private func loadedModel(_ names: [String], hidingProcessed: Bool? = nil) throws -> CleanShotPickerModel {
        for (index, name) in names.enumerated() { try makeShot(name, folder: "f\(index)") }
        let marked = date("2026-09-16 20:15:00")
        let model = CleanShotPickerModel(root: root, now: { marked })
        if let hiding = hidingProcessed { model.hidesProcessed = hiding }
        model.load()
        let deadline = Date().addingTimeInterval(5)
        while model.isLoading, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }
        XCTAssertFalse(model.isLoading, "the background scan never reported back")
        return model
    }

    private static let threeShots = ["CleanShot 2026-09-16 at 20.09.16.png",   // newest — index 0
                                     "CleanShot 2026-09-15 at 12.00.00.png",
                                     "CleanShot 2026-09-14 at 08.00.00.png"]   // oldest — index 2

    /// The default the report asked for. It has to be pinned: it is the one setting where getting it
    /// wrong shows the user an empty screen on first open.
    @available(macOS 11.0, *)
    func testHideProcessedIsOnByDefault() throws {
        XCTAssertTrue(CleanShotPickerModel(root: root).hidesProcessed)
    }

    @available(macOS 11.0, *)
    func testTheCarouselStartsOnTheNewestShot() throws {
        let model = try loadedModel(Self.threeShots)
        XCTAssertEqual(model.current?.displayName, "CleanShot 2026-09-16 at 20.09.16")
        XCTAssertEqual(model.currentPosition, 1)
        XCTAssertEqual(model.visibleShots.count, 3)
    }

    @available(macOS 11.0, *)
    func testSteppingForwardsAndBackwardsStopsAtTheEnds() throws {
        let model = try loadedModel(Self.threeShots)

        XCTAssertFalse(model.canGoPrevious, "nothing sits before the first shot")
        model.goPrevious()
        XCTAssertEqual(model.currentPosition, 1, "stepping back from the first must not wrap")

        model.goNext(); model.goNext()
        XCTAssertEqual(model.currentPosition, 3)
        XCTAssertFalse(model.canGoNext)
        model.goNext()
        XCTAssertEqual(model.currentPosition, 3, "stepping past the last must not wrap")

        model.goPrevious()
        XCTAssertEqual(model.currentPosition, 2)
    }

    /// Ticking means "done with this one" — staying put would make the user press → every single time.
    @available(macOS 11.0, *)
    func testMarkingProcessedAdvancesToTheNextShot() throws {
        let model = try loadedModel(Self.threeShots, hidingProcessed: false)
        let first = try XCTUnwrap(model.current)

        model.toggleProcessedOnCurrent()

        XCTAssertTrue(model.isProcessed(first))
        XCTAssertEqual(model.currentPosition, 2, "the carousel should have moved on")
        XCTAssertFalse(model.didFailToSave)
    }

    /// With the filter on, the marked shot disappears and the slot it vacated holds the next one — the
    /// same movement by another route, and the position must not run off the end.
    @available(macOS 11.0, *)
    func testMarkingWhileHidingProcessedLandsOnTheFollowingShot() throws {
        let model = try loadedModel(Self.threeShots, hidingProcessed: true)
        let first = try XCTUnwrap(model.current)

        model.toggleProcessedOnCurrent()

        XCTAssertEqual(model.visibleShots.count, 2)
        XCTAssertFalse(model.visibleShots.contains { $0.id == first.id })
        XCTAssertEqual(model.current?.displayName, "CleanShot 2026-09-15 at 12.00.00")
        XCTAssertEqual(model.currentPosition, 1)
    }

    /// Unticking is a correction, so it stays where it is — jumping away would hide the fix being made.
    @available(macOS 11.0, *)
    func testUnmarkingStaysOnTheSameShot() throws {
        let model = try loadedModel(Self.threeShots, hidingProcessed: false)
        model.goNext()
        let second = try XCTUnwrap(model.current)
        model.toggleProcessed(second)
        XCTAssertTrue(model.isProcessed(second))

        model.toggleProcessedOnCurrent()

        XCTAssertFalse(model.isProcessed(second))
        XCTAssertEqual(model.current?.id, second.id, "unmarking must not advance")
    }

    /// Marking the LAST shot has nowhere to advance to. It must stay on something real rather than
    /// leaving the carousel pointing past the end.
    @available(macOS 11.0, *)
    func testMarkingTheLastShotStaysOnAValidShot() throws {
        let model = try loadedModel(Self.threeShots, hidingProcessed: false)
        model.goNext(); model.goNext()
        XCTAssertEqual(model.currentPosition, 3)

        model.toggleProcessedOnCurrent()

        XCTAssertEqual(model.currentPosition, 3)
        XCTAssertNotNil(model.current)
    }

    /// Everything hidden must leave nothing selected, so the sheet shows its explanation rather than a
    /// stale picture — and unticking the filter must bring the carousel straight back.
    @available(macOS 11.0, *)
    func testHidingEveryShotEmptiesTheCarouselAndUntickingRestoresIt() throws {
        let model = try loadedModel(Self.threeShots, hidingProcessed: false)
        for shot in model.shots { model.toggleProcessed(shot) }

        model.hidesProcessed = true

        XCTAssertTrue(model.visibleShots.isEmpty)
        XCTAssertNil(model.current)
        XCTAssertNil(model.currentPosition)

        model.hidesProcessed = false

        XCTAssertEqual(model.visibleShots.count, 3)
        XCTAssertNotNil(model.current, "unticking must put the carousel back on something")
    }

    /// A `.cleanshot` is still listed — hiding it would mean a shot visible in CleanShot is missing
    /// here — and the carousel must be willing to sit on one without offering to attach it.
    @available(macOS 11.0, *)
    func testTheCarouselShowsCleanShotDocumentsButTheyAreNotAttachable() throws {
        let model = try loadedModel(["CleanShot 2026-09-16 at 13.19.41.cleanshot"])
        XCTAssertEqual(model.visibleShots.count, 1)
        XCTAssertEqual(model.current?.isAttachable, false)
    }

    @available(macOS 11.0, *)
    func testAnEmptyLibraryHasNothingSelected() throws {
        let model = try loadedModel([])
        XCTAssertTrue(model.visibleShots.isEmpty)
        XCTAssertNil(model.current)
        XCTAssertNil(model.currentPosition)
        XCTAssertFalse(model.canGoNext)
        XCTAssertFalse(model.canGoPrevious)
    }

    // MARK: - Sheet sizing

    /// The sheet must always keep room for its own chrome, on a laptop screen and on a big display
    /// alike. A sheet that handed its whole height to the picture pushed its header and footer off the
    /// edges on this app's other preview sheets, so the invariant is pinned here rather than eyeballed.
    @available(macOS 11.0, *)
    func testTheSheetAlwaysReservesRoomForItsChrome() {
        let chrome = CleanShotPickerSheet.chromeHeight
        XCTAssertGreaterThan(chrome, 0)

        let screens = [CGSize(width: 1440, height: 900),    // laptop
                       CGSize(width: 3440, height: 1440),   // ultrawide
                       CGSize(width: 1280, height: 800),
                       CGSize(width: 800, height: 600)]     // small / scaled down
        for screen in screens {
            let picture = ImagePreviewSizing.documentBox(available: screen, chromeHeight: chrome)
            let sheet = ImagePreviewSizing.sheetSize(available: screen, chromeHeight: chrome)

            XCTAssertGreaterThan(picture.height, 0, "no room left for the picture on \(screen)")
            XCTAssertGreaterThan(picture.width, 0, "no room left for the picture on \(screen)")
            XCTAssertEqual(sheet.height, picture.height + chrome, accuracy: 0.5,
                           "the sheet must be exactly picture + chrome on \(screen)")
            XCTAssertGreaterThanOrEqual(sheet.width, ImagePreviewSizing.minimumSide,
                                        "the sheet got narrower than it can be dismissed at on \(screen)")
        }
    }

    /// The whole complaint was that the images were too small, so the picture must actually scale with
    /// the screen rather than sitting at some fixed constant.
    @available(macOS 11.0, *)
    func testABiggerScreenGivesABiggerPicture() {
        let chrome = CleanShotPickerSheet.chromeHeight
        let small = ImagePreviewSizing.documentBox(available: CGSize(width: 1280, height: 800),
                                                   chromeHeight: chrome)
        let large = ImagePreviewSizing.documentBox(available: CGSize(width: 2560, height: 1440),
                                                   chromeHeight: chrome)
        XCTAssertGreaterThan(large.width, small.width)
        XCTAssertGreaterThan(large.height, small.height)
    }

    // MARK: - Strings

    /// Every string the modal shows must resolve to something, or part of it renders blank.
    func testEveryStringKeyResolves() {
        let strings = CleanShotPickerStrings.shared
        for key in CleanShotPickerStrings.defaults.keys {
            XCTAssertFalse(strings[key].isEmpty, "\(key) resolved to an empty string")
        }
    }

    /// "7 of 42" is the only thing telling the user where they are, and it is built by substituting
    /// these two placeholders. A translation that dropped one would silently lose half the message.
    func testThePositionStringCarriesBothPlaceholders() {
        let position = CleanShotPickerStrings.shared["position"]
        XCTAssertTrue(position.contains("<INDEX>"), "position lost its <INDEX> placeholder")
        XCTAssertTrue(position.contains("<COUNT>"), "position lost its <COUNT> placeholder")
    }
}
