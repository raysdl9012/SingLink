//
//  HandPoseClassifierInput.swift
//  SingLink
//
//  Created by Reinner Steven Daza Leiva on 17/11/25.
//

import CoreML

/// Input para el clasificador de hand poses
/// Este archivo se generará automáticamente cuando agregues el .mlmodel
class HandPoseClassifierInput: MLFeatureProvider {
    var poses: MLMultiArray
    
    var featureNames: Set<String> {
        return ["poses"]
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "poses" {
            return MLFeatureValue(multiArray: poses)
        }
        return nil
    }
    
    init(poses: MLMultiArray) {
        self.poses = poses
    }
}
