//
//  SelectableListBox.swift
//  FocusBear
//
//  Created by Manish Jain on 04/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class mainWindowListBox: NSBox {
    // MARK: - Properties
    
    let kBorderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
    private var hovered = false
    /// When true, this item refuses disable requests so it always stays clickable. Used for the
    /// Todo List, which must always be reachable. Onboarding is exempt — it deliberately locks the
    /// whole menu, so we don't fight it there.
    var alwaysEnabled = false
    var isEnabled: Bool = true{
        didSet {
            // alwaysEnabled tabs (Todo List) stay reachable during normal use, but must NOT before the
            // user is authenticated. The login and onboarding screens disable every tab; letting an
            // alwaysEnabled tab snap itself back on lets a logged-out user open it and leave the login
            // view with no way back. Allow the disable to stick in BOTH pre-auth states.
            if alwaysEnabled, !isEnabled, currentState != ._ONBOARDING_, currentState != ._LOGIN_ {
                isEnabled = true   // re-entrant set; guard above prevents recursion
                return
            }
            if oldValue != isEnabled {
                if isEnabled{
                    if !isSelected{
                        label?.textColor = NSColor.labelColor
                    }else{
                        label?.textColor = NSColor.black
                    }
                    imageView?.alphaValue = 1
                    disableReason = ""
                }else{
                    label?.textColor = NSColor.gray
                    imageView?.alphaValue = 0.5
                }
            }
        }
    }
    var disableReason = ""
    weak var delegate: mainWindowListBoxDelegate?
    
    var isSelected: Bool = false {
        didSet {
            // Selection does NOT touch `hovered`: the hover ✕ tracks the actual pointer, so selecting a
            // row you're hovering keeps the ✕ visible — it hides on real mouse-out or when another row is
            // entered. updateAppearance shows selected styling regardless of hover, so nothing is lost.
            // Only update appearance if value changed
            if oldValue != isSelected {
                updateAppearance()
                if isSelected {
                    notifySelectionChange()
                }
            }
            if isSelected {// needed beacuse some time box is already selected and we need to show window again setting it selected again so that screen frame will updated
                delegate?.selectableListBoxSelectionDidChange(self)
            }
        }
    }
    
    var imageIcon: NSImage? {
        didSet {
            imageView?.image = imageIcon
        }
    }
    
    override var title: String{
        didSet {
            label?.stringValue = title
        }
    }
    
    var imageView: NSImageView?
    private weak var label: NSTextField?

    /// When true, hovering this row reveals a trailing "hide" (✕) button. Used for TOOLS rows so
    /// users can simplify the sidebar; unset for everything else.
    var showsHideButton = false
    var onHideRequested: (() -> Void)?
    private weak var hideButton: cursorButton?
    private var scrollObserver: NSObjectProtocol?

    // MARK: - Initialization
    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func setDisableWithRaason(reason:String){
        isEnabled = false
        disableReason = reason
    }
    private func commonInit() {
        self.boxType = .custom
        self.borderWidth = 1.0
        self.cornerRadius = 4.0
        self.titlePosition = .noTitle
        
        setupContentView()
        updateAppearance()
        
        // Tracking area for hover effects
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    // MARK: - View Setup
    private func setupContentView() {
        let contentView = NSView()
        self.contentView = contentView
        
        // Image view
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Label
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        // Layout
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 19),
            imageView.heightAnchor.constraint(equalToConstant: 19),
            
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Set content hugging and compression resistance priorities
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
    
        if SettingsManagerObject.selectedFontIndex == systemFontIndex{
            label.font = NSFont.systemFont(ofSize: label.font?.pointSize ?? 24)
        }else{
            label.font = NSFont(name: selectedFont.regularFontName, size: label.font?.pointSize ?? 24) ?? NSFont.boldSystemFont(ofSize: 24)
        }
        
        self.imageView = imageView
        self.label = label

        // Trailing "hide" button, revealed on hover only when showsHideButton is set (see mouseEntered).
        let hideButton = cursorButton(title: "✕", target: self, action: #selector(hideButtonClicked))
        hideButton.bezelStyle = .circular
        hideButton.translatesAutoresizingMaskIntoConstraints = false
        hideButton.isHidden = true
        hideButton.toolTip = leftMenuConfigString("hideToolTooltip") ?? "Hide this tool"
        contentView.addSubview(hideButton)
        NSLayoutConstraint.activate([
            hideButton.widthAnchor.constraint(equalToConstant: 20),
            hideButton.heightAnchor.constraint(equalToConstant: 20),
            hideButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            hideButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        self.hideButton = hideButton
    }

    @objc private func hideButtonClicked() {
        onHideRequested?()
    }
    
    func showSelectedUi(){
        self.fillColor = buttonBgColor
        self.borderColor = kBorderColor
        label?.textColor = NSColor.black
        self.borderWidth = 1
    }
    
    func showHoveredUi(){
        self.fillColor = buttonBgColor.withAlphaComponent(0.3)
        self.borderColor = kBorderColor
        label?.textColor = NSColor.labelColor
        self.borderWidth = 1
    }
    
    func showNormalUi(){
        self.fillColor = NSColor.clear
        self.borderColor = .clear
        if isEnabled{
            label?.textColor = NSColor.labelColor
        }else{
            label?.textColor = NSColor.gray
        }
        self.borderWidth = 1
    }
    
    // MARK: - Appearance Updates
    private func updateAppearance() {
        if isSelected {
            showSelectedUi()
        } else if hovered {
            showHoveredUi()
        } else {
            showNormalUi()
        }
        // Drive the hover ✕ from a single place so it can never get stuck on — e.g. when selecting a
        // tool opens its window and steals focus, the follow-up mouseExited never arrives. Any state
        // change that touches `hovered`/`isSelected`/`isEnabled` and calls updateAppearance keeps it right.
        hideButton?.isHidden = !(showsHideButton && hovered && isEnabled)
        // #2252: keep the ✕ readable in every state. A selected row uses a solid light fill and forces
        // its label to black; the ✕ was left at the appearance-adaptive labelColor (white in dark mode),
        // so it vanished on the selected fill. Match the ✕ to the label's colour so it always contrasts.
        if let color = label?.textColor {
            hideButton?.attributedTitle = NSAttributedString(string: "✕", attributes: [.foregroundColor: color])
        }
    }
    
    // MARK: - Mouse Events
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        // Use showTooltipWithOsTahoe here, not showTooltip: its .transient popover ate the row's first click to dismiss itself, so collapsed-sidebar icons needed multiple clicks (#2484).
        if isEnabled{
            // Collapsed sidebar hides the row labels, so surface the item's title on hover. Only enabled
            // items reach here (they never carry a disableReason), so the disabled tooltip below is untouched.
            if (mainViewControllerObj?.isLeftPanelCollapsed ?? false), !title.isEmpty{
                showTooltipWithOsTahoe(sender: self, msg: title, preferredEdge: .maxX, maxWidthVal: 250, autoCloseOnMouseExit: true)
            }
            hovered = true
            updateAppearance()   // reveals the hover ✕ (see updateAppearance)
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    NSCursor.pointingHand.set()
                }
            }
            if let superview = self.superview {
                for subview in superview.subviews {
                    if let box = subview as? mainWindowListBox, box != self {
                        box.hovered = false
                        // Route through updateAppearance (not just showNormalUi) so the other row's hover
                        // ✕ hides too — covers a row that missed its own mouseExited (e.g. selection opened
                        // a window that swallowed it). Selected rows keep their selected styling.
                        box.updateAppearance()
                    }
                }
            }
        }else{
            // Disabled item: keep showing its disableReason (unchanged behavior).
            if !disableReason.isEmpty{
                showTooltipWithOsTahoe(sender: self, msg: disableReason, preferredEdge: .maxX, maxWidthVal: 250, autoCloseOnMouseExit: true)
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        // Close whatever hover tooltip we showed (disableReason or the collapsed-title one).
        closePopoverTooltipIfVisible()
        if isEnabled{
            hovered = false
            updateAppearance()   // hides the hover ✕ (see updateAppearance)
            NSCursor.arrow.set()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if isEnabled && !isSelected{
            if delegate?.selectableListBoxShouldChangeSelection(self) ?? true{
                isSelected = true
                delegate?.selectableListBoxDidChangeSelectionByUser(self)
            }
        }
    }
    
    // MARK: - Selection Management
    private func notifySelectionChange() {
        if let superview = self.superview {
            for subview in superview.subviews {
                if let box = subview as? mainWindowListBox, box != self {
                    box.isSelected = false
                    box.hovered = false
                }
            }
        }
    }
    
    // MARK: - updateTrackingAreas
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    // MARK: - Scroll-aware hover reconciliation
    // When the menu scrolls, a row can move out from under a stationary pointer without AppKit
    // delivering mouseExited — leaving the hover ✕ button (and pointing-hand cursor) stuck on. Watch
    // the enclosing scroll view's clip-view bounds changes and re-derive the hover state from the real
    // mouse position on every scroll tick.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let observer = scrollObserver {
            NotificationCenter.default.removeObserver(observer)
            scrollObserver = nil
        }
        guard let clipView = enclosingScrollView?.contentView else { return }
        clipView.postsBoundsChangedNotifications = true
        scrollObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification, object: clipView, queue: .main
        ) { [weak self] _ in
            self?.reconcileHoverWithMouseLocation()
        }
    }

    deinit {
        if let observer = scrollObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Re-derives hover state from the current mouse position — used when the row moves under the
    /// pointer (scroll) rather than the pointer moving over the row, which is when mouseEntered/Exited
    /// can be skipped. Each row reconciles itself, so a row scrolled off the pointer clears its own ✕.
    private func reconcileHoverWithMouseLocation() {
        guard isEnabled, let window = window else { return }
        let pointInView = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        let inside = bounds.contains(pointInView)
        if inside {
            guard !hovered else { return }
            hovered = true
            updateAppearance()   // reveals the hover ✕
            NSCursor.pointingHand.set()
        } else {
            guard hovered else { return }
            hovered = false
            updateAppearance()   // hides the hover ✕
            NSCursor.arrow.set()
        }
    }
}

protocol mainWindowListBoxDelegate: AnyObject {
    /// Called when the selection changes due to user interaction (click/tap)
    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox)
    
    func selectableListBoxShouldChangeSelection(_ box: mainWindowListBox) -> Bool
    
    /// Called when the selection changes for any reason (user or programmatic)
    func selectableListBoxSelectionDidChange(_ box: mainWindowListBox)
}
