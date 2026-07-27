import 'package:flutter/material.dart';
import 'services/supabase_config.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'theme.dart';

Future<void> main() async {
  // Required before any plugin channel calls (Supabase init, notifications).
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the read-only Supabase backend.
  await SupabaseConfig.initialize();

  // Initialize the local notification engine. Actual scheduling happens
  // later, from the Dashboard settings sheet, once the user opts in.
  await NotificationService().init();

  runApp(const PhysioApp());
}

class PhysioApp extends StatelessWidget {
  const PhysioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Physio & Mobility',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const DashboardScreen(),
    );
  }
}
