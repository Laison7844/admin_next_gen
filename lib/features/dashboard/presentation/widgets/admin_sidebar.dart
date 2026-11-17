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
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.value?.email ?? 'admin@nextgen.edu';

    final grouped = NavItem.groupedItems;
    final groups = [
      NavItem.groupOverview,
      NavItem.groupWebsiteContent,
      NavItem.groupEnquiriesMedia,
      NavItem.groupGeneral,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 72 : 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sidebarNavy, Color(0xFF0A1937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Academy Branding Header
          _buildHeader(),

          // Scrollable Grouped Navigation List
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 8 : 12,
                vertical: 16,
              ),
              children: [
                for (final group in groups) ...[
                  if (grouped.containsKey(group)) ...[
                    _buildGroupHeader(group),
                    const SizedBox(height: 4),
                    for (final item in grouped[group]!) ...[
                      _buildNavItem(context, item),
                      const SizedBox(height: 3),
                    ],
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),

          // Admin Profile & Logout Footer
          _buildFooter(context, ref, userEmail),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (isCollapsed) {
      return Container(
        height: 70,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF1E325C), width: 1),
          ),
        ),
        child: Center(
          child: InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGold, AppColors.darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.webp',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
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
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E325C), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.webp',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'NG',
                    style: TextStyle(
                      color: AppColors.primaryNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
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
                  style: AppTypography.bodySmall(color: AppColors.primaryGold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onToggleCollapse != null)
            IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: Color(0xFF9FB0D0),
                size: 20,
              ),
              tooltip: 'Collapse sidebar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onToggleCollapse,
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String groupName) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Color(0xFF1E325C), thickness: 1),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
      child: Text(
        groupName,
        style: const TextStyle(
          color: Color(0xFF6F88B6),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final isActive =
        currentRoute == item.route ||
        (item.route == '/dashboard' &&
            (currentRoute == '/' || currentRoute.isEmpty));

    if (isCollapsed) {
      return Tooltip(
        message: item.title,
        preferBelow: false,
        child: Material(
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
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? AppColors.sidebarActive : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: isActive
                    ? const Border(
                        left: BorderSide(
                          color: AppColors.primaryGold,
                          width: 3.5,
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isActive
                      ? AppColors.primaryGold
                      : const Color(0xFF9FB0D0),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasRoomForLabel = constraints.maxWidth >= 112;
        final itemContent = Container(
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: hasRoomForLabel ? 12 : 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.sidebarActive.withValues(alpha: 0.82)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: isActive
                ? const Border(
                    left: BorderSide(color: AppColors.primaryGold, width: 3.5),
                  )
                : null,
          ),
          child: hasRoomForLabel
              ? Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 19,
                      color: isActive
                          ? AppColors.primaryGold
                          : const Color(0xFF9FB0D0),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isActive
                              ? AppColors.surfaceWhite
                              : const Color(0xFFE2E8F0),
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Icon(
                    item.icon,
                    size: 19,
                    color: isActive
                        ? AppColors.primaryGold
                        : const Color(0xFF9FB0D0),
                  ),
                ),
        );

        final clickableItem = Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: () {
              onItemSelected?.call();
              if (!isActive) context.go(item.route);
            },
            borderRadius: BorderRadius.circular(11),
            hoverColor: AppColors.sidebarHover,
            child: itemContent,
          ),
        );
        return hasRoomForLabel
            ? clickableItem
            : Tooltip(message: item.title, child: clickableItem);
      },
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, String userEmail) {
    if (isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF07142E),
          border: Border(top: BorderSide(color: Color(0xFF1E325C), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.mediumNavy,
              child: Text(
                userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 6),
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Color(0xFFEF7777),
                size: 18,
              ),
              tooltip: AppStrings.logout,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF07142E),
        border: Border(top: BorderSide(color: Color(0xFF1E325C), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.mediumNavy,
                child: Text(
                  userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.lightGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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
                          fontSize: 9,
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
                  size: 19,
                ),
                tooltip: AppStrings.logout,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _confirmLogout(context, ref),
              ),
            ],
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
