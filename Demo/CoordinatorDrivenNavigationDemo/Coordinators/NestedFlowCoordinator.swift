//
//  NestedFlowCoordinator.swift
//  CoordinatorDrivenNavigationDemo
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//

import UIKit
import CoordinatorDrivenNavigation

enum NestedFlowCoordinatorStep: FlowStep, FlowStepAdapter {
    case main
}

enum NestedFlowCoordinatorCompletionState: FlowCompletionState {
    case userAction
}

class NestedFlowCoordinator: FlowCoordinator {
    var initialStep: NestedFlowCoordinatorStep = .main
    weak var flowCoordinator: NavigationFlowCoordinator?
    var completion: ((NestedFlowCoordinatorCompletionState, Any?) -> Void)?

    func newViewControllerOrCoordinatorForStep(_ step: NestedFlowCoordinatorStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        switch step {
        case .main:
            return createMainViewController()
        }
    }

    func createMainViewController() -> NestedViewController {
        let viewController = NestedViewController()

        viewController.onCompleteNestedFlow = { [weak self] in
            self?.completion?(.userAction, nil)
        }
        return viewController
    }
}
