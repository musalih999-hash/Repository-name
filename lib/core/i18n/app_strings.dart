import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this.arabic);
  final bool arabic;
  static AppStrings of(BuildContext context) => AppStrings._(Localizations.localeOf(context).languageCode == 'ar');
  String get selectRoute => arabic ? 'اختر المسار' : 'SELECT ROUTE';
  String get locations => arabic ? 'موقع' : 'LOCATIONS';
  String get vpngate => arabic ? 'خوادم VPNGate المجانية' : 'FREE VPNGATE SERVERS';
  String get loading => arabic ? 'جاري جلب الخوادم…' : 'Loading servers…';
  String get connect => arabic ? 'اتصال' : 'CONNECT';
  String get ovpn => arabic ? 'OpenVPN' : 'OpenVPN';
  String get noServers => arabic ? 'لا توجد خوادم متاحة حالياً' : 'No active servers available';
}
