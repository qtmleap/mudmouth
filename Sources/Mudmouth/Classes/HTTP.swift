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
import SwiftData

// protocol HTTPMessage {
//    var headers: HTTP.Parameters { get }
//    var data: Data? { get set}
// }

// MARK: - HTTP

// public enum HTTP {
//    public typealias Parameters = [Parameter]
//
//    @Model
//    public struct Parameter {
//        public var key: String
//        public var value: String
//
//        public init?(key: String, value: String) {
//            self.key = key
//            self.value = value
//        }
//    }
//
//    struct Message {
//        var request: Request
//        var response: Response?
//
//        init(request: Request) {
//            self.request = request
//        }
//    }
//
//    @Model
//    class Request: HTTPMessage {
//        var path: String
//        var headers: Parameters
//        var data: Data?
//
//        init(head: HTTPRequestHead) {
//            self.path = head.uri
//            self.headers = head.dictionaryObject
//            self.data = nil
//        }
//
//        var body: Parameters {
//            guard let data: Data = try? data?.gunzipped(),
//                  let objects: [String: Any] = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
//            else {
//                return []
//            }
//            return objects.compactMap { object in
//                guard let value: String = object.value as? String
//                else {
//                    return nil
//                }
//                return .init(key: object.key, value: value)
//            }
//        }
//
//        func add(_ buffer: ByteBuffer) {
//            if data == nil {
//                data = buffer.data
//            } else {
//                data?.append(contentsOf: buffer.data)
//            }
//        }
//    }
//
//    @Model
//    class Response: HTTPMessage {
//        var headers: Parameters
//        var data: Data?
//
//        init(head: HTTPResponseHead) {
//            self.headers = head.dictionaryObject
//            self.data = nil
//        }
//
//        func add(_ buffer: ByteBuffer) {
//            if data == nil {
//                data = buffer.data
//            } else {
//                data?.append(contentsOf: buffer.data)
//            }
//        }
//    }
// }
//
// extension HTTPRequestHead {
//    var dictionaryObject: HTTP.Parameters {
//        headers.compactMap { .init(key: $0.name, value: $0.value) }
//    }
// }
//
// extension HTTPResponseHead {
//    var dictionaryObject: HTTP.Parameters {
//        headers.compactMap { .init(key: $0.name, value: $0.value) }
//    }
// }
//
// extension HTTPHeaders {
//    var data: Data {
//        let dictionary: Dictionary = .init(uniqueKeysWithValues: map { ($0.name, $0.value) })
//        return try! JSONSerialization.data(withJSONObject: dictionary)
//    }
// }
//
// extension HTTP.Parameters {
//    var base64EncodedString: String {
//        let encoder: JSONEncoder = .init()
//        // swiftlint:disable:next force_try
//        return try! encoder.encode(self).base64EncodedString()
//    }
// }
