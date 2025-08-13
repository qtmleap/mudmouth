//
//  HTTPRequestHead.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/13.
//

import Foundation
import NIOHTTP1

extension HTTPRequestHead {
    var host: String? {
        headers.first(name: "Host")
    }

    var path: String {
        URL(unsafeString: uri).path
    }
}
