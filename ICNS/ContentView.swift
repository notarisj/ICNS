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

    var body: some View {
        VStack(spacing: 20) {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 300, maxHeight: 300)
            } else {
                Text("No Image Selected")
                    .foregroundColor(.gray)
            }
            Spacer()
            TextField("Icon Name", text: $iconName)
                .padding(.horizontal)
            Text("Output Directory: \(formatDirectory(url: outputDirectory))")
                .foregroundColor(.gray)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack {
                HStack {
                    Button("Select Image") {
                        selectImage()
                    }
                    Button("Select Output Directory") {
                        selectOutputDirectory()
                    }
                }
                HStack {
                    Button(action: generateIcons, label: {
                        Text("Generate Icons")
                    })
                    Button(action: generateICNS, label: {
                        Text("Generate ICNS")
                    })
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
}
