import 'dart:async';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../data/models/vpn_models.dart';

class OpenVpnService {
  OpenVpnService() {
    _openvpn = OpenVPN(
      onVpnStatusChanged: (status) => _statusController.add(status.toString()),
      onVpnStageChanged: (stage, message) => _stageController.add('${stage.toString()}:$message'),
    );
  }

  late final OpenVPN _openvpn;
  final _statusController = StreamController<String>.broadcast();
  final _stageController = StreamController<String>.broadcast();
  bool _initialized = false;

  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get stageStream => _stageController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    await _openvpn.initialize(
      groupIdentifier: 'group.com.nova.vpn',
      providerBundleIdentifier: 'com.example.vpn_luxe.VPNExtension',
      localizedDescription: 'NOVA VPN',
    );
    _initialized = true;
  }

  Future<void> connect(VpnServer server) async {
    final config = server.configOvpn;
    if (config == null || config.isEmpty) throw StateError('Missing OpenVPN config');
    await initialize();
    _openvpn.connect(
      config,
      server.id,
      username: server.username,
      password: server.password,
      bypassPackages: const [],
      certIsRequired: false,
    );
  }

  Future<void> disconnect() async {
    await initialize();
    _openvpn.disconnect();
  }

  Future<bool> isSupported() async => true;

  Future<void> dispose() async {
    await _statusController.close();
    await _stageController.close();
  }
}
