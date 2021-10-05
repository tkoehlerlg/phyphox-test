//
//  NearbyService.swift
//  phyphox
//
//  Created by Torben Köhler on 29.09.21.
//

import Combine
import NearbyInteraction

class NearbyService: NSObject, ObservableObject {
    private var nearbySession: NISession?
    static var nearbySessionsAvailable: Bool {
        return NISession.isSupported
    }

    // MARK: own Data
    var discoveryTokenEncrypted: Data? {
        guard let discoveryToken = nearbySession?.discoveryToken else { return nil }
        return encryptDiscoveryToken(discoveryToken)
    }
    var currentSessions: [
        Data: PassthroughSubject<NINearbyObject, Errors>
    ] = [:]
    private var cancellable = Set<AnyCancellable>()

    // MARK: Errors
    enum Errors: String, Error {
        case noDiscoveryToken, objectCantBeFoundLonger, sessionClosed, tokenCanNotEncrypted
    }

    // MARK: Session start
    override init() {
        super.init()
        self.startNearbySession()
    }
    private func startNearbySession() {
        if NearbyService.nearbySessionsAvailable {
            self.nearbySession = NISession()
            nearbySession?.delegate = self
        }
    }

    func addDeviceToSession(
        data: Data,
        with passthroughSubject: PassthroughSubject<NINearbyObject, Errors> = .init()
    ) {
        guard let discoveryToken = decryptDiscoveryToken(data) else { return }
        let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
        self.nearbySession?.run(config)
        currentSessions[data] = passthroughSubject
    }

    private func addDeviceToSessionWithResponse(
        data: Data,
        with passthroughSubject: PassthroughSubject<NINearbyObject, Errors> = .init()
    ) -> PassthroughSubject<NINearbyObject, Errors>? {
        guard let discoveryToken = decryptDiscoveryToken(data) else { return nil }
        let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
        self.nearbySession?.run(config)
        currentSessions[data] = passthroughSubject
        return passthroughSubject
    }
}

// MARK: Delegate
extension NearbyService: NISessionDelegate {
    // updates the distance and direction
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        nearbyObjects.forEach { object in
            guard let encryptedDiscoveryToken = encryptDiscoveryToken(object.discoveryToken) else { return }
            currentSessions[encryptedDiscoveryToken]?.send(object)
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        self.startNearbySession()
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        nearbyObjects.forEach { object in
            guard let encryptedDiscoveryToken = encryptDiscoveryToken(object.discoveryToken) else { return }
            currentSessions[encryptedDiscoveryToken]?.send(completion: .failure(.sessionClosed))
            currentSessions.removeValue(forKey: encryptedDiscoveryToken)
        }

        if nearbyObjects.isEmpty {
            session.invalidate()
            self.startNearbySession()
        }
    }

    func sessionSuspensionEnded(_ session: NISession) {
        currentSessions.forEach { session in
            guard let decryptedDiscoveryToken = decryptDiscoveryToken(session.key) else { return }
            let config = NINearbyPeerConfiguration(peerToken: decryptedDiscoveryToken)
            self.nearbySession?.run(config)
        }
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

