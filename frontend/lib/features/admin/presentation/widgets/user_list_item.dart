import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_user_model.dart';

class UserListItem extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onDeleteTap;

  const UserListItem({
    super.key,
    required this.user,
    this.onTap,
    this.onStatusTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.scaffoldBackground,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingXS,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        side: BorderSide(color: AppColors.grey200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: AppDimens.paddingM),
              Expanded(child: _buildUserInfo(context)),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: _getRoleColor().withValues(alpha: 0.1),
      backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
      child: user.avatar == null
          ? Text(
              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(context),
          ],
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimens.paddingXS),
        Row(
          children: [
            _buildRoleBadge(context),
            if (user.emailVerified) ...[
              const SizedBox(width: AppDimens.paddingS),
              Icon(
                Iconsax.verify5,
                size: 14,
                color: AppColors.success,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (user.status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'inactive':
        color = AppColors.grey500;
        break;
      case 'pending':
        color = AppColors.warning;
        break;
      case 'suspended':
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Text(
        user.statusLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingS,
        vertical: AppDimens.paddingXS,
      ),
      decoration: BoxDecoration(
        color: _getRoleColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXS),
      ),
      child: Text(
        user.roleLabel,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getRoleColor(),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.scaffoldBackground,
      icon: const Icon(Iconsax.more, color: AppColors.grey600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              const Icon(Iconsax.eye, size: 18),
              const SizedBox(width: AppDimens.paddingS),
              const Text('Voir détails'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              const Icon(Iconsax.edit, size: 18),
              const SizedBox(width: AppDimens.paddingS),
              const Text('Modifier statut'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Iconsax.trash, size: 18, color: AppColors.error),
              const SizedBox(width: AppDimens.paddingS),
              Text('Supprimer', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'view':
            onTap?.call();
            break;
          case 'status':
            onStatusTap?.call();
            break;
          case 'delete':
            onDeleteTap?.call();
            break;
        }
      },
    );
  }

  Color _getRoleColor() {
    switch (user.role) {
      case 'admin':
      case 'super_admin':
        return AppColors.primaryRed;
      case 'partner':
        return AppColors.primaryGreen;
      default:
        return AppColors.info;
    }
  }
}
