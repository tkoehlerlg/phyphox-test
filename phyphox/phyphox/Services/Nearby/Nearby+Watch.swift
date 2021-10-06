import Foundation
protocol NearbyWatch {
    var nearbyService: NearbyService { get }
    func receivedNearbyInvitation(data: Data, replyHandler: @escaping ([String : Any]) -> Void)
}
