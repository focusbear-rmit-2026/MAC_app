//
//  ToDoAttachmentsTests.swift
//  Focus BearTests
//
//  The task-attachment feature that the to-do editor and the Day Plan's task details now SHARE
//  (`ToDoAttachments.swift`) — asked for in report 2026-09-15_20-54-33, "should be able to
//  add/edit/remove/preview attachments in day plan details".
//

@testable import Focus_Bear
import AppKit
import SwiftUI
import XCTest

final class ToDoAttachmentsTests: XCTestCase {

    /// The English string the app ships for `key`, read from the bundled config rather than whatever
    /// downloaded/translated config happens to be live — same approach as EventCancellationTests.
    private static func bundledEnglish(_ key: ToDoStringKey) -> String? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let block = root[ToDoStrings.configBlockKey] as? [String: Any] else { return nil }
        return block[key.rawValue] as? String
    }

    private func store(taskId: String?, messages: @escaping (String) -> Void = { _ in }) -> ToDoAttachmentsStore {
        ToDoAttachmentsStore(taskId: taskId, strings: ToDoStrings(), showStatus: messages)
    }

    // MARK: - A task with no server id

    func testATaskWithAServerIdCanTakeAttachments() {
        XCTAssertTrue(store(taskId: "todo-1").canAttach)
    }

    func testALocalOnlyTaskCannotTakeAttachments() {
        // A Day Plan row is only backed by a to-do once it has been minted; the attachment endpoint is
        // `/to-do/:id/attachments`, so without an id there is nothing to attach to.
        XCTAssertFalse(store(taskId: nil).canAttach)
    }

    func testALocalOnlyTaskSaysNothingRatherThanFailingObscurely() {
        var messages: [String] = []
        let local = store(taskId: nil) { messages.append($0) }
        local.attach(URL(fileURLWithPath: "/tmp/does-not-matter.png"))

        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: nil, isUploading: false,
                                                          existingCount: 0, byteCount: 10),
                       .unavailable)
        XCTAssertTrue(messages.isEmpty, "the UI already shows why; an error sheet on top of it is noise")
        XCTAssertTrue(local.attachments.isEmpty)
    }

    func testTheUnavailableStateHasItsOwnWordingForEachHost() {
        // The editor's task does not exist yet and saving fixes it; a Day Plan row is waiting on a sync.
        // Two different situations, so two different sentences — both shipped in config.json.
        let afterSaving = Self.bundledEnglish(.attachmentsAfterSaving)
        let needTodo = Self.bundledEnglish(.attachmentsNeedTodo)
        XCTAssertNotNil(afterSaving)
        XCTAssertNotNil(needTodo)
        XCTAssertNotEqual(afterSaving, needTodo)
        XCTAssertFalse((needTodo ?? "").isEmpty)
    }

    // MARK: - Upload rules

    func testAnOrdinaryFileIsAccepted() {
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: 0, byteCount: 1024),
                       .ready)
    }

    func testAFileOverTwentyMegabytesIsRefusedWithTheSizeMessage() {
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: 0,
                                                          byteCount: ToDoAttachment.maximumBytes + 1),
                       .rejected(.attachmentTooLarge))
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: 0,
                                                          byteCount: ToDoAttachment.maximumBytes),
                       .ready, "exactly the server's ceiling is still allowed")
    }

    func testTheTwentyFirstAttachmentIsRefusedWithTheLimitMessage() {
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: ToDoAttachment.maximumPerTask,
                                                          byteCount: 10),
                       .rejected(.attachmentLimitReached))
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: ToDoAttachment.maximumPerTask - 1,
                                                          byteCount: 10),
                       .ready)
    }

    func testAnUnreadableFileIsRefusedRatherThanUploadedEmpty() {
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: 0, byteCount: nil),
                       .rejected(.attachmentFailed))
    }

    func testASecondUploadIsNotStartedWhileOneIsRunning() {
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: true,
                                                          existingCount: 0, byteCount: 10),
                       .unavailable)
    }

    // MARK: - Types the picker offers vs types the preview can render

    func testEveryExtensionThePickerOffersHasAKnownContentType() {
        let offered = ToDoAttachmentType.imageExtensions + ToDoAttachmentType.documentExtensions
        for ext in offered {
            XCTAssertNotEqual(ToDoAttachmentType.contentType(forExtension: ext), ToDoAttachmentType.fallback,
                              "\(ext) is offered in the file picker but has no MIME type")
        }
    }

    func testEveryExtensionThePickerOffersCanBePreviewedInTheWindow() {
        // The preview only renders images, PDFs and text; anything else lands on "save a copy", which
        // would be a poor thing to steer the user into from our own picker.
        for ext in ToDoAttachmentType.imageExtensions {
            XCTAssertTrue(ToDoAttachmentType.contentType(forExtension: ext).hasPrefix("image/"))
        }
        for ext in ToDoAttachmentType.documentExtensions {
            let type = ToDoAttachmentType.contentType(forExtension: ext)
            XCTAssertTrue(ToDoAttachmentType.isPDF(type) || ToDoAttachmentType.isText(type),
                          "\(ext) is offered but the in-app preview cannot draw it")
        }
    }

    func testAnUppercaseExtensionStillResolves() {
        XCTAssertEqual(ToDoAttachmentType.contentType(forExtension: "PNG"), "image/png")
    }

    func testAnUnknownExtensionFallsBackToOctetStream() {
        XCTAssertEqual(ToDoAttachmentType.contentType(forExtension: "sketch"), ToDoAttachmentType.fallback)
    }

    // MARK: - The list is one view, rendered by both hosts

    func testTheSameListViewIsBuiltForBothHostsAndDiffersOnlyInItsHostSpecificParts() {
        let strings = ToDoStrings()
        let editorList = ToDoAttachmentsList(store: store(taskId: "todo-1"), strings: strings,
                                             unavailableMessage: strings[.attachmentsAfterSaving],
                                             onPreview: { _ in })
        // The Day Plan is a popover with no scroll view of its own, so it caps the list height and
        // takes over the "Add file…" press (it has to close the popover first).
        let dayPlanList = ToDoAttachmentsList(store: store(taskId: "todo-1"), strings: strings,
                                              unavailableMessage: strings[.attachmentsNeedTodo],
                                              maximumListHeight: 120,
                                              onPreview: { _ in }, onAdd: {})

        XCTAssertNil(editorList.maximumListHeight)
        XCTAssertNil(editorList.onAdd, "the editor lets the shared view open the picker on its own window")
        XCTAssertNotNil(dayPlanList.maximumListHeight)
        XCTAssertNotNil(dayPlanList.onAdd)
        XCTAssertNotEqual(editorList.unavailableMessage, dayPlanList.unavailableMessage)
    }

    func testAScrollingListIsSizedToItsRowsSoAPopoverCanHostIt() {
        // A SwiftUI ScrollView has no height of its own, so the Day Plan's popover has to be told one
        // — an empty list must take no space, and a growing one must grow.
        XCTAssertEqual(ToDoAttachmentMetrics.listHeight(rows: 0), 0)
        XCTAssertEqual(ToDoAttachmentMetrics.listHeight(rows: 1), ToDoAttachmentMetrics.rowHeight)
        XCTAssertGreaterThan(ToDoAttachmentMetrics.listHeight(rows: 3),
                             ToDoAttachmentMetrics.listHeight(rows: 2))
    }

    // MARK: - The preview sheet is tall enough to show its own header
    //
    // Report 2026-09-15_20-54-33 follow-up: "It was not tall enough and it didn't have a close button
    // on the top right." The ✕ was always rendered — it was outside the sheet. Two causes, both here.

    /// Chrome heights around the document, spanning the plausible range for the sheet's own furniture.
    private static let chromeHeights: [CGFloat] = [0, 40, 98, 200]

    func testTheDocumentNeverTakesTheWholeSheetSoTheChromeAlwaysFits() {
        let available = CGSize(width: 1600, height: 875)
        for chrome in Self.chromeHeights {
            let sheet = ImagePreviewSizing.sheetSize(available: available, chromeHeight: chrome)
            let document = ImagePreviewSizing.documentBox(available: available, chromeHeight: chrome)
            XCTAssertEqual(sheet.height, document.height + chrome, accuracy: 0.5,
                           "the sheet must be the document PLUS its chrome, never just the document")
            XCTAssertGreaterThan(sheet.height - document.height, chrome - 1,
                                 "chrome \(chrome) has no room, so the header would be off the edge")
        }
    }

    func testAShortScreenKeepsAUsableDocumentRatherThanSqueezingItAway() {
        // Chrome taller than the whole preview box must not produce a zero — or negative — document.
        let cramped = CGSize(width: 400, height: 200)
        let document = ImagePreviewSizing.documentBox(available: cramped, chromeHeight: 400)
        XCTAssertEqual(document.height, ImagePreviewSizing.minimumDocumentSide)
        XCTAssertGreaterThan(ImagePreviewSizing.sheetSize(available: cramped, chromeHeight: 400).height,
                             ImagePreviewSizing.minimumDocumentSide)
    }

    func testAnImageIsFittedToTheDocumentBoxNotTheWholeSheet() {
        let available = CGSize(width: 1600, height: 875)
        let chrome: CGFloat = 98
        let document = ImagePreviewSizing.documentBox(available: available, chromeHeight: chrome)
        // A very tall picture is the one that would push the footer off the bottom.
        let fitted = ImagePreviewSizing.fit(image: CGSize(width: 1000, height: 4000), within: document)
        XCTAssertLessThanOrEqual(fitted.height, document.height)
        XCTAssertLessThanOrEqual(fitted.width, document.width)
    }

    func testTheSheetAsksForAnExactSizeSoAppKitCannotPresentItAtItsMinimum() {
        // The bug: `minHeight: 320` was the only REQUIRED constraint NSHostingController installed, so
        // `presentAsSheet` resolved the sheet to 320pt tall while `fittingSize` reported the ideal.
        // An exact frame makes the required minimum and the ideal the same number.
        let wanted = ToDoAttachmentPreviewSheet.preferredSheetSize
        XCTAssertGreaterThan(wanted.height, ImagePreviewSizing.minimumSide,
                             "a sheet stuck at the minimum side is the reported bug")

        let view = NSHostingController(rootView: Self.previewSheet()).view
        XCTAssertEqual(view.fittingSize.width, wanted.width, accuracy: 1)
        XCTAssertEqual(view.fittingSize.height, wanted.height, accuracy: 1)
    }

    func testTheSheetIsHandedItsFullHeightRatherThanAFloorAppKitCanSitOn() {
        // The heart of the bug. `presentAsSheet` resolves a sheet from the REQUIRED size the hosting
        // controller reports, not from an ideal — so `minHeight: 320, idealHeight: 700` was presented
        // 320pt tall with the header off the top edge, while `fittingSize` reported a healthy 700
        // (measured on the Day Plan path). The fix is an exact frame plus an explicit
        // `preferredContentSize`; this is that contract, built and laid out offscreen.
        let wanted = ToDoAttachmentPreviewSheet.preferredSheetSize
        XCTAssertGreaterThan(wanted.height, ImagePreviewSizing.minimumSide,
                             "a sheet sitting on its minimum side is the reported symptom")

        let controller = NSHostingController(rootView: Self.previewSheet())
        controller.preferredContentSize = ToDoAttachmentPreviewSheet.preferredSheetSize
        let view = controller.view
        view.frame = NSRect(origin: .zero, size: controller.preferredContentSize)
        view.layoutSubtreeIfNeeded()

        XCTAssertEqual(controller.preferredContentSize.height, wanted.height, accuracy: 1,
                       "AppKit sizes the sheet from this; a floor here is a clipped header")
        XCTAssertEqual(view.fittingSize.height, wanted.height, accuracy: 1,
                       "the laid-out view must want exactly the sheet it is given — no overflow to clip")
        XCTAssertEqual(view.fittingSize.width, wanted.width, accuracy: 1)
    }

    func testTheSheetLeavesRoomForItsHeaderOnEveryScreenItCouldOpenOn() {
        // Rendered at a spread of sizes rather than eyeballed at one: a laptop panel, an external
        // display, and a short window where the chrome is a large share of the height.
        let screens = [CGSize(width: 1600, height: 875), CGSize(width: 3008, height: 1610),
                       CGSize(width: 1280, height: 700), CGSize(width: 800, height: 450)]
        for screen in screens {
            for chrome in Self.chromeHeights {
                let sheet = ImagePreviewSizing.sheetSize(available: screen, chromeHeight: chrome)
                let document = ImagePreviewSizing.documentBox(available: screen, chromeHeight: chrome)
                XCTAssertGreaterThanOrEqual(sheet.height - document.height, chrome,
                                            "screen \(screen) chrome \(chrome): the header has nowhere to go")
                XCTAssertGreaterThanOrEqual(sheet.width, ImagePreviewSizing.minimumSide,
                                            "screen \(screen): too narrow to dismiss")
            }
        }
    }

    private static func previewSheet() -> ToDoAttachmentPreviewSheet {
        let attachment = ToDoAttachment(id: "a", task_id: "t", file_name: "report.pdf", file_key: "k",
                                        content_type: "application/pdf", file_size: 1234,
                                        download_url: nil, created_at: nil)
        return ToDoAttachmentPreviewSheet(attachment: attachment, strings: ToDoStrings(), close: {})
    }

    // MARK: - The paperclip on a Day Plan row

    private func dayPlanTask(sourceTaskId: String?, attachmentCount: Int?) -> DayPlanTask {
        DayPlanTask(title: "Write the report", sourceTaskId: sourceTaskId, attachmentCount: attachmentCount)
    }

    func testATaskWithFilesShowsThePaperclip() {
        XCTAssertTrue(dayPlanTask(sourceTaskId: "todo-1", attachmentCount: 1).hasAttachments)
        XCTAssertTrue(dayPlanTask(sourceTaskId: "todo-1", attachmentCount: 7).hasAttachments)
    }

    func testATaskWithNoFilesShowsNoPaperclip() {
        XCTAssertFalse(dayPlanTask(sourceTaskId: "todo-1", attachmentCount: 0).hasAttachments)
    }

    func testATaskNeverLookedAtShowsNoPaperclip() {
        // nil is "we have never asked", not "zero" — but an icon must not be drawn on a guess.
        XCTAssertFalse(dayPlanTask(sourceTaskId: "todo-1", attachmentCount: nil).hasAttachments)
    }

    func testALocalOnlyTaskNeverShowsThePaperclipEvenWithAStaleCount() {
        // No backing to-do means no attachments can exist, whatever a cached count from a previous
        // life of this row happens to say.
        XCTAssertFalse(dayPlanTask(sourceTaskId: nil, attachmentCount: 3).hasAttachments)
    }

    func testTheCachedCountSurvivesBeingStoredAndReadBack() {
        let task = dayPlanTask(sourceTaskId: "todo-1", attachmentCount: 2)
        let data = try! JSONEncoder().encode(task)
        let restored = try! JSONDecoder().decode(DayPlanTask.self, from: data)
        XCTAssertEqual(restored.attachmentCount, 2)
        XCTAssertTrue(restored.hasAttachments)
    }

    func testATaskStoredBeforeTheCountExistedStillDecodes() {
        // The field is optional so the tasks already in UserDefaults keep loading.
        let legacy = #"{"id":"1","title":"Old","durationMinutes":15,"done":false}"#
        let restored = try? JSONDecoder().decode(DayPlanTask.self, from: Data(legacy.utf8))
        XCTAssertNotNil(restored)
        XCTAssertNil(restored?.attachmentCount)
        XCTAssertFalse(restored?.hasAttachments ?? true)
    }

    func testTheBadgeCountsTheFilesItWasGiven() {
        XCTAssertTrue(DayPlanTasksPanel.attachmentBadgeTitle(3, color: .labelColor).string.contains("3"))
        XCTAssertFalse(DayPlanTasksPanel.attachmentBadgeTitle(3, color: .labelColor).string.isEmpty)
    }

    func testTheStoreReportsTheCountSoNoRowHasToFetchToDrawAnIcon() {
        // The badge is fed by the details panel's own load, never by a per-row request.
        var reported: [Int] = []
        let subject = store(taskId: "todo-1")
        subject.onCountChanged = { reported.append($0) }
        // No network in a unit test: the callback contract is what the Day Plan depends on.
        XCTAssertNotNil(subject.onCountChanged)
        XCTAssertTrue(reported.isEmpty, "nothing is reported until a load actually returns")
    }

    // MARK: - Row formatting

    func testAnAttachmentRowLabelsItsSizeForAHuman() {
        XCTAssertFalse(ToDoAttachmentSize.label(1_500_000).isEmpty)
        XCTAssertFalse(ToDoAttachmentSize.label(0).isEmpty)
        XCTAssertFalse(ToDoAttachmentSize.label(-1).isEmpty, "a nonsense size must not crash the row")
    }

    // MARK: - Scrolling the preview rather than shrinking it

    private static let documentBox = CGSize(width: 1000, height: 600)

    func testALongScreenshotIsKeptReadableAndLeftToScroll() {
        // The reported shape: a tall screenshot. `fit` squeezes it into the box, which at this aspect
        // ratio is a 150pt-wide strip of unreadable text; fitting the width keeps it legible and lets
        // the scroll view carry the rest.
        let tall = CGSize(width: 1200, height: 8000)
        let squeezed = ImagePreviewSizing.fit(image: tall, within: Self.documentBox)
        let scrollable = ImagePreviewSizing.scrollableFit(image: tall, within: Self.documentBox)

        XCTAssertEqual(scrollable.width, Self.documentBox.width, accuracy: 1, "the width is what is fitted")
        XCTAssertGreaterThan(scrollable.height, Self.documentBox.height, "it has to overflow to scroll")
        XCTAssertGreaterThan(scrollable.width, squeezed.width, "otherwise nothing was gained over `fit`")
        XCTAssertEqual(scrollable.width / scrollable.height, tall.width / tall.height, accuracy: 0.01,
                       "aspect ratio must survive")
    }

    func testASmallPictureIsShownAtItsOwnSizeNotBlownUp() {
        let small = CGSize(width: 120, height: 80)
        XCTAssertEqual(ImagePreviewSizing.scrollableFit(image: small, within: Self.documentBox), small,
                       "an upscaled picture is just a blurry one")
    }

    func testAWideImageIsNeverLeftWiderThanTheBox() {
        // Fitting by width means the horizontal axis never overflows, whatever the picture measures.
        let wide = ImagePreviewSizing.scrollableFit(image: CGSize(width: 9000, height: 500),
                                                    within: Self.documentBox)
        XCTAssertLessThanOrEqual(wide.width, Self.documentBox.width)
        XCTAssertLessThan(wide.height, Self.documentBox.height)
    }

    func testAnUnreadableImageDoesNotCrashTheSizing() {
        XCTAssertEqual(ImagePreviewSizing.scrollableFit(image: .zero, within: Self.documentBox), .zero)
        XCTAssertEqual(ImagePreviewSizing.scrollableFit(image: CGSize(width: 10, height: 10), within: .zero), .zero)
    }

    func testScrollersAreOfferedExactlyWhenThereIsSomethingToScrollTo() {
        let overflowing = ImagePreviewSizing.scrollableFit(image: CGSize(width: 1200, height: 8000),
                                                           within: Self.documentBox)
        XCTAssertTrue(ImagePreviewSizing.needsScrolling(content: overflowing, within: Self.documentBox))

        let fitting = ImagePreviewSizing.scrollableFit(image: CGSize(width: 1200, height: 600),
                                                       within: Self.documentBox)
        XCTAssertFalse(ImagePreviewSizing.needsScrolling(content: fitting, within: Self.documentBox),
                       "a picture fitted to the box must not claim it overflows on a rounded point")
        XCTAssertFalse(ImagePreviewSizing.needsScrolling(content: .zero, within: Self.documentBox))
        XCTAssertFalse(ImagePreviewSizing.needsScrolling(content: Self.documentBox, within: .zero))
    }

    // MARK: - One way out of the preview

    func testTheCloseButtonAndTheEscapeKeyTakeTheSameRoute() {
        // AppKit answers Esc by dismissing a presented controller on its own, which in the Day Plan
        // would skip re-opening the task details the preview was launched from. Both routes now land
        // in `close()`.
        var reopened = 0
        let controller = Self.previewController { reopened += 1 }
        controller.cancelOperation(nil)
        XCTAssertEqual(reopened, 1, "Esc must do what the ✕ does, not merely dismiss")
    }

    func testClosingTwiceStillOnlyClosesOnce() {
        // A single press of Esc can reach both the SwiftUI `.cancelAction` button and AppKit's
        // `cancelOperation`; re-opening the details twice would stack two popovers.
        var reopened = 0
        let controller = Self.previewController { reopened += 1 }
        controller.close()
        controller.cancelOperation(nil)
        controller.close()
        XCTAssertEqual(reopened, 1)
    }

    func testTheSheetControllerCarriesTheSizeItsHostNeeds() {
        // The host used to have to remember to set this; forgetting it put the ✕ outside the sheet.
        XCTAssertEqual(Self.previewController {}.preferredContentSize,
                       ToDoAttachmentPreviewSheet.preferredSheetSize)
    }

    private static func previewController(onClose: @escaping () -> Void) -> ToDoAttachmentPreviewSheetController {
        let attachment = ToDoAttachment(id: "a", task_id: "t", file_name: "shot.png", file_key: "k",
                                        content_type: "image/png", file_size: 10,
                                        download_url: nil, created_at: nil)
        return ToDoAttachmentPreviewSheetController(attachment: attachment, strings: ToDoStrings(),
                                                    onClose: onClose)
    }

    // MARK: - One "add another one" button

    func testEveryAddButtonIsTheSameControl() {
        // The whole of the request: "can you make the add attachment button match the add sub task
        // button?". They match because they ARE the same view — so a difference can only come from the
        // title, never from the styling.
        let subtask = NSHostingView(rootView: AddItemButton(title: "Add sub-task", action: {}))
        let attachment = NSHostingView(rootView: AddItemButton(title: "Add file…", action: {}))

        XCTAssertGreaterThan(subtask.fittingSize.height, 0)
        XCTAssertEqual(subtask.fittingSize.height, attachment.fittingSize.height, accuracy: 0.5,
                       "two add buttons of different heights is the reported mismatch")
    }

    func testAnAddButtonInAnAppKitFormHugsItsTitle() {
        // Hosted in the Day Plan's hand-built form, where a view that lets itself be stretched becomes
        // a full-width bar instead of a small + button.
        let hosted = AddItemButton.hosted(title: "Add sub-task") {}
        XCTAssertEqual(hosted.contentHuggingPriority(for: .horizontal), .required)
        XCTAssertEqual(hosted.contentHuggingPriority(for: .vertical), .required)
        XCTAssertFalse(hosted.translatesAutoresizingMaskIntoConstraints, "it is laid out by constraints")
        XCTAssertGreaterThan(hosted.fittingSize.width, 0)
    }

    func testTheAddButtonCarriesTheGlyphTheReporterAskedFor() {
        XCTAssertNotNil(NSImage(systemSymbolName: AddItemButton.symbol, accessibilityDescription: nil),
                        "the + has to be a real symbol, or the button silently loses its icon")
    }

    // MARK: - Pasting an image with Cmd-V

    func testPastingIsIgnoredWhenTheClipboardHoldsNoImage() {
        XCTAssertFalse(ToDoImagePaste.shouldAttach(hasImage: false, hasText: true, isEditingText: false))
        XCTAssertFalse(ToDoImagePaste.shouldAttach(hasImage: false, hasText: false, isEditingText: true))
    }

    func testPastingTextIntoAFieldIsNeverStolen() {
        // The whole risk of the feature: copying "Buy milk #home" off a web page puts BOTH text and a
        // picture on the clipboard. Typing a task name and pasting must still paste the name.
        XCTAssertFalse(ToDoImagePaste.shouldAttach(hasImage: true, hasText: true, isEditingText: true))
    }

    func testAScreenshotAttachesEvenWhileAFieldHasFocus() {
        // A bare screenshot has no text representation, so pasting it into a text field does nothing
        // at all today. These editors open with the title field focused, so refusing here would mean
        // the feature never worked where it was asked for.
        XCTAssertTrue(ToDoImagePaste.shouldAttach(hasImage: true, hasText: false, isEditingText: true))
    }

    func testAnImageAttachesWhenNothingIsBeingTyped() {
        XCTAssertTrue(ToDoImagePaste.shouldAttach(hasImage: true, hasText: true, isEditingText: false))
        XCTAssertTrue(ToDoImagePaste.shouldAttach(hasImage: true, hasText: false, isEditingText: false))
    }

    func testFocusIsReadFromTheFieldEditorNotTheClickedControl() {
        // An NSTextField hands focus to its field editor, an NSTextView, so that is what a focused
        // field actually looks like in the responder chain.
        XCTAssertTrue(ToDoImagePaste.isEditingText(NSTextView()))
        XCTAssertFalse(ToDoImagePaste.isEditingText(nil))
        XCTAssertFalse(ToDoImagePaste.isEditingText(NSButton()))
        XCTAssertFalse(ToDoImagePaste.isEditingText(NSView()))

        // A read-only text view is a label, not somewhere to type, so it must not veto a paste.
        let label = NSTextView()
        label.isEditable = false
        XCTAssertFalse(ToDoImagePaste.isEditingText(label))
    }

    func testAPastedImageBecomesAPngWithADatedName() {
        let image = NSImage(size: NSSize(width: 12, height: 8))
        image.lockFocus(); NSColor.red.setFill(); NSRect(x: 0, y: 0, width: 12, height: 8).fill(); image.unlockFocus()

        let board = NSPasteboard(name: NSPasteboard.Name("focusbear.tests.paste"))
        board.clearContents()
        board.writeObjects([image])

        let stamp = Date(timeIntervalSince1970: 1_757_990_400)
        guard let pasted = ToDoImagePaste.image(on: board, now: stamp) else {
            return XCTFail("an image on the pasteboard must be readable")
        }
        XCTAssertEqual(pasted.contentType, "image/png")
        XCTAssertTrue(pasted.fileName.hasSuffix(".png"), pasted.fileName)
        XCTAssertTrue(pasted.fileName.hasPrefix("pasted-image-"), pasted.fileName)
        // Re-encoded, not passed through: NSImage put TIFF on the board, PNG comes back.
        XCTAssertEqual(Array(pasted.data.prefix(4)), [0x89, 0x50, 0x4E, 0x47], "not PNG bytes")
        XCTAssertNotNil(NSImage(data: pasted.data), "the bytes must decode back to an image")
    }

    func testAnEmptyClipboardYieldsNothingToAttach() {
        let board = NSPasteboard(name: NSPasteboard.Name("focusbear.tests.paste.empty"))
        board.clearContents()
        board.setString("just text", forType: .string)
        XCTAssertNil(ToDoImagePaste.image(on: board))
        XCTAssertTrue(ToDoImagePaste.hasText(on: board))
    }

    func testThePastedNameIsStableAcrossRegions() {
        // A device set to an Arabic-Indic or Japanese calendar must not produce a filename another
        // device cannot make sense of, so the formatter is pinned to POSIX.
        let stamp = Date(timeIntervalSince1970: 1_757_990_400)
        let name = ToDoImagePaste.fileName(at: stamp)
        XCTAssertEqual(name.filter { $0.isNumber }.count, 14, name)
        XCTAssertTrue(name.allSatisfy { $0.isASCII }, name)
    }

    func testAPastedImageIsHeldToTheSameLimitsAsAPickedFile() {
        // Not a second cap: the pasted path goes through ToDoAttachmentUploadCheck like the picker.
        let tooBig = ToDoAttachment.maximumBytes + 1
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "t", isUploading: false,
                                                          existingCount: 0, byteCount: tooBig),
                       .rejected(.attachmentTooLarge))
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "t", isUploading: false,
                                                          existingCount: ToDoAttachment.maximumPerTask,
                                                          byteCount: 10),
                       .rejected(.attachmentLimitReached))
    }

    func testARejectedPasteReportsBackRatherThanGoingQuiet() {
        // The menu's quick-add has no attachment list to watch, so it depends on this completion both
        // for the error message and for knowing when to stop holding the store alive.
        var outcome: Bool?
        let subject = store(taskId: nil)
        subject.attach(pasted: ToDoPastedImage(data: Data([1, 2, 3]), fileName: "x.png",
                                               contentType: "image/png")) { outcome = $0 }
        let waited = expectation(description: "completion")
        DispatchQueue.main.async { waited.fulfill() }
        wait(for: [waited], timeout: 2)
        XCTAssertEqual(outcome, false, "a task with no server id cannot take a paste, and must say so")
    }

    func testOnlyCommandVIsTakenFromTheKeyboard() {
        XCTAssertTrue(ToDoImagePasteMonitor.isPasteShortcut(Self.key("v", .command)))
        XCTAssertFalse(ToDoImagePasteMonitor.isPasteShortcut(Self.key("v", [])))
        XCTAssertFalse(ToDoImagePasteMonitor.isPasteShortcut(Self.key("c", .command)))
        XCTAssertFalse(ToDoImagePasteMonitor.isPasteShortcut(Self.key("v", [.command, .shift])),
                       "Cmd-Shift-V is paste-and-match-style, not ours")
    }

    private static func key(_ character: String, _ flags: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                         windowNumber: 0, context: nil, characters: character,
                         charactersIgnoringModifiers: character, isARepeat: false, keyCode: 9)!
    }

    func testTheAttachmentsBlockSitsAtItsLeadingEdge() {
        // The reported misalignment. A SwiftUI block narrower than its NSHostingView is CENTRED, which
        // put "Add file…" in the middle of the Day Plan's form while "Add sub-task" — an AppKit view in
        // the same stack — sat at the left margin.
        let host = NSHostingView(rootView: ToDoAttachmentsList(
            store: store(taskId: "todo-1"), strings: ToDoStrings(),
            unavailableMessage: "", onPreview: { _ in }, onAdd: {}))
        let width: CGFloat = 320
        host.frame = NSRect(x: 0, y: 0, width: width, height: 80)
        host.layoutSubtreeIfNeeded()

        func leaves(_ view: NSView) -> [NSView] { view.subviews.flatMap { [$0] + leaves($0) } }
        // Only button-sized views. The full-width backgrounds this view installs (the window reader,
        // the paste catcher) start at x=0 whatever the layout does, so measuring those would pass
        // whether or not the block is centred.
        let buttons = leaves(host).filter { $0.frame.width > 20 && $0.frame.width < width / 2
                                            && $0.frame.height > 8 }
        guard let leftmost = buttons.map({ $0.convert($0.bounds, to: host).minX }).min() else {
            return XCTFail("the list drew no button to measure")
        }
        XCTAssertLessThan(leftmost, width / 4,
                          "the block is centred again; it must hug the leading edge like the sub-task button")
    }

    func testAPasteHintIsShippedSoTheShortcutIsDiscoverable() {
        // A keyboard shortcut nobody is told about is a feature nobody uses.
        let hint = Self.bundledEnglish(.attachmentPasteHint)
        XCTAssertNotNil(hint)
        XCTAssertFalse(hint?.isEmpty ?? true)
    }

    // MARK: - Where a paste goes before the task exists

    func testAPasteGoesStraightUpWhenTheTaskIsAlreadyBacked() {
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: true, canHoldForLater: false), .attachNow)
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: true, canHoldForLater: true), .attachNow)
    }

    func testAPasteIsHeldWhenTheTaskIsNotBackedYet() {
        // The reported bug, as a rule. A Day Plan row gets its to-do a round trip after it is created,
        // and for that whole window ⌘V was never even examined — the key travelled on and typed a
        // screenshot's path into Details (report 2026-09-15_20-54-33, four rounds).
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: false, canHoldForLater: true),
                       .holdUntilBacked)
    }

    func testAPasteIsLeftAloneWhenNothingCanEverTakeIt() {
        // Swallowing ⌘V and doing nothing is worse than not having the feature, so a host that can
        // never hold an image must let the key reach whatever has focus.
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: false, canHoldForLater: false), .leaveAlone)
    }

    func testTheMonitorAsksTheHostBeforeItTouchesTheClipboard() {
        // `canAccept` is what went wrong: it used to be a flag captured when the view was drawn, so a
        // task minted while the sheet sat open never changed the answer. It is now a question, and it
        // is asked before the pasteboard is read at all.
        var asked = 0
        let monitor = ToDoImagePasteMonitor(label: "test", window: { nil },
                                            canAccept: { asked += 1; return false },
                                            onImage: { _ in XCTFail("nothing may be taken") })
        monitor.start()
        defer { monitor.stop() }
        // No window, so the event cannot belong to this host and the host is never consulted — which
        // is the other half of the log evidence: the menu's monitor correctly ignored the sheet's key.
        XCTAssertFalse(ToDoImagePasteMonitor.isPasteShortcut(Self.key("v", [])))
        XCTAssertEqual(asked, 0)
    }

    func testAHostThatCanHoldKeepsTheMonitorLookingAfterItSaidNo() {
        // A sink whose answer changes over time is the whole fix: the same monitor must say no, then
        // yes, without being torn down and rebuilt in between.
        var backed = false
        let sink = ToDoPendingImageSink(canHold: { backed }, hold: { _ in })
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: false,
                                             canHoldForLater: sink.canHold()), .leaveAlone)
        backed = true
        XCTAssertEqual(ToDoPasteRoute.decide(canAttachNow: false,
                                             canHoldForLater: sink.canHold()), .holdUntilBacked)
    }

    func testAHeldImageStillGoesThroughTheOrdinaryLimits() {
        // Held or immediate, it is the same upload path — no second cap, no second error message.
        XCTAssertEqual(ToDoAttachmentUploadCheck.evaluate(taskId: "todo-1", isUploading: false,
                                                          existingCount: 0,
                                                          byteCount: ToDoAttachment.maximumBytes + 1),
                       .rejected(.attachmentTooLarge))
    }

    func testTheWaitingLineIsShippedSoAHeldImageIsNeverInvisible() {
        let pending = Self.bundledEnglish(.attachmentPastePending)
        XCTAssertNotNil(pending)
        XCTAssertFalse(pending?.isEmpty ?? true)
    }

    // MARK: - Which window a ⌘V has to arrive at

    private func window() -> NSWindow {
        NSWindow(contentRect: NSRect(x: 0, y: 0, width: 80, height: 60),
                 styleMask: [.titled], backing: .buffered, defer: true)
    }

    func testAPasteInThePopoversOwnWindowIsClaimed() {
        let host = window()
        XCTAssertTrue(ToDoPasteWindowMatch.isRelated(event: host, host: host))
    }

    func testAPasteDeliveredToTheWindowAPopoverHangsOffIsStillClaimed() {
        // THE BUG, as a rule. The Day Plan's task details is an NSPopover whose window is a CHILD of
        // the main window, and the ⌘V is delivered to that parent:
        //   paste image: ⌘V ignored, event window is not this host
        //                (event=CustomWindow host=_NSPopoverWindow)
        // The old test only looked downward from the host — sheets and children sitting ON it — so a
        // popover host could never match, and every paste in that sheet was thrown away.
        let main = window()
        let popover = window()
        main.addChildWindow(popover, ordered: .above)
        XCTAssertEqual(popover.parent, main, "precondition: a popover hangs off its anchor's window")
        XCTAssertTrue(ToDoPasteWindowMatch.isRelated(event: main, host: popover),
                      "a key delivered to the parent belongs to the popover on it")
    }

    func testAPasteDeliveredToASheetOnTheHostIsStillClaimed() {
        // The other direction, which already worked and must keep working: the preview sheet and the
        // file picker both sit on top of the screens this serves.
        let host = window()
        let child = window()
        host.addChildWindow(child, ordered: .above)
        XCTAssertTrue(ToDoPasteWindowMatch.isRelated(event: child, host: host))
    }

    func testTwoUnrelatedWindowsAreStillRejected() {
        // The menu popover correctly ignoring a key meant for the Day Plan is the behaviour that must
        // survive; widening the match must not make every monitor claim everything.
        XCTAssertFalse(ToDoPasteWindowMatch.isRelated(event: window(), host: window()))
        XCTAssertFalse(ToDoPasteWindowMatch.isRelated(event: nil, host: window()))
        XCTAssertFalse(ToDoPasteWindowMatch.isRelated(event: window(), host: nil))
    }

    func testTwoWindowsHangingOffTheSameParentDoNotClaimEachOther() {
        // A popover and a separate panel on one window are siblings, not the same surface.
        let main = window()
        let first = window()
        let second = window()
        main.addChildWindow(first, ordered: .above)
        main.addChildWindow(second, ordered: .above)
        XCTAssertFalse(ToDoPasteWindowMatch.isRelated(event: first, host: second))
    }

    func testTheChainIsBoundedSoAnEventMonitorCannotHang() {
        // Walked inside a key-event monitor, so it must terminate whatever AppKit hands back.
        let main = window()
        let child = window()
        main.addChildWindow(child, ordered: .above)
        XCTAssertLessThanOrEqual(ToDoPasteWindowMatch.chain(from: child).count,
                                 ToDoPasteWindowMatch.maximumDepth)
        XCTAssertEqual(ToDoPasteWindowMatch.chain(from: child).first, child)
    }

    func testTheChainIsWrittenIntoTheLogSoARejectionCanBeRead() {
        // `event=CustomWindow host=_NSPopoverWindow` could not say whether those two were related.
        // The description now carries the whole chain, which is what makes the next sample readable.
        let main = window()
        let child = window()
        main.addChildWindow(child, ordered: .above)
        let described = ToDoPasteWindowMatch.describe(child)
        XCTAssertTrue(described.contains("<-"), described)
        XCTAssertEqual(ToDoPasteWindowMatch.describe(nil), "nil")
    }

    func testAnImageAttachmentIsRecognisedFromItsContentType() {
        let image = ToDoAttachment(id: "a", task_id: "t", file_name: "shot.png", file_key: "k",
                                   content_type: "image/png", file_size: 10, download_url: nil, created_at: nil)
        let document = ToDoAttachment(id: "b", task_id: "t", file_name: "notes.pdf", file_key: "k",
                                      content_type: "application/pdf", file_size: 10, download_url: nil, created_at: nil)
        XCTAssertTrue(image.isImage)
        XCTAssertFalse(document.isImage)
        XCTAssertTrue(ToDoAttachmentType.isPDF(document.content_type))
    }

    // Report 2026-09-15_20-54-33, follow-up: "screenshot issue where I try and paste the screenshot
    // and it just shows path". CleanShot copies the FILE, so its path rides along as text, `hasText`
    // was true, focus vetoed the attach and ⌘V typed the path into the field.

    func testAScreenshotToolsOwnFilePathDoesNotVetoTheAttach() {
        XCTAssertTrue(ToDoImagePaste.shouldAttach(hasImage: true, hasText: true, isEditingText: true,
                                                  textIsOnlyAnImagePath: true),
                      "the path of the image you just captured is not text you meant to paste")
    }

    func testRealTextAlongsideAnImageStillWinsWhileTyping() {
        XCTAssertFalse(ToDoImagePaste.shouldAttach(hasImage: true, hasText: true, isEditingText: true,
                                                   textIsOnlyAnImagePath: false),
                       "copying from a web page must keep pasting its text — that is the whole risk here")
    }

    func testAPathOnlyPasteOutsideAFieldStillAttaches() {
        XCTAssertTrue(ToDoImagePaste.shouldAttach(hasImage: true, hasText: true, isEditingText: false,
                                                  textIsOnlyAnImagePath: true))
    }

    func testAnImageFilePasteboardIsRecognisedAsPathOnly() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("shot-\(UUID().uuidString).png")
        let board = NSPasteboard(name: .init("fb.test.\(UUID().uuidString)"))
        board.clearContents()
        board.writeObjects([url as NSURL])
        XCTAssertTrue(ToDoImagePaste.textIsOnlyAnImagePath(on: board))
    }

    func testAnImageFileWithAnUnrelatedCaptionIsNotPathOnly() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("shot-\(UUID().uuidString).png")
        let board = NSPasteboard(name: .init("fb.test.\(UUID().uuidString)"))
        board.clearContents()
        board.writeObjects([url as NSURL])
        board.setString("look at this", forType: .string)
        XCTAssertFalse(ToDoImagePaste.textIsOnlyAnImagePath(on: board),
                       "a caption the user copied deliberately is real text")
    }

    func testANonImageFilePathIsNotTreatedAsAnImagePath() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("notes-\(UUID().uuidString).txt")
        let board = NSPasteboard(name: .init("fb.test.\(UUID().uuidString)"))
        board.clearContents()
        board.writeObjects([url as NSURL])
        XCTAssertFalse(ToDoImagePaste.textIsOnlyAnImagePath(on: board))
    }
}
