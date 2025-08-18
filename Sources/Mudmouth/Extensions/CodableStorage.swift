//
//  CodableStorage.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/18.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation
import SwiftUI

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        let decoder: JSONDecoder = .init()
        guard let data = rawValue.data(using: .utf8),
              let value = try? decoder.decode([Element].self, from: data)
        else {
            return nil
        }
        self = value
    }

    public var rawValue: String {
        let encoder: JSONEncoder = .init()
        guard let data = try? encoder.encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
