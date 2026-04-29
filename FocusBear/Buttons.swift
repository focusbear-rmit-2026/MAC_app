//
//  Buttons.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa


class cursorButton: NSButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}

class mouseDownMoveWindowButton: NSButton {
    override var mouseDownCanMoveWindow: Bool{
        return true
    }
    var mouseDown = false
    var mouseDragged = false
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            mouseDown = true
            NSCursor.pointingHand.set()
        }
        mouseDragged = false
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        mouseDown = false
        mouseDragged = true
    }
    
    override func mouseUp(with event: NSEvent) {
        if self.isEnabled{
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
            }else{
//                if self.window?.windowController == taskPlayerWcObj{
//                    taskPlayerVcObj?.windowDragged()
//                }
            }
        }
        mouseDragged = false
    }
    
}

class hoverInfoButton: NSButton {
    
    var isAutoClickEnabled = true
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
        if isAutoClickEnabled{
            self.performClick(self)
        }
            
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        if popoverTooltip != nil{
            if popoverTooltip!.isShown{
                popoverTooltip?.close()
            }
        }
        if popoverFocusHelp != nil{
            if popoverFocusHelp!.isShown{
                popoverFocusHelp?.close()
            }
        }
    }
}

class toolTipButton: NSButton {
    
    //var isAutoClickEnabled = true
    var customToolTip = ""
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
        if !customToolTip.isEmpty{
            showTooltipWithOsTahoe(sender: self, msg: customToolTip, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        if popoverTooltip != nil{
            if popoverTooltip!.isShown{
                popoverTooltip?.close()
            }
        }
        if popoverFocusHelp != nil{
            if popoverFocusHelp!.isShown{
                popoverFocusHelp?.close()
            }
        }
    }
}

class settingsMouseDownEffectButton: NSButton {
    var mouseDown = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        self.layer?.cornerRadius = 4
    }
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.05).cgColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                NSCursor.pointingHand.set()
            }
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}

class underLineButton: cursorButton {
    
    var titleColor = NSColor.labelColor
    func setDisable(title:String){
        isEnabled = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    func setEnable(title:String){
        isEnabled = true
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    override var title: String {
        didSet {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = self.alignment
            paragraph.lineBreakMode = .byTruncatingTail
            let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
        }
    }
}

// onbaording skip button
class hoverUnderlineButton: cursorButton {
    
    var titleColor = NSColor.labelColor
    private var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        if !isEnabled{
            return;
        }
        applyUnderline(true)
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        applyUnderline(false)
        super.mouseExited(with: event)
    }

    private func applyUnderline(_ underline: Bool) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.alignment
        paragraph.lineBreakMode = .byTruncatingTail

        var attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: isEnabled ? titleColor : NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph
        ]

        if underline {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        self.attributedTitle = NSAttributedString(string: self.title, attributes: attrs)
    }

    func setDisable(title: String) {
        isEnabled = false
        self.title = title
        applyUnderline(false)
    }

    func setEnable(title: String) {
        isEnabled = true
        self.title = title
        applyUnderline(false)
    }

    override var title: String {
        didSet {
            applyUnderline(false)
        }
    }
}


let buttonTitleColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
let buttonBgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
class ButtonOld: NSButton {// not in use
    var mouseDown = false
    
    var titleDisableColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    var backgroundDisableColor = NSColor.clear.cgColor
    
    @IBInspectable var horizontalPadding   : CGFloat = 50
    @IBInspectable var verticalPadding    : CGFloat = 50
    
    @IBInspectable var isForPrefrences    : Bool = false
    
