//
//  Services.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation

struct Services {
    let watchSession: WCService
    let sensorsService: SensorsService
    let nearbyService: NearbyService

    init(
        watchSession: WCService,
        sensorsService: SensorsService,
        nearbyService: NearbyService
    ) {
        self.watchSession = watchSession
        self.sensorsService = sensorsService
        self.nearbyService = nearbyService
    }
}
