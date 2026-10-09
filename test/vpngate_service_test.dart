import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_luxe/services/vpngate_service.dart';

void main() {
  test('VPNGate parser ignores comments and decodes OVPN config', () {
    final config = '[client]\nremote 203.0.113.10 1194';
    final encoded = base64.encode(utf8.encode(config));
    final csv = '* VPNGate API\n# comment\nCountryShort,CountryLong,IP,Speed,Ping,OpenVPN_ConfigData_Base64\nJP,Japan,203.0.113.10,10000000,42,$encoded\n';
    final rows = VpnGateService.parseCsvText(csv);
    expect(rows, hasLength(1));
    expect(rows.single['CountryLong'], 'Japan');
    expect(utf8.decode(base64.decode(rows.single['OpenVPN_ConfigData_Base64']!)), contains('[client]'));
  });
}
