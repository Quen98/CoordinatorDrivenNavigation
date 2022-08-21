//
//  NavigationFlowCoordinator.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 19/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

public class NavigationFlowCoordinator: ManagedViewControllerProvider {
    public var flowStep: FlowStep?
    public var associatedViewController: UIViewController?

    private var router: NavigationControllerRouter?
    private let dataProvider: NavigationFlowCoordinatorDataProvider
    private var managedControllers: [ManagedViewControllerProvider] = []
    private var completion: ((_ coordinator: NavigationFlowCoordinator) -> Swift.Void)?

    public var currentStep: FlowStep? {
        steps.last
    }

    public var steps: [FlowStep] {
        managedControllers.compactMap { $0.flowStep }
    }

    init(dataProvider: NavigationFlowCoordinatorDataProvider,
         router: NavigationControllerRouter?) {
        self.dataProvider = dataProvider
        self.router = router
    }

    convenience init(dataProvider: NavigationFlowCoordinatorDataProvider) {
        self.init(
            dataProvider: dataProvider,
            router: nil
        )
    }

    convenience init(dataProvider: NavigationFlowCoordinatorDataProvider,
                     navigationController: CoordinatorDrivenNavigationViewController) {
        self.init(
            dataProvider: dataProvider,
            router: NavigationRouter(
                navigationController: navigationController
            )
        )
    }

    // MARK: Push
    public func push(step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        var viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        if let initialViewController = viewControllerProvider.viewController() {
            router?.push(viewController: initialViewController, animated: animated)
        }
        viewControllerProvider.flowStep = step
        managedControllers.append(viewControllerProvider)
    }

    // MARK: Present
    public func present(step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        var viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        if let initialViewController = viewControllerProvider.viewController() {
            router?.present(viewController: initialViewController, animated: animated)
        }
        if let navigationController = viewControllerProvider as? CoordinatorDrivenNavigationViewController,
           let coordinator = navigationController.flowCoordinator {

            // Setting a custom completion here because we need to remove the controller in the PREVIOUS coordinator
            coordinator.completion = { [weak self] _ in
                self?.remove(managedControllerContaining: navigationController)
            }
        }
        viewControllerProvider.flowStep = step
        managedControllers.append(viewControllerProvider)
    }

    // MARK: Replace
    public func replaceCurrentStep(with step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        var viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        if let viewController = viewControllerProvider.viewController() {
            router?.popLast(
                andShow: viewController,
                animated: animated
            )
            viewControllerProvider.flowStep = step
            managedControllers.removeLast()
            managedControllers.append(viewControllerProvider)
            updateAssociatedViewControllerIfNeeded()
        }
    }

    private func updateAssociatedViewControllerIfNeeded() {
        guard managedControllers.count == 1 else { return }

        if let viewController = managedControllers.first as? UIViewController {
            associatedViewController = viewController
        } else {
            associatedViewController = nil
        }
    }

    private func bindCoordinatorCompletion(_ coordinator: NavigationFlowCoordinator) {
        coordinator.completion = { [weak self] coordinator in
            self?.remove(managedController: coordinator)
        }
    }

    // MARK: Return
    public func returnTo(step: FlowStep, animated: Bool = true) {
        guard let managedViewControllerProvider = managedController(for: step),
              let viewController = managedViewControllerProvider.viewController() else { return }

        router?.pop(to: viewController, andShow: nil, animated: animated)
        if let index = firstIndex(of: managedViewControllerProvider) {
            managedControllers = Array(managedControllers[0..<index + 1])
        }
    }

    // MARK: Restart
    public func restartFlow(with step: FlowStep, param: Any? = nil, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        var viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }

