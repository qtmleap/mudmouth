//
//  Array.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

extension [UInt8] {
    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }

    var data: Data {
        .init(buffer: self)
    }
}
