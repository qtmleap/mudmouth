//
//  MITM.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//

import Foundation
import NetworkExtension
import SwiftyLogger

public enum MITM {
    public func createTunnelNetworkSettings(options: [String: NSObject]? = nil) throws -> NETunnelNetworkSettings {
        let url: URL = .init(unsafeString: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens")
        let proxySettings: NEProxySettings = .init()
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: 6836)
        proxySettings.httpsEnabled = true
        // swiftlint:disable:next force_unwrapping
        proxySettings.matchDomains = [url.host!]
        let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        networkSettings.mtu = 1500
        networkSettings.proxySettings = proxySettings
        networkSettings.ipv4Settings = ipv4Settings
        return networkSettings
    }
    
    public func startTunnel(options: [String: NSObject]? = nil) async throws {
        let decoder: JSONDecoder = .init()
        guard let options: [String: NSObject] = options,
              let data: Data = options[NEVPNConnectionStartOptionPassword] as? Data
        else {
            NSLog("No options provided or missing password data")
            SwiftyLogger.error("No options provided or missing password data")
            return
        }
    }
}
