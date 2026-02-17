//
//  ContentView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: IconStore
    @EnvironmentObject var profileStore: ProfileStore
    
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR - Category-based navigation
            CategorySidebarView(
                selectedIconID: $viewModel.selectedIconID,
                selectedCategoryID: $viewModel.selectedCategoryID
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
            .navigationTitle("Icons")

        } detail: {
            detailContent
                .onTapGesture {
                    // Only collapse toolbar search if it's empty
                    if viewModel.toolbarSearchText.isEmpty {
                        viewModel.isSearching = false
                    }
                    // Always clear focus from both search fields
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .automatic)
        .focusedSceneValue(\.searchFocus, $viewModel.isSearching)
        .focusedSceneValue(\.showInspector, $viewModel.showInspector)
        .sheet(isPresented: $viewModel.showAddIconSheet) {
            addIconSheet
        }
        .sheet(isPresented: $viewModel.showCategoryEditor) {
            CategoryEditorSheet(category: $viewModel.editingCategory) { category in
                viewModel.saveCategory(store: store, category: category)
            }
        }
        .alert(isPresented: $viewModel.showDeleteConfirmation) {
            Alert(
                title: Text("Remove Icon"),
                message: Text("Are you sure you want to remove this icon?"),
                primaryButton: .destructive(Text("Remove")) {
                    viewModel.deleteIcon(store: store)
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Empty Trash", isPresented: $viewModel.showEmptyTrashConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Empty Trash", role: .destructive) {
                store.emptyTrash()
            }
        } message: {
            Text("Are you sure you want to permanently delete these items? This action cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .newIconSet)) { _ in
            viewModel.newIconCategory = viewModel.selectedCategoryID
            viewModel.showAddIconSheet = true
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text(viewModel.alertTitle), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(NotificationCenter.default.publisher(for: .newCategory)) { _ in
            viewModel.editingCategory = nil
            viewModel.showCategoryEditor = true
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var detailContent: some View {
        Group {
            if let iconIndex = store.icons.firstIndex(where: { $0.id == viewModel.selectedIconID }) {
                // Show individual icon detail
                IconView(
                    icon: $store.icons[iconIndex],
                    icons: $store.icons,
                    showInspector: $viewModel.showInspector,
                    showAddIconSheet: $viewModel.showAddIconSheet,
                    showDeleteConfirmation: $viewModel.showDeleteConfirmation,
                    iconsGenerated: $viewModel.iconsGenerated,
                    showClearImageConfirmation: $viewModel.showClearImageConfirmation
                )
            } else if viewModel.selectedCategoryID != nil || viewModel.selectedIconID == nil {
                // Show icon grid for selected category or All Icons
                IconGridView(
                    icons: viewModel.iconsForSelectedCategory(store: store),
                    categoryName: viewModel.categoryTitle(store: store),
                    selectedIconID: $viewModel.selectedIconID,
                    showInspector: $viewModel.showInspector
                )
                    .navigationTitle(viewModel.categoryTitle(store: store))
            } else {
                WelcomeView(showInspector: $viewModel.showInspector)
            }
        }
        .frame(minHeight: 400)
        .navigationTitle(viewModel.currentIconName(store: store))
        .inspector(isPresented: $viewModel.showInspector) {
            inspectorContent
                .inspectorColumnWidth(min: 250, ideal: 270, max: 330)
        }
        .toolbar {
            toolbarItems
        }
    }
    
    @ViewBuilder
    private var inspectorContent: some View {
        if let selectedID = viewModel.selectedIconID,
           let index = store.icons.firstIndex(where: { $0.id == selectedID }) {
            InspectorView(icon: $store.icons[index])
                .id(selectedID)
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
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.toolbarSearchText.isEmpty {
                    viewModel.isSearching = false
                }
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // MARK: - Navigation Items (Left Side)
        ToolbarItemGroup(placement: .navigation) {
            if viewModel.didNavigateFromGrid && viewModel.selectedIconID != nil {
                Button {
                    viewModel.selectedIconID = nil
                    viewModel.didNavigateFromGrid = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            
            Menu {
                Button {
                    viewModel.newIconCategory = viewModel.selectedCategoryID
                    viewModel.showAddIconSheet = true
                } label: {
                    Label("New Icon Set", systemImage: "app.dashed")
                }
                
                Button {
                    viewModel.editingCategory = nil
                    viewModel.showCategoryEditor = true
                } label: {
                    Label("New Category", systemImage: "folder.badge.plus")
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
            .help("Create a new icon set or category")
        }
        
        // MARK: - Context Actions
        ToolbarItemGroup(placement: .primaryAction) {
            contextSpecificItems
        }
        
        // MARK: - Inspector Toggle
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.showInspector.toggle()
            } label: {
                Label("Inspector", systemImage: "slider.horizontal.3")
            }
            .help("Show or hide the inspector panel")
        }
    }
    
    // MARK: - Context-Specific Toolbar Items
    @ViewBuilder
    private var contextSpecificItems: some View {
        // IconGridView-specific toolbar items (Search + Trash)
        if viewModel.selectedIconID == nil {
            // Search field - only in grid view
            if viewModel.isSearching {
                SearchFieldView(text: $viewModel.toolbarSearchText, isSearching: $viewModel.isSearching)
                    .frame(width: 200)
            } else {
                Button {
                    viewModel.isSearching = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
            
            // Empty Trash button - only in Trash category
            if viewModel.selectedCategoryID == Category.trashID {
                Button {
                    viewModel.showEmptyTrashConfirmation = true
                } label: {
                    Label("Empty Trash", systemImage: "trash")
                }
                .help("Empty Trash")
                .disabled(store.icons.filter { $0.isTrashed }.isEmpty)
            }
        }
        
        // IconView-specific toolbar items
        if let iconIndex = store.icons.firstIndex(where: { $0.id == viewModel.selectedIconID }) {
            let currentIcon = store.icons[iconIndex]
            
            if !viewModel.iconsGenerated {
                Button {
                    viewModel.generateIcons(store: store, profileStore: profileStore)
                } label: {
                    Label("Generate Icons", systemImage: "sparkles.rectangle.stack")
                }
                .help("Generate the icon set from your master image")
                .disabled(currentIcon.image == nil || currentIcon.outputDirectory == nil)
            } else {
                Button {
                    viewModel.generateICNS(store: store)
                } label: {
                    Label("Save ICNS", systemImage: "arrow.down.doc.fill")
                }
                .help("Convert the icon set to a .icns file")
            }
            
            if currentIcon.image != nil {
                Button {
                    viewModel.showClearImageConfirmation = true
                } label: {
                    Label("Clear Image", systemImage: "trash")
                }
                .help("Remove the current image")
            }
        }
    }
    
    // MARK: - Example of moved logic: addIconSheet
    
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
                
                TextField("e.g. AppIcon", text: $viewModel.newIconName)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                    .padding(.top, 4)
                
                Picker("Category", selection: $viewModel.newIconCategory) {
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
                    viewModel.showAddIconSheet = false
                    viewModel.newIconName = ""
                    viewModel.newIconCategory = nil
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    viewModel.addNewIcon(store: store)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.newIconName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding(24)
        .frame(width: 350)
    }
}
