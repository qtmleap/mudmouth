//
//  Generate.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//

import SwiftUI
import Crypto
import X509
import NIO
import SwiftASN1
import KeychainAccess

func generate(
    subject: DistinguishedName,
    issuer: DistinguishedName,
    issuerPrivateKey: Certificate.PrivateKey,
    validityPeriod: TimeInterval,
    extensionsBuilder: () throws -> Certificate.Extensions
) throws -> KeyPair {
    let privateKey = P256.Signing.PrivateKey()
    let certPrivateKey = Certificate.PrivateKey(privateKey)

    let extensions = try extensionsBuilder()

    let certificate = try Certificate(
        version: .v3,
        serialNumber: .init(),
        publicKey: certPrivateKey.publicKey,
        notValidBefore: .now,
        notValidAfter: .now.addingTimeInterval(validityPeriod),
        issuer: issuer,
        subject: subject,
        signatureAlgorithm: .ecdsaWithSHA256,
        extensions: extensions,
        issuerPrivateKey: issuerPrivateKey
    )

    return .init(certificate: certificate, privateKey: privateKey)
}
