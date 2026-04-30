import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: CompassViewModel

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Glasses display
                Section("Glasses Display Format") {
                    ForEach(CompassFormat.allCases) { fmt in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(fmt.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(fmt.example)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vm.format == fmt {
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { vm.setFormat(fmt) }
                    }
                }

                // MARK: Streaming
                Section("Streaming") {
                    Toggle("Broadcast to glasses", isOn: Binding(
                        get:  { vm.broadcastEnabled },
                        set:  { vm.setBroadcastEnabled($0) }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Update threshold")
                            Spacer()
                            Text("≥\(String(format: "%.0f", vm.updateRate))°").foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { vm.updateRate },
                            set: { vm.setUpdateRate($0) }
                        ), in: 1...15, step: 1)
                    }

                    Text("Only broadcasts to glasses when heading changes by this many degrees. Lower = more frequent updates.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: Connection
                Section("Connection") {
                    LabeledContent("TCP port",  value: "8100").foregroundStyle(.secondary)
                    LabeledContent("Status",    value: vm.glassesServer.isRunning ? "Running" : "Stopped")
                        .foregroundStyle(vm.glassesServer.isRunning ? .green : .red)
                    LabeledContent("Clients",   value: "\(vm.glassesServer.clientCount)").foregroundStyle(.secondary)
                    LabeledContent("Accuracy",  value: vm.accuracyText)
                        .foregroundStyle(vm.isCalibrated ? .green : .orange)
                }

                // MARK: Calibration
                Section {
                    Text("If the compass is inaccurate, wave your phone in a figure-8 motion a few times to calibrate the magnetometer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Calibration tip")
                }

                // MARK: About
                Section("About") {
                    LabeledContent("App",      value: "Rokid Compass HUD")
                    LabeledContent("Version",  value: "1.0")
                    LabeledContent("Sensor",   value: "CLLocationManager heading")
                    LabeledContent("Protocol", value: "TCP :8100  JSON lines")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
