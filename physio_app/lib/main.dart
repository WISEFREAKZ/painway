import 'package:flutter/material.dart';

void main() {
  // Ensures native components initialize smoothly before the user interface draws
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PainWay Physio',
      debugShowCheckedModeBanner: false, // Disables the debug banner in the corner
      theme: ThemeData.light(), // Uses a safe, universal native material theme setup
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

  // Optimized list caching for your 2 screens to prevent rebuild layout loops
  final List<Widget> _screens = const [
    HomeScreenPlaceholder(),
    WorkoutScreenPlaceholder(),
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

// Temporary placeholder screens used until your main feature files are linked up
class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Welcome to PainWay Home')),
    );
  }
}

class WorkoutScreenPlaceholder extends StatelessWidget {
  const WorkoutScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Your Physical Therapy Workouts')),
    );
  }
}
