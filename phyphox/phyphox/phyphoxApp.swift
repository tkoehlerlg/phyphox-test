//
//  phyphoxApp.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI

@main
struct phyphoxApp: App {
    @StateObject private var model: AppModel

    init() {
        self._model = StateObject(wrappedValue: AppModel(services: Services()))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(services: model.services)
        }
    }
}
