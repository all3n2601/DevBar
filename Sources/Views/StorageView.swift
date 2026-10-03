import DevBarCore
import SwiftUI

struct StorageView: View {
    @ObservedObject var manager: DeviceManager
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("targetBundleId") private var targetBundleId = "com.example.app"

    @State private var preferences: [String: String] = [:]
    @State private var editingKey: String? = nil
    @State private var editingValue = ""
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var isLoading = false

    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastTimer: Timer? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))

                Text("App Storage Preferences")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Refresh Storage
                Button(action: loadPreferences) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
                .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.02))
            .overlay(
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1),
                alignment: .bottom
            )

            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        // Configuration Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TARGET CONTAINER BUNDLE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)

                            HStack {
                                TextField("Bundle ID", text: $targetBundleId)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.textPrimary)

                                Button(action: loadPreferences) {
                                    Text("Load")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .frame(height: 22)
                                }
                                .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Theme.bgInput)
                            .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)

                        // Active Key-Value List Grid
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PREFERENCE KEYS")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(Theme.textMuted)
                                    .tracking(0.5)

                                Spacer()

                                Text("\(preferences.count) items")
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }

                            if preferences.isEmpty {
                                emptyPreferencesView
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(preferences.keys.sorted(), id: \.self) { key in
                                        preferenceRow(key: key)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Add New Key Panel
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ADD NEW KEY")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.5)

                            HStack(spacing: 8) {
                                TextField("Key Name", text: $newKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Theme.bgInput)
                                    .cornerRadius(6)

                                TextField("Value", text: $newValue)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Theme.bgInput)
                                    .cornerRadius(6)

                                Button(action: addNewKey) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .bold))
                                        .frame(width: 24, height: 24)
                                }
                                .buttonStyle(PremiumButtonStyle(accentGradient: Theme.iosGradient, isCircular: true))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                // Loading Overlay
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            ProgressView()
                                .controlSize(.regular)
                        )
                }

                // Toast Alerts
                if showToast {
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: toastMessage.contains("failed") || toastMessage.contains("No active") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(toastMessage.contains("failed") || toastMessage.contains("No active") ? Color.orange : Theme.activeGreen)

                            Text(toastMessage)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassmorphic(cornerRadius: 100)
                        .padding(.top, 16)

                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .frame(width: 360, height: 500)
        .background(Theme.bgMain)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadPreferences)
    }

    // MARK: - Subviews

    private func preferenceRow(key: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)

                if editingKey == key {
                    HStack(spacing: 6) {
                        TextField("New Value", text: $editingValue)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.bgInput)
                            .cornerRadius(4)

                        Button(action: { saveKeyUpdate(key: key) }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(PremiumButtonStyle(accentGradient: Theme.mainAccentGradient, isCircular: true))

                        Button(action: { editingKey = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(PremiumButtonStyle(isCircular: true))
                    }
                } else {
                    Text(preferences[key] ?? "")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            if editingKey != key {
                Button(action: {
                    editingKey = key
                    editingValue = preferences[key] ?? ""
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PremiumButtonStyle(isCircular: true))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .glassmorphic(cornerRadius: 8)
    }

    private var emptyPreferencesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 20))
                .foregroundColor(Theme.textMuted)
                .padding(.top, 16)

            Text("No Keys Found")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Text("Ensure the simulator is running, the app is installed, and has run at least once to write preferences.")
                .font(.system(size: 9))
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(minHeight: 120)
    }

    // MARK: - Actions Logic

    private func loadPreferences() {
        guard !targetBundleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isLoading = true
        manager.loadStorageKeys(bundleId: targetBundleId) { dict in
            isLoading = false
            if let dict = dict {
                self.preferences = dict
            } else {
                showStorageToast(message: "Failed to locate storage sandbox.")
            }
        }
    }

    private func saveKeyUpdate(key: String) {
        isLoading = true
        manager.saveStorageKey(key: key, value: editingValue, bundleId: targetBundleId) { success in
            isLoading = false
            editingKey = nil
            if success {
                preferences[key] = editingValue
                showStorageToast(message: "Preferences updated!")
            } else {
                showStorageToast(message: "Failed to write key to sandbox.")
            }
        }
    }

    private func addNewKey() {
        let cleanKey = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return }

        isLoading = true
        manager.saveStorageKey(key: cleanKey, value: newValue, bundleId: targetBundleId) { success in
            isLoading = false
            if success {
                preferences[cleanKey] = newValue
                newKey = ""
                newValue = ""
                showStorageToast(message: "New key added successfully!")
            } else {
                showStorageToast(message: "Failed to write key.")
            }
        }
    }

    private func showStorageToast(message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.25)) {
            showToast = true
        }

        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }
}
