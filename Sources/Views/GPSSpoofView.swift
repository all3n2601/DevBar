import DevBarCore
import SwiftUI
import MapKit

struct GPSSpoofView: View {
    @ObservedObject var manager: DeviceManager

    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    ))

    @State private var latText = "37.774900"
    @State private var lngText = "-122.419400"

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastTimer: Timer? = nil
    @State private var isGpxTargeted = false

    struct PresetLocation: Identifiable {
        let id = UUID()
        let name: String
        let latitude: Double
        let longitude: Double
        let icon: String
    }

    let presets = [
        PresetLocation(name: "San Francisco", latitude: 37.774900, longitude: -122.419400, icon: "house.fill"),
        PresetLocation(name: "New York", latitude: 40.712800, longitude: -74.006000, icon: "building.2.fill"),
        PresetLocation(name: "London", latitude: 51.507400, longitude: -0.127800, icon: "crown.fill"),
        PresetLocation(name: "Tokyo", latitude: 35.676200, longitude: 139.650300, icon: "sun.max.fill"),
        PresetLocation(name: "Paris", latitude: 48.856600, longitude: 2.352200, icon: "heart.fill")
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Visual Map Panel
                MapReader { proxy in
                    Map(position: $position) {
                        Marker("Target Location", coordinate: selectedCoordinate)
                            .tint(.purple)
                    }
                    .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .including([])))
                    .onTapGesture { screenPoint in
                        if let coord = proxy.convert(screenPoint, from: .local) {
                            updateCoordinate(coord)
                        }
                    }
                }
                .frame(height: 190)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .overlay(
                    Text("Click anywhere on map to pin coordinates")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(.bottom, 12)
                        .padding(.trailing, 24),
                    alignment: .bottomTrailing
                )

                // Manual Coordinate Inputs
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LATITUDE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)

                        TextField("Latitude", text: $latText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.bgInput)
                            .cornerRadius(6)
                            .onChange(of: latText) { syncTextToCoordinates() }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("LONGITUDE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)

                        TextField("Longitude", text: $lngText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.bgInput)
                            .cornerRadius(6)
                            .onChange(of: lngText) { syncTextToCoordinates() }
                    }

                    // Apply coordinates trigger button
                    VStack {
                        Spacer().frame(height: 14)
                        Button(action: applyMockLocation) {
                            Text("Mock")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .frame(height: 25)
                                .padding(.horizontal, 16)
                        }
                        .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.horizontal, 16)

                // Saved Locations Preset Shelf
                VStack(alignment: .leading, spacing: 8) {
                    Text("SAVED PRESETS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets) { preset in
                                Button(action: {
                                    let coord = CLLocationCoordinate2D(latitude: preset.latitude, longitude: preset.longitude)
                                    updateCoordinate(coord)
                                    // Smooth pan map camera to preset
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        position = .region(MKCoordinateRegion(
                                            center: coord,
                                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                                        ))
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: preset.icon)
                                            .font(.system(size: 9))
                                            .foregroundColor(.purple)

                                        Text(preset.name)
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(PremiumButtonStyle())
                            }

                            // Dynamically merge workspace-level shared team presets
                            if let teamPresets = TeamLoader.shared.teamConfig?.gpsPresets {
                                ForEach(teamPresets) { preset in
                                    Button(action: {
                                        let coord = CLLocationCoordinate2D(latitude: preset.latitude, longitude: preset.longitude)
                                        updateCoordinate(coord)
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            position = .region(MKCoordinateRegion(
                                                center: coord,
                                                span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                                            ))
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: preset.icon)
                                                .font(.system(size: 9))
                                                .foregroundColor(.green) // Color-coded team presets as green to differentiate

                                            Text(preset.name)
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(PremiumButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.horizontal, 16)

                // GPX Route Playback Workspace
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPX ROUTE SIMULATION")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.5)

                    if manager.gpxPointsCount > 0 {
                        // Playback Status Controls Panel
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.mainAccentGradient.opacity(0.12))
                                    .frame(width: 32, height: 32)

                                Image(systemName: "point.topleft.down.to.point.bottomright.filled")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("GPX Route Active")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Text("Index: \(manager.gpxPlaybackIndex) / \(manager.gpxPointsCount) points")
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            Spacer()

                            // Play/Pause Action Toggle
                            Button(action: toggleGpxPlayState) {
                                Image(systemName: manager.isGpxPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 26, height: 26)
                            }
                            .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient, isCircular: true))

                            // Reset/Unload Button
                            Button(action: unloadGpxRoute) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                    .frame(width: 26, height: 26)
                            }
                            .buttonStyle(PremiumButtonStyle(isCircular: true))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassmorphic(cornerRadius: 10)
                    } else {
                        // Empty GPX dropzone card
                        VStack(spacing: 6) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isGpxTargeted ? .purple : Theme.textMuted)
                                .scaleEffect(isGpxTargeted ? 1.2 : 1.0)

                            Text(isGpxTargeted ? "Drop GPX file!" : "Drag & Drop .gpx route file here")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)

                            Text("Loads route logs to playback coordinates automatically.")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(isGpxTargeted ? 0.08 : 0.02))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isGpxTargeted ? Theme.iosGradient : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round, dash: isGpxTargeted ? [4, 3] : [])
                                )
                        )
                        .onDrop(of: ["public.file-url"], isTargeted: $isGpxTargeted) { providers in
                            handleGpxDrop(providers: providers)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Spacer()
            }

            // Toast Notification Overlay
            if showToast {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: toastMessage.contains("failed") || toastMessage.contains("No active") ? "exclamationmark.triangle.fill" : "location.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(toastMessage.contains("failed") || toastMessage.contains("No active") ? Color.orange : Theme.activeGreen)

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
        // Asynchronously listen and sync Map camera to GPX updates
        .onReceive(manager.$activeGpxCoordinate) { newCoord in
            guard let coord = newCoord else { return }
            self.selectedCoordinate = coord
            self.latText = String(format: "%.6f", coord.latitude)
            self.lngText = String(format: "%.6f", coord.longitude)

            // Smoothly pan camera region
            withAnimation(.easeInOut(duration: 0.4)) {
                self.position = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                ))
            }
        }
    }

    // MARK: - Helpers

    private func updateCoordinate(_ coord: CLLocationCoordinate2D) {
        selectedCoordinate = coord
        latText = String(format: "%.6f", coord.latitude)
        lngText = String(format: "%.6f", coord.longitude)
    }

    private func syncTextToCoordinates() {
        if let lat = Double(latText), let lng = Double(lngText) {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            if coord.latitude >= -90 && coord.latitude <= 90 && coord.longitude >= -180 && coord.longitude <= 180 {
                selectedCoordinate = coord
            }
        }
    }

    private func applyMockLocation() {
        guard let lat = Double(latText), let lng = Double(lngText) else {
            showSpoofToast(message: "Invalid coordinate formats!")
            return
        }

        manager.setGPSLocation(latitude: lat, longitude: lng) { success in
            if success {
                showSpoofToast(message: "Location spoofed across active devices!")
            } else {
                showSpoofToast(message: "No active devices to spoof location!")
            }
        }
    }

    private func showSpoofToast(message: String) {
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

    private func toggleGpxPlayState() {
        if manager.isGpxPlaying {
            manager.stopGPXPlayback()
            showSpoofToast(message: "GPX playback paused.")
        } else {
            manager.startGPXPlayback()
            showSpoofToast(message: "GPX route simulation active!")
        }
    }

    private func unloadGpxRoute() {
        manager.stopGPXPlayback()
        manager.gpxPointsCount = 0
        manager.gpxPlaybackIndex = 0
        manager.activeGpxCoordinate = nil
        showSpoofToast(message: "GPX route unloaded.")
    }

    private func handleGpxDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: "public.file-url") { data, error in
            guard let data = data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let filePath = url.path
            guard filePath.hasSuffix(".gpx") else {
                DispatchQueue.main.async {
                    showSpoofToast(message: "Invalid file! Drop a valid .gpx XML file.")
                }
                return
            }

            DispatchQueue.main.async {
                let count = manager.loadGPXFile(path: filePath)
                if count > 0 {
                    showSpoofToast(message: "Loaded GPX route: \(count) points!")
                } else {
                    showSpoofToast(message: "Failed to parse GPX XML elements.")
                }
            }
        }
        return true
    }
}
