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
                if self.window?.windowController == taskPlayerWcObj{
                    taskPlayerVcObj?.windowDragged()
                }
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

let buttonTitleColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
let buttonBgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
class Button: NSButton {
    var mouseDown = false
    
    let titleDisableColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
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
                self.layer?.backgroundColor = NSColor.clear.cgColor
                self.layer?.borderColor = NSColor.gray.cgColor
                self.titleColor = NSColor.gray///buttonTitleColor
            }
        }
    }
    
    override var isEnabled: Bool{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = NSColor.black//buttonTitleColor
            }else{
                self.layer?.backgroundColor = NSColor.clear.cgColor
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
