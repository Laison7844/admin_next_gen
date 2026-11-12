import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import 'models/nav_item.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_sidebar.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getPageTitle(String location) {
    for (final item in NavItem.items) {
      if (item.route == location ||
          (item.route == '/dashboard' && (location == '/' || location.isEmpty))) {
        return item.title;
      }
    }
    return 'Admin CMS';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final pageTitle = _getPageTitle(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.backgroundLight,
          drawer: isDesktop
              ? null
              : Drawer(
                  width: 260,
                  backgroundColor: AppColors.sidebarNavy,
                  child: AdminSidebar(
                    currentRoute: location,
                    onItemSelected: () {
                      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AdminSidebar(
                  currentRoute: location,
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminHeader(
                      title: pageTitle,
                      showDrawerButton: !isDesktop,
                      onOpenDrawer: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

