import Foundation
protocol NearbyWatch {
    var nearbyService: NearbyService { get }
    func receivedNearbyWCInvitation(data: Data, replyHandler: @escaping ([String : Any]) -> Void)
}
