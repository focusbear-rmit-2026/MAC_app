//
//  blankLayerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/03/24.
//

import Cocoa

class blankLayerVc: NSViewController {

    @IBOutlet weak var lblTitleDueDate: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblDays: NSTextField!
    @IBOutlet weak var boxBlue: NSBox!
    @IBOutlet weak var boxSmallTop: NSBox!
    @IBOutlet weak var draggableView: draggableView!
    @IBOutlet weak var lblDuration: NSTextField!
    @IBOutlet weak var boxTimeEntry: NSBox!
    @IBOutlet weak var boxYConstraints: NSLayoutConstraint!
    @IBOutlet weak var boxXConstraints: NSLayoutConstraint!
 
    @IBOutlet weak var leadingBox: NSLayoutConstraint!
    @IBOutlet weak var heightBox: NSLayoutConstraint!
    
    @IBOutlet weak var topBox: NSLayoutConstraint!
    @IBOutlet weak var widthBox: NSLayoutConstraint!
    var trackingArea:NSTrackingArea?
    var titleDay = "(<NUMBER> Day)"
    var titleDays = "(<NUMBER> Days)"
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Create a task"
        lblTitleDueDate.stringValue = "With due date"
        blankLayerVcObj = self
        boxTimeEntry.isHidden = true
        boxBlue.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        
        if let createTaskVcInfo = configjson.value(forKey: "createTaskVcInfo") as? NSDictionary{
            lblTitle.stringValue = createTaskVcInfo.value(forKey: "titleCreateTask") as? String ?? lblTitle.stringValue
            lblTitleDueDate.stringValue = createTaskVcInfo.value(forKey: "titleWithDueDate") as? String ?? lblTitleDueDate.stringValue
            titleDay = createTaskVcInfo.value(forKey: "titleDay") as? String ?? titleDay
            titleDays = createTaskVcInfo.value(forKey: "titleDays") as? String ?? titleDays
        }
    }

    override func viewWillAppear() {
        boxForStatusBar.borderWidth = 1
//        appdelegate!.statusbutton?.image = NSImage(named: NSImage.Name("blankImage"))
    }
    override func viewWillDisappear() {
        boxForStatusBar.borderWidth = 0
//        setFocusBearIconToNormal()
    }
    override func viewDidAppear() {
        if let frame = appdelegate?.statusbutton?.window?.frame{
            let leading = (frame.minX - (self.view.window?.frame.minX ?? 0))
            print("status button window frame")
            print(frame)
            leadingBox.constant = leading + boxForStatusBar.frame.minX
            widthBox.constant = statusBarBoxHeightWidth
            heightBox.constant = statusBarBoxHeightWidth
            topBox.constant = ((frame.height - statusBarBoxHeightWidth) / 2)
        }
        boxSmallTop.isHidden = false
        if self.trackingArea != nil{
            if self.boxSmallTop.trackingAreas.contains(self.trackingArea!){
                self.boxSmallTop.removeTrackingArea(self.trackingArea!)
            }
        }
        
        trackingArea = NSTrackingArea.init(rect: self.boxSmallTop.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.boxSmallTop.addTrackingArea(trackingArea!)
        
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
    }
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if !self.draggableView.isMouseDraged{
            self.view.window?.close()
        }
    }
    

}

var statusBarBoxHeightWidth:CGFloat = 22
var leadingStatusBarBox:CGFloat = 8


class draggableView:NSView{
    var isMouseDown = false
    var isMouseDraged = false
    var mouseDownLocation:NSPoint?
    var mouseDraggedLocation:NSPoint?
    var lastDate = Date()
    var lastDistance:Float = 0
    var smallBox:NSBox?
    override class func awakeFromNib() {
        
    }

    
    override func mouseDown(with event: NSEvent) {
        if appdelegate?.popover.isShown ?? false{
            blankLayerWcObj?.window?.close()
            print("return")
            return;
        }
        
        if let frame = appdelegate?.statusbutton?.window?.frame{
            if !frame.contains(NSEvent.mouseLocation){
                blankLayerWcObj?.window?.close()
            }
        }
        super.mouseDown(with: event)
        if smallBox == nil{
            smallBox = NSBox()
            smallBox?.boxType = .custom
            smallBox?.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
            smallBox?.borderWidth = 0
            smallBox?.cornerRadius = 8
            smallBox?.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
            self.addSubview(smallBox!)
        }
        isMouseDown = true
        isMouseDraged = false
        mouseDownLocation = event.locationInWindow
        smallBox?.isHidden = true
    }
    
