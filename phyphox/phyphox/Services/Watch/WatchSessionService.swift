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
    @Published var connectedToCounterpart: Bool = false
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
                self?.nearbyService.addDeviceToSession(identifier: "Apple Watch", data: encryptedToken, with: passthroughSubject)
            }
            .store(in: &self.cancellable)
        return passthroughSubject
    }
    #endif

    // MARK: FeatureRequest
    func requestFeatureOnCounterpart(_ feature: WCFeatureRequest) -> PassthroughSubject<Bool, Error> {
        let passthroughSubject: PassthroughSubject<Bool, Error> = .init()
        sendMessageWithResponse(["FeatureRequest" : feature.rawValue])
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
        connectedToCounterpart = true
        objectWillChange.send()
    }

    // MARK: Responses
    // - ask Watch
    // - Feature Resquests
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(message)
        #if os(watchOS)
        // ask watch to reply
        askWatchToReplyToMessage(message, replyHandler: replyHandler)
        #endif
        // Feature Requests
        if let request = message["FeatureRequest"] as? String {
            switch WCFeatureRequest(rawValue: request) {
            case .nearbySession:
                replyHandler(["FeatureReply": NISession.isSupported])
            case .none: break
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        connectedToCounterpart = false
        objectWillChange.send()
    }

    func sessionDidDeactivate(_ session: WCSession) {
        connectedToCounterpart = false
        objectWillChange.send()
    }
    #endif
}
