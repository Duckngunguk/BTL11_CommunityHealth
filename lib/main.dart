import 'package:flutter/material.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/mobile/mobile_shell.dart';
import 'screens/parent/parent_shell.dart';
import 'state/app_store.dart';
import 'widgets/common_widgets.dart';

void main() {
  runApp(
    AppScope(
      notifier: AppStore(),
      child: const CommunityHealthApp(),
    ),
  );
}

class CommunityHealthApp extends StatelessWidget {
  const CommunityHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CommunityHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen, brightness: Brightness.light),
        scaffoldBackgroundColor: pageBackground,
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD9E0DC))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD9E0DC))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryGreen, width: 1.6)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  AppMode? _mode;

  @override
  Widget build(BuildContext context) {
    if (_mode == null) {
      return LoginScreen(onLogin: (mode) => setState(() => _mode = mode));
    }
    if (_mode == AppMode.admin) {
      return AdminShell(onLogout: () => setState(() => _mode = null));
    }
    if (_mode == AppMode.parent) {
      return ParentShell(onLogout: () => setState(() => _mode = null));
    }
    return MobileShell(onLogout: () => setState(() => _mode = null));
  }
}