        if let newInitialViewController = viewControllerProvider.viewController() {
            if flowStep != nil, // In case we are the top main navigationflowcoordinator
               let initialViewController = viewController() {
                router?.pop(
                    toViewControllerBefore: initialViewController,
                    andShow: newInitialViewController,
                    animated: animated
                )
            } else {
                router?.setViewControllers([newInitialViewController], animated: animated)
            }
            viewControllerProvider.flowStep = step
            managedControllers = [viewControllerProvider]
            updateAssociatedViewControllerIfNeeded()
        }
    }

    // MARK: Dismiss
    public func dismiss(animated: Bool = true) {
        router?.dismiss(animated: animated)
    }

    func complete() {
        completion?(self)
    }

    // MARK: Handlers
    private func managedController(for flowStep: FlowStep) -> ManagedViewControllerProvider? {
        managedControllers.first { $0.flowStep == flowStep }
    }

    private func firstIndex(of controller: ManagedViewControllerProvider) -> Int? {
        managedControllers.firstIndex { $0.flowStep == controller.flowStep }
    }

    func remove(managedController: ManagedViewControllerProvider) {
        guard let index = managedControllers.lastIndex(where: { $0 === managedController }) else { return }

        managedControllers.remove(at: index)
        if managedControllers.isEmpty {
            completion?(self)
        }
    }

    func remove(managedControllerContaining viewController: UIViewController) {
        guard let containerCoordinator = navigationFlowCoordinator(containing: viewController) else { return }

        containerCoordinator.remove(managedController: viewController)
    }

    private func navigationFlowCoordinator(containing viewController: UIViewController) -> NavigationFlowCoordinator? {
        if managedControllers.contains(where: { $0 === viewController }) {
            return self
        }
        for controllerOrCoordinator in managedControllers {
            if let controllerOrCoordinator = controllerOrCoordinator as? NavigationFlowCoordinator,
               let coordinator = controllerOrCoordinator.navigationFlowCoordinator(containing: viewController) {
                return coordinator
            }
        }
        return nil
    }

    // MARK: NavigationFlowCoordinator init
    private func initializeNewlyCreated(coordinator: NavigationFlowCoordinator) {
        coordinator.router = router
        bindCoordinatorCompletion(coordinator)
        coordinator.initializeNestedCoordinatorsIfNeeded()
    }

    private func initializeNestedCoordinatorsIfNeeded() {
        var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(
            dataProvider.initialFlowStep,
            param: nil
        )

        guard var viewControllerProvider = viewControllerOrCoordinator?.managedViewControllerProvider() else { return }

        if let viewController = viewControllerProvider as? UIViewController {
            associatedViewController = viewController
        } else if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        viewControllerProvider.flowStep = dataProvider.initialFlowStep
        managedControllers.append(viewControllerProvider)
    }

    public func viewController() -> UIViewController? {
        guard let firstManagedController = managedControllers.first else { return nil }

        if let coordinator = firstManagedController as? NavigationFlowCoordinator {
            return coordinator.viewController()
        }
        return firstManagedController as? UIViewController
    }

    // MARK: Debug
    public func dumpHierarchy() {
        print("------------------------------")
        print("Printing view hierarchy")
        print(String(describing: self))
        print("    | DataProvider \(String(describing: dataProvider))")
        print("    | AssociatedVC \(String(describing: associatedViewController))")
        print("    | FlowStep \(String(describing: flowStep))")
        dumpHierarchy(with: "")
        print("------------------------------")
    }

    func dumpHierarchy(with prefix: String) {
        managedControllers.forEach {
            if let child = $0 as? UIViewController, child.isModal {
                print(prefix + "    ↑ \(String(describing: $0))")
            } else {
                print(prefix + "    → \(String(describing: $0))")
            }
            if let coordinator = $0 as? NavigationFlowCoordinator {
                print(prefix + "        | DataProvider \(String(describing: coordinator.dataProvider))")
            }
            print(prefix + "        | AssociatedVC \(String(describing: $0.associatedViewController))")
            print(prefix + "        | FlowStep \(String(describing: $0.flowStep))")
            if let child = $0 as? NavigationFlowCoordinator {
                child.dumpHierarchy(with: prefix + "    ")
            } else if let child = $0 as? CoordinatorDrivenNavigationViewController {
                child.dumpHierarchy(with: prefix + "    ")
            }
        }
    }
}
