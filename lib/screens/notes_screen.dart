import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class NotesScreen extends StatefulWidget {
  final int? taskId;
  const NotesScreen({super.key, this.taskId});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _notes = [];
  bool _isLoading = true;
  final TextEditingController _noteContentController = TextEditingController();
  
  // Audio Mock states
  bool _isRecording = false;
  String? _recordedVoicePath;
  List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getNotes(taskId: widget.taskId);
      setState(() => _notes = data);
    } catch (e) {
      _showSnackbar('Error loading notes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createNote() async {
    final content = _noteContentController.text.trim();
    if (content.isEmpty && _recordedVoicePath == null && _selectedImages.isEmpty) return;

    try {
      await _apiService.createNote(
        content,
        taskId: widget.taskId,
        voicePath: _recordedVoicePath,
        images: _selectedImages,
      );
      _noteContentController.clear();
      setState(() {
        _recordedVoicePath = null;
        _selectedImages = [];
      });
      _loadNotes();
      _showSnackbar('Note saved successfully!');
    } catch (e) {
      _showSnackbar('Failed to save note: $e');
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      await _apiService.deleteNote(noteId);
      setState(() {
        _notes.removeWhere((n) => n['id'] == noteId);
      });
      _showSnackbar('Note deleted.');
    } catch (e) {
      _showSnackbar('Failed to delete note: $e');
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.indigoAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Render stylized text resembling Markdown
  Widget _renderMarkdown(String text) {
    final lines = text.split('\n');
    List<Widget> children = [];

    for (var line in lines) {
      if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            line.substring(2),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
        ));
      } else if (line.startsWith('- ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
              Expanded(
                child: Text(line.substring(2), style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 3, bottom: 3),
          child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.taskId != null ? 'Task Attachments & Notes' : 'Journal & Thoughts',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Editor Panel
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _noteContentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Write notes here... (Use # for title, - for list)',
                    hintStyle: TextStyle(color: Color(0xFF64748B)),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 10),

                // Audio Mock / Image previews list
                if (_recordedVoicePath != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.indigoAccent, size: 18),
                        const SizedBox(width: 8),
                        const Text('Voice Note attachment saved (Simulated)', style: TextStyle(color: Colors.indigoAccent, fontSize: 12)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _recordedVoicePath = null),
                          child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                        )
                      ],
                    ),
                  ),

                if (_selectedImages.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (ctx, idx) => Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image, color: Colors.indigoAccent),
                          ),
                          Positioned(
                            top: 0,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(idx)),
                              child: const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.close, size: 10, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                // Attachments Controls
                Row(
                  children: [
                    // Mock voice record
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_isRecording) {
                            _isRecording = false;
                            _recordedVoicePath = "voice_notes/simulated_audio_${DateTime.now().millisecond}.mp3";
                            _showSnackbar("Voice recording completed (Simulated)");
                          } else {
                            _isRecording = true;
                            _showSnackbar("Recording started... Click again to stop");
                          }
                        });
                      },
                      icon: Icon(
                        _isRecording ? Icons.fiber_manual_record : Icons.mic_none,
                        color: _isRecording ? Colors.redAccent : const Color(0xFF94A3B8),
                      ),
                    ),
                    // Mock image picker
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImages.add("notes_images/simulated_img_${DateTime.now().millisecond}.png");
                          _showSnackbar("Mock image attached.");
                        });
                      },
                      icon: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _createNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Notes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const Center(
                        child: Text(
                          'No attachments or notes found.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        itemBuilder: (ctx, idx) {
                          final note = _notes[idx];
                          final hasVoice = note['voice_note_path'] != null;
                          final imagesList = note['images'] as List?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Journal Entry',
                                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteNote(note['id']),
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFF475569), size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),

                                // Text Render
                                _renderMarkdown(note['content'] ?? ''),
                                const SizedBox(height: 10),

                                // Voice player UI if exists
                                if (hasVoice)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.play_circle_fill, color: Colors.indigoAccent, size: 24),
                                        SizedBox(width: 8),
                                        Text('Play voice note attachment', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                      ],
                                    ),
                                  ),

                                // Image list attachments preview
                                if (imagesList != null && imagesList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Wrap(
                                      spacing: 6,
                                      children: imagesList.map((img) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF1E293B)),
                                        ),
                                        child: const Icon(Icons.image, color: Colors.indigoAccent, size: 24),
                                      )).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
