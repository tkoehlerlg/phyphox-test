//
//  WatchSessionService.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Combine
import WatchConnectivity
import NearbyInteraction

class WCService: NSObject, ObservableObject {
    private let session: WCSession
    private let nearbyService: NearbyService
    var isSupported: Bool {
        WCSession.isSupported()
    }
    @Published var watchIsConnected: Bool = false

    private(set) var receiveMessages: PassthroughSubject<String, Never> = .init()

    init(nearbyService: NearbyService) {
        self.session = WCSession.default
        self.nearbyService = nearbyService
        super.init()

        session.delegate = self
        session.activate()
    }

    func sendMessageWithResponse(_ message: [String: Any]) -> AnyPublisher<[String: Any], Error> {
        let passtroughtSubject: PassthroughSubject<[String: Any], Error> = .init()
        session.sendMessage(message) { reply in
            passtroughtSubject.send(reply)
        } errorHandler: { error in
            passtroughtSubject.send(completion: .failure(error))
        }
        return passtroughtSubject.eraseToAnyPublisher()
    }

    func sendMessage(_ message: [String: Any]) {
        session.sendMessage(message) { _ in
        } errorHandler: { _ in }
    }

    #if os(iOS)
    func transfer(_ message: [String: Any]) {
        session.transferCurrentComplicationUserInfo(message)
    }
    #endif
}

extension WCService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        watchIsConnected = true
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let discoveryToken = message["NearbySessionInvitation"] as? NIDiscoveryToken {
            nearbyService.acceptSessionInvitation(with: discoveryToken)
            receiveMessages.send("Start Session")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        self.receiveMessages.send(applicationContext.first?.value as? String ?? "")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        watchIsConnected = false
    }

    func sessionDidDeactivate(_ session: WCSession) {
        watchIsConnected = false
    }
    #endif
}
