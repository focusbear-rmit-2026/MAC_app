//
//  allSubclasses.swift
//  FocusBear
//
//  Created by Manish Jain on 23/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import SystemConfiguration

class DashedView:NSView {
    var isFirst = true
    let yourViewBorder = CAShapeLayer()
    override func draw(_ dirtyRect: NSRect) {
        yourViewBorder.strokeColor = NSColor.secondaryLabelColor.cgColor
        yourViewBorder.lineDashPattern = [3, 5]
        yourViewBorder.frame = dirtyRect
        yourViewBorder.fillColor = nil//NSColor.red.cgColor
        yourViewBorder.path = NSBezierPath(rect:dirtyRect).cgPath
        yourViewBorder.lineWidth = 2
        if isFirst {
            self.layer?.addSublayer(yourViewBorder)
            isFirst = false
        }
        super.draw(dirtyRect)
    }
}

// MARK: - 👉 This way, when your NSTableView scrolls and clips the last row, the dashed border will always align with the cell’s actual bounds — no random half rendering.
class DashedViewForTableViewCell:NSView {
    private let borderLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        layer?.addSublayer(borderLayer)

        borderLayer.strokeColor = NSColor.secondaryLabelColor.cgColor
        borderLayer.lineDashPattern = [3, 5]
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
    }

    override func layout() {
        super.layout()
        borderLayer.frame = bounds
        borderLayer.path = NSBezierPath(rect: bounds).cgPath
    }
}


// in macos 26 user was able to click on superview through subview in enterPasswordVc view (a button to prevent this already there but in macos 26 button was not stoppoint clickin on superview) to prevent this made this view 14/7/25 1.26.390
class BlockingView: NSView {
    override func mouseDown(with event: NSEvent) {
       // super.mouseDown(with: event)
    }
    override func mouseUp(with event: NSEvent) {
       // super.mouseDown(with: event)
    }
}


var backgroundColor = NSColor(named: "backgroundColor") ?? NSColor.windowBackgroundColor
class customBoxBg:NSBox{
    //    override func draw(_ dirtyRect: NSRect) {

    override func draw(_ dirtyRect: NSRect) {
        // Make the pattern tile repeat from the top of the view.
        let yOffset = NSMaxY(self.convert(self.frame, to: nil))
        NSGraphicsContext.current?.patternPhase = NSMakePoint(0, yOffset)
        
        super.draw(dirtyRect)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.fillColor = backgroundColor
        //let image = #imageLiteral(resourceName: "background")
        //self.contentView?.backgroundcolor = NSColor(patternImage: image)
    }
}



class CustomImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool{
        return true
    }
}

//MARK: Custom Popover Background and Arrow
class PopoverContentView:NSView {
    var backgroundView:PopoverBackgroundView?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if SettingsManagerObject.isMenuPopoverEnabled{
            if let frameView = self.window?.contentView?.superview {
                if backgroundView == nil {
                    backgroundView = PopoverBackgroundView(frame: frameView.bounds)
                    backgroundView!.autoresizingMask = NSView.AutoresizingMask([.width, .height]);
                    frameView.addSubview(backgroundView!, positioned: NSWindow.OrderingMode.below, relativeTo: frameView)
                }
            }
        }else if backgroundView != nil{
            backgroundView?.removeFromSuperview()
            backgroundView = nil
        }
    }
}

class PopoverBackgroundView:NSView {
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.set()
        //  NSRectFill(self.bounds)
        bounds.fill()
        
    }
}



class PopoverContentViewForMenuTour:NSView {
    var backgroundView:PopoverBackgroundViewForMenuTour?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let frameView = self.window?.contentView?.superview {
            if backgroundView == nil {
                backgroundView = PopoverBackgroundViewForMenuTour(frame: frameView.bounds)
                backgroundView!.autoresizingMask = NSView.AutoresizingMask([.width, .height]);
                frameView.addSubview(backgroundView!, positioned: NSWindow.OrderingMode.below, relativeTo: frameView)
            }
        }
    }
}

class PopoverBackgroundViewForMenuTour:NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.set()
        //  NSRectFill(self.bounds)
        bounds.fill()
        
    }
}



