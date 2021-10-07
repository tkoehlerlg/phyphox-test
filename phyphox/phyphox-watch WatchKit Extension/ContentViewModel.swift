//
//  ContentViewModel.swift
//  phyphox
//
//  Created by Torben Köhler on 15.09.21.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    private let services: Services
    var cancellable = Set<AnyCancellable>()

    @Published var appleWatchIsConnected: Bool
    @Published var label: String = ""

    init(services: Services) {
        self.services = services
        appleWatchIsConnected = services.watchSession.watchIsConnected
        services.watchSession.$watchIsConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.appleWatchIsConnected = response
            }
            .store(in: &cancellable)

        services.watchSession.receiveMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.label = message
            }
            .store(in: &cancellable)
    }

    func startMonitor() {
        services.nearbyService.currentSessions.first?.value
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { response in
                switch response {
                case .finished:
                    print("iPhone connected")
                case let .failure(error):
                    print("connection error: \(error)")
                }
            }, receiveValue: { [weak self] response in
                self?.label = "Distance: \(String(format: "%.3f", response.distance ?? 0))m"
            })
            .store(in: &cancellable)
    }
}
