import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/admin/admin_web_login_screen.dart';
import 'state/app_store.dart';
import 'widgets/common_widgets.dart';
import 'models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarThemeData(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
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
    if (_isLoggedIn) {
      return AdminShell(
        onLogout: () {
          setState(() {
            _isLoggedIn = false;
            AppScope.of(context).currentUser = null;
          });
        },
      );
    }

    return AdminWebLoginScreen(
      onLoginSuccess: () => setState(() => _isLoggedIn = true),
      onSwitchToMobileLogin: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đây là Cổng Web Quản trị độc lập. Để vào Mobile App, hãy mở main.dart.'),
          ),
        );
      },
    );
  }
}
