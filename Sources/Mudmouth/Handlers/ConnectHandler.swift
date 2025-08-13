//
//  ConnectHandler.swift
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

final class ConnectHandler: ChannelInboundHandler {
    // MARK: Internal

    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private func awaitingEnd(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        if case .end = httpData {
            // Upgrade to TLS server.
            // swiftlint:disable:next closure_body_length
            context.pipeline.context(handlerType: ByteToMessageHandler<HTTPRequestDecoder>.self)
                // swiftlint:disable:next closure_body_length
                .whenSuccess { handler in
                    context.pipeline.removeHandler(context: handler, promise: nil)
                    ClientBootstrap(group: context.eventLoop)
                        .channelInitializer { channel in
                            let clientConfiguration = TLSConfiguration.makeClientConfiguration()
                            // swiftlint:disable:next force_try
                            let sslClientContext = try! NIOSSLContext(configuration: clientConfiguration)
                            return channel.pipeline.addHandler(
                                // swiftlint:disable:next force_unwrapping force_try
                                try! NIOSSLClientHandler(context: sslClientContext, serverHostname: self.host!),
                            )
                            .flatMap { _ in
                                channel.pipeline.addHandler(HTTPRequestEncoder())
                            }
                            .flatMap { _ in
                                channel.pipeline.addHandler(
                                    ByteToMessageHandler(HTTPResponseDecoder(leftOverBytesStrategy: .forwardBytes)))
                            }
                        }
                        // swiftlint:disable:next force_unwrapping
                        .connect(host: self.host!, port: self.port!)
                        .whenComplete { result in
                            switch result {
                                case let .success(client):
                                    // Send 200 to downstream.
                                    let headers = HTTPHeaders([("Content-Length", "0")])
                                    let head = HTTPResponseHead(
                                        version: .init(major: 1, minor: 1), status: .ok, headers: headers,
                                    )
                                    context.write(self.wrapOutboundOut(.head(head)), promise: nil)
                                    context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                                    context.pipeline.context(handlerType: HTTPResponseEncoder.self).whenSuccess { handler in
                                        context.pipeline.removeHandler(context: handler, promise: nil)
                                        let (localGlue, remoteGlue) = GlueHandler.matchedPair()
                                        context.pipeline.addHandler(localGlue)
                                            .and(client.pipeline.addHandler(remoteGlue))
                                            .whenComplete { result in
                                                switch result {
                                                    case .success:
                                                        self.state = .established
                                                    case let .failure(failure):
                                                        SwiftyLogger.error(failure)
                                                        context.close(promise: nil)
                                                }
                                            }
                                    }

                                case let .failure(failure):
                                    NSLog("Interceptor: Failed to connect to \(self.host!):\(self.port!): \(failure)")
                                    // Send 404 to downstream.
                                    let headers = HTTPHeaders([("Content-Length", "0")])
                                    let head = HTTPResponseHead(
                                        version: .init(major: 1, minor: 1), status: .notFound, headers: headers,
                                    )
                                    context.write(self.wrapOutboundOut(.head(head)), promise: nil)
                                    context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                            }
                        }
                }
        }
    }

    private func idle(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        guard case let .head(head) = httpData else {
            return
        }
        guard head.method == .CONNECT else {
            // Send 405 to downstream.
            let headers = HTTPHeaders([("Content-Length", "0")])
            let head = HTTPResponseHead(
                version: .init(major: 1, minor: 1), status: .methodNotAllowed, headers: headers,
            )
            context.write(wrapOutboundOut(.head(head)), promise: nil)
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
            return
        }
        let components = head.uri.split(separator: ":")
        host = String(components[0])
        // swiftlint:disable:next force_unwrapping
        port = Int(components[1])!
        state = .awaitingEnd
    }

    // swiftlint:disable:next function_body_length
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch state {
            case .idle:
                idle(context: context, data: data)
            case .awaitingEnd:
                awaitingEnd(context: context, data: data)
            case .established:
                // Forward data to the next channel.
                context.fireChannelRead(data)
        }
    }

    // MARK: Private

    private enum State {
        case idle
        case awaitingEnd
        case established
    }

    private var state: State = .idle
    private var host: String?
    private var port: Int?
}
