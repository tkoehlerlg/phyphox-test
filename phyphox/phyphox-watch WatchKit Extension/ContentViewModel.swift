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
    @Published private(set) var distanceToPhoneString: String?

    init(services: Services) {
        self.services = services
        iPhoneIsConnected = services.watchSession.connectedToCounterpart
        services.watchSession.$connectedToCounterpart.assign(to: &$iPhoneIsConnected)

        services.nearbyService.$iPhoneConnection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] iPhoneConnection in
                guard let self = self else { return }
                guard let iPhoneConnection = iPhoneConnection else { return }
                iPhoneConnection.updateHandler
                    .receive(on: DispatchQueue.main)
                    .sink { response in
                        print(response)
                    } receiveValue: { response in
                        self.distanceToPhoneString = response.distanceString
                    }
                    .store(in: &self.cancellable)

            }
            .store(in: &cancellable)
    }
}
