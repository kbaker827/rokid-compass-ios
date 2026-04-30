import SwiftUI

struct CompassView: View {
    @EnvironmentObject private var vm: CompassViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                compassRose
                headingReadout
                glassesPreviewBadge
                statusBar
                Spacer()
            }
            .padding()
            .navigationTitle("Compass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { serverDot }
            }
        }
    }

    // MARK: - Compass rose

    private var compassRose: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 2)
                .frame(width: 260, height: 260)

            // Tick marks every 30°
            ForEach(0..<12, id: \.self) { i in
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 2, height: i % 3 == 0 ? 16 : 8)
                    .offset(y: -120)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Cardinal labels — rotate opposite to heading so they stay fixed
            ForEach([("N", 0.0), ("E", 90.0), ("S", 180.0), ("W", 270.0)], id: \.0) { label, angle in
                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(label == "N" ? .red : .primary)
                    .offset(y: -96)
                    .rotationEffect(.degrees(angle))
                    .rotationEffect(.degrees(vm.compassRoseRotation))
            }

            // Needle
            ZStack {
                // North (red)
                Triangle()
                    .fill(Color.red)
                    .frame(width: 16, height: 80)
                    .offset(y: -40)
                // South (white/gray)
                Triangle()
                    .fill(Color(.systemGray3))
                    .frame(width: 16, height: 80)
                    .rotationEffect(.degrees(180))
                    .offset(y: 40)
            }
            .rotationEffect(.degrees(-vm.compass.heading))
            .animation(.easeOut(duration: 0.2), value: vm.compass.heading)

            // Center dot
            Circle()
                .fill(Color(.systemBackground))
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color(.systemGray3), lineWidth: 2))
        }
        .frame(width: 260, height: 260)
    }

    // MARK: - Heading readout

    private var headingReadout: some View {
        VStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(vm.arrowText)
                    .font(.system(size: 48))
                Text(vm.directionText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                Text(vm.headingText)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text(vm.accuracyText)
                .font(.caption)
                .foregroundStyle(vm.isCalibrated ? .green : .orange)
        }
    }

    // MARK: - What the glasses see

    private var glassesPreviewBadge: some View {
        VStack(spacing: 8) {
            Text("On the glasses:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(vm.compass.glassesLine(format: vm.format))
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color(red: 0.3, green: 1.0, blue: 0.4))
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: 20) {
            // Broadcast toggle
            Button {
                vm.setBroadcastEnabled(!vm.broadcastEnabled)
            } label: {
                Label(
                    vm.broadcastEnabled ? "Streaming" : "Paused",
                    systemImage: vm.broadcastEnabled ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(vm.broadcastEnabled ? .green : .secondary)
            }

            Divider().frame(height: 20)

            // Format picker
            Menu {
                ForEach(CompassFormat.allCases) { fmt in
                    Button {
                        vm.setFormat(fmt)
                    } label: {
                        HStack {
                            Text(fmt.displayName)
                            Text("→ \(fmt.example)").foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                Label(vm.format.displayName, systemImage: "textformat.size")
                    .font(.caption.weight(.medium))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Server dot

    private var serverDot: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(vm.glassesServer.isRunning ? .green : .red)
                .frame(width: 8, height: 8)
            Text("\(vm.glassesServer.clientCount)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Triangle shape for compass needle

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to:    CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