    func restSmallView(){
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouseUp")
        if appdelegate?.popover.isShown ?? false{
            blankLayerWcObj?.window?.close()
            return;
        }
        if isMouseDraged{
            blankLayerWcObj?.window?.close()
            if lastDistance >= 40{
                showCreateTaskWindow(dueDate: lastDate)
            }
            
        }else{
            appdelegate?.showPopover()
            blankLayerWcObj?.window?.close()
        }
        isMouseDown = false
        isMouseDraged = false
        self.setNeedsDisplay(self.frame)
        blankLayerVcObj?.boxTimeEntry.isHidden = true
        smallBox?.isHidden = true
        blankLayerVcObj?.boxSmallTop.isHidden = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        print("mouseDragged")
        mouseDraggedLocation = event.locationInWindow
        smallBox?.setFrameOrigin(NSPoint(x: mouseDraggedLocation!.x - 8, y: mouseDraggedLocation!.y - 8))
        isMouseDraged = true
        smallBox?.isHidden = false
        blankLayerVcObj?.boxTimeEntry.isHidden = false
        blankLayerVcObj?.boxXConstraints.constant = mouseDraggedLocation!.x - blankLayerVcObj!.boxTimeEntry.frame.width
        blankLayerVcObj?.boxYConstraints.constant = mouseDraggedLocation!.y - blankLayerVcObj!.boxTimeEntry.frame.height
        
        var duration = 0
        let distance = hypotf(Float(mouseDownLocation!.x - mouseDraggedLocation!.x), Float(mouseDraggedLocation!.y - mouseDownLocation!.y))
        print(distance)
        
        lastDistance = distance
        if distance >= 40{
            blankLayerVcObj?.boxTimeEntry.isHidden = false
            if distance < 110{
                duration = Int((distance - 40) * 4000)
            }else if distance < 220{
                duration = Int((distance - 40) * 4500)
            }else if distance < 330{
                duration = Int((distance - 40) * 4800)
            }else{
                duration = Int((distance - 40) * 5000)
            }
            
        }else{
            blankLayerVcObj?.boxTimeEntry.isHidden = true
        }
        let currentDate = Date()
        lastDate = currentDate.addingTimeInterval(TimeInterval(duration))
        blankLayerVcObj?.lblDuration.stringValue = getStringFromDate(date: lastDate, dateFormat: "yyyy-MM-dd")
        let morningTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: currentDate) ?? currentDate
        let diffDays = Calendar.current.dateComponents([.day], from: morningTime, to: lastDate).day ?? 0
        if diffDays == 1{
            blankLayerVcObj?.lblDays.stringValue = blankLayerVcObj?.titleDay.replacingOccurrences(of: "<NUMBER>", with: "\(diffDays)") ?? "(\(diffDays) Day)"
        }else{
            blankLayerVcObj?.lblDays.stringValue = blankLayerVcObj?.titleDays.replacingOccurrences(of: "<NUMBER>", with: "\(diffDays)") ?? "(\(diffDays) Days)"
        }
        self.setNeedsDisplay(self.frame)
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawLine()
    }
    
    func drawLine(){
        if isMouseDown && isMouseDraged{
            let path = NSBezierPath()
            path.move(to: NSPoint(x: blankLayerVcObj!.boxSmallTop.frame.midX, y: blankLayerVcObj!.boxSmallTop.frame.midY))
            path.line(to: mouseDraggedLocation!)
            path.close()
            (NSColor(named: "dark_OrangeColor") ?? NSColor.blue).set()
            path.lineWidth = 3
            path.stroke()
        }
    }
}
