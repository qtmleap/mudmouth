//
//  Certificate.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import CryptoKit
import Foundation
import SwiftyLogger
import X509

public extension Certificate {
    var derRepresentation: Data {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes.data
    }

    var pemRepresentation: String {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().pemString
    }

    var derBytes: [UInt8] {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes
    }

    var orgnization: String {
        issuer.first(where: { name in
            name.description.starts(with: "O=")
        })!.description.replacingOccurrences(of: "O=", with: "")
    }

    var commonName: String {
        subject.first(where: { name in
            name.description.starts(with: "CN=")
        })!.description.replacingOccurrences(of: "CN=", with: "")
    }

    var sha256Hash: String {
        let hash = SHA256.hash(data: derRepresentation)
        return hash.map { String(format: "%02X", $0) }.joined()
    }

    func isValid(privateKey key: Certificate.PrivateKey) -> Bool {
        key.publicKey == publicKey
    }

    func isValid(publicKey key: Certificate.PublicKey) -> Bool {
        key == publicKey
    }

    /// 証明書を発行する
    /// - Parameter privateKey: <#privateKey description#>
    init(_ privateKey: Certificate.PrivateKey) throws {
        // CA証明書
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
        let calendar = Calendar.current
        let notValidBefore = calendar.startOfDay(for: .now)
        let notValidAfter = calendar.date(byAdding: .day, value: 2 * 365, to: notValidBefore)!
        // 自己署名CA証明書
        try self.init(
            version: .v3,
            serialNumber: .default,
            publicKey: privateKey.publicKey,
            notValidBefore: notValidBefore,
            notValidAfter: notValidAfter,
            issuer: name,
            subject: name,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: privateKey,
        )
    }

    /// サイト証明書を発行する
    /// - Parameters:
    ///   - publicKey: Site PublicKey
    ///   - issuerPrivateKey: CA PrivateKey
    ///   - issuer: CA Certificate
    ///   - url: target URL
    init(publicKey: Certificate.PublicKey, issuerPrivateKey: Certificate.PrivateKey, issuer: Certificate, host: String) throws {
        try! self.init(publicKey: publicKey, issuerPrivateKey: issuerPrivateKey, issuer: issuer, hosts: [host])
    }

    init(publicKey: Certificate.PublicKey, issuerPrivateKey: Certificate.PrivateKey, issuer: Certificate, hosts: [String]) throws {
        let siteSubject: DistinguishedName = try! .init(builder: {
            CommonName("Interceptor")
            OrganizationName("NEVER KNOWS BEST")
        })
        let extensions = try! Certificate.Extensions(builder: {
            Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
            Critical(KeyUsage(digitalSignature: true, keyCertSign: true))
            try! ExtendedKeyUsage([.serverAuth, .ocspSigning])
            SubjectKeyIdentifier(hash: publicKey)
            SubjectAlternativeNames(hosts.map { .dnsName($0) })
        })
        SwiftyLogger.debug("Verify: \(issuer.isValid(privateKey: issuerPrivateKey))")
        let calendar = Calendar.current
        let notValidBefore = calendar.startOfDay(for: .now)
        let notValidAfter = calendar.date(byAdding: .day, value: 2 * 365, to: notValidBefore)!
        try! self.init(
            version: .v3,
            serialNumber: .init(),
            publicKey: publicKey,
            notValidBefore: notValidBefore,
            notValidAfter: notValidAfter,
            issuer: issuer.subject,
            subject: siteSubject,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: issuerPrivateKey,
        )
    }
}

public extension Certificate.PrivateKey {
    var pemRepresentation: String {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().pemString
    }

    var derBytes: [UInt8] {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes
    }

    var derRepresentation: Data {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes.data
    }

    /// 毎回ランダムに鍵を生成する
    static var `default`: Certificate.PrivateKey {
        .init(P256.Signing.PrivateKey())
    }

    init(pemRepresentation: String) throws {
        try self.init(P256.Signing.PrivateKey(pemRepresentation: pemRepresentation))
    }
}

public extension Certificate.PublicKey {
    var pemRepresentation: String {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().pemString
    }

    var derBytes: [UInt8] {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes
    }

    var derRepresentation: Data {
        // swiftlint:disable:next force_try
        try! serializeAsPEM().derBytes.data
    }
}
