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
                .frame(minWidth: 380, maxWidth: .infinity, minHeight: 450, maxHeight: .infinity)
        }
        .defaultSize(width: 380, height: 450)
    }
}
