import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/exercise_list_screen.dart';

// Imports your custom models folder to make CategoryModel visible here
import 'models/models.dart'; 

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
  Widget build(BuildContext context) {
    return const _MainNavigationScreenContent();
  }
}

class _MainNavigationScreenContent extends StatefulWidget {
  const _MainNavigationScreenContent();

  @override
  State<_MainNavigationScreenContent> createState() => _MainNavigationScreenContentState();
}

class _MainNavigationScreenContentState extends State<_MainNavigationScreenContent> {
  int _currentIndex = 0;

  // Lazily computes the screen collection to pass a fully valid model constructor instance
  List<Widget> get _screens => [
        const DashboardScreen(),
        ExerciseListScreen(
          category: CategoryModel(
            id: 'all',
            name: 'All Exercises',
            icon: 'fitness_center', // Matches standard fallback properties
          ),
        ),
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
