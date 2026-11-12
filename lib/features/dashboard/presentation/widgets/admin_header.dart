import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawerButton;
  final VoidCallback? onOpenDrawer;

  const AdminHeader({
    super.key,
    required this.title,
    this.showDrawerButton = false,
    this.onOpenDrawer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'Administrator';

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (showDrawerButton)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primaryNavy),
              onPressed: onOpenDrawer,
              tooltip: 'Open navigation',
            ),
          if (showDrawerButton) const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTypography.headingSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.softBlueBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'CMS Admin',
                    style: AppTypography.bodySmall(
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softGrayBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 18,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    userEmail,
                    style: AppTypography.bodySmall(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary, size: 20),
            tooltip: AppStrings.logout,
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    AppStrings.logoutConfirmTitle,
                    style: AppTypography.headingSmall(),
                  ),
                  content: Text(
                    AppStrings.logoutConfirmMessage,
                    style: AppTypography.bodyMedium(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: AppColors.surfaceWhite,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              ).then((confirmed) {
                if (confirmed == true) {
                  ref.read(authControllerProvider.notifier).signOut();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

