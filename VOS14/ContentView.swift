//
//  ContentView.swift
//  VOS14
//
//  Created by Alexandr Chubutkin on 12/03/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Image("splashScreen")
                .resizable()
                .aspectRatio(contentMode: .fill)
            VStack(spacing: 10) {
                Spacer()
                Text("Bubble-Wrupper")
                    .font(.system(size: 30, weight: .bold))
                Text("Cheer up grumpy clouds by shining a happy beam with your heart.")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .frame(width: 340)
                    .padding(.bottom, 10)
                Button {
                    showImmersiveSpace.toggle()
                } label: {
                    Text("Play")
                        .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding(.horizontal, 150)
            .frame(width: 634, height: 499)
            .onChange(of: showImmersiveSpace) { _, newValue in
                Task {
                    if newValue {
                        switch await openImmersiveSpace(id: "ImmersiveSpace") {
                        case .opened:
                            immersiveSpaceIsShown = true
                            dismiss()
                        case .error, .userCancelled:
                            fallthrough
                        @unknown default:
                            immersiveSpaceIsShown = false
                            showImmersiveSpace = false
                        }
                    } else if immersiveSpaceIsShown {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsShown = false
                    }
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
