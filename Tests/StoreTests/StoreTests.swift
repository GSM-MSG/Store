import Combine
import XCTest
@testable import Store

final class TestStore: Store {
    struct State: Equatable {
        var count = 0
    }

    enum Action {
        case increase
    }

    enum Mutation {
        case increase
    }

    var initialState: State
    var stateSubject: CurrentValueSubject<State, Never>
    var subscription: Set<AnyCancellable> = .init()

    init() {
        self.initialState = .init()
        self.stateSubject = CurrentValueSubject(initialState)
    }

    func mutate(state: State, action: Action) -> SideEffect<Mutation, Never> {
        switch action {
        case .increase:
            return .just(.increase)
        }
    }

    func reduce(state: State, mutate: Mutation) -> State {
        var newState = state

        switch mutate {
        case .increase:
            newState.count += 1
        }

        return newState
    }
}

final class StoreTests: XCTestCase {
    var subscription = Set<AnyCancellable>()

    func testStore() {
        let store = TestStore()

        let expectation = XCTestExpectation(description: "State Updated")

        store.state
            .dropFirst()
            .sink { state in
                XCTAssertEqual(state.count, 1)
                expectation.fulfill()
            }
            .store(in: &subscription)

        store.send(.increase)

        wait(for: [expectation], timeout: 1.0)
    }
}