//var headercolor = NSColor(red: 62/255, green: 70/255, blue: 106/255, alpha: 1)
class CustomScroller: NSScroller {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
        self.drawKnob()
    }
    
    override func drawKnob() {
        var knobSlot: NSRect = rect(for: .knob)
        let orientation = self.accessibilityOrientation()
        if orientation.rawValue == 2  {
            //Horizontal
            knobSlot.size.height = 20
            knobSlot.origin.y = 4
        } else {
            knobSlot.size.width = 7
            knobSlot.origin.x = 3
        }
        
        let path = NSBezierPath(roundedRect: knobSlot, xRadius: 5, yRadius: 5)
        NSColor.black.withAlphaComponent(0.5).set()
        path.fill()
    }
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        var newRect: NSRect = slotRect
        let orientation = self.accessibilityOrientation()
        
        if orientation.rawValue == 2 {
            newRect.origin.y = 4
        } else {
            newRect.origin.x = 3
        }
        super.drawKnobSlot(in: newRect, highlight: flag)
    }
    
}

class CustomScrollerForSettiings: NSScroller {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.tertiaryLabelColor.withAlphaComponent(0.1).set()
        dirtyRect.fill()
        self.drawKnob()
    }
    
    override func drawKnob() {
        var knobSlot: NSRect = rect(for: .knob)
        let orientation = self.accessibilityOrientation()
        if orientation.rawValue == 2  {
            //Horizontal
            knobSlot.size.height = 20
            knobSlot.origin.y = 4
        } else {
            knobSlot.size.width = 8
            knobSlot.origin.x = 3
        }
        
        let path = NSBezierPath(roundedRect: knobSlot, xRadius: 5, yRadius: 5)
        NSColor.secondaryLabelColor.set()
        path.fill()
    }
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        var newRect: NSRect = slotRect
        let orientation = self.accessibilityOrientation()
        
        if orientation.rawValue == 2 {
            newRect.origin.y = 4
        } else {
            newRect.origin.x = 3
        }
        super.drawKnobSlot(in: newRect, highlight: flag)
    }
    
}

class DraggableHorizontallyNudgeWindow: NSWindow {
    private var initialLocation: NSPoint = .zero
    var nudgeWindowDelegate:NudgeWindowDelegate?
    override func mouseDown(with event: NSEvent) {
        // Store the initial mouse location relative to window frame
        initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
//        guard let screen = screen else { return }
//
//        // Get current window frame
//        var windowFrame = frame
//
//        // Calculate new X position while keeping Y position fixed
//        let newX = windowFrame.origin.x + (event.locationInWindow.x - initialLocation.x)
//
//        // Ensure the window remains within screen bounds
//        let maxX = screen.visibleFrame.maxX - windowFrame.width
//        let minX = screen.visibleFrame.minX
//
//        windowFrame.origin.x = min(maxX, max(minX, newX))  // Clamp X position
//
//        // Apply new frame
//        setFrame(windowFrame, display: true, animate: false)
//        nudgeWindowDelegate?.nudgeDragged()
        isNudgeDraggedInCurrentFocusSession = true
    }
}


class BlinkingNSBox: NSBox {// 22/7/25  v 1.26.393
    private var blinkTimer: Timer?
    private let colors: [NSColor] = [NSColor(named: "dark_OrangeColor") ?? NSColor.blue, NSColor(red: 249/255, green: 233/255, blue: 142/255, alpha: 1)]
    private var currentColorIndex = 0
    private let blinkInterval: TimeInterval = 0.5
    private var windowObserver: NSKeyValueObservation?
    private var blinkCount = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.borderWidth = 2.0
        self.borderColor = colors.first!
    }
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopBlinking()
            }
        }
    }
    
    func startBlinking() {
        guard !isHidden, blinkTimer == nil else { return }
        self.borderColor = self.colors.last!
        blinkCount = 0
        currentColorIndex = 0
        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if blinkCount > 9{
                stopBlinking()
                return;
            }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = self.blinkInterval / 2
                self.currentColorIndex = (self.currentColorIndex + 1) % self.colors.count
                self.animator().borderColor = self.colors[self.currentColorIndex]
                self.blinkCount += 1
            }
        }
    }
    
    func stopBlinking() {
        guard blinkTimer != nil else { return }
        blinkTimer?.invalidate()
        blinkTimer = nil
        currentColorIndex = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = blinkInterval / 2
            self.animator().borderColor = self.colors.last!
        }
    }
    
    deinit {
        stopBlinking()
    }
}


