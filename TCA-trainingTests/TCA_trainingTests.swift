//
//  TCA_trainingTests.swift
//  TCA-trainingTests
//
//  Created by Fernando Putallaz on 17/07/2026.
//

import ComposableArchitecture
import Testing
@testable import TCA_training

struct TCA_trainingTests {

    @Test func incrementAndDecrement() async throws {
        let store = TestStore(initialState: CounterFeature.State()) {
            CounterFeature()
        }

        await store.send(.incrementButtonTapped) {
            $0.count = 1
        }
        await store.send(.decrementButtonTapped) {
            $0.count = 0
        }
    }
}
