//
//  UNUserNotificationCenter.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/12.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import Foundation

// @preconcurrency
import UserNotifications

// extension UNUserNotificationCenter:
//    func getNotificationSettings() async throws -> UNNotificationSettings {
//        await withCheckedContinuation({ continuation in
//            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
//                continuation.resume(returning: settings)
//            })
//        })
//    }
// }
//

extension UNNotificationSettings: @unchecked Sendable {}
