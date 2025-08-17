//
//  CertificateView.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/12.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import SwiftUI

public struct CertificateView: View {
    @Environment(Mudmouth.self) private var manager
    @State private var isPresented: Bool = false

    public init() {}

    public var body: some View {
        Form(content: {
            Section(content: {
                LabeledContent(NSLocalizedString("ORGANIZATION", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.orgnization)
                })
                LabeledContent(NSLocalizedString("COMMON_NAME", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.commonName)
                })
                LabeledContent(NSLocalizedString("NOT_VALID_BEFORE", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.notValidBefore.formatted())
                        .monospacedDigit()
                })
                LabeledContent(NSLocalizedString("NOT_VALID_AFTER", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.notValidAfter.formatted())
                        .monospacedDigit()
                })
            }, header: {
                Text("HEADER_GENERAL", bundle: .module)
            })
            Section(content: {
                LabeledContent(NSLocalizedString("ALGORITHM", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.signature.description)
                })
                LabeledContent(NSLocalizedString("CERTIFICATE_SHA256_HASH", bundle: .module, comment: ""), content: {
                    Text(manager.certificate.sha256Hash)
                        .monospaced()
                        .lineLimit(1)
                })
                LabeledContent(NSLocalizedString("PUBLIC_KEY_DATA", bundle: .module, comment: ""), content: {
                    Text(manager.privateKey.publicKey.derBytes.hexString)
                        .monospaced()
                        .lineLimit(1)
                })
                LabeledContent(NSLocalizedString("PRIVATE_KEY_DATA", bundle: .module, comment: ""), content: {
                    Text(manager.privateKey.derBytes.hexString)
                        .monospaced()
                        .lineLimit(1)
                })
            }, header: {
                Text("HEADER_KEY_INFORMATION", bundle: .module)
            })
            Section(content: {
                LabeledContent(NSLocalizedString("CERTIFICATE_VERIFIED", bundle: .module, comment: ""), content: {
                    CheckStatus(manager.certificate.isValid(privateKey: manager.privateKey))
                })
                LabeledContent(NSLocalizedString("CERTIFICATE_INSTALLED", bundle: .module, comment: ""), content: {
                    CheckStatus(manager.isVerified)
                })
                LabeledContent(NSLocalizedString("CERTIFICATE_TRUSTED", bundle: .module, comment: ""), content: {
                    CheckStatus(manager.isTrusted)
                })
            }, header: {
                Text("HEADER_CERTIFICATE_VALIDATION", bundle: .module)
            }, footer: {
                Text("FOOTER_CERTIFICATE_VALIDATION", bundle: .module)
            })
            Section(content: {
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Text("GENERATE_NEW_CERTIFICATE", bundle: .module)
                })
                .confirmationDialog(NSLocalizedString("DIALOG_REGENERATE_CERTIFICATE_TITLE", bundle: .module, comment: ""), isPresented: $isPresented, titleVisibility: .visible, actions: {
                    Button(role: .cancel, action: {}, label: {
                        Text("ACTION_CANCEL", bundle: .module)
                    })
                    Button(role: .destructive, action: {
                        manager.generateCAKeyPair()
                    }, label: {
                        Text("ACTION_REVOKE_CERTIFICATE", bundle: .module)
                    })
                })
            }, header: {
                Text("HEADER_CERTIFICATE_UTILS", bundle: .module)
            })
        })
        .navigationTitle(Text("TITLE_CERTIFICATE"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView(content: {
        CertificateView()
    })
    .environment(Mudmouth.default)
}
