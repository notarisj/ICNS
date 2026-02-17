//
//  CategorySidebarView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct CategorySidebarView: View {
    @EnvironmentObject var store: IconStore
    @Binding var selectedIconID: Icon.ID?
    @Binding var selectedCategoryID: UUID?
    @Binding var didNavigateFromGrid: Bool
    @Binding var isSidebarSearching: Bool
    @State private var showCategoryEditor = false
    @State private var editingCategory: Category? = nil
    @State private var showDeleteConfirmation = false
    @State private var categoryToDelete: Category? = nil
    @State private var isUncategorizedExpanded = true
    @State private var searchText = ""

    // Focused Value State Caches
    @State private var cachedEditCategoryAction: (() -> Void)?
    @State private var cachedRenameItemAction: (() -> Void)?
    @State private var cachedDeleteItemAction: (() -> Void)?
    
    // Icon Context Menu States
    @State private var iconToDelete: Icon? = nil
    @State private var showIconDeleteConfirmation = false
    @State private var iconToRename: Icon? = nil
    @State private var showRenameIconAlert = false
    @State private var newIconName = ""
    @State private var showEmptyTrashConfirmation = false
    
    // Special IDs for All Icons and Uncategorized
    private let allIconsID = Category.allIconsID
    private let uncategorizedID = Category.uncategorizedID
    private let trashID = Category.trashID
    
    var body: some View {
        List(selection: selectionBinding) {
            // "All Icons" - simple clickable row (no nested icons)
            allIconsRow
            
            // Categories section with Uncategorized first, then custom categories
            Section {
                // Custom categories
                if !filteredCategories.isEmpty {
                    ForEach(filteredCategories) { category in
                        categoryRow(for: category)
                    }
                    .onMove(perform: searchText.isEmpty ? moveCategories : nil)
                }

                // Uncategorized section (collapsible with nested icons)
                uncategorizedSection
            } header: {
                Text("Categories")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            // Trash Section
            Section {
               trashRow
            }
        }
        .searchable(text: $searchText, isPresented: $isSidebarSearching, placement: .sidebar, prompt: "Search")
        .onChange(of: searchText) { _, newValue in
            store.updateSearchText(newValue)
            validateSelection()
        }
        .scrollContentBackground(.hidden)
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
        .alert("Delete Category", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    store.removeCategory(withID: category.id)
                }
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete \"\(category.name)\"? Icons in this category will be moved to Uncategorized.")
            }
        }
        .alert("Delete Icon", isPresented: $showIconDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let icon = iconToDelete {
                    store.removeIcon(withID: icon.id)
                    if selectedIconID == icon.id {
                        selectedIconID = nil
                    }
                }
            }
        } message: {
            if let icon = iconToDelete {
                Text("Are you sure you want to move \"\(icon.name)\" to Trash?")
            }
        }
        .alert("Rename Icon", isPresented: $showRenameIconAlert) {
            TextField("Name", text: $newIconName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let icon = iconToRename {
                    store.renameIcon(icon, to: newIconName)
                }
            }
        } message: {
            Text("Enter a new name for this icon.")
        }
        .alert("Empty Trash", isPresented: $showEmptyTrashConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Empty Trash", role: .destructive) {
                store.emptyTrash()
            }
        } message: {
            Text("Are you sure you want to permanently erase the items in the Trash? This action cannot be undone.")
        }
        // Update actions when selection changes
        .onChange(of: selectedIconID) { _, _ in updateActions() }
        .onChange(of: selectedCategoryID) { _, _ in updateActions() }
        .onAppear { updateActions() }

    .focusedValue(\.editCategoryAction, cachedEditCategoryAction)
    .focusedValue(\.renameItemAction, cachedRenameItemAction)
    .focusedValue(\.deleteItemAction, cachedDeleteItemAction)
    }
    
    // MARK: - All Icons Row
    
    private var allIconsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .foregroundStyle(.blue)
                .font(.system(size: 16))
            
            Text("All Icons")
                .font(.body)
            
            Spacer()
            
            Text("\(store.icons.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .tag(allIconsID)
    }
    
    // MARK: - Uncategorized Section
    
    @ViewBuilder
    private var uncategorizedSection: some View {
        // Use searchedIcons from store and ignore category ID checks if we are searching
        let uncategorizedIcons = store.searchedIcons.filter { icon in
             icon.categoryID == nil || !store.categories.contains(where: { $0.id == icon.categoryID })
        }
        
        // Only show if we have items or if we are not searching
        if !searchText.isEmpty && uncategorizedIcons.isEmpty {
             EmptyView()
        } else if uncategorizedIcons.isEmpty {
            // Empty Uncategorized Row
            HStack(spacing: 8) {
                Image(systemName: "tray")
                    .foregroundStyle(.gray)
                    .font(.system(size: 16))
                
                Text("Uncategorized")
                    .font(.body)
                
                Spacer()
                
                Text("0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
            .padding(.leading, 4)
            .tag(uncategorizedID)
        } else {
            // Expandable Uncategorized Section
            DisclosureGroup(
                isExpanded: Binding(
                    get: { isUncategorizedExpanded || !searchText.isEmpty },
                    set: { isUncategorizedExpanded = $0 }
                ),
                content: {
                    ForEach(uncategorizedIcons) { icon in
                        SidebarIconRow(
                            icon: icon,
                            onRename: promptRename,
                             onDelete: promptDelete
                        )
                    }
                },
                label: {
                    HStack(spacing: 8) {
                        Image(systemName: "tray")
                            .foregroundStyle(.gray)
                            .font(.system(size: 16))
                        
                        Text("Uncategorized")
                            .font(.body)
                        
                        Spacer()
                        
                        Text("\(uncategorizedIcons.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .tag(uncategorizedID)
                }
            )
        }
    }
    
    // MARK: - Trash Row
    
    private var trashRow: some View {
        let trashCount = store.icons.filter { $0.isTrashed }.count
        
        return HStack(spacing: 8) {
            Image(systemName: trashCount > 0 ? "trash.fill" : "trash")
                .foregroundStyle(.gray)
                .font(.system(size: 16))
            
            Text("Trash")
                .font(.body)
            
            Spacer()
            
            Text("\(trashCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(8)
        }
        .tag(trashID)
        .contextMenu {
            Button(role: .destructive) {
                showEmptyTrashConfirmation = true
            } label: {
                Text("Empty Trash")
            }
            .disabled(trashCount == 0)
        }
        .onDrop(of: [.text], delegate: TrashDropDelegate(store: store))
    }
    
    
    // MARK: - Category Row
    
    private func categoryRow(for category: Category) -> some View {
        // Use filtered set from store
        let categoryIcons = store.searchedIcons.filter { $0.categoryID == category.id }
        
        return Group {
            if categoryIcons.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: category.iconName)
                        .foregroundStyle(category.color.color)
                        .font(.system(size: 16))
                    
                    Text(category.name)
                        .font(.body)
                    
                    Spacer()
                    
                    Text("0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)
                .padding(.leading, 4)
                .contentShape(Rectangle()) // Ensure entire row is droppable even if empty space
                .tag(category.id)
                .contextMenu {
                    Button {
                        editingCategory = category
                        showCategoryEditor = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        categoryToDelete = category
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } else {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { category.isExpanded || !searchText.isEmpty },
                        set: { _ in store.toggleCategoryExpansion(category.id) }
                    ),
                    content: {
                        ForEach(categoryIcons) { icon in
                            SidebarIconRow(
                                icon: icon,
                                onRename: promptRename,
                                onDelete: promptDelete
                            )
                        }
                    },
                    label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.iconName)
                                .foregroundStyle(category.color.color)
                                .font(.system(size: 16))
                            
                            Text(category.name)
                                .font(.body)
                            
                            Spacer()
                            
                            Text("\(store.iconCount(for: category))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .tag(category.id)
                        .contextMenu {
                            Button {
                                editingCategory = category
                                showCategoryEditor = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                categoryToDelete = category
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                )
            }
        }
        .onDrop(of: [.text], delegate: CategoryDropDelegate(
            category: category,
            store: store
        ))
    }
    
    // MARK: - Helper Functions
    
    private func updateActions() {
        // Edit Category
        if selectedIconID == nil,
           let categoryID = selectedCategoryID,
           let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                cachedEditCategoryAction = {
                    editingCategory = category
                    showCategoryEditor = true
                }
            } else {
                cachedEditCategoryAction = nil
            }
        } else {
            cachedEditCategoryAction = nil
        }
        
        // Rename Item
        if let iconID = selectedIconID,
           let icon = store.icons.first(where: { $0.id == iconID }) {
            cachedRenameItemAction = { promptRename(icon) }
        } else if selectedIconID == nil,
                  let categoryID = selectedCategoryID,
                  let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                cachedRenameItemAction = {
                    editingCategory = category
                    showCategoryEditor = true
                }
            } else {
                cachedRenameItemAction = nil
            }
        } else {
            cachedRenameItemAction = nil
        }
        
        // Delete Item
        if let iconID = selectedIconID,
           let icon = store.icons.first(where: { $0.id == iconID }) {
            cachedDeleteItemAction = { promptDelete(icon) }
        } else if selectedIconID == nil,
                  let categoryID = selectedCategoryID,
                  let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                cachedDeleteItemAction = {
                    categoryToDelete = category
                    showDeleteConfirmation = true
                }
            } else {
                cachedDeleteItemAction = nil
            }
        } else {
            cachedDeleteItemAction = nil
        }
    }
    
    // MARK: - Helper Computeds
    
    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedIconID ?? selectedCategoryID },
            set: { newValue in
                // Dispatch to main queue to avoid "Publishing changes from within view updates"
                // when List updates selection during layout passes.
                DispatchQueue.main.async {
                    // Only act if value actually changed
                    if newValue == (selectedIconID ?? selectedCategoryID) {
                        return
                    }
                    
                    if let uuid = newValue {
                        // Check if it's an icon by checking if it's in our known icon IDs
                        if store.icons.contains(where: { $0.id == uuid }) {
                             if selectedIconID != uuid {
                                 didNavigateFromGrid = false
                                 selectedIconID = uuid
                                 selectedCategoryID = nil
                             }
                        } else {
                            // Must be a category
                            if selectedCategoryID != uuid {
                                selectedIconID = nil
                                selectedCategoryID = uuid
                            }
                        }
                    } else {
                        // Deselect
                        if selectedIconID != nil || selectedCategoryID != nil {
                            selectedIconID = nil
                            didNavigateFromGrid = false
                            selectedCategoryID = nil
                        }
                    }
                }
            }
        )
    }

    private var filteredCategories: [Category] {
        store.categories.sorted(by: { $0.order < $1.order }).filter { category in
            if searchText.isEmpty { return true }
            if category.name.localizedCaseInsensitiveContains(searchText) { return true }
            return store.searchedIcons.contains { $0.categoryID == category.id }
        }
    }
    
    /// Pre-emptively validates and clears selection if the item is no longer visible in the current search.
    /// This prevents glitches where the List tries to update the selection asynchronously after the row disappears.
    private func validateSelection() {
        if searchText.isEmpty { return }
        
        // Check selected Icon
        if let iconID = selectedIconID {
            // If the icon is not in the searched results, deselect it immediately
            if !store.searchedIcons.contains(where: { $0.id == iconID }) {
                selectedIconID = nil
            }
        }
        
        // Check selected Category
        if let categoryID = selectedCategoryID {
            if categoryID == allIconsID || categoryID == uncategorizedID || categoryID == trashID {
                // These rows are generally handled specially
                if categoryID == uncategorizedID {
                     // Check if uncategorized section is visible
                     let hasUncategorized = store.searchedIcons.contains(where: { $0.categoryID == nil })
                     // Note: The UI logic for hiding uncategorized is:
                     // if !searchText.isEmpty && uncategorizedIcons.isEmpty { EmptyView() }
                     if !hasUncategorized {
                         selectedCategoryID = nil
                     }
                }
                // All Icons and Trash are always visible or logic dependent?
                // Trash logic from original code: Trash Row is in a Section.
                // Wait, in filtered view, Trash might still be there.
            } else {
                // Custom Category
                // Check if this category is in filteredCategories
                let isVisible = filteredCategories.contains(where: { $0.id == categoryID })
                if !isVisible {
                    selectedCategoryID = nil
                }
            }
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        store.moveCategories(from: source, to: destination)
    }
    
    private func promptRename(_ icon: Icon) {
        iconToRename = icon
        newIconName = icon.name
        showRenameIconAlert = true
    }
    
    private func promptDelete(_ icon: Icon) {
        iconToDelete = icon
        showIconDeleteConfirmation = true
    }
}

