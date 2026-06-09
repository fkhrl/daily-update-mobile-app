import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WalkthroughOverlay extends StatefulWidget {
  final VoidCallback onDismissed;
  const WalkthroughOverlay({super.key, required this.onDismissed});

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> {
  int _currentStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Welcome to TaskDigest! 🚀',
      'description': 'Your advanced task checklist is now upgraded with premium AI and productivity tools.',
      'icon': '⚡',
    },
    {
      'title': 'Habit Tracker Streaks 🪴',
      'description': 'Form atomic habits! Track water, reading, or exercise daily and build streak multipliers.',
      'icon': '🔥',
    },
    {
      'title': 'Pomodoro Focus Timer ☕',
      'description': 'Stay focused for 25-minute work intervals and take 5-minute break sessions.',
      'icon': '⏰',
    },
    {
      'title': 'Smart AI Recommendations 🎯',
      'description': 'Gemini 2.5 Flash analyzes your schedules to pick your top 3 tasks and optimal daily hours.',
      'icon': '🤖',
    },
    {
      'title': 'Team Workspaces & Chat 💬',
      'description': 'Create shared workspaces, invite teammates, log activities, and write task comments.',
      'icon': '👥',
    },
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                step['icon']!,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 15),
              Text(
                step['title']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step['description']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip
                  TextButton(
                    onPressed: widget.onDismissed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Indicators
                  Row(
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentStep ? Colors.indigoAccent : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),

                  // Next / Finish
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      _currentStep == _steps.length - 1 ? 'Finish' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, 
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
