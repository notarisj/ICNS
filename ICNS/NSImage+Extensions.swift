//
//  NSImage+Extensions.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import AppKit

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    func resizeImage(to size: NSSize) -> NSImage {
        let img = NSImage(size: size)
        img.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1.0)
        img.unlockFocus()
        return img
    }
    
    func saveImage(as type: NSBitmapImageRep.FileType, to url: URL) {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return }
        if let data = bitmapImage.representation(using: type, properties: [:]) {
            try? data.write(to: url)
        }
    }
}
