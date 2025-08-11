//
//  SiteAuthority.swift
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
final class SiteAuthority: KeyPairAuthority {
    func generateKeyPair(url: URL, ca: KeyPair) -> KeyPair {
        // サイト用の鍵
        let sitePrivateKey = P256.Signing.PrivateKey()
        let siteCertificateKey = Certificate.PrivateKey(sitePrivateKey)
        
        // サイトのSubject情報
        let siteSubject: DistinguishedName = try! .init(builder: {
            CommonName("Mudmouth Generated")
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
            issuer: ca.certificate.subject, // CAのsubjectをissuerに
            subject: siteSubject,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: ca.privateKey.certificatePrivateKey
        )
        
        return .init(certificate: certificate, privateKey: sitePrivateKey)
    }
}

extension P256.Signing.PrivateKey {
    var certificatePrivateKey: Certificate.PrivateKey {
        Certificate.PrivateKey(self)
    }
}
