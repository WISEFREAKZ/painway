import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/exercise_list_screen.dart';
import 'services/supabase_config.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Required before any plugin channel calls (Supabase init, notifications).
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the read-only Supabase backend.
  //
  // THESE TWO CALLS WERE MISSING ENTIRELY in a previous edit — without
  // them, Supabase queries would throw (client never initialized), and
  // more subtly: NotificationService().init() is what loads the
  // timezone database and calls tz.setLocalLocation(). Skip it and
  // every scheduled reminder falls back to computing times in UTC
  // instead of the device's real local timezone — which looks exactly
  // like "the time window is being ignored," because from the device's
  // perspective, it effectively is.
  await SupabaseConfig.initialize();
  await NotificationService().init();

  // Self-heals any reminder chain that silently broke (see the comment
  // on rescheduleFromSavedPreferences for why that can happen) — safe
  // to call on every launch since it only re-arms reminders the person
  // already has enabled.
  await NotificationService().rescheduleFromSavedPreferences();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PainWay Physio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // "Workouts" now genuinely fetches every exercise across all
  // categories via SupabaseConfig.fetchAllExercises() (see
  // exercise_list_screen.dart) instead of the previous fake
  // CategoryModel(id: 0, ...) — no category has id 0, since Postgres
  // identity columns start at 1, so that tab was always silently empty.
  List<Widget> get _screens => const [
        DashboardScreen(),
        ExerciseListScreen(category: null),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Workouts',
          ),
        ],
      ),
    );
  }
}
