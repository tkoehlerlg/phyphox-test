//
//  NearbyService.swift
//  phyphox
//
//  Created by Torben Köhler on 29.09.21.
//

import Combine
import NearbyInteraction

class NearbyService: NSObject, ObservableObject {
    private var session: NISession
    var isSupported: Bool {
        NISession.isSupported
    }
    private(set) var currentSessions: [
        NIDiscoveryToken: PassthroughSubject<NINearbyObject, Errors>
    ] = [:]

    enum Errors: String, Error {
        case noDiscoveryToken, objectCantBeFoundLonger, sessionClosed
    }

    private var cancellable = Set<AnyCancellable>()

    override init() {
        self.session = NISession()
        super.init()

        guard NISession.isSupported else {
            print("This device doesn't support Nearby Interaction.")
            return
        }
        session.delegate = self
    }

    deinit {
        session.invalidate()
    }

    private func startSession(with token: NIDiscoveryToken) {
        let config = NINearbyPeerConfiguration(peerToken: token)
        session.run(config)
    }

    func acceptSessionInvitationWithResponse(with token: NIDiscoveryToken) -> PassthroughSubject<NINearbyObject, Errors> {
        let passthroughSubject: PassthroughSubject<NINearbyObject, Errors> = .init()
        self.currentSessions[token] = passthroughSubject
        self.startSession(with: token)
        return passthroughSubject
    }

    func acceptSessionInvitation(with token: NIDiscoveryToken) {
        self.currentSessions[token] = .init()
        self.startSession(with: token)
    }

    #if os(iOS)
    func startWatchSession(_ sessionService: WCService) -> PassthroughSubject<NINearbyObject, Errors> {
        let passthroughSubject: PassthroughSubject<NINearbyObject, Errors> = .init()
        if sessionService.watchIsConnected {
            if let discoveryToken = session.discoveryToken {
                sessionService.sendMessageWithResponse(
                    ["NearbySessionInvitation": "\(discoveryToken)"]
                )
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { response in
                        switch response {
                        case .finished:
                            print("Watch connected")
                        case let .failure(error):
                            print("Watch not connected: \(error)")
                        }
                    }, receiveValue: { response in
                        guard
                            let sessionResponse = response["NearbySessionResponse"],
                            let token = sessionResponse as? NIDiscoveryToken
                        else { return }
                        self.currentSessions[token] = passthroughSubject
                        self.startSession(with: token)
                    })
                    .store(in: &cancellable)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    passthroughSubject.send(completion: .failure(.noDiscoveryToken))
                }
            }
        }
        return passthroughSubject
    }
    #endif
}

extension NearbyService: NISessionDelegate {
    // updates the distance and direction
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        nearbyObjects.forEach { object in
            self.currentSessions.forEach { session in
                if object.discoveryToken == session.key {
                    session.value.send(object)
                }
            }
        }
    }

    // device can't be found longer
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        nearbyObjects.forEach { object in
            self.currentSessions.forEach { session in
                if object.discoveryToken == session.key {
                    session.value.send(completion: .failure(.objectCantBeFoundLonger))
                }
            }
        }
    }

    // Session closed
    func sessionWasSuspended(_ session: NISession) {
        self.currentSessions.forEach { session in
            session.value.send(completion: .failure(.sessionClosed))
        }
    }
}
