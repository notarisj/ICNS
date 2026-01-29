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
    @State private var showCategoryEditor = false
    @State private var editingCategory: Category? = nil
    @State private var showDeleteConfirmation = false
    @State private var categoryToDelete: Category? = nil
    @State private var isUncategorizedExpanded = true
    @State private var searchText = ""
    @State private var isSearchPresented = false
    
    // Icon Context Menu States
    @State private var iconToDelete: Icon? = nil
    @State private var showIconDeleteConfirmation = false
    @State private var iconToRename: Icon? = nil
    @State private var showRenameIconAlert = false
    @State private var newIconName = ""
    
    // Special IDs for All Icons and Uncategorized
    private let allIconsID = Category.allIconsID
    private let uncategorizedID = Category.uncategorizedID
    
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
        }
        .searchable(text: $searchText, isPresented: $isSearchPresented, placement: .sidebar, prompt: "Search")
        .onChange(of: searchText) { newValue in
            store.updateSearchText(newValue)
        }
        .background {
            Button("Find") {
                isSearchPresented = true
            }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0)
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
                Text("Are you sure you want to delete \"\(icon.name)\"? This action cannot be undone.")
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


    .focusedValue(\.editCategoryAction, editCategoryAction)
    .focusedValue(\.renameItemAction, renameItemAction)
    .focusedValue(\.deleteItemAction, deleteItemAction)
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
    
    private var uncategorizedSection: some View {
        // Use searchedIcons from store and ignore category ID checks if we are searching (since we want global results?)
        // Wait, "Uncategorized" section should strictly show uncategorized icons matching search.
        
        let uncategorizedIcons = store.searchedIcons.filter { icon in
             icon.categoryID == nil || !store.categories.contains(where: { $0.id == icon.categoryID })
        }
        
        // Hide section if searching and no matches
        if !searchText.isEmpty && uncategorizedIcons.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            DisclosureGroup(
                isExpanded: Binding(
                    get: { isUncategorizedExpanded || !searchText.isEmpty },
                    set: { isUncategorizedExpanded = $0 }
                ),
                content: {
                    if uncategorizedIcons.isEmpty {
                        Text("No uncategorized icons")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 24)
                    } else {
                        ForEach(uncategorizedIcons) { icon in
                            SidebarIconRow(
                                icon: icon,
                                onRename: promptRename,
                                onDelete: promptDelete
                            )
                        }
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
                        
                        let count = store.icons.filter { icon in
                            icon.categoryID == nil || !store.categories.contains(where: { $0.id == icon.categoryID })
                        }.count
                        
                        Text("\(count)")
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
        )
    }
    
    // MARK: - Category Row
    
    private func categoryRow(for category: Category) -> some View {
        // Use filtered set from store
        let categoryIcons = store.searchedIcons.filter { $0.categoryID == category.id }
        
        return DisclosureGroup(
            isExpanded: Binding(
                get: { category.isExpanded || !searchText.isEmpty },
                set: { _ in store.toggleCategoryExpansion(category.id) }
            ),
            content: {
                if categoryIcons.isEmpty {
                    if searchText.isEmpty {
                        Text("No icons")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 24)
                    } else {
                        EmptyView()
                    }
                } else {
                    ForEach(categoryIcons) { icon in
                        SidebarIconRow(
                            icon: icon,
                            onRename: promptRename,
                            onDelete: promptDelete
                        )
                    }
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
        .onDrop(of: [.text], delegate: CategoryDropDelegate(
            category: category,
            store: store
        ))
    }
    
    // MARK: - Icon Row
    
    // MARK: - Helper Functions
    
    // MARK: - Focused Value Actions
    
    // MARK: - Helper Computeds
    
    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedIconID ?? selectedCategoryID },
            set: { newValue in
                if let uuid = newValue {
                    if store.icons.contains(where: { $0.id == uuid }) {
                        selectedIconID = uuid
                    } else {
                        selectedIconID = nil
                        selectedCategoryID = uuid
                    }
                } else {
                    selectedIconID = nil
                    selectedCategoryID = nil
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
    
    private var editCategoryAction: (() -> Void)? {
        if selectedIconID == nil,
           let categoryID = selectedCategoryID,
           let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                return {
                    editingCategory = category
                    showCategoryEditor = true
                }
            }
        }
        return nil
    }
    
    private var renameItemAction: (() -> Void)? {
        if let iconID = selectedIconID,
           let icon = store.icons.first(where: { $0.id == iconID }) {
            return { promptRename(icon) }
        } else if selectedIconID == nil,
                  let categoryID = selectedCategoryID,
                  let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                return {
                    editingCategory = category
                    showCategoryEditor = true
                }
            }
        }
        return nil
    }
    
    private var deleteItemAction: (() -> Void)? {
        if let iconID = selectedIconID,
           let icon = store.icons.first(where: { $0.id == iconID }) {
            return { promptDelete(icon) }
        } else if selectedIconID == nil,
                  let categoryID = selectedCategoryID,
                  let category = store.categories.first(where: { $0.id == categoryID }) {
            let allIconsID = Category.allIconsID
            let uncategorizedID = Category.uncategorizedID
            
            if categoryID != allIconsID && categoryID != uncategorizedID {
                return {
                    categoryToDelete = category
                    showDeleteConfirmation = true
                }
            }
        }
        return nil
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

#Preview {
    CategorySidebarView(
        selectedIconID: .constant(nil),
        selectedCategoryID: .constant(nil)
    )
    .environmentObject(IconStore())
    .frame(width: 250)
}
