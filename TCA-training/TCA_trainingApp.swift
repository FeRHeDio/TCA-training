//
//  TCA_trainingApp.swift
//  TCA-training
//
//  Created by Fernando Putallaz on 17/07/2026.
//

import ComposableArchitecture
import SwiftUI

@main
struct TCA_trainingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(initialState: CounterFeature.State()) {
                    CounterFeature()
                }
            )
        }
    }
}
