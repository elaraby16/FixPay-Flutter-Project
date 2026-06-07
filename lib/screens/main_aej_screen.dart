import 'package:flutter/material.dart';
import 'welcome_screen_modified.dart';
import 'jobs_screen.dart'; 
import 'assigned_tasks_screen.dart';
import 'earnings_screen.dart'; 
import 'account_screen.dart'; 

class MainScreen extends StatefulWidget {
  final List<String> selectedSkills;
  const MainScreen({super.key, required this.selectedSkills});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 1. بنعرف اللستة هنا كمتغير عادي مش static ولا ثابت
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    // 2. بنملا اللستة هنا أول ما الصفحة تفتح (عشان نقدر نستخدم widget.selectedSkills)
    _widgetOptions = [
      JobsScreen(selectedSkills: widget.selectedSkills),
      const AssignedTasksScreen(),
      const EarningsScreen(),
      AccountScreen(selectedSkills: widget.selectedSkills),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      ///Colors.white,
      // 3. بنعرض الصفحة بناءً على الاختيار
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
 backgroundColor:
 // const Color(0xFFF2EFE9),
          AppColors.backgroundWhite,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryDarkGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'My Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
