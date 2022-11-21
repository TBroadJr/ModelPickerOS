//
//  Model.swift
//  ModelPickerOS
//
//  Created by Tornelius Broadwater, Jr on 11/21/22.
//

import SwiftUI
import RealityKit
import Combine

class Model: Identifiable {
    var modelName: String
    var image: Image
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        self.image = Image(modelName)
        
        let filename = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletion in
               print("DEBUG: Unable to load modelEntity for modelName: \(modelName)")
            }, receiveValue: { modelEntity in
                self.modelEntity = modelEntity
                print("DEBUG: Successfully added modelEntity for modelName: \(modelName)")
            })
    }
}
