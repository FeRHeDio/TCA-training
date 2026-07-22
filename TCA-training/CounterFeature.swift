//
//  CounterFeature.swift
//  TCA-training
//
//  Created by Fernando Putallaz on 17/07/2026.
//

import ComposableArchitecture

@Reducer
struct CounterFeature {

    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action {
        case decrementButtonTapped
        case incrementButtonTapped
    }

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
}
