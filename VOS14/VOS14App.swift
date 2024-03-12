//
//  VOS14App.swift
//  VOS14
//
//  Created by Alexandr Chubutkin on 12/03/24.
//

import SwiftUI

@main
struct VOS14App: App {
    init() {
        registerComponents()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
    
    private func registerComponents() {
        MyComponent.registerComponent()
    }
}
