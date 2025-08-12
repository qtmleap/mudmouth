//
//  CertificateHandler.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/12.
//

import Foundation
import NIOCore
import NIOHTTP1
import X509

/// X509証明書をインストールするためのChannelInboundHandler
/// PacketTunnelには直接関与しない
class CertificateHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let certificate: Certificate

    init(certificate: Certificate) {
        self.certificate = certificate
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let httpData = unwrapInboundIn(data)
        guard case .head = httpData else {
            return
        }
        let pemString: String = certificate.pemRepresentation
        let headers: HTTPHeaders = .init([
            ("Content-Length", pemString.count.formatted()),
            ("Content-Type", "application/x-x509-ca-cert"),
        ])
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .ok, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        let buffer: ByteBuffer = context.channel.allocator.buffer(string: pemString)
        let body: HTTPServerResponsePart = .body(.byteBuffer(buffer))
        context.writeAndFlush(wrapOutboundOut(body), promise: nil)
    }
}

extension HTTPResponseEncoder: @unchecked @retroactive Sendable {}

extension ByteToMessageHandler: @unchecked @retroactive Sendable {}
