//
//  NSImage+Extensions.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import AppKit

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
        else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    
    func resizeImage(to size: NSSize) -> NSImage {
        let width = Int(size.width)
        let height = Int(size.height)
        
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return NSImage(size: size)
        }
        
        rep.size = size
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        
        self.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)
        
        NSGraphicsContext.restoreGraphicsState()
        
        let newImage = NSImage(size: size)
        newImage.addRepresentation(rep)
        return newImage
    }
    
    func saveImage(as type: NSBitmapImageRep.FileType, to url: URL) {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation)
        else { return }
        if let data = bitmapImage.representation(using: type, properties: [:]) {
            try? data.write(to: url)
        }
    }
}
