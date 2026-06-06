import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({Key? key}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  static const int workSeconds = 25 * 60;
  static const int breakSeconds = 5 * 60;

  int _totalSeconds = workSeconds;
  int _secondsRemaining = workSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isWorkSession = true;
  int _completedSessions = 0;

  void _startPauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          _onSessionComplete();
        }
      });
    }
  }

  void _onSessionComplete() {
    setState(() {
      _isRunning = false;
      if (_isWorkSession) {
        _completedSessions++;
        _isWorkSession = false;
        _totalSeconds = breakSeconds;
        _secondsRemaining = breakSeconds;
        _showDialog("Session Completed!", "Time for a 5-minute break. Rest up!");
      } else {
        _isWorkSession = true;
        _totalSeconds = workSeconds;
        _secondsRemaining = workSeconds;
        _showDialog("Break Over!", "Ready to dive back into deep work?");
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isWorkSession = true;
      _totalSeconds = workSeconds;
      _secondsRemaining = workSeconds;
    });
  }

  void _showDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(body, style: const TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Let's Go", style: TextStyle(color: Colors.indigoAccent)),
          )
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? (_totalSeconds - _secondsRemaining) / _totalSeconds : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Focus Mode & Pomodoro', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Session Type Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _isWorkSession
                      ? Colors.indigoAccent.withOpacity(0.15)
                      : const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isWorkSession
                        ? Colors.indigoAccent.withOpacity(0.4)
                        : const Color(0xFF10B981).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  _isWorkSession ? "⚒️ WORK SESSION" : "☕ REST BREAK",
                  style: TextStyle(
                    color: _isWorkSession ? Colors.indigoAccent : const Color(0xFF10B981),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Circular Progress Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isWorkSession ? Colors.indigoAccent : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(_secondsRemaining),
                        style: GoogleFonts.outfit(
                          fontSize: 62,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isRunning ? "FOCUSING" : "PAUSED",
                        style: TextStyle(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 50),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Button
                  IconButton(
                    onPressed: _resetTimer,
                    iconSize: 32,
                    color: const Color(0xFF94A3B8),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 30),

                  // Start/Pause Floating Button
                  GestureDetector(
                    onTap: _startPauseTimer,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _isWorkSession ? Colors.indigoAccent : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isWorkSession ? Colors.indigoAccent : const Color(0xFF10B981)).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),

                  // Stats counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _completedSessions.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "SESSIONS",
                        style: TextStyle(
                          fontSize: 9,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "\"Focus is a muscle, and you are building it right now.\"",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
