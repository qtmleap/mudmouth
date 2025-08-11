//
//  KeyPairAuthority.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import SwiftUI
import Crypto
import X509
import NIO
import SwiftASN1
import KeychainAccess

protocol KeyPairAuthority {
    var keychain: Keychain { get }
//    func generateKeyPair() -> KeyPair
}

extension KeyPairAuthority {
    var keychain: Keychain {
        Keychain(server: "https://api.lp1.av5ja.srv.nintendo.net", protocolType: .https)
    }
}
