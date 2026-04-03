import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Barre de pagination réutilisable.
/// Affiche : [< Précédent]  [Page X / Y · N résultats]  [Suivant >]
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final bool isLoading;
  final void Function(int page) onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final hasPrev = currentPage > 1;
    final hasNext = currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Précédent
          _NavButton(
            label: 'Préc.',
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev && !isLoading,
            onTap: () => onPageChanged(currentPage - 1),
          ),

          // Indicateur central
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page $currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  '$total résultat${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),

          // Bouton Suivant
          _NavButton(
            label: 'Suiv.',
            icon: Icons.chevron_right_rounded,
            iconFirst: false,
            enabled: hasNext && !isLoading,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool iconFirst;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.iconFirst = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.primaryGreen : AppColors.grey300;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: enabled ? AppColors.primaryGreen : AppColors.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconFirst
              ? [Icon(icon, size: 18, color: color), const SizedBox(width: 2), Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))]
              : [Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)), const SizedBox(width: 2), Icon(icon, size: 18, color: color)],
        ),
      ),
    );
  }
}
