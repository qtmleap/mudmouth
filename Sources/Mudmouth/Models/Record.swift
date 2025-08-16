//
//  Record.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/16.
//

import Foundation
import NIOCore
import NIOHTTP1
import SwiftData

@Model
public final class RecordGroup: Identifiable {
    @Attribute(.unique)
    public var host: String

    @Relationship(deleteRule: .cascade, inverse: \Record.host)
    public var records: [Record]

    init(host: String, records: [Record]) {
        self.host = host
        self.records = records
    }
}

@Model
public final class Record: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var method: String
    public var path: String
    public var host: RecordGroup?
    @Relationship(deleteRule: .cascade)
    public var request: HTTP.Request
    @Relationship(deleteRule: .cascade)
    public var response: HTTP.Response

    init(container: HTTP.MessageContainer) {
        id = .init()
        method = container.request.method
        path = container.request.path
        request = container.request
        response = container.response
    }
}

public enum HTTP {
    public protocol Message {
        var header: Data { get }
        var data: Data? { get set }
        var body: String? { get }

        var headers: [HTTP.Header] { get }
    }

    struct MessageContainer: Sendable {
        var request: HTTP.Request
        /// ないってことはないと思う
        var response: HTTP.Response!
    }

    public struct Header: Hashable {
        public let key: String
        public let value: String
    }

    @Model
    public class Request: HTTP.Message, @unchecked Sendable {
        @Attribute(.unique)
        public var id: UUID
        public var host: String
        public var path: String
        public var header: Data
        public var method: String
        public var data: Data?

        init(head: HTTPRequestHead) {
            id = .init()
            host = head.host!
            path = head.uri
            method = head.method.rawValue
            header = head.headers.data
            data = nil
        }

        func add(_ buffer: ByteBuffer) {
            if data == nil {
                data = buffer.data
            } else {
                data?.append(contentsOf: buffer.data)
            }
        }
    }

    @Model
    public class Response: HTTP.Message, @unchecked Sendable {
        @Attribute(.unique)
        public var id: UUID
        public var header: Data
        public var data: Data?

        init(head: HTTPResponseHead) {
            id = .init()
            header = head.headers.data
            data = nil
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

public extension HTTP.Message {
    var headers: [HTTP.Header] {
        guard let headers = try? JSONSerialization.jsonObject(with: header) as? [String: String]
        else {
            return []
        }
        return headers.map { .init(key: $0.key, value: $0.value) }.sorted(by: { $0.key < $1.key })
    }

    var encoding: String? {
        guard let value = headers.first(where: { $0.key.lowercased() == "content-encoding" })?.value
        else {
            return nil
        }
        return value.lowercased()
    }

    var body: String? {
        guard let data else { return nil }
        if encoding == "gzip" {
            guard let data = try? data.gunzipped() else {
                return nil
            }
            guard let object = try? JSONSerialization.jsonObject(with: data),
                  let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

// @Model
// public final class Record: Identifiable {
//    @Attribute(.unique) public var id: UUID
//    public var method: String
//    public var path: String
//    public var host: RecordGroup?
//    @Relationship(deleteRule: .cascade)
//    var request: Request
//    @Relationship(deleteRule: .cascade)
//    var response: Response
//
//    init(request: Request, response: Response) {
//        self.id = .init()
//        self.method = request.method
//        self.path = request.path
//        self.request = request
//        self.response = response
//    }

//    public var headers: [HTTPHeader] {
//        guard let headers = try? JSONSerialization.jsonObject(with: _headers) as? [String: String]
//        else {
//            return []
//        }
//        return headers.map { .init(key: $0.key, value: $0.value) }.sorted(by: { $0.key < $1.key })
//    }
//
//    public var body: [String: Any]? {
//        guard let data = _body else { return nil }
//        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
//    }
// }
//

public struct HTTPHeader: Identifiable, Hashable {
    public var id: String { key }
    public let key: String
    public let value: String
}

extension HTTPHeaders {
    var dictionary: [String: String] {
        Dictionary(map { ($0.name, $0.value) }, uniquingKeysWith: +)
    }

    var data: Data {
        try! JSONSerialization.data(withJSONObject: dictionary)
    }
}

// extension HTTP.Headers { public var values: [HTTPHeader] {
//        map { ($0.key, $0.value) }.sorted(by: { $0.0 < $1.0 })
//    }
// }

// extension HTTPRequestHead {
//    var dictionaryObject: Parameters {
//        headers.compactMap { .init(key: $0.name, value: $0.value) }
//    }
// }
//
// extension HTTPResponseHead {
//    var dictionaryObject: Parameters {
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
// extension Parameters {
//    var base64EncodedString: String {
//        let encoder: JSONEncoder = .init()
//        // swiftlint:disable:next force_try
//        return try! encoder.encode(self).base64EncodedString()
//    }
// }
//
