import 'package:flutter/material.dart';
import '../screens/overview_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/users_screen.dart';
import 'sidebar_widget.dart';
import 'top_header_widget.dart';

enum DashboardPage { overview, users, notifications }

class DashboardShellWidget extends StatefulWidget {
  const DashboardShellWidget({super.key});

  @override
  State<DashboardShellWidget> createState() => _DashboardShellWidgetState();
}

class _DashboardShellWidgetState extends State<DashboardShellWidget> {
  DashboardPage _currentPage = DashboardPage.overview;

  void _onPageChanged(DashboardPage page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return Scaffold(
          body: Row(
            children: [
              if (!isMobile)
                SidebarWidget(
                  currentPage: _currentPage,
                  onPageChanged: _onPageChanged,
                ),
              Expanded(
                child: Column(
                  children: [
                    TopHeaderWidget(
                      isMobileLayout: isMobile,
                      currentPage: _currentPage,
                      onPageChanged: _onPageChanged,
                    ),
                    Expanded(child: _buildPageContent()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageContent() {
    return switch (_currentPage) {
      DashboardPage.overview => const OverviewScreen(),
      DashboardPage.users => const UsersScreen(),
      DashboardPage.notifications => const NotificationScreen(),
    };
  }
}
