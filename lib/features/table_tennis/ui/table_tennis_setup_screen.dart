import 'package:flutter/material.dart';
import '../models/table_tennis_match_state.dart';
import 'table_tennis_score_screen.dart';

class TableTennisSetupScreen extends StatefulWidget {
  const TableTennisSetupScreen({super.key});

  @override
  State<TableTennisSetupScreen> createState() => _TableTennisSetupScreenState();
}

class _TableTennisSetupScreenState extends State<TableTennisSetupScreen> {
  TTMatchType _matchType = TTMatchType.singles;
  
  final TextEditingController _pA1Controller = TextEditingController(); // A1
  final TextEditingController _pA2Controller = TextEditingController(); // A2
  final TextEditingController _pB1Controller = TextEditingController(); // B1
  final TextEditingController _pB2Controller = TextEditingController(); // B2
  
  int _setsToWin = 3; 

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

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => TableTennisScoreScreen(
        matchType: _matchType,
        playerA1: a1,
        playerA2: a2,
        playerB1: b1,
        playerB2: b2,
        setsToWin: _setsToWin,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    bool isDoubles = _matchType == TTMatchType.doubles;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Sports Turf"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             const Text("Table Tennis Setup",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                    SegmentedButton<TTMatchType>(
                      segments: const [
                        ButtonSegment(value: TTMatchType.singles, label: Text("SINGLES"), icon: Icon(Icons.person)),
                        ButtonSegment(value: TTMatchType.doubles, label: Text("DOUBLES"), icon: Icon(Icons.group)),
                      ],
                      selected: {_matchType},
                      onSelectionChanged: (Set<TTMatchType> newSelection) {
                        setState(() {
                          _matchType = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue[800]!; 
                          }
                          return Colors.grey[200]!; 
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                           if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
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
            Text(isDoubles ? "TEAM A (Top)" : "PLAYER A (Top)", 
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(_pA1Controller, isDoubles ? "Player 1 Name" : "Name"),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _buildTextField(_pA2Controller, "Player 2 Name"),
            ],
             
             const SizedBox(height: 24),
             
             // Team B
            Text(isDoubles ? "TEAM B (Bottom)" : "PLAYER B (Bottom)", 
                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(_pB1Controller, isDoubles ? "Player 1 Name" : "Name"),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _buildTextField(_pB2Controller, "Player 2 Name"),
            ],
             
             const SizedBox(height: 32),
             const Text("SETS TO WIN MATCH", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             SegmentedButton<int>(
               segments: const [
                 ButtonSegment(value: 2, label: Text("Best of 3")),
                 ButtonSegment(value: 3, label: Text("Best of 5")),
                 ButtonSegment(value: 4, label: Text("Best of 7")),
               ],
               selected: {_setsToWin},
               onSelectionChanged: (s) => setState(() => _setsToWin = s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) return Colors.blue[800]!;
                    return Colors.grey[200]!;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                     if (states.contains(WidgetState.selected)) return Colors.white;
                    return Colors.black87;
                  }),
                ),
             ),
             
             const SizedBox(height: 48),
             SizedBox(
               height: 56,
               child: ElevatedButton(
                 onPressed: _startGame,
                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                 child: const Text("START MATCH", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
