//
//  NSImage+Extensions.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import AppKit

extension NSImage {
    func resize(to newSize: NSSize) -> NSImage {
        let newImage = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        newImage.size = newSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newImage)
        self.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()
        let resizedImage = NSImage(size: newSize)
        resizedImage.addRepresentation(newImage)
        return resizedImage
    }

    func save(as type: NSBitmapImageRep.FileType, to url: URL) {
        guard let data = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: data),
              let imageData = imageRep.representation(using: type, properties: [:]) else { return }
        do {
            try imageData.write(to: url)
        } catch {
            print("Error saving image: \(error)")
        }
    }
}
