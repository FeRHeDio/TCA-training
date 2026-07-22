# TCA Fundamentals — The Counter

This is the smallest possible TCA feature: a counter with `+`/`−` buttons and no
side effects at all. The goal isn't the counter — it's isolating the four
pieces every TCA feature is built from, before any complexity (effects,
dependencies, navigation, composition) gets added on top.

## The problem TCA solves

Plain SwiftUI state (`@State`, `@Observable` view models) works fine until a
feature grows: business logic gets tangled with view code, side effects
(network calls, timers) are hard to test, and two features that need to talk
to each other end up reaching into each other's internals.

TCA borrows the Redux/Elm idea — **unidirectional data flow** — and adds:

- a rigorous, mechanical way to compose small features into bigger ones
- first-class, deterministic testing of business logic *and* side effects
- a single place (the reducer) where all state mutation happens

## The four pieces

Every feature is the same four ingredients. Here they are for the counter
(`TCA-training/CounterFeature.swift`):

### 1. `State` — what the feature needs to render

```swift
@ObservableState
struct State: Equatable {
    var count = 0
}
```

Just data. No logic. `@ObservableState` is what makes SwiftUI re-render when
it changes (it plugs into Swift's Observation framework — the same mechanism
behind `@Observable`). `Equatable` is what makes the feature testable (see
below) and lets TCA skip redundant view updates.

### 2. `Action` — everything that can happen

```swift
enum Action {
    case decrementButtonTapped
    case incrementButtonTapped
}
```

Every user interaction, every timer tick, every network response is an
`Action` case. Naming convention: describe the *event*, not the intent —
`incrementButtonTapped`, not `increment`. The button doesn't know what
incrementing means; only the reducer does.

### 3. `Reducer` — the only place state changes

```swift
var body: some ReducerOf<Self> {
    Reduce { state, action in
        switch action {
        case .decrementButtonTapped:
            state.count -= 1
            return .none
        case .incrementButtonTapped:
            state.count += 1
            return .none
        }
    }
}
```

A reducer is a pure function: `(inout State, Action) -> Effect<Action>`.
Given the current state and an action, it mutates state directly and returns
an `Effect` describing any side effect to run (`.none` means "no side effect,
we're done"). Nothing outside this function is allowed to touch `state`.

The `@Reducer` macro on the struct wires up boilerplate (mainly the
`Reducer` protocol conformance) so you can write `body` instead of a manual
`reduce(into:action:)` implementation.

### 4. `Store` — the runtime that ties it together

```swift
Store(initialState: CounterFeature.State()) {
    CounterFeature()
}
```

The `Store` holds the current state, and is the only thing a view talks to.
The view never calls the reducer directly — it sends actions:

```swift
Button("+") { store.send(.incrementButtonTapped) }
```

and reads state directly off the store, since `@ObservableState` makes
`store.count` observable in the view body:

```swift
Text("\(store.count)")
```

## The data flow, end to end

```
View                    Store                    Reducer
 |                        |                          |
 |--- store.send(.tap) -->|                          |
 |                        |--- reduce(&state, tap) -->|
 |                        |<---- mutated state -------|
 |<---- observes count ---|                          |
```

1. The view sends an `Action`.
2. The `Store` hands the current `State` and that `Action` to the `Reducer`.
3. The reducer mutates state in place and returns an `Effect` (here, `.none`).
4. The `Store` publishes the new state; any view reading the changed
   properties re-renders automatically.

It's one-way: the view can never mutate state itself, and the reducer can
never talk to the view. That single constraint is what makes every reducer
testable in complete isolation from SwiftUI.

## Why this is testable (the payoff)

```swift
let store = TestStore(initialState: CounterFeature.State()) {
    CounterFeature()
}

await store.send(.incrementButtonTapped) {
    $0.count = 1
}
await store.send(.decrementButtonTapped) {
    $0.count = 0
}
```

`TestStore` sends real actions through the real reducer — no mocking. The
trailing closure is an *assertion*: you describe exactly how you expect state
to change, and the test fails if the reducer does anything else (including if
it changes something you didn't mention). This exhaustiveness is what makes
TCA tests catch regressions that a plain "does the count equal 1" assertion
would miss.

See `TCA-trainingTests/TCA_trainingTests.swift` for the full test.

## What's deliberately not here yet

This example has **no side effects** — every action returns `.none`. The next
step up in complexity is an action whose reducer case returns a real
`Effect` (e.g. an async network call or a timer), and testing that with
`TestStore` by asserting on the actions it feeds back in. That's the natural
next fundamental once this one is solid.

## File map

| File | Role |
|---|---|
| `TCA-training/CounterFeature.swift` | `State`, `Action`, `Reducer` |
| `TCA-training/ContentView.swift` | View — sends actions, reads state |
| `TCA-training/TCA_trainingApp.swift` | Creates the app's `Store` |
| `TCA-trainingTests/TCA_trainingTests.swift` | `TestStore` example |

## A note on this project's build settings

Xcode's newer project template default (`SWIFT_DEFAULT_ACTOR_ISOLATION =
MainActor`) currently triggers a compiler crash ("circular reference") when
combined with TCA's `@Reducer` macro and its opaque `some ReducerOf<Self>`
return type. This project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`
to avoid it — worth knowing about if you start a fresh TCA project from an
Xcode 16.3+/26 template and hit the same error.
