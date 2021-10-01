//
//  AppModel.swift
//  phyphox
//
//  Created by Torben Köhler on 27.09.21.
//

import Foundation
import SwiftUI
import Combine

class AppModel: ObservableObject {
    var services: Services

    init(services: Services) {
        self.services = services
    }
}
