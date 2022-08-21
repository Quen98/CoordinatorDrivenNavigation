//
//  PresentedViewController.swift
//  CoordinatorDrivenNavigationDemo
//
//  Created by Quentin QUENNEHEN on 21/08/2022.
//

import UIKit

class PresentedViewController: UIViewController {
    private lazy var label: UILabel = createLabel()

    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        buildViewHierarchy()
        setConstraints()
    }

    // MARK: Layout
    private func buildViewHierarchy() {
        view.addSubview(label)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            label.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

private extension PresentedViewController {
    func createLabel() -> UILabel {
        let label = UILabel()

        label.numberOfLines = 0
        label.text = "This UIViewController is being presented"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