    var borderWidth: CGFloat = 1{
        didSet{
            self.layer?.borderWidth = borderWidth
        }
    }
    var currentTitle = ""
    var buttonColor = buttonBgColor.cgColor{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = NSColor.black//buttonTitleColor
            }else{
                self.layer?.backgroundColor = backgroundDisableColor
                self.layer?.borderColor = NSColor.gray.cgColor
                self.titleColor = NSColor.gray///buttonTitleColor
            }
        }
    }
    
    var isSecondaryButton = false{
        didSet{
            buttonColor = isSecondaryButton
                        ? NSColor.white.cgColor
                        : buttonBgColor.cgColor
        }
    }
    
    override var isEnabled: Bool{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = NSColor.black//buttonTitleColor
            }else{
                self.layer?.backgroundColor = backgroundDisableColor
                self.layer?.borderColor = NSColor.gray.cgColor
                self.titleColor = NSColor.gray//titleDisableColor//buttonTitleColor
            }
        }
    }
    var buttonDownColor = NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1).cgColor
    var titleColor = NSColor.black{//buttonTitleColor
        didSet{
            self.title = currentTitle
        }
    }
    var borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1).cgColor
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        self.isBordered = false
        self.layer?.cornerRadius = self.frame.height/7
        self.layer?.backgroundColor = buttonColor
        
        self.layer?.borderWidth = borderWidth
        self.layer?.borderColor = borderColor
        self.contentTintColor = titleColor
    }
    
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        if self.image == nil{// if not an image button than
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }else{
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }
        return size;
    }
    override func draw(_ dirtyRect: NSRect) {
        let originalBounds = self.bounds
        defer { self.bounds = originalBounds }
        
        // Inset bounds by the image padding
        self.bounds = originalBounds.insetBy(
            dx: 10,
            dy: 0
        )
        //}
        // Draw the button content with padding
        super.draw(dirtyRect)
    }
        
    
    override var title: String {
        didSet {
            currentTitle = title
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            
            let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, .font:self.font ?? NSFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
            // }
        }
    }
    
    
    
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = buttonDownColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                if isEnabled{// possible to be in disable state after mouse down
                    NSCursor.pointingHand.set()
                }
            }
            if isEnabled{// possible to be in disable state after mouse down
                self.layer?.backgroundColor = buttonColor
            }
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        if self.isEnabled{
            NSCursor.arrow.set()
            self.layer?.backgroundColor = buttonColor
        }
    }
}



class Button: NSButton {
    var mouseDown = false
    
    var titleDisableColor = NSColor.gray
    var titleEnableColor = NSColor.white
    var backgroundDisableColor = NSColor.clear.cgColor
    var grayBorderColor = NSColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1).cgColor
    
    @IBInspectable var horizontalPadding   : CGFloat = 50
    @IBInspectable var verticalPadding    : CGFloat = 50
    
    @IBInspectable var isForPrefrences    : Bool = false
    
    var borderWidth: CGFloat = 1{
        didSet{
            self.layer?.borderWidth = borderWidth
        }
    }
    
    var titleColor = NSColor.white{//buttonTitleColor
        didSet{
            self.title = currentTitle
            self.contentTintColor = titleColor
        }
    }
    
    var currentTitle = ""
    var buttonColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.orange.cgColor{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = titleEnableColor//buttonTitleColor
            }else{
                self.layer?.backgroundColor = backgroundDisableColor
                self.layer?.borderColor = grayBorderColor
                self.titleColor = titleDisableColor///buttonTitleColor
            }
        }
    }
    
    var isSecondaryButton = false{
        didSet{
            if isSecondaryButton{
                titleEnableColor = NSColor.black
                borderColor = grayBorderColor
                buttonColor = NSColor.white.cgColor
                buttonDownColor = NSColor(named: "light_OrangeColor")?.cgColor ?? NSColor.orange.cgColor
            }else{
                titleEnableColor = NSColor.white
                borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.orange.cgColor
                buttonColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.orange.cgColor
                buttonDownColor = NSColor(named: "dark_OrangeColor")?.withAlphaComponent(0.7).cgColor ?? NSColor.orange.cgColor
            }
        }
    }
    
    override var isEnabled: Bool{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = titleEnableColor
            }else{
                self.layer?.backgroundColor = backgroundDisableColor
                self.layer?.borderColor = grayBorderColor
                self.titleColor = titleDisableColor
            }
        }
    }
    var buttonDownColor = NSColor(named: "dark_OrangeColor")?.withAlphaComponent(0.7).cgColor ?? NSColor.orange.cgColor//NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1).cgColor
    
    var borderColor = NSColor(named: "dark_OrangeColor")?.cgColor ?? NSColor.orange.cgColor
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        self.isBordered = false
        self.layer?.cornerRadius = self.frame.height/7
        self.layer?.backgroundColor = buttonColor
        
        self.layer?.borderWidth = borderWidth
        self.layer?.borderColor = borderColor
        self.contentTintColor = titleColor
    }
    
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        if self.image == nil{// if not an image button than
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }else{
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }
        return size;
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let originalBounds = self.bounds
        defer { self.bounds = originalBounds }
        
        // Inset bounds by the image padding
        self.bounds = originalBounds.insetBy(
            dx: 10,
            dy: 0
        )
        //}
        // Draw the button content with padding
        super.draw(dirtyRect)
    }
        
    
    override var title: String {
        didSet {
            currentTitle = title
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            
            let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, .font:self.font ?? NSFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
        }
    }
    
    
    
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = buttonDownColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                if isEnabled{// possible to be in disable state after mouse down
                    NSCursor.pointingHand.set()
                }
            }
            if isEnabled{// possible to be in disable state after mouse down
                self.layer?.backgroundColor = buttonColor
            }
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        if self.isEnabled{
            NSCursor.arrow.set()
            self.layer?.backgroundColor = buttonColor
        }
    }
}


