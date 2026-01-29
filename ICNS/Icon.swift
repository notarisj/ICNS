//
//  Icon.swift
//  ICNS
//
//  Created by Ioannis Notaris on 7/5/24.
//

import Foundation
import AppKit

struct Icon: Hashable, Codable, Identifiable {
    let id: UUID
    var name: String
    var imageID: String?
    var outputDirectory: String?
    var selectedProfileID: UUID?
    var categoryID: UUID?
    
    // Legacy support: map the old "image" key to this property so we can decode old data.
    // We make it private(set) so we can check it during migration but not use it generally.
    var legacyImageData: Data?
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageID, outputDirectory, selectedProfileID, categoryID
        case legacyImageData = "image"
    }
    
    var imageURL: URL? {
        if let id = imageID {
            return ImageStorageService.shared.getImageURL(id: id)
        }
        return nil
    }

    var image: Data? {
        get {
            if let id = imageID {
                return ImageStorageService.shared.loadImage(id: id)
            }
            return legacyImageData
        }
        set {
            if let newData = newValue {
                // Save new image to disk and get ID
                if let newID = ImageStorageService.shared.saveImage(data: newData) {
                    // Delete old image if it existed and was different (though UUID generic makes it unique usually)
                    if let oldID = imageID {
                        ImageStorageService.shared.deleteImage(id: oldID)
                    }
                    self.imageID = newID
                    self.legacyImageData = nil // Clear legacy data if we're setting new data
                }
            } else {
                // remove image
                if let oldID = imageID {
                    ImageStorageService.shared.deleteImage(id: oldID)
                }
                self.imageID = nil
                self.legacyImageData = nil
            }
        }
    }
    
    init(name: String, image: NSImage?, outputDirectory: URL?) {
        self.id = UUID()
        self.name = name
        self.outputDirectory = outputDirectory?.absoluteString
        
        if let tiff = image?.tiffRepresentation {
            self.image = tiff // This uses the setter to save to disk
        }
    }
    
    // A convenience init for creating an icon with optional parameters
    init(name: String, image: Data? = nil, outputDirectory: String? = nil) {
        self.id = UUID()
        self.name = name
        self.outputDirectory = outputDirectory
        
        if let data = image {
            self.image = data // This uses the setter to save to disk
        }
    }
    
    // Helper to clear legacy data after migration
    mutating func clearLegacyData() {
        self.legacyImageData = nil
    }
}

