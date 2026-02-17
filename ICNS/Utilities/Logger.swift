//
//  Logger.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//

import OSLog
import Foundation

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.notaris.ICNS"

    /// Logs related to image storage and file system operations
    static let storage = Logger(subsystem: subsystem, category: "storage")

    /// Logs related to UI events and ViewModels
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Logs related to data persistence and stores
    static let data = Logger(subsystem: subsystem, category: "data")

    /// Logs related to migration processes
    static let migration = Logger(subsystem: subsystem, category: "migration")
}
