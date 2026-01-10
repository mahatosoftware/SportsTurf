import 'package:flutter/material.dart';
import '../models/badminton_match_state.dart';
import 'badminton_score_screen.dart';

class BadmintonSetupScreen extends StatefulWidget {
  const BadmintonSetupScreen({super.key});

  @override
  State<BadmintonSetupScreen> createState() => _BadmintonSetupScreenState();
}

class _BadmintonSetupScreenState extends State<BadmintonSetupScreen> {
  BadmintonMatchType _matchType = BadmintonMatchType.singles;
  
  final TextEditingController _pA1Controller = TextEditingController();
  final TextEditingController _pA2Controller = TextEditingController(); 
  final TextEditingController _pB1Controller = TextEditingController();
  final TextEditingController _pB2Controller = TextEditingController();

  @override
  void dispose() {
    _pA1Controller.dispose();
    _pA2Controller.dispose();
    _pB1Controller.dispose();
    _pB2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    String a1 = _pA1Controller.text.trim().toUpperCase();
    String a2 = _pA2Controller.text.trim().toUpperCase();
    String b1 = _pB1Controller.text.trim().toUpperCase();
    String b2 = _pB2Controller.text.trim().toUpperCase();

    if (a1.isEmpty) a1 = "PLAYER A";
    if (b1.isEmpty) b1 = "PLAYER B";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadmintonScoreScreen(
          matchType: _matchType,
          playerA1: a1,
          playerA2: a2,
          playerB1: b1,
          playerB2: b2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDoubles = _matchType == BadmintonMatchType.doubles;

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Badminton Setup",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.black87
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Match Type
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("MATCH TYPE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SegmentedButton<BadmintonMatchType>(
                      segments: const [
                        ButtonSegment(value: BadmintonMatchType.singles, label: Text("SINGLES"), icon: Icon(Icons.person)),
                        ButtonSegment(value: BadmintonMatchType.doubles, label: Text("DOUBLES"), icon: Icon(Icons.group)),
                      ],
                      selected: {_matchType},
                      onSelectionChanged: (Set<BadmintonMatchType> newSelection) {
                        setState(() { _matchType = newSelection.first; });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) return Colors.green;
                          return Colors.grey[200]!; 
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                           if (states.contains(WidgetState.selected)) return Colors.white;
                          return Colors.black87;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Team A
            Text(isDoubles ? "TEAM A" : "PLAYER A", 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(_pA1Controller, isDoubles ? "Player 1 Name" : "Player Name", Icons.person),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _buildTextField(_pA2Controller, "Player 2 Name", Icons.person_outline),
            ],

            const SizedBox(height: 24),

            // Team B
            Text(isDoubles ? "TEAM B" : "PLAYER B", 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 8),
            _buildTextField(_pB1Controller, isDoubles ? "Player 1 Name" : "Player Name", Icons.person),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _buildTextField(_pB2Controller, "Player 2 Name", Icons.person_outline),
            ],

            const SizedBox(height: 48),

            // Start
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.green, width: 2)),
      ),
    );
  }
}
