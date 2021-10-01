//
//  ContentViewModel.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published private(set) var accelerometerService: AccelerometerSS
    @Published private(set) var watchServices: WCService

    var currentXData: Double { xDataArray.last ?? 0.0 }
    @Published var xDataArray: [Double] = []

    var cancellable = Set<AnyCancellable>()

    @Published var label: String = "Nothing"
    var lastTimeStamp: Date?

    init(services: Services) {
        self.accelerometerService = services.sensorsService.accelerometer
        self.watchServices = services.watchSession
        self.accelerometerService.startRecording()

        self.accelerometerService.$currentAcceleration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let acceleration = response?.acceleration else { return }
                self?.xDataArray.append(acceleration.x)
                self?.watchServices.sendMessage([
                    "x": acceleration.x,
                    "y": acceleration.y,
                    "z": acceleration.z
                ])
                if let lastTimeStamp = self?.lastTimeStamp {
                    let diffComponents = Calendar.current.dateComponents([.second], from: lastTimeStamp, to: Date())
                    self?.label = "\(diffComponents.second ?? 0)"
                }
                self?.lastTimeStamp = response?.timestamp
            }
            .store(in: &cancellable)
    }
}
