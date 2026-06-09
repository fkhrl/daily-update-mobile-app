import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import '../models/task.dart';
import '../screens/task_form_screen.dart';

class AiAssistantBottomSheet extends StatefulWidget {
  final VoidCallback onTaskCreated;

  const AiAssistantBottomSheet({super.key, required this.onTaskCreated});

  @override
  State<AiAssistantBottomSheet> createState() => _AiAssistantBottomSheetState();
}

class _AiAssistantBottomSheetState extends State<AiAssistantBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isParsing = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _dialogError = 'Speech recognition error: ${val.errorMsg}';
            });
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _dialogError = null;
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
        );
      } else {
        setState(() {
          _isListening = false;
          _dialogError = "The user has denied the use of speech recognition or it's not available.";
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(color: Color(0xFF334155), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI & Voice Task Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Powered by Google Gemini',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Describe your task in natural language. You can type it or tap the microphone button on your keyboard to speak it.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., meeting with boss tomorrow at 10 AM priority high category work",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.redAccent : Colors.white54,
                  ),
                  onPressed: _listen,
                ),
              ),
            ),
            if (_dialogError != null) ...[
              const SizedBox(height: 12),
              Text(
                _dialogError!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: _isParsing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(
                _isParsing ? 'AI is processing...' : 'Parse Task with AI',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF818CF8),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isParsing
                  ? null
                  : () async {
                      final text = _textController.text.trim();
                      if (text.isEmpty) {
                        setState(() {
                          _dialogError = 'Please enter or dictate a task description.';
                        });
                        return;
                      }

                      setState(() {
                        _isParsing = true;
                        _dialogError = null;
                      });

                      try {
                        final String timeContext = " (Note: The user's current local date and time is ${DateTime.now().toIso8601String()})";
                        final data = await ApiService().parseTaskWithAi(text + timeContext);
                        if (!context.mounted) return;
                        Navigator.pop(context); // Close sheet

                        // Create dummy Task object with id: 0
                        final parsedTask = Task(
                          id: 0,
                          title: data['title'] ?? 'New AI Task',
                          description: data['description'] ?? '',
                          scheduledAt: DateTime.tryParse(data['scheduled_at'] ?? '') ??
                              DateTime.now().add(const Duration(minutes: 10)),
                          isInstant: false,
                          isNotified: false,
                          priority: data['priority'] ?? 'medium',
                          category: data['category'] ?? 'personal',
                          status: 'pending',
                          recurrence: 'none',
                          recurrenceInterval: 1,
                          reminders: [],
                          position: 0,
                          completionPercentage: 0,
                          subtasks: [],
                        );

                        // Navigate to TaskFormScreen with prefilled task
                        if (!context.mounted) return;
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(task: parsedTask),
                          ),
                        );
                        if (result == true) {
                          widget.onTaskCreated();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        setState(() {
                          _isParsing = false;
                          _dialogError = 'Error: $e';
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
