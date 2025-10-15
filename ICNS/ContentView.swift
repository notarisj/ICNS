//
//  ContentView.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI

struct ContentView: View {
    @State private var icons: [Icon] = []
    @State private var selectedIcon: Icon? = nil
    @State private var showDeleteConfirmation = false
    @State private var showInspector = true
    @State private var showAddIconSheet = false
    @State private var newIconName = ""

    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR
            List(selection: $selectedIcon) {
                ForEach(icons) { icon in
                    Text(icon.name)
                        .tag(icon)
                }
                .onMove(perform: moveIcons)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 300)
            .navigationTitle("Icons")

        } detail: {
            // MAIN CONTENT AREA
            Group {
                if let iconIndex = icons.firstIndex(where: { $0.id == selectedIcon?.id }) {
                    IconView(
                        icon: $icons[iconIndex],
                        icons: $icons,
                        selectedIcon: $selectedIcon,
                        showInspector: $showInspector,
                        showAddIconSheet: $showAddIconSheet,
                        showDeleteConfirmation: $showDeleteConfirmation
                    )
                } else {
                    VStack {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Drop Image Here")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(currentIconName)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackground(.hidden, for: .automatic)
        .inspector(isPresented: $showInspector) {
            if let bindingIcon = bindingForSelectedIcon() {
                InspectorView(icon: bindingIcon)
                    .inspectorColumnWidth(min: 250, ideal: 280, max: 350)
            } else {
                VStack {
                    Text("No icon selected")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .inspectorColumnWidth(min: 250, ideal: 280, max: 350)
            }
        }
        .onAppear {
            loadIcons()
            if selectedIcon == nil, !icons.isEmpty {
                selectedIcon = icons.first
            }
        }
        .onChange(of: icons) { _ in
            saveIcons()
            if selectedIcon == nil, !icons.isEmpty {
                selectedIcon = icons.first
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
                    if let toDelete = selectedIcon {
                        deleteIcon(icon: toDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func bindingForSelectedIcon() -> Binding<Icon>? {
        guard let selectedIcon = selectedIcon,
              let index = icons.firstIndex(where: { $0.id == selectedIcon.id }) else {
            return nil
        }
        return $icons[index]
    }
    
    private var addIconSheet: some View {
        VStack(spacing: 20) {
            Text("Enter a name for the new icon:")
                .font(.headline)
            
            TextField("Icon name", text: $newIconName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            
            HStack {
                Button("Cancel") {
                    showAddIconSheet = false
                    newIconName = ""
                }
                Button("Create") {
                    addIcon(named: newIconName)
                    showAddIconSheet = false
                    newIconName = ""
                }
                .disabled(newIconName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(minWidth: 300)
    }
    
    private func addIcon(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty { return }
        
        var finalName = trimmedName
        var counter = 2
        while icons.contains(where: { $0.name == finalName }) {
            finalName = "\(trimmedName) \(counter)"
            counter += 1
        }
        
        let newIcon = Icon(name: finalName, image: nil as NSImage?, outputDirectory: nil as URL?)
        icons.append(newIcon)
        selectedIcon = newIcon
    }
    
    private func moveIcons(from source: IndexSet, to destination: Int) {
        // Remember the currently selected icon
        let selectedIconId = selectedIcon?.id
        
        // Perform the move operation
        icons.move(fromOffsets: source, toOffset: destination)
        
        // Restore the selection after reordering
        if let selectedId = selectedIconId {
            selectedIcon = icons.first { $0.id == selectedId }
        }
        
        // Save the new order
        saveIcons()
    }
    
    private func deleteIcon(icon: Icon) {
        if let index = icons.firstIndex(where: { $0.id == icon.id }) {
            icons.remove(at: index)
            
            if icons.indices.contains(index) {
                selectedIcon = icons[index]
            } else if index > 0 {
                selectedIcon = icons[index - 1]
            } else {
                selectedIcon = nil
            }
        }
    }
    
    private func loadIcons() {
        if let savedIconsData = UserDefaults.standard.data(forKey: "icons") {
            do {
                let savedIcons = try JSONDecoder().decode([Icon].self, from: savedIconsData)
                icons = savedIcons
            } catch {
                print("Error decoding icons: \(error)")
            }
        }
    }
    
    private func saveIcons() {
        do {
            let iconsData = try JSONEncoder().encode(icons)
            UserDefaults.standard.set(iconsData, forKey: "icons")
        } catch {
            print("Error encoding icons: \(error)")
        }
    }
    
    // Add this computed property
    private var currentIconName: String {
        guard let selectedIcon = selectedIcon,
              let iconIndex = icons.firstIndex(where: { $0.id == selectedIcon.id }) else {
            return "ICNS"
        }
        return icons[iconIndex].name
    }
}