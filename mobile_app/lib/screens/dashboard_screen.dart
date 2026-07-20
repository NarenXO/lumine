import 'package:flutter/material.dart';
import '../services/app_controller.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: AppController(),
        builder: (context, _) {
          final controller = AppController();

          if (_selectedIndex == 0) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Moral Drift Dashboard",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Text("Anxiety: ${controller.anxiety.toStringAsFixed(2)}"),
                  Text("Gratitude: ${controller.gratitude.toStringAsFixed(2)}"),
                  Text("Reactivity: ${controller.reactivity.toStringAsFixed(2)}"),
                  Text("Humility: ${controller.humility.toStringAsFixed(2)}"),
                ],
              ),
            );
          }

          if (_selectedIndex == 1) {
            return const ChatScreen();
          }

          return const ProfileScreen();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}