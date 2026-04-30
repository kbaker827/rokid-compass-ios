import Foundation
import Network

/// TCP server on port 8100.
/// Streams compass heading to glasses as a single JSON line on every update.
@MainActor
final class GlassesServer: ObservableObject {

    @Published var isRunning   = false
    @Published var clientCount = 0

    private var listener:    NWListener?
    private var connections: [NWConnection] = []
    private let port: NWEndpoint.Port = 8100
    private let queue = DispatchQueue(label: "CompassGlassesQ", qos: .userInteractive)

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        guard let l = try? NWListener(using: .tcp, on: port) else { return }
        listener = l
        l.newConnectionHandler = { [weak self] conn in
            Task { @MainActor [weak self] in self?.accept(conn) }
        }
        l.stateUpdateHandler = { [weak self] state in
            Task { @MainActor [weak self] in self?.isRunning = (state == .ready) }
        }
        l.start(queue: queue)
    }

    func stop() {
        listener?.cancel(); listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
        clientCount = 0; isRunning = false
    }

    // MARK: - Broadcast heading

    /// Called on every compass update. Sends a compact JSON line to all connected glasses.
    func broadcastHeading(line: String) {
        let dict: [String: String] = ["type": "compass", "text": line]
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        let packet = data + Data([0x0A]) // newline delimiter
        connections.forEach { conn in
            conn.send(content: packet, completion: .contentProcessed { _ in })
        }
    }

    func broadcastStatus(_ text: String) {
        let dict: [String: String] = ["type": "status", "text": text]
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        let packet = data + Data([0x0A])
        connections.forEach { conn in
            conn.send(content: packet, completion: .contentProcessed { _ in })
        }
    }

    // MARK: - Private

    private func accept(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                Task { @MainActor [weak self] in
                    self?.connections.removeAll { $0 === conn }
                    self?.clientCount = self?.connections.count ?? 0
                }
            default: break
            }
        }
        conn.start(queue: queue)
        connections.append(conn)
        clientCount = connections.count

        // Send a welcome packet immediately on connect
        broadcastStatus("Rokid Compass connected — heading data streaming on TCP :8100")
    }
}
