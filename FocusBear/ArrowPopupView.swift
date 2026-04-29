//
//  ArrowPopupView.swift
//  FocusBear
//
//  Created by Manish Jain on 24/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

enum ArrowDirection {
    case left, right, top, bottom
}
// Add a weak reference to prevent memory leaks and allow multiple popups
class PopupManager {
    private static var activePopups: [BubbleView] = []
    
    static func showPopup(for targetView: NSView, edge: NSRectEdge, selfView: NSView, text: String, verticalOffset: CGFloat = 0, horizontalOffset: CGFloat = 0, fontSize:CGFloat = 18, width: CGFloat = 240, image: NSImage? = nil)-> BubbleView {
        // Optionally remove old popups targeting the same view
        //activePopups.removeAll { $0.superview == nil }
        
        let bubble = BubbleView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.popupText = text
        
        selfView.addSubview(bubble)
        activePopups.append(bubble)
        
        // Show with animation
        bubble.showWithAnimation()
        
        setupPopup(bubble, for: targetView, edge: edge, selfView: selfView, text: text, verticalOffset: verticalOffset, horizontalOffset: horizontalOffset, fontSize: fontSize, width: width, image: image)
        
        return bubble
    }
    
    static func dismissAllPopups() {
        activePopups.forEach { $0.removeFromSuperview() }
        activePopups.removeAll()
    }
    
    private static func setupPopup(_ bubble: BubbleView, for targetView: NSView, edge: NSRectEdge, selfView: NSView, text: String, verticalOffset: CGFloat = 0, horizontalOffset: CGFloat = 0, fontSize:CGFloat = 18, width: CGFloat = 240, image: NSImage? = nil) {
        let spacing: CGFloat = 8
        
        // Set direction
        bubble.direction = directionForEdge(edge)
        
        // Setup constraints
        var constraints: [NSLayoutConstraint] = [
            bubble.widthAnchor.constraint(equalToConstant: width)
        ]
        
        constraints += positionConstraints(for: bubble, targetView: targetView, edge: edge, spacing: spacing, verticalOffset: verticalOffset, horizontalOffset:horizontalOffset)
        NSLayoutConstraint.activate(constraints)
        
        // Add and setup label
        setupContent(in: bubble, text: text, fontSize: fontSize, image: image)
    }
    
