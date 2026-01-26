//
//  InspectorView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 6/1/25.
//

import SwiftUI

struct InspectorView: View {
    @Binding var icon: Icon
    @AppStorage("showImageBorder") private var showImageBorder = true
    @EnvironmentObject var profileStore: ProfileStore
    
    @State private var showProfilesManagement = false
    
    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $icon.name)
            }
            
            Section("Export Settings") {
                LabeledContent("Location") {
                    HStack {
                        Text(formatDirectory(url: URL(string: icon.outputDirectory ?? "")))
                            .truncationMode(.middle)
                            .foregroundStyle(.secondary)
                            .help(icon.outputDirectory ?? "Not Selected")
                        
                        Spacer()
                        
                        Button {
                            selectOutputDirectory()
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Change output directory")
                    }
                }
            }
            
            Section("Export Profile") {
                VStack(alignment: .leading, spacing: 8) {
                    ProfilePicker(
                        selectedProfileID: $icon.selectedProfileID,
                        profiles: profileStore.profiles
                    )
                    
                    Button {
                        showProfilesManagement = true
                    } label: {
                        Label("Manage Profiles", systemImage: "square.stack.3d.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            Section("Master Image") {
                if let data = icon.image, let nsImg = NSImage(data: data) {
                    VStack(spacing: 12) {
                        LabeledContent("Dimensions", value: "\(Int(nsImg.size.width)) × \(Int(nsImg.size.height))")
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("No image selected")
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
            
            Section("Display") {
                Toggle("Show Border", isOn: $showImageBorder)
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showProfilesManagement) {
            ExportProfilesView(profileStore: profileStore)
        }
        .onTapGesture {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }
    
    // MARK: - Functions
    
    func formatDirectory(url: URL?) -> String {
        guard let url = url else {
            return "Not Selected"
        }
        let path = url.absoluteString
        if let range = path.range(of: "file://") {
            return String(path[range.upperBound...]).removingPercentEncoding ?? path
        } else {
            return path
        }
    }
    
    func selectOutputDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.begin { (result) in
            if result == .OK {
                if let url = openPanel.url {
                    let accessGranted = url.startAccessingSecurityScopedResource()
                    if accessGranted {
                        icon.outputDirectory = url.absoluteString
                        do {
                            let bookmarkData = try url.bookmarkData(options: .withSecurityScope,
                                                                    includingResourceValuesForKeys: nil,
                                                                    relativeTo: nil)
                            UserDefaults.standard.set(bookmarkData, forKey: "outputDirectoryBookmark")
                        } catch {
                            print("Failed to save bookmark data for \(url): \(error)")
                        }
                    } else {
                        print("Access to the directory was denied.")
                    }
                }
            }
        }
    }
}
