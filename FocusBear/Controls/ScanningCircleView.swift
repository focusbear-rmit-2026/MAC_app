//
//  ScanningCircleView.swift
//  FocusBear
//
//  Created by Manish Jain on 07/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class ScanningCircleView: NSView {
    
    private var ringLayers: [CAShapeLayer] = []
    private var centerDotLayer: CAShapeLayer?
    private var isAnimating = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layout() {
        super.layout()
        updateLayers()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.masksToBounds = false
    }
    
    private func updateLayers() {
        // Remove existing layers
        ringLayers.forEach { $0.removeFromSuperlayer() }
        centerDotLayer?.removeFromSuperlayer()
        ringLayers.removeAll()
        
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        // Create center dot
        centerDotLayer = CAShapeLayer()
        let centerDotSize: CGFloat = 8
        let centerDotRect = CGRect(
            x: centerX - centerDotSize/2,
            y: centerY - centerDotSize/2,
            width: centerDotSize,
            height: centerDotSize
        )
        centerDotLayer?.path = CGPath(ellipseIn: centerDotRect, transform: nil)
        centerDotLayer?.fillColor = (NSColor(named: "dark_OrangeColor") ?? NSColor.orange).cgColor
        layer?.addSublayer(centerDotLayer!)
        
        // Create 3 pulsing rings
        let ringSizes: [CGFloat] = [12, 14, 16]
        
        for (index, size) in ringSizes.enumerated() {
            let ringLayer = CAShapeLayer()
            
            // Set anchor point to center for proper scaling
            ringLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            ringLayer.position = CGPoint(x: centerX, y: centerY)
            
            // Create ring path centered at origin (since anchor point is at center)
            let ringRect = CGRect(
                x: -size/2,
                y: -size/2,
                width: size,
                height: size
            )
            ringLayer.path = CGPath(ellipseIn: ringRect, transform: nil)
            
            ringLayer.strokeColor = (NSColor(named: "dark_OrangeColor") ?? NSColor.orange).cgColor
            ringLayer.lineWidth = 2
            ringLayer.fillColor = NSColor.clear.cgColor
            ringLayer.opacity = 0.7 - (Float(index) * 0.15)
            
            layer?.addSublayer(ringLayer)
            ringLayers.append(ringLayer)
        }
        
        // Start animation if it was already running
        if isAnimating {
            startAnimating()
        }
    }
    
    func startAnimating() {
        isAnimating = true
        
        for (index, ringLayer) in ringLayers.enumerated() {
            // Remove any existing animations
            ringLayer.removeAllAnimations()
            
            // Reset transform
            ringLayer.transform = CATransform3DIdentity
            
            // Scale animation - expands from center
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 3.0 + Double(index) * 0.5
            scaleAnimation.duration = 1.8
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            // Opacity animation
            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = 0.6 - (Double(index) * 0.15)
            opacityAnimation.toValue = 0.0
            opacityAnimation.duration = 1.8
            opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            // Group animations
            let animationGroup = CAAnimationGroup()
            animationGroup.animations = [scaleAnimation, opacityAnimation]
            animationGroup.duration = 1.8
            animationGroup.repeatCount = .infinity
            animationGroup.isRemovedOnCompletion = false
            animationGroup.fillMode = .forwards
            
            // Add delay for staggered effect
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * 0.3)) { [weak self] in
                guard self?.isAnimating == true else { return }
                ringLayer.add(animationGroup, forKey: "pulsing-\(index)")
            }
        }
    }
    
    func stopAnimating() {
        isAnimating = false
        ringLayers.forEach { $0.removeAllAnimations() }
    }
}


