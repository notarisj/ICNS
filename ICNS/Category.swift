//
//  Category.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var color: CategoryColor
    var order: Int
    var isExpanded: Bool
    
    init(name: String, iconName: String, color: CategoryColor, order: Int, isExpanded: Bool = true) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.color = color
        self.order = order
        self.isExpanded = isExpanded
    }
    
    // Special "Uncategorized" category
    static var uncategorized: Category {
        Category(name: "Uncategorized", iconName: "tray", color: .gray, order: -1, isExpanded: true)
    }

    // Special "Trash" category
    static var trash: Category {
        Category(name: "Trash", iconName: "trash", color: .red, order: -1, isExpanded: false)
    }
    
    // Special IDs
    static let allIconsID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let uncategorizedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let trashID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
}
