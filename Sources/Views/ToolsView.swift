import DevBarCore
import SwiftUI

struct ToolsView: View {
    @ObservedObject var manager: DeviceManager

    // Core Status Overrides
    @State private var darkModeEnabled = false
    @State private var cleanStatusBarEnabled = false

    // Storage Sheet Presentation
    @State private var showStorageEditor = false

    // Persistent Bundle ID/Package target selection
    @AppStorage("targetBundleId") private var targetBundleId = "com.example.app"

    // Custom Deeplinks States
    @State private var savedDeeplinks: [String] = []
    @State private var newDeeplinkUrl = ""
    @State private var isDeeplinking = false

    // Drag-Drop Push States
    @State private var isTargetedForPushDrop = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastTimer: Timer? = nil
    @State private var isInjecting = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Unified System Switches Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SYSTEM OVERRIDES")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)

                        VStack(spacing: 8) {
                            // Dark Appearance Toggle Card
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.mainAccentGradient.opacity(0.12))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: darkModeEnabled ? "moon.stars.fill" : "sun.max.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("System Night Mode")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Toggle system dark/light appearances.")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $darkModeEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                                    .onChange(of: darkModeEnabled) { _, newValue in
                                        manager.toggleAppearance(darkMode: newValue)
                                        showToolsToast(message: "Night Mode appearance broadcasted!")
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .glassmorphic(cornerRadius: 10)

                            // Clean Status Bar Toggle Card
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.mainAccentGradient.opacity(0.12))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "battery.100")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Clean Status Bar")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Set time to 9:41, battery to 100%, full cellular bars.")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $cleanStatusBarEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                                    .onChange(of: cleanStatusBarEnabled) { _, newValue in
                                        manager.toggleCleanStatusBar(enabled: newValue)
                                        showToolsToast(message: newValue ? "Clean Status Bar override active!" : "Clean overrides cleared.")
                                    }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .glassmorphic(cornerRadius: 10)

                            // Live Storage Editor Trigger Card
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.iosGradient.opacity(0.12))
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 13))
                                        .foregroundColor(.purple)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Live Sandbox Editor")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("Edit User Defaults plist & SharedPreferences XML.")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(Theme.textSecondary)
                                }

                                Spacer()

                                Button(action: { showStorageEditor = true }) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 9, weight: .bold))
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(PremiumButtonStyle(isCircular: true))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .glassmorphic(cornerRadius: 10)
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.vertical, 2)

                    // Deeplinks Presets Shelf & Launcher Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEEPLINK PRESENTS & LAUNCHER")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)

                        VStack(alignment: .leading, spacing: 10) {
                            // Manual link launch
                            HStack {
                                TextField("Enter custom URL scheme (e.g. myapp://feed)...", text: $newDeeplinkUrl)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)

                                Button(action: { triggerDeeplinkLaunch(url: newDeeplinkUrl) }) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient, isCircular: true))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.bgInput)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )

                            // Saved Deeplinks List Shelf
                            if !savedDeeplinks.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(savedDeeplinks, id: \.self) { link in
                                            Button(action: { triggerDeeplinkLaunch(url: link) }) {
                                                HStack(spacing: 5) {
                                                    Image(systemName: "safari.fill")
                                                        .font(.system(size: 8))
                                                        .foregroundColor(.blue)

                                                    Text(URL(string: link)?.host ?? link)
                                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                            }
                                            .buttonStyle(PremiumButtonStyle())
                                            .contextMenu {
                                                Button("Delete Preset") {
                                                    deleteDeeplinkPreset(url: link)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.vertical, 2)

                    // Push Notification Workstation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PUSH PAYLOAD WORKSTATION")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)

                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TARGET BUNDLE IDENTIFIER / PACKAGE")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)

                                TextField("e.g. com.company.app", text: $targetBundleId)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Theme.bgInput)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }

                            VStack(spacing: 8) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isTargetedForPushDrop ? .purple : Theme.textMuted)
                                    .scaleEffect(isTargetedForPushDrop ? 1.2 : 1.0)
                                    .animation(.spring(), value: isTargetedForPushDrop)

                                Text(isTargetedForPushDrop ? "Drop JSON Payload now!" : "Drag & Drop .json Payload here")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)

                                Text("Will inject mock push banner across matching active devices.")
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    if isTargetedForPushDrop {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.purple.opacity(0.1))
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.02))
                                    }
                                }
                            )
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        isTargetedForPushDrop ? Theme.iosGradient : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .top, endPoint: .bottom),
                                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round, dash: isTargetedForPushDrop ? [4, 3] : [])
                                    )
                            )
                            .onDrop(of: ["public.file-url"], isTargeted: $isTargetedForPushDrop) { providers in
                                handlePushDrop(providers: providers)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            // Local Progress Overlay
            if isInjecting || isDeeplinking {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)

                            Text(isDeeplinking ? "Routing Custom URL Scheme..." : "Injecting Push Payload...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .glassmorphic(cornerRadius: 12)
                    )
                    .zIndex(9)
            }

            // Toast Notification Banner
            if showToast {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: toastMessage.contains("failed") || toastMessage.contains("Invalid") ? "exclamationmark.triangle.fill" : "bell.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(toastMessage.contains("failed") || toastMessage.contains("Invalid") ? Color.orange : Theme.activeGreen)

                        Text(toastMessage)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassmorphic(cornerRadius: 100)
                    .padding(.top, 24)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear(perform: loadDeeplinkPresets)
        // Storage editor modal trigger
        .sheet(isPresented: $showStorageEditor) {
            StorageView(manager: manager)
        }
    }

    // MARK: - Actions Helper

    private func loadDeeplinkPresets() {
        if let array = UserDefaults.standard.stringArray(forKey: "savedDeeplinks") {
            self.savedDeeplinks = array
        } else {
            let defaults = [
                "myapp://profile",
                "myapp://cart/checkout",
                "https://www.google.com"
            ]
            self.savedDeeplinks = defaults
            UserDefaults.standard.set(defaults, forKey: "savedDeeplinks")
        }
    }

    private func triggerDeeplinkLaunch(url: String) {
        let clean = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        isDeeplinking = true
        manager.launchDeeplink(url: clean) { success, msg in
            isDeeplinking = false
            showToolsToast(message: msg)
            if success {
                // Save preset to library
                saveDeeplinkPreset(url: clean)
                newDeeplinkUrl = ""
            }
        }
    }

    private func saveDeeplinkPreset(url: String) {
        if !savedDeeplinks.contains(url) {
            savedDeeplinks.append(url)
            UserDefaults.standard.set(savedDeeplinks, forKey: "savedDeeplinks")
        }
    }

    private func deleteDeeplinkPreset(url: String) {
        if let idx = savedDeeplinks.firstIndex(of: url) {
            savedDeeplinks.remove(at: idx)
            UserDefaults.standard.set(savedDeeplinks, forKey: "savedDeeplinks")
            showToolsToast(message: "Preset deleted.")
        }
    }

    private func handlePushDrop(providers: [NSItemProvider]) -> Bool {
        guard !targetBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showToolsToast(message: "Invalid target bundle identifier!")
            return false
        }

        guard let provider = providers.first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
            guard let data = data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let filePath = url.path
            guard filePath.hasSuffix(".json") else {
                DispatchQueue.main.async {
                    showToolsToast(message: "Payload must be a valid .json file!")
                }
                return
            }

            DispatchQueue.main.async {
                isInjecting = true
                manager.injectPushNotification(payloadPath: filePath, bundleId: targetBundleId) { success, msg in
                    isInjecting = false
                    showToolsToast(message: msg)
                }
            }
        }
        return true
    }

    private func showToolsToast(message: String) {
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
}
