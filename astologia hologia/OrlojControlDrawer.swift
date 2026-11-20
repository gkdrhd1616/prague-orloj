//
//  OrlojControlDrawer.swift
//  astologia hologia
//
//  Created by Shubeu on 5/6/26.
//

import SwiftUI

struct OrlojControlDrawer: View {
    let state: OrlojClockState?
    let readout: OrlojAstronomyReadout?
    @Binding var timeState: OrlojTimeState
    @Binding var locationState: OrlojLocationState
    @Binding var isPresented: Bool
    @Binding var selectedTab: OrlojDrawerTab
    @Binding var dialFocus: OrlojDialFocusState
    let isLocating: Bool
    let locationStatusMessage: String
    let selectLocationMode: (OrlojLocationMode) -> Void
    let confirmManualLocation: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            if readout != nil {
                Picker("Drawer tab", selection: $selectedTab) {
                    ForEach(OrlojDrawerTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("drawerTabPicker")
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }

            Divider()
                .overlay(OrlojDesignSystem.textMuted.opacity(0.28))

            ScrollView(showsIndicators: false) {
                Group {
                    if let readout {
                        switch selectedTab {
                        case .settings:
                            settingsTab
                        case .astronomy:
                            astronomyTab(readout)
                        case .guide:
                            guideTab
                        }
                    } else {
                        locationSettingsSection
                    }
                }
                .padding(20)
            }
        }
        .font(.system(.body, design: .rounded))
        .foregroundStyle(OrlojDesignSystem.text)
        .tint(OrlojDesignSystem.highlightGold)
        .background(OrlojDesignSystem.ink.opacity(0.97), in: RoundedRectangle(cornerRadius: OrlojDesignSystem.drawerCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OrlojDesignSystem.drawerCornerRadius, style: .continuous)
                .stroke(OrlojDesignSystem.textMuted.opacity(0.24), lineWidth: 1)
        }
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Astologia Hologia")
                    .font(.headline)
                    .foregroundStyle(OrlojDesignSystem.text)

                if let readout {
                    Text("\(readout.localDate) · \(readout.locationName)")
                        .font(.caption)
                        .foregroundStyle(OrlojDesignSystem.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
            }

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.24)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .foregroundStyle(OrlojDesignSystem.text)
            .background(OrlojDesignSystem.ink.opacity(0.58), in: Circle())
            .accessibilityLabel("Close controls")
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            timeSettingsSection

            Divider()
                .overlay(OrlojDesignSystem.textMuted.opacity(0.24))

            locationSettingsSection

            Divider()
                .overlay(OrlojDesignSystem.textMuted.opacity(0.24))

            currentBasisSection

            Divider()
                .overlay(OrlojDesignSystem.textMuted.opacity(0.24))

            displaySettingsSection
        }
    }

    private var timeSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DrawerSectionTitle("Time")

            SettingsChoiceRow(
                title: "Live now",
                detail: "Use the current clock time.",
                systemImage: "clock.arrow.circlepath",
                isActive: timeState.mode == .live
            ) {
                timeState.useLiveNow()
            }

            SettingsChoiceRow(
                title: "Manual time",
                detail: "Choose the moment represented by the dial.",
                systemImage: "calendar",
                isActive: timeState.mode == .manual
            ) {
                timeState.useManual(state?.date ?? .now)
            }

            if timeState.mode == .manual {
                DatePicker(
                    "Manual moment",
                    selection: momentSelection,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .environment(\.calendar, selectedCalendar)
                .environment(\.timeZone, selectedTimeZone)
                .datePickerStyle(.compact)
            }
        }
    }

    private var locationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DrawerSectionTitle("Location mode")

            SettingsChoiceRow(
                title: OrlojLocationMode.prague.title,
                detail: "Canonical Old Town Hall reconstruction mode.",
                systemImage: "building.columns",
                isActive: locationState.mode == .prague
            ) {
                selectLocationMode(.prague)
            }

            SettingsChoiceRow(
                title: OrlojLocationMode.device.title,
                detail: isLocating ? "Checking device location..." : "Personal sky from a one-time device location request.",
                systemImage: "location.viewfinder",
                isActive: locationState.mode == .device || isLocating
            ) {
                selectLocationMode(.device)
            }
            .disabled(isLocating)

            SettingsChoiceRow(
                title: OrlojLocationMode.manual.title,
                detail: "Personal sky from city, coordinate, and timezone controls.",
                systemImage: "slider.horizontal.3",
                isActive: locationState.mode == .manual
            ) {
                selectLocationMode(.manual)
            }

            Text(locationStatusMessage)
                .font(.caption2)
                .foregroundStyle(OrlojDesignSystem.textMuted)

            if locationState.mode == .manual {
                manualLocationControls
                if state == nil {
                    Button("Use these coordinates", action: confirmManualLocation)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var manualLocationControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("City preset", selection: manualPresetSelection) {
                Text("Custom").tag("custom")
                Text("Prague").tag(OrlojClockLocation.prague.id)
                Text("Seoul").tag(OrlojClockLocation.seoul.id)
            }
            .pickerStyle(.menu)

            Picker("Time Zone", selection: timeZoneSelection) {
                Text("Prague").tag(OrlojClockLocation.prague.timeZone.identifier)
                Text("Seoul").tag(OrlojClockLocation.seoul.timeZone.identifier)
                Text("Device").tag(TimeZone.current.identifier)
                Text("UTC").tag("UTC")
            }
            .pickerStyle(.menu)

            SettingNumberField(
                title: "Latitude",
                systemImage: "arrow.up.and.down",
                value: latitudeSelection,
                range: -90...90,
                step: 0.1
            )

            SettingNumberField(
                title: "Longitude",
                systemImage: "arrow.left.and.right",
                value: longitudeSelection,
                range: -180...180,
                step: 0.1
            )
        }
        .padding(12)
        .background(OrlojDesignSystem.ink.opacity(0.28), in: RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous))
    }

    private var currentBasisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DrawerSectionTitle("Current basis")

            Text("Mode: \(locationState.conceptualModeTitle)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OrlojDesignSystem.text)

            Text(locationState.conceptualModeDetail)
                .font(.caption2)
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Label(locationTitle, systemImage: "mappin.and.ellipse")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OrlojDesignSystem.text)

            Text(locationCoordinateSummary)
                .font(.caption)
                .foregroundStyle(OrlojDesignSystem.textMuted)

            Text("Basis: \(locationState.basis.label) · \(locationState.precisionLabel)")
                .font(.caption2)
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var displaySettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DrawerSectionTitle("Display")

            InstrumentControlRow(
                title: "Viewing mode",
                detail: dialFocus.mode.rawValue,
                systemImage: "eye"
            ) {
                Text(dialFocus.mode.detail)
                    .font(.caption2)
                    .foregroundStyle(OrlojDesignSystem.textMuted)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160, alignment: .trailing)
            }

            Picker("Viewing mode", selection: dialModeSelection) {
                Text("Display").tag(OrlojDialMode.display)
                if dialFocus.mode == .guide {
                    Text("Guide").tag(OrlojDialMode.guide)
                }
                Text("Debug").tag(OrlojDialMode.debug)
            }
            .pickerStyle(.segmented)

            if dialFocus.mode == .guide, dialFocus.focus != .all {
                Button {
                    showWholeDial()
                } label: {
                    Label("Return to Display", systemImage: "eye")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bordered)
                .tint(OrlojDesignSystem.gold)
            }

            Picker("Layer focus", selection: displayFocusSelection) {
                ForEach(OrlojLayerFocus.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func astronomyTab(_ readout: OrlojAstronomyReadout) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                DrawerSectionTitle("Current readout")
                Spacer()
                if shouldShowFocusReset {
                    focusResetButton
                }
            }

            ForEach(readout.primaryMetrics) { metric in
                let targetFocus = focusTarget(for: metric)
                InteractiveReadoutMetricRow(
                    metric: metric,
                    targetFocus: targetFocus,
                    isSelected: isReadoutSelected(metric),
                    learnAction: learnAction(for: metric)
                ) {
                    highlight(metric)
                }
            }

            Divider()
                .overlay(OrlojDesignSystem.textMuted.opacity(0.24))

            DrawerSectionTitle("Astronomy")

            ForEach(readout.astronomyMetrics) { metric in
                let targetFocus = focusTarget(for: metric)
                InteractiveReadoutMetricRow(
                    metric: metric,
                    targetFocus: targetFocus,
                    isSelected: isReadoutSelected(metric),
                    learnAction: learnAction(for: metric)
                ) {
                    highlight(metric)
                }
            }
        }
    }

    private var guideTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                DrawerSectionTitle("Reading guide")
                Spacer()
                if shouldShowFocusReset {
                    focusResetButton
                }
            }

            if let selectedGuideItem {
                SelectedGuideCard(item: selectedGuideItem)

                Divider()
                    .overlay(OrlojDesignSystem.textMuted.opacity(0.24))
            }

            ForEach(guideItems) { item in
                GuideTopicRow(
                    item: item,
                    isSelected: dialFocus.activeGuideItemId == item.id && dialFocus.mode == .guide
                ) {
                    inspect(item)
                }
            }
        }
    }

    private var focusResetButton: some View {
        Button {
            showWholeDial()
        } label: {
            Label("Return to Display", systemImage: "eye")
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .foregroundStyle(OrlojDesignSystem.textMuted)
        .accessibilityIdentifier("focusResetButton")
        .accessibilityHint("Returns to the finished display mode and hides guide callouts")
    }

    private var shouldShowFocusReset: Bool {
        dialFocus.mode != .display
    }

    private var locationTitle: String {
        "\(locationState.label) · \(locationState.timezone)"
    }

    private var locationCoordinateSummary: String {
        "\(locationState.coordinates.latitudeLabel), \(locationState.coordinates.longitudeLabel)"
    }

    private var guideItems: [OrlojResolvedGuideItem] {
        guard let readout else { return [] }
        return OrlojGuideCatalog.resolvedItems(readout: readout)
    }

    private var selectedGuideItem: OrlojResolvedGuideItem? {
        guard let readout else { return nil }
        return OrlojGuideCatalog.resolvedItem(for: dialFocus.activeGuideItemId, readout: readout)
    }

    private func inspect(_ item: OrlojResolvedGuideItem) {
        withAnimation(.snappy(duration: 0.2)) {
            dialFocus = .guide(item: item)
        }
    }

    private func showWholeDial() {
        withAnimation(.snappy(duration: 0.2)) {
            dialFocus = .display
        }
    }

    private func highlight(_ metric: OrlojReadoutMetric) {
        guard let item = guideItem(for: metric) else {
            withAnimation(.snappy(duration: 0.2)) {
                selectedTab = .settings
                dialFocus = .display
            }
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            dialFocus = .readout(item: item)
        }
    }

    private func openGuide(for metric: OrlojReadoutMetric) {
        guard let item = guideItem(for: metric) else {
            selectedTab = .settings
            return
        }

        withAnimation(.snappy(duration: 0.2)) {
            selectedTab = .guide
            dialFocus = .guide(item: item)
        }
    }

    private func learnAction(for metric: OrlojReadoutMetric) -> (() -> Void)? {
        guard metric.guideTopic != nil else {
            return nil
        }

        return {
            openGuide(for: metric)
        }
    }

    private func isReadoutSelected(_ metric: OrlojReadoutMetric) -> Bool {
        guard dialFocus.mode == .guide,
              let item = guideItem(for: metric) else {
            return false
        }

        return dialFocus.targetLayers == item.targetLayerSet
    }

    private func guideItem(for metric: OrlojReadoutMetric) -> OrlojResolvedGuideItem? {
        guard let topic = metric.guideTopic else {
            return nil
        }

        return guideItems.first { $0.id == topic }
    }

    private func focusTarget(for metric: OrlojReadoutMetric) -> OrlojLayerFocus {
        guideItem(for: metric)?.focus ?? .all
    }

    private var momentSelection: Binding<Date> {
        Binding(
            get: { timeState.resolvedDate(liveDate: state?.date ?? .now) },
            set: {
                timeState.useManual($0)
            }
        )
    }

    private var timeZoneSelection: Binding<String> {
        Binding(
            get: { locationState.timezone },
            set: {
                locationState.updateTimeZone($0)
            }
        )
    }

    private var manualPresetSelection: Binding<String> {
        Binding(
            get: { manualPresetID },
            set: { presetID in
                switch presetID {
                case OrlojClockLocation.prague.id:
                    locationState.applyManualPreset(.prague)
                case OrlojClockLocation.seoul.id:
                    locationState.applyManualPreset(.seoul)
                default:
                    locationState.markManual()
                }
            }
        )
    }

    private var manualPresetID: String {
        guard locationState.mode == .manual else {
            return "custom"
        }
        if locationState.coordinates == OrlojClockLocation.prague.coordinates,
           locationState.timezone == OrlojClockLocation.prague.timeZone.identifier {
            return OrlojClockLocation.prague.id
        }
        if locationState.coordinates == OrlojClockLocation.seoul.coordinates,
           locationState.timezone == OrlojClockLocation.seoul.timeZone.identifier {
            return OrlojClockLocation.seoul.id
        }
        return "custom"
    }

    private var dialModeSelection: Binding<OrlojDialMode> {
        Binding(
            get: {
                dialFocus.mode
            },
            set: { mode in
                switch mode {
                case .display:
                    dialFocus = .display
                case .guide:
                    if dialFocus.mode != .guide {
                        dialFocus = .manualFocus(dialFocus.focus)
                    }
                case .debug:
                    dialFocus = .debug
                }
            }
        )
    }

    private var displayFocusSelection: Binding<OrlojLayerFocus> {
        Binding(
            get: { dialFocus.focus },
            set: { focus in
                dialFocus = .manualFocus(focus)
            }
        )
    }

    private var latitudeSelection: Binding<Double> {
        Binding(
            get: { locationState.latitude },
            set: {
                locationState.updateLatitude($0)
            }
        )
    }

    private var longitudeSelection: Binding<Double> {
        Binding(
            get: { locationState.longitude },
            set: {
                locationState.updateLongitude($0)
            }
        )
    }

    private var selectedTimeZone: TimeZone {
        locationState.timeZone
    }

    private var selectedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = selectedTimeZone
        return calendar
    }
}

