//
//  ContentView.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI

struct ContentView: View {
    @State private var icons: [Icon] = []
    @State private var selectedIndex: Int? = nil
    @State private var showDeleteConfirmation = false
    @State private var iconCount = 0
    
    init() {
        loadIcons()
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(icons.indices, id: \.self) { index in
                    NavigationLink(destination: LazyView(IconView(icon: $icons[index])), tag: index, selection: $selectedIndex) {
                        Text(icons[index].name)
                    }
                }
                .onDelete { indexSet in
                    self.showDeleteConfirmation = true
                }
            }
            .onChange(of: icons) {
                saveIcons()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.left")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: addIcon) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        if selectedIndex != nil {
                            self.showDeleteConfirmation = true
                        }
                    }) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedIndex == nil)
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Remove Icon"),
                            message: Text("Are you sure you want to remove this icon?"),
                            primaryButton: .destructive(Text("Remove")) {
                                if let selectedIndex = selectedIndex {
                                    self.deleteIcon(at: selectedIndex)
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
        .onAppear {
            loadIcons() // Ensure icons are loaded when the view appears
            if !icons.isEmpty {
                selectedIndex = 0
            }
        }
    }
    
    func addIcon() {
        var uniqueNameFound = false
        var newIconName = ""
        
        while !uniqueNameFound {
            iconCount += 1
            newIconName = "icon\(iconCount)"
            
            if !icons.contains(where: { $0.name == newIconName }) {
                uniqueNameFound = true
            }
        }
        
        let newIcon = Icon(name: newIconName, image: nil, outputDirectory: nil)
        icons.append(newIcon)
    }
    
    func deleteIcon(at index: Int) {
        self.icons.remove(at: index)
        if icons.indices.contains(index) {
            // If the next item exists, select it
            self.selectedIndex = index
        } else if index > 0 {
            // Otherwise, select the previous item
            self.selectedIndex = index - 1
        } else {
            // If no items are left, create a new empty item and select it
            addIcon()
            self.selectedIndex = icons.count - 1
        }
    }
    
    func loadIcons() {
        if let savedIconsData = UserDefaults.standard.data(forKey: "icons") {
            do {
                let savedIcons = try JSONDecoder().decode([Icon].self, from: savedIconsData)
                print("Loaded icons: \(savedIcons)")
                icons = savedIcons
            } catch {
                print("Error decoding icons: \(error)")
            }
        }
    }
    
    func saveIcons() {
        do {
            let iconsData = try JSONEncoder().encode(icons)
            print("Saving icons: \(icons)")
            UserDefaults.standard.set(iconsData, forKey: "icons")
        } catch {
            print("Error encoding icons: \(error)")
        }
    }
    
    func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}
