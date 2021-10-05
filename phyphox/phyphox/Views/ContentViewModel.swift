//
//  ContentViewModel.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI
import Combine
import NearbyInteraction

class ContentViewModel: ObservableObject {
    @Published private var services: Services
    var cancellable = Set<AnyCancellable>()

    @Published var appleWatchIsConnected: Bool

    /// in meters
    @Published var distance: Float = 0
    @Published var direction: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)

    init(services: Services) {
        self.services = services
        appleWatchIsConnected = services.watchSession.watchIsConnected
        services.watchSession.$watchIsConnected.assign(to: &$appleWatchIsConnected)
    }

    @Published var test1Message: String?
    func launchTest1() {
        services.watchSession.sendMessageWithResponse(["Test1" : "Some Message"])
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .finished:
                    print("Test 1 - respondet")
                case let .failure(error):
                    print(error)
                }
            } receiveValue: { [weak self] response in
                self?.test1Message = response["Test1"] as? String
            }
            .store(in: &cancellable)
    }

    @Published var test2Message: String?
    func launchTest2() {
        #if !targetEnvironment(simulator)
        guard let tokenEncryped = services.nearbyService.discoveryTokenEncrypted else {
            print("Encryption error in test")
            return
        }
        services.watchSession.sendMessageWithResponse(
            ["NearbySessionInvitation-Test" : tokenEncryped]
        )
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .finished:
                    print("Test 2 - respondet")
                case let .failure(error):
                    print(error)
                }
            } receiveValue: { [weak self] response in
                self?.test2Message = "Response: Data..."
                if let data = response["NearbySessionResponse"] as? Data {
                    self?.test2Message = "Response: \((self?.services.nearbyService.decryptDiscoveryToken(data)?.description) ?? "Cant Decrypeted")"
                }
            }
            .store(in: &cancellable)
        #endif
    }

    func connect() {
        services.nearbyService.startNearbySession()
        #if !targetEnvironment(simulator)
        guard let handler = services.watchSession.startNearbyInteractionSessionWithWatch() else { return }
        handler
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response {
                case .finished:
                    print("Connection to watch finished")
                case let .failure(error):
                    print(error)
                }
            } receiveValue: { response in
                guard let distance = response.distance, let direction = response.direction else { return }
                self.distance = distance
                self.direction = (
                    x: direction.x,
                    y: direction.y,
                    z: direction.z
                )
            }
            .store(in: &cancellable)
        #endif
    }
}
