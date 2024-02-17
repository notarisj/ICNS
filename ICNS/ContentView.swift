//
//  ContentView.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var image: NSImage? = nil
    @State private var outputDirectory: URL? = nil
    @State private var iconName: String = "icon"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var iconsGenerated = false
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if let img = image {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                } else {
                    VStack {
                        Image(systemName: "plus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Drag and Drop Image Here")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: 400, maxHeight: 400)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 8, dash: [20]))
                            .foregroundColor(.gray)
                    )
                    .onDrop(of: [UTType.image], isTargeted: nil) { providers -> Bool in
                        providers.first?.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier, completionHandler: { (data, error) in
                            if let data = data, let nsImage = NSImage(data: data) {
                                self.image = nsImage
                            }
                        })
                        return true
                    }
                    .onTapGesture {
                        selectImage()
                    }
                }
            }
            Spacer().frame(height: 15)
            TextField("Icon Name", text: $iconName)
                .padding(.horizontal)
            Text("Output Directory: \(formatDirectory(url: outputDirectory))")
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(25)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: selectOutputDirectory) {
                    Label("Select Output Directory", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: generateIcons) {
                    Label("Generate Icons", systemImage: "square.grid.2x2")
                }
                .disabled(image == nil || outputDirectory == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: generateICNS) {
                    Label("Generate ICNS", systemImage: "doc.append")
                }
                .disabled(!iconsGenerated)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: clearImage) {
                    Label("Clear Image", systemImage: "xmark.circle")
                }
            }
        }
    }
    
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
    
    func selectImage() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType.jpeg, UTType.png, UTType.gif, UTType.tiff, UTType.bmp]
        openPanel.begin { (result) in
            if result == .OK {
                if let url = openPanel.url, let nsImage = NSImage(contentsOf: url) {
                    self.image = nsImage
                }
            }
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
                        outputDirectory = url
                    } else {
                        // Handle the case where access is denied.
                        print("Access to the directory was denied.")
                    }
                }
            }
        }
    }
    
    func generateIcons() {
        guard let image = image, let outputDirectory = outputDirectory else { return }
        
        let sizes = [16, 32, 128, 256, 512]
        
        // Create a new .iconset folder
        let iconsetFolder = outputDirectory.appendingPathComponent("\(iconName).iconset")
        do {
            try FileManager.default.createDirectory(at: iconsetFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating .iconset folder: \(error)")
            return
        }
        
        for size in sizes {
            for scale in [1, 2] {
                let scaledSize = NSSize(width: size*scale, height: size*scale)
                let newImage = image.resize(to: scaledSize)
                let scaleSuffix = scale == 2 ? "@2x" : ""
                let filename = "icon_\(size)x\(size)\(scaleSuffix).png"
                let fileURL = iconsetFolder.appendingPathComponent(filename)
                newImage.save(as: .png, to: fileURL)
            }
        }
        
        outputDirectory.stopAccessingSecurityScopedResource()
        
        // Display alert
        self.iconsGenerated = true
        self.alertMessage = "Icons have been successfully created at \(iconsetFolder.path)!"
        self.showAlert = true
    }
    
    func generateICNS() {
        guard let outputDirectory = outputDirectory else { return }
        
        let iconsetFolder = outputDirectory.appendingPathComponent("\(iconName).iconset")
        
        // Convert the .iconset folder to an .icns file
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetFolder.path]
        process.launch()
        
        // Display alert
        let icnsFilePath = outputDirectory.appendingPathComponent("\(iconName).icns").path
        self.alertMessage = "ICNS file has been successfully created at \(icnsFilePath)!"
        self.showAlert = true
    }
    
    func clearImage() {
        self.image = nil
        self.iconName = "icon"
        self.iconsGenerated = false  // Reset iconsGenerated when the image is cleared
        self.outputDirectory = nil
    }
}
