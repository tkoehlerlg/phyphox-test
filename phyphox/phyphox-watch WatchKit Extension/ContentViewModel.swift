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

    @Published private(set) var iPhoneIsConnected: Bool
    @Published private(set) var sessionStarted: Bool

    init(services: Services) {
        self.services = services
        iPhoneIsConnected = services.watchSession.connectedToCounterpart
        sessionStarted = services.nearbyService.iPhoneConnection != nil
        services.watchSession.$connectedToCounterpart.assign(to: &$iPhoneIsConnected)
        services.nearbyService.$iPhoneConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] iPhoneConnection in
                self?.sessionStarted = iPhoneConnection != nil
            }
            .store(in: &cancellable)
    }
}
