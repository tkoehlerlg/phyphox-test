//
//  NearbyService.swift
//  phyphox
//
//  Created by Torben Köhler on 29.09.21.
//

import Combine
import NearbyInteraction

#if !targetEnvironment(simulator)
class NearbyService: NSObject, ObservableObject {
    private var session: NISession
    var isSupported: Bool {
        NISession.isSupported
    }
    var discoveryTokenEncrypted: Data? {
        guard let discoveryToken = session.discoveryToken else { return nil }
        return NearbyService.encryptDiscoveryToken(discoveryToken)
    }
    private(set) var currentSessions: [
        Data: PassthroughSubject<NINearbyObject, Errors>
    ] = [:]

    enum Errors: String, Error {
        case noDiscoveryToken, objectCantBeFoundLonger, sessionClosed, tokenCanNotEncrypted
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
        if let encryptToken = NearbyService.encryptDiscoveryToken(token) {
            self.currentSessions[encryptToken] = passthroughSubject
            self.startSession(with: token)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                passthroughSubject.send(completion: .failure(.tokenCanNotEncrypted))
            }
        }
        return passthroughSubject
    }

    func acceptSessionInvitation(with token: NIDiscoveryToken) {
        if let encryptToken = NearbyService.encryptDiscoveryToken(token) {
            self.currentSessions[encryptToken] = .init()
            self.startSession(with: token)
        }
    }

    func acceptSessionInvitation(with token: Data) {
        if let decryptToken = NearbyService.decryptDiscoveryToken(token) {
            self.currentSessions[token] = .init()
            self.startSession(with: decryptToken)
        }
    }

    #if os(iOS)
    func startWatchSession(_ sessionService: WCService) -> PassthroughSubject<NINearbyObject, Errors> {
        let passthroughSubject: PassthroughSubject<NINearbyObject, Errors> = .init()
        if sessionService.watchIsConnected {
            if let discoveryToken = session.discoveryToken {
                sessionService.sendMessageWithResponse(
                    ["NearbySessionInvitation": discoveryToken]
                )
                    .receive(on: DispatchQueue.main)
                    .sink(receiveCompletion: { response in
                        switch response {
                        case .finished:
                            print("Watch connected")
                        case let .failure(error):
                            print("Watch not connected: \(error)")
                        }
                    }, receiveValue: { [weak self] response in
                        guard
                            let sessionResponse = response["NearbySessionResponse"],
                            let token = sessionResponse as? NIDiscoveryToken
                        else { return }
                        self?.acceptSessionInvitation(with: token)
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
                guard let discoveryToken = NearbyService.decryptDiscoveryToken(session.key) else { return }
                if object.discoveryToken == discoveryToken {
                    session.value.send(object)
                }
            }
        }
    }

    // device can't be found longer
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        nearbyObjects.forEach { object in
            self.currentSessions.forEach { session in
                guard let discoveryToken = NearbyService.decryptDiscoveryToken(session.key) else { return }
                if object.discoveryToken == discoveryToken {
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

// MARK: Key Cription
extension NearbyService {
    static func encryptDiscoveryToken(_ token: NIDiscoveryToken) -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }

    static func decryptDiscoveryToken(_ data: Data) -> NIDiscoveryToken? {
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data)
    }
}
#endif
