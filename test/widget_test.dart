import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_luxe/main.dart';

void main() {
  testWidgets('NOVA VPN home renders', (tester) async {
    await tester.pumpWidget(const NovaVpnApp());
    expect(find.text('NOVA//VPN'), findsOneWidget);
    expect(find.text('READY TO CONNECT'), findsOneWidget);
  });
}
