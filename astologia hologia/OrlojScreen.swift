//
//  OrlojScreen.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import SwiftUI

struct OrlojScreen: View {
    let state: OrlojClockState?
    let readout: OrlojAstronomyReadout?
    @Binding var timeState: OrlojTimeState
    @Binding var locationState: OrlojLocationState
    @Binding var isDrawerPresented: Bool
    @Binding var selectedDrawerTab: OrlojDrawerTab
    @Binding var dialFocus: OrlojDialFocusState
    let isLocating: Bool
    let locationStatusMessage: String
    let selectLocationMode: (OrlojLocationMode) -> Void
    var confirmManualLocation: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            let safeSize = CGSize(
                width: max(1, proxy.size.width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing),
                height: max(1, proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
            )
            let clockSide = min(safeSize.width, safeSize.height) * 0.92
            let drawerWidth = min(safeSize.width - 32, min(max(safeSize.width * 0.43, 360), 460))

            ZStack {
                OrlojBackdrop()

                if let state {
                    OrlojClockView(state: state, dialFocus: dialFocus)
                        .frame(width: clockSide, height: clockSide)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        .shadow(color: .black.opacity(0.44), radius: 26, y: 18)
                } else {
                    ContentUnavailableView {
                        Label("Choose a location", systemImage: "location")
                    } description: {
                        Text(locationStatusMessage)
                    } actions: {
                        Button("Location settings") {
                            selectedDrawerTab = .settings
                            isDrawerPresented = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .foregroundStyle(OrlojDesignSystem.text)
                }

                VStack {
                    HStack {
                        Button {
                            withAnimation(.snappy(duration: 0.28)) {
                                isDrawerPresented.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 52, height: 52)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(OrlojDesignSystem.gold)
                        .background(OrlojDesignSystem.ink.opacity(0.72), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(OrlojDesignSystem.gold.opacity(0.3), lineWidth: 1)
                        }
                        .accessibilityLabel("Open controls")

                        Spacer()
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                if isDrawerPresented {
                    Color.black.opacity(0.34)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.24)) {
                                isDrawerPresented = false
                            }
                        }

                    HStack(spacing: 0) {
                        OrlojControlDrawer(
                            state: state,
                            readout: readout,
                            timeState: $timeState,
                            locationState: $locationState,
                            isPresented: $isDrawerPresented,
                            selectedTab: $selectedDrawerTab,
                            dialFocus: $dialFocus,
                            isLocating: isLocating,
                            locationStatusMessage: locationStatusMessage,
                            selectLocationMode: selectLocationMode,
                            confirmManualLocation: confirmManualLocation
                        )
                        .frame(width: drawerWidth)
                        .padding(.vertical, 18)
                        .padding(.leading, 18)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

private struct OrlojBackdrop: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let longSide = max(size.width, size.height)
            let shortSide = min(size.width, size.height)

            context.fill(Path(rect), with: .color(OrlojDesignSystem.stoneDeep))
            context.fill(Path(rect), with: .radialGradient(
                Gradient(colors: [
                    OrlojDesignSystem.stone.opacity(0.36),
                    OrlojDesignSystem.background.opacity(0.78),
                    OrlojDesignSystem.ink.opacity(0.98)
                ]),
                center: center,
                startRadius: shortSide * 0.16,
                endRadius: longSide * 0.72
            ))
        }
        .ignoresSafeArea()
    }
}
