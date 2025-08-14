//
//  FirstLaunchView.swift
//  Mudmouth
//
//  Created by devonly on 2025/08/13.
//  Copyright © 2025 QuantumLeap, Corporation. All rights reserved.
//

import BetterSafariView
import SwiftUI
import SwiftUIIntrospect

public struct FirstLaunchView: View {
    @Environment(Mudmouth.self) private var mudmouth: Mudmouth
    @Environment(\.dismiss) var dismiss
    @State private var selection: Int = 0
    @State private var isPresented: Bool = false
    private let proxy: X509Proxy = .default

    var isEnabled: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        switch selection {
            case 1:
            mudmouth.isAPPInstalled
            case 2:
            mudmouth.isAuthorized
            case 3:
            true
            case 4:
            mudmouth.isVerified
            case 5:
            mudmouth.isTrusted
            case 6:
            mudmouth.isVPNInstalled
            case 7:
            mudmouth.isConnected
            default:
            true
        }
        #endif
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selection, content: {
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_APP_NAME", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Logo", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_APP_NAME", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(0)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_INSTALL_NINTENDO_APP", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Nintendo", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_INSTALL_NINTENDO_APP", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(1)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_ALLOW_NOTIFICATION", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Notification", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_ALLOW_NOTIFICATION", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(2)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_DOWNLOAD_VPN_PROFILE", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Download", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_DOWNLOAD_VPN_PROFILE", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(3)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_INSTALL_VPN_PROFILE", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Certificate", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_INSTALL_VPN_PROFILE", bundle: .module)
                })
            })
            .tag(4)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_TRUST_CERTIFICATE", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Verified", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_TRUST_CERTIFICATE", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(5)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_INSTALL_VPN", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("VPN", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_INSTALL_VPN", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(6)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_TEST_TOGGLE_VPN", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Activate", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_TEST_TOGGLE_VPN", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(7)
            FirstLaunch(content: {
                VStack(content: {
                    Text("TITLE_TEST_OPEN_APP", bundle: .module)
                        .font(.title)
                        .fontWeight(.bold)
                    Image("Start", bundle: .module)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .padding()
                    Text("DESCRIPTION_TEST_OPEN_APP", bundle: .module)
                        .padding(.horizontal)
                })
            })
            .tag(8)
        })
        .disabled(true)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .multilineTextAlignment(.center)
        .overlay(alignment: .bottom, content: {
            VStack(content: {
                switch selection {
                    case 1:
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://apps.apple.com/app/id1234806557")!)
                        }, label: {
                            Text("BUTTON_OPEN_APP_STORE", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 2:
                        Button(action: {
                            Task(priority: .background, operation: {
                                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
                            })
                        }, label: {
                            Text("BUTTON_ALLOW_NOTIFICATION", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 3:
                        Group(content: {
                            Button(action: {
                                mudmouth.generateCAKeyPair()
                            }, label: {
                                Text("BUTTON_GENERATE_CERTIFICATE", bundle: .module)
                                    .fontWeight(.bold)
                                    .frame(width: 300, height: 40)
                            })
                            Button(action: {
                                isPresented.toggle()
                            }, label: {
                                Text("BUTTON_DOWNLOAD_PROFILE", bundle: .module)
                                    .fontWeight(.bold)
                                    .frame(width: 300, height: 40)
                            })
                        })
                    case 4:
                        Button(action: {
                            UIApplication.shared.open(URL(string: "App-prefs:General&path=ManagedConfigurationList/VPN")!)
                        }, label: {
                            Text("BUTTON_OPEN_VPN_SETTINGS", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 5:
                        Button(action: {
                            UIApplication.shared.open(URL(string: "App-prefs:General&path=About/CERT_TRUST_SETTINGS")!)
                        }, label: {
                            Text("BUTTON_TRUST_CERTIFICATE", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 6:
                        Button(action: {
                            Task(priority: .background, operation: {
                                try await mudmouth.installVPN()
                            })
                        }, label: {
                            Text("BUTTON_INSTALL_VPN", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 7:
                        Button(action: {
                            Task(priority: .background, operation: {
                                try await mudmouth.startVPNTunnel()
                            })
                        }, label: {
                            Text("BUTTON_ACTIVATE_VPN", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    case 8:
                        Button(action: {
                            UIApplication.shared.open(URL(string: "com.nintendo.znca://")!)
                        }, label: {
                            Text("BUTTON_OPEN_APP", bundle: .module)
                                .fontWeight(.bold)
                                .frame(width: 300, height: 40)
                        })
                    default:
                        EmptyView()
                }
                Button(action: {
                    withAnimation(.spring) {
                        selection != 8 ? selection += 1 : dismiss()
                    }
                }, label: {
                    Text(selection == 8 ? "BUTTON_END" : "BUTTON_NEXT", bundle: .module)
                        .fontWeight(.bold)
                        .frame(width: 300, height: 40)
                        .buttonStyle(.borderedProminent)
                })
                .buttonStyle(.borderedProminent)
                .disabled(!isEnabled)
            })
            .buttonStyle(.borderedProminent)
        })
        .sheet(isPresented: $isPresented, content: {
            SafariView(url: .init(string: "http://127.0.0.1:8888")!)
                .onAppear(perform: {
                    Task(priority: .background, operation: {
                        try proxy.start()
                    })
                })
                .onDisappear(perform: {
                    Task(priority: .background, operation: {
                        try proxy.stop()
                    })
                })
        })
    }
}

struct FirstLaunch<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader(content: { geometry in
            VStack(content: {
                content()
                Spacer()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, geometry.size.height * 0.2)
            .padding(.horizontal)
        })
    }
}

#Preview {
    FirstLaunchView()
        .environment(\.locale, .init(identifier: "ja"))
        .environment(Mudmouth())
}
