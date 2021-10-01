//
//  AccelerometerSS.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation
import Combine
import CoreMotion

class AccelerometerSS: ObservableObject {
    private var manager: CMMotionManager
    private let updateTimer: Publishers.Autoconnect<Timer.TimerPublisher>
    private var cancellables: Set<AnyCancellable> = []

    @Published var currentAcceleration: (timestamp: Date, acceleration: CMAcceleration)?

    var accelerometerUpdateInterval: TimeInterval {
        manager.accelerometerUpdateInterval
    }

    init(manager: CMMotionManager, refreshRate: Double = 0.01) {
        self.manager = manager
        self.updateTimer = Timer.publish(every: refreshRate, on: .main, in: .common).autoconnect()
        updateTimer
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                guard let accelerometerData = manager.accelerometerData else { return }
                self.currentAcceleration = (Date(), accelerometerData.acceleration)
            }
            .store(in: &cancellables)
    }

    deinit {
        manager.stopAccelerometerUpdates()
    }

    func stopRecording() {
        manager.stopAccelerometerUpdates()
    }

    func startRecording() {
        manager.startAccelerometerUpdates()
    }
}
