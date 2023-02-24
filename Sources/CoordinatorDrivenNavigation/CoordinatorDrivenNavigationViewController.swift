//
//  CoordinatorDriverNavigationViewController.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

fileprivate extension FlowCoordinator {
    mutating func newFlowCoordinator(navigation: CoordinatorDrivenNavigationViewController) -> NavigationFlowCoordinator {
        let coordinator = NavigationFlowCoordinator(
            dataProvider: self,
            navigationController: navigation
        )
        flowCoordinator = coordinator
        return coordinator
    }

    mutating func start(in navigation: CoordinatorDrivenNavigationViewController) -> NavigationFlowCoordinator {
        let flowCoordinator = newFlowCoordinator(navigation: navigation)

        push(step: initialStep)
        return flowCoordinator
    }
}

open class CoordinatorDrivenNavigationViewController: UINavigationController {
    private(set) var flowCoordinator: NavigationFlowCoordinator?
    private var dismissingViewController: UIViewController?
    public let coordinator: any FlowCoordinator

    public override var delegate: UINavigationControllerDelegate? {
        get { customDelegate }
        set { customDelegate = newValue }
    }

    private weak var customDelegate: UINavigationControllerDelegate?

    public convenience init<T>(coordinator: T) where T: FlowCoordinator {
        self.init(coordinator: coordinator, navigationBarClass: nil, toolbarClass: nil)
    }

    public init<T>(coordinator: T, navigationBarClass: AnyClass?, toolbarClass: AnyClass?) where T: FlowCoordinator {
        self.coordinator = coordinator

        defer {
            super.delegate = self
            var coordinator = coordinator
            flowCoordinator = coordinator.start(in: self)
        }
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func dumpHierarchy(with prefix: String) {
        flowCoordinator?.dumpHierarchy(with: prefix)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissed {
            flowCoordinator?.complete()
        }
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissingViewController = presentedViewController

        super.dismiss(animated: flag, completion: { [weak self] in
            if let dismissingViewController = self?.dismissingViewController,
               self?.presentedViewController == nil { // Dismiss successfull
                self?.flowCoordinator?.remove(managedControllerContaining: dismissingViewController)
            }
            self?.dismissingViewController = nil
            completion?()
        })
    }
}

// MARK: - UINavigationControllerDelegate
extension CoordinatorDrivenNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        delegate?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
    }

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        delegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )

        guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
              navigationController.viewControllers.contains(fromVC) == false else { return }

        flowCoordinator?.remove(managedControllerContaining: fromVC)
    }

    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        delegate?.navigationControllerSupportedInterfaceOrientations?(navigationController) ?? UIApplication.shared.delegate?.application?(
            UIApplication.shared,
            supportedInterfaceOrientationsFor: nil
        ) ?? .all
    }

    public func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(navigationController) ?? .portrait
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        delegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        )
    }
}
