//
//  ICNSApp.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI

@main
struct ICNSApp: App {
    @StateObject private var store = IconStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 900, height: 600)
    }
}
