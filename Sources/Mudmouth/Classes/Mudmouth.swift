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
    private var manager: NETunnelProviderManager?
    private(set) var privateKey: Certificate.PrivateKey! {
        willSet {
            SwiftyLogger.warning("Private key updated, regenerating certificate")
            try? keychain.setPrivateKey(newValue)
        }
    }

    private(set) var certificate: Certificate! {
        willSet {
            SwiftyLogger.warning("Certificate updated, saving to keychain")
            try? keychain.setCertificate(newValue)
        }
    }

//    {
//        didSet {
//            SwiftyLogger.warning("Certificate updated, saving to keychain")
//            try? keychain.setCertificate(newValue)
//        }
//    }

//    /// CA秘密鍵
//    private(set) var privateKey: Certificate.PrivateKey {
//        get {
//            guard let privateKey = try? keychain.getPrivateKey()
//            else {
//                SwiftyLogger.warning("No private key found, generating a new one")
//                return .default
//            }
//            return privateKey
//        }
//        set {
//            SwiftyLogger.warning("Setting new private key in keychain")
//            try? keychain.setPrivateKey(newValue)
//        }
//    }
//
//    /// CA証明書
//    @ObservationTracked
//    private(set) var certificate: Certificate {
//        get {
//            guard let certificate = try? keychain.getCertificate()
//            else {
//                SwiftyLogger.warning("No certificate found, generating a new one")
//                return try! .init(privateKey)
//            }
//            return certificate
//        }
//        set {
//            SwiftyLogger.warning("Setting new certificate in keychain")
//            try? keychain.setCertificate(newValue)
//        }
//    }

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

    private(set) var isAuthorized: Bool = false

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

    @objc
    private func willEnterForegroundNotification() {
        SwiftyLogger.debug("Interceptor: Configuring VPN Manager on foreground")
        // NETunnelProviderManagerを更新
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { managers, _ in
            self.manager = managers?.first
        })
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { @MainActor settings in
            self.isAuthorized = settings.authorizationStatus == .authorized
        })
    }

    @objc
    private func didEnterBackgroundNotification() {
        SwiftyLogger.debug("Interceptor: Configuring VPN Manager on background")
        // NETunnelProviderManagerを更新
        NETunnelProviderManager.loadAllFromPreferences(completionHandler: { managers, _ in
            self.manager = managers?.first
        })
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            self.isAuthorized = settings.authorizationStatus == .authorized
        })
    }

    /// VPNトンネルを開始する
    public func startVPNTunnel() async throws {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
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

    /// NOTE: アプリ起動時に証明書を発行する
    /// 多分失敗しないのであんまり気にしなくて大丈夫
    /// - Returns: <#description#>
    func generateCAKeyPair() {
        let privateKey: Certificate.PrivateKey = .default
        let certificate: Certificate = try! .init(privateKey)
        self.privateKey = privateKey
        self.certificate = certificate
    }

    /// <#Description#>
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    private func generateSiteKeyPair(url: URL) -> KeyPair {
        // サイト用の鍵
        let caCertificateKey: Certificate.PrivateKey = .default
        let certificate: Certificate = try! .init(
            publicKey: caCertificateKey.publicKey,
            issuerPrivateKey: privateKey,
            issuer: certificate,
            url: url,
        )
        return .init(certificate: certificate, privateKey: caCertificateKey)
    }

    #if DEBUG || targetEnvironment(simulator)
    public init() {
        SwiftyLogger.debug("Mudmouth: Initializing in DEBUG mode")
//        try! keychain.removeAll()
        privateKey = {
            guard let privateKey = try? keychain.getPrivateKey()
            else {
                SwiftyLogger.warning("No private key found, generating a new one")
                return .default
            }
            return privateKey
        }()
        certificate = {
            guard let certificate = try? keychain.getCertificate()
            else {
                SwiftyLogger.warning("No certificate found, generating a new one")
                SwiftyLogger.debug(privateKey.derRepresentation.hexString)
                SwiftyLogger.debug(self.privateKey.derRepresentation.hexString)
                return try! .init(privateKey)
            }
            return certificate
        }()
        SwiftyLogger.debug("Mudmouth: Keychain cleared")
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
//            /// ユーザーの通知設定を取得する
//            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
//                DispatchQueue.main.async(execute: {
            ////                    SwiftyLogger.debug("Thread: \(Thread.current.isMainThread ? "Main" : "Background")")
//                    print("Thread: \(Thread.current.isMainThread ? "Main" : "Background")")
//                    self.isAuthorized = settings.authorizationStatus == .authorized
//                })
//            })
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
            NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
    #else
    public init() {
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
    #endif
}
