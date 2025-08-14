//
//  GameWebToken.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/14.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

public struct GameWebToken: Codable, Sendable {
    public let header: Header
    public let payload: Payload
    public let signature: String
    
    public init(_ value: String) throws {
        let values: [String] = value.split(separator: ".").map(String.init)
        if values.count < 3 {
            throw NSError(domain: "GameWebToken", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JWT format"])
        }
        print(values.map(\.base64DecodedString))
        let data: [Data] = values.compactMap(\.base64DecodedString).compactMap({ $0.data(using: .utf8) })
        let decoder: JSONDecoder = .init()
        decoder.dateDecodingStrategy = .secondsSince1970
        self.header = try! decoder.decode(Header.self, from: data[0])
        self.payload = try! decoder.decode(Payload.self, from: data[1])
        self.signature = values[2]
    }
    
    public var isRefreshNeeded: Bool {
        Date.now.timeIntervalSince1970 > TimeInterval(payload.exp)
    }
    
    public struct Header: Codable, Sendable {
        public let alg: String
        public let jku: URL
        public let kid: String
        public let typ: String
    }
    
    public struct Payload: Codable, Sendable {
        public let isChildRestricted: Bool
        public let aud: String
        public let exp: Int
        public let iat: Int
        public let iss: String
        public let jti: UUID
        public let sub: Int
        public let links: Links
        public let typ: String
        public let membership: Membership
    }
    
    public struct Membership: Codable, Sendable {
        public let active: Bool
    }
    
    public struct Links: Codable, Sendable {
        public let networkServiceAccount: ServiceAccount
    }
    
    public struct ServiceAccount: Codable, Sendable {
        public let id: String
    }
}
