import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseSafely();
  runApp(const NovaVpnApp());
}

class NovaVpnApp extends StatelessWidget {
  const NovaVpnApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'NOVA VPN', theme: buildAppTheme(),
    supportedLocales: const [Locale('en'), Locale('ar')],
    localeResolutionCallback: (locale, supported) => supported.firstWhere((item) => item.languageCode == locale?.languageCode, orElse: () => const Locale('en')),
    home: const HomePage(),
  );
}
