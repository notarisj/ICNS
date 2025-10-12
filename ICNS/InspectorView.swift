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
        VStack(alignment: .leading, spacing: 12) {
            // Text("Inspector")
            //     .font(.title2)
            
            // Divider()
            
            // Icon name
            Text("Icon Name:")
                .fontWeight(.semibold)
            TextField("", text: $icon.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Output directory
            Text("Output Directory:")
                .fontWeight(.semibold)
            Text(formatDirectory(url: URL(string: icon.outputDirectory ?? "")))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Button("Select Output Directory") {
                selectOutputDirectory()
            }
            .buttonStyle(LinkButtonStyle())
            
            Divider()
            
            // Icon information
            if let data = icon.image,
               let nsImg = NSImage(data: data) {
                Text("Icon Dimensions: \(Int(nsImg.size.width))x\(Int(nsImg.size.height))")
                    .font(.subheadline)
            } else {
                Text("No image selected")
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Functions
    
    func formatDirectory(url: URL?) -> String {
        guard let url = url else {
            return "Not Selected"
        }
        let path = url.absoluteString
        if let range = path.range(of: "file://") {
            return String(path[range.upperBound...])
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