private struct DrawerSectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .foregroundStyle(OrlojDesignSystem.textMuted)
            .accessibilityIdentifier("section-\(title)")
    }
}

private struct InstrumentControlRow<Accessory: View>: View {
    let title: String
    let detail: String
    let systemImage: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(OrlojDesignSystem.text)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(OrlojDesignSystem.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            accessory
        }
    }
}

private struct SettingsChoiceRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    private var titleColor: Color {
        isActive ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.text
    }

    private var detailColor: Color {
        isActive ? OrlojDesignSystem.text.opacity(0.86) : OrlojDesignSystem.textMuted
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(titleColor)

                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(detailColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isActive ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.textMuted)
        .background(
            isActive ? OrlojDesignSystem.gold.opacity(0.16) : OrlojDesignSystem.ink.opacity(0.34),
            in: RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous)
                .stroke(OrlojDesignSystem.gold.opacity(isActive ? 0.34 : 0.16), lineWidth: 1)
        }
        .accessibilityIdentifier("settingsChoice-\(title)")
    }
}

private struct InteractiveReadoutMetricRow: View {
    let metric: OrlojReadoutMetric
    let targetFocus: OrlojLayerFocus
    let isSelected: Bool
    let learnAction: (() -> Void)?
    let action: () -> Void

