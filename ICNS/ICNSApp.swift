//
//  ICNSApp.swift
//  ICNS
//
//  Created by Ioannis Notaris on 17/2/24.
//

import SwiftUI

@main
struct ICNSApp: App {
    @StateObject private var store = IconStore()
    @StateObject private var profileStore = ProfileStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(profileStore)
        }
        .defaultSize(width: 900, height: 600)
    }
}
