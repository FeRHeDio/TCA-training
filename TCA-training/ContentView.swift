//
//  ContentView.swift
//  TCA-training
//
//  Created by Fernando Putallaz on 17/07/2026.
//

import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    let store: StoreOf<CounterFeature>

    var body: some View {
        VStack(spacing: 16) {
            Text("\(store.count)")
                .font(.largeTitle)
                .monospacedDigit()

            HStack(spacing: 16) {
                Button("−") { store.send(.decrementButtonTapped) }
                Button("+") { store.send(.incrementButtonTapped) }
            }
            .font(.title)
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    ContentView(
        store: Store(initialState: CounterFeature.State()) {
            CounterFeature()
        }
    )
}
