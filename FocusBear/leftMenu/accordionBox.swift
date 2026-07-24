//
//  accordionBox.swift
//  FocusBear
//
//  Created by Manish Jain on 05/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class accordionBox: NSBox {
    
    // MARK: - Properties
    private var isExpanded: Bool = false {
        didSet {
            updateAppearance()
            onStateChanged?(isExpanded)
        }
    }
    
    override var title: String{
        didSet {
            titleLabel.stringValue = title
        }
    }
    
    var onStateChanged: ((Bool) -> Void)?

    /// Set to show a gear icon to the left of the chevron (e.g. TOOLS, to restore hidden rows).
    /// Left nil for sections that don't need one.
    var onGearClicked: (() -> Void)? {
        didSet { gearButton.isHidden = (onGearClicked == nil) }
    }

    private lazy var gearButton: cursorButton = {
        let button = cursorButton(title: "", target: self, action: #selector(gearButtonClicked))
        button.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Manage hidden tools")
        button.isBordered = false
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = .labelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        if SettingsManagerObject.selectedFontIndex == systemFontIndex{
            label.font = NSFont.systemFont(ofSize: label.font?.pointSize ?? 24)
        }else{
            label.font = NSFont(name: selectedFont.regularFontName, size: label.font?.pointSize ?? 24) ?? NSFont.boldSystemFont(ofSize: 24)
        }
        return label
    }()
    
    private let arrowImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()
    
    private var trackingArea: NSTrackingArea?
    
    // MARK: - Initialization
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.boxType = .custom
        self.borderWidth = 0.0
        self.borderColor = NSColor.separatorColor
        self.cornerRadius = 4.0
        self.fillColor = NSColor.clear
        self.titlePosition = .noTitle
        
        addSubview(titleLabel)
        addSubview(gearButton)
        addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 18),
            arrowImageView.heightAnchor.constraint(equalToConstant: 18),

            gearButton.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            gearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            gearButton.widthAnchor.constraint(equalToConstant: 18),
            gearButton.heightAnchor.constraint(equalToConstant: 18)
        ])
        
        updateAppearance()
        
        // Tracking area for hover effects
        updateTrackingAreas()
    }
    
    // MARK: - Appearance
    private func updateAppearance() {
        let arrowImageName = isExpanded ? NSImage.touchBarGoDownTemplateName : NSImage.touchBarGoForwardTemplateName
        arrowImageView.image = NSImage(named: arrowImageName)
    }
    
    // MARK: - Mouse Handling
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
        self.alphaValue = 0.8
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
        self.alphaValue = 1.0
    }
    
    override func mouseDown(with event: NSEvent) {
        self.alphaValue = 0.7
    }
    
    override func mouseUp(with event: NSEvent) {
        self.alphaValue = 1.0
        
        let point = convert(event.locationInWindow, from: nil)
        if bounds.contains(point) {
            isExpanded.toggle()
        }
    }
    
    // MARK: - Public Methods
    func setExpanded(_ expanded: Bool, animated: Bool = false) {
        isExpanded = expanded
    }

    @objc private func gearButtonClicked() {
        onGearClicked?()
    }
}
