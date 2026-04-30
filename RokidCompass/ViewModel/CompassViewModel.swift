import Foundation
import Combine

@MainActor
final class CompassViewModel: ObservableObject {

    // MARK: - Published
    @Published var format:        CompassFormat = .full
    @Published var updateRate:    Double = 1.0   // minimum degrees change to re-broadcast
    @Published var broadcastEnabled: Bool = true

    let compass       = CompassManager()
    let glassesServer = GlassesServer()

    private var cancellables = Set<AnyCancellable>()
    private var lastBroadcastHeading: Double = -999

    // MARK: - Init

    init() {
        // Load saved settings
        if let saved = UserDefaults.standard.string(forKey: "compass_format"),
           let fmt = CompassFormat(rawValue: saved) {
            format = fmt
        }
        updateRate      = UserDefaults.standard.double(forKey: "compass_update_rate").nonZero ?? 1.0
        broadcastEnabled = UserDefaults.standard.object(forKey: "compass_broadcast") as? Bool ?? true

        glassesServer.start()
        compass.requestPermissionAndStart()

        // Watch heading changes and broadcast when threshold exceeded
        compass.$heading
            .receive(on: RunLoop.main)
            .sink { [weak self] newHeading in
                self?.onHeadingChanged(newHeading)
            }
            .store(in: &cancellables)
    }

    // MARK: - Heading broadcast

    private func onHeadingChanged(_ heading: Double) {
        guard broadcastEnabled, glassesServer.clientCount > 0 else { return }
        let diff = abs(heading - lastBroadcastHeading)
        let wrappedDiff = min(diff, 360 - diff)
        guard wrappedDiff >= updateRate else { return }
        lastBroadcastHeading = heading
        glassesServer.broadcastHeading(line: compass.glassesLine(format: format))
    }

    // MARK: - Settings persistence

    func setFormat(_ fmt: CompassFormat) {
        format = fmt
        UserDefaults.standard.set(fmt.rawValue, forKey: "compass_format")
        // Force an immediate broadcast with new format
        lastBroadcastHeading = -999
        onHeadingChanged(compass.heading)
    }

    func setUpdateRate(_ rate: Double) {
        updateRate = rate
        UserDefaults.standard.set(rate, forKey: "compass_update_rate")
    }

    func setBroadcastEnabled(_ enabled: Bool) {
        broadcastEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "compass_broadcast")
        if !enabled { glassesServer.broadcastStatus("Compass broadcast paused") }
    }

    // MARK: - Computed display values

    var compassRoseRotation: Double { -compass.heading }  // rotate rose opposite to heading

    var headingText: String  { compass.degreesFormatted }
    var directionText: String { compass.direction.rawValue }
    var arrowText: String     { compass.direction.arrow }

    var accuracyText: String {
        if compass.accuracy < 0 { return "Calibrating…" }
        return "±\(Int(compass.accuracy))°"
    }

    var isCalibrated: Bool { compass.accuracy >= 0 && compass.accuracy <= 15 }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
