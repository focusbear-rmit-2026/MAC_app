import Cocoa
import SwiftUI

@objc protocol SearchableComboBoxDelegate: AnyObject {
    func itemSelectedByUser(comboBox: searchableComboBox)
    @objc optional func itemEditedByUser(comboBox: searchableComboBox)
    @objc optional func listSelectionChangedByUser(comboBox: searchableComboBox)
}

class searchableComboBox: NSComboBox, NSComboBoxCellDataSource, NSComboBoxDataSource, NSComboBoxDelegate {
    
    var items = [""]
    var filterdItems = [""]
    var menuShowByButton = true
    var customDelegate: SearchableComboBoxDelegate?

    // MARK: - Telling a choice from a blur
    //
    // An `NSComboBox` sends its action when editing ends for *any* reason, so the action alone
    // cannot say whether the user chose something or simply clicked away from part-typed text —
    // which is the whole difference a `.whenResolved` caller cares about. These three answer it, and
    // nothing reads them unless that policy is in force.

    /// Set while `textDidEndEditing` is running, i.e. the action about to arrive was caused by
    /// editing ending rather than by the user taking a row out of the pop-up list.
    private(set) var isEndingEditing = false
    /// Whether that end of editing was Return rather than focus moving elsewhere.
    private(set) var endedEditingWithReturn = false
    /// Whether the user has moved the pop-up list's highlight during this editing session. Typing
    /// clears it again: text typed after a pick is no longer that pick.
    private(set) var hasPickedFromList = false
    /// Set while the list is being rebuilt, so the selection this class makes itself is not mistaken
    /// for one the user made.
    private var isReloadingList = false

    /// Whether what is happening right now is the user *choosing* — a row taken from the pop-up
    /// list, or Return on what they typed — rather than abandoning part-typed text.
    var isChoosingSelection: Bool { !isEndingEditing || endedEditingWithReturn || hasPickedFromList }

    override func textDidBeginEditing(_ notification: Notification) {
        hasPickedFromList = false
        super.textDidBeginEditing(notification)
    }

    override func textDidEndEditing(_ notification: Notification) {
        endedEditingWithReturn = (notification.userInfo?["NSTextMovement"] as? Int) == NSTextMovement.return.rawValue
        isEndingEditing = true
        // Both the action and `controlTextDidEndEditing` are sent from inside this call, so the
        // flags have to be in place before it and cleared only after it.
        super.textDidEndEditing(notification)
        isEndingEditing = false
        hasPickedFromList = false
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        guard !isReloadingList else { return }
        hasPickedFromList = true
        customDelegate?.listSelectionChangedByUser?(comboBox: self)
    }
    
    init() {
        super.init(frame: NSZeroRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.delegate = self
        self.dataSource = self
        (self.cell as! NSComboBoxCell).dataSource = self
    }
    
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        print("SubString = \(string)")
        print(filterdItems.count)
        let filteredArray = filterdItems.filter {$0.caseInsensitiveCompare(string) == .orderedSame}
        if filteredArray.count != 0{
            self.stringValue = filteredArray.first!
        }
        return string
    }

    func filterData(comboBox:NSComboBox, selectedText:String){
        isReloadingList = true
        defer { isReloadingList = false }
        filterdItems.removeAll()
        if selectedText == ""{
            filterdItems = items
            comboBox.reloadData()
            isReloadingList = true
            for i in 0..<filterdItems.count{
                let item = filterdItems[i]
                if item.caseInsensitiveCompare(self.stringValue) == .orderedSame {
                    comboBox.selectItem(at: i)
                }
            }
            isReloadingList = false
        }else{
            for item in items{
                if item.localizedCaseInsensitiveContains(selectedText){
                    filterdItems.append(item)
                }
            }
            comboBox.reloadData()
        }
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return(filterdItems.count)
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return(filterdItems[index] as AnyObject)
    }
    
