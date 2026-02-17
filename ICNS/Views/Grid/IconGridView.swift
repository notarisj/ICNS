//
//  IconGridView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 26/1/26.
//

import SwiftUI

struct IconGridView: View {
    let icons: [Icon]
    @EnvironmentObject var store: IconStore
    let categoryName: String?
    @Binding var selectedIconID: Icon.ID?
    @Binding var showInspector: Bool
    @Binding var didNavigateFromGrid: Bool
    @State private var showEmptyTrashConfirmation = false
    @State private var showRestoreIconConfirmation = false
    @State private var iconToRestore: Icon? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 16)
    ]
    
    var body: some View {
        if icons.isEmpty {
            if categoryName == "Trash" {
                VStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Trash is Empty")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let name = categoryName, name != "All Icons" {
                VStack(spacing: 12) {
                     Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No icons in \(name)")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                WelcomeView(showInspector: $showInspector)
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(icons) { icon in
                        IconGridItem(icon: icon, isSelected: selectedIconID == icon.id)
                            .onTapGesture {
                                if icon.isTrashed {
                                    iconToRestore = icon
                                    showRestoreIconConfirmation = true
                                    // Deselect if it was somehow selected
                                    if selectedIconID == icon.id {
                                        selectedIconID = nil
                                    }
                                } else {
                                    didNavigateFromGrid = true
                                    selectedIconID = icon.id
                                }
                            }
                            .contextMenu {
                                if icon.isTrashed {
                                    Button {
                                        store.restoreIcon(withID: icon.id)
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        store.permanentlyDeleteIcon(withID: icon.id)
                                    } label: {
                                        Label("Delete Immediately", systemImage: "trash.fill")
                                    }
                                } else {
                                    Button(role: .destructive) {
                                        store.removeIcon(withID: icon.id)
                                    } label: {
                                        Label("Move to Trash", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .padding()
            }
            .alert("Empty Trash", isPresented: $showEmptyTrashConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Empty Trash", role: .destructive) {
                    store.emptyTrash()
                }
            } message: {
                Text("Are you sure you want to permanently erase the items in the Trash? This action cannot be undone.")
            }
            .alert("Restore Icon", isPresented: $showRestoreIconConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore") {
                    if let icon = iconToRestore {
                        store.restoreIcon(withID: icon.id)
                    }
                }
            } message: {
                if let icon = iconToRestore {
                    Text("Do you want to put \"\(icon.name)\" back in its original location?")
                } else {
                    Text("Do you want to put this icon back in its original location?")
                }
            }
        }
    }

}

struct IconGridItem: View {
    let icon: Icon
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                
                if let imageURL = icon.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                             ProgressView()
                                .controlSize(.small)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 64, height: 64)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 100)
            
            Text(icon.name)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(width: 100)
    }
}

#Preview {
    IconGridView(icons: [], categoryName: "All Icons", selectedIconID: .constant(nil), showInspector: .constant(true), didNavigateFromGrid: .constant(false))
}
