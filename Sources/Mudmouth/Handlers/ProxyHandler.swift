//
//  ProxyHandler.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import DequeModule
import Foundation
import NIOCore
import NIOHTTP1
import NIOPosix
import NIOSSL
import OSLog
import SwiftData
import SwiftyLogger
import UserNotifications

final class ProxyHandler: NotificationHandler, ChannelDuplexHandler {
    // MARK: Internal

    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPClientRequestPart
    typealias OutboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    private let options: [ProxyOption]

    init(options: [ProxyOption] = []) {
        self.options = options
    }

    private var queues: Deque<HTTP.MessageContainer> = []

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        switch httpData {
            case let .head(head):
                queues.append(.init(request: .init(head: head)))
//                if let host: String = head.host,
//                   let target: ProxyTarget = targets.first(where: { $0.host == host }),
//                   target.path == head.path
//                {
//                    NSLog("Received request: \(head)")
//                    requests.append(.init(head: head))
//                }
//                if let host: String = head.host,
//                   let target: ProxyTarget = targets.first(where: { $0.host == host })
//                {
//                    Task(operation: { @MainActor in
//                        do {
//                            let context: ModelContext = ModelContainer.default.mainContext
//                            let record: Record = .init(head: head)
//                            context.insert(record)
//                            context.insert(RecordGroup(host: host, records: [record]))
//                            try context.save()
//                            NSLog("Model Context: Saved request for \(host) at path \(head.path)")
//                        } catch {
//                            NSLog("Model Context: \(error)")
//                        }
//                    })
//                }
                context.fireChannelRead(wrapInboundOut(.head(head)))

            case let .body(body):
                queues.last?.request.add(body)
//                self.request?.add(body)
                context.fireChannelRead(wrapInboundOut(.body(.byteBuffer(body))))

            case .end:
                context.fireChannelRead(wrapInboundOut(.end(nil)))
        }
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let httpData = unwrapOutboundIn(data)
        switch httpData {
            case let .head(head):
                if var queue = queues.popFirst() {
                    queue.response = .init(head: head)
                    queues.prepend(queue)
                }
//                self.queues.first?.response = .init(head: head)
                context.write(wrapOutboundOut(.head(head)), promise: promise)

            case let .body(body):
                if var message = queues.popFirst() {
                    message.response?.add(body)
                    queues.prepend(message)
                }
//                self.queues.first?.response.add(body)
//                if let request: HTTP.Request = requests.first {
//                    request.add(body)
//                }
                context.write(wrapOutboundOut(.body(.byteBuffer(body))), promise: promise)

            case .end:
                if let queue = queues.popFirst() {
                    /// ホストが含まれていればキャプチャする
                    if options.map(\.host).contains(queue.request.host) {
                        NSLog("[Capture] Request: \(queue.request)")
                        Task(operation: { @MainActor in
                            let context: ModelContext = ModelContainer.default.mainContext
                            let record: Record = .init(container: queue)
                            context.insert(record)
                            context.insert(RecordGroup(host: queue.request.host, records: [record]))
                            try? context.save()
                        })
                    }
                    /// ホストの通知設定が有効かつ、通知を飛ばすパスなら通知を飛ばす
                    if let option = options.first(where: { $0.host == queue.request.host }),
                       option.notify,
                       option.targets(keyPath: \.notify).contains(URL(string: queue.request.path)!.path)
                    {
                        NSLog("[Notify] Request: \(queue.request)")
                        Task(operation: { @MainActor in
                            let content: UNMutableNotificationContent = .init()
                            content.title = NSLocalizedString("UNNOTIFICATION_REQUEST_TITLE", bundle: .module, comment: "")
                            content.body = NSLocalizedString("UNNOTIFICATION_REQUEST_BODY", bundle: .module, comment: "")
                            content.userInfo = [
                                "headers": queue.request.header.base64EncodedString(),
                                "body": queue.response.data?.base64EncodedString(),
                                "path": queue.request.path,
                            ]
                            let triger: UNTimeIntervalNotificationTrigger = .init(timeInterval: 1, repeats: false)
                            let request: UNNotificationRequest = .init(
                                identifier: UUID().uuidString, content: content, trigger: triger,
                            )
                            try await UNUserNotificationCenter.current().add(request)
                        })
                    }
                }

                //                if let queue = self.queues.popFirst() {
//                Task(priority: .background) { [queues] in
//                    var localQueues = queues
//                    await MainActor.run {
//                        if let queue = localQueues.popFirst() {
//                            let record: Record = .init(container: queue)
//                            let context: ModelContext = ModelContainer.default.mainContext
//                            context.insert(record)
//                            context.insert(RecordGroup(host: queue.request.host, records: [record]))
//                            try? context.save()
//                        }
//                    }
//                }
                //                    Task(priority: .background) { @MainActor in
//                        NSLog("Request: \(queue.request)")
//                        NSLog("Response: \(queue.response)")
//                        let record: Record = .init(container: queue)
//                        await MainActor.run {
//                            self.context.insert(record)
//                            self.context.insert(RecordGroup(host: queue.request.host, records: [record]))
//                        }
//                    }
//                }
                //                if let request: HTTP.Request = requests.popFirst() {
//                    let headers = request.headers.base64EncodedString
//                    // BodyはGzipでエンコードされているので、デコードして返す
//                    // NOTE: エンコードされていないときは知らないです
//                    let body = request.body.base64EncodedString
//                    let path = request.path
//                    // データを処理して通知を送信し、アプリにデータを渡す
//                    // NOTE: とりあえずヘッダーとレスポンスをBASE64でエンコードして全部返している
//                    // このデータが有ればとりあえず困ることはなさそう
//                    Task(priority: .background, operation: {
//                        let content: UNMutableNotificationContent = .init()
//                        content.title = NSLocalizedString("UNNOTIFICATION_REQUEST_TITLE", bundle: .module, comment: "")
//                        content.body = NSLocalizedString("UNNOTIFICATION_REQUEST_BODY", bundle: .module, comment: "")
//                        content.userInfo = [
//                            "headers": headers,
//                            "body": body,
//                            "path": path,
//                        ]
//                        NSLog("Notification headers: \(headers)")
//                        NSLog("Notification body: \(body)")
//                        let triger: UNTimeIntervalNotificationTrigger = .init(timeInterval: 1, repeats: false)
//                        let request: UNNotificationRequest = .init(
//                            identifier: UUID().uuidString, content: content, trigger: triger,
//                        )
//                        try await UNUserNotificationCenter.current().add(request)
//                    })
//                }
                context.write(wrapOutboundOut(.end(nil)), promise: promise)
        }
    }

    func channelInactive(context _: ChannelHandlerContext) {}
}