class mouseDownEffectButton: NSButton {
    var mouseDown = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        if let box = self.superview?.superview as? NSBox{
            self.layer?.cornerRadius = box.cornerRadius
        }
    }
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                NSCursor.pointingHand.set()
            }
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}




class boxButtonOld: NSBox {

    // MARK: - Public API
    weak var target: AnyObject?
    var action: Selector?

    var isEnabled: Bool = true {
        didSet {
            updateAppearance()
        }
    }
    let buttonBorderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
    var buttonDownColor = NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1)
    var buttonBgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
    var titleColor = NSColor.black
    
    // MARK: - UI
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")

    // MARK: - State
    private var hovered = false
    private var pressed = false

    // MARK: - Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        boxType = .custom
        cornerRadius = 6
        borderWidth = 1
        titlePosition = .noTitle

        setupContent()
        updateAppearance()
        borderColor = buttonBorderColor
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }

    // MARK: - Content
    private func setupContent() {
        let contentView = NSView()
        self.contentView = contentView

        // StackView to keep icon + label together
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Truncation
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            // Center the whole group
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // Minimum padding from edges
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),

            // Icon size
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }


    // MARK: - Public setters
    func setTitle(_ title: String) {
        titleLabel.stringValue = title
    }

    func setImage(_ image: NSImage?) {
        iconView.image = image
    }
    func setButtonColor(_ color: NSColor) {
        buttonBgColor = color
        fillColor = buttonBgColor
    }
    
    func setTitleColor(_ color: NSColor) {
        titleLabel.textColor = color
        titleColor = color
    }
    // MARK: - Appearance
    private func updateAppearance() {
        if !isEnabled {
            fillColor = .clear
            borderColor = .clear
            titleLabel.textColor = .gray
            iconView.alphaValue = 0.5
            return
        }

        if pressed {
            fillColor = buttonDownColor
        } else if hovered {
            fillColor = buttonBgColor
        } else {
            fillColor = buttonBgColor
        }

        titleLabel.textColor = titleColor
        iconView.alphaValue = 1
    }

    // MARK: - Mouse handling
    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else { return }
        hovered = true
        updateAppearance()
        NSCursor.pointingHand.set()
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        pressed = false
        updateAppearance()
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }

        pressed = true
        updateAppearance()
    }

    override func mouseUp(with event: NSEvent) {
        pressed = false
        updateAppearance()
        
        // Convert mouse location to local coordinates
        let location = convert(event.locationInWindow, from: nil)
        
        // Fire action ONLY if mouseUp is inside the button
        if bounds.contains(location) {
            if let target = target, let action = action {
                NSApp.sendAction(action, to: target, from: self)
            }
        }
    }

    // MARK: - Tracking area
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)

        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }
}

