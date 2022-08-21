//
//  NestedViewController.swift
//  CoordinatorDrivenNavigationDemo
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//

import UIKit

class NestedViewController: UIViewController {
    private lazy var button: UIButton = createButton()

    var onCompleteNestedFlow: (() -> Swift.Void)?

    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Nested main"
        buildViewHierarchy()
        setConstraints()
    }

    // MARK: Layout
    private func buildViewHierarchy() {
        view.addSubview(button)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: User interactions
    @objc private func handleTapOnButton() {
        onCompleteNestedFlow?()
    }
}

private extension NestedViewController {
    func createButton() -> UIButton {
        let button = UIButton()

        button.setTitleColor(.label, for: .normal)
        button.setTitle("Back to initial flow", for: .normal)
        button.addTarget(self, action: #selector(handleTapOnButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
