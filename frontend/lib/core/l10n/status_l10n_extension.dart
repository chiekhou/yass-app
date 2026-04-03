import 'package:win_app/l10n/app_localizations.dart';

extension StatusLocalization on AppLocalizations {
  /// Traduit un code de statut brut (venant du backend) dans la langue active.
  String statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'active':
        return statusActive;
      case 'rejected':
        return statusRejected;
      case 'suspended':
        return statusSuspended;
      case 'draft':
        return statusDraft;
      case 'approved':
        return statusApproved;
      case 'reported':
        return statusReported;
      default:
        return status ?? '';
    }
  }
}
