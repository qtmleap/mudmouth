//
//  ModelContainer.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/16.
//

import Foundation
import SwiftData

public extension ModelContainer {
    static let `default`: ModelContainer = {
        let bundleIdentifier = "group.jp.qleap.intrcptr"
        NSLog("Using app group identifier: \(bundleIdentifier)")
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: bundleIdentifier)
        guard let container
        else {
            fatalError("Could not find container URL for app group.")
        }

        let dbURL: URL = container.appendingPathComponent("Mudmouth.sqlite")
        // #if DEBUG
//        // デバッグビルド時に永続ストアをリセット
//        let fileManager = FileManager.default
//        if fileManager.fileExists(atPath: dbURL.path) {
//            do {
//                try fileManager.removeItem(at: dbURL)
//                NSLog("Persistent store reset successfully (DEBUG mode).")
//            } catch {
//                fatalError("Failed to reset persistent store: \(error)")
//            }
//        }
        // #endif
        let config: ModelConfiguration = .init(url: dbURL)
        return try! ModelContainer(for: RecordGroup.self, Record.self, configurations: config)
    }()
}