class CustomTextField: NSTextField, NSTextViewDelegate {
    override func rightMouseDown(with event: NSEvent) {
        
    }
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        return nil
    }
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {

        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        return false
    }
}
class ignoreMouseTextField: NSTextField, NSTextViewDelegate {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class PasteView: NSTextView, NSTextViewDelegate {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func paste(_ sender: Any?) {
        Swift.print("user tries to paste")
        // super.pasteAsPlainText(nil)
    }
}
class CustomWindow: NSWindow {//bacause titleless window per textfield kaam ni kar rhi
    override var canBecomeKey: Bool{
        return true
    }
}




////////////////////////////////activation text field ///////////////////////////////////
class CustomTextFieldCell: NSTextFieldCell {
    
    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)
        
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight
        
        return titleRect
    }
    
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }
    
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
class Editing: NSTextField {
    
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}



// #MARK:- Check Internet connectivity
public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
        
    }
}


class PopoverAwareTextField: NSTextField, NSPopoverDelegate {// not in use
    
    var parentVcObj:rememberNextHabitVc?
    var itemsArr = [String]()
    var popoverViewControllerObj:PopoverViewController?// = PopoverViewController()
    var selectedItemId = -1
    
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = -1
            
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: itemsArr)
            popoverViewControllerObj!.tblView.reloadData()
            let range = self.currentEditor()?.selectedRange
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        }
        
        return super.becomeFirstResponder()
    }
    
    
    
    @objc func Close(){
        popoverViewControllerObj!.view.isHidden = true
    }
    
    override func keyUp(with theEvent: NSEvent) {
        
        if theEvent.keyCode == 53 || theEvent.keyCode == 48{//esc,tab
            super.keyUp(with: theEvent)
            popoverViewControllerObj?.view.isHidden = true
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{//enter
            if popoverViewControllerObj!.view.isHidden == false{
                popoverViewControllerObj!.doubleClicked()
            }else{
                
            }
            super.keyUp(with: theEvent)
            return
        }
        if theEvent.keyCode == 126{//// up key
            popoverViewControllerObj!.selectPrevious()
            return
        }
        if theEvent.keyCode == 125{//down key (go next)
            if popoverViewControllerObj!.view.isHidden == true{
                popoverViewControllerObj!.view.isHidden = false
            }else{
                popoverViewControllerObj!.selectNext()
            }
            return
        }
        self.complete(self)
        super.keyUp(with: theEvent)
    }
    
    override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        var matches = [String]()
        selectedItemId = -1
        if self.itemsArr.count != 0 {
            matches.removeAll()
            for result in self.itemsArr {
                if result.localizedStandardContains(self.stringValue){
                    matches.append(result)
                }
            }
            
        }
        
        if lengthOfWord == 0{
            matches = self.itemsArr
        }
        if matches.count > 0 {
            let range = self.currentEditor()?.selectedRange
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: matches)
            popoverViewControllerObj!.tblView.reloadData()
            
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        } else{
            popoverViewControllerObj!.view.isHidden = true
        }
    }
    
}
class PopoverAwareSearchField: NSSearchField, NSPopoverDelegate {
    
