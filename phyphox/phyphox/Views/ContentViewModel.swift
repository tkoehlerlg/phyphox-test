//
//  ContentViewModel.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI
import Combine

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

    func connect() {
        services.nearbyService.startWatchSession(services.watchSession)
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
    }
}
