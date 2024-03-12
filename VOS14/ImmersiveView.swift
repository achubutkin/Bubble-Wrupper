//
//  ImmersiveView.swift
//  VOS14
//
//  Created by Alexandr Chubutkin on 12/03/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

var root: Entity = Entity()
var audioPlayers = [AVAudioPlayer]()
var effect: Entity? = nil


struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            content.add(root)
            root.position = [0.0, 1.5, -1.5]
            
            generateCloud()
            
            // Load multiple audio files
            let soundFileNames = ["audio-editor-output-1", "audio-editor-output-2"] // Replace with your sound file names
            for fileName in soundFileNames {
                if let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") {
                    do {
                        let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                        audioPlayer.prepareToPlay()
                        audioPlayers.append(audioPlayer)
                    } catch {
                        print("Error loading sound file \(fileName): \(error.localizedDescription)")
                    }
                } else {
                    print("Sound file \(fileName) not found")
                }
            }

            /*
             if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
             content.add(immersiveContentEntity)
             
             // Add an ImageBasedLight for the immersive content
             guard let resource = try? await EnvironmentResource(named: "ImageBasedLight") else { return }
             let iblComponent = ImageBasedLightComponent(source: .single(resource), intensityExponent: 0.25)
             immersiveContentEntity.components.set(iblComponent)
             immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: immersiveContentEntity))
             
             // Put skybox here.  See example in World project available at
             // https://developer.apple.com/
             }
             */
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTap(value)
                }
        )
    }
    
    func handleTap(_ value: EntityTargetValue<SpatialTapGesture.Value>) {
        // Play a random sound effect
        if !audioPlayers.isEmpty {
            let randomIndex = Int.random(in: 0..<audioPlayers.count)
            audioPlayers[randomIndex].play()
        }
        
        let tappedEntity = value.entity
        tappedEntity.removeFromParent()
        
        // Find and remove nearby entities
        removeNearbyEntities(from: tappedEntity.position)
    }
    
    func generateCloud() {
        let cloudRadius: Float = 1.0
        let minSpheres = 50
        let maxSpheres = 100
        let sphereRadius: Float = 0.03
        var existingPositions = [SIMD3<Float>]()
        
        let numSpheres = Int.random(in: minSpheres...maxSpheres)
        
        for _ in 0..<numSpheres {
            var newPosition: SIMD3<Float>
            var isPositionValid: Bool
            
            repeat {
                let theta = Float.random(in: 0...(2 * .pi))
                let phi = Float.random(in: 0...(2 * .pi))
                let radius = Float.random(in: 0...(cloudRadius - sphereRadius))
                
                let x = radius * sin(phi) * cos(theta)
                let y = radius * sin(phi) * sin(theta)
                let z = radius * cos(phi)
                
                newPosition = SIMD3<Float>(x, y, z)
                
                isPositionValid = true
                
                for existingPosition in existingPositions {
                    let distance = distanceBetweenPoints(newPosition, existingPosition)
                    
                    if distance < 2 * sphereRadius { // Assuming sphere diameter as reference
                        isPositionValid = false
                        break
                    }
                }
            } while !isPositionValid
            
            existingPositions.append(newPosition)
            
            let sphere = MeshResource.generateSphere(radius: sphereRadius)
            let material = SimpleMaterial(color: .init(red: 1.0, green: 0.86, blue: 0.0, alpha: 1), isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
            sphereEntity.position = newPosition
            
            sphereEntity.collision = CollisionComponent(shapes: [.generateSphere(radius: sphereRadius)], collisionOptions: .fullContactInformation)
            sphereEntity.components.set(InputTargetComponent())
            sphereEntity.components.set(HoverEffectComponent())
            
            sphereEntity.name = "Sphere"
            
            root.addChild(sphereEntity)
        }
    }
    
    func removeNearbyEntities(from position: SIMD3<Float>) {
        let thresholdDistance: Float = 0.2 // Adjust as needed
        var index: Double = 0
        
        for entity in root.children {
            guard entity.name == "Sphere" else { continue }
            
            let distance = simd_distance(entity.position, position)
            if distance < thresholdDistance {
                // Remove the nearby entity from the scene with a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * index) { // Adjust the delay as needed
                    // Play a sound effect
                    if !audioPlayers.isEmpty {
                        let randomIndex = Int.random(in: 0..<audioPlayers.count)
                        audioPlayers[randomIndex].play()
                    }
                    
                    // Remove the nearby entity from the scene
                    entity.removeFromParent()
                }
                
                index += 1
            }
        }
    }
    
    func distanceBetweenPoints(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let deltaX = a.x - b.x
        let deltaY = a.y - b.y
        let deltaZ = a.z - b.z
        return sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
    }
    
    func randomYellowishColor() -> UIColor {
        let hue = CGFloat.random(in: 0.1...0.2) // More towards yellow
        let saturation = CGFloat.random(in: 0.5...1.0)
        let brightness = CGFloat.random(in: 0.5...1.0)
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
    }
    
    func introToRealityKit(_ content: RealityViewContent) {
        let anchorEntity = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [4.0, 4.0]))
        
        let mesh = MeshResource.generatePlane(width: 4, depth: 4)
        var material = SimpleMaterial(color: .white.withAlphaComponent(0.3), isMetallic: false)
        material.roughness = 1
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        anchorEntity.addChild(modelEntity)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            content.add(anchorEntity)
            modelEntity.components[MyComponent.self] = MyComponent(mass: 2.0)
        }
    }
    
    func interactivityInRealityKit(_ content: RealityViewContent) {
        
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}

struct MyComponent: Component {
    var mass: Float
    
    init(mass: Float) {
        self.mass = mass
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}

