//
//  Services.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation

extension Services {
    init() {
        #if !targetEnvironment(simulator)
        let nearbyService = NearbyService()
        self.init(
            watchSession: WCService(nearbyService: nearbyService),
            sensorsService: SensorsService(),
            nearbyService: nearbyService
        )
        #else
        self.init(
            watchSession: WCService(),
            sensorsService: SensorsService()
        )
        #endif
    }
}
