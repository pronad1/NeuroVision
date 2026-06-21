// lib/src/services/server_config.dart
// Persists the AI-server base URL in SharedPreferences so it can be changed
// at runtime — no rebuild needed when the PC's IP changes on a new Wi-Fi.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  ServerConfig._();
  static final ServerConfig instance = ServerConfig._();

  // ── Defaults ───────────────────────────────────────────────────────────────
  /// Fallback used when the user has never saved a custom IP.
  static const String _defaultAndroidIp = '192.168.0.196';
  static const int _defaultPort = 8000;
  static const String _prefKey = 'nv_server_base_url';

  // ── State ──────────────────────────────────────────────────────────────────
  String _baseUrl = 'http://$_defaultAndroidIp:$_defaultPort/api/v1';

  /// The full base URL used by [AIService] (e.g. "http://192.168.1.5:8000/api/v1").
  String get baseUrl => _baseUrl;

  /// The host+port portion for display (e.g. "192.168.1.5:8000").
  String get hostPort {
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null) return _baseUrl;
    return '${uri.host}:${uri.port}';
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  /// Call once at app startup (before runApp or inside main()).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _baseUrl = saved;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  /// Save a new server IP (and optional port). Notifies listeners so the UI
  /// can reflect the change immediately.
  ///
  /// [ip] e.g. "192.168.1.5"
  /// [port] defaults to 8000
  Future<void> setServer(String ip, {int port = _defaultPort}) async {
    final url = 'http://$ip:$port/api/v1';
    _baseUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, url);
  }

  /// Reset to factory default.
  Future<void> resetToDefault() async {
    await setServer(_defaultAndroidIp, port: _defaultPort);
  }

  /// Returns true if the given string looks like a valid IPv4 address.
  static bool isValidIp(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4) return false;
    return parts.every((p) {
      final n = int.tryParse(p);
      return n != null && n >= 0 && n <= 255;
    });
  }
}
