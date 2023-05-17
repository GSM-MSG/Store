import Combine
import Foundation

public protocol Store: AnyObject {
    associatedtype State: Equatable
    associatedtype Action
    associatedtype Mutation

    var stateSubject: CurrentValueSubject<State, Never> { get }
    var initialState: State { get }
    var subscription: Set<AnyCancellable> { get set }

    var currentState: State { get }
    var state: AnyPublisher<State, Never> { get }

    func mutate(state: State, action: Action) -> SideEffect<Mutation, Never>
    func reduce(state: State, mutate: Mutation) -> State
    func send(_ action: Action)
}

public extension Store {
    var currentState: State {
        stateSubject.value
    }

    var state: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func send(_ action: Action) {
        mutate(state: currentState, action: action)
            .sink { [weak self] mutate in
                guard let self else { return }
                let newState = self.reduce(state: currentState, mutate: mutate)
                self.stateSubject.send(newState)
            }
            .store(in: &subscription)
    }
}
