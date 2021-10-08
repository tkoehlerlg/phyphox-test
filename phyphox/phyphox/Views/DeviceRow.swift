//
//  DeviceRow.swift
//  phyphox
//
//  Created by Torben Köhler on 07.10.21.
//

import SwiftUI

struct DeviceRow: View {
    @ObservedObject var model: DeviceRowModel
    @State var isAnimating = false

    init(
        deviceName: String,
        services: Services,
        deviceType: DeviceRowModel.DeviceType
    ) {
        self._model = ObservedObject(
            wrappedValue: DeviceRowModel(
                deviceName: deviceName,
                services: services,
                deviceType: deviceType
            )
        )
    }

    init(model: DeviceRowModel) {
        self._model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        Button {
            model.startConnection()
        } label: {
            HStack {
                Text(model.deviceName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                Text(distanceText)
                    .fontWeight(.medium)
                    .padding()
            }
            .foregroundColor(.primary)
            .frame(height: 50)
            .background(background)
            .cornerRadius(15)
        }

    }

    var distanceText: String {
        switch model.connectionState {
        case .connected:
            return model.distance ?? "waiting for Data"
        case .error:
            return "Error"
        case .depending:
            return "connecting"
        case .listed:
            return ""
        }
    }

    var background: some View {
        ZStack {
            switch model.connectionState {
            case .connected:
                Color.green
            case .error:
                Color.red
            case .depending:
                Color.orange.opacity(self.isAnimating ? 0.9: 0.6)
                    .animation(.easeInOut(duration: 1).repeatForever())
                    .onAppear {
                        self.isAnimating = true
                    }
            case .listed:
                Color.gray.opacity(0.2)
            }
        }
    }
}

struct DeviceRow_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRow(
            deviceName: "Apple Watch",
            services: Services(),
            deviceType: .watch
        )
    }
}
