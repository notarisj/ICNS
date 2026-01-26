//
//  ContentView.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: IconStore
    @State private var selectedIconID: Icon.ID? = nil
    @State private var showDeleteConfirmation = false
    @State private var showInspector = true
    @State private var showAddIconSheet = false
    @State private var newIconName = ""

    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR
            List(selection: $selectedIconID) {
                ForEach(store.icons) { icon in
                    Text(icon.name)
                        .tag(icon.id)
                }
                .onMove(perform: moveIcons)
                
                // Deselection Area
                Color.gray.opacity(0.01)
                    .frame(minHeight: 500)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIconID = nil
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .scrollContentBackground(.hidden)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 300)
            .navigationTitle("Icons")

        } detail: {
            // MAIN CONTENT AREA
            Group {
                if let iconIndex = store.icons.firstIndex(where: { $0.id == selectedIconID }) {
                    IconView(
                        icon: $store.icons[iconIndex],
                        icons: $store.icons,
                        showInspector: $showInspector,
                        showAddIconSheet: $showAddIconSheet,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                } else {
                    WelcomeView(showInspector: $showInspector)
                }
            }
            .navigationTitle(currentIconName)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        showAddIconSheet = true
                    } label: {
                        Label("New Icon", systemImage: "plus")
                    }
                    .help("Create a new icon")
                    
                    Button {
                        if selectedIconID != nil {
                            showDeleteConfirmation = true
                        }
                    } label: {
                        Label("Delete Icon", systemImage: "minus")
                    }
                    .help("Delete the selected icon")
                    .disabled(selectedIconID == nil)
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
    }
    
    // MARK: - Helper Views
    
    struct WelcomeView: View {
        @Binding var showInspector: Bool
        
        var body: some View {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "app.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                }
                
                VStack(spacing: 8) {
                    Text("Welcome to ICNS")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create a new icon set to start generating\nicons for macOS and iOS.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.square")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Set")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Click + in the toolbar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 150, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundStyle(.purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Drag & Drop")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Add your master image")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 150, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Generate icons & ICNS")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 150, alignment: .leading)
                }
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        WindowHelper.toggleInspectorWithResize($showInspector)
                    } label: {
                        Label("Inspector", systemImage: "slider.horizontal.3")
                    }
                    .help("Show or hide the inspector panel")
                }
            }
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
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    showAddIconSheet = false
                    newIconName = ""
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Create") {
                    addIcon(named: newIconName)
                    showAddIconSheet = false
                    newIconName = ""
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
    
    private func addIcon(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { return }
        
        var finalName = trimmedName
        var counter = 2
        while store.icons.contains(where: { $0.name == finalName }) {
            finalName = "\(trimmedName) \(counter)"
            counter += 1
        }
        
        let newIcon = Icon(name: finalName, image: nil as NSImage?, outputDirectory: nil as URL?)
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
}
