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
    private var allowConnecting: Bool = true
    @Published private(set) var connectionState: ConnectionState = .listed {
        didSet {
            switch connectionState {
            case .connected:
                allowConnecting = false
            case .depending:
                allowConnecting = false
            case .error:
                allowConnecting = true
            case .listed:
                allowConnecting = true
            }
        }
    }
    let deviceType: DeviceType

    enum ConnectionState {
        case connected, depending, error, listed
    }
    enum DeviceType {
        case watch, phone
    }

    private var cancellable = Set<AnyCancellable>()

    init(
        deviceName: String,
        services: Services,
        deviceType: DeviceType
    ) {
        self.services = services
        self.deviceName = deviceName
        self.deviceType = deviceType
    }

    func startConnection() {
        guard allowConnecting else { return }
        self.connectionState = .depending
        switch deviceType {
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

extension DeviceRowModel: Equatable {
    static func == (lhs: DeviceRowModel, rhs: DeviceRowModel) -> Bool {
        lhs.deviceName == rhs.deviceName
    }
}
