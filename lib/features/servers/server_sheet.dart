import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../data/models/vpn_models.dart';

class ServerSheet extends StatelessWidget {
  const ServerSheet({super.key, required this.servers, required this.selected});
  final List<VpnServer> servers;
  final VpnServer selected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DraggableScrollableSheet(
      initialChildSize: .72, maxChildSize: .92,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(color: AppColors.charcoal, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(children: [
          Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(strings.selectRoute, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            Text('${servers.length} ${strings.locations}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 18),
          Expanded(child: ListView.separated(
            controller: controller, itemCount: servers.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s = servers[i]; final isSelected = s.id == selected.id; final isGate = s.source == 'vpngate';
              return InkWell(
                onTap: () => Navigator.pop(context, s), borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isSelected ? AppColors.emerald.withOpacity(.1) : AppColors.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppColors.emerald.withOpacity(.55) : AppColors.line)),
                  child: Row(children: [
                    Text(s.flag, style: const TextStyle(fontSize: 30)), const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isGate ? '${s.country} • ${s.countryShort}' : s.city, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(isGate ? '${s.endpointHost}  •  ${s.speed ~/ 1000} Mbps' : '${s.country}  •  ${s.load}% load', style: const TextStyle(color: AppColors.mist, fontSize: 12)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: isGate ? AppColors.cyan.withOpacity(.12) : AppColors.graphite, borderRadius: BorderRadius.circular(8)), child: Text(isGate ? strings.ovpn : s.badge, style: TextStyle(color: isGate ? AppColors.cyan : AppColors.mist, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .8))),
                      const SizedBox(height: 6), Text('${s.ping} ms', style: const TextStyle(color: AppColors.mist, fontSize: 12)),
                    ]),
                  ]),
                ),
              );
            },
          )),
        ]),
      ),
    );
  }
}
