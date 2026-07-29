import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/exercise_list_screen.dart';
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
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Uses integer 0 for the id to perfectly align with your CategoryModel types
  List<Widget> get _screens => [
        const DashboardScreen(),
        ExerciseListScreen(
          category: CategoryModel(
            id: 0, 
            name: 'All Exercises',
            iconSlug: 'fitness_center',
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
