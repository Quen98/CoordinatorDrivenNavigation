//
//  Coordinator.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 18/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

public typealias FlowStep = Int
public typealias FlowCompletionState = Int

public protocol FlowStepAdapter: Equatable {
    var rawValue: FlowStep { get }

    init?(rawValue: FlowStep)
}

public typealias ManagedViewControllerProvider = NSObject & ViewControllerProvider & FlowStepIdentifiable & DebugAssociatedViewController

public protocol UIViewControllerOrFlowCoordinator {
    mutating func managedViewControllerProvider() -> ManagedViewControllerProvider
}

public protocol FlowStepIdentifiable {
    var flowStep: FlowStep? { get set }
}

public protocol ViewControllerProvider {
    func viewController() -> UIViewController?
}

/**
 Used for debug purposes when dumping the coordination hierarchy
 */
public protocol DebugAssociatedViewController {
    var associatedViewController: UIViewController? { get }
}

public protocol FlowCoordinator: NavigationFlowCoordinatorDataProvider, UIViewControllerOrFlowCoordinator {
    associatedtype Step: FlowStepAdapter
    associatedtype CompletionState: Equatable

    var initialStep: Step { get }
    var flowCoordinator: NavigationFlowCoordinator? { get set }
    var completion: ((_ state: CompletionState, _ param: Any?) -> Void)? { get }

    func newViewControllerOrCoordinatorForStep(_ step: Step, param: Any?) -> UIViewControllerOrFlowCoordinator?
    func dumpHierarchy()
}

public extension FlowCoordinator {
    mutating func managedViewControllerProvider() -> ManagedViewControllerProvider {
        let coordinator = NavigationFlowCoordinator(
            dataProvider: self
        )
        flowCoordinator = coordinator
        return coordinator
    }

    var currentStep: Step? {
        return flowCoordinator?.currentStep.map { Step(rawValue: $0)! }
    }

    var steps: [Step] {
        flowCoordinator?.steps.compactMap {
            Step(rawValue: $0)
        } ?? []
    }

    func dumpHierarchy() {
        flowCoordinator?.dumpHierarchy()
    }

    func push(step: Step, param: Any? = nil, animated: Bool = true) {
        flowCoordinator?.push(
            step: step.rawValue,
            param: param,
            animated: animated
        )
    }

    func present(step: Step, param: Any? = nil, animated: Bool = true) {
        flowCoordinator?.present(
            step: step.rawValue,
            param: param,
            animated: animated
        )
    }

    func replaceCurrentStep(with step: Step, param: Any? = nil, animated: Bool = true) {
        flowCoordinator?.replaceCurrentStep(
            with: step.rawValue,
            param: param,
            animated: animated
        )
    }

    func returnTo(_ step: Step, animated: Bool = true) {
        flowCoordinator?.returnTo(
            step: step.rawValue,
            animated: animated
        )
    }

    func restartFlow(with step: Step, param: Any? = nil, animated: Bool = true) {
        flowCoordinator?.restartFlow(
            with: step.rawValue,
            param: param,
            animated: animated
        )
    }
}
