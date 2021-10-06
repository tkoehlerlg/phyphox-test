//
//  Services.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation

extension Services {
    init() {
        let nearbyService = NearbyService()
        self.init(
            watchSession: WatchSessionService(nearbyService: nearbyService),
            sensorsService: SensorsService(),
            nearbyService: nearbyService
        )
    }
}
