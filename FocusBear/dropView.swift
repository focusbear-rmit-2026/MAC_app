//
//  dropView.swift
//  FocusBear
//
//  Created by Manish Jain on 27/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa
import AppKit
import UniformTypeIdentifiers


class dropView: NSView {
    
    var delegate: dropViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        if #available(macOS 10.13, *) {
            registerForDraggedTypes([.fileURL])
        } else {
            // Legacy support
            registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeFileURL as String)])
        }
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return containsOnlyImages(sender) ? .copy : []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard
        guard let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        let imageUrls = urls.filter { $0.isImage }
        guard !imageUrls.isEmpty else { return false }
        delegate?.filesAddedInDropView(filesAdded: imageUrls)
        return true
    }
    
    private func containsOnlyImages(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        return urls.allSatisfy { $0.isImage }
    }
}

protocol dropViewDelegate {
    func filesAddedInDropView(filesAdded:[URL])
}

extension URL {
    /// Check if file is an image using UTType (macOS 11+) or fallback to extension
    var isImage: Bool {
        if #available(macOS 11.0, *) {
            if let type = try? resourceValues(forKeys: [.contentTypeKey]).contentType {
                return type.conforms(to: .image)
            }
        }
        // Fallback: check extension
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "heic", "tiff", "bmp"]
        return imageExtensions.contains(pathExtension.lowercased())
    }
}
