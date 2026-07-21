import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  Widget _buildRadarChart(AppController c) {
    return SizedBox(
      height: 320,
      child: RadarChart(
        RadarChartData(
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          gridBorderData: const BorderSide(color: Colors.white24, width: 1),
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent),
          radarBorderData: const BorderSide(color: Colors.white24),
          getTitle: (index, angle) {
            const titles = [
              "Anxiety",
              "Gratitude",
              "Reactivity",
              "Humility",
            ];
            return RadarChartTitle(
              text: titles[index],
              angle: 0,
            );
          },
          titleTextStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          dataSets: [
            RadarDataSet(
              fillColor: Colors.amberAccent.withOpacity(0.3),
              borderColor: Colors.amberAccent,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: c.anxiety.clamp(0, 1)),
                RadarEntry(value: c.gratitude.clamp(0, 1)),
                RadarEntry(value: c.reactivity.clamp(0, 1)),
                RadarEntry(value: (c.humility.abs()).clamp(0, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return AnimatedBuilder(
      animation: AppController(),
      builder: (context, _) {
        final c = AppController();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Moral Drift Dashboard",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your inner state in real time",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildRadarChart(c),
              const SizedBox(height: 30),
              _buildMetric("Anxiety", c.anxiety),
              _buildMetric("Gratitude", c.gratitude),
              _buildMetric("Reactivity", c.reactivity),
              _buildMetric("Humility", c.humility.abs()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, double value) {
    double clamped = value.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                clamped.toStringAsFixed(2),
                style: const TextStyle(color: Colors.amberAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    if (_selectedIndex == 0) {
      screen = _buildDashboard();
    } else if (_selectedIndex == 1) {
      screen = const ChatScreen();
    } else {
      screen = const ProfileScreen();
    }

    return Scaffold(
      body: screen,
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