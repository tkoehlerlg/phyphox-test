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
                    Text("Test 1 - Watch Message")
                        .bold()
                    Text("\(model.test1Message ?? "(Answer)")")
                    Button {
                        model.launchTest1()
                    } label: {
                        Text("Send Message")
                    }
                }
                #if !targetEnvironment(simulator)
                Spacer()
                    .frame(height: 50)
                Group {
                        Text("Test 2 - Session Key")
                            .bold()
                        Text("\(model.test2Message ?? "(Answer)")")
                        Button {
                            model.launchTest2()
                        } label: {
                            Text("Send Message")
                        }
                    }
                    Spacer()
                        .frame(height: 50)
                Group {
                    Text("Test 3 - Session completed")
                        .bold()
                    Text("Distance: \(String(format: "%.3f", model.distance))m")
                    Text("Direction: x: \(model.direction.x), y: \(model.direction.y), z: \(model.direction.z)")
                    Button {
                        model.connect()
                    } label: {
                        Text("Start Session")
                    }
                }
                #endif
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