    private static func positionConstraints(for bubble: BubbleView, targetView: NSView,
                                            edge: NSRectEdge, spacing: CGFloat,
                                            verticalOffset: CGFloat = 0,
                                            horizontalOffset: CGFloat = 0) -> [NSLayoutConstraint] {
        switch edge {
        case .maxX: // right side
            return [
                bubble.leadingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: spacing + horizontalOffset),
                bubble.centerYAnchor.constraint(equalTo: targetView.centerYAnchor, constant: verticalOffset)
            ]
        case .minX: // left side
            return [
                bubble.trailingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: -spacing + horizontalOffset),
                bubble.centerYAnchor.constraint(equalTo: targetView.centerYAnchor, constant: verticalOffset)
            ]
        case .maxY: // top
            return [
                bubble.bottomAnchor.constraint(equalTo: targetView.topAnchor, constant: -bubble.tailHeight + verticalOffset),
                bubble.centerXAnchor.constraint(equalTo: targetView.centerXAnchor, constant: horizontalOffset)
            ]
        case .minY: // bottom
            return [
                bubble.topAnchor.constraint(equalTo: targetView.bottomAnchor, constant: bubble.tailHeight + verticalOffset),
                bubble.centerXAnchor.constraint(equalTo: targetView.centerXAnchor, constant: horizontalOffset)
            ]
        default:
            return []
        }
    }
    
    private static func directionForEdge(_ edge: NSRectEdge) -> ArrowDirection {
        switch edge {
        case .minX: return .right
        case .maxX: return .left
        case .minY: return .top
        case .maxY: return .bottom
        @unknown default: return .right
        }
    }
    
    private static func positionConstraints(for bubble: BubbleView, targetView: NSView,
                                            edge: NSRectEdge, spacing: CGFloat) -> [NSLayoutConstraint] {
        switch edge {
        case .maxX: // right
            return [
                bubble.leadingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: spacing),
                bubble.centerYAnchor.constraint(equalTo: targetView.centerYAnchor)
            ]
        case .minX: // left
            return [
                bubble.trailingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: -spacing),
                bubble.centerYAnchor.constraint(equalTo: targetView.centerYAnchor)
            ]
        case .maxY: // top
            return [
                bubble.bottomAnchor.constraint(equalTo: targetView.topAnchor, constant: -bubble.tailHeight),
                bubble.centerXAnchor.constraint(equalTo: targetView.centerXAnchor)
            ]
        case .minY: // bottom
            return [
                bubble.topAnchor.constraint(equalTo: targetView.bottomAnchor, constant: bubble.tailHeight),
                bubble.centerXAnchor.constraint(equalTo: targetView.centerXAnchor)
            ]
        default:
            return []
        }
    }
    
    private static func setupLabel(in bubble: BubbleView, with text: String, fontSize:CGFloat = 18) {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        label.textColor = .black
        label.alignment = .center
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        
        bubble.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let padding = calculatePadding(for: bubble.direction)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: padding.left),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -padding.right),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: padding.top),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -padding.bottom)
        ])
        
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private static func setupContent(in bubble: BubbleView, text: String, fontSize: CGFloat = 18, image: NSImage? = nil) {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 15

        
        // Label
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        label.textColor = .black
        label.alignment = .center
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        label.isSelectable = false
        
        
        // Image (if provided)
        if let image = image {
            let imageView = NSImageView(image: image)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
            stackView.addArrangedSubview(imageView)
            
            // if image is added then label will be left align
            label.alignment = .left
        }

        

        stackView.addArrangedSubview(label)

        bubble.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let padding = calculatePadding(for: bubble.direction)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: padding.left),
            stackView.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -padding.right),
            stackView.topAnchor.constraint(equalTo: bubble.topAnchor, constant: padding.top),
            stackView.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -padding.bottom)
        ])

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private static func calculatePadding(for direction: ArrowDirection) -> (top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        let padding: CGFloat = 20
        let tailWidth: CGFloat = 22
        
        switch direction {
        case .right:
            return (padding, padding, padding, padding + tailWidth)
        case .left:
            return (padding, padding, padding + tailWidth, padding)
        case .top:
            return (padding, padding + tailWidth, padding, padding)
        case .bottom:
            return (padding + tailWidth, padding, padding, padding)
        }
    }
    
    private static func setupDismissGesture(for bubble: BubbleView, in view: NSView) {
        // Dismiss when clicking outside
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(dismissPopup(_:)))
        clickGesture.delegate = bubble
        view.window?.contentView?.addGestureRecognizer(clickGesture)
        
        // Auto-dismiss after 3 seconds
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        //            bubble.removeFromSuperview()
        //        }
    }
    
    @objc private func dismissPopup(_ gesture: NSClickGestureRecognizer) {
        // Implementation to find and dismiss the clicked popup
    }
}

