//
//  WatchSessionService+WatchResponse.swift
//  phyphox-watch WatchKit Extension
//
//  Created by Torben Köhler on 08.10.21.
//

import Foundation

extension WatchSessionService {
    func askWatchToReplyToMessage(_ message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Reply to NearbySession
        if let discoveryToken = message["NearbySessionInvitation"] as? Data {
            receivedNearbyWCInvitation(data: discoveryToken, replyHandler: replyHandler)
        }
    }
}