    var parentVcObj:settingsSideBarVc?
    var itemsArr = [[String:Any]]()
    var popoverViewControllerObj:PopoverViewControllerForSearch?// = PopoverViewController()
    var selectedItemId = ""
    
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = ""
            
            
            //            self.superview?.addSubview(popoverViewControllerObj.view)
            //            addConstraints()
            //            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)
            popoverViewControllerObj!.view.isHidden = true
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: itemsArr)
            popoverViewControllerObj!.tblView.reloadData()
            let range = self.currentEditor()?.selectedRange
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        }
        
        return super.becomeFirstResponder()
    }
    
    
    @objc func Close(){
        popoverViewControllerObj!.view.isHidden = true
    }
    
    override func keyUp(with theEvent: NSEvent) {
        
        if theEvent.keyCode == 53 || theEvent.keyCode == 48{//esc,tab
            super.keyUp(with: theEvent)
            popoverViewControllerObj?.view.isHidden = true
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{//enter
            if popoverViewControllerObj!.view.isHidden == false{
                popoverViewControllerObj!.doubleClicked()
            }else{
                
            }
            super.keyUp(with: theEvent)
            return
        }
        if theEvent.keyCode == 126{//// up key
            popoverViewControllerObj!.selectPrevious()
            return
        }
        if theEvent.keyCode == 125{//down key (go next)
            if popoverViewControllerObj!.view.isHidden == true{
                popoverViewControllerObj!.view.isHidden = false
            }else{
                popoverViewControllerObj!.selectNext()
            }
            return
        }
        self.complete(self)
        super.keyUp(with: theEvent)
    }
    
    override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        if lengthOfWord == 0{
            popoverViewControllerObj!.view.isHidden = true
            return;
        }
        var matches = [[String:Any]]()
        selectedItemId = ""
        if self.itemsArr.count != 0 {
            matches.removeAll()
            for result in self.itemsArr {
                if ((result)["title"] as? String ?? "").localizedStandardContains(self.stringValue){
                    matches.append(result)
                }
            }
            
        }
        
        if lengthOfWord == 0{
            matches = self.itemsArr
        }
        if matches.count > 0 {
            let range = self.currentEditor()?.selectedRange
            //            popover.show(relativeTo: self.frame, of: self, preferredEdge: .maxY)
            //            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)//////
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: matches)
            popoverViewControllerObj!.tblView.reloadData()
            
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        } else{
            //            popover.close()/////
            popoverViewControllerObj!.view.isHidden = true
        }
    }
    
}



//*******************CUSTOM SLIDER CLASS ******************//

class CustomSliderCell: NSSliderCell {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = aRect.height
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.lightGray.setFill()
        bg.fill()
    }
}
class CustomSlider: NSSlider {
    init() {
        super.init(frame: NSZeroRect)
        addFilter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addFilter()
    }
    
    func addFilter() {
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(CIColor(cgColor: NSColor.lightGray.cgColor), forKey: "inputColor1")
        self.contentFilters = [colorFilter]
    }
}
//------------------------------------------------------------------------//



//--------------------------------custom New Item Badge Box----------------------------//

class customNewBadgeBox: NSBox {
    var mouseDown = false
    var tagValue = 0
    var isTableView = false
    var label:NSTextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.boxType = .custom
        self.borderWidth = 0
        self.cornerRadius = self.frame.height / 2
        self.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        var newBadgeText = "New"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            newBadgeText = common.value(forKey: "newBadgeText") as? String ?? newBadgeText
        }
        label = NSTextField(string: newBadgeText)
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = NSColor.black
        label.isEditable = false
        label.isSelectable = false
        self.addSubview(label)
        self.addVerticalCenterConstraints(subView: label)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseDown(with event: NSEvent) {
        // super.mouseDown(with: event)
        print("mouse down")
        if isTableView{
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }else{
            super.mouseDown(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouse up")
        if mouseDown {
            mouseDown = false
            
            NSCursor.pointingHand.set()
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }else{
            return;
        }
    }
    

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}
//--------------------------------Onboarding Progress----------------------------//



class customStatusBarBox: NSBox {
    var count = 0
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if count == 0{
            count = 1
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if isPurchased == false && daysLeft <= 0{
            return;
        }
        if !SettingsManagerObject.isGeekModeEnabled{
            return;
        }
        if appdelegate?.popover.isShown ?? false{
            return;
        }
        
        if !NSEvent.modifierFlags.contains(.control){
            return;
        }
        getBlankLayerWcObject().showWindow(nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
    }
}



class customStatusBarBoxForTooltip: NSBox {
    var count = 0
    var customToolTip = ""
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if count == 0{
            count = 1
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        }
    }
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if appdelegate?.popover.isShown ?? false{
            return;
        }
        if !self.customToolTip.isEmpty{
            showTooltip(sender: self, msg: customToolTip, preferredEdge: .minY, maxWidthVal: 300)
        }else if appdelegate!.isUserOnMeeting{
            if !SettingsManagerObject.IsShowBreaksInCallEnabled{
                var toolTipMeetingsText = "We've detected that you're in a video call and won't show breaks during this time"
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    toolTipMeetingsText = common.value(forKey: "toolTipMeetingsText") as? String ?? toolTipMeetingsText
                }
                showTooltip(sender: self, msg: toolTipMeetingsText, preferredEdge: .minY, maxWidthVal: 300)
            }
        }else{
            print("customToolTip is blank")
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if popoverTooltip != nil{
            if popoverTooltip!.isShown{
                popoverTooltip?.close()
            }
        }
    }
}


