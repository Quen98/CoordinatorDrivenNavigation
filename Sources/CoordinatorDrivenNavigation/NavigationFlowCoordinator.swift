//
//  NavigationFlowCoordinator.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 19/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

typealias StepIdentifiableControllerProvider = (flowStep: FlowStep, managedController: ManagedViewControllerProvider)

public class NavigationFlowCoordinator: ManagedViewControllerProvider {
    public var associatedViewController: UIViewController?

    private var router: NavigationControllerRouter?
    private let dataProvider: NavigationFlowCoordinatorDataProvider
    private var managedControllers: [StepIdentifiableControllerProvider] = []
    private var completion: ((_ coordinator: NavigationFlowCoordinator) -> Swift.Void)?
    private let isTopMainNavigationCoordinator: Bool

    // Used for Units tests
    public func flowStep(associatedTo viewController: ManagedViewControllerProvider) -> FlowStep? {
        managedControllers.first { $0.managedController === viewController }?.flowStep
    }

    public var currentStep: FlowStep? {
        steps.last
    }

    public var steps: [FlowStep] {
        managedControllers.compactMap { $0.flowStep }
    }

    init(dataProvider: NavigationFlowCoordinatorDataProvider,
         router: NavigationControllerRouter?,
         isTopMainNavigationCoordinator: Bool) {
        self.dataProvider = dataProvider
        self.router = router
        self.isTopMainNavigationCoordinator = isTopMainNavigationCoordinator
    }

    convenience init(dataProvider: NavigationFlowCoordinatorDataProvider) {
        self.init(
            dataProvider: dataProvider,
            router: nil,
            isTopMainNavigationCoordinator: false
        )
    }

    convenience init(dataProvider: NavigationFlowCoordinatorDataProvider,
                     navigationController: CoordinatorDrivenNavigationViewController) {
        self.init(
            dataProvider: dataProvider,
            router: NavigationRouter(
                navigationController: navigationController
            ),
            isTopMainNavigationCoordinator: true
        )
    }

    // MARK: Push
    public func push(step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        let viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        if let initialViewController = viewControllerProvider.viewController() {
            router?.push(viewController: initialViewController, animated: animated)
        }
        managedControllers.append((step, viewControllerProvider))
    }

    // MARK: Present
    public func present(step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        let viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
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
        managedControllers.append((step, viewControllerProvider))
    }

    // MARK: Replace
    public func replaceCurrentStep(with step: FlowStep, param: Any?, animated: Bool = true) {
        guard
            var viewControllerOrCoordinator = dataProvider.newViewControllerOrCoordinatorForFlowStep(step, param: param)
        else { return }

        let viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        if let viewController = viewControllerProvider.viewController() {
            router?.popLast(
                andShow: viewController,
                animated: animated
            )
            managedControllers.removeLast()
            managedControllers.append((step, viewControllerProvider))
            updateAssociatedViewControllerIfNeeded()
        }
    }

    private func updateAssociatedViewControllerIfNeeded() {
        guard managedControllers.count == 1 else { return }

        if let viewController = managedControllers.first?.managedController as? UIViewController {
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
        guard let managedViewControllerProvider = lastManagedController(for: step),
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

        let viewControllerProvider = viewControllerOrCoordinator.managedViewControllerProvider()
        if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }

        if let newInitialViewController = viewControllerProvider.viewController() {
            if isTopMainNavigationCoordinator == false,
               let initialViewController = viewController() {
                router?.pop(
                    toViewControllerBefore: initialViewController,
                    andShow: newInitialViewController,
                    animated: animated
                )
            } else {
                router?.setViewControllers([newInitialViewController], animated: animated)
            }
            managedControllers = [(step, viewControllerProvider)]
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
    private func lastManagedController(for flowStep: FlowStep,
                                       includeLastElement: Bool = false) -> ManagedViewControllerProvider? {
        var index = managedControllers.count - 1 // Ensuring the behavior stays the same when popping to a step with identical flowStep

        if includeLastElement == false {
            index -= 1
        }

        while index >= 0 {
            if managedControllers[index].flowStep == flowStep {
                return managedControllers[index].managedController
            }
            index -= 1
        }
        return nil
    }

    private func firstIndex(of controller: ManagedViewControllerProvider) -> Int? {
        managedControllers.firstIndex { $0.managedController === controller }
    }

    func remove(managedController: ManagedViewControllerProvider) {
        guard
            let index = managedControllers.lastIndex(where: { $0.managedController === managedController })
        else { return }

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
        if managedControllers.contains(where: { $0.managedController === viewController }) {
            return self
        }
        for controllerOrCoordinator in managedControllers {
            if let controllerOrCoordinator = controllerOrCoordinator.managedController as? NavigationFlowCoordinator,
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

        guard
            let viewControllerProvider = viewControllerOrCoordinator?.managedViewControllerProvider()
        else { return }

        if let viewController = viewControllerProvider as? UIViewController {
            associatedViewController = viewController
        } else if let coordinator = viewControllerProvider as? NavigationFlowCoordinator {
            initializeNewlyCreated(coordinator: coordinator)
        }
        managedControllers.append((dataProvider.initialFlowStep, viewControllerProvider))
    }

    public func viewController() -> UIViewController? {
        guard let firstManagedController = managedControllers.first else { return nil }

        if let coordinator = firstManagedController.managedController as? NavigationFlowCoordinator {
            return coordinator.viewController()
        }
        return firstManagedController.managedController as? UIViewController
    }

    // MARK: Debug
    public func dumpHierarchy() {
        print("------------------------------")
        print("Printing view hierarchy")
        print(String(describing: self))
        print("    | DataProvider \(String(describing: dataProvider))")
        print("    | AssociatedVC \(String(describing: associatedViewController))")
        dumpHierarchy(with: "")
        print("------------------------------")
    }

    func dumpHierarchy(with prefix: String) {
        managedControllers.forEach {
            if let child = $0.managedController as? UIViewController, child.isModal {
                print(prefix + "    ↑ \(String(describing: $0))")
            } else {
                print(prefix + "    → \(String(describing: $0))")
            }
            if let coordinator = $0.managedController as? NavigationFlowCoordinator {
                print(prefix + "        | DataProvider \(String(describing: coordinator.dataProvider))")
            }
            print(prefix + "        | AssociatedVC \(String(describing: $0.managedController.associatedViewController))")
            print(prefix + "        | FlowStep \(String(describing: $0.flowStep))")
            if let child = $0.managedController as? NavigationFlowCoordinator {
                child.dumpHierarchy(with: prefix + "    ")
            } else if let child = $0.managedController as? CoordinatorDrivenNavigationViewController {
                child.dumpHierarchy(with: prefix + "    ")
            }
        }
    }
}
