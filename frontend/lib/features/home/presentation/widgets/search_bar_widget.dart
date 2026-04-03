import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.search_normal_1,
              color: AppColors.grey500,
              size: AppDimens.iconS,
            ),
            const SizedBox(width: AppDimens.paddingM),
            Expanded(
              child: onTap != null
                  ? Text(
                      context.l10n.searchHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                          ),
                    )
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      autofocus: autofocus,
                      enabled: enabled,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: context.l10n.searchHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: const Icon(
                Iconsax.setting_4,
                color: AppColors.white,
                size: AppDimens.iconS,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
