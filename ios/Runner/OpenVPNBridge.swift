import Flutter
import NetworkExtension

final class OpenVPNBridge {
    static let channelName = "vpn_luxe/openvpn"
    private let manager = NETunnelProviderManager()

    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "isSupported": result(true)
            case "connect":
                guard let args = call.arguments as? [String: Any], let config = args["config"] as? String, !config.isEmpty else { result(FlutterError(code: "MISSING_CONFIG", message: "OpenVPN config is empty", details: nil)); return }
                // Production: pass `config` to an OpenVPN Packet Tunnel Provider/SDK.
                self?.manager.connection.startVPNTunnel(); result(nil)
            case "disconnect": self?.manager.connection.stopVPNTunnel(); result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }
}
