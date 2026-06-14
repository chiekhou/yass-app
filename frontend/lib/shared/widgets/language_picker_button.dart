import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/language_cubit.dart';

class LanguagePickerButton extends StatelessWidget {
  final Color iconColor;

  const LanguagePickerButton({super.key, this.iconColor = AppColors.white});

  static const _flags = {
    'fr': '🇫🇷',
    'ar': '🇩🇿',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'nl': '🇳🇱',
    'it': '🇮🇹',
  };

  void _show(BuildContext context) {
    final current = context.read<LanguageCubit>().state;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<LanguageCubit>(),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: AppDimens.paddingL,
            bottom:
                AppDimens.paddingL + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Langue',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimens.paddingM),
              ...LanguageCubit.supportedLocales.map((locale) {
                final isSelected = locale.languageCode == current.languageCode;
                final name = LanguageCubit.localeNames[locale.languageCode] ??
                    locale.languageCode;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isSelected ? AppColors.primaryGreen : AppColors.grey100,
                    radius: 18,
                    child: Text(
                      _flags[locale.languageCode] ?? '🌐',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primaryGreen : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    context.read<LanguageCubit>().changeLanguage(locale);
                    Navigator.pop(sheetCtx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: iconColor,
      tooltip: 'Langue',
      icon: Icon(Iconsax.language_square, color: iconColor),
      onPressed: () => _show(context),
    );
  }
}
