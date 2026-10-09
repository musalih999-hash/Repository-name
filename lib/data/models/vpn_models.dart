enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

class VpnServer {
  const VpnServer({
    required this.id,
    required this.country,
    required this.city,
    required this.flag,
    required this.ping,
    required this.load,
    required this.isFastest,
    required this.configAsset,
    this.endpointHost,
    this.endpointPort = 51820,
    this.isActive = true,
    this.tags = const [],
    this.countryShort = '',
    this.speed = 0,
    this.configOvpn,
    this.source = 'managed',
    this.username,
    this.password,
  });

  final String id;
  final String country;
  final String city;
  final String flag;
  final int ping;
  final int load;
  final bool isFastest;
  final String configAsset;
  final String? endpointHost;
  final int endpointPort;
  final bool isActive;
  final List<String> tags;
  final String countryShort;
  final int speed;
  final String? configOvpn;
  final String source;
  final String? username;
  final String? password;

  String get badge => isFastest ? 'FASTEST' : ping < 45 ? 'LOW PING' : 'STABLE';
  bool get isFastestLive => tags.contains('FASTEST') || isFastest;

  factory VpnServer.fromMap(Map<String, dynamic> map) => VpnServer(
    id: map['id'] as String,
    country: map['country'] as String? ?? '', city: map['city'] as String? ?? '',
    flag: map['flag'] as String? ?? '🌐',
    ping: (map['ping_ms'] as num?)?.round() ?? (map['ping'] as num?)?.round() ?? 999,
    load: (map['load'] as num?)?.round() ?? 0,
    isFastest: (map['tags'] as List<dynamic>?)?.contains('FASTEST') ?? false,
    configAsset: map['config_asset'] as String? ?? '',
    endpointHost: map['endpoint_host'] as String?,
    endpointPort: (map['endpoint_port'] as num?)?.round() ?? 51820,
    isActive: map['is_active'] as bool? ?? true,
    tags: List<String>.from(map['tags'] as List<dynamic>? ?? const []),
    countryShort: map['country_short'] as String? ?? '',
    speed: (map['speed'] as num?)?.round() ?? 0,
    configOvpn: map['config_ovpn'] as String?,
    source: map['source'] as String? ?? 'managed',
    username: map['username'] as String?,
    password: map['password'] as String?,
  );
}

class TrafficSample {
  const TrafficSample(this.download, this.upload);
  final double download;
  final double upload;
}