class BubbleView: NSView, NSGestureRecognizerDelegate {
    var direction: ArrowDirection = .right
    let radius: CGFloat = 24
    let tailWidth: CGFloat = 22
    let tailHeight: CGFloat = 24
    var popupText: String = ""
    
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
        updateShadowProperties()
    }
    
    
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }
    
    
    @objc private func updateAppearance() {
        // Reapply shadow properties when appearance changes
        updateShadowProperties()
        // Force a redraw if needed
        needsDisplay = true
    }
    
    private func updateShadowProperties() {
        guard let layer = layer else { return }
        
        // Update shadow properties
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: -2)
        
        // Update shadow path if bounds are valid
        if bounds != .zero {
            layer.shadowPath = bubblePath()
        }
    }
    
    override func layout() {
        super.layout()
        updateShadowPath()
    }
    
    private func updateShadowPath() {
        guard let layer = layer, bounds != .zero else { return }
        layer.shadowPath = bubblePath()
    }
    
    
    private func bubblePath() -> CGPath {
        let rect = bounds
        let path = CGMutablePath()
        
        let midX = rect.midX
        let midY = rect.midY
        
        var bubbleRect = rect
        
        switch direction {
        case .right:
            bubbleRect.size.width -= tailWidth
        case .left:
            bubbleRect.origin.x += tailWidth
            bubbleRect.size.width -= tailWidth
        case .top:
            bubbleRect.origin.y += tailWidth
            bubbleRect.size.height -= tailWidth
        case .bottom:
            bubbleRect.size.height -= tailWidth
        }
        
        // ---- Rounded rect ----
        path.addPath(CGPath(
            roundedRect: bubbleRect,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        ))
        
        // ---- Tail ----
        switch direction {
        case .right:
            let tip = CGPoint(x: bubbleRect.maxX + tailWidth, y: midY)

            path.move(to: CGPoint(x: bubbleRect.maxX, y: midY + tailHeight/2))

            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: bubbleRect.maxX + tailWidth * 0.7,
                                 y: midY + tailHeight * 0.25)
            )

            path.addQuadCurve(
                to: CGPoint(x: bubbleRect.maxX, y: midY - tailHeight/2),
                control: CGPoint(x: bubbleRect.maxX + tailWidth * 0.7,
                                 y: midY - tailHeight * 0.25)
            )
            
        case .left:
            let tip = CGPoint(x: bubbleRect.minX - tailWidth, y: midY)

            path.move(to: CGPoint(x: bubbleRect.minX, y: midY + tailHeight/2))

            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: bubbleRect.minX - tailWidth * 0.7,
                                 y: midY + tailHeight * 0.25)
            )

            path.addQuadCurve(
                to: CGPoint(x: bubbleRect.minX, y: midY - tailHeight/2),
                control: CGPoint(x: bubbleRect.minX - tailWidth * 0.7,
                                 y: midY - tailHeight * 0.25)
            )
            
        case .top:
            let tip = CGPoint(x: midX, y: bubbleRect.maxY + tailWidth)

            path.move(to: CGPoint(x: midX - tailHeight/2, y: bubbleRect.maxY))

            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: midX - tailHeight * 0.25,
                                 y: bubbleRect.maxY + tailWidth * 0.7)
            )

            path.addQuadCurve(
                to: CGPoint(x: midX + tailHeight/2, y: bubbleRect.maxY),
                control: CGPoint(x: midX + tailHeight * 0.25,
                                 y: bubbleRect.maxY + tailWidth * 0.7)
            )
            
        case .bottom:
            let tip = CGPoint(x: midX, y: bubbleRect.minY - tailWidth)

            path.move(to: CGPoint(x: midX - tailHeight/2, y: bubbleRect.minY))

            path.addQuadCurve(
                to: tip,
                control: CGPoint(x: midX - tailHeight * 0.25,
                                 y: bubbleRect.minY - tailWidth * 0.7)
            )

            path.addQuadCurve(
                to: CGPoint(x: midX + tailHeight/2, y: bubbleRect.minY),
                control: CGPoint(x: midX + tailHeight * 0.25,
                                 y: bubbleRect.minY - tailWidth * 0.7)
            )
        }
        
        path.closeSubpath()
        return path
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let context = NSGraphicsContext.current?.cgContext
        context?.addPath(bubblePath())
        context?.setFillColor(NSColor.white.cgColor)
        context?.fillPath()
    }
}




// Add animation extensions to BubbleView
extension BubbleView {
    func showWithAnimation() {
        alphaValue = 0
        wantsLayer = true
        layer?.setAffineTransform(CGAffineTransform(scaleX: 0.8, y: 0.8))
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            self.animator().alphaValue = 1
            self.animator().layer?.setAffineTransform(.identity)
        })
    }
    
    func hideWithAnimation(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            self.animator().alphaValue = 0
            self.animator().layer?.setAffineTransform(CGAffineTransform(scaleX: 0.9, y: 0.9))
        }, completionHandler: completion)
    }
}
