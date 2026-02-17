//
//  ImageGenerationService.swift
//  ICNS
//
//  Created by Ioannis Notaris on 29/1/26.
//

import Foundation
import AppKit

class ImageGenerationService {
    static let shared = ImageGenerationService()
    
    private init() {}
    
    func generateIcons(from image: NSImage, outputDirectory: URL, profile: ExportProfile, iconName: String) async -> Result<URL, Error> {
        return await Task.detached {
            let sizes = profile.sizes
            let iconsetFolder = outputDirectory.appendingPathComponent("\(iconName).iconset")
            
            do {
                try FileManager.default.createDirectory(at: iconsetFolder, withIntermediateDirectories: true, attributes: nil)
                
                for size in sizes {
                    for scale in [1, 2] {
                        let scaledSize = NSSize(width: size*scale, height: size*scale)
                        let newImage = image.resizeImage(to: scaledSize)
                        let scaleSuffix = scale == 2 ? "@2x" : ""
                        let filename = "icon_\(size)x\(size)\(scaleSuffix).png"
                        let fileURL = iconsetFolder.appendingPathComponent(filename)
                        newImage.saveImage(as: NSBitmapImageRep.FileType.png, to: fileURL)
                    }
                }
                return .success(iconsetFolder)
            } catch {
                return .failure(error)
            }
        }.value
    }
    
    func generateICNS(from iconName: String, inside outputDirectory: URL) async -> Result<URL, Error> {
        return await Task.detached {
            let iconsetFolder = outputDirectory.appendingPathComponent("\(iconName).iconset")
            let icnsFilePath = outputDirectory.appendingPathComponent("\(iconName).icns")
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
            process.arguments = ["-c", "icns", iconsetFolder.path, "-o", icnsFilePath.path]
            
            let outPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errorPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    return .success(icnsFilePath)
                } else {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    return .failure(NSError(domain: "com.ICNS.iconutil", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorOutput]))
                }
            } catch {
                return .failure(error)
            }
        }.value
    }
}
