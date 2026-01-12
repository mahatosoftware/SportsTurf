import 'package:flutter/material.dart';
import '../logic/cricket_state_machine.dart';
import '../models/cricket_match_state.dart';
import 'cricket_stats_screen.dart';
import 'dart:convert';
import '../../../core/database/database_helper.dart';
import '../../../core/models/match_result.dart';

class CricketScoreScreen extends StatefulWidget {
  final String teamA;
  final String teamB;
  final List<String> squadA;
  final List<String> squadB;
  final int overs;

  const CricketScoreScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    this.squadA = const [],
    this.squadB = const [],
    required this.overs,
  });

  @override
  State<CricketScoreScreen> createState() => _CricketScoreScreenState();
}

class _CricketScoreScreenState extends State<CricketScoreScreen> {
  late CricketStateMachine _machine;
  
  bool _isWide = false;
  bool _isNoBall = false;
  bool _isBye = false;
  bool _isLegBye = false;

  @override
  void initState() {
    super.initState();
    _machine = CricketStateMachine(
      teamAName: widget.teamA,
      teamBName: widget.teamB,
      squadA: widget.squadA,
      squadB: widget.squadB,
      totalOvers: widget.overs,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOpeningDetailsDialog();
    });
  }
  
  Future<void> _showOpeningDetailsDialog() async {
    final currentState = _machine.state;
    // Determine batting/bowling squads based on who is batting currently
    // If currentInning == 1, teamAName is batting (usually), so use active batting squad
    List<String> battingSquad;
    List<String> bowlingSquad;
    
    if (currentState.battingTeamName == widget.teamA) {
      battingSquad = widget.squadA;
      bowlingSquad = widget.squadB;
    } else {
      battingSquad = widget.squadB;
      bowlingSquad = widget.squadA;
    }
    
    String? selectedStriker;
    String? selectedNonStriker;
    String? selectedBowler;

    if (battingSquad.isNotEmpty) selectedStriker = battingSquad[0];
    if (battingSquad.length > 1) selectedNonStriker = battingSquad[1];
    if (bowlingSquad.isNotEmpty) selectedBowler = bowlingSquad[0];
    
    // If stats already track these players, maybe use their existing names? 
    // But this is usually for "Opening" batsmen of the inning, so defaults are fine.

    final strikerCtrl = TextEditingController(text: selectedStriker);
    final nonStrikerCtrl = TextEditingController(text: selectedNonStriker);
    final bowlerCtrl = TextEditingController(text: selectedBowler);

    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Recalculate available lists based on current selections
            // We use the controllers' text to determine current selection
            
            final currentStriker = strikerCtrl.text;
            final currentNonStriker = nonStrikerCtrl.text;
            
            final availableForStriker = battingSquad.where((p) => p != currentNonStriker).toList();
            final availableForNonStriker = battingSquad.where((p) => p != currentStriker).toList();

            return AlertDialog(
              title: Text("Innings ${currentState.currentInning} Start"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Batsmen", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    _buildPlayerSelector(
                        "Striker", 
                        availableForStriker, 
                        strikerCtrl, 
                        onChanged: () => setStateDialog(() {})
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerSelector(
                        "Non-Striker", 
                        availableForNonStriker, 
                        nonStrikerCtrl,
                        onChanged: () => setStateDialog(() {})
                    ),
                    const SizedBox(height: 16),
                    const Text("Select Opening Bowler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    _buildPlayerSelector("Bowler", bowlingSquad, bowlerCtrl),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                     // Basic validation
                     if (strikerCtrl.text == nonStrikerCtrl.text && strikerCtrl.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Striker and Non-Striker must be different!")));
                        return;
                     }
                     
                     _machine.updatePlayers(
                       striker: strikerCtrl.text.isNotEmpty ? strikerCtrl.text : "Striker",
                       nonStriker: nonStrikerCtrl.text.isNotEmpty ? nonStrikerCtrl.text : "Non-Striker",
                       bowler: bowlerCtrl.text.isNotEmpty ? bowlerCtrl.text : "Bowler",
                     );
                     setState(() {});
                     Navigator.pop(context);
                  },
                  child: const Text("START INNINGS"),
                )
              ],
            );
          }
        );
      }
    );
  }
  
  Widget _buildPlayerSelector(String label, List<String> squad, TextEditingController controller, {VoidCallback? onChanged}) {
    if (squad.isEmpty) {
      return TextField(controller: controller, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()));
    }
    
    // Ensure current text is valid option
    if (controller.text.isNotEmpty && !squad.contains(controller.text)) {
      // If current text is filtered out, clear it or pick first available?
      // Clearing it is safer to force re-selection
      controller.text = ""; 
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<String>(
          initialSelection: controller.text.isNotEmpty && squad.contains(controller.text) ? controller.text : null,
          controller: controller,
          label: Text(label),
          dropdownMenuEntries: squad.map((p) => DropdownMenuEntry(value: p, label: p)).toList(),
          onSelected: (val) {
             if (val != null) {
               controller.text = val;
               onChanged?.call();
             }
          },
          expandedInsets: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _submitBall(int runs) {
    int oldInning = _machine.state.currentInning;
    
    _machine.recordBall(
      runsScored: runs,
      isWide: _isWide,
      isNoBall: _isNoBall,
      isBye: _isBye,
      isLegBye: _isLegBye,
      isWicket: false,
    );
    _resetToggles();
    setState(() {});
    
    // Check for Innings Change
    if (_machine.state.currentInning > oldInning && !_machine.state.isMatchComplete) {
       Future.delayed(Duration.zero, () {
         _showOpeningDetailsDialog();
       });
       return;
    }
    
    // Check for Over Completion
    if (!_machine.state.isMatchComplete && 
        _machine.state.ballsInOver == 0 && 
        _machine.state.oversCompleted > 0) {
      // Over just completed. Prompt for new bowler.
      Future.delayed(Duration.zero, () {
         _changeBowler(mandatory: true);
      });
    }
  }
  
  void _handleWicketPress() {
    _showWicketDialog();
  }

  Future<void> _showWicketDialog() async {
    final nameController = TextEditingController();
    bool isStrikerOut = true;
    
    // Filter Squad
    final currentState = _machine.state;
    final allBattingSquad = currentState.currentInning == 1 ? widget.squadA : widget.squadB;
    final currentStriker = currentState.striker.name;
    final currentNonStriker = currentState.nonStriker.name;
    final dismissed = currentState.dismissedPlayers;
    
    final availableBatsmen = allBattingSquad.where((p) {
      return p != currentStriker && p != currentNonStriker && !dismissed.contains(p);
    }).toList();
    
    // UI State for dialog
    // We need stateful builder for radio button toggle in dialog
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("WICKET FALLEN!"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isWide || _isNoBall) 
                       Container(
                         padding: const EdgeInsets.all(8), 
                         color: Colors.orange[100], 
                         child: Text("Extras Active: ${_isWide ? 'Wide' : ''} ${_isNoBall ? 'No Ball' : ''}"),
                       ),
                    const SizedBox(height: 16),
                    // Who is Out?
                    const Text("Who is Out?", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        ChoiceChip(
                           label: Text("${currentState.striker.name} (Striker)"),
                           selected: isStrikerOut,
                           onSelected: (v) => setStateDialog(() => isStrikerOut = true),
                           selectedColor: Colors.red[100],
                           labelStyle: TextStyle(color: isStrikerOut ? Colors.red : Colors.black),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                           label: Text("${currentState.nonStriker.name} (Non-Striker)"),
                           selected: !isStrikerOut,
                           onSelected: (v) => setStateDialog(() => isStrikerOut = false),
                           selectedColor: Colors.red[100],
                           labelStyle: TextStyle(color: !isStrikerOut ? Colors.red : Colors.black),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Text("New Batsman:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPlayerSelector("Select/Enter Name", availableBatsmen, nameController),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                TextButton(
                  onPressed: () {
                     _machine.recordBall(
                      runsScored: 0, 
                      isWide: _isWide,
                      isNoBall: _isNoBall,
                      isBye: _isBye,
                      isLegBye: _isLegBye,
                      isWicket: true,
                      isStrikerOut: isStrikerOut,
                      newBatsmanName: nameController.text.isNotEmpty ? nameController.text : "Batsman",
                    );
                    _resetToggles();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("CONFIRM OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }
  
  Future<void> _changeBowler({bool mandatory = false}) async {
    final nameController = TextEditingController();
    final currentState = _machine.state;
    // Get correct bowling squad
    final bowlingSquad = currentState.currentInning == 1 ? widget.squadB : widget.squadA;
    
    // Filter out current bowler if mandatory (Must change bowler)
    // Also remove them from dropdown options
    final currentBowlerName = currentState.bowler.name;
    final availableBowlers = mandatory 
        ? bowlingSquad.where((name) => name != currentBowlerName).toList()
        : bowlingSquad;
        
    // Default selection logic: Pick first available that isn't current
    if (availableBowlers.isNotEmpty && nameController.text.isEmpty) {
       // logic handled by _buildPlayerSelector but we can pre-fill
    }

    await showDialog(
      context: context,
      barrierDismissible: !mandatory, // Cannot dismiss if mandatory
      builder: (context) => PopScope(
        canPop: !mandatory, // Prevent back button if mandatory
        child: AlertDialog(
          title: Text(mandatory ? "End of Over: Select New Bowler" : "Change Bowler"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               if (mandatory)
                 const Padding(
                   padding: EdgeInsets.only(bottom: 8.0),
                   child: Text("Previous bowler cannot bowl consecutive overs.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                 ),
               _buildPlayerSelector("New Bowler", availableBowlers, nameController),
            ],
          ),
          actions: [
            if (!mandatory)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            TextButton(
               onPressed: () {
                 if (nameController.text.isEmpty) return; 
                 // If mandatory, ensure it's actually different (though list is filtered)
                 if (mandatory && nameController.text == currentBowlerName) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Must select a different bowler!")));
                    return;
                 }
                 
                 _machine.updatePlayers(bowler: nameController.text);
                 setState(() {});
                 Navigator.pop(context);
               },
               child: const Text("UPDATE"),
            )
          ],
        ),
      )
    );
  }

  void _resetToggles() {
    _isWide = false; _isNoBall = false;
    _isBye = false; _isLegBye = false; 
  }
  
  Color _isOutColor(bool isOut) => isOut ? Colors.red : Colors.white;

  Future<void> _saveMatch() async {
    final state = _machine.state;
    if (!state.isMatchComplete) return;

    final result = MatchResult(
      sport: 'Cricket',
      date: DateTime.now(),
      teamA: widget.teamA,
      teamB: widget.teamB,
      // For Cricket, score is complex. We can store runs of each team from history.
      // But MatchState only keeps current inning details in top level? 
      // Actually CricketMatchState doesn't nicely store previous innings summary in easy fields.
      // We will assume Inning 1 was Team A (or whoever batted first) and Inning 2 is current.
      // A better way relies on the 'matchResult' string which describes who won.
      // Let's store total runs of current batting and bowling teams?
      // Since it's done, 'totalRuns' is the chasing team's score. 'targetRuns - 1' was first inning score?
      
      // Simplification: Store "Runs/Wickets" as the score string for A and B.
      scoreA: -1, // Placeholder, using Details for real scores
      scoreB: -1,
      winner: state.matchResult ?? "Draw", 
      details: jsonEncode({
        'resultDescription': state.matchResult,
        'totalOvers': state.totalOvers,
        'finalScore': "${state.totalRuns}/${state.wicketsLost} (${state.oversCompleted}.${state.ballsInOver})",
        // Ideally we'd have full scorecard here.
      }),
    );

    // Override winner text with just Team Name if possible, but matchResult is "Team A wins by..."
    // Let's parse or just save the full result string as winner for now.
    
    await DatabaseHelper.instance.insertMatch(result);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Match Result Saved!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _machine.state;
    
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: Text("${s.battingTeamName} vs ${s.bowlingTeamName}"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => CricketStatsScreen(state: s)));
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Score Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.green[800],
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    "${s.totalRuns} / ${s.wicketsLost}",
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Overs: ${s.oversCompleted}.${s.ballsInOver}  (Max ${s.totalOvers})",
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  if (s.currentInning == 2)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text("Target: ${s.targetRuns} | Need ${s.targetRuns! - s.totalRuns} runs", 
                          style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                     ),
                  if (s.isMatchComplete)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      color: Colors.green,
                      child: Column(
                        children: [
                          Text(s.matchResult ?? "GAME OVER", 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CricketStatsScreen(state: s))),
                                child: const Text("STATS"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _saveMatch,
                                icon: const Icon(Icons.save),
                                label: const Text("SAVE"),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // 2. Batsmen Stats
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBatsmanCard(s.striker, true),
                  _buildBatsmanCard(s.nonStriker, false),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24),
            
            // 3. Bowler Stats
            GestureDetector(
               onTap: _changeBowler, 
               child: Container(
                 width: double.infinity,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 color: Colors.transparent, // Tappable area
                 child: Row(
                   children: [
                     const Icon(Icons.sports_baseball, color: Colors.white, size: 16),
                     const SizedBox(width: 8),
                     Text("${s.bowler.name} : ${s.bowler.wickets}-${s.bowler.runsConceded} (${s.bowler.ballsBowled ~/ 6}.${s.bowler.ballsBowled % 6})",
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                     const Spacer(),
                     const Text("CHANGE", style: TextStyle(color: Colors.white54, fontSize: 10)),
                     const SizedBox(width: 4),
                     const Icon(Icons.edit, color: Colors.white24, size: 16),
                   ],
                 ),
               ),
            ),
            
            const Spacer(),
            
            // 4. Controls
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Extras Toggles
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToggle("WD", _isWide, (v) => setState(() => _isWide = v)),
                        _buildToggle("NB", _isNoBall, (v) => setState(() => _isNoBall = v)),
                        _buildToggle("BYE", _isBye, (v) => setState(() => _isBye = v)),
                        _buildToggle("LB", _isLegBye, (v) => setState(() => _isLegBye = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Run Buttons + Wicket
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...[0, 1, 2, 3, 4, 6].map((r) => _buildRunButton(r)),
                      
                      // Wicket Button
                      SizedBox(
                        width: 80, height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: s.isMatchComplete ? null : _handleWicketPress,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_cricket, size: 20),
                              Text("OUT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       TextButton.icon(
                         icon: const Icon(Icons.undo), 
                         label: const Text("Undo Last Ball"),
                         onPressed: _machine.canUndo ? () => setState(() => _machine.undo()) : null,
                       ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBatsmanCard(CricketPlayer p, bool isStrike) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           children: [
             if (isStrike) const Icon(Icons.star, color: Colors.yellow, size: 16),
             Text(p.name, style: TextStyle(color: _isOutColor(p.isOut), fontWeight: FontWeight.bold, fontSize: 18)),
           ],
         ),
         Text("${p.runs} (${p.ballsFaced})", style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged, {Color color = Colors.blue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: value,
        onSelected: onChanged,
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
        labelStyle: TextStyle(color: value ? color : Colors.black87, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRunButton(int runs) {
    Color bg = Colors.grey[200]!;
    if (runs == 4) bg = Colors.green[100]!;
    if (runs == 6) bg = Colors.purple[100]!;
    
    return SizedBox(
      width: 60, height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _machine.state.isMatchComplete ? null : () => _submitBall(runs),
        child: Text("$runs", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}
