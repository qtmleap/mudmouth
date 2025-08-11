//
//  X509Proxy.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//

import SwiftUI
import Foundation
import KeychainAccess
import X509
import NIOCore
import NIOPosix
import NIOHTTP1
import QuantumLeap

@Observable
public class X509Proxy: ChannelInboundHandler, @unchecked Sendable {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private let keychain: Keychain = .init(server: "https://api.lp1.av5ja.srv.nintendo.net", protocolType: .https)
    private let port: Int = 8888
    public var url: URL {
        .init(string: "http://127.0.0.1:\(port)")!
    }
    
    
    /// X509証明書インストール用のサーバーの起動
    func start() throws {
        Logger.debug("Starting X509Proxy on port \(port)")
//        let privateKey: PrivateKey = try keychain.getPrivateKey()
        let certificate: Certificate = try keychain.getCertificate()
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let handler: CertificateHandler = .init(certificate: certificate)
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline()
                    .flatMap { _ in
                        channel.pipeline.addHandler(handler)
                    }
            }
        // swiftlint:disable:next force_try
        bootstrap.bind(to: try! SocketAddress(ipAddress: "127.0.0.1", port: port))
            .whenComplete { [self] result in
                switch result {
                case .success:
                    NSLog("Interceptor: Server bound to port \(port)")
                    break
                case .failure(let failure):
                    NSLog("Interceptor: Failed to bind server: \(failure)")
                    Logger.error(failure)
                    break
                }
            }
    }
    
    /// X509証明書インストール用のサーバーの停止
    /// FIXME: 現状は停止しない
    func stop() throws {
        Logger.debug("Stopping X509Proxy on port \(port)")
        // Implement stopping logic if necessary
        // This might involve shutting down the event loop group or closing channels
    }
    
    init() {}
}

extension X509Proxy {
    public static let `default`: X509Proxy = .init()
}
