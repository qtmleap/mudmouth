//
//  Types.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import CryptoKit
import Foundation
import X509

struct KeyPair: Codable {
    let certificate: Certificate
    let privateKey: P256.Signing.PrivateKey
    private let encoder: JSONEncoder = .init()

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.certificate = try .init(derEncoded: try container.decode(Data.self, forKey: .certificate).bytes)
        self.privateKey = try .init(derRepresentation: try container.decode(Data.self, forKey: .privateKey))
    }
    
    init(certificate: Certificate, privateKey: P256.Signing.PrivateKey) {
        self.certificate = certificate
        self.privateKey = privateKey
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(certificate.derRepresentation, forKey: .certificate)
        try container.encode(privateKey.derRepresentation, forKey: .privateKey)
    }
    
    /// 失敗しないはずなので大丈夫
    var data: Data {
        return try! encoder.encode(self)
    }
    
    enum CodingKeys: String, CodingKey {
        case certificate
        case privateKey
    }
}
