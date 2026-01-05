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
    @Binding var icons: [Icon]

    @Binding var showInspector: Bool
    @Binding var showAddIconSheet: Bool
    @Binding var showDeleteConfirmation: Bool
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Success"
    @State private var iconsGenerated = false
    @State private var showClearImageConfirmation = false
    @State private var isDropTargeted = false
    
    var body: some View {
        VStack {
            Spacer()
            // Main icon display or drop target
            ZStack {
                if let imgData = icon.image, let img = NSImage(data: imgData) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .overlay(
                            ZStack {
                                Rectangle()
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            }
                        )
                } else {

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(isDropTargeted ? 0.2 : 0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 36))
                                .foregroundStyle(.tint)
                                .scaleEffect(isDropTargeted ? 1.1 : 1.0)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDropTargeted)
                        
                        VStack(spacing: 6) {
                            Text(isDropTargeted ? "Drop Image Here" : "Drop Master Image")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("Drag your 1024x1024 artwork here\nor click to browse files")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 250)
                        }
                    }
                    .frame(maxWidth: 360, maxHeight: 360)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.accentColor.opacity(isDropTargeted ? 0.1 : 0.02))
                            
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(style: StrokeStyle(lineWidth: isDropTargeted ? 3 : 2, dash: isDropTargeted ? [] : [10, 6]))
                                .foregroundStyle(isDropTargeted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary.opacity(0.5)))
                        }
                    )
                    .animation(.easeInOut(duration: 0.2), value: isDropTargeted)

                    .contentShape(Rectangle())
                    .onDrop(of: [UTType.image], isTargeted: $isDropTargeted) { providers -> Bool in
                        providers.first?.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier,
                                                               completionHandler: { (data, error) in
                            if let data = data {
                                DispatchQueue.main.async {
                                    self.icon.image = data
                                    self.icon.outputDirectory = nil // Reset output directory on new image
                                    self.iconsGenerated = false
                                }
                            }
                        })
                        return true
                    }
                    .onTapGesture {
                        selectImage()
                    }
                }
            }
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: icon.name) {
            iconsGenerated = false
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !iconsGenerated {
                    Button(action: generateIcons) {
                        Label("Generate Icons", systemImage: "sparkles.rectangle.stack")
                    }
                    .help("Generate the icon set from your master image")
                    .disabled(self.icon.image == nil || icon.outputDirectory == nil)
                } else {
                    Button(action: generateICNS) {
                        Label("Save ICNS", systemImage: "arrow.down.doc.fill")
                    }
                    .help("Convert the icon set to a .icns file")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInspector.toggle()
                } label: {
                    Label("Inspector", systemImage: "slider.horizontal.3")
                }
                .help("Show or hide the inspector panel")
            }
            
            if icon.image != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showClearImageConfirmation = true
                    }) {
                        Label("Clear Image", systemImage: "trash")
                    }
                    .help("Remove the current image")
                }
            }
        }
        .alert("Clear Image", isPresented: $showClearImageConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClearImage()
            }
        } message: {
            Text("Are you sure you want to clear this image and output directory? This action cannot be undone.")
        }
    }
    
    // MARK: - Functions
    
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
    
    func generateIcons() {
        guard let imageData = icon.image,
              let image = NSImage(data: imageData),
              let outputDirectoryString = self.icon.outputDirectory,
              let outputDirectoryURL = URL(string: outputDirectoryString)
        else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
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
            self.alertMessage = "Error creating .iconset folder: \(error)"
            self.alertTitle = "Error"
            self.showAlert = true
            return
        }
        
        // Generate PNG files
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
        
        self.alertMessage = "Icons have been successfully created at \(iconsetFolder.path)!"
        self.alertTitle = "Success"
        self.iconsGenerated = true
        self.showAlert = true
    }
    
    func generateICNS() {
        guard let outputDirectoryString = self.icon.outputDirectory,
              let outputDirectoryURL = URL(string: outputDirectoryString)
        else { return }
        
        let accessGranted = outputDirectoryURL.startAccessingSecurityScopedResource()
        
        if !accessGranted {
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
        
        let outPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
        } catch {
            self.alertMessage = "Failed to run iconutil process."
            self.alertTitle = "Error"
            self.showAlert = true
            outputDirectoryURL.stopAccessingSecurityScopedResource()
            return
        }
        
        process.waitUntilExit()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8)
        
        if process.terminationStatus == 0 {
            let icnsFilePath = outputDirectoryURL.appendingPathComponent("\(icon.name).icns").path
            self.alertMessage = "ICNS file has been successfully created at \(icnsFilePath)!"
            self.alertTitle = "Success"
        } else {
            self.alertMessage = "Failed to create ICNS file. Error: \(errorOutput ?? "Unknown error")"
            self.alertTitle = "Error"
        }
        
        self.showAlert = true
        outputDirectoryURL.stopAccessingSecurityScopedResource()
    }
    
    func clearImage() {
        showClearImageConfirmation = true
    }
    
    func performClearImage() {
        self.icon.image = nil
        self.icon.outputDirectory = ""
        iconsGenerated = false
    }
}
