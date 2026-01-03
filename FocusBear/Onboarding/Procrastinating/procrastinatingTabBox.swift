//
//  SelectableListBox.swift
//  FocusBear
//
//  Created by Manish Jain on 03/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//


import Cocoa

class procrastinatingTabBox: NSBox {
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
                    disableReason = ""
                }else{
                    label?.textColor = NSColor.gray
                }
            }
        }
    }
    var disableReason = ""
    weak var delegate: procrastinatingTabBoxDelegate?
    
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
    
    
    override var title: String{
        didSet {
            label?.stringValue = title
        }
    }
    
  
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
        
        
        // Label
        let label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        // Layout
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        // Set content hugging and compression resistance priorities
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
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
        self.borderColor = kBorderColor
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
                    if let box = subview as? procrastinatingTabBox, box != self {
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
            isSelected = true
        }
    }
    
    // MARK: - Selection Management
    private func notifySelectionChange() {
        if let superview = self.superview {
            for subview in superview.subviews {
                if let box = subview as? procrastinatingTabBox, box != self {
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

protocol procrastinatingTabBoxDelegate: AnyObject {
    /// Called when the selection changes due to user interaction (click/tap)
    func selectableListBoxSelectionDidChange(_ box: procrastinatingTabBox)
}
