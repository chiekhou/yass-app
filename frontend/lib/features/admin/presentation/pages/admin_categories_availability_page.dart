import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/admin_drawer.dart';

class AdminCategoriesAvailabilityPage extends StatefulWidget {
  const AdminCategoriesAvailabilityPage({super.key});

  @override
  State<AdminCategoriesAvailabilityPage> createState() =>
      _AdminCategoriesAvailabilityPageState();
}

class _AdminCategoriesAvailabilityPageState
    extends State<AdminCategoriesAvailabilityPage> {
  final _repo = AdminRepository();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getAdminCategories();
      if (mounted) setState(() { _categories = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(String id, int index) async {
    if (_toggling.contains(id)) return;
    setState(() => _toggling.add(id));
    try {
      final result = await _repo.toggleCategory(id);
      if (mounted) {
        setState(() {
          _categories[index] = {..._categories[index], 'is_active': result['is_active']};
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _categories.where((c) => c['is_active'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          context.l10n.categoriesAvailability,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      drawer: const AdminDrawer(currentRoute: '/admin/categories'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : Column(
              children: [
                _buildHeader(activeCount),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(
      margin: const EdgeInsets.all(AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.category, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              '$activeCount catégorie${activeCount > 1 ? 's' : ''} active${activeCount > 1 ? 's' : ''} sur ${_categories.length}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingS),
      itemBuilder: (context, i) {
        final cat = _categories[i];
        final id = cat['id']?.toString() ?? '';
        final isActive = cat['is_active'] == true;
        final isToggling = _toggling.contains(id);
        final colorHex = cat['color'] as String?;
        Color accentColor = AppColors.primaryGreen;
        if (colorHex != null) {
          try {
            accentColor = Color(
              int.parse(colorHex.replaceFirst('#', '0xFF')),
            );
          } catch (_) {}
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.2)
                  : const Color(0xFFF0F0F0),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingM,
              vertical: AppDimens.paddingXS,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor.withValues(alpha: 0.12)
                    : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Icon(
                Iconsax.category,
                size: 20,
                color: isActive ? accentColor : AppColors.grey400,
              ),
            ),
            title: Text(
              cat['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? const Color(0xFF1A1A1A) : AppColors.grey500,
              ),
            ),
            subtitle: Text(
              cat['name_ar'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.grey600 : AppColors.grey400,
              ),
            ),
            trailing: isToggling
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : Switch(
                    value: isActive,
                    onChanged: (_) => _toggle(id, i),
                    activeTrackColor: AppColors.primaryGreen,
                  ),
          ),
        );
      },
    );
  }
}
