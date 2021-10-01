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
                Text("Distance: \(String(format: "%.3f", model.distance))m")
                Text("Direction: x: \(model.direction.x), y: \(model.direction.y), z: \(model.direction.z)")
                Button {
                    model.connect()
                } label: {
                    Text("Pair with Watch")
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

//        VStack {
//            Text(model.label)
//            Button {
//                model.sendMessage("What ever it takes")
//            } label: {
//                Text("Start")
//            }
//            Color(model.watchServices.watchIsConnected ? .green : .red)
//                .ignoresSafeArea()
//                .frame(height: 50)
//                .ignoresSafeArea()
//            Line(data: model.xDataArray, frame: .constant(CGRect(x: 0, y: 0, width: 400, height: 200)))
//            .frame(width: 400, height: 200, alignment: .center)
//            Text("X: \(model.currentXData)")
//            Line(data: model.yDataArray, frame: .constant(CGRect(x: 0, y: 0, width: 400, height: 200)))
//            .frame(width: 400, height: 200, alignment: .center)
//            Text("Y: \(model.currentYData)")
//            Line(data: model.zDataArray, frame: .constant(CGRect(x: 0, y: 0, width: 400, height: 200)))
//            .frame(width: 400, height: 200, alignment: .center)
//            Text("Z: \(model.currentZData)")
//        }
