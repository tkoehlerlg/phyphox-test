//
//  ContentView.swift
//  phyphox-watch WatchKit Extension
//
//  Created by Torben Köhler on 27.09.21.
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
        VStack {
            Text("hi, jens")
//            Text("**Version 1.0**")
//            Line(data: model.xDataArray, frame: .constant(CGRect(x: 0, y: 0, width: 200, height: 80)))
//            Text("**X**: \(String(format: "%.2f", model.currentXData))")
//            Text("**UpdateTI**: \(String(format: "%.3f", model.accelerometerService.accelerometerUpdateInterval))")
//            HStack {
//                Button {
//                    model.accelerometerService.startRecording()
//                } label: {
//                    Label("Start", systemImage: "paperplane")
//                        .foregroundColor(model.watchServices.watchIsConnected ? .green : .red)
//                }
//            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(services: Services())
    }
}
