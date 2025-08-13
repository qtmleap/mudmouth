//
//  ProxyTarget.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/13.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

public struct ProxyTarget: Codable {
    public let host: String
    public let path: String
    public let script: String? = nil

    public init(url: URL) {
        host = url.host!
        path = url.path
    }

    public init(url value: String) {
        let url: URL = .init(unsafeString: value)
        host = url.host!
        path = url.path
    }
}

extension [ProxyTarget] {
    var hosts: [String] {
        map(\.host)
    }

    var data: Data {
        let encoder: JSONEncoder = .init()
        return try! encoder.encode(self)
    }
}
