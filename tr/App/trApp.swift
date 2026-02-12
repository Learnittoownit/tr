//
//  trApp.swift
//  tr
//
//  Created by Rama AlQahtani on 16/08/1447 AH.
//

import SwiftUI
import SwiftData

@main
struct trApp: App {
    let container: ModelContainer
    
        init() {
            container = DatabaseConfig.createContainer()
        }
    var body: some Scene {
        WindowGroup {
            MainPage().modelContainer(container)
                
        }
    }
}
