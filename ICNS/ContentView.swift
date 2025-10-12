import SwiftUI

struct ContentView: View {
    @State private var icons: [Icon] = []
    @State private var selectedIcon: Icon? = nil
    @State private var showDeleteConfirmation = false
    
    // Shows/hides the right inspector
    @State private var showInspector = true
    
    // Prompt user for new icon name
    @State private var showAddIconSheet = false
    @State private var newIconName = ""
    
    var body: some View {
        NavigationSplitView {
            // LEFT SIDEBAR
            List(icons, selection: $selectedIcon) { icon in
                Text(icon.name)
                    .tag(icon) // Ensure proper tagging for selection
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            
        } detail: {
            // CONTENT + INSPECTOR SIDE BY SIDE
            HStack(spacing: 0) {
                // MAIN CONTENT
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // "Drop image here" / "Select or create an Icon"
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
                // This ensures the main content expands to fill remaining space
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // INSPECTOR (conditionally shown)
                if showInspector {
                    Divider()
                    
                    if let bindingIcon = bindingForSelectedIcon() {
                        InspectorView(icon: bindingIcon)
                            .frame(width: 250)
                            .transition(.move(edge: .trailing))
                    } else {
                        Text("No icon selected")
                            .frame(width: 250)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            // Animate inspector's show/hide
            .animation(.default, value: showInspector)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(selectedIcon?.name ?? "ICNS")
        
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
}
