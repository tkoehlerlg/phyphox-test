//
//  WatchSessionService.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Combine
import WatchConnectivity
import NearbyInteraction

final class WatchSessionService: NSObject, ObservableObject {
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
    func startNearbyInteractionSessionWithWatch() -> PassthroughSubject<NINearbyObject, NearbyObjectError>? {
        let passthroughSubject = PassthroughSubject<NINearbyObject, NearbyObjectError>()
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
                self?.nearbyService.addDeviceToSession(identifier: "My Watch", data: encryptedToken, with: passthroughSubject)
            }
            .store(in: &self.cancellable)
        return passthroughSubject
    }
    #endif

    // MARK: FeatureRequest
    func requestFeatureOnCounterpart(_ feature: WCFeatureRequest) -> PassthroughSubject<Bool, Error> {
        let passthroughSubject: PassthroughSubject<Bool, Error> = .init()
        sendMessageWithResponse(["FeatureRequest" : feature])
            .receive(on: DispatchQueue.main)
            .sink { response in
                passthroughSubject.send(completion: response)
            } receiveValue: { response in
                guard let featureReply = response["FeatureReply"] as? Bool else { return }
                passthroughSubject.send(featureReply)
            }
            .store(in: &cancellable)
        return passthroughSubject
    }
}

extension WatchSessionService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        watchIsConnected = true
        objectWillChange.send()
    }

    // MARK: Responses
    // - NearbyInteraction
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received Message: \(message)")
        #if os(watchOS)
        // Reply to NearbySession
        if let discoveryToken = message["NearbySessionInvitation"] as? Data {
            receivedNearbyWCInvitation(data: discoveryToken, replyHandler: replyHandler)
        }
        #elseif os(iOS)
        // ios responsesd
        #endif
        //both
        if let request = message["FeatureRequest"] as? WCFeatureRequest {
            switch request {
            case .nearbySession:
                replyHandler(["FeatureReply": NISession.isSupported])
            }
        }
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
    func receivedNearbyWCInvitation(data: Data, replyHandler: @escaping ([String : Any]) -> Void) {
        print("connect to watch")
        nearbyService.addDeviceToSession(identifier: "My iPhone", data: data)
        receiveMessages.send(nearbyService.decryptDiscoveryToken(data)?.description ?? "Cant decrypt token")

        // send back
        guard let encryptedToken = nearbyService.discoveryTokenEncrypted else { return }
        replyHandler(["NearbySessionResponse": encryptedToken])
    }
}
#endif
