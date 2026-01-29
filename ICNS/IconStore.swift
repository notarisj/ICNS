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
    
    @Published var categories: [Category] = [] {
        didSet {
            saveCategories()
        }
    }
    
    init() {
        loadIcons()
        loadCategories()
        ensureDefaultCategory()
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
    
    private func loadCategories() {
        if let savedCategoriesData = UserDefaults.standard.data(forKey: "categories") {
            do {
                let savedCategories = try JSONDecoder().decode([Category].self, from: savedCategoriesData)
                self.categories = savedCategories
            } catch {
                print("Error decoding categories: \(error)")
            }
        }
    }
    
    private func saveCategories() {
        do {
            let categoriesData = try JSONEncoder().encode(categories)
            UserDefaults.standard.set(categoriesData, forKey: "categories")
        } catch {
            print("Error encoding categories: \(error)")
        }
    }
    
    private func ensureDefaultCategory() {
        // The "Uncategorized" category is virtual and handled in the UI
        // No need to add it to the categories array
        if !categories.contains(where: { $0.id == Category.uncategorized.id }) {
            // Don't add the special "Uncategorized" to the categories array
            // It will be handled separately in the UI
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
    
    // MARK: - Category Actions
    
    func addCategory(_ category: Category) {
        categories.append(category)
    }
    
    func removeCategory(withID id: UUID) {
        // Move all icons in this category back to uncategorized
        for index in icons.indices {
            if icons[index].categoryID == id {
                icons[index].categoryID = nil
            }
        }
        
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories.remove(at: index)
        }
    }
    
    func updateCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        }
    }
    
    func moveCategories(from source: IndexSet, to destination: Int) {
        categories.move(fromOffsets: source, toOffset: destination)
        // Update order values
        for (index, _) in categories.enumerated() {
            categories[index].order = index
        }
    }
    
    func toggleCategoryExpansion(_ categoryID: UUID) {
        if let index = categories.firstIndex(where: { $0.id == categoryID }) {
            categories[index].isExpanded.toggle()
        }
    }
    
    // MARK: - Icon Filtering
    
    func icons(for category: Category?) -> [Icon] {
        guard let category = category else {
            return icons
        }
        
        // "Uncategorized" shows icons without a category
        if category.name == "Uncategorized" {
            return icons.filter { $0.categoryID == nil }
        }
        
        return icons.filter { $0.categoryID == category.id }
    }
    
    func moveIcon(withID iconID: UUID, toCategoryID categoryID: UUID?) {
        if let index = icons.firstIndex(where: { $0.id == iconID }) {
            icons[index].categoryID = categoryID
        }
    }
    
    func iconCount(for category: Category) -> Int {
        if category.name == "Uncategorized" {
            return icons.filter { $0.categoryID == nil }.count
        }
        return icons.filter { $0.categoryID == category.id }.count
    }
    
    func renameIcon(_ icon: Icon, to newName: String) {
        if let index = icons.firstIndex(where: { $0.id == icon.id }) {
            icons[index].name = newName
        }
    }
}
