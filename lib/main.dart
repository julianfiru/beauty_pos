import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database_helper.dart';
import 'core/shell/app_shell.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Warmup local database
  await DatabaseHelper.instance.database;

  runApp(
    const ProviderScope(
      child: BeautyPOSApp(),
    ),
  );
}

class BeautyPOSApp extends StatelessWidget {
  const BeautyPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
