import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';
import '../models/nav_item.dart';

class AdminSidebar extends ConsumerWidget {
  final String currentRoute;
  final VoidCallback? onItemSelected;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'admin@nextgen.edu';

    return Container(
      width: 260,
      color: AppColors.sidebarNavy,
      child: Column(
        children: [
          // Academy Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E325C), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGold, AppColors.darkGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'NG',
                      style: TextStyle(
                        color: AppColors.primaryNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NextGen',
                        style: AppTypography.titleMedium(
                          color: AppColors.surfaceWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Excellence Academy CMS',
                        style: AppTypography.bodySmall(
                          color: AppColors.primaryGold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: NavItem.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = NavItem.items[index];
                final isActive = currentRoute == item.route ||
                    (item.route == '/dashboard' && currentRoute == '/');

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      onItemSelected?.call();
                      if (!isActive) {
                        context.go(item.route);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: AppColors.sidebarHover,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.sidebarActive
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isActive
                            ? const Border(
                                left: BorderSide(
                                  color: AppColors.primaryGold,
                                  width: 3.5,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive
                                ? AppColors.primaryGold
                                : const Color(0xFF9FB0D0),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTypography.navItem(isActive: isActive),
                            ),
                          ),
                          if (isActive)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Admin Profile & Logout Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF07142E),
              border: Border(
                top: BorderSide(color: Color(0xFF1E325C), width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.mediumNavy,
                      child: Text(
                        userEmail.isNotEmpty
                            ? userEmail[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: AppColors.lightGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userEmail,
                            style: AppTypography.bodySmall(
                              color: AppColors.surfaceWhite,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: AppColors.lightGold,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Color(0xFFEF7777),
                        size: 20,
                      ),
                      tooltip: AppStrings.logout,
                      onPressed: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(authControllerProvider.notifier).signOut();
      }
    });
  }
}
