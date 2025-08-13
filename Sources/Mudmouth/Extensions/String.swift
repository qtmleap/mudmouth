//
//  String.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/13.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

public extension String {
    var base64DecodedString: String? {
        guard let data: Data = .init(base64Encoded: self)
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
