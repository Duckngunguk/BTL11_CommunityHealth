import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_web_login_screen.dart';
import 'state/app_store.dart';
import 'widgets/common_widgets.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: AppScope(
        child: AdminWebHealthApp(),
      ),
    ),
  );
}

class AdminWebHealthApp extends StatelessWidget {
  const AdminWebHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommunityHealth Web Admin',
      debugShowCheckedModeBanner: false,
      theme: buildCommunityHealthTheme(),
      home: const _AdminAppRouter(),
    );
  }
}

class _AdminAppRouter extends StatefulWidget {
  const _AdminAppRouter();

  @override
  State<_AdminAppRouter> createState() => _AdminAppRouterState();
}

class _AdminAppRouterState extends State<_AdminAppRouter> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (store.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isLoggedIn = _isLoggedIn ||
        (store.currentUser != null &&
            store.currentUser!.role == UserRole.admin);

    if (isLoggedIn) {
      return AdminShell(
        onLogout: () async {
          await store.logout();
          if (!mounted) return;
          setState(() => _isLoggedIn = false);
        },
      );
    }

    return AdminWebLoginScreen(
      onLoginSuccess: () => setState(() => _isLoggedIn = true),
      onSwitchToMobileLogin: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Đây là Cổng Web Quản trị độc lập. Để vào Mobile App, hãy mở main.dart.'),
          ),
        );
      },
    );
  }
}
