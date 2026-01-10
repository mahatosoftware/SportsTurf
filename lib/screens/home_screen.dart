import 'package:flutter/material.dart';
import '../features/coin_toss/coin_toss_screen.dart';

import '../features/tennis/ui/tennis_setup_screen.dart';

import '../features/badminton/ui/badminton_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              context,
              title: "Coin Toss",
              icon: Icons.monetization_on,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CoinTossScreen()),
                );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Tennis Score",
              icon: Icons.sports_tennis, // Tennis Ball
              color: Colors.lightGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TennisSetupScreen()),
                );
              },
            ),
            _buildFeatureCard(
              context,
              title: "Badminton",
              icon: Icons.sports_tennis_rounded, // Use similar icon but distinct color
              color: Colors.teal,
              onTap: () {
                 Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BadmintonSetupScreen()),
                );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Scoreboard",
              icon: Icons.scoreboard,
              color: Colors.blue,
              onTap: () {
                 // TODO
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coming Soon!")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
