//
//  InspectorView.swift
//  ICNS
//
//  Created by Ioannis Notaris on 6/1/25.
//

import SwiftUI

struct InspectorView: View {
    @Binding var icon: Icon
    
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
        }
        .formStyle(.grouped)
        .padding()
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
