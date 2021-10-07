import Foundation
import NearbyInteraction
extension NINearbyObject {
    var distanceInMeter: Measurement<UnitLength>? {
        guard let distance = distance else { return nil }
        return Measurement(value: Double(distance), unit: .meters)
    }

    var distanceString: String? {
        guard let distanceInMeter = distanceInMeter else { return nil }

        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.alwaysShowsDecimalSeparator = true
        formatter.numberFormatter.roundingMode = .ceiling
        formatter.numberFormatter.maximumFractionDigits = 3
        formatter.numberFormatter.minimumFractionDigits = 1

        return "\(formatter.string(from: distanceInMeter))m"
    }
}
