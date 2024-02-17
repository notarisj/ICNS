//
//  ICNSApp.swift
//  ICNS
//
//  Created by John Notaris on 17/2/24.
//

import SwiftUI

@main
struct ICNSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 350, maxWidth: .infinity, minHeight: 350, maxHeight: .infinity)
        }
        .defaultSize(width: 350, height: 350)
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
