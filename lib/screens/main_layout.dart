import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'task_form_screen.dart';
import 'study_hub_screen.dart';
import 'habits_screen.dart';
import '../widgets/glass_container.dart';
import '../widgets/main_drawer.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardScreen(),
      TaskFormScreen(
        onTaskSaved: () {
          setState(() {
            _pages[0] = DashboardScreen(key: UniqueKey());
            _currentIndex = 0;
          });
        },
      ),
      const StudyHubScreen(),
      const HabitsScreen(),
    ];
  }

  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'Task', style: TextStyle(color: Color(0xFF818CF8))),
              TextSpan(text: 'Digest', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),

      ),
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          // Background subtle gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          
          // Current Page
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),

          // Custom Bottom Navigation Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: GlassContainer(
              height: 60,
              borderRadius: BorderRadius.circular(30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.check_box_outlined,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.menu_book_rounded,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.medical_services_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF6366F1) : Colors.white54;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
