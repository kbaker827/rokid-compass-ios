import Foundation
import CoreLocation
import Combine

// MARK: - Cardinal direction

enum CardinalDirection: String {
    case N, NNE, NE, ENE, E, ESE, SE, SSE, S, SSW, SW, WSW, W, WNW, NW, NNW

    var arrow: String {
        switch self {
        case .N:   return "↑"
        case .NNE: return "↑"
        case .NE:  return "↗"
        case .ENE: return "→"
        case .E:   return "→"
        case .ESE: return "→"
        case .SE:  return "↘"
        case .SSE: return "↓"
        case .S:   return "↓"
        case .SSW: return "↓"
        case .SW:  return "↙"
        case .WSW: return "←"
        case .W:   return "←"
        case .WNW: return "←"
        case .NW:  return "↖"
        case .NNW: return "↑"
        }
    }

    /// Primary cardinal (N/E/S/W) for minimal display
    var primary: String {
        switch self {
        case .N, .NNE, .NNW:         return "N"
        case .NE, .ENE:              return "NE"
        case .E, .ESE:               return "E"
        case .SE, .SSE:              return "SE"
        case .S, .SSW:               return "S"
        case .SW, .WSW:              return "SW"
        case .W, .WNW:               return "W"
        case .NW, .NNW:              return "NW"
        }
    }

    static func from(degrees: Double) -> CardinalDirection {
        let d = ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        switch d {
        case 0..<11.25:   return .N
        case 11.25..<33.75:  return .NNE
        case 33.75..<56.25:  return .NE
        case 56.25..<78.75:  return .ENE
        case 78.75..<101.25: return .E
        case 101.25..<123.75: return .ESE
        case 123.75..<146.25: return .SE
        case 146.25..<168.75: return .SSE
        case 168.75..<191.25: return .S
        case 191.25..<213.75: return .SSW
        case 213.75..<236.25: return .SW
        case 236.25..<258.75: return .WSW
        case 258.75..<281.25: return .W
        case 281.25..<303.75: return .WNW
        case 303.75..<326.25: return .NW
        case 326.25..<348.75: return .NNW
        default:             return .N
        }
    }
}

// MARK: - Compass display format

enum CompassFormat: String, CaseIterable, Identifiable {
    case full     = "full"
    case compact  = "compact"
    case minimal  = "minimal"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .full:    return "Full"
        case .compact: return "Compact"
        case .minimal: return "Minimal"
        }
    }

    var example: String {
        switch self {
        case .full:    return "↑ N  007°"
        case .compact: return "↑ N"
        case .minimal: return "N"
        }
    }
}

// MARK: - Compass Manager

@MainActor
final class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var heading:   Double = 0          // 0–359.9°
    @Published var direction: CardinalDirection = .N
    @Published var accuracy:  Double = -1          // ±degrees, -1 = uncalibrated
    @Published var isAvailable: Bool = false
    @Published var authStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        isAvailable = CLLocationManager.headingAvailable()
    }

    func requestPermissionAndStart() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.headingFilter     = 1          // update every 1°
        manager.headingOrientation = .portrait
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            self?.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self?.start()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            guard newHeading.headingAccuracy >= 0 else { return } // skip uncalibrated
            let deg = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
            self?.heading   = deg
            self?.direction = CardinalDirection.from(degrees: deg)
            self?.accuracy  = newHeading.headingAccuracy
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }

    // MARK: - Formatted strings

    var degreesFormatted: String {
        String(format: "%03.0f°", heading)
    }

    func glassesLine(format: CompassFormat) -> String {
        switch format {
        case .full:    return "\(direction.arrow) \(direction.rawValue)  \(degreesFormatted)"
        case .compact: return "\(direction.arrow) \(direction.rawValue)"
        case .minimal: return direction.rawValue
        }
    }
}
