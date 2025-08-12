//
//  Mudmouth.swift
//  Interceptor
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Crypto
import Foundation
import KeychainAccess
@preconcurrency import NetworkExtension
import NIO
import NIOHTTP1
import NIOSSL
import OSLog
import SwiftASN1
import SwiftUI
import SwiftyLogger
import UniformTypeIdentifiers
import X509

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
    private let port: Int = 16_836
    private let bundleIdentifier: String = "\(Bundle.main.bundleIdentifier!).packet-tunnel"
    private let generator: UINotificationFeedbackGenerator = .init()
    private var status: NEVPNStatus = .invalid

    /// スプラトゥーン3のURLスキーム
    private let url: URL = .init(unsafeString: "com.nintendo.znca://znca/game/4834290508791808")

    /// <#Description#>
    var isInstalled: Bool {
        SwiftyLogger.debug("Checking VPN is installed")
        return manager != nil
    }

    var isConnected: Bool {
        SwiftyLogger.debug("Checking VPN is connected")
        return status == .connected
    }

    var isNSOInstalled: Bool {
        SwiftyLogger.debug("Checking Nintendo Switch Online is installed")
        return UIApplication.shared.canOpenURL(URL(string: "com.nintendo.znca://")!)
    }

    /// 証明書がインストールされているかどうか
    var isVerified: Bool {
        SwiftyLogger.debug("Checking certificate installation")
        let der = certificate.derRepresentation
        let secCertificate = SecCertificateCreateWithData(nil, der as CFData)!
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(secCertificate, policy, &trust)
        guard status == errSecSuccess, let trust else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }

    /// 証明書が信頼されているかどうか
    var isTrusted: Bool {
        SwiftyLogger.debug("Checking certificate trust")
        let url: URL = .init(unsafeString: "https://mudmouth.local")
        let keyPair = generateSiteKeyPair(url: url)
        let der = keyPair.certificate.derRepresentation
        let secCertificate = SecCertificateCreateWithData(nil, der as CFData)!
        let policy = SecPolicyCreateSSL(true, url.host! as NSString)
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(secCertificate, policy, &trust)
        guard status == errSecSuccess, let trust else {
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
        SwiftyLogger.debug(configuration)
        try await manager.saveToPreferences()
    }

    /// 初期設定
    @objc
    private func configure() {
        SwiftyLogger.debug("Interceptor: Configuring VPN Manager")
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { managers, _ in
            self.manager = managers?.first
        })
    }

    /// VPNトンネルを開始する
    public func startVPNTunnel() async throws {
        SwiftyLogger.debug("Interceptor: Starting VPN Tunnel")
        // 一応マネージャーがあるかをチェックする
        guard let manager = try await NETunnelProviderManager.loadAllFromPreferences().first
        else {
            SwiftyLogger.error("Interceptor: No VPN manager found")
            return
        }
        let keyPair: KeyPair = generateSiteKeyPair(url: URL(unsafeString: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens"))
        // VPN設定を有効化する
        manager.isEnabled = true
        // 何をしているのかはよくわからない
        try await manager.saveToPreferences()
        SwiftyLogger.debug("Interceptor: VPN Manager configured")
        SwiftyLogger.debug("Interceptor: Starting VPN Tunnel with options: \(keyPair)")
        // サイト用の証明書をパスワードに同梱し、アプリに渡す
        try manager.connection.startVPNTunnel(options: [
            //            NEVPNConnectionStartOptionUsername: "Interceptor",
            NEVPNConnectionStartOptionPassword: keyPair.data as NSObject,
        ])
        generator.notificationOccurred(.success)
    }

    /// VPNトンネルを停止する
    /// アプリが復帰したときにVPNを無効化する
    @objc
    public func stopVPNTunnel() {
        SwiftyLogger.debug("Interceptor: Stopping VPN Tunnel")
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
            issuerPrivateKey: caCertificateKey,
        )

        var serializer = DER.Serializer()
        try! serializer.serialize(certificate)

        // 保存
        try! keychain.setPrivateKey(privateKey)
        try! keychain.setCertificate(certificate)

        // データを更新
        privateKey = caPrivateKey
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
            issuerPrivateKey: privateKey.certificatePrivateKey,
        )

        return .init(certificate: certificate, privateKey: sitePrivateKey)
    }

    public init() {
        // ここで何かしらの値が返ってくる
        let keyPair: KeyPair = load()
        certificate = keyPair.certificate
        privateKey = keyPair.privateKey
        /// アプリの状態変化時にデータを再読込する
        /// VPNマネージャをロードする
        /// NOTE: 非同期関数が使えないのでこうやって読み込んでおく
        /// NOTE: NEVPNManagerを読み込んでから通知を登録しないと無限にとんでくる
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { [self] managers, _ in
            if let manager = managers?.first {
                self.manager = manager
                NotificationCenter.default.addObserver(forName: .NEVPNStatusDidChange, object: manager.connection, queue: .main, using: { notification in
                    guard let session: NETunnelProviderSession = notification.object as? NETunnelProviderSession
                    else {
                        return
                    }
                    Task(priority: .background, operation: { @MainActor in
                        SwiftyLogger.debug("VPN Status Changed: \(session.status)")
                        self.status = session.status
                    })
                })
            }
        })
        NotificationCenter.default.addObserver(self, selector: #selector(stopVPNTunnel), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configure), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
}
