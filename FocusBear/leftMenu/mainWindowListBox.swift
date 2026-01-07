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
    var isEnabled: Bool = true{
        didSet {
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
            // Only update appearance if value changed
            if oldValue != isSelected {
                updateAppearance()
                if isSelected {
                    notifySelectionChange()
                }
            }
            if isSelected {// needed beacuse some time box is already selected and we need to show window again setting it selected again so that screen frame will updated
                delegate?.selectableListBoxSelectionDidChange(self)
                hovered = false
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
            options: [.activeAlways, .mouseEnteredAndExited],
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
    }
    
    // MARK: - Mouse Events
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if isEnabled{
            hovered = true
            updateAppearance()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    NSCursor.pointingHand.set()
                }
            }
            if let superview = self.superview {
                for subview in superview.subviews {
                    if let box = subview as? mainWindowListBox, box != self {
                        box.hovered = false
                        if !box.isSelected{
                            box.showNormalUi()
                        }
                    }
                }
            }
        }else{
            if !disableReason.isEmpty{
                showTooltip(sender: self, msg: disableReason, preferredEdge: .maxX, maxWidthVal: 250, autoCloseOnMouseExit: true)
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if isEnabled{
            hovered = false
            updateAppearance()
            NSCursor.arrow.set()
        }else{
            closePopoverTooltipIfVisible()
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
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
}

protocol mainWindowListBoxDelegate: AnyObject {
    /// Called when the selection changes due to user interaction (click/tap)
    func selectableListBoxDidChangeSelectionByUser(_ box: mainWindowListBox)
    
    func selectableListBoxShouldChangeSelection(_ box: mainWindowListBox) -> Bool
    
    /// Called when the selection changes for any reason (user or programmatic)
    func selectableListBoxSelectionDidChange(_ box: mainWindowListBox)
}
