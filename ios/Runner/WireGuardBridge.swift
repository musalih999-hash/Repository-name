import Flutter
import NetworkExtension

final class WireGuardBridge {
    static let channelName = "vpn_luxe/wireguard"
    private let manager = NETunnelProviderManager()

    func register(with controller: FlutterViewController) {
        let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "isSupported": result(true)
            case "connect":
                // Production: configure NETunnelProviderProtocol with a WireGuard provider extension.
                // The provider extension owns parsing and applying the tunnel configuration.
                self?.manager.connection.startVPNTunnel()
                result(nil)
            case "disconnect":
                self?.manager.connection.stopVPNTunnel(); result(nil)
            case "setKillSwitch":
                // Production: enforce always-on semantics in the Network Extension entitlement/profile.
                result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }
}
