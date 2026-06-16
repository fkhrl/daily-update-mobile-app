import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class RoutineTimerScreen extends StatefulWidget {
  final Map<String, dynamic> routine;

  const RoutineTimerScreen({super.key, required this.routine});

  @override
  State<RoutineTimerScreen> createState() => _RoutineTimerScreenState();
}

class _RoutineTimerScreenState extends State<RoutineTimerScreen> {
  late List<Map<String, dynamic>> _phases;
  int _currentPhaseIndex = 0;

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isRunning = false;
  bool _alarmTriggeredForPhase = false;

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    
    final reading = _parseInt(widget.routine['reading_minutes']);
    final writing = _parseInt(widget.routine['writing_minutes']);
    final mcq = _parseInt(widget.routine['mcq_minutes']);

    _phases = [
      if (reading > 0)
        {'name': 'Reading', 'duration': reading * 60, 'icon': Icons.menu_book},
      if (writing > 0)
        {'name': 'Writing', 'duration': writing * 60, 'icon': Icons.edit},
      if (mcq > 0)
        {'name': 'MCQ / Practice', 'duration': mcq * 60, 'icon': Icons.quiz},
    ];

    if (_phases.isNotEmpty) {
      _secondsRemaining = _phases[0]['duration'];
    }
  }

  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          
          // 5-minute warning
          if (_secondsRemaining == 300 && !_alarmTriggeredForPhase) {
            _alarmTriggeredForPhase = true;
            _playAlarmAndShowDialog();
          }
        } else {
          _timer!.cancel();
          _isRunning = false;
          _nextPhase();
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = false);
  }

  void _nextPhase() {
    if (_currentPhaseIndex < _phases.length - 1) {
      setState(() {
        _currentPhaseIndex++;
        _secondsRemaining = _phases[_currentPhaseIndex]['duration'];
        _alarmTriggeredForPhase = false;
      });
      // Optionally auto-start next phase
      // _startTimer();
    } else {
      // Finished all phases
      if (!kIsWeb) FlutterRingtonePlayer().playNotification();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Session Complete!', style: TextStyle(color: Colors.white)),
          content: const Text('Great job completing your study routine!', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close screen
              },
              child: const Text('Done', style: TextStyle(color: Colors.indigoAccent)),
            )
          ],
        )
      );
    }
  }

  void _playAlarmAndShowDialog() {
    if (!kIsWeb) FlutterRingtonePlayer().playAlarm(looping: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('5 Minutes Left!', style: TextStyle(color: Colors.orangeAccent)),
        content: Text(
          'Your ${_phases[_currentPhaseIndex]['name']} phase is almost over. Do you need more time?', 
          style: const TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!kIsWeb) FlutterRingtonePlayer().stop();
              Navigator.pop(ctx);
            },
            child: const Text('No, Im good', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (!kIsWeb) FlutterRingtonePlayer().stop();
              setState(() => _secondsRemaining += 5 * 60);
              Navigator.pop(ctx);
            },
            child: const Text('+5 Min', style: TextStyle(color: Colors.indigoAccent)),
          ),
          TextButton(
            onPressed: () {
              if (!kIsWeb) FlutterRingtonePlayer().stop();
              setState(() => _secondsRemaining += 10 * 60);
              Navigator.pop(ctx);
            },
            child: const Text('+10 Min', style: TextStyle(color: Colors.indigoAccent)),
          ),
          TextButton(
            onPressed: () {
              if (!kIsWeb) FlutterRingtonePlayer().stop();
              setState(() => _secondsRemaining += 15 * 60);
              Navigator.pop(ctx);
            },
            child: const Text('+15 Min', style: TextStyle(color: Colors.indigoAccent)),
          ),
        ],
      )
    );
  }

  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    if (!kIsWeb) FlutterRingtonePlayer().stop();
    super.dispose();
  }

  String get _timeString {
    final m = (_secondsRemaining / 60).floor().toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_phases.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No durations set for this routine.', style: TextStyle(color: Colors.white))),
      );
    }

    final currentPhase = _phases[_currentPhaseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.routine['subject'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Phase Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_phases.length, (index) {
                final isActive = index == _currentPhaseIndex;
                final isDone = index < _currentPhaseIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.indigoAccent : (isDone ? Colors.green : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_phases[index]['icon'], size: 14, color: isActive || isDone ? Colors.white : Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        _phases[index]['name'], 
                        style: TextStyle(
                          color: isActive || isDone ? Colors.white : Colors.white54, 
                          fontSize: 12, 
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),

            // Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: _secondsRemaining / currentPhase['duration'],
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFF1E293B),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _secondsRemaining <= 300 ? Colors.orangeAccent : Colors.indigoAccent
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(currentPhase['icon'], size: 40, color: Colors.white70),
                    const SizedBox(height: 8),
                    Text(
                      _timeString,
                      style: GoogleFonts.outfit(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      currentPhase['name'],
                      style: const TextStyle(fontSize: 18, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_secondsRemaining < currentPhase['duration'])
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _secondsRemaining = currentPhase['duration'];
                        _alarmTriggeredForPhase = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white54, size: 32),
                  ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: _isRunning ? _pauseTimer : _startTimer,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRunning ? Colors.redAccent : Colors.indigoAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRunning ? Colors.redAccent : Colors.indigoAccent).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  onPressed: _nextPhase,
                  icon: const Icon(Icons.skip_next, color: Colors.white54, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
