//
//  DeviceRowModel.swift
//  phyphox
//
//  Created by Torben Köhler on 07.10.21.
//

import Foundation

class DeviceRowModel: ObservableObject {
    @Published private(set) var deviceName: String
    @Published private(set) var distance: String
    @Published private(set) var connectionState: ConnectionState

    enum ConnectionState {
        case connected, depending, error
    }

    init(nearbyObject: NearbyObject) {
        nearbyObject.updateHandler
            .receive(on: DispatchQueue.main)
            .sink { response in
                switch response { [weak self] in
                case .finished: break
                case .failure:
                    self.connectionState = .error
                }
            } receiveValue: { response in
                <#code#>
            }
            .store(in: &<#T##Set<AnyCancellable>#>)

    }
}
