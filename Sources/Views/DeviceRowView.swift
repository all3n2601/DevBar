import DevBarCore
import SwiftUI

struct DeviceRowView: View {
    let device: Device
    @ObservedObject var manager: DeviceManager

    @AppStorage("favoriteDeviceIDs") private var favorites = ""
    @State private var confirmingErase = false
    @State private var actionEditor: String?
    @State private var actionValue = ""
    @State private var showingActionEditor = false
    @State private var isPulseActive = false
    @State private var isHovered = false
    @State private var isTargetedForDrop = false

    // Toast UI states
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var toastTimer: Timer?
    @State private var isInstalling = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Control Row
            HStack(spacing: 12) {
                // Platform Icon Badge
                ZCornerIcon(platform: device.platform)

                // Name and Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(device.displayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)

                    Text(device.displayOS)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                // State Indicator & Controls
                HStack(spacing: 10) {
                    stateBadge

                    controlButton
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Expanded Actions Tray (only when booted)
            if device.state == .booted {
                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.horizontal, 8)

                actionTrayView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            ZStack {
                // Translucent drop target glow
                if isTargetedForDrop {
                    RoundedRectangle(cornerRadius: 10)
                        .fill((device.platform == .ios ? Color.pink : Color.green).opacity(0.12))
                }

                // Toast notifications overlay
                if showToast {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.bgCard)
                        .overlay(
                            HStack(spacing: 6) {
                                Image(systemName: toastMessage.contains("failed") || toastMessage.contains("Incompatible") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(toastMessage.contains("failed") || toastMessage.contains("Incompatible") ? Color.orange : Theme.activeGreen)

                                Text(toastMessage)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        )
                        .transition(.opacity)
                        .zIndex(10)
                }

                // Package installation progress overlay
                if isInstalling {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.bgCard.opacity(0.9))
                        .overlay(
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)

                                Text("Installing Build Package...")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        )
                        .zIndex(11)
                }
            }
        )
        .glassmorphic(cornerRadius: 10)
        .overlay(
            Group {
                if isTargetedForDrop {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            device.platform == .ios ? Theme.iosGradient : Theme.androidGradient,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [4, 3])
                        )
                }
            }
        )
        .confirmationDialog("Erase \(device.name)?", isPresented: $confirmingErase, titleVisibility: .visible) {
            Button("Erase All Simulator Data", role: .destructive) { manager.wipeDevice(device) }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This deletes installed apps and all data on this simulator.") }
        .sheet(isPresented: $showingActionEditor) {
            VStack(alignment: .leading, spacing: 12) {
                Text(actionEditor == "launch" ? "Launch App on \(device.name)" : "Open Link on \(device.name)")
                    .font(.headline)
                TextField(actionEditor == "launch" ? "com.example.myapp" : "myapp://screen", text: $actionValue)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") { showingActionEditor = false }
                    Spacer()
                    Button("Run") {
                        let value = actionValue
                        let action = actionEditor
                        showingActionEditor = false
                        DispatchQueue.global(qos: .userInitiated).async {
                            do {
                                if action == "launch" { try DeviceService().launch(device, app: value) }
                                else { try DeviceService().openURL(device, url: value) }
                                DispatchQueue.main.async { showRowToast(message: "Command completed.") }
                            } catch {
                                DispatchQueue.main.async { manager.lastError = error.localizedDescription }
                            }
                        }
                    }.disabled(actionValue.isEmpty)
                }
            }.padding(20).frame(width: 320)
        }
        .contextMenu {
            if device.state == .booted {
                Button("Launch App…") { actionValue = ""; actionEditor = "launch"; showingActionEditor = true }
                Button("Open Deep Link…") { actionValue = ""; actionEditor = "url"; showingActionEditor = true }
                Divider()
            }
            Button("Copy Device ID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(device.id, forType: .string)
            }
            Button(favorites.split(separator: "|").contains(Substring(device.id)) ? "Remove Favorite" : "Add Favorite") {
                var ids = Set(favorites.split(separator: "|").map(String.init))
                if ids.contains(device.id) { ids.remove(device.id) } else { ids.insert(device.id) }
                favorites = ids.sorted().joined(separator: "|")
            }
        }
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hover
            }
        }
        // Enable build installation via Drag and Drop
        .onDrop(of: ["public.file-url"], isTargeted: $isTargetedForDrop) { providers in
            handleDrop(providers: providers)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var stateBadge: some View {
        switch device.state {
        case .booted:
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.activeGreen)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isPulseActive ? 1.3 : 1.0)
                    .opacity(isPulseActive ? 0.6 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: isPulseActive
                    )
                    .onAppear { isPulseActive = true }

                Text("Running")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.activeGreen)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Theme.activeGreen.opacity(0.12))
            .cornerRadius(6)

        case .booting:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.mini)

                Text("Booting...")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.bootingOrange)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Theme.bootingOrange.opacity(0.12))
            .cornerRadius(6)

        case .shutdown:
            Text("Shutdown")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
        }
    }

    @ViewBuilder
    private var controlButton: some View {
        switch device.state {
        case .shutdown:
            Button(action: { manager.bootDevice(device) }) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient, isCircular: true))

        case .booted:
            Button(action: { manager.shutdownDevice(device) }) {
                Image(systemName: "square.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(nsColor: NSColor(calibratedRed: 0.95, green: 0.25, blue: 0.25, alpha: 1.0)))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(PremiumButtonStyle(isCircular: true))
            .disabled(device.isPhysical)

        case .booting:
            Button(action: {}) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.3)
                    .frame(width: 24, height: 24)
            }
            .disabled(true)
            .buttonStyle(PremiumButtonStyle(isCircular: true))
        }
    }

    private var actionTrayView: some View {
        HStack(spacing: 8) {
            // Drag Drop Zone Helper label
            Label {
                Text("Drop build to install")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            } icon: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.03))
            .cornerRadius(6)

            Spacer()

            // Action Buttons
            HStack(spacing: 6) {
                // Take Screenshot Button
                Button(action: triggerScreenshot) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .help("Take Screenshot (Copies to Clipboard)")

                // Record Video Button
                let isRecording = manager.activeRecordings.contains(device.id)
                Button(action: toggleRecording) {
                    ZStack {
                        if isRecording {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 7, height: 7)
                                .scaleEffect(isPulseActive ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulseActive)
                        } else {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.red)
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .help(isRecording ? "Stop Screen Recording" : "Start Screen Recording")

                // Deep Wipe/Erase Button
                Button(action: triggerWipe) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .help("Erase Simulator Data")
                .disabled(device.platform != .ios || manager.activeRecordings.contains(device.id))
            }
        }
    }

    // MARK: - Actions Helper Logic

    private func triggerScreenshot() {
        manager.takeScreenshot(for: device) { success, msg in
            showRowToast(message: msg)
        }
    }

    private func toggleRecording() {
        let isRecording = manager.activeRecordings.contains(device.id)
        if isRecording {
            manager.stopRecording(for: device) { success, msg in
                showRowToast(message: msg)
            }
        } else {
            manager.startRecording(for: device) { success, msg in
                showRowToast(message: msg)
            }
        }
    }

    private func triggerWipe() {
        confirmingErase = true
    }

    private func showRowToast(message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.25)) {
            showToast = true
        }

        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
            guard let data = data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let filePath = url.path

            // Validate compatibility
            let isIosBuild = filePath.hasSuffix(".app")
            let isAndroidBuild = filePath.hasSuffix(".apk")

            DispatchQueue.main.async {
                if (device.platform == .ios && isIosBuild) || (device.platform == .android && isAndroidBuild) {
                    isInstalling = true
                    manager.installApp(filePath: filePath, to: device) { success, msg in
                        isInstalling = false
                        showRowToast(message: msg)
                    }
                } else {
                    showRowToast(message: "Incompatible build type dropped!")
                }
            }
        }
        return true
    }
}

// Custom decorative icon for platforms
struct ZCornerIcon: View {
    let platform: DevicePlatform

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(platform == .ios ? Theme.iosGradient : Theme.androidGradient)
                .frame(width: 28, height: 28)
                .shadow(color: (platform == .ios ? Color.red : Color.green).opacity(0.2), radius: 4, x: 0, y: 2)

            Image(systemName: platform.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
