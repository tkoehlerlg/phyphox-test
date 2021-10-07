//
//  ContentView.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var model: ContentViewModel

    init(services: Services) {
        self._model = ObservedObject(
            wrappedValue: ContentViewModel(services: services)
        )
    }

    var body: some View {
        ZStack {
            VStack {
                Group {
                    Text("Test 3 - Session completed")
                        .bold()
                    Text("Distance: \(String(format: "%.3f", model.distance))m")
                    Text("Direction: x: \(model.direction.x), y: \(model.direction.y), z: \(model.direction.z)")
                    Button {
                        model.connectToWatch()
                    } label: {
                        Text("Start Session")
                    }
                }
            }
            Color(model.appleWatchIsConnected ? .green : .red)
                .ignoresSafeArea()
                .frame(height: 0)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(services: Services())
    }
}
