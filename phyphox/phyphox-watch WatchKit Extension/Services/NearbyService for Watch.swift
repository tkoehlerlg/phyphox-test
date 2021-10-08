//
//  NearbyService.swift
//  phyphox
//
//  Created by Torben Köhler on 29.09.21.
//

import Combine
import UIKit
import NearbyInteraction

final class NearbyService: NSObject, ObservableObject {
    private var nearbySession: NISession?
    static var nearbySessionIsAvailable: Bool {
        return NISession.isSupported
    }

    // MARK: own Data
    var discoveryTokenEncrypted: Data? {
        guard let discoveryToken = nearbySession?.discoveryToken else { return nil }
        return encryptDiscoveryToken(discoveryToken)
    }
    @Published var iPhoneConnection: NearbyObject?
    private var cancellable = Set<AnyCancellable>()

    // MARK: Session start
    override init() {
        super.init()
        self.startNearbySession()
    }

    deinit {
        stopNearbySession()
    }

    func startNearbySession() {
        guard NISession.isSupported else {
            print("This device doesn't support Nearby Interaction.")
            return
        }
        self.nearbySession = NISession()
        nearbySession?.delegate = self
        nearbySession?.delegateQueue = DispatchQueue.main
    }

    func stopNearbySession() {
        nearbySession?.invalidate()
        nearbySession = nil
    }
}

// MARK: Delegate
extension NearbyService: NISessionDelegate {
    // updates the distance and direction
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let iPhone = nearbyObjects.first else { return }
        iPhoneConnection?.updateHandler.send(iPhone)
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        self.startNearbySession()
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        iPhoneConnection?.updateHandler.send(completion: .failure(.sessionClosed))
        session.invalidate()
        self.startNearbySession()
    }

    func sessionSuspensionEnded(_ session: NISession) {
        guard let encryptedToken = iPhoneConnection?.encryptedToken else { return }
        guard let decryptedDiscoveryToken = decryptDiscoveryToken(encryptedToken) else { return }
        let config = NINearbyPeerConfiguration(peerToken: decryptedDiscoveryToken)
        self.nearbySession?.run(config)
    }

    func sessionWasSuspended(_ session: NISession) {
        print("Session stopped")
    }
}

// MARK: Key Cription
extension NearbyService {
    func encryptDiscoveryToken(_ token: NIDiscoveryToken) -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    func decryptDiscoveryToken(_ data: Data) -> NIDiscoveryToken? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data)
    }
}
