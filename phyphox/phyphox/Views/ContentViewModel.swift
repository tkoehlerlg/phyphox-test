//
//  ContentViewModel.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    var cancellable = Set<AnyCancellable>()

    @Published var appleWatchIsConnected: Bool

    /// in meters
    @Published var distance: Float = 0
    @Published var direction: (x: Float, y: Float, z: Float) = (x: 0, y: 0, z: 0)

    init(services: Services) {
        appleWatchIsConnected = services.watchSession.watchIsConnected
        services.watchSession.$watchIsConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.appleWatchIsConnected = response
            }
            .store(in: &cancellable)

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
