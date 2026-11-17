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
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'Administrator';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isVeryNarrow = constraints.maxWidth < 400;

        return Container(
          height: preferredSize.height,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            border: const Border(
              bottom: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (showDrawerButton)
                IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.primaryNavy),
                  onPressed: onOpenDrawer,
                  tooltip: 'Open navigation',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              if (showDrawerButton) const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.headingSmall().copyWith(
                          fontSize: isMobile ? 16 : 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isVeryNarrow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBlueBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Text(
                          'CMS Admin',
                          style:
                              AppTypography.bodySmall(
                                color: AppColors.primaryNavy,
                              ).copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // User chip
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isVeryNarrow ? 7 : 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softBlueBg,
                  borderRadius: BorderRadius.circular(12),
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
                    if (!isVeryNarrow) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 90 : 160,
                        ),
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
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: AppStrings.logout,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                            foregroundColor: AppColors.surfaceWhite,
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
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
      },
    );
  }
}
