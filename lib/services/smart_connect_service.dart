import 'dart:async';
import 'dart:io';
import '../data/models/vpn_models.dart';

class SmartConnectService {
  Future<VpnServer> chooseBest(List<VpnServer> servers) async {
    final candidates = servers.where((s) => s.isActive).toList()
      ..sort((a, b) => a.ping.compareTo(b.ping));
    final topThree = candidates.take(3).toList();
    if (topThree.isEmpty) throw StateError('No active VPN servers available');
    final measured = await Future.wait(topThree.map(_measure));
    measured.sort((a, b) => a.rttMs.compareTo(b.rttMs));
    return measured.first.server;
  }

  Future<_Measurement> _measure(VpnServer server) async {
    final host = server.endpointHost;
    if (host == null || host.isEmpty) return _Measurement(server, server.ping);
    final started = Stopwatch()..start();
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .timeout(const Duration(seconds: 2));
      final address = (await InternetAddress.lookup(host)).first;
      socket.send(const [0x4e, 0x4f, 0x56, 0x41], address, server.endpointPort);
      await socket.first.timeout(const Duration(milliseconds: 1200));
      return _Measurement(server, started.elapsedMilliseconds);
    } catch (_) {
      return _Measurement(server, server.ping + 250);
    } finally {
      socket?.close();
    }
  }
}

class _Measurement {
  const _Measurement(this.server, this.rttMs);
  final VpnServer server;
  final int rttMs;
}
