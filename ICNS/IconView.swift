//
//  IconView.swift
//  ICNS
//
//  Created by John Notaris on 7/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct IconView: View {
    @Binding var icon: Icon
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Success"
    @State private var iconsGenerated = false
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                ZStack {
                    if let imgData = icon.image, let img = NSImage(data: imgData) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300, maxHeight: 300)
                    } else {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Spacer().frame(height: 20)
                            Text("Drop Image Here")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: 200, maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 8, dash: [25]))
                                .foregroundColor(.gray)
                        )
                        .onDrop(of: [UTType.image], isTargeted: nil) { providers -> Bool in
                            providers.first?.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier, completionHandler: { (data, error) in
                                if let data = data {
                                    self.icon.image = data
                                }
                            })
                            return true
                        }
                        .onTapGesture {
                            selectImage()
                        }
                    }
                }
                
            }
            Spacer() // This will push the above VStack to the top
            TextField("Icon Name", text: $icon.name)
            //                .padding(.horizontal)
                .onChange(of: icon.name) {
                    iconsGenerated = false
                }
            Text("Output Directory: \(formatDirectory(url: URL(string: icon.outputDirectory ?? "")))")
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(25)
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: selectOutputDirectory) {
                    Label("Select Output Directory", systemImage: "folder.badge.plus")
                }
                .help("Select Output Directory")
            }
            ToolbarItem(placement: .principal) {
                Button(action: generateIcons) {
                    Label("Generate Icons", systemImage: "gearshape.fill")
                }
                .help("Generate Icons")
                .disabled(self.icon.image == nil || icon.outputDirectory == nil)
            }
            ToolbarItem(placement: .principal) {
                Button(action: generateICNS) {
                    Label("Generate ICNS", systemImage: "doc.badge.gearshape")
                }
                .help("Generate ICNS")
                .disabled(!iconsGenerated)
            }
            ToolbarItem(placement: .principal) {
                Button(action: clearImage) {
                    Label("Clear Icon", systemImage: "trash")
                }
                .help("Clear Icon")
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
                    self.icon.image = nsImage.tiffRepresentation
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
                        icon.outputDirectory = url.absoluteString
                        do {
                            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                            UserDefaults.standard.set(bookmarkData, forKey: "outputDirectoryBookmark")
                        } catch {
                            print("Failed to save bookmark data for \(url): \(error)")
                        }
                    } else {
                        // Handle the case where access is denied.
                        print("Access to the directory was denied.")
                    }
                }
            }
        }
    }
    
    func generateIcons() {
        guard let imageData = icon.image, let image = NSImage(data: imageData), let outputDirectoryString = self.icon.outputDirectory, let outputDirectoryURL = URL(string: outputDirectoryString) else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
            // Handle the case where access is denied.
            self.alertMessage = "Access to the directory was denied. Select the output directory and try again."
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        let sizes = [16, 32, 128, 256, 512]
        
        // Create a new .iconset folder
        let iconsetFolder = outputDirectoryURL.appendingPathComponent("\(icon.name).iconset")
        do {
            try FileManager.default.createDirectory(at: iconsetFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // Display error alert
            self.alertMessage = "Error creating .iconset folder: \(error)"
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        for size in sizes {
            for scale in [1, 2] {
                let scaledSize = NSSize(width: size*scale, height: size*scale)
                let newImage = image.resizeImage(to: scaledSize)
                let scaleSuffix = scale == 2 ? "@2x" : ""
                let filename = "icon_\(size)x\(size)\(scaleSuffix).png"
                let fileURL = iconsetFolder.appendingPathComponent(filename)
                newImage.saveImage(as: .png, to: fileURL)
            }
        }
        
        outputDirectoryURL.stopAccessingSecurityScopedResource()
        
        // Display success alert
        self.alertMessage = "Icons have been successfully created at \(iconsetFolder.path)!"
        self.alertTitle = "Success"
        self.iconsGenerated = true
        self.showAlert = true
    }
    
    func generateICNS() {
        guard let outputDirectoryString = self.icon.outputDirectory, let outputDirectoryURL = URL(string: outputDirectoryString) else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
            // Handle the case where access is denied.
            self.alertMessage = "Access to the directory was denied. Select the output directory and try again."
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        let iconsetFolder = outputDirectoryURL.appendingPathComponent("\(icon.name).iconset")
        
        // Convert the .iconset folder to an .icns file
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        process.arguments = ["-c", "icns", iconsetFolder.path]
        
        // Setup the pipes to capture standard output and error
        let outPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errorPipe
        
        process.launch()
        
        // Wait for the process to finish
        process.waitUntilExit()
        
        // Read the process output
        let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
        _ = String(data: outputData, encoding: .utf8)
        
        // Read the process error output
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8)
        
        // Check if the process completed successfully
        if process.terminationStatus == 0 {
            // Display success alert
            let icnsFilePath = outputDirectoryURL.appendingPathComponent("\(icon.name).icns").path
            self.alertMessage = "ICNS file has been successfully created at \(icnsFilePath)!"
            self.alertTitle = "Success"
        } else {
            // Display error alert
            self.alertMessage = "Failed to create ICNS file. Error: \(errorOutput ?? "Unknown error")"
            self.alertTitle = "Error"
        }
        
        self.showAlert = true
        outputDirectoryURL.stopAccessingSecurityScopedResource()
    }
    
    func clearImage() {
        self.icon.image = nil
        self.icon.outputDirectory = ""
    }
}
