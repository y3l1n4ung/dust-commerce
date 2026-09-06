import 'package:admin_app/src/session/admin_gate.dart';
import 'package:flutter/material.dart';

/// Dedicated merchant application; no storefront routes are mounted here.
class MorrowAdminApp extends StatelessWidget {
  /// Creates the admin application.
  const MorrowAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Morrow Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF18181B),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const AdminGate(),
      );
}
