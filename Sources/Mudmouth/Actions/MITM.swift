//
//  MITM.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation
import NetworkExtension
import NIOCore
import NIOHTTP1
import NIOPosix
import NIOSSL
import SwiftyLogger

public enum MITM {
    //  public static func createTunnelNetworkSettings(options: [String: NSObject]? = nil) throws -> NETunnelNetworkSettings {
//    let url: URL = .init(unsafeString: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens")
//    let proxySettings: NEProxySettings = .init()
//    proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: 6836)
//    proxySettings.httpsEnabled = true
//    // swiftlint:disable:next force_unwrapping
//    proxySettings.matchDomains = [url.host!]
//    let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
//    let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
//    networkSettings.mtu = 1500
//    networkSettings.proxySettings = proxySettings
//    networkSettings.ipv4Settings = ipv4Settings
//    return networkSettings
    //  }
//
    private static let port: Int = 6_836
    private static let group: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    public static func startTunnel(options: [String: NSObject]? = nil) async throws {
        let decoder: JSONDecoder = .init()
        guard let options: [String: NSObject] = options,
              let data: Data = options[NEVPNConnectionStartOptionPassword] as? Data,
              let keyPair: KeyPair = try? decoder.decode(KeyPair.self, from: data)
        else {
            NSLog("No options provided or missing password data")
            SwiftyLogger.error("No options provided or missing password data")
            return
        }
        guard let data: Data = options[NEVPNConnectionProxyTargets] as? Data,
              let targets: [ProxyTarget] = try? decoder.decode([ProxyTarget].self, from: data)
        else {
            NSLog("No options provided or missing password data")
            SwiftyLogger.error("No options provided or missing password data")
            return
        }
        NSLog("Interceptor: Starting server on port \(port)")
        ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers(
                    [
                        ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
                        HTTPResponseEncoder(),
                        ConnectHandler(),
                        NIOSSLServerHandler(context: keyPair.context),
                        ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
                        HTTPResponseEncoder(),
                        ProxyHandler(targets: targets),
                    ], position: .last,
                )
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .bind(host: "127.0.0.1", port: port)
    }
}
