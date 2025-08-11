//
//  CAAuthority.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import SwiftUI
import Crypto
import X509
import NIO
import SwiftASN1
import KeychainAccess

@Observable
final class CAAuthority: KeyPairAuthority {
    func generateKeyPair() throws -> KeyPair {
        // CA用の秘密鍵
        let caPrivateKey = P256.Signing.PrivateKey()
        let caCertificateKey = Certificate.PrivateKey(caPrivateKey)
        
        // CAのDN
        let name: DistinguishedName = try .init(builder: {
            CommonName("Mudmouth Generated")
            OrganizationName("NEVER KNOWS BEST")
        })
        
        // 証明書拡張
        let extensions = try Certificate.Extensions(builder: {
            Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
            Critical(KeyUsage(digitalSignature: true, keyCertSign: true))
        })
        
        // 自己署名CA証明書
        let certificate = try Certificate(
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
        try serializer.serialize(certificate)
        
        // 保存
        try keychain.set(caPrivateKey.rawRepresentation, key: "privateKey")
        try keychain.set(Data(serializer.serializedBytes), key: "certificate")
        
        return .init(certificate: certificate, privateKey: caPrivateKey)
    }
}
