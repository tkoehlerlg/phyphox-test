//
//  WatchSessionService.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Combine
import WatchConnectivity
import NearbyInteraction

class WatchSessionService: NSObject, ObservableObject {
    private let session: WCSession
    internal let nearbyService: NearbyService
    var isSupported: Bool {
        WCSession.isSupported()
    }
    @Published var watchIsConnected: Bool = false

    private(set) var receiveMessages: PassthroughSubject<String, Never> = .init()
    private var cancellable = Set<AnyCancellable>()

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
    // MARK: NearbyInteraction
    func startNearbyInteractionSessionWithWatch() -> PassthroughSubject<NINearbyObject, NearbyService.Errors>? {
        let passthroughSubject = PassthroughSubject<NINearbyObject, NearbyService.Errors>()
        guard let discoveryTokenEncrypted = nearbyService.discoveryTokenEncrypted else { return nil }
        self.sendMessageWithResponse(["NearbySessionInvitation" : discoveryTokenEncrypted])
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .finished:
                    print("NearbySession response received")
                case let .failure(error):
                    print("NearbySession error: \(error)")
                }
            } receiveValue: { [weak self] response in
                guard let encryptedToken = response["NearbySessionResponse"] as? Data else { return }
                self?.nearbyService.addDeviceToSession(data: encryptedToken, with: passthroughSubject)
            }
            .store(in: &self.cancellable)
        return passthroughSubject
    }
    #endif
}

extension WatchSessionService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        watchIsConnected = true
        objectWillChange.send()
    }

    // MARK: Responses
    // - NearbyInteraction
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        #if os(watchOS)
        // Reply to NearbySession
        if let discoveryToken = message["NearbySessionInvitation"] as? Data {
            receivedNearbyInvitation(data: discoveryToken, replyHandler: replyHandler)
        }
        // Test Session
        if (message["NearbySessionInvitation-Test"] as? Data) != nil {
            receiveMessages.send("Test Session")

            // send back
            guard let encryptedToken = nearbyService.discoveryTokenEncrypted else { return }
            replyHandler(["NearbySessionResponse": encryptedToken])
        }
        // Test 1
        if message["Test1"] != nil {
            receiveMessages.send("Test 1")
            replyHandler(["Test1" : "Some watch-message"])
        }
        #elseif os(iOS)
        // ios responsesd
        #endif
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        self.receiveMessages.send(applicationContext.first?.value as? String ?? "")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        watchIsConnected = false
        objectWillChange.send()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        watchIsConnected = false
        objectWillChange.send()
    }
    #endif
}

#if os(watchOS)
// MARK: Nearby Service
extension WatchSessionService: NearbyWatch {
    func receivedNearbyInvitation(data: Data, replyHandler: @escaping ([String : Any]) -> Void) {
        nearbyService.addDeviceToSession(data: data)
        receiveMessages.send(nearbyService.decryptDiscoveryToken(data)?.description ?? "Cant decrypt token")

        // send back
        guard let encryptedToken = nearbyService.discoveryTokenEncrypted else { return }
        replyHandler(["NearbySessionResponse": encryptedToken])
    }
}
#endif
