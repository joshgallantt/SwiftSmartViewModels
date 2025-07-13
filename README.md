# SwiftSmartViewModels

SwiftSmartViewModels is a lightweight, protocol-driven library for building robust, composable ViewModels in SwiftUI and UIKit apps. It is designed to work naturally with SwiftUI patterns, including ObservableObject and @Published, not against them.

## <br><br> Features
- Protocols for handling state (`StateViewModel`) and one-off effects (`EventViewModel`)
- Seamless with `ObservableObject` and `@Published` for idiomatic SwiftUI
- Publisher-based APIs for SwiftUI, UIKit, and Combine
- Works cross-platform: iOS, macOS, watchOS, tvOS, visionOS

## <br><br> Installation
Add SwiftSmartViewModels using Swift Package Manager.

Xcode:
1. File > Add Packages...
2. Enter the repository URL and add the package

Or in Package.swift:

```Swift
dependencies: [
  .package(url: "https://github.com/joshgallantt/SwiftSmartViewModels.git", from: "1.0.0")
]

targets: [
  .target(
    name: "YourTarget",
    dependencies: ["SwiftSmartViewModels"]
  ),
]
```

## <br><br> Usage

### StateViewModel — A container for your state properties

```Swift
struct CounterState {
  var count: Int = 0
}

final class CounterViewModel: ObservableObject, StateViewModel {

  @Published private(set) var state = CounterState()
  
  var statePublisher: Published<CounterState>.Publisher { $state }
  
  func increment() { state.count += 1 }
}
```

This works perfectly with SwiftUI's property wrappers:

```Swift
import SwiftSmartViewModels
import SwiftUI

struct CounterView: View {
  @ObservedObject var viewModel: CounterViewModel
  var body: some View {
    VStack {
      Text("Count: \(viewModel.state.count)")
      Button("Increment") {
        viewModel.increment()
      }
    }
  }
}
```

### EventViewModel — One-Off Effects, SwiftUI-Friendly

```Swift
struct LoginSucceeded: ViewModelEvent {}
struct LoginFailed: ViewModelEvent { let message: String }

final class LoginViewModel: ObservableObject, EventViewModel {
  private let eventSubject = PassthroughSubject<ViewModelEvent, Never>()
  var eventPublisher: AnyPublisher<ViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }

  func login(username: String, password: String) {
    if username == "cat", password == "meow" {
      eventSubject.send(LoginSucceeded())
    } else {
      eventSubject.send(LoginFailed(message: "Invalid password"))
    }
  }
}

struct LoginView: View {
  @ObservedObject var viewModel: LoginViewModel
  @State private var showAlert = false
  @State private var alertMessage = ""
  
  var body: some View {
    VStack {
      Button("Login") {
        viewModel.login(username: "cat", password: "meow")
      }
    }
    .onReceive(viewModel.eventPublisher) { event in
      if let failure = event as? LoginFailed {
        alertMessage = failure.message
        showAlert = true
      }
    }
    .alert("Login Error", isPresented: $showAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(alertMessage)
    }
  }
}
```

## <br> EventViewModel — Examples

### <br> 1. **Child to Parent via Child Event (Parent listens using `.onReceive`)**

*User sees both views. User interacts with the parent view (e.g. a button). Parent view sends command to child view model, child emits event, and parent view reacts via `.onReceive`.*

```swift
import SwiftSmartViewModels
import SwiftUI
import Combine

struct ExampleEvent: ViewModelEvent {
    let text: String
}

// 1. ParentView is shown with a button and the child view.
struct ParentView: View {
    @ObservedObject var viewModel: ParentViewModel
    @State private var lastChildEvent: String = "No event"

    var body: some View {
        VStack(spacing: 16) {
            Button("Send to child") {
                // 2. User taps button, triggers parent VM to send command to child
                viewModel.sendToChild()
            }
            Text("Parent received: \(lastChildEvent)")
            ChildView(viewModel: viewModel.child)
        }
        .onReceive(viewModel.child.eventPublisher) { event in
            // 6. ParentView listens for child's event and reacts
            if let evt = event as? ExampleEvent {
                // 7. Parent updates its UI
                lastChildEvent = evt.text
            }
        }
    }
}

// 3. ParentViewModel holds child and can send command to it
final class ParentViewModel: ObservableObject {
    let child = ChildViewModel()
    func sendToChild() {
        // 4. Instructs child to emit event
        child.emitExampleEvent("Hello from Parent")
    }
}

// 5. ChildViewModel emits event when asked
final class ChildViewModel: EventViewModel, ObservableObject {
    private let eventSubject = PassthroughSubject<ViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<ViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func emitExampleEvent(_ text: String) {
        eventSubject.send(ExampleEvent(text: text))
    }
}
```

