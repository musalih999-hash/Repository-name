import 'package:flutter/services.dart';
import '../data/models/vpn_models.dart';

class WireGuardService {
  static const _channel = MethodChannel('vpn_luxe/wireguard');

  Future<void> connect(VpnServer server) async {
    await _channel.invokeMethod('connect', {'configAsset': server.configAsset, 'serverId': server.id});
  }

  Future<void> disconnect() => _channel.invokeMethod('disconnect');

  Future<void> setKillSwitch(bool enabled) => _channel.invokeMethod('setKillSwitch', {'enabled': enabled});

  Future<bool> isSupported() async => await _channel.invokeMethod<bool>('isSupported') ?? false;
}
