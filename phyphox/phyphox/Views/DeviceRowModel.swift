//
//  DeviceRowModel.swift
//  phyphox
//
//  Created by Torben Köhler on 07.10.21.
//

import Foundation
import Combine

class DeviceRowModel: ObservableObject {
    let services: Services
    let deviceName: String
    @Published private(set) var distance: String?
    @Published private(set) var connectionState: ConnectionState = .listed
    let device: Device

    enum ConnectionState {
        case connected, depending, error, listed
    }
    enum Device {
        case watch, phone
    }

    private var cancellable = Set<AnyCancellable>()

    init(
        deviceName: String,
        services: Services,
        device: Device
    ) {
        self.services = services
        self.deviceName = deviceName
        self.device = device
    }

    func startConnection() {
        self.connectionState = .depending
        switch device {
        case .watch:
            connectToWatch()
        case .phone:
            break
        }
    }

    private func connectToWatch() {
        guard let handler = services.watchSession.startNearbyInteractionSessionWithWatch() else {
            self.connectionState = .error
            return
        }
        handler
            .receive(on: DispatchQueue.main)
            .sink {  [weak self] response in
                switch response {
                case .finished: break
                case .failure:
                    self?.connectionState = .error
                }
            } receiveValue: { [weak self] response in
                self?.connectionState = .connected
                self?.distance = response.distanceString
            }
            .store(in: &cancellable)
    }
}
