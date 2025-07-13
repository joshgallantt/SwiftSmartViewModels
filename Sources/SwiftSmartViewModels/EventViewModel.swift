//
//  EventViewModel.swift
//  SwiftSmartViewModels
//
//  Created by Josh Gallant on 12/07/2025.
//

import Combine

/// Marker protocol for view events, allowing polymorphic handling of event types.
public protocol ViewModelEvent {}


/// A protocol for view models that publish transient, one-off events (such as navigation, alerts, or side effects) to be observed by external components like views or coordinators.
///
/// Use this protocol when your view model needs to communicate actions or effects that are not part of continuous state.
/// It is complementary to `StateViewModel`, which manages persistent or continuous view state.
///
/// ### Usage:
/// 1. Define each event as a struct (or class) conforming to `ViewEvent`.
/// 2. Expose an `eventPublisher` using a `PassthroughSubject<ViewEvent, Never>`.
/// 3. Send specific event types as needed from your view model methods.
///
/// ```swift
/// protocol ViewEvent {}
/// struct LoginSucceeded: ViewEvent {}
/// struct LoginFailed: ViewEvent { let message: String }
///
/// final class LoginViewModel: EventViewModel {
///     private let eventSubject = PassthroughSubject<ViewEvent, Never>()
///     var eventPublisher: AnyPublisher<ViewEvent, Never> { eventSubject.eraseToAnyPublisher() }
///
///     func login(username: String, password: String) {
///         if username == "cat", password == "meow" {
///             eventSubject.send(LoginSucceeded())
///         } else {
///             eventSubject.send(LoginFailed(message: "Invalid password"))
///         }
///     }
/// }
/// ```
public protocol EventViewModel: AnyObject {
    var eventPublisher: AnyPublisher<ViewModelEvent, Never> { get }
}
