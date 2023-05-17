import Combine

public struct SideEffect<Output, Failure: Error>: Publisher {
    public let upstream: AnyPublisher<Output, Failure>

    public init<P: Publisher>(
        _ publisher: P
    ) where P.Output == Output, P.Failure == Failure {
        self.upstream = publisher.eraseToAnyPublisher()
    }

    public init(error: Failure) {
        self.init(
            Fail(error: error)
        )
    }

    public func receive<S>(
        subscriber: S
    ) where S: Combine.Subscriber, Failure == S.Failure, Output == S.Input {
        self.upstream.subscribe(subscriber)
    }
}

extension SideEffect {
    public static var none: SideEffect {
        Empty(completeImmediately: true)
            .eraseToSideEffect()
    }

    public static func just(
        _ value: Output
    ) -> Self {
        Just(value).setFailureType(to: Failure.self)
            .eraseToSideEffect()
    }

    public static func future(
        _ result: @escaping (@escaping (Result<Output, Failure>) -> Void) -> Void
    ) -> Self {
        Future(result)
            .eraseToSideEffect()
    }

    public static func merge(
        _ sideEffects: SideEffect...
    ) -> Self {
        .merge(sideEffects)
    }

    public static func merge<S: Sequence>(
        _ sideEffects: S
    ) -> Self where S.Element == SideEffect {
        Publishers.MergeMany(sideEffects)
            .eraseToSideEffect()
    }

    public static func concat(
        _ sideEffects: SideEffect...
    ) -> Self {
        .concat(sideEffects)
    }

    public static func concat<C: Collection>(
        _ sideEffects: C
    ) -> Self where C.Element == SideEffect {
        return sideEffects
            .reduce(into: .none) { result, sideEffect in
                result = Publishers.Concatenate(
                    prefix: result,
                    suffix: sideEffect
                )
                .eraseToSideEffect()
            }
    }

    public static func async(
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping () async -> Output
    ) -> Self {
        var task: Task<Void, Never>?
        return .future { promise in
            task = Task(
                priority: priority,
                operation: { @MainActor in
                    guard !Task.isCancelled else { return }
                    let output = await operation()
                    guard !Task.isCancelled else { return }
                    promise(.success(output))
                }
            )
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToSideEffect()
    }

    public static func tryAsync(
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping () async throws -> Output
    ) -> SideEffect<Output, Error> {
        Deferred {
            let subject = PassthroughSubject<Output, Error>()
            let task = Task(
                priority: priority,
                operation: { @MainActor in
                    do {
                        try Task.checkCancellation()
                        let output = try await operation()
                        try Task.checkCancellation()
                        subject.send(output)
                        subject.send(completion: .finished)
                    } catch is CancellationError {
                        subject.send(completion: .finished)
                    } catch {
                        subject.send(completion: .failure(error))
                    }
                }
            )
            return subject.handleEvents(receiveCancel: task.cancel)
        }
        .eraseToSideEffect()
    }

    public func map<T>(
        _ transform: @escaping (Output) -> T
    ) -> SideEffect<T, Failure> {
        (self.map(transform) as Publishers.Map<Self, T>)
            .eraseToSideEffect()
    }

    public func catchMap(
        _ transform: @escaping (Failure) -> Output
    ) -> SideEffect<Output, Never> {
        self.catch { Just(transform($0)) }
            .eraseToSideEffect()
    }

    public func catchToNever() -> SideEffect<Output, Never> {
        self.catch { _ in Empty(completeImmediately: true) }
            .eraseToSideEffect()
    }

    public func catchAndReturn(
        _ value: Output
    ) -> SideEffect<Output, Never> {
        self.catchMap { _ in value }
            .eraseToSideEffect()
    }
}

extension Publisher {
    public func eraseToSideEffect() -> SideEffect<Output, Failure> {
        SideEffect(self)
    }
}
