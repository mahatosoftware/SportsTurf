import 'package:flutter/material.dart';
import '../models/tournament.dart';
import '../models/team.dart';
import 'package:uuid/uuid.dart';
import 'seed_assignment_screen.dart';

class TournamentSetupScreen extends StatefulWidget {
  const TournamentSetupScreen({super.key});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _participantCountController = TextEditingController(text: '4');
  String _sport = 'Tennis';
  final List<String> _sports = ['Tennis', 'Badminton', 'Table Tennis', 'Cricket', 'Volleyball', 'Football', 'Basketball', 'Other'];
  TournamentFormat _format = TournamentFormat.singleElimination;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('New Tournament'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Tournament Name'),
            const SizedBox(height: 8),
            _buildTextField(_nameController, "Enter Name"),
            const SizedBox(height: 24),
            
            _buildSectionTitle('Sport'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _sport,
              items: _sports.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _sport = v!),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Format'),
            const SizedBox(height: 8),
            _buildDropdown<TournamentFormat>(
              value: _format,
              items: TournamentFormat.values.map((f) {
                const labels = {
                  TournamentFormat.roundRobin: 'Round Robin',
                  TournamentFormat.singleElimination: 'Single Elimination',
                  TournamentFormat.doubleElimination: 'Double Elimination',
                };
                return DropdownMenuItem(
                  value: f,
                  child: Text(labels[f]!),
                );
              }).toList(),
              onChanged: (v) => setState(() => _format = v!),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Participants'),
            const SizedBox(height: 8),
            _buildTextField(
               _participantCountController, 
               "Enter number of teams", 
               keyboardType: TextInputType.number,
            ),
             const SizedBox(height: 24),
            if (_format != TournamentFormat.roundRobin)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: const Text('Enable Seeding', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manually assign seeds or randomize'),
                  activeColor: Colors.green,
                  value: _seeded,
                  onChanged: (v) => setState(() => _seeded = v),
                ),
              ),
              
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: const Text(
                  'NEXT: TEAM SETUP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
        fontSize: 14,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) => value?.isEmpty == true ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      int count = int.tryParse(_participantCountController.text) ?? 4;
      if (count < 2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 2 teams required')));
        return;
      }
      
      // Create initial dummy teams
      List<Team> teams = List.generate(
        count,
        (index) => Team(
          id: const Uuid().v4(),
          name: 'Team ${index + 1}',
          seed: _seeded ? index + 1 : null,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeedAssignmentScreen(
            tournamentName: _nameController.text,
            sport: _sport,
            format: _format,
            seeded: _seeded,
            initialTeams: teams,
          ),
        ),
      );
    }
  }
}
