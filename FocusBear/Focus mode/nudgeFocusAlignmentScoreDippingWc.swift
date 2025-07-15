//
//  nudgeFocusAlignmentScoreDippingWc.swift
//  Desktop Widget
//
//  Created by Prashant Sawnani on 22/11/24.
//

import Cocoa
var nudgeFocusAlignmentScoreDippingWcObject:nudgeFocusAlignmentScoreDippingWc?
class nudgeFocusAlignmentScoreDippingWc: NSWindowController, NudgeWindowDelegate {
    var isNudgeVisible = false
    private var isNudgeMoving = false
//    let menuWidth: CGFloat = 430
    private let animationDuration: TimeInterval = 100

    init() {
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let viewFrame = getNudgeFocusAlignmentScoreDippingVcObject().view.frame
        
//        var xPoint = screenFrame.width - (viewFrame.width + 50)
//        if let savedXPoint = UserDefaults.standard.object(forKey: kUserDefaultsLastNudgeScoreWindowXPoisition) as? CGFloat{
//            xPoint = savedXPoint
//        }
        
        let windowFrame = NSRect(
            x: screenFrame.width - (viewFrame.width + 50), // Start off-screen
            y: 0 - (viewFrame.height),
            width: viewFrame.width,
            height: viewFrame.height
        )
        
        let window = DraggableHorizontallyNudgeWindow(
            contentRect: windowFrame,
            styleMask: [.nonactivatingPanel, .titled],
            backing: .buffered,
            defer: false
        )
        
        window.title = ""
        window.level = .statusBar
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = NSColor.clear
        window.makeKeyAndOrderFront(nil)
        window.styleMask = .borderless
        
        window.collectionBehavior = .stationary // prevent from expose desktop under mission control

        
        super.init(window: window)
        
        
        window.nudgeWindowDelegate = self
        setupWindow()
    }

    func nudgeDragged() {
        // save nudge last drag location x point
//        let xPoint = self.window?.frame.minX ?? 0
//        UserDefaults.standard.set(xPoint, forKey: kUserDefaultsLastNudgeScoreWindowXPoisition)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        // Additional setup can go here
        self.contentViewController = getNudgeFocusAlignmentScoreDippingVcObject()
    }
    
    func toggleMenu() {
        if isNudgeMoving{
            return;
        }
        guard self.window != nil else { return }
        let screenFrame = NSScreen.main?.frame ?? NSRect.zero
        let viewFrame = getNudgeFocusAlignmentScoreDippingVcObject().view.frame
        
        let targetY = isNudgeVisible ? (0 - viewFrame.height) : 0
        moveWindowManually(window: self.window!, to: NSPoint(x: self.window?.frame.minX ?? screenFrame.width - (viewFrame.width + 50), y: targetY), duration: 0.15)
    }
    
    func moveWindowManually(window: NSWindow, to newPosition: NSPoint, duration: TimeInterval) {
        guard let currentFrame = window.frame as NSRect? else { return }
        isNudgeMoving = true
        let startX = currentFrame.origin.x
        let startY = currentFrame.origin.y
        let targetX = newPosition.x
        let targetY = newPosition.y
        
        let totalFrames = Int(60 * duration) // Assuming 60 FPS
        var currentFrameIndex = 0

        let deltaX = (targetX - startX) / CGFloat(totalFrames)
        let deltaY = (targetY - startY) / CGFloat(totalFrames)
        if !self.isNudgeVisible{
            self.window?.alphaValue = 1
        }
        if isNudgeDraggedInCurrentFocusSession{
            self.isNudgeVisible.toggle()
            self.isNudgeMoving = false
            if !self.isNudgeVisible{
                self.window?.alphaValue = 0
            }else{
                self.window?.alphaValue = 1
            }
            return;
        }
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            if currentFrameIndex >= totalFrames {
                timer.invalidate()
                self.isNudgeVisible.toggle()
                self.isNudgeMoving = false
                if !self.isNudgeVisible{
                    self.window?.alphaValue = 0
                }else{
                    self.window?.alphaValue = 1
                }
            } else {
                currentFrameIndex += 1
                let newX = startX + deltaX * CGFloat(currentFrameIndex)
                let newY = startY + deltaY * CGFloat(currentFrameIndex)
                window.setFrameOrigin(NSPoint(x: newX, y: newY))
            }
        }
        
        RunLoop.current.add(timer, forMode: .common)
    }
}
