import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/admin_drawer.dart';

class AdminWilayasPage extends StatefulWidget {
  const AdminWilayasPage({super.key});

  @override
  State<AdminWilayasPage> createState() => _AdminWilayasPageState();
}

class _AdminWilayasPageState extends State<AdminWilayasPage> {
  final _repo = AdminRepository();
  List<Map<String, dynamic>> _wilayas = [];
  bool _isLoading = true;
  bool _isBulkLoading = false;
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getAdminWilayas();
      if (mounted) setState(() { _wilayas = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(String id, int index) async {
    if (_toggling.contains(id)) return;
    setState(() => _toggling.add(id));
    try {
      final result = await _repo.toggleWilaya(id);
      if (mounted) {
        setState(() {
          _wilayas[index] = {..._wilayas[index], 'is_active': result['is_active']};
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

  Future<void> _toggleAll(bool targetActive) async {
    final toChange = _wilayas
        .asMap()
        .entries
        .where((e) => (e.value['is_active'] == true) != targetActive)
        .toList();

    if (toChange.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              targetActive ? Iconsax.tick_circle : Iconsax.close_circle,
              size: 20,
              color: targetActive ? AppColors.primaryGreen : AppColors.primaryRed,
            ),
            const SizedBox(width: 8),
            Text(
              targetActive ? 'Tout activer' : 'Tout désactiver',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: Text(
          targetActive
              ? 'Activer les ${toChange.length} wilayas désactivées ?'
              : 'Désactiver les ${toChange.length} wilayas actives ?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: targetActive ? AppColors.primaryGreen : AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: Text(targetActive ? 'Tout activer' : 'Tout désactiver'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBulkLoading = true);

    try {
      final results = await Future.wait(
        toChange.map((e) => _repo.toggleWilaya(e.value['id'].toString())),
      );

      if (mounted) {
        setState(() {
          for (var i = 0; i < toChange.length; i++) {
            final idx = toChange[i].key;
            _wilayas[idx] = {..._wilayas[idx], 'is_active': results[i]['is_active']};
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isBulkLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _wilayas.where((w) => w['is_active'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          context.l10n.wilayasAvailability,
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
      drawer: const AdminDrawer(currentRoute: '/admin/wilayas'),
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
    final allActive = activeCount == _wilayas.length;
    final allInactive = activeCount == 0;

    return Container(
      margin: const EdgeInsets.all(AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Text(
                  '$activeCount wilaya${activeCount > 1 ? 's' : ''} active${activeCount > 1 ? 's' : ''} sur ${_wilayas.length}',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_isBulkLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
            ],
          ),
          if (!_isBulkLoading) ...[
            const SizedBox(height: AppDimens.paddingS),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: allActive ? null : () => _toggleAll(true),
                    icon: const Icon(Iconsax.tick_circle, size: 16),
                    label: const Text('Tout activer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: BorderSide(
                        color: allActive
                            ? AppColors.grey300
                            : AppColors.primaryGreen,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.paddingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: allInactive ? null : () => _toggleAll(false),
                    icon: const Icon(Iconsax.close_circle, size: 16),
                    label: const Text('Tout désactiver'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: BorderSide(
                        color: allInactive
                            ? AppColors.grey300
                            : AppColors.primaryRed,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      itemCount: _wilayas.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.paddingS),
      itemBuilder: (context, i) {
        final w = _wilayas[i];
        final id = w['id']?.toString() ?? '';
        final isActive = w['is_active'] == true;
        final isToggling = _toggling.contains(id);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryGreen.withValues(alpha: 0.15)
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
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  w['code'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primaryGreen : AppColors.grey500,
                  ),
                ),
              ),
            ),
            title: Text(
              w['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? const Color(0xFF1A1A1A) : AppColors.grey500,
              ),
            ),
            subtitle: Text(
              w['name_ar'] ?? '',
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
                    onChanged: _isBulkLoading ? null : (_) => _toggle(id, i),
                    activeTrackColor: AppColors.primaryGreen,
                  ),
          ),
        );
      },
    );
  }
}