    private var isPrimary: Bool {
        metric.prominence == .primary
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: metric.systemImage)
                .font(.system(size: isPrimary ? 17 : 14, weight: .semibold))
                .foregroundStyle(isSelected ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.textMuted)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: isPrimary ? 4 : 2) {
                HStack(spacing: 6) {
                    Text(metric.title)
                        .font(isPrimary ? .caption : .caption2)
                        .foregroundStyle(OrlojDesignSystem.textMuted)

                    if isSelected {
                        Image(systemName: targetFocus.systemImage)
                            .font(.caption2)
                            .foregroundStyle(OrlojDesignSystem.highlightGold)
                    }
                }

                Text(metric.value)
                    .font(.system(isPrimary ? .headline : .subheadline, design: .rounded, weight: isPrimary ? .semibold : .medium))
                    .foregroundStyle(OrlojDesignSystem.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 12)

            Text(metric.detail)
                .font(isPrimary ? .caption : .caption2)
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)

            if let learnAction {
                Button(action: learnAction) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .accessibilityLabel("Learn about \(metric.title)")
                .accessibilityIdentifier("learn-\(metric.title)")
            }
        }
        .padding(.vertical, isPrimary ? 8 : 5)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous)
                    .fill(OrlojDesignSystem.gold.opacity(0.10))
            }
        }
        .onTapGesture(perform: action)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("readout-\(metric.title)")
        .accessibilityHint("Highlights \(targetFocus.rawValue) on the dial")
    }
}

