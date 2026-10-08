#!/usr/bin/env swift
//
// Regenerates FocusBear/Assets.xcassets/AppIcon-UITest.appiconset from AppIcon.appiconset: the same
// bear with a red "TEST" banner across the bottom, so the UI-test build (docs/ui-tests.md) can never
// be mistaken for the real Focus Bear in the Dock or Cmd-Tab.
//
//     swift scripts/make-uitest-app-icon.swift
//
import AppKit

let catalog = URL(fileURLWithPath: "FocusBear/Assets.xcassets")
let source = catalog.appendingPathComponent("AppIcon.appiconset")
let destination = catalog.appendingPathComponent("AppIcon-UITest.appiconset")
let bannerText = "TEST"
let bannerHeightRatio: CGFloat = 0.26
let bannerColor = NSColor(calibratedRed: 0.86, green: 0.16, blue: 0.12, alpha: 0.95)
let textHeightRatio: CGFloat = 0.72

func badged(_ image: NSImage, pixels: Int) -> Data? {
    let size = CGFloat(pixels)
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    let banner = NSRect(x: 0, y: 0, width: size, height: size * bannerHeightRatio)
    bannerColor.setFill()
    banner.fill()
    let font = NSFont.systemFont(ofSize: banner.height * textHeightRatio, weight: .black)
    let text = NSAttributedString(string: bannerText, attributes: [.font: font, .foregroundColor: NSColor.white])
    let textSize = text.size()
    text.draw(at: NSPoint(x: (size - textSize.width) / 2, y: (banner.height - textSize.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

let fileManager = FileManager.default
try? fileManager.removeItem(at: destination)
try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
try fileManager.copyItem(at: source.appendingPathComponent("Contents.json"), to: destination.appendingPathComponent("Contents.json"))
for file in try fileManager.contentsOfDirectory(atPath: source.path) where file.hasSuffix(".png") {
    let url = source.appendingPathComponent(file)
    guard let image = NSImage(contentsOf: url), let rep = image.representations.first,
          let data = badged(image, pixels: rep.pixelsWide) else {
        FileHandle.standardError.write("could not badge \(file)\n".data(using: .utf8)!)
        exit(1)
    }
    try data.write(to: destination.appendingPathComponent(file))
}
print("wrote \(destination.path)")
