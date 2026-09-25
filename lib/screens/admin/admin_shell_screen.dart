import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/colors.dart';
import '../../providers/session_provider.dart';
import 'admin_content_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';
import 'admin_widgets.dart';
import 'admin_activity_screen.dart';

/// Admin-only tab shell: نظرة عامة / المستخدمون / المحتوى / النشاط.
///
/// Route: /admin. The client-side isAdmin guard is display-level only —
/// every data call behind it re-checks fn_is_admin() on the server.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<SessionProvider>().isAdmin;
    if (!isAdmin) {
      return const _UnauthorizedScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: const [
            AdminOverviewScreen(),
            AdminUsersScreen(),
            AdminContentScreen(),
            AdminActivityScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: HaffarColors.white,
        indicatorColor: HaffarColors.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'نظرة عامة',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'المستخدمون',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'المحتوى',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'النشاط',
          ),
        ],
      ),
    );
  }
}

/// Shown on a deep link by a non-admin; every RPC would return
/// `not authorized` anyway, so fail fast with a clear message.
class _UnauthorizedScreen extends StatelessWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const AdminErrorView(message: 'غير مصرح — هذه الصفحة للأدمن فقط'),
    );
  }
}
