//
//  ContentView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: IconStore
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
            // MAIN CONTENT AREA
            Group {
                if let iconIndex = store.icons.firstIndex(where: { $0.id == selectedIconID }) {
                    // Show individual icon detail
                    IconView(
                        icon: $store.icons[iconIndex],
                        icons: $store.icons,
                        showInspector: $showInspector,
                        showAddIconSheet: $showAddIconSheet,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                    .ignoresSafeArea()
                } else if selectedCategoryID != nil || selectedIconID == nil {
                    // Show icon grid for selected category or All Icons
                    let displayedIcons = iconsForSelectedCategory
                    IconGridView(
                        icons: displayedIcons, 
                        selectedIconID: Binding(
                            get: { selectedIconID },
                            set: { 
                                selectedIconID = $0
                                if $0 != nil { didNavigateFromGrid = true }
                            }
                        ),
                        showInspector: $showInspector
                    )
                        .navigationTitle(categoryTitle)
                } else {
                    WelcomeView(showInspector: $showInspector)
                }
            }
            .navigationTitle(currentIconName)
            .toolbar {
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
                

                

            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .automatic)
        .frame(minWidth: showInspector ? nil : 600)
        .inspector(isPresented: $showInspector) {
            if let bindingIcon = bindingForSelectedIcon() {
                InspectorView(icon: bindingIcon)
                    .inspectorColumnWidth(min: 250, ideal: 280, max: 350)
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
                .inspectorColumnWidth(min: 250, ideal: 280, max: 350)
            }
        }

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
        .onReceive(NotificationCenter.default.publisher(for: .newIconSet)) { _ in
            newIconCategory = selectedCategoryID
            showAddIconSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .newCategory)) { _ in
            editingCategory = nil
            showCategoryEditor = true
        }
    }
    
    // MARK: - Helper Views
    

    
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
            store.icons.remove(at: index)
            
            if store.icons.isEmpty {
                selectedIconID = nil
            } else if store.icons.indices.contains(index) {
                selectedIconID = store.icons[index].id
            } else if index > 0 {
                selectedIconID = store.icons[index - 1].id
            } else {
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
                return store.icons
            } else if categoryID == Category.uncategorizedID {
                return store.icons.filter { $0.categoryID == nil }
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
            } else if let category = store.categories.first(where: { $0.id == categoryID }) {
                return category.name
            }
        }
        return "All Icons"
    }
}
