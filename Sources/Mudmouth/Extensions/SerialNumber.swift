//
//  SerialNumber.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation
import X509

extension Certificate.SerialNumber {
    static var `default`: Certificate.SerialNumber {
        .init()
    }
}
