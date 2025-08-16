//
//  Record.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/16.
//

import Foundation
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
    var _headers: Data
    var _body: Data?
    public var host: RecordGroup?

    init(head: HTTPRequestHead) {
        id = UUID()
        method = head.method.rawValue
        path = head.uri
        _headers = head.headers.data
        _body = nil
    }

    public var headers: [HTTPHeader] {
        guard let headers = try? JSONSerialization.jsonObject(with: _headers) as? [String: String]
        else {
            return []
        }
        return headers.map { .init(key: $0.key, value: $0.value) }.sorted(by: { $0.key < $1.key })
    }

    public var body: [String: Any]? {
        guard let data = _body else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }
}

public struct HTTPHeader: Identifiable, Hashable {
    public var id: String { key }
    public let key: String
    public let value: String
}
