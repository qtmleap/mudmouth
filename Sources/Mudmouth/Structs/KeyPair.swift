//
//  KeyPair.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import CryptoKit
import Foundation
import NIOSSL
import X509

public struct KeyPair: Codable {
    public let certificate: Certificate
    public let privateKey: P256.Signing.PrivateKey
    private let encoder: JSONEncoder = .init()

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        certificate = try .init(derEncoded: container.decode(Data.self, forKey: .certificate).bytes)
        privateKey = try .init(derRepresentation: container.decode(Data.self, forKey: .privateKey))
    }

    init(certificate: Certificate, privateKey: P256.Signing.PrivateKey) {
        self.certificate = certificate
        self.privateKey = privateKey
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificate.derRepresentation, forKey: .certificate)
        try container.encode(privateKey.derRepresentation, forKey: .privateKey)
    }

    /// 失敗しないはずなので大丈夫
    var data: Data {
        try! encoder.encode(self)
    }

    var context: NIOSSLContext {
        try! .init(configuration: try TLSConfiguration.makeServerConfiguration(certificateChain: [
            .certificate(NIOSSLCertificate(bytes: certificate.derBytes, format: .der)),
        ], privateKey: .privateKey(NIOSSLPrivateKey(bytes: privateKey.certificatePrivateKey.derBytes, format: .der))))
    }

    enum CodingKeys: String, CodingKey {
        case certificate
        case privateKey
    }
}
