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
    #if !targetEnvironment(simulator)
    private let nearbyService: NearbyService
    #endif
    var isSupported: Bool {
        WCSession.isSupported()
    }
    @Published var watchIsConnected: Bool = false

    private(set) var receiveMessages: PassthroughSubject<String, Never> = .init()

    #if !targetEnvironment(simulator)
    init(nearbyService: NearbyService) {
        self.session = WCSession.default
        self.nearbyService = nearbyService
        super.init()

        session.delegate = self
        session.activate()
    }
    #else
    override init() {
        self.session = WCSession.default
        super.init()

        session.delegate = self
        session.activate()
    }
    #endif

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
        #if os(watchOS)
        #if !targetEnvironment(simulator)
        if let discoveryToken = message["NearbySessionInvitation"] as? NIDiscoveryToken {
            nearbyService.acceptSessionInvitation(with: discoveryToken)
            receiveMessages.send("Start Session")
        }
        #endif
        if message["Test1"] != nil {
            receiveMessages.send("Test 1")
            replyHandler(["Test1" : "Some watch-message"])
        }
        #endif
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
