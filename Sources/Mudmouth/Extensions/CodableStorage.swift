//
//  CodableStorage.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/18.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftyLogger

@propertyWrapper
public struct CodableStorage<Value: Codable>: DynamicProperty {
    @AppStorage
    private var value: Data
    private var key: String

    private let decoder: JSONDecoder = .init()
    private let encoder: JSONEncoder = .init()

    public init(wrappedValue: Value, _ key: String, store: UserDefaults = .standard) {
        guard let data: Data = try? encoder.encode(wrappedValue)
        else {
            fatalError("Failed to encode initial value for CodableStorage")
        }
//        UserDefaults.standard.set(data, forKey: key)
        _value = .init(wrappedValue: data, key, store: store)
        self.key = key
    }

    public var wrappedValue: Value {
        get {
            try! decoder.decode(Value.self, from: value)
        }
        nonmutating set {
            value = try! encoder.encode(newValue)
        }
    }

    public var projectedValue: Binding<Value> {
        Binding<Value>(
            get: {
                wrappedValue
            },
            set: { newValue in
                wrappedValue = newValue
                if let data: Data = try? encoder.encode(newValue) {
                    SwiftyLogger.debug("Storing \(key) in UserDefaults")
                    UserDefaults.standard.set(data, forKey: key)
                }
            },
        )
    }
}
