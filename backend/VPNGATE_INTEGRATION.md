# VPNGate integration

- Source: `http://www.vpngate.net/api/iphone/`
- The Flutter client ignores comment lines beginning with `*` or `#`.
- It parses CSV columns `CountryLong`, `CountryShort`, `IP`, `Speed`, `Ping`, and `OpenVPN_ConfigData_Base64`.
- The Base64 field is decoded to an `.ovpn` text configuration and held in memory only.
- Selecting a VPNGate server marks it as `source: vpngate`; the main connect button then sends the decoded text through `MethodChannel('vpn_luxe/openvpn')`.

## Important production requirements

1. Prefer an HTTPS proxy/cache under your control because the supplied endpoint is HTTP and Android/iOS may block cleartext traffic.
2. Do not persist VPNGate configs or private credentials in logs, analytics, Firestore, or crash reports.
3. Use a maintained OpenVPN native SDK / Packet Tunnel Provider on each platform. The included bridges are the integration boundary, not an OpenVPN engine.
4. Validate the downloaded profile before passing it to the SDK: allowed directives, certificates, remote host, and auth method.
5. VPNGate is a public third-party service with variable availability and trust characteristics. Show a consent/notice before connecting and do not present it as a privacy-guaranteed commercial VPN.
6. The API may change its CSV schema; keep parser tests with fixture data and enforce timeouts and maximum response size.
