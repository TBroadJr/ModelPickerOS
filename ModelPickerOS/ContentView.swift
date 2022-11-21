//
//  ContentView.swift
//  ModelPickerOS
//
//  Created by Tornelius Broadwater, Jr on 11/19/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private var models: [Model] = {
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath,
              let files = try? filemanager.contentsOfDirectory(atPath: path) else { return [] }
        
        var availableModels: [Model] = []
        
        for filename in files where filename.hasSuffix("usdz") {
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            availableModels.append(model)
        }
        return availableModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            if isPlacementEnabled {
                PlacementButtonsView(
                    isPlacementEnabled: $isPlacementEnabled,
                    selectedModel: $selectedModel,
                    modelConfirmedForPlacement: $modelConfirmedForPlacement
                )
            } else {
                ModelPickerView(
                    isPlacementEnabled: $isPlacementEnabled,
                    selectedModel: $selectedModel,
                    models: models
                )
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        let arView = CustomARView(frame: .zero)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = modelConfirmedForPlacement {
            if let modelEntity = model.modelEntity {
                print("DEBUG: adding model to scene - \(model.modelName)")
                
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                uiView.scene.addAnchor(anchorEntity)
            } else {
                print("DEBUG: Unable to load modelEntity for: \(model.modelName)")
            }
            
            // Modifying value while the UI is still processing it.
            DispatchQueue.main.async {
                modelConfirmedForPlacement = nil
            }
        }
    }
}

class CustomARView: ARView, FocusEntityDelegate {
    
    enum FocusStyleChoices {
            case classic
            case material
            case color
        }

        /// Style to be displayed in the example
        let focusStyle: FocusStyleChoices = .classic
        var focusEntity: FocusEntity?
        required init(frame frameRect: CGRect) {
            super.init(frame: frameRect)
            self.setupARView()

            switch self.focusStyle {
            case .color:
                self.focusEntity = FocusEntity(on: self, focus: .plane)
            case .material:
                do {
                    let onColor: MaterialColorParameter = try .texture(.load(named: "Add"))
                    let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
                    self.focusEntity = FocusEntity(
                        on: self,
                        style: .colored(
                            onColor: onColor, offColor: offColor,
                            nonTrackingColor: offColor
                        )
                    )
                } catch {
                    self.focusEntity = FocusEntity(on: self, focus: .classic)
                    print("Unable to load plane textures")
                    print(error.localizedDescription)
                }
            default:
                self.focusEntity = FocusEntity(on: self, focus: .classic)
            }
        }
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupARView() {
        let config = ARWorldTrackingConfiguration()
        
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
            // improves experience, check for this because if the app does not have support for this it will crash
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        session.run(config)
    }
}

extension CustomARView {
    func toInitializingState() {
        print("initializing")
    }
}

struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack( spacing: 30) {
                ForEach(models) { item in
                    Button {
                        isPlacementEnabled = true
                        selectedModel = item
                        print("DEBUG: selected model with name \(item.modelName)")
                    } label: {
                        VStack {
                            item.image
                                 .resizable()
                                 .scaledToFit()
                                 .frame(height: 75)
                                 .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        HStack {
            // cancel button
            Button {
                resetPlacementPerameters()
                print("DEBUG: Model placement cancel")
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(20)
            }
            
            // confirm button
            Button {
                modelConfirmedForPlacement = selectedModel
                resetPlacementPerameters()
                print("DEBUG: Model placement confirm")
            } label: {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(20)
            }
        }
    }
    
    private func resetPlacementPerameters() {
        isPlacementEnabled = false
        selectedModel = nil
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
