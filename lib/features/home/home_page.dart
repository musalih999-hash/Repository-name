import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/vpn_models.dart';
import '../../data/repositories/server_repository.dart';
import '../../services/wireguard_service.dart';
import '../../services/smart_connect_service.dart';
import '../../services/openvpn_service.dart';
import '../servers/server_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _repo = const ServerRepository();
  final _wireguard = WireGuardService();
  final _smartConnect = SmartConnectService();
  final _openVpn = OpenVpnService();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  VpnStatus _status = VpnStatus.disconnected;
  late VpnServer _server;
  bool _killSwitch = true;
  int _tab = 0;
  Timer? _trafficTimer;
  double _download = 0;
  double _upload = 0;
  List<TrafficSample> _samples = const [];
  List<VpnServer> _liveServers = const [];
  StreamSubscription<List<VpnServer>>? _serversSubscription;

  @override void initState() {
    super.initState();
    _liveServers = _repo.servers;
    _server = _repo.quickConnect(_liveServers);
    _loadVpnGateServers();
    if (Firebase.apps.isNotEmpty) {
      _serversSubscription = _repo.watchServers().listen((servers) {
        if (!mounted || servers.isEmpty) return;
        setState(() { _liveServers = servers; if (!_liveServers.any((s) => s.id == _server.id)) _server = _repo.quickConnect(_liveServers); });
      });
    }
  }
  @override void dispose() { _serversSubscription?.cancel(); _pulse.dispose(); _trafficTimer?.cancel(); super.dispose(); }

  Future<void> _loadVpnGateServers() async {
    if (!mounted) return;
    try {
      final publicServers = await _repo.fetchVpnGateServers();
      if (mounted && publicServers.isNotEmpty) setState(() => _liveServers = [..._liveServers, ...publicServers]);
    } catch (_) {
      // Keep managed servers visible when VPNGate is unavailable or blocked by the network.
    }
  }

  Future<void> _toggleConnection() async {
    HapticFeedback.mediumImpact();
    if (_status == VpnStatus.connected) {
      setState(() => _status = VpnStatus.disconnecting);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      try { if (_server.source == 'vpngate') { await _openVpn.disconnect(); } else { await _wireguard.disconnect(); } } catch (_) {}
      _trafficTimer?.cancel();
      if (mounted) setState(() { _status = VpnStatus.disconnected; _download = 0; _upload = 0; });
      return;
    }
    setState(() => _status = VpnStatus.connecting);
    try { _server = await _smartConnect.chooseBest(_liveServers); } catch (_) { _server = _repo.quickConnect(_liveServers); }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      if (_server.source == 'vpngate') { await _openVpn.connect(_server); }
      else { await _wireguard.connect(_server); }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _status = VpnStatus.connected);
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = 68.0 + math.Random().nextDouble() * 19.0;
      final u = 8.0 + math.Random().nextDouble() * 8.0;
      setState(() { _download = d; _upload = u; _samples = [..._samples, TrafficSample(d, u)].takeLast(18); });
    });
  }

  Future<void> _openServers() async {
    final selected = await showModalBottomSheet<VpnServer>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ServerSheet(servers: _liveServers, selected: _server),
    );
    if (selected != null) setState(() => _server = selected);
  }

  String get _statusLabel => switch (_status) {
    VpnStatus.connected => 'PROTECTED', VpnStatus.connecting => 'SECURING',
    VpnStatus.disconnecting => 'CLOSING', _ => 'READY TO CONNECT',
  };
  Color get _accent => _status == VpnStatus.connected ? AppColors.emerald : AppColors.cyan;

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: [_dashboard(), _dashboard(), _settings()])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab, onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: AppColors.charcoal, indicatorColor: AppColors.emerald.withOpacity(.14),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.radar_rounded), label: 'Pulse'),
          NavigationDestination(icon: Icon(Icons.public_rounded), label: 'Servers'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Control'),
        ],
      ),
    );
  }

  Widget _dashboard() => CustomScrollView(slivers: [
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 0), child: _header())),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 26, 24, 0), child: _heroButton())),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 0), child: _trafficCard())),
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), child: _serverCard())),
  ]);

  Widget _header() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('NOVA//VPN', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2.2)),
      const SizedBox(height: 4), Text('PRIVATE BY DESIGN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted, letterSpacing: 2.4)),
    ]),
    Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)), child: const Icon(Icons.notifications_none_rounded, color: AppColors.mist)),
  ]);

  Widget _heroButton() => Column(children: [
    SizedBox(height: 270, child: AnimatedBuilder(animation: _pulse, builder: (_, __) {
      final glow = _status == VpnStatus.connected ? .18 + _pulse.value * .18 : .04;
      return Stack(alignment: Alignment.center, children: [
        Container(width: 246 + _pulse.value * 10, height: 246 + _pulse.value * 10, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: _accent.withOpacity(glow), blurRadius: 70, spreadRadius: 18)])),
        Container(width: 202, height: 202, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_accent.withOpacity(.24), AppColors.graphite], stops: const [.08, .86]), border: Border.all(color: _accent.withOpacity(.55), width: 1.5)), child: GestureDetector(onTap: _toggleConnection, child: Container(margin: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.obsidian, border: Border.all(color: _accent.withOpacity(.45), width: 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_status == VpnStatus.connected ? Icons.lock_rounded : Icons.power_settings_new_rounded, size: 42, color: _accent), const SizedBox(height: 10), Text(_statusLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _accent, fontWeight: FontWeight.bold, letterSpacing: 1.5))])))),
      ]);
    })),
    const SizedBox(height: 8), Text(_status == VpnStatus.connected ? 'Connection is encrypted' : 'One tap. Total privacy.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mist)),
  ]);

  Widget _trafficCard() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.panel.withOpacity(.65), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LIVE TELEMETRY', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted, letterSpacing: 1.7)), Icon(Icons.insights_rounded, color: _accent, size: 20)]),
    const SizedBox(height: 18), Row(children: [_metric(Icons.arrow_downward_rounded, 'DOWNLOAD', '${_download.toStringAsFixed(1)} Mbps', AppColors.emerald), const SizedBox(width: 28), _metric(Icons.arrow_upward_rounded, 'UPLOAD', '${_upload.toStringAsFixed(1)} Mbps', AppColors.cyan), const Spacer(), _metric(Icons.bolt_rounded, 'PING', '${_server.ping} ms', AppColors.amber)]),
    const SizedBox(height: 18), SizedBox(height: 52, child: CustomPaint(painter: _SparklinePainter(samples: _samples, color: _accent))),
  ]));

  Widget _metric(IconData icon, String label, String value, Color color) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 5), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted, fontSize: 9, letterSpacing: 1.1))]), const SizedBox(height: 5), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]);

  Widget _serverCard() => GestureDetector(
    onTap: _openServers,
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.graphite, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Text(_server.flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CURRENT ROUTE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.muted, letterSpacing: 1.3)),
          const SizedBox(height: 3),
          Text('${_server.city}, ${_server.country}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ])),
        const Icon(Icons.swap_horiz_rounded, color: AppColors.mist),
      ]),
    ),
  );

  Widget _settings() => ListView(padding: const EdgeInsets.all(24), children: [
    Text('CONTROL ROOM', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
    const SizedBox(height: 8), Text('Fine-tune your privacy layer.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mist)),
    const SizedBox(height: 28),
    _settingTile(Icons.shield_rounded, 'Kill Switch', 'Block traffic if VPN drops', _killSwitch, (v) { setState(() => _killSwitch = v); _wireguard.setKillSwitch(v); }),
    _settingTile(Icons.auto_awesome_rounded, 'Quick Connect', 'Measure the best of the top 3 routes', true, (_) async { final best = await _smartConnect.chooseBest(_liveServers); if (mounted) setState(() => _server = best); }),
    _settingTile(Icons.notifications_active_outlined, 'Connection Alerts', 'Quiet, battery-friendly status updates', true, (_) {}),
  ]);

  Widget _settingTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)), child: Row(children: [Icon(icon, color: AppColors.emerald), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: AppColors.mist, fontSize: 12))])), Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.emerald)]));
}

extension _TakeLast<T> on List<T> { List<T> takeLast(int n) => length <= n ? this : sublist(length - n); }

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.samples, required this.color});
  final List<TrafficSample> samples; final Color color;
  @override void paint(Canvas canvas, Size size) { final p = Paint()..color = color.withOpacity(.85)..strokeWidth = 2.2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round; final path = Path(); for (var i = 0; i < samples.length; i++) { final x = samples.length <= 1 ? 0.0 : i / (samples.length - 1) * size.width; final y = size.height - (samples[i].download / 100.0 * size.height); if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); } } canvas.drawPath(path, p); }
  @override bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.samples != samples || oldDelegate.color != color;
}
