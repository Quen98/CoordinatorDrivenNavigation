# CoordinatorDrivenNavigation
A framework than handles iOS app navigation using Coordinators

This framework has been created upon Soroush Khanlou's work about [Coordinators](https://khanlou.com/2015/01/the-coordinator/)
that leverages the navigation workload outside the `UIViewController`

It has been combined with a UIViewController/FlowStep association to simplyfy the navigation

## Installation
For now, the best way to use the CoordinationDrivenNavigationFramework is to used it as submodule and link it in your Xcode project.

## Creating a coordinated driven navigation

First, you will need to declare two enums:
- An enum listing all the steps possible in your coordinator, implementing `FlowStep` and `FlowStepAdapter`. This is what is going to be use to retrieve the `UIViewControllers` later.
- A CompletionState, implementing `FlowCompletionState`

Example:

```
enum AppFlowStep: FlowStep, FlowStepAdapter { 
    case main
    case detail
}

enum AppFlowCompletionState: FlowCompletionState {
    case success
}
```

Now, create a `class` that implements the `FlowCoordinator` protocol, and fills it requirements.

Example:

```
class AppFlowCoordinator: FlowCoordinator {
    var initialStep: AppFlowStep = .welcome
    weak var flowCoordinator: NavigationFlowCoordinator?
    var completion: ((AppFlowCompletionState, Any?) -> Void)?

    func newViewControllerOrCoordinatorForStep(_ step: AppFlowStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        switch step {
        case .main:
            return createWelcomeViewController()
        case .detail:
            return createDetailViewController()
        }
    }
```

### /!\ `flowCoordinator` should always be weak to prevent retain cycles

The Coordination needs a special `UINavigationController` subclass to work, called `CoordinatorDrivenNavigationViewController`
Simply instantiate it, put it in your `window`, and let the coordinator handle the navigation

Example:
```
let window = UIWindow(windowScene: scene)
let navigation = CoordinatorDrivenNavigationViewController(
    coordinator: AppFlowCoordinator()
)

window.rootViewController = navigation
window.makeKeyAndVisible()
self.window = window
```

## Navigating using the FlowCoordinator

Once the Navigation is setup with your Navigator, you just need from the Coordinator to calls the existing methods to drive your app's navigation

For now, the FlowCoordinator provides the following methods:
- `push(step:)` 
- `present(step:)` 
- `replaceCurrentStep(with:)` (replaces the current viewController by the one provided)
- `return(to:)` (goes back to the specified step)
- `restartFlow(with:)` (replaces every current steps previously provided by the new one)


Example:

```
class AppFlowCoordinator: FlowCoordinator {
    var initialStep: AppFlowStep = .welcome
    weak var flowCoordinator: NavigationFlowCoordinator?
    var completion: ((AppFlowCompletionState, Any?) -> Void)?

    func newViewControllerOrCoordinatorForStep(_ step: AppFlowStep, param: Any?) -> UIViewControllerOrFlowCoordinator? {
        switch step {
        case .welcome:
            return createWelcomeViewController()
        case .detail:
            return createDetailViewController()
        }
    }

    private func createWelcomeViewController() -> UIViewController {
        let viewController = WelcomeViewController()

        viewController.onNextButtonTapped = { [weak self] in
            self?.push(step: .detail)
        }
        return viewController
    }
}
```

See the demo app for a concrete implementation of the CoordinatorDrivenNavigation