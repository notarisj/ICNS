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
    
    // Special IDs for All Icons and Uncategorized
    private let allIconsID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let uncategorizedID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    
    var body: some View {
        List(selection: Binding(
            get: { selectedIconID ?? selectedCategoryID },
            set: { newValue in
                if let uuid = newValue {
                    // Check if it's an icon or category
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
        )) {
            // "All Icons" - simple clickable row (no nested icons)
            allIconsRow
            
            // Categories section with Uncategorized first, then custom categories
            Section {
                // Custom categories
                let filteredCategories = store.categories.sorted(by: { $0.order < $1.order }).filter { category in
                    if searchText.isEmpty { return true }
                    if category.name.localizedCaseInsensitiveContains(searchText) { return true }
                    return store.icons(for: category).contains { $0.name.localizedCaseInsensitiveContains(searchText) }
                }
                
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
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search")
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
        // Include icons that are truly uncategorized OR have an invalid category ID (orphans)
        let uncategorizedIcons = store.icons.filter { icon in
            let isUncategorized = icon.categoryID == nil || !store.categories.contains(where: { $0.id == icon.categoryID })
            return isUncategorized && (searchText.isEmpty || icon.name.localizedCaseInsensitiveContains(searchText))
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
                            iconRow(for: icon)
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
        let categoryIcons = store.icons(for: category).filter { 
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
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
                        iconRow(for: icon)
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
            }
        )
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
        .onDrop(of: [.text], delegate: CategoryDropDelegate(
            category: category,
            store: store
        ))
    }
    
    // MARK: - Icon Row
    
    private func iconRow(for icon: Icon) -> some View {
        HStack(spacing: 8) {
            if let imageData = icon.image,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
    }
    
    // MARK: - Helper Functions
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        store.moveCategories(from: source, to: destination)
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
