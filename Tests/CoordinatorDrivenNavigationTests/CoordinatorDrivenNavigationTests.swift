import XCTest
@testable import CoordinatorDrivenNavigation

enum CoordinatorStep: FlowStep, FlowStepAdapter {
    case first
    case second
    case third
}

enum CoordinatorCompletionState: FlowCompletionState {
    case success
}

var FlowStepAssociatedObjectKey: UInt8 = 0

extension UIViewController {
    var flowStep: FlowStep? {
        get {
            objc_getAssociatedObject(
                self,
                &FlowStepAssociatedObjectKey
            ) as? FlowStep
        }
        set {
            objc_setAssociatedObject(
                self,
                &FlowStepAssociatedObjectKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
}

class FakeNavigationController: CoordinatorDrivenNavigationViewController {
    override var viewControllers: [UIViewController] {
        get { controllers }
        set { controllers = newValue }
    }

    private var controllers: [UIViewController] = []

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewControllers.append(viewController)
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        viewControllers.popLast()
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        guard let index = viewControllers.firstIndex(of: viewController) else { return nil }

        viewControllers = Array(viewControllers.prefix(upTo: index))
        return nil
    }

    func isInSyncWithCoordinator() -> Bool {
        controllers.map { flowCoordinator?.flowStep(associatedTo: $0) } == flowCoordinator?.steps
    }
}

class Coordinator: FlowCoordinator {
    var initialStep: CoordinatorStep = .first
    weak var flowCoordinator: NavigationFlowCoordinator?
    var completion: ((CoordinatorCompletionState, Any?) -> Void)?

    func newViewControllerOrCoordinatorForStep(_ step: CoordinatorStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        return UIViewController()
    }
}

final class CoordinatorDrivenNavigationTests: XCTestCase {
    func test_simplePush() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )
        coordinator.push(step: .second)
        coordinator.push(step: .third)
        let expectedResults: [CoordinatorStep] = [.first, .second, .third]
        XCTAssertEqual(coordinator.steps, expectedResults)
        XCTAssertEqual(navigation.viewControllers.count, expectedResults.count)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }

    func test_returningToStep() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )
        coordinator.push(step: .second)
        coordinator.push(step: .third)
        coordinator.returnTo(.second)
        XCTAssertEqual(coordinator.steps, [.first, .second])
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())

        coordinator.returnTo(.first)
        XCTAssertEqual(coordinator.steps, [.first])
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }

    func test_replaceCurrentStep() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )
        coordinator.push(step: .second)
        coordinator.replaceCurrentStep(with: .third)
        XCTAssertEqual(coordinator.steps, [.first, .third])
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }

    func test_retartFlow() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )
        coordinator.push(step: .second)
        coordinator.restartFlow(with: .third)
        XCTAssertEqual(coordinator.steps, [.third])
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }

    func test_pushingSameStep() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )

        coordinator.push(step: .second)
        coordinator.push(step: .second)
        XCTAssertEqual(coordinator.steps, [.first, .second, .second])
        XCTAssertEqual(navigation.viewControllers.count, 3)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }

    func test_returningFromSameSteps() {
        let coordinator = Coordinator()
        let navigation = FakeNavigationController(
            coordinator: coordinator
        )

        coordinator.push(step: .second)
        coordinator.push(step: .second)
        coordinator.push(step: .third)
        coordinator.returnTo(.second)

        XCTAssertEqual(coordinator.steps, [.first, .second, .second])
        XCTAssertEqual(navigation.viewControllers.count, 3)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())

        coordinator.returnTo(.second)
        XCTAssertEqual(coordinator.steps, [.first, .second])
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())

        // Nothing should happen here as there is not second flowStep anymore
        coordinator.returnTo(.second)
        XCTAssertEqual(coordinator.steps, [.first, .second])
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertTrue(navigation.isInSyncWithCoordinator())
    }
}
