//
//  Request.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/16.
//

import CoreData
import Foundation
import NIOHTTP1

@objc(Request)
public class Request: NSManagedObject, Identifiable {}

public extension Request {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Request> {
        NSFetchRequest<Request>(entityName: "Request")
    }

    internal convenience init(context: NSManagedObjectContext, head: HTTPRequestHead) {
        let entity = NSEntityDescription.entity(forEntityName: "Request", in: context)!
        self.init(entity: entity, insertInto: context)
        date = .now
        host = head.host!
        path = head.path
        method = head.method.rawValue
        headers = head.headers.data
        body = nil
    }

    @NSManaged
    var id: UUID

    @NSManaged
    var host: String

    @NSManaged
    var path: String

    @NSManaged
    var method: String

    @NSManaged
    var date: Date

    @NSManaged
    var headers: Data?

    @NSManaged
    var body: Data?
}
