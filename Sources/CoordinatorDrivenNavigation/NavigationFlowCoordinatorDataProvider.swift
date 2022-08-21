//
//  NavigationFlowCoordinatorDataProvider.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 19/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

public protocol NavigationFlowCoordinatorDataProvider {
    var initialFlowStep: FlowStep { get }

    func newViewControllerOrCoordinatorForFlowStep(_ step: FlowStep, param: Any?) -> UIViewControllerOrFlowCoordinator?
}

public extension NavigationFlowCoordinatorDataProvider where Self: FlowCoordinator {
    var initialFlowStep: FlowStep {
        return initialStep.rawValue
    }

    func newViewControllerOrCoordinatorForFlowStep(_ flowStep: FlowStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        guard let step = Step(rawValue: flowStep) else { return nil }

        return newViewControllerOrCoordinatorForStep(step, param: param)
    }
}
