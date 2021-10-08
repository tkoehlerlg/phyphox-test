//
//  WatchSessionService.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Combine
import WatchConnectivity
import NearbyInteraction

// MARK: Nearby Service
extension WatchSessionService {
    func receivedNearbyWCInvitation(data: Data, replyHandler: @escaping ([String : Any]) -> Void) {
        nearbyService.iPhoneConnection = NearbyObject(
            identifier: "My iPhone",
            encryptedToken: data,
            updateHandler: .init()
        )

        // send token to iPhone
        guard let encryptedToken = nearbyService.discoveryTokenEncrypted else { return }
        replyHandler(["NearbySessionResponse": encryptedToken])
    }
}
