import Foundation
import NearbyInteraction
import Combine

struct NearbyObject {
    let identifier: String
    let encryptedToken: Data
    let updateHandler: PassthroughSubject<NINearbyObject, NearbyObjectError>
}

// MARK: Errors
enum NearbyObjectError: String, Error {
    case noDiscoveryToken, objectCantBeFoundLonger, sessionClosed, tokenCanNotEncrypted
}
