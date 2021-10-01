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
    @Published var label: String = "Hi Jens ;)"

    init(services: Services) {
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
}
