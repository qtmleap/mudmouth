//
//  PersistenceController.swift
//  Interceptor
//
//  Created by devonly on 2025/08/16.
//  Copyright © 2025 QuantumLeap. All rights reserved.
//

import CoreData

public struct PersistenceController: Sendable {
    public static let `default`: PersistenceController = .init()
    private let bundleIdentifier = "group.jp.qleap.intrcptr"
    let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        NSLog("Initializing PersistenceController with inMemory: \(inMemory)")
        NSLog("Bundle Identifier: \(bundleIdentifier)")
        guard let modelURL = Bundle.module.url(forResource: "Mudmouth", withExtension: "momd")
        else {
            fatalError("Could not find Mudmouth.momd in bundle.")
        }
        container = .init(name: "Mudmouth")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = .init(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        })
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: bundleIdentifier)
        else {
            fatalError("Could not find container URL for app group.")
        }
        let url = containerURL.appendingPathComponent("Mudmouth.sqlite")
        let description = NSPersistentStoreDescription(url: url)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { _, error in
            if let error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
