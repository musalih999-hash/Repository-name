import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/vpn_models.dart';

class VpnGateService {
  static final Uri endpoint = Uri.parse('http://www.vpngate.net/api/iphone/');

  Future<List<VpnServer>> fetchServers() async {
    final response = await http.get(endpoint, headers: {'Accept': 'text/plain'}).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('VPNGate HTTP ${response.statusCode}');
    final rows = parseCsvText(response.body);
    return rows.map(_toServer).where((server) => server != null).cast<VpnServer>().where((server) => server.isActive && server.configOvpn?.isNotEmpty == true).toList()
      ..sort((a, b) => (a.ping == 0 ? 999999 : a.ping).compareTo(b.ping == 0 ? 999999 : b.ping));
  }

  static List<Map<String, String>> parseCsvText(String text) {
    final lines = text.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty && !line.startsWith('*') && !line.startsWith('#')).toList();
    if (lines.isEmpty) return [];
    final header = _splitLine(lines.first);
    if (!header.contains('IP')) return [];
    return lines.skip(1).map((line) {
      final values = _splitLine(line);
      return <String, String>{for (var i = 0; i < header.length && i < values.length; i++) header[i] : values[i]};
    }).where((row) => row['IP'] != null).toList();
  }

  static List<String> _splitLine(String line) {
    final output = <String>[]; final buffer = StringBuffer(); var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') { if (quoted && i + 1 < line.length && line[i + 1] == '"') { buffer.write('"'); i++; } else { quoted = !quoted; } }
      else if (char == ',' && !quoted) { output.add(buffer.toString()); buffer.clear(); }
      else { buffer.write(char); }
    }
    output.add(buffer.toString()); return output;
  }

  VpnServer? _toServer(Map<String, String> row) {
    final ip = row['IP']?.trim() ?? '';
    final country = row['CountryLong']?.trim() ?? '';
    final short = row['CountryShort']?.trim() ?? '';
    final encoded = row['OpenVPN_ConfigData_Base64']?.trim() ?? '';
    if (ip.isEmpty || country.isEmpty || encoded.isEmpty) return null;
    try {
      final config = utf8.decode(base64.decode(base64.normalize(encoded)));
      final ping = int.tryParse(row['Ping'] ?? '') ?? 0;
      final speed = int.tryParse(row['Speed'] ?? '') ?? 0;
      return VpnServer(
        id: 'vpngate-$ip', country: country, countryShort: short, city: ip,
        flag: _flag(short), ping: ping, speed: speed, load: 0,
        isFastest: false, configAsset: '', configOvpn: config, endpointHost: ip,
        endpointPort: 1194, source: 'vpngate',
      );
    } catch (_) { return null; }
  }

  String _flag(String code) => code.length == 2 ? String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 127397 + c)) : '🌐';
}
