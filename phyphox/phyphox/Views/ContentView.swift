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
        NavigationView {
            ZStack {
                if !model.devices.isEmpty {
                    ScrollView {
                        ForEach(model.devices, id: \.deviceName) { device in
                            DeviceRow(model: device)
                                .padding(.horizontal)
                                .padding(.bottom, 5)
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("Devices")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(services: Services())
    }
}
