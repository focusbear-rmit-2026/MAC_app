//
//  ToggleBoxTitledBox.swift
//  FocusBear
//
//  Created by Manish Jain on 20/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class toggleTitledBox: NSBox {

    // MARK: - Properties
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    var index = 0
    var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private var trackingArea: NSTrackingArea?
    
    // MARK: - Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupBox()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBox()
    }
    
    private func setupBox() {
        // Box appearance
        self.boxType = .custom
//        self.borderType = .lineBorder
        self.borderWidth = 1
        self.cornerRadius = 6
        self.borderColor = NSColor.separatorColor
        self.fillColor = NSColor.controlBackgroundColor
        
        // Add label
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        
        // Enable mouse events
        self.wantsLayer = true
        self.updateAppearance()
    }
    
    // MARK: - Appearance
    private func updateAppearance() {
        if isSelected {
            self.fillColor = NSColor.systemOrange
            self.titleLabel.textColor = .white
        } else {
            self.fillColor = NSColor.controlBackgroundColor
            self.titleLabel.textColor = .labelColor
        }
    }
    
    // MARK: - Mouse Events
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(rect: self.bounds,
                                      options: [.mouseEnteredAndExited, .activeAlways],
                                      owner: self,
                                      userInfo: nil)
        if let trackingArea = trackingArea {
            self.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.push()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.pop()
    }
    
    override func mouseDown(with event: NSEvent) {
        isSelected.toggle()
        super.mouseDown(with: event)
    }
}