// MARK: - Sidebar Icon Row

private struct SidebarIconRow: View, Equatable {
    let icon: Icon
    let onRename: (Icon) -> Void
    let onDelete: (Icon) -> Void
    
    static func == (lhs: SidebarIconRow, rhs: SidebarIconRow) -> Bool {
        lhs.icon == rhs.icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let imageURL = icon.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure, .empty:
                        // Fallback or loading state (keep simple for sidebar)
                        Color.gray.opacity(0.3)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 16, height: 16)
                .cornerRadius(3)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: 16)
            }
            
            Text(icon.name)
                .font(.body)
        }
        .tag(icon.id)
        .draggable(icon.id.uuidString)
        .contextMenu {
            Button {
                onRename(icon)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete(icon)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Drop Delegate

struct CategoryDropDelegate: DropDelegate {
    let category: Category
    let store: IconStore
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            guard let data = data as? Data,
                  let uuidString = String(data: data, encoding: .utf8),
                  let iconID = UUID(uuidString: uuidString) else {
                return
            }
            
            DispatchQueue.main.async {
                store.moveIcon(withID: iconID, toCategoryID: category.id)
            }
        }
        
        return true
    }
}
 
 struct TrashDropDelegate: DropDelegate {
     let store: IconStore
     
     func performDrop(info: DropInfo) -> Bool {
         guard let itemProvider = info.itemProviders(for: [.text]).first else {
             return false
         }
         
         itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
             guard let data = data as? Data,
                   let uuidString = String(data: data, encoding: .utf8),
                   let iconID = UUID(uuidString: uuidString) else {
                 return
             }
             
             DispatchQueue.main.async {
                 store.moveIcon(withID: iconID, toCategoryID: Category.trashID)
             }
         }
         
         return true
     }
 }
 
 #Preview {
    CategorySidebarView(
        selectedIconID: .constant(nil),
        selectedCategoryID: .constant(nil),
        didNavigateFromGrid: .constant(false),
        isSidebarSearching: .constant(false)
    )
    .environmentObject(IconStore())
    .frame(width: 250)
}
