
import SwiftUI
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    // MARK: - Navigation State
    @Published var selectedIconID: Icon.ID? {
        didSet {
            // When navigating directly via selection, ensure we track where we came from if needed
            // Logic moved from ContentView binding
            if selectedIconID != nil { didNavigateFromGrid = false }
        }
    }
    @Published var selectedCategoryID: UUID? = Category.allIconsID
    @Published var didNavigateFromGrid = false
    
    // MARK: - UI State
    @Published var showInspector = true
    @Published var showAddIconSheet = false
    @Published var showCategoryEditor = false
    @Published var showDeleteConfirmation = false
    @Published var showEmptyTrashConfirmation = false
    @Published var showClearImageConfirmation = false
    
    // MARK: - Editing State
    @Published var editingCategory: Category?
    @Published var newIconName = ""
    @Published var newIconCategory: UUID?
    
    // MARK: - Generation State
    @Published var iconsGenerated = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = "Success"
    
    // MARK: - Search State
    @Published var toolbarSearchText = ""
    @Published var isSearching = false
    
    // MARK: - Actions
    
    func addNewIcon(store: IconStore) {
        let trimmedName = newIconName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        var finalName = trimmedName
        var counter = 2
        while store.icons.contains(where: { $0.name == finalName }) {
            finalName = "\(trimmedName) \(counter)"
            counter += 1
        }
        
        var newIcon = Icon(name: finalName, image: nil as NSImage?, outputDirectory: nil as URL?)
        newIcon.categoryID = newIconCategory
        store.addIcon(newIcon)
        selectedIconID = newIcon.id
        
        // Reset state
        newIconName = ""
        newIconCategory = nil
        showAddIconSheet = false
    }
    
    func deleteSelectedIcon(store: IconStore) {
        guard let selectedID = selectedIconID,
              let index = store.icons.firstIndex(where: { $0.id == selectedID }) else { return }
        
        store.removeIcon(at: index)
        selectedIconID = nil
    }
    
    func deleteIcon(store: IconStore) {
        guard let selectedID = selectedIconID,
              let index = store.icons.firstIndex(where: { $0.id == selectedID }) else { return }
        
        store.removeIcon(at: index)
        
        // Selection logic: if item moved to trash (hidden), we need to select something else
        if iconsForSelectedCategory(store: store).isEmpty {
             selectedIconID = nil
        } else {
             selectedIconID = nil
        }
    }
    
    func saveCategory(store: IconStore, category: Category) {
        if editingCategory != nil {
            store.updateCategory(category)
        } else {
            var newCategory = category
            newCategory.order = store.categories.count
            store.addCategory(newCategory)
        }
        editingCategory = nil
        showCategoryEditor = false
    }

    func generateIcons(store: IconStore, profileStore: ProfileStore) {
        guard let selectedID = selectedIconID,
              let index = store.icons.firstIndex(where: { $0.id == selectedID }) else { return }
        
        let icon = store.icons[index]
        
        guard let imageData = icon.image,
              let image = NSImage(data: imageData),
              let outputDirectoryString = icon.outputDirectory,
              let outputDirectoryURL = URL(string: outputDirectoryString)
        else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
            self.alertMessage = "Access to the directory was denied. Select the output directory and try again."
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        // Get selected profile or use default
        let profile = profileStore.getProfile(byID: icon.selectedProfileID)
        
        let result = ImageGenerationService.shared.generateIcons(
            from: image,
            outputDirectory: outputDirectoryURL,
            profile: profile,
            iconName: icon.name
        )
        
        outputDirectoryURL.stopAccessingSecurityScopedResource()
        
        switch result {
        case .success(let folderURL):
            self.alertMessage = "Icons have been successfully created at \(folderURL.path)!"
            self.alertTitle = "Success"
            self.iconsGenerated = true
        case .failure(let error):
            self.alertMessage = "Error creating icons: \(error.localizedDescription)"
            self.alertTitle = "Error"
        }
        
        self.showAlert = true
    }
    
    func generateICNS(store: IconStore) {
        guard let selectedID = selectedIconID,
              let index = store.icons.firstIndex(where: { $0.id == selectedID }) else { return }
        
        let icon = store.icons[index]
        
        guard let outputDirectoryString = icon.outputDirectory,
              let outputDirectoryURL = URL(string: outputDirectoryString)
        else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
            self.alertMessage = "Access to the directory was denied. Select the output directory and try again."
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        let result = ImageGenerationService.shared.generateICNS(from: icon.name, inside: outputDirectoryURL)
        
        outputDirectoryURL.stopAccessingSecurityScopedResource()
        
        switch result {
        case .success(let icnsURL):
             self.alertMessage = "ICNS file has been successfully created at \(icnsURL.path)!"
             self.alertTitle = "Success"
        case .failure(let error):
            self.alertMessage = "Failed to create ICNS file. Error: \(error.localizedDescription)"
            self.alertTitle = "Error"
        }
        
        self.showAlert = true
    }
    
    // MARK: - Computed Helpers
    
    func currentIconName(store: IconStore) -> String {
        guard let selectedID = selectedIconID,
              let iconIndex = store.icons.firstIndex(where: { $0.id == selectedID }) else {
            return "ICNS"
        }
        return store.icons[iconIndex].name
    }
    
    func categoryTitle(store: IconStore) -> String {
        if let categoryID = selectedCategoryID {
            if categoryID == Category.allIconsID {
                return "All Icons"
            } else if categoryID == Category.uncategorizedID {
                return "Uncategorized"
            } else if categoryID == Category.trashID {
                return "Trash"
            } else if let category = store.categories.first(where: { $0.id == categoryID }) {
                return category.name
            }
        }
        return "All Icons"
    }
    
    // Helper to filter icons for the view
    func iconsForSelectedCategory(store: IconStore) -> [Icon] {
         var icons: [Icon]
         
         if let categoryID = selectedCategoryID {
             if categoryID == Category.allIconsID {
                 icons = store.icons.filter { !$0.isTrashed }
             } else if categoryID == Category.uncategorizedID {
                 icons = store.icons.filter { $0.categoryID == nil && !$0.isTrashed }
             } else if categoryID == Category.trashID {
                 icons = store.icons.filter { $0.isTrashed }
             } else if let category = store.categories.first(where: { $0.id == categoryID }) {
                 icons = store.icons(for: category)
             } else {
                 icons = store.icons.filter { !$0.isTrashed }
             }
         } else {
             icons = store.icons.filter { !$0.isTrashed }
         }
         
         if toolbarSearchText.isEmpty {
             return icons
         } else {
             return icons.filter { $0.name.localizedCaseInsensitiveContains(toolbarSearchText) }
         }
    }
}
