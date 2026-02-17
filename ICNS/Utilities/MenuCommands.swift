//
//  MenuCommands.swift
//  ICNS
//
//  Created by Ioannis Notaris on 29/1/26.
//

import SwiftUI

// MARK: - Focused Value Keys
struct FocusedEditCategoryKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct FocusedRemoveImageKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct FocusedResetViewKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct FocusedRenameItemKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct FocusedDeleteItemKey: FocusedValueKey {
    typealias Value = () -> Void
}

struct ShowInspectorKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var editCategoryAction: FocusedEditCategoryKey.Value? {
        get { self[FocusedEditCategoryKey.self] }
        set { self[FocusedEditCategoryKey.self] = newValue }
    }
    
    var removeImageAction: FocusedRemoveImageKey.Value? {
        get { self[FocusedRemoveImageKey.self] }
        set { self[FocusedRemoveImageKey.self] = newValue }
    }
    
    var resetViewAction: FocusedResetViewKey.Value? {
        get { self[FocusedResetViewKey.self] }
        set { self[FocusedResetViewKey.self] = newValue }
    }
    
    var renameItemAction: FocusedRenameItemKey.Value? {
        get { self[FocusedRenameItemKey.self] }
        set { self[FocusedRenameItemKey.self] = newValue }
    }
    
    var deleteItemAction: FocusedDeleteItemKey.Value? {
        get { self[FocusedDeleteItemKey.self] }
        set { self[FocusedDeleteItemKey.self] = newValue }
    }
    
    var showInspector: Binding<Bool>? {
        get { self[ShowInspectorKey.self] }
        set { self[ShowInspectorKey.self] = newValue }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let newIconSet = Notification.Name("newIconSet")
    static let newCategory = Notification.Name("newCategory")
}

// MARK: - Menu Commands
struct MenuCommands: Commands {
    @FocusedValue(\.editCategoryAction) var editCategory
    @FocusedValue(\.removeImageAction) var removeImage
    @FocusedValue(\.resetViewAction) var resetView
    @FocusedValue(\.renameItemAction) var renameItem
    @FocusedValue(\.deleteItemAction) var deleteItem
    @FocusedValue(\.searchFocus) var searchFocus
    
    var body: some Commands {
        // Replace "New" item
        CommandGroup(replacing: .newItem) {
            Button {
                NotificationCenter.default.post(name: .newIconSet, object: nil)
            } label: {
                Label("New Icon Set", systemImage: "app.dashed")
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button {
                NotificationCenter.default.post(name: .newCategory, object: nil)
            } label: {
                Label("New Category", systemImage: "folder.badge.plus")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
        
        // Add "Edit Category" to File menu or Edit menu?
        // User requested "Edit Category" explicitly. Often this fits in Edit > Rename area, or File.
        // Let's put it in Edit.
        
        CommandGroup(after: .pasteboard) {
            Divider()
            
            Button {
                editCategory?()
            } label: {
                Label("Edit Category", systemImage: "pencil")
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(editCategory == nil)
            
            Button {
                renameItem?()
            } label: {
                Label("Rename", systemImage: "pencil.line")
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(renameItem == nil)
            
            Button(role: .destructive) {
                deleteItem?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(deleteItem == nil)
            
            Divider()
            
            Button {
                searchFocus?.wrappedValue = true
            } label: {
                Label("Find", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(searchFocus == nil)
        }
}
}
