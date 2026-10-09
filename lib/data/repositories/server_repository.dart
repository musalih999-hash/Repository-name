import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/vpn_models.dart';
import '../../services/vpngate_service.dart';

class ServerRepository {
  const ServerRepository();
  static final VpnGateService _vpnGate = VpnGateService();

  List<VpnServer> get servers => const [
    VpnServer(id: 'de-fra-01', country: 'Germany', city: 'Frankfurt', flag: '🇩🇪', ping: 28, load: 31, isFastest: true, configAsset: 'assets/wireguard/de-fra-01.conf', endpointHost: 'fra.example-vpn.com'),
    VpnServer(id: 'nl-ams-01', country: 'Netherlands', city: 'Amsterdam', flag: '🇳🇱', ping: 34, load: 42, isFastest: false, configAsset: 'assets/wireguard/nl-ams-01.conf', endpointHost: 'ams.example-vpn.com'),
    VpnServer(id: 'uk-lon-01', country: 'United Kingdom', city: 'London', flag: '🇬🇧', ping: 47, load: 24, isFastest: false, configAsset: 'assets/wireguard/uk-lon-01.conf', endpointHost: 'lon.example-vpn.com'),
    VpnServer(id: 'sg-sin-01', country: 'Singapore', city: 'Singapore', flag: '🇸🇬', ping: 88, load: 18, isFastest: false, configAsset: 'assets/wireguard/sg-sin-01.conf', endpointHost: 'sin.example-vpn.com'),
  ];

  Stream<List<VpnServer>> watchServers() {
    if (Firebase.apps.isEmpty) return Stream.value(servers);
    try {
      return FirebaseFirestore.instance.collection('vpn_servers').where('is_active', isEqualTo: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => VpnServer.fromMap({...doc.data(), 'id': doc.id})).toList());
    } catch (_) { return Stream.value(servers); }
  }

  Future<List<VpnServer>> fetchVpnGateServers() => _vpnGate.fetchServers();

  VpnServer quickConnect([List<VpnServer>? source]) {
    final active = (source ?? servers).where((s) => s.isActive).toList();
    return active.reduce((a, b) => a.ping < b.ping ? a : b);
  }
}
