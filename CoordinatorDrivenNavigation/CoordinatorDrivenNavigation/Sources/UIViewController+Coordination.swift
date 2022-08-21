//
//  UIViewController+Coordination.swift
//  ForgottenTales
//
//  Created by Quentin Quennehen on 28/12/2020.
//  Copyright © 2020 Toasted-Bread. All rights reserved.
//

import UIKit

private struct Constants {
    static let flowStepKey = "flowStep"
}

fileprivate var AssociatedObjectFlowStepKey: UInt8 = 0

extension UIViewController {
    var isModal: Bool {
        let isSingleViewControllerPresented = presentingViewController != nil && navigationController == nil
        let isNavigationControllerPresenter = presentingViewController != nil && self.isKind(of: UINavigationController.self)

        return isSingleViewControllerPresented || isNavigationControllerPresenter
    }
}

extension UIViewController: DebugAssociatedViewController {
    public var associatedViewController: UIViewController? {
        self
    }
}

extension UIViewController: ViewControllerProvider {
    public func viewController() -> UIViewController? {
        self
    }
}

extension UIViewController: UIViewControllerOrFlowCoordinator {
    public func managedViewControllerProvider() -> ManagedViewControllerProvider {
        self
    }
}

extension UIViewController: FlowStepIdentifiable {
    public var flowStep: FlowStep? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectFlowStepKey) as? FlowStep
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedObjectFlowStepKey,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
