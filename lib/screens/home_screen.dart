import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/coin_toss/coin_toss_screen.dart';

import '../features/tennis/ui/tennis_setup_screen.dart';

import '../features/badminton/ui/badminton_setup_screen.dart';

import '../features/table_tennis/ui/table_tennis_setup_screen.dart';
import '../features/cricket/ui/cricket_setup_screen.dart';
import '../features/volleyball/ui/volleyball_setup_screen.dart';
import '../features/players/players_screen.dart';
import 'scorecard_screen.dart';

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
              icon: Icons.sports_tennis_rounded, 
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
              title: "Table Tennis",
              icon: Icons.sports_baseball, // Placeholder for Ping Pong Ball
              color: Colors.blue[800]!,
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const TableTennisSetupScreen()),
                 );
              },
            ),
            _buildFeatureCard(
              context,
              title: "Cricket Scorer",
              icon: Icons.sports_cricket, 
              color: Colors.blueAccent,
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const CricketSetupScreen()),
                 );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Volleyball",
              icon: Icons.sports_volleyball, 
              color: Colors.amber, 
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const VolleyballSetupScreen()),
                 );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Scorecard",
              icon: Icons.assignment, 
              color: Colors.deepPurple, 
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const ScorecardScreen()),
                 );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Players",
              icon: Icons.people,
              color: Colors.indigo,
              onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const PlayersScreen()),
                 );
              },
            ),
             _buildFeatureCard(
              context,
              title: "Exit App",
              icon: Icons.exit_to_app, 
              color: Colors.redAccent,
              onTap: () {
                 SystemNavigator.pop();
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