class cursorSegmentedControl: NSSegmentedControl {
    
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


class shadowScrollViewForTextView: NSScrollView {
    
    var shadowOpacity:Float = 0.3
    var shadowOffset: CGSize = NSMakeSize(0, 5)
    var shadowRadius: CGFloat = 5
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setShadow()
    }
    
    func setShadow(){
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = shadowOpacity
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = shadowOffset
        self.layer?.shadowRadius = shadowRadius
    }
}

class shadowView: NSBox {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, -2)
        self.layer?.shadowRadius = 3
    }
}

class shadowTextField: NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, 2)
        self.layer?.shadowRadius = 3
    }
    
    
}

class menuItemLabel: NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textColor = NSColor.black//buttonTitleColor
        
    }
}

class shadowSecureTextField: NSSecureTextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, 2)
        self.layer?.shadowRadius = 3
    }
    
    
}


class GeekModeSegmentedControl: NSSegmentedControl {

    var segmentGeekModeTrackingArea: NSTrackingArea?
    let geekModeIndex = 0
    let simpleModeIndex = 1
    var isMenuButton = false
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectedSegmentBezelColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        var titleGeekMode = "🤓 Geek Mode"
        var titleSimpleMode = "😎 Simple Mode"
        
        if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
            titleGeekMode = geekModeInfo.value(forKey: "titleGeekMode") as? String ?? titleGeekMode
            titleSimpleMode = geekModeInfo.value(forKey: "titleSimpleMode") as? String ?? titleSimpleMode
        }
        self.setLabel(titleGeekMode, forSegment: geekModeIndex)
        self.setLabel(titleSimpleMode, forSegment: simpleModeIndex)
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        segmentGeekModeTrackingArea = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(segmentGeekModeTrackingArea!)
        
        
        let customBox = NSBox()
        customBox.boxType = .custom
        customBox.borderWidth = 0
        customBox.fillColor = NSColor.clear
        self.superview?.addSubview(customBox)
