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

    @Published var devices: [DeviceRowModel] = []

    init(services: Services) {
        self.services = services

        let watch = DeviceRowModel(
            deviceName: "Apple Watch",
            services: services,
            deviceType: .watch
        )

        services.watchSession.$connectedToCounterpart
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                guard let self = self else { return }
                if response {
                    services.watchSession.requestFeatureOnCounterpart(.nearbySession)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { response in
                            print(response)
                        }, receiveValue: { response in
                            if response {
                                if !self.devices.contains(where: { $0 == watch }) {
                                    self.devices.append(watch)
                                }
                            } else {
                                self.devices.removeAll(where: { $0 == watch })
                            }
                        })
                        .store(in: &self.cancellable)
                } else {
                    self.devices.removeAll(where: { $0 == watch })
                }
            }
            .store(in: &cancellable)
    }
}
