//
//  Interceptor.swift
//  Interceptor
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Crypto
import Foundation
@preconcurrency import NetworkExtension
import OSLog
import X509
import SwiftUI
import KeychainAccess
import SwiftASN1
import UniformTypeIdentifiers
import NIO
import NIOHTTP1
import QuantumLeap
import NIOSSL

@MainActor
@Observable
public final class Mudmouth {
    public typealias CompletionHandler = (Error?) -> Void
    
    private var manager: NETunnelProviderManager?
    /// NOTE: 空っぽのことはないはずなので多分大丈夫
    private var certificate: Certificate!
    /// NOTE: 空っぽのことはないはずなので多分大丈夫
    private var privateKey: P256.Signing.PrivateKey!
    private let keychain: Keychain = .init(server: "https://api.lp1.av5ja.srv.nintendo.net", protocolType: .https)
    private let port: Int = 16836
    /// NOTE: 使ってないかも
    private var channel: Channel? = nil
    /// NOTE: 使ってないかも
    private var group: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private let bundleIdentifier: String = "\(Bundle.main.bundleIdentifier!).packet-tunnel"
    private let generator: UINotificationFeedbackGenerator = .init()
    /// スプラトゥーン3のURLスキーム
    private let url: URL = .init(unsafeString: "com.nintendo.znca://znca/game/4834290508791808")
    
    /// <#Description#>
    var isInstalled: Bool {
        Logger.debug("Checking VPN is installed")
        return manager != nil
    }
    
