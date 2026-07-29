import 'package:flutter/material.dart';

// 1. Explicitly imports your real, existing screen files into the entry file
import 'screens/dashboard_screen.dart';
import 'screens/exercise_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  // 2. Maps your real, existing dashboard and exercise screen files directly to the tabs
  final List<Widget> _screens = const [
    DashboardScreen(),    // First tab loads your real Dashboard Screen
    ExerciseListScreen(),  // Second tab loads your real Exercise List Screen
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
