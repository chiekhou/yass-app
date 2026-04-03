import 'package:flutter/foundation.dart';

/// Configuration injectée au moment du build via --dart-define-from-file
///
/// Dev :  flutter run --dart-define-from-file=.env.dev.json
/// Prod : flutter build apk --dart-define-from-file=.env.prod.json
class AppConfig {
  AppConfig._();

  // ── API ────────────────────────────────────────────────────────────────────
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.108:3000/api/v1',
  );

  // ── Localisation de test (DEV uniquement) ──────────────────────────────────
  // Coordonnées d'Alger — utilisées uniquement en kDebugMode quand définies.
  static const String _devLatStr = String.fromEnvironment('DEV_LATITUDE',  defaultValue: '');
  static const String _devLngStr = String.fromEnvironment('DEV_LONGITUDE', defaultValue: '');

  /// Retourne les coordonnées de test si elles sont configurées ET qu'on est
  /// en mode debug. Retourne null en production ou si non configurées.
  static ({double lat, double lng})? get devLocation {
    if (!kDebugMode) return null;
    final lat = double.tryParse(_devLatStr);
    final lng = double.tryParse(_devLngStr);
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  // ── Feature flags ──────────────────────────────────────────────────────────
  static const bool enableLogs = kDebugMode;
}
