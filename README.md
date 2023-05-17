# Store

Unidirectional data flow state management library.

[Document](https://gsm-msg.github.io/Store/documentation/store/)

## contents- [Store](#store)
- [Store](#store)
  - [contents- Store](#contents--store)
  - [Requirements](#requirements)
  - [Overview](#overview)
  - [Communication](#communication)
  - [Installation](#installation)
    - [Swift Package Manager](#swift-package-manager)
    - [Manually](#manually)
  - [Usage](#usage)
    - [Quick Start](#quick-start)

## Requirements
- iOS 13.0+
- tvOS 13.0+
- macOS 10.15+
- watchOS 7.0+
- Swift 5.7+


## Overview

Unidirectional data flow state management library.

## Communication
- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.


## Installation

### Swift Package Manager

[Swift Package Manager](https://www.swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate `Store` into your Xcode project using Swift Package Manager, add it to the dependencies value of your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/GSM-MSG/Store.git", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate MSGLayout into your project manually.

## Usage

### Quick Start
```swift
import Combine
import Store
import UIKit

// MARK: - Store
final class SampleStore: Store {
    struct State: Equatable {
        var count: Int = 0
    }

    enum Action {
        case plusButtonDidTap
        case minusButtonDidTap
    }

    enum Mutation {
        case updateCount(Int)
    }

    var stateSubject: CurrentValueSubject<State, Never>
    var initialState: State
    var subscription: Set<AnyCancellable> = .init()

    init(initialState: State) {
        self.initialState = initialState
        self.stateSubject = CurrentValueSubject(initialState)
    }

    func mutate(state: State, action: Action) -> SideEffect<Mutation, Never> {
        switch action {
        case .plusButtonDidTap:
            return .tryAsync { [count = state.count] in
                try await Task.sleep(for: .milliseconds(500))
                return .updateCount(count + 1)
            }
            .catchToNever()

        case .minusButtonDidTap:
            return .just(.updateCount(state.count - 1))

        default :
            return .none
        }
        return .none
    }

    func reduce(state: State, mutate: Mutation) -> State {
        var newState = state
        switch mutate {
        case let .updateCount(count):
            newState.count = count
        }
        return newState
    }
}

// MARK: - ViewController
final class SampleViewController: UIViewController {
    let store: SampleStore
    var subscription: Set<AnyCancellable> = .init()

    init() {
        self.store = .init(initialState: .init())
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0"
        return label
    }()
    private let plusButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("+", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    private let minusButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("-", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(countLabel)
        view.addSubview(plusButton)
        view.addSubview(minusButton)

        NSLayoutConstraint.activate([
            countLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            countLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            plusButton.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor),
            plusButton.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor),

            minusButton.leadingAnchor.constraint(equalTo: countLabel.trailingAnchor),
            minusButton.centerYAnchor.constraint(equalTo: countLabel.centerYAnchor)
        ])

        plusButton.addAction(UIAction(handler: { [weak self] _ in
            self?.store.send(.plusButtonDidTap)
        }), for: .touchUpInside)

        minusButton.addAction(UIAction(handler: { [weak self] _ in
            self?.store.send(.minusButtonDidTap)
        }), for: .touchUpInside)

        store.state.map(\.count)
            .map(String.init)
            .assign(to: \.text, on: countLabel)
            .store(in: &subscription)
    }
}
```