    var isNSOInstalled: Bool {
        Logger.debug("Checking NSO is installed")
        Logger.debug("URL Schema: \(UIApplication.shared.canOpenURL(URL(string: "com.nintendo.znca://")!))")
        Logger.debug("URL Schema: \(UIApplication.shared.canOpenURL(URL(string: "npf71b963c1b7b6d119://")!))")
        return UIApplication.shared.canOpenURL(URL(string: "com.nintendo.znca://")!)
    }
    
    /// 証明書がインストールされているかどうか
    var isVerified: Bool {
        Logger.debug("Checking certificate installation")
        let der = certificate.derRepresentation
        let secCertificate = SecCertificateCreateWithData(nil, der as CFData)!
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(secCertificate, policy, &trust)
        guard status == errSecSuccess, let trust = trust else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }
    
    /// 証明書が信頼されているかどうか
    var isTrusted: Bool {
        Logger.debug("Checking certificate trust")
        let url: URL = .init(unsafeString: "https://mudmouth.local")
        let keyPair = generateSiteKeyPair(url: url)
        let der = keyPair.certificate.derRepresentation
        let secCertificate = SecCertificateCreateWithData(nil, der as CFData)!
        let policy = SecPolicyCreateSSL(true, url.host! as NSString)
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(secCertificate, policy, &trust)
        guard status == errSecSuccess, let trust = trust else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }
    
    /// VPN構成のインストールを実行する
    /// パスコード等の認証が必要になる
    @MainActor
    func installVPN() async throws {
        let manager: NETunnelProviderManager = .init()
        manager.localizedDescription = "Interceptor"
        let configuration: NETunnelProviderProtocol = .init()
        configuration.providerBundleIdentifier = bundleIdentifier
        configuration.serverAddress = "Interceptor"
        manager.protocolConfiguration = configuration
        Logger.debug(configuration)
        try await manager.saveToPreferences()
    }
    
    /// 初期設定
    @objc
    private func configure() {
        Logger.debug("Interceptor: Configuring VPN Manager")
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { managers, error in
            self.manager = managers?.first
        })
    }
    
    /// VPNトンネルを開始する
    public func startVPNTunnel() async throws {
        Logger.debug("Interceptor: Starting VPN Tunnel")
        // 一応マネージャーがあるかをチェックする
        guard let manager = try await NETunnelProviderManager.loadAllFromPreferences().first
        else {
            Logger.error("Interceptor: No VPN manager found")
            return
        }
        let keyPair: KeyPair = generateSiteKeyPair(url: URL(unsafeString: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens"))
        // VPN設定を有効化する
        manager.isEnabled = true
        // 何をしているのかはよくわからない
        try await manager.saveToPreferences()
        // サイト用の証明書をパスワードに同梱し、アプリに渡す
        try manager.connection.startVPNTunnel(options: [
//            NEVPNConnectionStartOptionUsername: "Interceptor",
            NEVPNConnectionStartOptionPassword: keyPair.data as NSObject
        ])
        generator.notificationOccurred(.success)
        await UIApplication.shared.open(url)
    }

    /// VPNトンネルを停止する
    /// アプリが復帰したときにVPNを無効化する
    @objc
    public func stopVPNTunnel() {
        Logger.debug("Interceptor: Stopping VPN Tunnel")
        /// 非同期関数はobjcで定義できないのでTaskでラップする
        Task(priority: .background, operation: {
            if let manager = try await NETunnelProviderManager.loadAllFromPreferences().first {
                manager.connection.stopVPNTunnel()
                generator.notificationOccurred(.success)
            }
        })
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    private func load() -> KeyPair {
//        if let privateKeyData = try? keychain.getData("privateKey"),
//           let certificateData = try? keychain.getData("certificate"),
//           let privateKey = try? P256.Signing.PrivateKey(rawRepresentation: privateKeyData),
//           let der = try? DER.parse([UInt8](certificateData)),
//           let certificate = try? Certificate(derEncoded: der)
//        {
//            return (certificate, privateKey)
//        }
        if let privateKey = try? keychain.getPrivateKey(),
           let certificate = try? keychain.getCertificate()
        {
            return .init(certificate: certificate, privateKey: privateKey)
        }
        return generateCAKeyPair()
    }
    
    /// NOTE: アプリ起動時に証明書を発行する
    /// 多分失敗しないのであんまり気にしなくて大丈夫
    /// - Returns: <#description#>
    @discardableResult
    func generateCAKeyPair() -> KeyPair {
        // CA用の秘密鍵
        let caPrivateKey = P256.Signing.PrivateKey()
        let caCertificateKey = Certificate.PrivateKey(caPrivateKey)
        
        // CAのDN
        let name: DistinguishedName = try! .init(builder: {
            CountryName("JP")
            CommonName("Interceptor")
            LocalityName("TOKYO")
            OrganizationName("QuantumLeap")
            OrganizationalUnitName("NEVER KNOWS BEST")
        })
        
        // 証明書拡張
        let extensions = try! Certificate.Extensions(builder: {
            Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
            Critical(KeyUsage(digitalSignature: true, keyCertSign: true))
        })
        
        // 自己署名CA証明書
        let certificate = try! Certificate(
            version: .v3,
            serialNumber: .init(),
            publicKey: caCertificateKey.publicKey,
            notValidBefore: .now,
            notValidAfter: .now.addingTimeInterval(60 * 60 * 24 * 365 * 10),
            issuer: name,
            subject: name,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: caCertificateKey
        )
        
        var serializer = DER.Serializer()
        try! serializer.serialize(certificate)
        
        // 保存
        try! keychain.setPrivateKey(privateKey)
        try! keychain.setCertificate(certificate)
     
        // データを更新
        self.privateKey = caPrivateKey
        self.certificate = certificate
        
        return .init(certificate: certificate, privateKey: caPrivateKey)
    }
    
    /// <#Description#>
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    private func generateSiteKeyPair(url: URL) -> KeyPair {
        // サイト用の鍵
        let sitePrivateKey = P256.Signing.PrivateKey()
        let siteCertificateKey = Certificate.PrivateKey(sitePrivateKey)
        
        // サイトのSubject情報
        let siteSubject: DistinguishedName = try! .init(builder: {
            CommonName("Interceptor")
            OrganizationName("NEVER KNOWS BEST")
        })
        
        // 証明書の拡張
        let extensions = try! Certificate.Extensions(builder: {
            Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
            Critical(KeyUsage(digitalSignature: true, keyCertSign: true))
            try! ExtendedKeyUsage([.serverAuth, .ocspSigning])
            SubjectKeyIdentifier(hash: siteCertificateKey.publicKey)
            SubjectAlternativeNames([.dnsName(url.host!)])
        })
        
        // 証明書作成
        let certificate = try! Certificate(
            version: .v3,
            serialNumber: .init(),
            publicKey: siteCertificateKey.publicKey,
            notValidBefore: .now,
            notValidAfter: .now.addingTimeInterval(60 * 60 * 24 * 365 * 2),
            issuer: certificate.subject, // CAのsubjectをissuerに
            subject: siteSubject,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: privateKey.certificatePrivateKey
        )
        
        return .init(certificate: certificate, privateKey: privateKey)
    }
   
    @discardableResult
    public func startTunnel()  {
        NSLog("Interceptor: Starting server on port \(port)")
        let context: NIOSSLContext = try! .init(configuration: try! TLSConfiguration.makeServerConfiguration(
            certificateChain: [
                .certificate(.init(bytes: certificate.derBytes, format: .der))
            ],
            privateKey: .privateKey(.init(bytes: privateKey.certificatePrivateKey.derBytes, format: .der))))
        ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandlers(
                    [
                        ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
                        HTTPResponseEncoder(),
                        ConnectHandler(),
                        NIOSSLServerHandler(context: context),
                        ByteToMessageHandler(HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)),
                        HTTPResponseEncoder(),
                        ProxyHandler(),
                    ], position: .last
                )
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .bind(host: "127.0.0.1", port: port)
    }
    
    public init() {
        // ここで何かしらの値が返ってくる
        let keyPair: KeyPair = load()
        self.certificate = keyPair.certificate
        self.privateKey = keyPair.privateKey
        /// アプリの状態変化時にデータを再読込する
//        NotificationCenter.default.addObserver(self, selector: #selector(stopVPNTunnel), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopVPNTunnel), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configure), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}

/// X509証明書をインストールするためのChannelInboundHandler
/// PacketTunnelには直接関与しない
class CertificateHandler: ChannelInboundHandler, @unchecked Sendable {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private let certificate: Certificate
    
    init(certificate: Certificate) {
        self.certificate = certificate
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        guard case .head = httpData else {
            return
        }
        let pemString: String = certificate.pemRepresentation
        let headers: HTTPHeaders = .init([
            ("Content-Length", pemString.count.formatted()),
            ("Content-Type", "application/x-x509-ca-cert"),
        ])
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        let buffer: ByteBuffer = context.channel.allocator.buffer(string: pemString)
        let body: HTTPServerResponsePart = .body(.byteBuffer(buffer))
        context.writeAndFlush(wrapOutboundOut(body), promise: nil)
    }
}

extension HTTPResponseEncoder: @unchecked @retroactive Sendable {}

extension ByteToMessageHandler: @unchecked @retroactive Sendable {}
