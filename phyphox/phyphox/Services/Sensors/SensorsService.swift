//
//  SensorsService.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation
import CoreMotion

class SensorsService: ObservableObject {
    private let manager: CMMotionManager
    @Published var accelerometer: AccelerometerSS

    init() {
        manager = CMMotionManager()
        accelerometer = AccelerometerSS(manager: manager)
        if manager.isDeviceMotionAvailable {
//            print(manager.isGyroAvailable)
//            print(manager.isMagnetometerAvailable)
//            print(manager.isAccelerometerAvailable)
        }
    }
}
