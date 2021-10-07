//
//  DeviceRow.swift
//  phyphox
//
//  Created by Torben Köhler on 07.10.21.
//

import SwiftUI

struct DeviceRow: View {
    var body: some View {
        HStack {
            Text("Apple Watch")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            Text("1,000 m")
                .fontWeight(.medium)
                .padding()
        }
        .frame(height: 50)
        .background(
            Color.gray.opacity(0.2)
        )
        .cornerRadius(15)
    }
}

struct DeviceRow_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRow()
    }
}
