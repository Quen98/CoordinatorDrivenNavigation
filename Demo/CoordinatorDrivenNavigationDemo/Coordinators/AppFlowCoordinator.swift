//
//  AppFlowCoordinator.swift
//  CoordinatorDrivenNavigationDemo
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//

import UIKit
import CoordinatorDrivenNavigation

enum AppFlowStep: FlowStep, FlowStepAdapter {
    case welcome
    case detail
    case presented
    case nestedCoordinator
}

enum AppFlowCompletionState: FlowCompletionState {
    case success
}

class AppFlowCoordinator: FlowCoordinator {
    var initialStep: AppFlowStep = .welcome
    weak var flowCoordinator: NavigationFlowCoordinator?
    var completion: ((AppFlowCompletionState, Any?) -> Void)?

    func newViewControllerOrCoordinatorForStep(_ step: AppFlowStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        switch step {
        case .welcome:
            return createWelcomeViewController()
        case .detail:
            return createDetailViewController()
        case .presented:
            return PresentedViewController()
        case .nestedCoordinator:
            return createNestedFlowCoordinator()
        }
    }

    private func createWelcomeViewController() -> UIViewController {
        let viewController = WelcomeViewController()

        viewController.onNextButtonTapped = { [weak self] in
            self?.push(step: .detail)
        }
        return viewController
    }

    private func createDetailViewController() -> UIViewController {
        let viewController = DetailViewController()

        viewController.onPresentButtonTapped = { [weak self] in
            self?.present(step: .presented)
        }
        viewController.onNestedCoordinatorButtonTapped = { [weak self] in
            self?.push(step: .nestedCoordinator)
        }
        return viewController
    }

    private func createNestedFlowCoordinator() -> NestedFlowCoordinator {
        let coordinator = NestedFlowCoordinator()

        coordinator.completion = { [weak self] success, _ in
            self?.returnTo(.detail)
        }
        return coordinator
    }
}
