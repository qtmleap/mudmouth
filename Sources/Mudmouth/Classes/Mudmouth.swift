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
    private var manager: NETunnelProviderManager? {
        willSet {
            SwiftyLogger.debug("Interceptor: VPN Manager updated \(newValue)")
            // 現在の値ではなく、新しくセットする値がnilかどうかでチェックする
            isVPNInstalled = newValue != nil
        }
    }

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

    // iCloud Keychainを利用する
    // NOTE: ライブラリを利用するアプリのバンドルIDで初期化
    private let keychain: Keychain = .init(service: Bundle.main.bundleIdentifier!).synchronizable(true)
    private let port: Int = 16_836
    private let bundleIdentifier: String = "\(Bundle.main.bundleIdentifier!).packet-tunnel"
    private let generator: UINotificationFeedbackGenerator = .init()
    private let notificationCenter: UNUserNotificationCenter = .current()
    private var status: NEVPNStatus = .invalid
    /// パケットをキャプチャするドメインまとめ
    private let targets: [ProxyTarget] = [
        //        URL(string: "https://api-lp1.znc.srv.nintendo.net/v4/Game/GetWebServiceToken")!, // Nintendo (暗号化されているので現在は取得不可)
        URL(string: "https://api.accounts.nintendo.com/2.0.0/users/me")!, // Nintendo
//        URL(string: "https://api.lp1.usagi.srv.nintendo.net/api/primer_tokens")!, // Splatoon 3
        URL(string: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens")!, // Splatoon 3
        URL(string: "https://api.lp1.87abc152.srv.nintendo.net/auth")!, // Zelda Notes
        URL(string: "https://accounts.nintendo.com/connect/1.0.0/api/token")!, // Nintendo
        URL(string: "https://app.splatoon2.nintendo.net/")!, // Splatoon 2
        URL(string: "https://app.smashbros.nintendo.net/")!, // Smash World
        URL(string: "https://web.sd.lp1.acbaa.srv.nintendo.net/")!, // NookLink
    ].map { .init(url: $0) }

    /// Nintendo Switch Appがインストールされているかどうか
    /// NOTE: 一度アプリがバックグラウンドになるので、フォアグラウンドになったときにチェックすれば良い
    private(set) var isAPPInstalled: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isAPPInstalled changed from \(isAPPInstalled) to \(newValue)")
        }
    }

    /// VPNがインストールされているかどうか
    /// NOTE: アプリがフォアグラウンドになったときか、VPNをインストール直後にチェックすれば良い
    private(set) var isVPNInstalled: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isVPNInstalled changed from \(isVPNInstalled) to \(newValue)")
        }
    }

    /// VPNに接続されているかどうか
    /// NOTE: VPNの状態が変更されたときにチェックすれば良い
    private(set) var isConnected: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isConnected changed from \(isConnected) to \(newValue)")
        }
    }

    /// 証明書がインストールされているかどうか
    /// NOTE: アプリがフォアグラウンドになったときにチェックすれば良い
    private(set) var isVerified: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isVerified changed from \(isVerified) to \(newValue)")
        }
    }

    /// 証明書が信頼されているかどうか
    /// NOTE: アプリがフォアグラウンドになったときにチェックすれば良い
    private(set) var isTrusted: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isTrusted changed from \(isTrusted) to \(newValue)")
        }
    }

    /// 通知設定が許可されているかどうか
    /// NOTE: アプリがフォアグラウンドになったときと、通知許可リクエストの直後にチェックすれば良い
    private(set) var isAuthorized: Bool = false {
        willSet {
            SwiftyLogger.debug("Interceptor: isAuthorized changed from \(isAuthorized) to \(newValue)")
        }
    }

    /// VPN構成のインストールを実行する
    /// NOTE: パスコード等の認証が必要になる
    /// NOTE: isVPNInstalledを更新する
    /// NOTE: マネージャがそもそもなければどうなるんだ感はあるが、新しく作られまくる心配がない
    func installVPN() async throws {
        manager?.localizedDescription = "Interceptor"
        let configuration: NETunnelProviderProtocol = .init()
        configuration.providerBundleIdentifier = bundleIdentifier
        configuration.serverAddress = "Interceptor"
        manager?.protocolConfiguration = configuration
        SwiftyLogger.debug(configuration)
        try await manager?.saveToPreferences()
    }

    /// ユーザーに通知の許可をリクエストする
    /// 拒否されている場合には設定を開く
    public func requestAuthorization(options: [UNNotificationPresentationOptions] = []) async throws {
        let settings = try await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized {
            return
        }
        if settings.authorizationStatus == .notDetermined {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
            return
        }
        await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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
        SwiftyLogger.debug("Interceptor: Targets \(targets)")
        // 今は実際にはここはほぼ利用していない
        let keyPair: KeyPair = generateSiteKeyPair(hosts: targets.hosts)
        // VPN設定を有効化する
        manager.isEnabled = true
        // 何をしているのかはよくわからない
        try await manager.saveToPreferences()
        SwiftyLogger.debug("Interceptor: VPN Manager configured")
        SwiftyLogger.debug("Interceptor: Starting VPN Tunnel with options: \(keyPair)")
        SwiftyLogger.debug("Interceptor: \(NEVPNConnectionStartOptionPassword)")
        // サイト用の証明書をパスワードに同梱し、アプリに渡す
        try manager.connection.startVPNTunnel(options: [
            NEVPNConnectionProxyTargets: targets.data as NSObject,
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

    public func openURL(_ contentId: ContentId) {
        UIApplication.shared.open(URL(unsafeString: "com.nintendo.znca://znca/game/\(contentId.rawValue)"))
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

    /// サイト用の証明書を発行する
    /// NOTE: 現在は指定したサイトにのみ有効な設定
    /// - Parameter url: <#url description#>
    /// - Returns: <#description#>
    private func generateSiteKeyPair(hosts: [String]) -> KeyPair {
        // サイト用の鍵
        let caCertificateKey: Certificate.PrivateKey = .default
        let certificate: Certificate = try! .init(
            publicKey: caCertificateKey.publicKey,
            issuerPrivateKey: privateKey,
            issuer: certificate,
            hosts: hosts,
        )
        return .init(certificate: certificate, privateKey: caCertificateKey)
    }

    public init() {
        #if DEBUG || targetEnvironment(simulator)
        SwiftyLogger.debug("Mudmouth: Initializing in DEBUG mode")
        #else
        SwiftyLogger.debug("Mudmouth: Initializing in RELEASE mode")
        #endif
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
        NotificationCenter.default.addObserver(self, selector: #selector(statusDidChange), name: .NEVPNStatusDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActiveNotification), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// VPN接続が変化するたびに呼ばれる
    @objc
    private func statusDidChange() {
        SwiftyLogger.debug("Interceptor: VPN Status Changed")
        isConnected = getConnected()
    }

    /// アプリがフォアグラウンドになったときに呼ばれる
    /// NOTE: 起動時には呼ばれない
    @objc
    private func willEnterForegroundNotification() {
        SwiftyLogger.debug("Interceptor: WillEnterForegroundNotification")
        /// 少し時間をおいてから実行しないとfalseになる
        /// NOTE: 根本的な解決方法を模索したい
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            isTrusted = getTrusted()
        }
    }

    /// アプリがバックグラウンドになったときに呼ばれる
    @objc
    private func didEnterBackgroundNotification() {
        SwiftyLogger.debug("Interceptor: DidEnterBackgroundNotification")
    }

    /// 起動時にも呼ばれる
    /// アプリがアクティブになるたびに毎回呼ばれる
    @objc
    private func didBecomeActiveNotification() {
        SwiftyLogger.debug("Interceptor: DidBecomeActiveNotification")
        isAPPInstalled = getAppInstalled()
        isVerified = getVerified()
        Task(priority: .background, operation: {
            self.isAuthorized = try await getAuthorized()
            /// VPN設定を読み込んでマネージャをロードする
            /// NOTE: VPN設定が有効かどうかのチェックはwillSetで実行するのでgetVPNInstalledは不要
            self.manager = try await NETunnelProviderManager.loadAllFromPreferences().first
        })
        /// 少し時間をおいてから実行しないとfalseになる
        /// NOTE: 根本的な解決方法を模索したい
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            isTrusted = getTrusted()
        }
    }
}

extension Mudmouth {
    /// Nintendo Switch Appがインストールされているかどうかをチェックする
    /// NOTE: いきなり呼んでも大丈夫でした
    /// NOTE: URLスキームが動作するかどうかでチェックしています
    /// - Returns: <#description#>
    private func getAppInstalled() -> Bool {
        SwiftyLogger.debug("Checking if Nintendo Switch Online App is installed")
        return UIApplication.shared.canOpenURL(URL(string: "com.nintendo.znca://")!)
    }

    /// 証明書がインストールされているかどうかをチェックする
    /// NOTE: いつ呼んでも大丈夫でした
    /// - Returns: <#description#>
    private func getVerified() -> Bool {
        SwiftyLogger.debug("Checking if certificate is installed")
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

    /// 証明書が信頼されているかどうかをチェックする
    /// NOTE: 少し時間を置かないとチェックされない
    /// NOTE: 別のトリガーを用意したほうがいい気もする
    /// - Returns: <#description#>
    private func getTrusted() -> Bool {
        SwiftyLogger.debug("Checking if certificate is trusted")
        let url: URL = .init(unsafeString: "https://mudmouth.local")
        let keyPair = generateSiteKeyPair(hosts: [url.host!])
        let der = keyPair.certificate.derRepresentation
        let secCertificate = SecCertificateCreateWithData(nil, der as CFData)!
        let policy = SecPolicyCreateSSL(true, url.host! as NSString)
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(secCertificate, policy, &trust)
        SwiftyLogger.debug("Interceptor: SecTrustCreateWithCertificates status: \(status)")
        guard status == errSecSuccess, let trust else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }

    /// 通知が許可されているかをチェックする
    /// - Returns: <#description#>
    private func getAuthorized() async throws -> Bool {
        SwiftyLogger.debug("Checking if notifications are authorized")
        let settings: UNNotificationSettings = try await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

//    private func getVPNInstalled() -> Bool {
//        SwiftyLogger.debug("Checking if VPN is installed")
//        SwiftyLogger.debug("Interceptor: VPN Manager is \(String(describing: manager))")
//        return self.manager != nil
//    }

    private func getConnected() -> Bool {
        manager?.connection.status == .connected
    }
}
