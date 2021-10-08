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
    static var nearbySessionsAvailable: Bool {
        return NISession.isSupported
    }

    // MARK: own Data
    var discoveryTokenEncrypted: Data? {
        guard let discoveryToken = nearbySession?.discoveryToken else { return nil }
        return encryptDiscoveryToken(discoveryToken)
    }
    private(set) var currentNearbyObjects: [NearbyObject] = []
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

    // MARK: Add Device
    func addDeviceToSession(
        identifier: String,
        data encrypetedToken: Data,
        with passthroughSubject: PassthroughSubject<NINearbyObject, NearbyObjectError> = .init()
    ) {
        var deviceName = identifier
        if !currentNearbyObjects.contains(where: { $0.encryptedToken == encrypetedToken }) {
            if !currentNearbyObjects.contains(where: { $0.identifier == identifier }) {
                deviceName += "_"
            }
            guard let discoveryToken = decryptDiscoveryToken(encrypetedToken) else { return }
            let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
            self.nearbySession?.run(config)
            currentNearbyObjects.append(
                NearbyObject(
                    identifier: deviceName,
                    encryptedToken: encrypetedToken,
                    updateHandler: passthroughSubject
                )
            )
        }
    }
    private func addDeviceToSessionWithResponse(
        identifier: String,
        data encrypetedToken: Data,
        with passthroughSubject: PassthroughSubject<NINearbyObject, NearbyObjectError> = .init()
    ) -> PassthroughSubject<NINearbyObject, NearbyObjectError>? {
        addDeviceToSession(identifier: identifier, data: encrypetedToken, with: passthroughSubject)
        return passthroughSubject
    }
}

// MARK: Delegate
extension NearbyService: NISessionDelegate {
    // updates the distance and direction
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        nearbyObjects.forEach { object in
            guard let encryptedDiscoveryToken = encryptDiscoveryToken(object.discoveryToken) else { return }
            currentNearbyObjects.forEach({
                if $0.encryptedToken == encryptedDiscoveryToken {
                    $0.updateHandler.send(object)
                }
            })
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        self.startNearbySession()
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        nearbyObjects.forEach { object in
            guard let encryptedDiscoveryToken = encryptDiscoveryToken(object.discoveryToken) else { return }
            currentNearbyObjects.forEach({
                if $0.encryptedToken == encryptedDiscoveryToken {
                    $0.updateHandler.send(completion: .failure(.sessionClosed))
                }
            })
            currentNearbyObjects.removeAll(where: { $0.encryptedToken == encryptedDiscoveryToken })
        }

        if nearbyObjects.isEmpty {
            session.invalidate()
            self.startNearbySession()
        }
    }

    func sessionSuspensionEnded(_ session: NISession) {
        currentNearbyObjects.forEach {
            guard let decryptedDiscoveryToken = decryptDiscoveryToken($0.encryptedToken) else { return }
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

