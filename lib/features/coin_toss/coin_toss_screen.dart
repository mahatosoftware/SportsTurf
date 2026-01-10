import 'dart:math';
import 'package:flutter/material.dart';

class CoinTossScreen extends StatefulWidget {
  const CoinTossScreen({super.key});

  @override
  State<CoinTossScreen> createState() => _CoinTossScreenState();
}

class _CoinTossScreenState extends State<CoinTossScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  // true = Heads, false = Tails
  bool _isHeads = true;
  String _result = "";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 2 * pi * 5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _result = _isHeads ? "HEADS" : "TAILS";
        });
      }
    });

    _controller.addListener(() {
      setState(() {});
    });
  }

  void _tossCoin() {
    setState(() {
      _result = "";
    });
    // Randomize result before flipping
    bool nextIsHeads = Random().nextBool();
    
    // Reset controller
    _controller.reset();
    
    _isHeads = nextIsHeads; 
    
    // Tweaked logic:
    // Always rotate 5 full rounds (10pi).
    // Add extra pi if we need to flip face.
    
    _controller.duration = const Duration(seconds: 2);
    _animation = Tween<double>(
        begin: 0, 
        end: 10 * pi + (_isHeads ? 0 : pi)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Coin Toss"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final double value = _animation.value;
                // Calculate rotation Y
                // We want to show the "Front" image when 0 < val < pi/2 or 3pi/2 < val < 2pi
                // "Back" image when pi/2 < val < 3pi/2
                
                // Normalize value to 0..2pi
                double normalized = value % (2 * pi);
                bool showFront = normalized < (pi / 2) || normalized > (3 * pi / 2);
                
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX(value),
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(width: 4, color: Colors.orangeAccent),
                      boxShadow: [
                         BoxShadow(
                            color: Color.fromARGB(50, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                         )
                      ]
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: Image.asset(
                        showFront 
                            ? "assets/images/heads.png" 
                            : "assets/images/tails.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            Text(
              _result,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _controller.isAnimating ? null : _tossCoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text("FLIP COIN"),
            ),
          ],
        ),
      ),
    );
  }
}
