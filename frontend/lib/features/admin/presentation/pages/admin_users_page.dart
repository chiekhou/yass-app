import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app_router.dart';
import '../../data/models/admin_user_model.dart';
import '../bloc/admin_users_bloc.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/user_list_item.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AdminUsersBloc>().add(const AdminUsersLoad());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminUsersBloc>().add(AdminUsersLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: AppRoutes.adminUsers),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          Expanded(child: _buildUsersList(context)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      color: AppColors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un utilisateur...',
          prefixIcon: const Icon(Iconsax.search_normal, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<AdminUsersBloc>()
                        .add(const AdminUsersSearch(query: ''));
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.grey100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
        ),
        onChanged: (value) {
          context.read<AdminUsersBloc>().add(AdminUsersSearch(query: value));
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return BlocBuilder<AdminUsersBloc, AdminUsersState>(
      builder: (context, state) {
        String? roleFilter;
        String? statusFilter;

        if (state is AdminUsersLoaded) {
          roleFilter = state.roleFilter;
          statusFilter = state.statusFilter;
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM,
            vertical: AppDimens.paddingS,
          ),
          color: AppColors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'Tous les rôles',
                  isSelected: roleFilter == null,
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: null)),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Utilisateurs',
                  isSelected: roleFilter == 'user',
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'user')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Partenaires',
                  isSelected: roleFilter == 'partner',
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'partner')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Admins',
                  isSelected: roleFilter == 'admin',
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'admin')),
                ),
                const SizedBox(width: AppDimens.paddingM),
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.grey300,
                ),
                const SizedBox(width: AppDimens.paddingM),
                _buildFilterChip(
                  context,
                  label: 'Actifs',
                  isSelected: statusFilter == 'active',
                  color: AppColors.success,
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'active')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Inactifs',
                  isSelected: statusFilter == 'inactive',
                  color: AppColors.grey500,
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'inactive')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'En attente',
                  isSelected: statusFilter == 'pending',
                  color: AppColors.warning,
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'pending')),
                ),
                const SizedBox(width: AppDimens.paddingS),
                _buildFilterChip(
                  context,
                  label: 'Suspendus',
                  isSelected: statusFilter == 'suspended',
                  color: AppColors.error,
                  onTap: () => context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'suspended')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM,
          vertical: AppDimens.paddingS,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? chipColor.withValues(alpha: 0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? chipColor : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return BlocBuilder<AdminUsersBloc, AdminUsersState>(
      builder: (context, state) {
        if (state is AdminUsersLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (state is AdminUsersError) {
          return _buildErrorState(state.message);
        }

        if (state is AdminUsersLoaded) {
          if (state.users.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminUsersBloc>().add(AdminUsersRefresh());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primaryGreen,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingM),
              itemCount: state.users.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.users.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.paddingM),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final user = state.users[index];
                return UserListItem(
                  user: user,
                  onTap: () => context.push(
                    AppRoutes.adminUserDetails.replaceFirst(':id', user.id),
                  ),
                  onStatusTap: () => _showStatusDialog(context, user),
                  onDeleteTap: () => _showDeleteDialog(context, user),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<AdminUsersBloc>().add(const AdminUsersLoad()),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.people, size: 64, color: AppColors.grey400),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              'Aucun utilisateur trouvé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              'Essayez de modifier vos filtres de recherche',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final bloc = context.read<AdminUsersBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: _FilterBottomSheet(),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Iconsax.tick_circle, color: AppColors.success),
              title: const Text('Actif'),
              selected: user.status == 'active',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<AdminUsersBloc>().add(
                      AdminUserUpdateStatus(userId: user.id, status: 'active'),
                    );
              },
            ),
            ListTile(
              leading:
                  const Icon(Iconsax.minus_cirlce, color: AppColors.grey500),
              title: const Text('Inactif'),
              selected: user.status == 'inactive',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<AdminUsersBloc>().add(
                      AdminUserUpdateStatus(
                          userId: user.id, status: 'inactive'),
                    );
              },
            ),
            ListTile(
              leading:
                  const Icon(Iconsax.clock, color: AppColors.warning),
              title: const Text('En attente'),
              selected: user.status == 'pending',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<AdminUsersBloc>().add(
                      AdminUserUpdateStatus(
                          userId: user.id, status: 'pending'),
                    );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.slash, color: AppColors.error),
              title: const Text('Suspendu'),
              selected: user.status == 'suspended',
              onTap: () {
                Navigator.pop(dialogContext);
                context.read<AdminUsersBloc>().add(
                      AdminUserUpdateStatus(
                          userId: user.id, status: 'suspended'),
                    );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.fullName} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AdminUsersBloc>().add(
                    AdminUserDelete(userId: user.id),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  context.read<AdminUsersBloc>().add(const AdminUsersLoad());
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'Rôle',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Wrap(
            spacing: AppDimens.paddingS,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: null));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Utilisateur'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'user'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Partenaire'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'partner'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Admin'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByRole(role: 'admin'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          Wrap(
            spacing: AppDimens.paddingS,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: null));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Actif'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'active'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Inactif'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'inactive'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('En attente'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'pending'));
                  Navigator.pop(context);
                },
              ),
              FilterChip(
                label: const Text('Suspendu'),
                selected: false,
                onSelected: (_) {
                  context
                      .read<AdminUsersBloc>()
                      .add(const AdminUsersFilterByStatus(status: 'suspended'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingL),
        ],
      ),
    );
  }
}