    func comboBox(_ comboBox: NSComboBox, indexOfItemWithStringValue string: String) -> Int {
        var i = 0
        for str in filterdItems {
            if str == string{
                return i
            }
            i += 1
        }
        return -1
    }
    func controlTextDidChange(_ obj: Notification) {
        print("controlTextDidChange")
        if let object = obj.object as? NSComboBox{
            // Typing after taking a row out of the list means the row is no longer what the field
            // says, so it stops counting as this session's choice.
            hasPickedFromList = false
            filterData(comboBox: object, selectedText: object.stringValue)
            expandPopUp(comboBox: object, value: object.stringValue)
            customDelegate?.itemEditedByUser?(comboBox: self)
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        print("textDidEndEditing123")
        customDelegate?.itemSelectedByUser(comboBox: self)
    }
    
    func comboBoxWillPopUp(_ notification: Notification) {
        if menuShowByButton == false{
            menuShowByButton = true
            if let object = notification.object as? NSComboBox{
                filterData(comboBox: object, selectedText: object.stringValue)
            }
        }else{
            if let object = notification.object as? NSComboBox{
                filterData(comboBox: object, selectedText: "")
            }
            
        }
    }
    
    func expandPopUp(comboBox:NSComboBox, value:String){
        let isValueEmpty = value.isEmpty
        let isPopUpExpanded = comboBox.isAccessibilityExpanded()
        
        if (isValueEmpty && isPopUpExpanded){
            comboBox.cell?.setAccessibilityExpanded(false)
        }
        if (!isValueEmpty && !isPopUpExpanded){
            comboBox.cell?.setAccessibilityExpanded(true)
            menuShowByButton = false
        }
    }
}

// MARK: - SwiftUI

/// Whether an AppKit combo box's text may be replaced with the selected option's name.
///
/// `updateNSView` runs on every SwiftUI refresh, so unconditionally writing the selection back into
/// the field makes the field impossible to type in: each keystroke leaves `stringValue` differing
/// from the selection, and the next refresh replaces it — typing "Deep" reverted to "Meetings"
/// letter by letter. While the user is editing, their text is the truth. Shared by every SwiftUI
/// combo-box wrapper so the trap is fixed in one place rather than rediscovered in the next one.
enum ComboBoxTextSync {
    static func shouldOverwriteText(isEditing: Bool, current: String, selectedName: String) -> Bool {
        !isEditing && current != selectedName
    }
}

/// A SwiftUI dropdown whose menu narrows to what the user has typed, backed by `searchableComboBox`
/// — the same AppKit control the Create Task and Focus goal screens use — rather than a second
/// typeahead implementation. A flat `Picker` is unusable once the list is long, which is what this
/// replaces.
///
/// The binding is an option *id*, not text: the field shows a name, but what it reports is the id
/// the caller filters on, and `clearedOptionTitle` is the first row (e.g. "All projects") that puts
/// the binding back to nil.
struct SearchableComboBoxField: NSViewRepresentable {

    struct Option: Equatable {
        let id: String
        let name: String
    }

    /// When the field is allowed to write its binding.
    enum CommitPolicy {
        /// Every keystroke resolves into the binding, and abandoning the field keeps whatever the
        /// text resolved to. Required wherever a control elsewhere reads the binding without the
        /// field ever ending editing — a SwiftUI button click does not move first responder off an
        /// AppKit field, so "Create" would otherwise act on the previous selection.
        case asTyped
        /// The binding is written the moment the field says something unambiguous — text that names
        /// exactly one option, a row taken from the pop-up list, or Return — and at no other time.
        /// Text that still matches several options, or none, writes nothing at all rather than the
        /// nil it resolves to, so narrowing towards an answer never reads as "cleared". An empty
        /// field is itself unambiguous and clears at once. Abandoning part-typed text applies
        /// nothing and the field goes back to naming what is bound.
        case whenResolved
    }

    let options: [Option]
    /// The chosen option's id, or nil for "nothing chosen" — shown as `clearedOptionTitle`.
    @SwiftUI.Binding var selectedId: String?
    /// The leading row that clears the selection, and the field's placeholder.
    let clearedOptionTitle: String
    var commitPolicy: CommitPolicy = .asTyped

    private static let fontSize: CGFloat = 13
    private static let visibleItems = 10

    func makeNSView(context: Context) -> searchableComboBox { makeBox(coordinator: context.coordinator) }

    func updateNSView(_ box: searchableComboBox, context: Context) { apply(to: box, coordinator: context.coordinator) }

