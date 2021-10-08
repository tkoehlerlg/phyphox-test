//
//  ContentView.swift
//  phyphox-watch WatchKit Extension
//
//  Created by Torben Köhler on 27.09.21.
//

import SwiftUI
import NearbyInteraction

struct ContentView: View {
    @ObservedObject var model: ContentViewModel

    init(services: Services) {
        self._model = ObservedObject(
            wrappedValue: ContentViewModel(services: services)
        )
    }

    var body: some View {
        ZStack {
            (model.iPhoneIsConnected ? Color.green.opacity(0.5) : Color.red)
                .ignoresSafeArea()
            Text(text)
                .multilineTextAlignment(.center)
                .padding()
        }
    }

    var text: String {
        if !model.iPhoneIsConnected {
            return "Öffne die Phyphox-App auf deinem iPhone."
        } else {
            if !NearbyService.nearbySessionIsAvailable {
                return "NearbyInteraction wird nicht unterstüzt."
            } else {
                if !model.sessionStarted {
                    return "Tippe auf deinen iPhone auf \"Apple Watch\" um eine verbindung herzustellen."
                } else {
                    return "Verbunden mit iPhone"
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(services: Services())
    }
}