class boxButton: NSBox {

    // MARK: - Public API
    weak var target: AnyObject?
    var action: Selector?

    var isEnabled: Bool = true {
        didSet {
            updateAppearance()
        }
    }
    let buttonBorderColor = NSColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
    var buttonDownColor = NSColor(named: "light_OrangeColor") ?? NSColor.orange
    var buttonBgColor = NSColor.white
    var titleColor = NSColor.black
    
    // MARK: - UI
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")

    // MARK: - State
    private var hovered = false
    private var pressed = false

    // MARK: - Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        boxType = .custom
        cornerRadius = 6
        borderWidth = 1
        titlePosition = .noTitle

        setupContent()
        updateAppearance()
        borderColor = buttonBorderColor
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }

    // MARK: - Content
    private func setupContent() {
        let contentView = NSView()
        self.contentView = contentView

        // StackView to keep icon + label together
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Truncation
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            // Center the whole group
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            // Minimum padding from edges
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),

            // Icon size
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }


    // MARK: - Public setters
    func setTitle(_ title: String) {
        titleLabel.stringValue = title
    }

    func setImage(_ image: NSImage?) {
        iconView.image = image
    }
    func setButtonColor(_ color: NSColor) {
        buttonBgColor = color
        fillColor = buttonBgColor
    }
    
    func setTitleColor(_ color: NSColor) {
        titleLabel.textColor = color
        titleColor = color
    }
    // MARK: - Appearance
    private func updateAppearance() {
        if !isEnabled {
            fillColor = .clear
            borderColor = .clear
            titleLabel.textColor = .gray
            iconView.alphaValue = 0.5
            return
        }

        if pressed {
            fillColor = buttonDownColor
        } else if hovered {
            fillColor = buttonBgColor
        } else {
            fillColor = buttonBgColor
        }

        titleLabel.textColor = titleColor
        iconView.alphaValue = 1
    }

    // MARK: - Mouse handling
    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else { return }
        hovered = true
        updateAppearance()
        NSCursor.pointingHand.set()
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        pressed = false
        updateAppearance()
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }

        pressed = true
        updateAppearance()
    }

    override func mouseUp(with event: NSEvent) {
        pressed = false
        updateAppearance()
        
        // Convert mouse location to local coordinates
        let location = convert(event.locationInWindow, from: nil)
        
        // Fire action ONLY if mouseUp is inside the button
        if bounds.contains(location) {
            if let target = target, let action = action {
                NSApp.sendAction(action, to: target, from: self)
            }
        }
    }

    // MARK: - Tracking area
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)

        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }
}

@IBDesignable
class iconTitleButton: NSButton {

    // MARK: - Layout
    
    @IBInspectable var leftPadding: CGFloat = 10
    @IBInspectable var rightPadding: CGFloat = 10
    @IBInspectable var iconTitleSpacing: CGFloat = 10
    @IBInspectable var iconSize: CGFloat = 23{
        didSet {
            iconWidthConstraint?.constant = iconSize
            iconHeightConstraint?.constant = iconSize
        }
    }
    