### **Call order:**

1. `ParentView` renders and subscribes to `child.eventPublisher`.
2. User taps "Send to child" button.
3. `ParentViewModel.sendToChild()` is called.
4. `ChildViewModel.emitExampleEvent("Hello from Parent")` is called.
5. `eventSubject` in child emits `ExampleEvent`.
6. `.onReceive` in `ParentView` receives the event.
7. `lastChildEvent` is updated, UI refreshes.


### <br>  2. **Child to Child via Event (Sibling communication mediated by parent, observed via `.onReceive`)**

*User sees parent with two children. User interacts with one child view, which causes that child to emit an event. The parent listens, then tells the other child to emit, and the sibling child view listens with `.onReceive` and updates UI.*

```swift
import SwiftSmartViewModels
import SwiftUI
import Combine

struct ExampleEvent: ViewModelEvent {
    let text: String
}

// 1. ParentViewModel holds both children
final class ParentViewModel: ObservableObject {
    let childA = ChildAViewModel()
    let childB = ChildBViewModel()
}

// 2. ParentView is shown with both children
struct ParentView: View {
    @ObservedObject var viewModel: ParentViewModel

    var body: some View {
        VStack(spacing: 16) {
            ChildAView(viewModel: viewModel.childA)
            ChildBView(viewModel: viewModel.childB)
        }
        // 5. Listen to childA's events
        .onReceive(viewModel.childA.eventPublisher) { event in
            if let evt = event as? ExampleEvent {
                // 6. ParentView tells childB to emit an event
                viewModel.childB.emitExampleEvent("ChildA said: \(evt.text)")
            }
        }
    }
}

// 3. ChildAView shows a button to emit event
struct ChildAView: View {
    @ObservedObject var viewModel: ChildAViewModel
    var body: some View {
        Button("Send to sibling") {
            // 4. User taps: childA emits event
            viewModel.emitExampleEvent("Hello from ChildA")
        }
    }
}

// 5. ChildAViewModel emits event when asked
final class ChildAViewModel: EventViewModel, ObservableObject {
    private let eventSubject = PassthroughSubject<ViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<ViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func emitExampleEvent(_ text: String) {
        eventSubject.send(ExampleEvent(text: text))
    }
}

// 6. ChildBViewModel emits event when asked by parent
final class ChildBViewModel: EventViewModel, ObservableObject {
    private let eventSubject = PassthroughSubject<ViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<ViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func emitExampleEvent(_ text: String) {
        eventSubject.send(ExampleEvent(text: text))
    }
}

// 7. ChildBView listens for childB's events and updates
struct ChildBView: View {
    @ObservedObject var viewModel: ChildBViewModel
    @State private var lastEvent: String = "No event"
    var body: some View {
        Text("ChildB received: \(lastEvent)")
            .onReceive(viewModel.eventPublisher) { event in
                // 8. ChildBView receives event from its own VM and updates UI
                if let evt = event as? ExampleEvent {
                    lastEvent = evt.text
                }
            }
    }
}
```

### **Call order:**

1. User sees `ParentView` displaying `ChildAView` and `ChildBView`.
2. User taps the button in `ChildAView`.
3. `ChildAView` calls `viewModel.emitExampleEvent("Hello from ChildA")` on `ChildAViewModel`.
4. `ChildAViewModel` sends an `ExampleEvent` via its `eventSubject`.
5. `ParentView` listens to `childA.eventPublisher` via `.onReceive`, receives the event.
6. `ParentView`, in response, tells `childB` to emit a new event with a message referencing ChildA.
7. `ChildBViewModel` emits an `ExampleEvent` via its own `eventSubject`.
8. `ChildBView` listens to `viewModel.eventPublisher` via `.onReceive`, receives the event, and updates its UI (`lastEvent`).


## <br> License

MIT – see [`LICENSE`](./LICENSE)

## <br> Questions or Feedback?

Open an issue or join a discussion!

<br>

Made with ❤️ by Josh Gallant
