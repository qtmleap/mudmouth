//
//  CertificateView.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/12.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import SwiftUI

struct CertificateView: View {
    @Environment(Mudmouth.self) private var manager
    @State private var isPresented: Bool = false

    var body: some View {
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
                LabeledContent(NSLocalizedString("CERTIFICATE_VARIDATION", bundle: .module, comment: ""), content: {
                    CheckStatus(manager.certificate.isValid(privateKey: manager.privateKey))
                })
            }, header: {
                Text("HEADER_KEY_INFORMATION", bundle: .module)
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
    }
}

#Preview {
    CertificateView()
        .environment(Mudmouth())
}
