import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Handles incoming deep links with the `win://` custom URL scheme.
///
/// Supported routes:
///   win://partner/subscription?success=1       → abonnement réussi
///   win://partner/subscription?failed=1        → abonnement échoué
///   win://partner/establishments/:id?featured_success=1
///   win://partner/establishments/:id?featured_failed=1
///   win://verify-email?token=...               → vérification email
///   win://reset-password?token=...             → réinitialisation mot de passe
class DeepLinkService {
  static final _appLinks = AppLinks();

  static Future<void> initialize(GoRouter router) async {
    // Liens reçus pendant que l'app est en cours d'exécution
    _appLinks.uriLinkStream.listen((uri) => _navigate(uri, router));

    // Lien qui a lancé l'app depuis un état fermé (cold start)
    // addPostFrameCallback garantit que GoRouter est prêt avant de naviguer
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigate(initial, router);
        });
      }
    } catch (_) {}
  }

  static void _navigate(Uri uri, GoRouter router) {
    if (uri.scheme != 'win') return;

    // Reconstruit le chemin GoRouter depuis win://host/path?query
    // Ex: win://partner/subscription?success=1 → /partner/subscription?success=1
    final host = uri.host; // "partner", "verify-email", "reset-password"
    final path = uri.path; // "/subscription", "/establishments/abc", ""
    final query = uri.query; // "success=1", "token=xxx"

    final routerPath = '/$host$path${query.isNotEmpty ? '?$query' : ''}';
    router.go(routerPath);
  }
}
