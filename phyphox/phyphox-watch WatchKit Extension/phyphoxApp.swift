//
//  phyphoxApp.swift
//  phyphox-watch WatchKit Extension
//
//  Created by Torben Köhler on 27.09.21.
//

import SwiftUI

@main
struct phyphoxApp: App {
    @StateObject var model: AppModel

    init() {
        self._model = StateObject(wrappedValue: AppModel(services: Services()))
    }

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(services: model.services)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
