//
//  HTTP.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation
import Gzip
import NIOCore
import NIOHTTP1

// MARK: - HTTP

enum HTTP {
    typealias Parameters = [Parameter]

    struct Parameter: Codable {
        let key: String
        let value: String

        init?(key: String, value: String) {
            self.key = key
            self.value = value
        }
    }

    class Request {
        // MARK: Lifecycle

        init(head: HTTPRequestHead) {
            path = head.uri
            headers = head.dictionaryObject
            data = nil
        }

        // MARK: Internal

        let path: String
        let headers: Parameters
        var data: Data?

        var body: Parameters {
            guard let data: Data = try? data?.gunzipped(),
                  let objects: [String: Any] = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                return []
            }
            return objects.compactMap { object in
                guard let value: String = object.value as? String
                else {
                    return nil
                }
                return .init(key: object.key, value: value)
            }
        }

        func add(_ buffer: ByteBuffer) {
            if data == nil {
                data = buffer.data
            } else {
                data?.append(contentsOf: buffer.data)
            }
        }
    }
}

extension HTTPRequestHead {
    var dictionaryObject: HTTP.Parameters {
        headers.compactMap { .init(key: $0.name, value: $0.value) }
    }
}

extension HTTP.Parameters {
    var base64EncodedString: String {
        let encoder: JSONEncoder = .init()
        // swiftlint:disable:next force_try
        return try! encoder.encode(self).base64EncodedString()
    }
}