//        self.addConstraints(subView: customBox)
        
        
        customBox.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: customBox, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: customBox, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
        let bottom = NSLayoutConstraint(item: customBox, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let height = NSLayoutConstraint(item: customBox, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.superview?.addConstraint(trailing)
        self.superview?.addConstraint(bottom)
        self.superview?.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
        self.superview?.addConstraint(height)
        
    }

    
    override func mouseEntered(with event: NSEvent) {
        if SettingsManagerObject.isGeekModeEnabled{
            var tooltipGeekMode = "Geek Mode active! Advanced features activated. Overwhelmed? Toggle the switch to go back to Simple Mode"
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                tooltipGeekMode = geekModeInfo.value(forKey: "tooltipGeekMode") as? String ?? tooltipGeekMode
            }
            showTooltip(sender: self, msg: tooltipGeekMode, preferredEdge: NSRectEdge.minX, maxWidthVal:230)
        }else{
            var tooltipSimpleMode = "Simple Mode active - only basic features shown. Toggle the switch to activate Geek Mode"
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                tooltipSimpleMode = geekModeInfo.value(forKey: "tooltipSimpleMode") as? String ?? tooltipSimpleMode
            }
            showTooltip(sender: self, msg: tooltipSimpleMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == segmentGeekModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
        NSCursor.arrow.set()
    }
    
    func changeAppModeTo(geekMode:Bool){
        //--------------------------------------------------------------------//
        //Support freemium#1066
        //only simple mode allowed
        addLog(text:"func changeAppModeTo geekMode \(geekMode)")
        if isExpired && geekMode{
            var titleNoGeekMode = "Geek mode is only supported in Pro edition."
            if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                titleNoGeekMode = upgradeToProNagVcInfo.value(forKey: "titleNoGeekMode") as? String ?? titleNoGeekMode
            }
            showUpgradeToProNagWindow(titleText: titleNoGeekMode, reason: "activate_geek_mode")
            if SettingsManagerObject.isGeekModeEnabled{
                self.setSelected(true, forSegment: 0)
            }else{
                self.setSelected(true, forSegment: 1)
            }
            return;
        }
        //-----------------------------------------------------------------------//
        if SettingsManagerObject.isGeekModeEnabled == geekMode{
            return;
        }
        
        if geekMode{
            let dontShowGeekModeConfirmAlert = UserDefaults.standard.object(forKey: kUserdefaultsDontShowConfirmGeekModeAlert) as? Bool ?? false
            if !dontShowGeekModeConfirmAlert{
                allApiObject.capturePosthog(event: "waiting-to-confirm-wants-to-switch-to-geek-mode", metadata: [:])
                
                var alertConfirmSwitchGeekMode = "Geek Mode activates a lot more features and can be overwhelming. We recommend you stick with Simple Mode for the first few days."
                var buttonActivateGeekModeText = "Activate Geek Mode"
                var buttonStickSimpleModeText = "Stick with Simple Mode"
                var buttonDontShowAgainText = "Don't show again"
                var alertConfirmSwitchGeekModeDescription = "You can switch the modes from Preferences -> Settings tab"
                
                if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                    alertConfirmSwitchGeekMode = geekModeInfo.value(forKey: "alertConfirmSwitchGeekMode") as? String ?? alertConfirmSwitchGeekMode
                    buttonActivateGeekModeText = geekModeInfo.value(forKey: "buttonActivateGeekModeText") as? String ?? buttonActivateGeekModeText
                    buttonStickSimpleModeText = geekModeInfo.value(forKey: "buttonStickSimpleModeText") as? String ?? buttonStickSimpleModeText
                    buttonDontShowAgainText = geekModeInfo.value(forKey: "buttonDontShowAgainText") as? String ?? buttonDontShowAgainText
                    alertConfirmSwitchGeekModeDescription = geekModeInfo.value(forKey: "alertConfirmSwitchGeekModeDescription") as? String ?? alertConfirmSwitchGeekModeDescription
                }
            
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = alertConfirmSwitchGeekMode
                if isMenuButton{
                    alert.informativeText = alertConfirmSwitchGeekModeDescription
                }
                alert.addButton(withTitle: buttonStickSimpleModeText)
                alert.addButton(withTitle: buttonActivateGeekModeText)
                
                alert.showsSuppressionButton = true
                alert.suppressionButton?.title = buttonDontShowAgainText
                NSApplication.shared.activate(ignoringOtherApps: true)
                let result = alert.runModal()
                if result == .alertFirstButtonReturn{
                    self.setSelected(true, forSegment: 1)
                    allApiObject.capturePosthog(event: "stick-to-simple-mode", metadata: [:])
                }else if result == .alertSecondButtonReturn{
                    SettingsManagerObject.isGeekModeEnabled = geekMode
                    appModeChangeDone(geekMode: geekMode)
                }
                if alert.suppressionButton?.state == .on{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsDontShowConfirmGeekModeAlert)
                }
            }else{
                SettingsManagerObject.isGeekModeEnabled = geekMode
                appModeChangeDone(geekMode: geekMode)
            }
        }else{
            SettingsManagerObject.isGeekModeEnabled = geekMode
            appModeChangeDone(geekMode: geekMode)
        }
    }
    
    func appModeChangeDone(geekMode:Bool){
        if !geekMode{
            SettingsManagerObject.isCuddlyModeEnabled = true
        }else{
            // doing this because in simple mode when user start a pomodoro mode with blocking style (AI) we change local var isAiCheckUrlEnabled to true and if user starts pomodoro with blockDistractingsites/apps focus mode we change isAiCheckUrlEnabled to false but doesn't upload it so when user change app mode to geek mode we need to reload this setting from userdefaults
            if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAiCheckUrlEnabled) as? Bool{
                SettingsManagerObject.isAiCheckUrlEnabled = isEnabled
            }
        }
        SettingsManagerObject.isSettingsChanged = true
        
        if isFocusBearMenuVisible(){
            menuViewControllerObj?.reloadData()
        }
        if SettingsManagerObject.isGeekModeEnabled{
            preferencesSettingsIndex = 3
            preferencesEditHabitsIndex = 4
            preferencesBlocksIndex = 2
//            leftMenuVcObj?.boxFocusModeSettings.isHidden = false
        }else{
            preferencesSettingsIndex = 2
            preferencesEditHabitsIndex = 3
            preferencesBlocksIndex = 1
//            leftMenuVcObj?.boxFocusModeSettings.isHidden = true
        }

        if leftMenuVcObj?.boxSettings.isSelected ?? false{
            settingsSideBarVcObj?.reloadDataForAppMode()
            if geekMode{
                settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: geekModeIndex)
            }else{
                settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: simpleModeIndex)
            }
            
            let selectedRow = settingsSideBarVcObj?.tblView.selectedRow ?? 0
            let arrSettingsList = settingsSideBarVcObj?.arrSettingsList ?? []
            let id = arrSettingsList[selectedRow]["id"] as? String ?? ""
            
            switch id {
            case idUi:
                uIVcObj?.reloadDataForAppMode()
            case idAccesibility:
                break;
            case idAi:
                break;
            case idPomodoro:
                break;
            case idStrictness:
                strictnessVcObj?.reloadDataForAppMode()
            case idAdvanced:
                break;
            case idAccount:
                break;
            case idUninstall:
                break;
            case idPermissions:
                break;
            default:
                break;
            }
        }
        
        if SettingsManagerObject.isGeekModeEnabled{
            allApiObject.capturePosthog(event: "switch-to-geek-mode", metadata: [:])
        }else{
            allApiObject.capturePosthog(event: "switch-to-simple-mode", metadata: [:])
        }
        
        if !geekMode{
            var msg = "Simple Mode active - only basic features shown. Focus modes, pomodoros etc. are no longer available. Toggle the switch to go back to Geek Mode."
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                msg = geekModeInfo.value(forKey: "alertSimpleModeEnabled") as? String ?? msg
            }
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = msg
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}


