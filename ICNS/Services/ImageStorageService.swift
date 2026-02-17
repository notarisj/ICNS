//
//  ImageStorageService.swift
//  ICNS
//
//  Created by Ioannis Notaris on 29/1/26.
//

import Foundation
import AppKit
import OSLog

class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    private let imagesDirectory: URL
    
    private init() {
        // Get the Application Support directory
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
             Logger.storage.fault("Fatal: Could not find Application Support directory")
             fatalError("Could not find Application Support directory")
        }
        let appDirectory = appSupportURL.appendingPathComponent(Bundle.main.bundleIdentifier ?? "com.ICNS")
        imagesDirectory = appDirectory.appendingPathComponent("Images")
        
        createDirectoryIfNeeded()
    }
    
    func clearImagesDirectory() {
        do {
            if fileManager.fileExists(atPath: imagesDirectory.path) {
                try fileManager.removeItem(at: imagesDirectory)
            }
            createDirectoryIfNeeded()
        } catch {
            Logger.storage.error("Error clearing images directory: \(error, privacy: .public)")
        }
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                Logger.storage.error("Error creating images directory: \(error, privacy: .public)")
            }
        }
    }
    
    func saveImage(data: Data) -> String? {
        let id = UUID().uuidString
        let fileURL = imagesDirectory.appendingPathComponent(id)
        
        do {
            try data.write(to: fileURL)
            return id
        } catch {
            Logger.storage.error("Error saving image: \(error, privacy: .public)")
            return nil
        }
    }
    
    func loadImage(id: String) -> Data? {
        let fileURL = imagesDirectory.appendingPathComponent(id)
        
        // Check if file exists to avoid noisy errors during deletion/race conditions
        if !fileManager.fileExists(atPath: fileURL.path) {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            Logger.storage.error("Error loading image for id \(id, privacy: .public): \(error, privacy: .public)")
            return nil
        }
    }
    
    func deleteImage(id: String) {
        let fileURL = imagesDirectory.appendingPathComponent(id)
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            Logger.storage.error("Error deleting image for id \(id, privacy: .public): \(error, privacy: .public)")
        }
    }
    
    func getImageURL(id: String) -> URL {
        return imagesDirectory.appendingPathComponent(id)
    }
}
