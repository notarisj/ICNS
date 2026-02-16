//
//  ContentView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: IconStore
    @EnvironmentObject var profileStore: ProfileStore
    @State private var selectedIconID: Icon.ID? = nil
    @State private var selectedCategoryID: UUID? = Category.allIconsID
    @State private var showDeleteConfirmation = false
    @State private var showInspector = true
    @State private var showAddIconSheet = false
    @State private var showCategoryEditor = false
    @State private var editingCategory: Category? = nil

    @State private var newIconName = ""
    @State private var newIconCategory: UUID? = nil // State for selected category
    @State private var didNavigateFromGrid = false
    
    // IconView toolbar state
    @State private var iconsGenerated = false
    @State private var showClearImageConfirmation = false
    @State private var showEmptyTrashConfirmation = false
    
    // Alert state for generation
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Success"

    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR - Category-based navigation
            CategorySidebarView(
                selectedIconID: Binding(
                    get: { selectedIconID },
                    set: { 
                        selectedIconID = $0
                        if $0 != nil { didNavigateFromGrid = false }
                    }
                ),
                selectedCategoryID: $selectedCategoryID
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
            .navigationTitle("Icons")

        } detail: {
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .automatic)

        .focusedSceneValue(\.showInspector, $showInspector)
        .sheet(isPresented: $showAddIconSheet) {
            addIconSheet
        }
        .sheet(isPresented: $showCategoryEditor) {
            CategoryEditorSheet(category: $editingCategory) { category in
                if editingCategory != nil {
                    store.updateCategory(category)
                } else {
                    var newCategory = category
                    newCategory.order = store.categories.count
                    store.addCategory(newCategory)
                }
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Remove Icon"),
                message: Text("Are you sure you want to remove this icon?"),
                primaryButton: .destructive(Text("Remove")) {
                    deleteIcon()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Empty Trash", isPresented: $showEmptyTrashConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Empty Trash", role: .destructive) {
                store.emptyTrash()
            }
        } message: {
            Text("Are you sure you want to permanently delete these items? This action cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newIconSet)) { _ in
            newIconCategory = selectedCategoryID
            showAddIconSheet = true
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(NotificationCenter.default.publisher(for: .newCategory)) { _ in
            editingCategory = nil
            showCategoryEditor = true
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var detailContent: some View {
        Group {
            if let iconIndex = store.icons.firstIndex(where: { $0.id == selectedIconID }) {
                // Show individual icon detail
                IconView(
                    icon: $store.icons[iconIndex],
                    icons: $store.icons,
                    showInspector: $showInspector,
                    showAddIconSheet: $showAddIconSheet,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    iconsGenerated: $iconsGenerated,
                    showClearImageConfirmation: $showClearImageConfirmation
                )
                // .ignoresSafeArea()
            } else if selectedCategoryID != nil || selectedIconID == nil {
                // Show icon grid for selected category or All Icons
                let displayedIcons = iconsForSelectedCategory
                IconGridView(
                    icons: displayedIcons, 
                    categoryName: categoryTitle,
                    selectedIconID: Binding(
                        get: { selectedIconID },
                        set: { newValue in
                            selectedIconID = newValue
                            if newValue != nil { didNavigateFromGrid = true }
                        }
                    ),
                    showInspector: $showInspector
                )
                    .navigationTitle(categoryTitle)
            } else {
                WelcomeView(showInspector: $showInspector)
            }
        }
        .frame(minHeight: 400)
        .navigationTitle(currentIconName)
        .inspector(isPresented: $showInspector) {
            inspectorContent
                .inspectorColumnWidth(min: 250, ideal: 270, max: 330)
        }
        .toolbar {
            toolbarItems
        }
    }
    
    @ViewBuilder
    private var inspectorContent: some View {
        if let bindingIcon = bindingForSelectedIcon() {
            InspectorView(icon: bindingIcon)
                .id(selectedIconID)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
                Text("No Selection")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Select an icon to view its details")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            if didNavigateFromGrid && selectedIconID != nil {
                Button {
                    selectedIconID = nil
                    didNavigateFromGrid = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            
            Menu {
                Button {
                    newIconCategory = selectedCategoryID // Default to current category
                    showAddIconSheet = true
                } label: {
                    Label("New Icon Set", systemImage: "app.dashed")
                }
                
                Button {
                    editingCategory = nil
                    showCategoryEditor = true
                } label: {
                    Label("New Category", systemImage: "folder.badge.plus")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
            .help("Create a new icon set or category")
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            // IconView-specific toolbar items
            if let iconIndex = store.icons.firstIndex(where: { $0.id == selectedIconID }) {
                let currentIcon = store.icons[iconIndex]
                
                if !iconsGenerated {
                    Button {
                        generateIcons()
                    } label: {
                        Label("Generate Icons", systemImage: "sparkles.rectangle.stack")
                    }
                    .help("Generate the icon set from your master image")
                    .disabled(currentIcon.image == nil || currentIcon.outputDirectory == nil)
                } else {
                    Button {
                        generateICNS()
                    } label: {
                        Label("Save ICNS", systemImage: "arrow.down.doc.fill")
                    }
                    .help("Convert the icon set to a .icns file")
                }
                
                if currentIcon.image != nil {
                    Button {
                        showClearImageConfirmation = true
                    } label: {
                        Label("Clear Image", systemImage: "trash")
                    }
                    .help("Remove the current image")
                }
            }
            
            // IconGridView-specific toolbar items (Trash)
            if selectedCategoryID == Category.trashID && selectedIconID == nil {
                Button {
                    showEmptyTrashConfirmation = true
                } label: {
                    Label("Empty Trash", systemImage: "trash")
                }
                .help("Empty Trash")
                .disabled(store.icons.filter { $0.isTrashed }.isEmpty)
            }
            
            // Inspector toggle (always visible)
            Button {
                showInspector.toggle()
            } label: {
                Label("Inspector", systemImage: "slider.horizontal.3")
            }
            .help("Show or hide the inspector panel")
        }
    }
    
    // MARK: - Helper Functions
    
    private func bindingForSelectedIcon() -> Binding<Icon>? {
        guard let selectedID = selectedIconID,
              let index = store.icons.firstIndex(where: { $0.id == selectedID }) else {
            return nil
        }
        return $store.icons[index]
    }
    
    private var addIconSheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "plus.square.dashed")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                
                VStack(spacing: 4) {
                    Text("New Icon Set")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Enter a name for your new icon project.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                
                TextField("e.g. AppIcon", text: $newIconName)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                Picker("Category", selection: $newIconCategory) {
                    Text("Uncategorized").tag(UUID?.none)
                    ForEach(store.categories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    showAddIconSheet = false
                    newIconName = ""
                    newIconCategory = nil
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    addIcon(named: newIconName, categoryID: newIconCategory)
                    showAddIconSheet = false
                    newIconName = ""
                    newIconCategory = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(newIconName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(width: 350)
    }
    
    private func addIcon(named name: String, categoryID: UUID?) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { return }
        
        var finalName = trimmedName
        var counter = 2
        while store.icons.contains(where: { $0.name == finalName }) {
            finalName = "\(trimmedName) \(counter)"
            counter += 1
        }
        
        var newIcon = Icon(name: finalName, image: nil as NSImage?, outputDirectory: nil as URL?)
        newIcon.categoryID = categoryID
        store.icons.append(newIcon)
        selectedIconID = newIcon.id
    }
    
    private func moveIcons(from source: IndexSet, to destination: Int) {
        store.icons.move(fromOffsets: source, toOffset: destination)
    }
    
    private func deleteIcon() {
        if let selectedID = selectedIconID,
           let index = store.icons.firstIndex(where: { $0.id == selectedID }) {
            // Use store method to handle trash logic
            store.removeIcon(at: index)
            
            // Selection logic: if item moved to trash (hidden), we need to select something else
            // If we are in Trash view, it might be permanently deleted.
            // Simplified selection logic:
            if store.filteredIcons.isEmpty {
                 selectedIconID = nil
            } else {
                 // Try to select next or previous from filtered list?
                 // Since store.icons changes could be complex (reordering), just deselect for now or keep generic logic
                 // If the icon is still in store.icons (just trashed) but we are filtering it out, we should deselect it.
                 selectedIconID = nil
            }
        }
    }
    
    // Add this computed property
    private var currentIconName: String {
        guard let selectedID = selectedIconID,
              let iconIndex = store.icons.firstIndex(where: { $0.id == selectedID }) else {
            return "ICNS"
        }
        return store.icons[iconIndex].name
    }
    
    private var iconsForSelectedCategory: [Icon] {
        if let categoryID = selectedCategoryID {
            if categoryID == Category.allIconsID {
                return store.icons.filter { !$0.isTrashed }
            } else if categoryID == Category.uncategorizedID {
                return store.icons.filter { $0.categoryID == nil && !$0.isTrashed }
            } else if categoryID == Category.trashID {
                return store.icons.filter { $0.isTrashed }
            } else if let category = store.categories.first(where: { $0.id == categoryID }) {
                return store.icons(for: category)
            }
        }
        // Default to All Icons
        return store.icons
    }
    
    private var categoryTitle: String {
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
    
    // MARK: - Generation Functions
    
    private func generateIcons() {
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
    
    private func generateICNS() {
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
    

}
