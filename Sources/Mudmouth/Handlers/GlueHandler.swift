//
//  GlueHandler.swift
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

final class GlueHandler: ChannelDuplexHandler {
    // MARK: Internal

    typealias InboundIn = NIOAny
    typealias OutboundIn = NIOAny
    typealias OutboundOut = NIOAny

    static func matchedPair() -> (GlueHandler, GlueHandler) {
        let first = GlueHandler()
        let second = GlueHandler()

        first.partner = second
        second.partner = first

        return (first, second)
    }

    func handlerAdded(context: ChannelHandlerContext) {
        self.context = context
    }

    func handlerRemoved(context _: ChannelHandlerContext) {
        context = nil
        partner = nil
    }

    func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        partner?.partnerWrite(data)
    }

    func channelReadComplete(context _: ChannelHandlerContext) {
        partner?.partnerFlush()
    }

    func channelInactive(context _: ChannelHandlerContext) {
        partner?.partnerCloseFull()
    }

    func channelWritabilityChanged(context: ChannelHandlerContext) {
        if context.channel.isWritable {
            partner?.partnerBecameWritable()
        }
    }

    func userInboundEventTriggered(context _: ChannelHandlerContext, event: Any) {
        if let event = event as? ChannelEvent, case .inputClosed = event {
            partner?.partnerWriteEOF()
        }
    }

    func errorCaught(context _: ChannelHandlerContext, error _: Error) {
        partner?.partnerCloseFull()
    }

    func read(context: ChannelHandlerContext) {
        if let partner, partner.partnerWritable {
            context.read()
        } else {
            pendingRead = true
        }
    }

    // MARK: Private

    private var partner: GlueHandler?
    private var context: ChannelHandlerContext?
    private var pendingRead = false

    private var partnerWritable: Bool {
        context?.channel.isWritable ?? false
    }

    private func partnerWrite(_ data: NIOAny) {
        context?.write(data, promise: nil)
    }

    private func partnerFlush() {
        context?.flush()
    }

    private func partnerWriteEOF() {
        context?.close(mode: .output, promise: nil)
    }

    private func partnerCloseFull() {
        context?.close(promise: nil)
    }

    private func partnerBecameWritable() {
        if pendingRead {
            pendingRead = false
            context?.read()
        }
    }
}
