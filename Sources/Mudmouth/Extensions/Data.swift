//
//  Data.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

extension Data {
    init(buffer: [UInt8]) {
        var tmp: [UInt8] = buffer
        // swiftlint:disable:next legacy_objc_type
        self.init(referencing: NSData(bytes: &tmp, length: tmp.count))
    }

    var bytes: [UInt8] {
        [UInt8](self)
    }

    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }
}
