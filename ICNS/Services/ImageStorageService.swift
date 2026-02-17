//
//  ImageStorageService.swift
//  ICNS
//
//  Created by Ioannis Notaris on 29/1/26.
//

import Foundation
import AppKit

class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let fileManager = FileManager.default
    private let imagesDirectory: URL
    
    private init() {
        // Get the Application Support directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
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
            print("Error clearing images directory: \(error)")
        }
    }
    
    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating images directory: \(error)")
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
            print("Error saving image: \(error)")
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
            print("Error loading image for id \(id): \(error)")
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
            print("Error deleting image for id \(id): \(error)")
        }
    }
    
    func getImageURL(id: String) -> URL {
        return imagesDirectory.appendingPathComponent(id)
    }
}
