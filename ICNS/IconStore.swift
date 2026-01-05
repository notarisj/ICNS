//
//  IconStore.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import SwiftUI
import Combine

class IconStore: ObservableObject {
    @Published var icons: [Icon] = [] {
        didSet {
            saveIcons()
        }
    }
    
    init() {
        loadIcons()
    }
    
    // MARK: - Persistence
    
    private func loadIcons() {
        if let savedIconsData = UserDefaults.standard.data(forKey: "icons") {
            do {
                let savedIcons = try JSONDecoder().decode([Icon].self, from: savedIconsData)
                self.icons = savedIcons
            } catch {
                print("Error decoding icons: \(error)")
            }
        }
    }
    
    private func saveIcons() {
        do {
            let iconsData = try JSONEncoder().encode(icons)
            UserDefaults.standard.set(iconsData, forKey: "icons")
        } catch {
            print("Error encoding icons: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func addIcon(_ icon: Icon) {
        icons.append(icon)
    }
    
    func removeIcon(at index: Int) {
        guard icons.indices.contains(index) else { return }
        icons.remove(at: index)
    }
    
    func removeIcon(withID id: UUID) {
        if let index = icons.firstIndex(where: { $0.id == id }) {
            icons.remove(at: index)
        }
    }
    
    func moveIcons(from source: IndexSet, to destination: Int) {
        icons.move(fromOffsets: source, toOffset: destination)
    }
}
