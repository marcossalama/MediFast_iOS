//
//  MediFastAppApp.swift
//  MediFastApp
//
//  Created by Marcos Salama on 8/31/25.
//

import SwiftUI

@main
struct MediFastAppApp: App {
    init() {
        Appearance.apply()
    }
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(Theme.primary)
        }
    }
}
