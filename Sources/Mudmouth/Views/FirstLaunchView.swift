//
//  FirstLaunchView.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/11.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import BetterSafariView
import SwiftUI

struct CheckStatus: View {
    let status: Bool

    init(_ status: Bool) {
        self.status = status
    }

    var body: some View {
        Image(systemName: status ? "checkmark" : "xmark")
            .foregroundStyle(status ? .green : .red)
            .fontWeight(.bold)
    }
}

public struct ConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isPresented: Bool = false
    @State private var isEnabled: Bool = false
    private var manager: Mudmouth = .init()
    private var proxy: X509Proxy = .default

    public init() {}

    public var body: some View {
        Form(content: {
            Section(content: {
                Button(action: {
                    Task(priority: .background, operation: {
                        UIApplication.shared.open(URL(string: "https://apps.apple.com/app/id1234806557")!)
                    })
                }, label: {
                    LabeledContent(content: {
                        CheckStatus(manager.isNSOInstalled)
                    }, label: {
                        Label(NSLocalizedString("LABEL_INSTALL_NSO", bundle: .module, comment: ""), systemImage: "switch.2")
                    })
                })
                Button(action: {
                    UIApplication.shared.open(URL(string: "com.nintendo.znca://znca/game/4834290508791808")!)
                }, label: {
                    Label(NSLocalizedString("LABEL_OPEN_NSO", bundle: .module, comment: ""), systemImage: "link")
                })
            }, header: {
                Text("HEADER_NSO", bundle: .module)
            }, footer: {
                Text("FOOTER_NSO", bundle: .module)
            })
            Section(content: {
                Button(action: {
                    Task(priority: .background, operation: {
                        try await manager.installVPN()
                    })
                }, label: {
                    LabeledContent(content: {
                        CheckStatus(manager.isInstalled)
                    }, label: {
                        Label(NSLocalizedString("LABEL_INSTALL_VPN", bundle: .module, comment: ""), systemImage: "lock.shield.fill")
                    })
                })
                LabeledContent(content: {
                    CheckStatus(manager.isConnected)
                }, label: {
                    Label(NSLocalizedString("LABEL_CONNECTION_STATUS_VPN", bundle: .module, comment: ""), systemImage: "network")
                })
                Toggle(isOn: $isEnabled, label: {
                    Text(NSLocalizedString("LABEL_TOGGLE_VPN", bundle: .module, comment: ""))
                })
            }, header: {
                Text("HEADER_VPN", bundle: .module)
            }, footer: {
                Text("FOOTER_VPN", bundle: .module)
            })
            Section(content: {
                Button(action: {
                    manager.generateCAKeyPair()
                }, label: {
                    Label(NSLocalizedString("LABEL_GENERATE_CERT", bundle: .module, comment: ""), systemImage: "key.fill")
                })
                Button(action: {
                    isPresented.toggle()
                }, label: {
                    Label(NSLocalizedString("LABEL_DOWNLOAD_CERT", bundle: .module, comment: ""), systemImage: "square.and.arrow.down.fill")
                })
                Button(action: {
                    UIApplication.shared.open(URL(string: "App-prefs:General&path=ManagedConfigurationList/VPN")!)
                }, label: {
                    LabeledContent(content: {
                        CheckStatus(manager.isVerified)
                    }, label: {
                        Label(NSLocalizedString("LABEL_VERIFY_CERT", bundle: .module, comment: ""), systemImage: "checkmark.seal.fill")
                    })
                })
                Button(action: {
                    UIApplication.shared.open(URL(string: "App-prefs:General&path=About/CERT_TRUST_SETTINGS")!)
                }, label: {
                    LabeledContent(content: {
                        CheckStatus(manager.isTrusted)
                    }, label: {
                        Label(NSLocalizedString("LABEL_TRUST_CERT", bundle: .module, comment: ""), systemImage: "checkmark.shield.fill")
                    })
                })
                Button(action: {
                    UIApplication.shared.open(URL(string: "com.nintendo.znca://znca/game/4834290508791808")!)
                }, label: {
                    Label(NSLocalizedString("LABEL_OPEN", bundle: .module, comment: ""), systemImage: "link")
                })
            }, header: {
                Text("HEADER_CERT", bundle: .module)
            }, footer: {
                Text("FOOTER_CERT", bundle: .module)
            })
            Button(action: {
                dismiss()
            }, label: {
                Text("LABEL_DONE", bundle: .module)
            })
        })
        .onChange(of: isEnabled, perform: { value in
            if value {
                Task(priority: .background, operation: {
                    try await manager.startVPNTunnel()
                })
            }
        })
//        .onAppear(perform: {
//            Task(priority: .background, operation: {
//                try await manager.stopVPNTunnel()
//            })
//        })
        .sheet(isPresented: $isPresented, content: {
            SafariView(url: proxy.url)
                .onAppear(perform: {
                    try? proxy.start()
                })
                .onDisappear(perform: {
                    try? proxy.stop()
                })
        })
        .navigationTitle("TITLE_CONFIGURATION")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ConfigurationView()
}
