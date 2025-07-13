//
//  StateViewModel.swift
//  SwiftSmartViewModels
//
//  Created by Josh Gallant on 12/07/2025.
//

import Combine

/// A protocol for view models that expose an immutable state and a publisher for observing state changes.
///
/// Use this protocol to create view models that manage a single state struct and allow observers (such as SwiftUI views or Combine subscribers)
/// to react to state updates in a type-safe and predictable way.
///
/// Example usage:
/// ```swift
///struct CounterStateState {
///     var count: Int = 0
///}
///
/// final class CounterViewModel: StateViewModel {
///
///     @Published private(set) var state = State()
///
///     var statePublisher: Published<State>.Publisher { $state }
///
///     func increment() { state.count += 1 }
/// }
/// ```
public protocol StateViewModel: AnyObject {
    /// The type describing all state for this view model.
    associatedtype State
    
    /// The current value of the state.
    var state: State { get }
    
    /// A publisher that emits the state whenever it changes.
    var statePublisher: Published<State>.Publisher { get }
}
