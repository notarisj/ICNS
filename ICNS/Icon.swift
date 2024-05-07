//
//  Icon.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import Foundation
import AppKit

struct Icon: Hashable, Codable {
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
}
