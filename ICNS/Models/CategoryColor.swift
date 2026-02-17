//
//  CategoryColor.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

enum CategoryColor: String, Codable, CaseIterable, Identifiable {
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case teal
    case indigo
    case gray
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .teal:
            return .teal
        case .indigo:
            return .indigo
        case .gray:
            return .gray
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}
