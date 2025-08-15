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
import SwiftyLogger
import UserNotifications

final class ProxyHandler: NotificationHandler, ChannelDuplexHandler {
    // MARK: Internal

    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPClientRequestPart
    typealias OutboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    private let targets: [ProxyTarget]

    init(targets: [ProxyTarget] = []) {
        self.targets = targets
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        switch httpData {
            case let .head(head):
                if let host: String = head.host,
                   let target: ProxyTarget = targets.first(where: { $0.host == host }),
                   target.path == head.path
                {
                    NSLog("Received request: \(head)")
                    requests.append(.init(head: head))
                }
                if let host: String = head.host,
                   let target: ProxyTarget = targets.first(where: { $0.host == host }) {}
                context.fireChannelRead(wrapInboundOut(.head(head)))

            case let .body(body):
                context.fireChannelRead(wrapInboundOut(.body(.byteBuffer(body))))

            case .end:
                context.fireChannelRead(wrapInboundOut(.end(nil)))
        }
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let httpData = unwrapOutboundIn(data)
        switch httpData {
            case let .head(head):
                context.write(wrapOutboundOut(.head(head)), promise: promise)

            case let .body(body):
                if let request: HTTP.Request = requests.first {
                    request.add(body)
                }
                context.write(wrapOutboundOut(.body(.byteBuffer(body))), promise: promise)

            case .end:
                if let request: HTTP.Request = requests.popFirst() {
                    let headers = request.headers.base64EncodedString
                    // BodyはGzipでエンコードされているので、デコードして返す
                    // NOTE: エンコードされていないときは知らないです
                    let body = request.body.base64EncodedString
                    let path = request.path
                    // データを処理して通知を送信し、アプリにデータを渡す
                    // NOTE: とりあえずヘッダーとレスポンスをBASE64でエンコードして全部返している
                    // このデータが有ればとりあえず困ることはなさそう
                    Task(priority: .background, operation: {
                        let content: UNMutableNotificationContent = .init()
                        content.title = NSLocalizedString("UNNOTIFICATION_REQUEST_TITLE", bundle: .module, comment: "")
                        content.body = NSLocalizedString("UNNOTIFICATION_REQUEST_BODY", bundle: .module, comment: "")
                        content.userInfo = [
                            "headers": headers,
                            "body": body,
                            "path": path,
                        ]
                        NSLog("Notification headers: \(headers)")
                        NSLog("Notification body: \(body)")
                        let triger: UNTimeIntervalNotificationTrigger = .init(timeInterval: 1, repeats: false)
                        let request: UNNotificationRequest = .init(
                            identifier: UUID().uuidString, content: content, trigger: triger,
                        )
                        try await UNUserNotificationCenter.current().add(request)
                    })
                }
                context.write(wrapOutboundOut(.end(nil)), promise: promise)
        }
    }

    func channelInactive(context _: ChannelHandlerContext) {}

    // MARK: Private

    private let url: URL = .init(unsafeString: "https://api.lp1.av5ja.srv.nintendo.net/api/bullet_tokens")
    private var requests: Deque<HTTP.Request> = []
    private let decoder: JSONDecoder = .init()
}
