//
//  IconStore.swift
//  ICNS
//
//  Created by Ioannis Notaris on 7/5/24.
//

import SwiftUI
import Combine

class IconStore: ObservableObject {
    @Published var icons: [Icon] = [] {
        didSet {
            saveIcons()
            updateFilteredIcons()
        }
    }
    
    // Search Optimization: storing filtered results
    @Published var filteredIcons: [Icon] = []
    
    // Current filter state
    var currentCategory: Category? = nil {
        didSet { updateFilteredIcons() }
    }
    var currentSearchText: String = "" {
        didSet { updateFilteredIcons() }
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
        migrateIcons() // Migrate legacy images to disk
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
    
    private func migrateIcons() {
        var migrationNeeded = false
        
        for index in icons.indices {
            if let legacyData = icons[index].legacyImageData {
                // Trigger the setter to save to disk and clear legacy
                let dataToSave = legacyData
                icons[index].image = dataToSave 
                migrationNeeded = true
                print("Migrated icon: \(icons[index].name)")
            }
        }
        
        if migrationNeeded {
            saveIcons() // Save the updated structure (ids instead of data)
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
        // Move to trash instead of deleting immediately
        let icon = icons[index]
        if icon.isTrashed {
            // Permanently delete
             // Clean up image file
            icons[index].image = nil // This triggers delete in setter
            icons.remove(at: index)
        } else {
            // Move to trash
            icons[index].isTrashed = true
        }
    }
    
    func removeIcon(withID id: UUID) {
        if let index = icons.firstIndex(where: { $0.id == id }) {
            // Move to trash instead of deleting immediately
             if icons[index].isTrashed {
                // Permanently delete
                icons[index].image = nil // This triggers delete in setter
                icons.remove(at: index)
             } else {
                 // Move to trash
                 icons[index].isTrashed = true
             }
        }
    }
    
    func permanentlyDeleteIcon(withID id: UUID) {
         if let index = icons.firstIndex(where: { $0.id == id }) {
            // Clean up image file
            icons[index].image = nil // This triggers delete in setter
            icons.remove(at: index)
        }
    }
    
    func restoreIcon(withID id: UUID) {
        if let index = icons.firstIndex(where: { $0.id == id }) {
            icons[index].isTrashed = false
        }
    }
    
    func emptyTrash() {
        // Find all trashed icons
        let trashedIndices = icons.indices.filter { icons[$0].isTrashed }
        
        // Remove them in reverse order to keep indices valid during removal
        for index in trashedIndices.reversed() {
             icons[index].image = nil // Triggers image file deletion
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
    
    // Filter by Searching Text Only (for Sidebar)
    @Published var searchedIcons: [Icon] = []
    
    // MARK: - Icon Filtering & Updates
    
    func updateSearchText(_ text: String) {
        currentSearchText = text
    }
    
    func selectCategory(_ category: Category?) {
        currentCategory = category
    }
    
    private func updateFilteredIcons() {
        var result = icons
        
        // Update searchedIcons (Global search for sidebar)
        if !currentSearchText.isEmpty {
            self.searchedIcons = icons.filter { 
                $0.name.localizedCaseInsensitiveContains(currentSearchText) && !$0.isTrashed 
            }
        } else {
            self.searchedIcons = icons.filter { !$0.isTrashed }
        }
        
        // Filter by Category (for Main View)
        if let category = currentCategory {
            if category.name == "Trash" {
                result = result.filter { $0.isTrashed }
            } else if category.name == "Uncategorized" {
                result = result.filter { $0.categoryID == nil && !$0.isTrashed }
            } else {
                result = result.filter { $0.categoryID == category.id && !$0.isTrashed }
            }
        } else {
             // By default (All Icons view usually), exclude trashed
             result = result.filter { !$0.isTrashed }
        }
        
        // Filter by Search Text (for Main View as well)
        if !currentSearchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(currentSearchText) }
        }
        
        self.filteredIcons = result
    }
    
    // Helper to get icons for a specific category (used by sidebar, separate from main selection)
    func icons(for category: Category?) -> [Icon] {
        guard let category = category else {
            return icons.filter { !$0.isTrashed }
        }
        
        if category.name == "Trash" {
            return icons.filter { $0.isTrashed }
        }
        
        // "Uncategorized" shows icons without a category
        if category.name == "Uncategorized" {
            return icons.filter { $0.categoryID == nil && !$0.isTrashed }
        }
        
        return icons.filter { $0.categoryID == category.id && !$0.isTrashed }
    }
    
    func moveIcon(withID iconID: UUID, toCategoryID categoryID: UUID?) {
        if let index = icons.firstIndex(where: { $0.id == iconID }) {
             // If we are moving to trash (via drag and drop maybe?), we should set isTrashed
             if categoryID == Category.trashID {
                 icons[index].isTrashed = true
             } else {
                icons[index].categoryID = categoryID
                icons[index].isTrashed = false // Restore if moved out of trash
             }
        }
    }
    
    func iconCount(for category: Category) -> Int {
        if category.name == "Trash" {
            return icons.filter { $0.isTrashed }.count
        }
        if category.name == "Uncategorized" {
            return icons.filter { $0.categoryID == nil && !$0.isTrashed }.count
        }
        return icons.filter { $0.categoryID == category.id && !$0.isTrashed }.count
    }
    
    func renameIcon(_ icon: Icon, to newName: String) {
        if let index = icons.firstIndex(where: { $0.id == icon.id }) {
            icons[index].name = newName
        }
    }
}

