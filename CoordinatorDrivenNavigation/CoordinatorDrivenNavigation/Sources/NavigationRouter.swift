//
//  NavigationRouter.swift
//  ForgottenTales
//
//  Created by Quentin QUENNEHEN on 19/08/2022.
//  Copyright © 2022 Toasted-Bread. All rights reserved.
//

import UIKit

public protocol NavigationControllerRouter {
    func viewController(before viewController: UIViewController) -> UIViewController?
    func push(viewController: UIViewController, animated: Bool)
    func present(viewController: UIViewController, animated: Bool)
    func popLast(andShow nextViewController: UIViewController?, animated: Bool)
    func pop(to viewController: UIViewController, andShow nextViewController: UIViewController?, animated: Bool)
    func pop(toViewControllerBefore viewController: UIViewController, andShow nextViewController: UIViewController?, animated: Bool)
    func dismiss(animated: Bool)
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
}

// NavigationRouter is the object that actually manages navigation in the UINavigationController.
public class NavigationRouter: NavigationControllerRouter {
    private weak var navigationController: UINavigationController?

    var viewControllers: [UIViewController] {
        navigationController?.viewControllers ?? []
    }

    // Used for Units Tests
    var steps: [FlowStep] {
        navigationController?.viewControllers.compactMap { $0.flowStep } ?? []
    }

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func viewController(before viewController: UIViewController) -> UIViewController? {
        guard let index = navigationController?.viewControllers.firstIndex(of: viewController),
              index > 0 else { return nil }

        return navigationController?.viewControllers[index - 1]
    }

    public func push(viewController: UIViewController, animated: Bool) {
        guard navigationController?.viewControllers.isEmpty == false else {
            setViewControllers([viewController], animated: animated)
            return
        }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    public func present(viewController: UIViewController, animated: Bool) {
        navigationController?.present(viewController, animated: animated)
    }

    public func popLast(andShow nextViewController: UIViewController? = nil, animated: Bool) {
        guard var viewControllers = navigationController?.viewControllers else { return }

        viewControllers.removeLast()
        setViewControllers(
            viewControllers + [nextViewController].compactMap { $0 },
            animated: animated
        )
    }

    public func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        navigationController?.setViewControllers(
            viewControllers,
            animated: animated
        )
    }

    public func pop(to viewController: UIViewController, andShow nextViewController: UIViewController? = nil, animated: Bool) {
       guard let index = navigationController?.viewControllers.firstIndex(of: viewController),
             let previousControllers = navigationController?.viewControllers[0..<index + 1] else {
           setViewControllers([nextViewController].compactMap { $0 }, animated: animated)
           return
       }

        setViewControllers(
            previousControllers + [nextViewController].compactMap { $0 },
            animated: animated
        )
    }

    public func dismiss(animated: Bool) {
        navigationController?.dismiss(animated: animated)
    }

    public func pop(toViewControllerBefore viewController: UIViewController, andShow nextViewController: UIViewController?, animated: Bool) {
        guard let previousController = self.viewController(before: viewController) else { return }

        pop(to: previousController, andShow: nextViewController, animated: animated)
    }

    func lastViewController(for flowStep: FlowStep) -> UIViewController? {
        return navigationController?.viewControllers.last { $0.flowStep == flowStep }
    }
}