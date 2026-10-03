import DevBarCore
import SwiftUI

struct MainView: View {
    @ObservedObject var manager: DeviceManager

    init(manager: DeviceManager, initialTab: AppTab = .devices) {
        self.manager = manager
        _activeTab = State(initialValue: initialTab)
    }

    // Custom workspace tab state routing
    @State private var activeTab: AppTab = .devices

    @AppStorage("favoriteDeviceIDs") private var favorites = ""
    @State private var searchText = ""
    @State private var selectedPlatformFilter: PlatformFilter = .all
    @State private var diagnostics = ""
    @State private var showingDiagnostics = false
    @State private var checkingTools = false
    @State private var spinAngle: Double = 0.0

    // Global Drag & Drop Overlay States (Phase 1)
    @State private var isTargetedForGlobalDrop = false
    @State private var globalInstalling = false
    @State private var showGlobalToast = false
    @State private var globalToastMessage = ""
    @State private var globalToastTimer: Timer? = nil

    enum AppTab {
        case devices
        case gps
        case tools
    }

    enum PlatformFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case ios = "iOS"
        case android = "Android"

        var id: String { self.rawValue }
    }

    var body: some View {
        ZStack {
            // Main Layout Container
            VStack(spacing: 0) {
                // Unified Header Section
                headerView
                if let error = manager.lastError {
                    HStack {
                        Text(error).font(.caption).foregroundStyle(.orange)
                        Button("Dismiss") { manager.lastError = nil }
                    }.padding(8)
                }

                // Active workspace drawer router
                ZStack {
                    switch activeTab {
                    case .devices:
                        devicesListView
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)), removal: .opacity.combined(with: .move(edge: .trailing))))
                    case .gps:
                        GPSSpoofView(manager: manager)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    case .tools:
                        ToolsView(manager: manager)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)), removal: .opacity.combined(with: .move(edge: .leading))))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: activeTab)

                Spacer(minLength: 0)

                // Glassmorphic bottom tab bar selector dock
                tabBarView
            }

            // Global Multi-Install Dropzone Overlay
            if isTargetedForGlobalDrop {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Theme.bgMain.opacity(0.85))
                    .overlay(
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.mainAccentGradient.opacity(0.15))
                                    .frame(width: 76, height: 76)

                                Image(systemName: "square.and.arrow.down.on.square.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Theme.mainAccentGradient)
                            }

                            VStack(spacing: 6) {
                                Text("Install On All Active Devices")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Drop build to simultaneously install on all running simulators or emulators.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 44)
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
            }

            // Global Multi-Installing HUD overlay
            if globalInstalling {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)

                            Text("Installing Package Across Devices...")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .glassmorphic(cornerRadius: 12)
                    )
                    .zIndex(101)
            }

            // Global Toast Notification Banner
            if showGlobalToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: globalToastMessage.contains("failed") || globalToastMessage.contains("No active") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(globalToastMessage.contains("failed") || globalToastMessage.contains("No active") ? Color.orange : Theme.activeGreen)

                        Text(globalToastMessage)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .glassmorphic(cornerRadius: 100)
                    .padding(.top, 70)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(102)
            }
        }
        .alert("Development Tools", isPresented: $showingDiagnostics) {
            Button("OK", role: .cancel) {}
        } message: { Text(diagnostics) }
        .frame(width: 360, height: 500)
        .background(Theme.bgMain)
        .preferredColorScheme(.dark)
        .onDrop(of: ["public.file-url"], isTargeted: $isTargetedForGlobalDrop) { providers in
            // Handle drops globally only when on the Devices list tab
            guard activeTab == .devices else { return false }
            return handleGlobalDrop(providers: providers)
        }
    }

    // MARK: - Subviews

    private var devicesListView: some View {
        VStack(spacing: 0) {
            // Search & Filter Section
            searchAndFilterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            // Devices Scroll Feed
            ScrollView {
                VStack(spacing: 8) {
                    if filteredDevices.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(filteredDevices.sorted { a, b in
                            let ids = Set(favorites.split(separator: "|").map(String.init))
                            if ids.contains(a.id) != ids.contains(b.id) { return ids.contains(a.id) }
                            return a.name < b.name
                        }) { device in
                            DeviceRowView(
                                device: device,
                                manager: manager
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private var tabBarView: some View {
        HStack(spacing: 4) {
            tabButton(tab: .devices, label: "Devices", icon: "ipad.and.iphone")
            tabButton(tab: .gps, label: "GPS Mock", icon: "location.fill")
            tabButton(tab: .tools, label: "Tools", icon: "wrench.and.screwdriver.fill")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.01))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tabButton(tab: AppTab, label: String, icon: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activeTab = tab
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(
            PremiumButtonStyle(
                accentGradient: activeTab == tab ? Theme.mainAccentGradient : nil
            )
        )
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("DevBar")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Circle()
                        .fill(Theme.iosGradient)
                        .frame(width: 5, height: 5)
                }

                Text("Simulator Command Deck")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(0.5)
            }

            Spacer()

            if activeDeviceCount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.activeGreen)
                        .frame(width: 5, height: 5)

                    Text("\(activeDeviceCount) active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.activeGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.activeGreen.opacity(0.1))
                .cornerRadius(100)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: activeDeviceCount)
            }

            HStack(spacing: 8) {
                Button {
                    checkingTools = true
                    DispatchQueue.global(qos: .userInitiated).async {
                        let report = DeviceService().doctor().map {
                            "\($0["name"]!): \(($0["available"] as? Bool == true) ? "Ready" : "Missing")\n\($0["detail"]!)"
                        }.joined(separator: "\n\n")
                        DispatchQueue.main.async {
                            diagnostics = report
                            showingDiagnostics = true
                            checkingTools = false
                        }
                    }
                } label: {
                    Image(systemName: "stethoscope").frame(width: 28, height: 28)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .disabled(checkingTools)
                .help("Check development tools")
                Button(action: {
                    withAnimation(.linear(duration: 0.8)) {
                        spinAngle += 360
                    }
                    manager.refreshDevices()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(manager.isRefreshing ? Theme.bootingOrange : .white)
                        .rotationEffect(.degrees(spinAngle))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .disabled(manager.isRefreshing)

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color.white.opacity(0.02))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textMuted)

                TextField("Search simulators & API versions...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.bgInput)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            HStack(spacing: 6) {
                ForEach(PlatformFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selectedPlatformFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        PremiumButtonStyle(
                            accentGradient: selectedPlatformFilter == filter ? Theme.mainAccentGradient : nil
                        )
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 60, height: 60)

                Image(systemName: "ipad.and.iphone")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.top, 40)

            Text(searchText.isEmpty ? "No Devices Detected" : "No Results Match Query")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            if searchText.isEmpty {
                Text("Ensure Xcode Simulators or Android Virtual Devices (AVD) are configured on your system. DevBar will automatically detect active devices.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            } else {
                Text("Try adjusting your keywords or clearing your active search filters.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(minHeight: 280)
        .transition(.opacity)
    }

    // MARK: - Filter Logic

    private var filteredDevices: [Device] {
        manager.devices.filter { device in
            let matchesSearch = searchText.isEmpty ||
                device.name.localizedCaseInsensitiveContains(searchText) ||
                device.osVersion.localizedCaseInsensitiveContains(searchText)

            let matchesPlatform: Bool
            switch selectedPlatformFilter {
            case .all:
                matchesPlatform = true
            case .ios:
                matchesPlatform = device.platform == .ios
            case .android:
                matchesPlatform = device.platform == .android
            }

            return matchesSearch && matchesPlatform
        }
    }

    private var activeDeviceCount: Int {
        manager.devices.filter { $0.state == .booted }.count
    }

    // MARK: - Multi-Device Drop Logic (Phase 1)

    private func handleGlobalDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
            guard let data = data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let filePath = url.path
            let isIosBuild = filePath.hasSuffix(".app")
            let isAndroidBuild = filePath.hasSuffix(".apk")

            DispatchQueue.main.async {
                let matchingDevices = manager.devices.filter { device in
                    guard device.state == .booted else { return false }
                    if isIosBuild && device.platform == .ios { return true }
                    if isAndroidBuild && device.platform == .android { return true }
                    return false
                }

                if matchingDevices.isEmpty {
                    showGlobalToastAlert(message: "No active compatible devices found!")
                    return
                }

                globalInstalling = true

                let group = DispatchGroup()
                var successCount = 0
                var failCount = 0

                for device in matchingDevices {
                    group.enter()
                    manager.installApp(filePath: filePath, to: device) { success, msg in
                        if success {
                            successCount += 1
                        } else {
                            failCount += 1
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    globalInstalling = false
                    if failCount == 0 {
                        showGlobalToastAlert(message: "Installed build on \(successCount) active devices!")
                    } else {
                        showGlobalToastAlert(message: "Installed on \(successCount) devices. \(failCount) failed.")
                    }
                }
            }
        }
        return true
    }

    private func showGlobalToastAlert(message: String) {
        globalToastTimer?.invalidate()
        globalToastMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            showGlobalToast = true
        }

        globalToastTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                showGlobalToast = false
            }
        }
    }
}