private struct SettingNumberField: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    private var constrainedValue: Binding<Double> {
        Binding(
            get: { value },
            set: { value = $0.clamped(to: range) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(OrlojDesignSystem.textMuted)

            HStack(spacing: 10) {
                TextField(title, value: constrainedValue, format: .number.precision(.fractionLength(3)))
                    .textFieldStyle(.roundedBorder)
                    .monospacedDigit()

                Stepper(title, value: constrainedValue, in: range, step: step)
                    .labelsHidden()
            }
        }
    }
}

private struct SelectedGuideCard: View {
    let item: OrlojResolvedGuideItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(item.title, systemImage: item.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(OrlojDesignSystem.highlightGold)

            if let currentValue = item.currentValue {
                Text("Current: \(currentValue)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(OrlojDesignSystem.text)
            }

            Text(item.shortDescription)
                .font(.caption2)
                .foregroundStyle(OrlojDesignSystem.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(OrlojDesignSystem.ink.opacity(0.34), in: RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous)
                .stroke(OrlojDesignSystem.textMuted.opacity(0.22), lineWidth: 1)
        }
        .accessibilityIdentifier("selectedGuideCard-\(item.id.rawValue)")
        .accessibilityElement(children: .combine)
    }
}

private struct GuideTopicRow: View {
    let item: OrlojResolvedGuideItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.textMuted)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.text)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(OrlojDesignSystem.text.opacity(0.78))
                    }

                    Text(item.shortDescription)
                        .font(.caption2)
                        .foregroundStyle(OrlojDesignSystem.textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    if let currentValue = item.currentValue {
                        Text(currentValue)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(isSelected ? OrlojDesignSystem.highlightGold : OrlojDesignSystem.text.opacity(0.82))
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: OrlojDesignSystem.controlCornerRadius, style: .continuous)
                        .fill(OrlojDesignSystem.gold.opacity(0.10))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("guideTopic-\(item.id.rawValue)")
        .accessibilityHint("Shows this element on the dial")
    }
}