protocol toggleButtonBoxDelegate {
    func toggleButtonBoxClicked(box:NSBox)
}
class toggleButtonBox: NSBox {
    var mouseDown = false
    var isSelected = false
    var customDelegate: toggleButtonBoxDelegate?
    var normalColor = NSColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.fillColor = buttonBgColor
        NSCursor.pointingHand.set()
    }
    override func mouseDown(with event: NSEvent) {
        // super.mouseDown(with: event)
        print("mouse down")
        mouseDown = true
        self.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        NSCursor.pointingHand.set()
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouse up")
        if mouseDown {
            mouseDown = false
            NSCursor.pointingHand.set()
            self.fillColor = buttonBgColor
            self.isSelected = true
            self.borderWidth = 1
            self.borderColor = .separatorColor
            customDelegate?.toggleButtonBoxClicked(box:self)
        }

    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        mouseDown = false
        NSCursor.arrow.set()
        if !isSelected{
            self.fillColor = normalColor
        }
    }
}


//------------------------------------------------------------------//
//if the user has non timer based habits, add an estimate based on how long they spent on the habits the last few times

class NonTimerBasedHabit:NSObject {
    var arrNonTimerBasedHabitsDurations = [String:[Int]]()
    
    func addDurationForHabit(id:String, duration:Int){
        var arrDurations = [Int]()
        if let arrOldDurations = arrNonTimerBasedHabitsDurations[id]{
            arrDurations = arrOldDurations
        }
        arrDurations.append(duration)
        if arrDurations.count > 10{
            arrDurations.remove(at: 0)
        }
        arrNonTimerBasedHabitsDurations[id] = arrDurations
        writeNonTimerBasedHabitsDurations()
    }

    func writeNonTimerBasedHabitsDurations(){
        let plistContent = NSDictionary(dictionary: arrNonTimerBasedHabitsDurations)
        let _ = plistContent.write(toFile: arrNonTimerBasedHabitsDurationsPlistFileUrl!.path, atomically: true)
    }

    func readNonTimerBasedHabitsDurations(){
        if let data = try? Data(contentsOf: arrNonTimerBasedHabitsDurationsPlistFileUrl) {
            if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [Int]] { // [String: Any] which ever it is
                print(result)
                arrNonTimerBasedHabitsDurations = result
            }
        }
        print(arrNonTimerBasedHabitsDurations)
    }
}




