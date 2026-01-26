//
//  ExportProfile.swift
//  ICNS
//
//  Created by Ioannis Notaris on 9/1/26.
//

import Foundation

struct ExportProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sizes: [Int]
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, sizes: [Int], isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.sizes = sizes.sorted()
        self.isDefault = isDefault
    }
    
    // Computed property for display
    var sizesDescription: String {
        guard !sizes.isEmpty else { return "No sizes" }
        let count = sizes.count
        let minSize = sizes.min() ?? 0
        let maxSize = sizes.max() ?? 0
        return "\(count) size\(count == 1 ? "" : "s"): \(minSize)-\(maxSize)px"
    }
    
    // Factory method for default profile
    static func createDefault() -> ExportProfile {
        ExportProfile(
            name: "Default",
            sizes: [16, 32, 128, 256, 512],
            isDefault: true
        )
    }
}
