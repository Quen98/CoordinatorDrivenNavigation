//
//  DetailViewController.swift
//  CoordinatorDrivenNavigationDemo
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//

import UIKit

class DetailViewController: UIViewController {
    private lazy var presentButton: UIButton = createPresentButton()
    private lazy var showNestedCoordinatorButton: UIButton = createNestedCoordinatorButton()

    var onPresentButtonTapped: (() -> Swift.Void)?
    var onNestedCoordinatorButtonTapped: (() -> Swift.Void)?

    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        navigationItem.title = "Detail"
        buildViewHierarchy()
        setConstraints()
    }

    // MARK: Layout
    private func buildViewHierarchy() {
        view.addSubview(presentButton)
        view.addSubview(showNestedCoordinatorButton)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            presentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presentButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),

            showNestedCoordinatorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            showNestedCoordinatorButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50)
        ])
    }

    // MARK: User interactions
    @objc private func handleTapOnPresentButton() {
        onPresentButtonTapped?()
    }

    @objc private func handleTapOnNestedCoordinatorButton() {
        onNestedCoordinatorButtonTapped?()
    }
}

private extension DetailViewController {
    func createPresentButton() -> UIButton {
        let button = createButton()

        button.setTitle("Present UIViewController", for: .normal)
        button.addTarget(self, action: #selector(handleTapOnPresentButton), for: .touchUpInside)
        return button
    }

    func createNestedCoordinatorButton() -> UIButton {
        let button = createButton()

        button.setTitle("Show Nested Coordinator", for: .normal)
        button.addTarget(self, action: #selector(handleTapOnNestedCoordinatorButton), for: .touchUpInside)
        return button
    }

    func createButton() -> UIButton {
        let button = UIButton()

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.label, for: .normal)
        return button
    }
}