    /// The control `makeNSView` builds, and the refresh `updateNSView` performs, reachable without a
    /// SwiftUI `Context` — so a test can drive the real control through the real coordinator rather
    /// than a stand-in that could agree with a broken one.
    func makeBox(coordinator: Coordinator) -> searchableComboBox {
        let box = SearchableComboBoxField.makeFilteringBox(placeholder: clearedOptionTitle)
        box.customDelegate = coordinator
        box.target = coordinator
        box.action = #selector(Coordinator.comboCommitted(_:))
        return box
    }

    func apply(to box: searchableComboBox, coordinator: Coordinator) {
        coordinator.parent = self
        let titles = SearchableComboBoxField.titles(clearedOptionTitle: clearedOptionTitle, options: options)
        let isEditing = box.currentEditor() != nil
        if box.items != titles {
            box.items = titles
            // Re-apply the query the user is part-way through, so a list that arrives mid-typing
            // does not silently re-expand the menu to every option.
            box.filterData(comboBox: box, selectedText: isEditing ? box.stringValue : "")
        }
        let selectedName = SearchableComboBoxField.displayName(for: selectedId, options: options,
                                                               clearedOptionTitle: clearedOptionTitle)
        coordinator.boundName = selectedName
        if ComboBoxTextSync.shouldOverwriteText(isEditing: isEditing, current: box.stringValue,
                                                selectedName: selectedName) {
            box.stringValue = selectedName
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Pure helpers (tested without a window)

    /// A `searchableComboBox` configured to filter its menu as the user types. The storyboard copies
    /// of this control get the same wiring from their nib; one built in code has to ask for it.
    static func makeFilteringBox(placeholder: String) -> searchableComboBox {
        let box = searchableComboBox()
        box.usesDataSource = true
        box.completes = true
        box.isEditable = true
        box.hasVerticalScroller = true
        box.numberOfVisibleItems = visibleItems
        box.font = .systemFont(ofSize: fontSize)
        box.placeholderString = placeholder
        box.delegate = box
        box.dataSource = box
        (box.cell as? NSComboBoxCell)?.dataSource = box
        return box
    }

    /// The menu: the row that clears the filter, then every option.
    static func titles(clearedOptionTitle: String, options: [Option]) -> [String] {
        [clearedOptionTitle] + options.map { $0.name }
    }

    static func displayName(for selectedId: String?, options: [Option], clearedOptionTitle: String) -> String {
        guard let selectedId = selectedId,
              let option = options.first(where: { $0.id == selectedId }) else { return clearedOptionTitle }
        return option.name
    }

    /// Which option the text in the field means. An exact name wins; otherwise text that narrows the
    /// menu to exactly one option picks that one, which is what the user was looking at. Anything
    /// else — including the cleared row and an empty field — means "no option", so the field can
    /// never be left showing a name that filters to nothing.
    /// Whether the field says "nothing chosen" rather than "not finished typing" — it is empty, or
    /// it names the row whose whole job is to clear the selection. Those are the only two texts a
    /// `.whenResolved` caller may act on when `resolve` answers nil; every other nil means the user
    /// is still mid-word.
    static func isCleared(text: String, clearedOptionTitle: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed.caseInsensitiveCompare(clearedOptionTitle) == .orderedSame
    }

    static func resolve(text: String, options: [Option]) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let exact = options.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return exact.id
        }
        let matches = options.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        return matches.count == 1 ? matches[0].id : nil
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, SearchableComboBoxDelegate {
        var parent: SearchableComboBoxField
        /// The name of whatever the binding currently holds, kept here rather than read back from
        /// `parent` at the moment it is needed: a commit writes the binding, and SwiftUI does not
        /// hand the coordinator the updated `parent` until its next refresh, so reading `parent`
        /// while handling the events of a single click can still see the previous selection.
        var boundName: String?

        init(_ parent: SearchableComboBoxField) { self.parent = parent }

        /// Return pressed, or a row picked from the menu. `stringValue` is not committed yet at this
        /// point, so the highlighted row is the reliable answer.
        @objc func comboCommitted(_ sender: NSComboBox) {
            guard let box = sender as? searchableComboBox else { return }
            // `.whenResolved`: clicking away from part-typed text is not an answer, and the action
            // arrives for that too. `itemSelectedByUser` puts the field back to what is bound.
            guard parent.commitPolicy == .asTyped || box.isChoosingSelection else { return }
            // The highlighted row is the answer only when the user put it there. `reloadData` leaves
            // the previous index behind as the list narrows, so trusting it unconditionally lets
            // Return commit a row nobody looked at. `.asTyped` keeps the old reading, since its
            // callers have relied on it since before this flag existed.
            let index = box.indexOfSelectedItem
            let trustsHighlightedRow = parent.commitPolicy == .asTyped || box.hasPickedFromList
            let picked = trustsHighlightedRow && index >= 0 && index < box.filterdItems.count
                ? box.filterdItems[index] : box.stringValue
            commit(text: picked, in: box)
        }

        func listSelectionChangedByUser(comboBox: searchableComboBox) {
            comboCommitted(comboBox)
        }

        /// Editing finished (the user clicked away, or a pick ended it).
        ///
        /// Under `.asTyped` their text is what they meant, so it commits. Under `.whenResolved`
        /// abandoned typing applies nothing and the field goes back to showing what is bound —
        /// leaving "phd" in a box that is not filtering by `phd` would be a lie on screen.
        func itemSelectedByUser(comboBox: searchableComboBox) {
            guard parent.commitPolicy == .whenResolved else {
                commit(text: comboBox.stringValue, in: comboBox)
                return
            }
            // A choice is the action's to commit — rewriting the text here would hand it the old
            // value, since the action reads `stringValue` when no row is highlighted.
            guard !comboBox.isChoosingSelection else { return }
            let name = boundName ?? parent.clearedOptionTitle
            if comboBox.stringValue != name { comboBox.stringValue = name }
        }

        /// Every keystroke, so the binding always means what the field visibly says.
        ///
        /// Without this the selection only moved when editing *ended*, and a SwiftUI button click does
        /// not end AppKit field editing — the click never moves first responder off the field. So a
        /// user who typed a project name and went straight to "Create" fired the action against the
        /// previous selection. Resolving as they type removes the hazard for every caller rather than
        /// asking each one to remember to defuse it.
        ///
        /// `.whenResolved` keeps the good half of that and drops the bad half: it still answers while
        /// the user types, so typing a name in full needs no second gesture, but it stays silent
        /// while the text is still ambiguous instead of reporting the nil that resolves to. Writing
        /// that nil is what made a per-keystroke filter refetch everything mid-word.
        ///
        /// Only the binding is written here, never `stringValue`: replacing the text mid-word is the
        /// other trap this control exists to avoid (see `ComboBoxTextSync`).
        func itemEditedByUser(comboBox: searchableComboBox) {
            let resolved = SearchableComboBoxField.resolve(text: comboBox.stringValue, options: parent.options)
            if parent.commitPolicy == .whenResolved, resolved == nil,
               !SearchableComboBoxField.isCleared(text: comboBox.stringValue,
                                                  clearedOptionTitle: parent.clearedOptionTitle) { return }
            guard parent.selectedId != resolved else { return }
            // Keep the restore target in step with the write: a blur can follow before SwiftUI has
            // handed this coordinator the refreshed `parent`.
            boundName = SearchableComboBoxField.displayName(for: resolved, options: parent.options,
                                                            clearedOptionTitle: parent.clearedOptionTitle)
            parent.selectedId = resolved
        }

        private func commit(text: String, in box: searchableComboBox) {
            let resolved = SearchableComboBoxField.resolve(text: text, options: parent.options)
            // Return on text that names nothing in particular is not an answer either. `.asTyped`
            // still clears on it — a caller whose button reads the binding needs it to mean the
            // visible text — but `.whenResolved` leaves the selection alone and puts the field back.
            if parent.commitPolicy == .whenResolved, resolved == nil,
               !SearchableComboBoxField.isCleared(text: text, clearedOptionTitle: parent.clearedOptionTitle) {
                let name = boundName ?? parent.clearedOptionTitle
                if box.stringValue != name { box.stringValue = name }
                return
            }
            let name = SearchableComboBoxField.displayName(for: resolved, options: parent.options,
                                                           clearedOptionTitle: parent.clearedOptionTitle)
            boundName = name
            if box.stringValue != name { box.stringValue = name }
            if parent.selectedId != resolved { parent.selectedId = resolved }
        }
    }
}
