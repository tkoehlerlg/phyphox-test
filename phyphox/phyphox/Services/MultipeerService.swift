////
////  MultipeerService.swift
////  phyphox
////
////  Created by Torben Köhler on 06.10.21.
////
//
//import UIKit
//import MultipeerConnectivity
//
//final class MultipeerService: NSObject {
//    // MARK: Own Data
//    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
//    var connectedPeers: [MCPeerID] = []
//    @Published var invitedByPeer: MCPeerID?
//
//    private lazy var serviceAdvertiser: MCNearbyServiceAdvertiser = {
//        return .init(peer: myPeerID, discoveryInfo: nil, serviceType: "phyphox")
//    }()
//    private lazy var serviceBrowser: MCNearbyServiceBrowser = {
//        return .init(peer: myPeerID, serviceType: "phyphox")
//    }()
//
//    private lazy var session: MCSession = {
//        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
//        session.delegate = self
//        return session
//    }()
//
//    // MARK: Sessions
//    func startBrowsingForPeers() {
//        serviceAdvertiser.delegate = self
//        serviceAdvertiser.startAdvertisingPeer()
//        serviceBrowser.delegate = self
//        serviceBrowser.startBrowsingForPeers()
//    }
//
//    func stopBrowsingForPeers() {
//        serviceBrowser.stopBrowsingForPeers()
//        serviceAdvertiser.stopAdvertisingPeer()
//    }
//
//    func shareDiscoveryToken(_ data: Data, with peer: MCPeerID) {
//        print("Share Discovery token with \(peer.displayName)")
//        guard session.connectedPeers.count > 0 else { return }
//        do {
//            try self.session.send(data, toPeers: [peer], with: .reliable)
//        } catch let error {
//            print("Share Discovery token error: \(error)")
//        }
//    }
//}
//
//// MARK: Advertiser
//
//extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//        print("received invitation by: \(peerID.displayName)")
//        invitationHandler(true, session)
//    }
//
//}
//
//extension MultipeerService: MCNearbyServiceBrowserDelegate {
//    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
//        NSLog("%@", "foundPeer: \(peerID)")
//        NSLog("%@", "invitePeer: \(peerID)")
//        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
//    }
//
//    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
//}
//
//extension MultipeerService: MCSessionDelegate {
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        if state == .connected {
//            delegate?.connectedToDevice()
//        }
//        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
//        delegate?.connectedDevicesChanged(devices: session.connectedPeers.map{$0.displayName})
//    }
//
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        NSLog("%@", "didReceiveData: \(data) from \(peerID.displayName)")
//        delegate?.receivedDiscoveryToken(data: data)
//    }
//
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
//    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
//
//}
