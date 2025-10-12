//
//  Icon.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import Foundation
import AppKit

struct Icon: Hashable, Codable, Identifiable {
    let id: UUID
    var name: String
    var image: Data?
    var outputDirectory: String?
    
    init(name: String, image: NSImage?, outputDirectory: URL?) {
        self.id = UUID()
        self.name = name
        self.image = image?.tiffRepresentation
        self.outputDirectory = outputDirectory?.absoluteString
    }
    
    // A convenience init for creating an icon with optional parameters
    init(name: String, image: Data? = nil, outputDirectory: String? = nil) {
        self.id = UUID()
        self.name = name
        self.image = image
        self.outputDirectory = outputDirectory
    }
}