    // 0 = left, 1 = center, 2 = right
    @IBInspectable var titleAlignmentOption: Int = 0
    
    
    @IBInspectable var borderColor: NSColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue {
        didSet { needsDisplay = true }
    }

    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet { needsDisplay = true }
    }
    @IBInspectable var iconColor: NSColor?{
        didSet { needsDisplay = true }
    }
    // MARK: - Colors
    
    @IBInspectable var bgColor: NSColor = NSColor(named: "light_OrangeColor") ?? NSColor.blue
    @IBInspectable var hoverColor: NSColor = NSColor(named: "light_OrangeColor") ?? NSColor.blue
    @IBInspectable var downColor: NSColor = NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1)
    
    @IBInspectable var cornerRadius: CGFloat = 6{
        didSet { layer?.cornerRadius = cornerRadius}
    }
    
    
    @IBInspectable var titleColor: NSColor = .black {
        didSet { needsDisplay = true }
    }
    private let iconImageView = NSImageView()
    
    // MARK: - Private
    
    private var trackingArea: NSTrackingArea?
    private var isHover = false
    private var isPressed = false
    
    private var iconWidthConstraint: NSLayoutConstraint!
    private var iconHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    private func setup() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.contentTintColor = iconColor ?? .labelColor
        iconImageView.isEditable = false
        //iconImageView.isUserInteractionEnabled = false // ensures button clicks pass through
        addSubview(iconImageView)
        iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        iconWidthConstraint = iconImageView.widthAnchor.constraint(equalToConstant: iconSize)
        iconHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: iconSize)

        iconWidthConstraint.isActive = true
        iconHeightConstraint.isActive = true
        
        
        isBordered = false
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        
        imagePosition = .noImage
        title = title
    }
    
    // MARK: - Hover
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil)
        
        addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHover = true
        needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isHover = false
        needsDisplay = true
    }
    
    override func mouseDown(with event: NSEvent) {
        isPressed = true
        needsDisplay = true
        
        super.mouseDown(with: event)
        
        isPressed = false
        needsDisplay = true
    }
    
    
    override func resetCursorRects() {
        if isEnabled {
            addCursorRect(bounds, cursor: .pointingHand)
        } else {
            addCursorRect(bounds, cursor: .arrow)
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        
        drawBackground()
        drawContent()
    }
    
    private func drawBackground() {
        
        var color = bgColor
        
        if isPressed {
            color = downColor
        } else if isHover {
            color = hoverColor
        }
        
        // Background path
        let bgRect = bounds
        let bgPath = NSBezierPath(
            roundedRect: bgRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )
        
        color.setFill()
        bgPath.fill()
        
        // Border path (slightly inset)
        if borderWidth > 0 {
            
            let borderRect = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            
            let borderPath = NSBezierPath(
                roundedRect: borderRect,
                xRadius: cornerRadius,
                yRadius: cornerRadius
            )
            
            borderColor.setStroke()
            borderPath.lineWidth = borderWidth
            borderPath.stroke()
        }
    }
    
    private func drawContent() {
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 14),
            .foregroundColor: titleColor
        ]
        
        let titleSize = title.size(withAttributes: attributes)
        
        var iconWidth: CGFloat = 0
        
        if image != nil {
            iconWidth = iconSize + iconTitleSpacing
        }
        
        let totalWidth = iconWidth + titleSize.width
        
        var startX: CGFloat = leftPadding
        
        switch titleAlignmentOption {
            
        case 0: // left
            startX = leftPadding
            
        case 1: // center
            startX = (bounds.width - totalWidth) / 2
            
        case 2: // right
            startX = bounds.width - totalWidth - rightPadding
            
        default:
            break
        }
        
        let centerY = bounds.midY
        
        if let img = image {
            iconImageView.image = img
            iconImageView.contentTintColor = iconColor ?? .labelColor
//            iconImageView.frame = NSRect(
//                x: startX,
//                y: centerY - iconSize / 2,
//                width: iconSize,
//                height: iconSize
//            )
            iconImageView.frame.origin.x = startX
            startX += iconSize + iconTitleSpacing
        }
        
        // Draw title
        
        let titleRect = NSRect(
            x: startX,
            y: centerY - titleSize.height/2,
            width: titleSize.width,
            height: titleSize.height
        )
        
        title.draw(in: titleRect, withAttributes: attributes)
    }
}

extension NSImage {
    func attributedString(tint: NSColor, size: CGFloat) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = self

        // Resize icon
        attachment.bounds = CGRect(x: 0, y: -(size - size/1.5)/2, width: size, height: size)

        // Set template mode
        self.isTemplate = true

        // Create attributed string
        let attributed = NSAttributedString(attachment: attachment)

        // Add tint
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.addAttribute(.foregroundColor, value: tint, range: NSRange(location: 0, length: mutable.length))

        return mutable
    }
}




class hoverEffectButton: NSButton {
    var mouseDown = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        if let box = self.superview?.superview as? NSBox{
            self.layer?.cornerRadius = box.cornerRadius
        }
    }
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                NSCursor.pointingHand.set()
            }
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.1).cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}
